# OpenClaw Personal Assistant System

Hệ thống multi-agent chạy trên OpenClaw, tích hợp Jira, Azure DevOps, Teams, Figma và Telegram.

## Mục tiêu

- Theo dõi task Jira, build Azure DevOps, tin nhắn Teams
- Tạo tóm tắt hằng ngày/tuần theo workflow cá nhân
- Cho phép automation có kiểm soát trong container

## Yêu cầu trước khi chạy

- Docker Desktop (đã bật Docker Compose)
- Git
- macOS/Linux shell
- Tài khoản và token cho các dịch vụ cần dùng (Jira, Azure, Teams, Figma, Telegram)

## Cấu trúc chính

- `docker-compose.yml`: khởi chạy `openclaw_agent` và `openclaw_vault`
- `entrypoint.sh`: nạp secrets từ Vault vào runtime OpenClaw
- `config/policies.yaml`: network/tool policy
- `skills/`: bộ skill theo domain
- `openclaw_data/`: state runtime của OpenClaw (đã ignore khỏi git)

## Quick Start cho người mới clone

### 1) Clone repo

```bash
git clone <repo-url>
cd openclaw_manager
```

### 2) Khởi động dịch vụ

```bash
docker compose up -d --build
docker compose ps
```

UI Vault local: `http://127.0.0.1:8200`

### 3) Init Vault lần đầu

Nếu là môi trường mới hoàn toàn, chạy:

```bash
docker exec -it openclaw_vault vault operator init
docker exec -it openclaw_vault vault operator unseal <UNSEAL_KEY_1>
docker exec -it openclaw_vault vault operator unseal <UNSEAL_KEY_2>
docker exec -it openclaw_vault vault operator unseal <UNSEAL_KEY_3>
```

Lưu lại `Initial Root Token` ở nơi an toàn.

### 4) Đăng nhập Vault và ghi secrets

```bash
docker exec -it openclaw_vault vault login <ROOT_OR_ADMIN_TOKEN>
docker exec -it openclaw_vault vault kv put openclaw_secrets/api_keys \
  JIRA_BASE_URL="https://your-domain.atlassian.net" \
  JIRA_USER_EMAIL="you@company.com" \
  JIRA_API_TOKEN="xxx" \
  AZURE_DEVOPS_ORG_URL="https://dev.azure.com/your-org" \
  AZURE_DEVOPS_ORG="your-org" \
  AZURE_DEVOPS_PROJECT="your-project" \
  AZURE_DEVOPS_PAT="xxx" \
  MS_TENANT_ID="xxx" \
  MS_CLIENT_ID="xxx" \
  MS_CLIENT_SECRET="xxx" \
  TEAMS_USER_EMAIL="you@company.com" \
  GRAPH_BASE_URL="https://graph.microsoft.com/v1.0" \
  GRAPH_SCOPES="https://graph.microsoft.com/.default" \
  FIGMA_API_TOKEN="xxx" \
  FIGMA_FILE_KEY="xxx" \
  FIGMA_TEAM_ID="xxx" \
  FIGMA_ORG_ID="xxx" \
  GMAIL_ACCOUNT="you@gmail.com" \
  GMAIL_USER="you@gmail.com" \
  GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx" \
  BROWSERACT_API_KEY="xxx" \
  APIFY_TOKEN="xxx" \
  AMADEUS_API_KEY="xxx" \
  AMADEUS_API_SECRET="xxx" \
  AMADEUS_BASE_URL="https://test.api.amadeus.com" \
  AGENT_BRAIN_SUPERMEMORY_SYNC="off" \
  AGENT_BRAIN_PII_MODE="strict" \
  AGENT_BRAIN_REMOTE_EMBEDDINGS="off"
```

### 5) Truyền `VAULT_TOKEN` vào container OpenClaw

`entrypoint.sh` chỉ fetch secret khi có `VAULT_TOKEN`.

```bash
export VAULT_TOKEN='<VAULT_TOKEN_CO_QUYEN_DOC_openclaw_secrets/api_keys>'
docker compose up -d --build --force-recreate openclaw
```

### 6) Kiểm tra OpenClaw đã nạp config

```bash
docker logs --tail 80 openclaw_agent
docker exec openclaw_agent openclaw config validate
```

Nếu thành công, log sẽ có dòng `Secrets successfully loaded into RAM environment.`

## Sử dụng

- Gateway WebSocket: `ws://127.0.0.1:3000`
- Token gateway nằm trong `openclaw_data/openclaw.json` phần `gateway.auth.token`
- Khi vào Control UI, dùng đúng token gateway để pair

## Chạy native trên macOS

Nếu không dùng Docker, chạy gateway bằng:

```bash
./start_native.sh
```

Native gateway hiện dùng port `18789`:

