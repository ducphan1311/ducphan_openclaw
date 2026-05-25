# Mobile App Factory Skill

`mobile_app_factory` is an OpenClaw AgentSkill for building mobile apps end-to-end with one commander and eight specialist workers.

It is designed for requests like:

> Build me a mobile app from idea to production, including design, documentation, client, server, testing, and deployment.

The skill does not magically skip product decisions or approval gates. It gives the agent a repeatable delivery pipeline, role definitions, document templates, and quality checks so the work can be split into focused sub-agents instead of one overloaded generic coding session.

## Team Structure

The skill contains **1 commander + 8 workers**.

| Role | File | Responsibility |
|---|---|---|
| Commander | `agents/mobile-app-commander.md` | Owns the end-to-end plan, worker handoffs, milestones, approval gates, and final synthesis. |
| Product BA | `agents/product-ba-worker.md` | Writes PRD, MVP scope, user stories, and testable acceptance criteria. |
| UX/UI Designer | `agents/ux-ui-design-worker.md` | Defines user flows, screen specs, design tokens, and UI states. |
| Solution Architect | `agents/solution-architect-worker.md` | Designs stack, architecture, API contract, database schema, security baseline, and deployment plan. |
| Mobile Client Engineer | `agents/mobile-client-worker.md` | Implements the mobile app, preferably Flutter unless another stack is requested. |
| Backend API Engineer | `agents/backend-api-worker.md` | Implements server, database, auth, API endpoints, validation, and backend tests. |
| QA Test Engineer | `agents/qa-test-worker.md` | Creates/runs manual and automated tests, maps tests to acceptance criteria, reports bugs. |
| DevOps Release Engineer | `agents/devops-release-worker.md` | Prepares CI/CD, environments, backend deploy, mobile build, release checklist, rollback notes. |
| Technical Writer & Security Reviewer | `agents/technical-writer-security-worker.md` | Finalizes README/setup/API/deploy docs and performs lightweight security review. |

## How It Works

When the user asks for an end-to-end mobile app, OpenClaw loads `SKILL.md`. The commander then runs the project through this pipeline:

1. **Intake**
   - Clarify app purpose, users, platforms, stack preference, backend needs, auth, deploy target, deadline, and constraints.

2. **Product Gate**
   - Product BA creates:
     - `docs/PRD.md`
     - `docs/user-stories.md`
     - `docs/acceptance-criteria.md`
   - Commander asks for approval if scope is ambiguous or large.

3. **Design Gate**
   - UX/UI worker creates:
     - `docs/design-system.md`
     - `docs/screen-specs.md`
     - `docs/user-flow.md`
   - Design specs become the implementation source of truth.

4. **Architecture Gate**
   - Architect creates:
     - `docs/architecture.md`
     - `docs/api-contract.md` or `openapi.yaml`
     - `docs/database-schema.md`
     - `docs/security-checklist.md`
     - `docs/deployment-plan.md`

5. **Build**
   - Mobile and backend workers can run in parallel after the API contract is stable.
   - Default structure:

   ```text
   apps/
     mobile/
     server/
   docs/
   ```

6. **Integration**
   - Client/server mismatches are resolved.
   - Env config and seed data are checked.

7. **Testing**
   - QA worker creates and runs:
     - unit tests
     - API tests
     - mobile widget/integration tests where practical
     - manual test checklist
   - The app is not considered done without evidence or a named blocker.

8. **Release / Deploy**
   - DevOps worker prepares local build, CI/CD, backend deployment, and mobile distribution.
   - Production deploys, cloud resource creation, app store submission, git push, paid services, and secret changes require explicit approval.

9. **Handover**
   - Technical writer/security worker finalizes setup, deployment, API, security, and release notes.

## Required Setup Before Running

### 1. OpenClaw workspace

The skill must live under the OpenClaw workspace skills directory:

```text
~/.openclaw/workspace/skills/mobile_app_factory/
```

In this environment it is located at:

```text
/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/workspace/skills/mobile_app_factory/
```

### 2. Skill files must exist

Minimum required files:

```text
skills/mobile_app_factory/SKILL.md
skills/mobile_app_factory/agents/mobile-app-commander.md
skills/mobile_app_factory/agents/product-ba-worker.md
skills/mobile_app_factory/agents/ux-ui-design-worker.md
skills/mobile_app_factory/agents/solution-architect-worker.md
skills/mobile_app_factory/agents/mobile-client-worker.md
skills/mobile_app_factory/agents/backend-api-worker.md
skills/mobile_app_factory/agents/qa-test-worker.md
skills/mobile_app_factory/agents/devops-release-worker.md
skills/mobile_app_factory/agents/technical-writer-security-worker.md
```

