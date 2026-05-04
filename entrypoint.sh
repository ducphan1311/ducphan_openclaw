#!/bin/bash
set -e

if [ -n "${VAULT_TOKEN:-}" ]; then
  # Only block on Vault when a token is provided and secrets are expected.
  echo "Waiting for Vault to be ready at ${VAULT_ADDR}..."
  while ! curl -s -f "${VAULT_ADDR}/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204" > /dev/null; do
    sleep 2
  done
  echo "Fetching secrets from Vault..."
  echo "Calling Vault API at ${VAULT_ADDR}/v1/openclaw_secrets/data/api_keys"
  SECRETS_JSON=$(curl -sS -L -H "X-Vault-Token: $VAULT_TOKEN" "${VAULT_ADDR}/v1/openclaw_secrets/data/api_keys")
  export SECRETS_JSON
  source <(node -e "
    try {
      const raw = process.env.SECRETS_JSON;
      if (!raw) throw new Error('SECRETS_JSON is empty in Node env');
      const data = JSON.parse(raw);
      let secrets;
      if (data.data && data.data.data) {
        secrets = data.data.data;
      } else if (data.data) {
        secrets = data.data;
      } else {
        console.error('echo \"Unexpected secret format from Vault\"');
        process.exit(1);
      }
      for (const [key, value] of Object.entries(secrets)) {
        if (value === null || value === undefined) continue;
        const safeValue = value.toString().replace(/'/g, \"'\\\\''\");
        console.log(\`export \${key}='\${safeValue}'\`);
        if (key === 'GOOGLE_GENERATIVE_AI_API_KEY') {
          console.log(\`export GOOGLE_API_KEY='\${safeValue}'\`);
        }
      }
    } catch (err) {
      console.error('echo \"Failed to parse secrets JSON. Error: ' + err.message + '\"');
      process.exit(1);
    }
  ")
  unset SECRETS_JSON
  unset VAULT_TOKEN
  echo "Secrets successfully loaded into RAM environment."
else
  echo "VAULT_TOKEN is not set, skipping Vault secret fetch."
fi
openclaw config set env.shellEnv.enabled true --strict-json >/dev/null 2>&1 || true
sync_env_var() {
  key="$1"
  value="$(printenv "$key" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    openclaw config set "env.vars.${key}" "$value" >/dev/null 2>&1 || true
  fi
}
for key in \
  JIRA_BASE_URL JIRA_USER_EMAIL JIRA_API_TOKEN \
  AZURE_DEVOPS_ORG_URL AZURE_DEVOPS_ORG AZURE_DEVOPS_PROJECT AZURE_DEVOPS_PAT \
  MS_TENANT_ID MS_CLIENT_ID MS_CLIENT_SECRET \
  TEAMS_TENANT_ID TEAMS_USER_EMAIL \
  GRAPH_BASE_URL GRAPH_SCOPES \
  FIGMA_API_TOKEN FIGMA_FILE_KEY FIGMA_TEAM_ID FIGMA_ORG_ID; do
  sync_env_var "$key"
done
echo "Starting OpenClaw..."

# Execute the original command
exec "$@"