```bash
lsof -nP -iTCP:18789 -sTCP:LISTEN
```

`start_native.sh` sẽ:

- Nạp `.env` nếu có.
- Fetch secrets từ Vault nếu có `VAULT_TOKEN` hoặc `~/.vault-token`.
- Dùng `openclaw_data/openclaw.json` làm state local.
- Dùng `skills/` làm workspace skills directory.
- Sync các biến Jira/Figma/Gmail/Shopping/Amadeus/Memory vào runtime config.

Sau khi thêm hoặc sửa skill trong `skills/`, restart native gateway để OpenClaw nạp skill mới.

## Tích hợp dịch vụ

### Jira

- Cần: `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, `JIRA_API_TOKEN`

### Azure DevOps

- Cần: `AZURE_DEVOPS_ORG_URL`, `AZURE_DEVOPS_ORG`, `AZURE_DEVOPS_PROJECT`, `AZURE_DEVOPS_PAT`

### Microsoft Teams / Graph

- Cần: `MS_TENANT_ID`, `MS_CLIENT_ID`, `MS_CLIENT_SECRET`, `TEAMS_USER_EMAIL`
- App Registration trên Entra ID cần cấp quyền Graph phù hợp và admin consent

### Figma

- Cần: `FIGMA_API_TOKEN`, `FIGMA_FILE_KEY`
- Optional: `FIGMA_TEAM_ID`, `FIGMA_ORG_ID`

### Gmail / Google Workspace

- Đọc/tóm tắt Gmail: `GMAIL_ACCOUNT`
- SMTP/IMAP app-password mode: `GMAIL_USER`, `GMAIL_APP_PASSWORD`
- Luôn lưu app password trong Vault/env runtime, không commit vào repo.

### Shopping / săn sale

- Amazon BrowserAct workflows: `BROWSERACT_API_KEY`
- Apify price monitor workflows: `APIFY_TOKEN`
- Bot chỉ nghiên cứu/so sánh giá; checkout/mua/return cần xác nhận thủ công trong cùng lượt chat.

### Flights / travel

- Amadeus: `AMADEUS_API_KEY`, `AMADEUS_API_SECRET`
- Sandbox mặc định: `AMADEUS_BASE_URL=https://test.api.amadeus.com`
- Production real fare: `AMADEUS_BASE_URL=https://api.amadeus.com`
- Bot chỉ tìm/so sánh chuyến bay; booking/check-in/thay đổi hành khách cần xác nhận thủ công.

### Memory + planning + English

- Local memory mặc định dùng `workspace/memory/`.
- Nếu dùng `agent-brain`, giữ `AGENT_BRAIN_SUPERMEMORY_SYNC=off`, `AGENT_BRAIN_PII_MODE=strict`, `AGENT_BRAIN_REMOTE_EMBEDDINGS=off` trừ khi bạn chủ động bật cloud/remote embedding.

## Skill setup hiện tại

- `skills/browser_automation/`: UI testing, browser automation, screenshot, public web research.
- `skills/email_assistant/`: Gmail summary, email triage, draft/send với approval.
- `skills/codebase_intelligence/`: AgentLens/Atris-style repo map; map nằm ở `atris/MAP.md`.
- `skills/shopping_research/`: săn sale, so sánh sản phẩm, wishlist/watchlist.
- `skills/travel_flights/`: tìm và so sánh chuyến bay.
- `skills/memory/`: memory local, không lưu secret.
- `skills/english_learning_planner/`: kế hoạch cá nhân và học tiếng Anh.
- Review rủi ro skill bên ngoài nằm ở `docs/skill-security-review.md`.

## Xử lý lỗi thường gặp

### 1) `VAULT_TOKEN is not set, skipping Vault secret fetch`

```bash
export VAULT_TOKEN='<token>'
docker compose up -d --build --force-recreate openclaw
```

### 2) Browser tool lỗi trong container

Repo đã bật cấu hình phù hợp container (`headless`, `noSandbox`, `shm_size`).
Nếu vẫn lỗi:

```bash
docker compose up -d --build --force-recreate openclaw
docker logs --tail 120 openclaw_agent
```

### 3) GitHub push lỗi `Permission denied (publickey)`

- Cấu hình SSH key đúng account và đúng host alias trong `~/.ssh/config`
- Kiểm tra:

```bash
ssh -T git@github.com
```

## Bảo mật bắt buộc

- Không commit token vào git.
- `openclaw_data/` đã được ignore để tránh đẩy state runtime lên remote.
- Backup dạng `*.bak` chứa dữ liệu nhạy cảm, không lưu trữ lâu.
- Bất kỳ AI/agent nào có quyền đọc workspace đều có thể đọc file plaintext trong repo local.
- Chỉ giữ secrets trong Vault hoặc env runtime, rotate token ngay nếu từng lộ ra log/file.