### 3. Runtime/tools needed for actual app builds

The skill can write docs without these tools, but real builds need the stack-specific tooling.

Recommended baseline:

- Git
- Node.js / npm / pnpm / yarn if using JS/TS backend or React Native
- Flutter SDK if using Flutter
- Android Studio / Android SDK for Android builds
- Xcode for iOS builds on macOS
- Docker if backend/database runs in containers
- Database CLI or Docker image, depending on selected DB
- Cloud/provider CLI only if deploying to that provider

### 4. Credentials and secrets

Do **not** put secrets in skill files or docs.

Use `.env.example` for names only:

```env
API_BASE_URL=
DATABASE_URL=
JWT_SECRET=
```

Real secrets should stay in local environment, secret manager, CI/CD secret store, or OpenClaw-approved config mechanisms.

### 5. Approval expectations

The skill can safely create local files, docs, tests, and local builds.

It must ask before:

- production deploy
- creating paid cloud resources
- app store submission
- git push or release tag
- DNS/domain changes
- deleting data
- changing or revealing secrets

## Example Run

User request:

```text
Build a Flutter mobile app for personal expense tracking.
It should include login, add expense, category summary, monthly report,
and a backend API. Deploy the backend and give me an APK.
```

Expected factory flow:

### Step 1 — Commander intake

The commander asks only for missing decisions, for example:

```text
I can start. I need 3 decisions before implementation:
1. Auth: email/password only or Google login too?
2. Backend target: local Docker first, then deploy to Render/Fly/VPS?
3. Design style: minimal finance dashboard or colorful consumer app?
```

If Danny says:

```text
Email/password, local Docker first then Render, minimal finance dashboard.
```

### Step 2 — Product BA output

Creates:

```text
docs/PRD.md
docs/user-stories.md
docs/acceptance-criteria.md
```

Example acceptance criterion:

```text
Given I am logged in
When I create an expense with amount, category, note, and date
Then the expense appears in my transaction list and updates the monthly category summary.
```

### Step 3 — UX/UI output

Creates:

```text
docs/design-system.md
docs/screen-specs.md
docs/user-flow.md
```

Example screens:

- Login
- Register
- Dashboard
- Add Expense
- Expense List
- Monthly Report
- Settings

### Step 4 — Architecture output

Creates:

```text
docs/architecture.md
docs/api-contract.md
docs/database-schema.md
docs/deployment-plan.md
```

Example API endpoints:

```text
POST /auth/register
POST /auth/login
GET /expenses
POST /expenses
PUT /expenses/:id
DELETE /expenses/:id
GET /reports/monthly?month=YYYY-MM
```

### Step 5 — Build output

Creates or updates:

```text
apps/mobile/   # Flutter app
apps/server/   # Backend API
```

Mobile worker runs evidence commands such as:

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Backend worker runs evidence commands such as:

```bash
npm test
npm run build
docker compose up -d
```

The exact commands depend on the chosen stack.

### Step 6 — QA output

Creates:

```text
docs/test-plan.md
docs/manual-test-report.md
```

Example QA result:

```text
PASS: User can register and log in.
PASS: User can add expense.
PASS: Dashboard updates category total.
FAIL: Monthly report empty state copy is missing.
```

### Step 7 — Release output

Creates:

```text
docs/deployment-guide.md
docs/release-notes.md
```

If deployment is requested, the commander asks for approval before pushing/deploying:

```text
Backend is ready for Render deploy. This will create/update an external service.
Approve production deploy?
```

### Step 8 — Final handover

Final response includes:

- What was built
- File paths
- Build/test results
- Deploy status
- Known issues
- Next recommended actions

## Quality Bar

The commander should not mark a project complete unless it can cite evidence:

- PRD and acceptance criteria exist
- Design and architecture docs exist
- Client and server compile or blockers are named
- Tests/manual checks ran or blockers are named
- Deployment/build artifact status is clear
- Setup and handover docs exist

## Notes for Future Improvement

Possible future additions:

- Separate Flutter and React Native worker files
- Provider-specific deploy references: Render, Fly.io, VPS, Firebase, Supabase, AWS
- App store release worker for TestFlight and Google Play Console
- Reusable project scaffolding scripts
- More opinionated templates for common app types
