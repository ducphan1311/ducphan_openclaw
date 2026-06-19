# OpenClaw Manager

Hệ thống personal AI assistant chạy trên [OpenClaw](https://openclaw.ai), tích hợp đa kênh và đa dịch vụ. Giao tiếp chính qua **Telegram**, hỗ trợ hai chế độ chạy: **Native macOS** và **Docker**.

---

## Tổng quan kiến trúc

```
Telegram ──► OpenClaw Gateway (port 18789)
                    │
          ┌─────────┴──────────┐
          │   Skills (agents)  │
          └─────────┬──────────┘
                    │
     ┌──────────────┼──────────────┐
     │              │              │
  Vault          9Router        Services
(secrets)     (LLM router)   (Jira, Gmail,
                              Azure, Figma…)
```

- **Gateway**: OpenClaw chạy trên port `18789`, expose ra `3000` (Docker) hoặc `18789` (native).
- **9Router**: Local OpenAI-compatible LLM router (`http://127.0.0.1:20128/v1`), quản lý model routing và fallback.
- **Vault**: HashiCorp Vault lưu toàn bộ secrets, không commit vào git.
- **Skills**: Các agent chuyên biệt, mỗi skill là một thư mục trong `skills/` chứa `SKILL.md`.

---

## Yêu cầu

| Chế độ | Yêu cầu |
|--------|---------|
| Native macOS | Node.js 22+, `openclaw` CLI, `curl` |
| Docker | Docker Desktop với Compose |

Cả hai chế độ đều cần:
- HashiCorp Vault (local hoặc Docker) để lưu secrets
- 9Router chạy local (port `20128`) hoặc API key LLM trực tiếp
- Telegram Bot Token + User ID để giao tiếp

---

## Cấu trúc thư mục

```
openclaw_manager/
├── skills/                    # Các agent skill (39 skills)
│   ├── ai-quota-check/        # Unified AI quota monitor & model recommender
│   ├── antigravity-control/   # Hand off projects/files to Google Antigravity
│   ├── brandkit/              # Taste-skill: premium brand-kit image generation
│   ├── browser_automation/    # Browser automation, screenshot, web research
│   ├── brutalist-skill/       # Taste-skill: industrial/brutalist UI direction
│   ├── codebase_intelligence/ # Repo map, code navigation (Atris-style)
│   ├── commander/             # Điều phối Commander → worker agents
│   ├── communication/         # Telegram, Messenger, Zalo, Gmail
│   ├── cv_job_hunter/         # CV management & job hunting automation
│   ├── data-qa-knowledge-curator/ # Crawl & digest Data QA knowledge hàng ngày
│   ├── devops/                # CI/CD, Azure DevOps, Git workflow
│   ├── document_analysis/     # PDF/image extraction, OCR-style
│   ├── document_visual_summarizer/ # Summarize long docs with screenshots
│   ├── email_assistant/       # Gmail triage, draft, send
│   ├── english_learning_planner/ # Kế hoạch học tiếng Anh
│   ├── figma_product_design/  # Figma UI design, review, design-to-code
│   ├── google_workspace/      # Gmail, Drive, Sheets, Calendar
│   ├── gpt-tasteskill/        # Taste-skill: GSAP/motion-heavy frontend design
│   ├── hanoi-date-spot-finder/ # Date/hangout spot recommendations in Hanoi
│   ├── image-to-code-skill/   # Taste-skill: image-first website implementation
│   ├── imagegen-frontend-mobile/ # Taste-skill: mobile UI image generation
│   ├── imagegen-frontend-web/ # Taste-skill: web UI image generation
│   ├── linkedin/              # LinkedIn automation via browser relay
│   ├── memory/                # Local memory, không lưu secret
│   ├── minimalist-skill/      # Taste-skill: minimalist high-end UI direction
│   ├── mobile_app_factory/    # Build mobile apps end-to-end (8 workers)
│   ├── output-skill/          # Taste-skill: full-output enforcement
│   ├── planner/               # Daily/weekly planning
│   ├── product-finder/        # Product search & comparison across marketplaces
│   ├── redesign-skill/        # Taste-skill: redesign existing projects
│   ├── research/              # Web search, browser automation
│   ├── shopping_research/     # Săn sale, so sánh giá
│   ├── soft-skill/            # Taste-skill: soft/high-end visual design
│   ├── stitch-skill/          # Taste-skill: Google Stitch DESIGN.md generation
│   ├── task_manager/          # Jira integration
│   ├── taste-skill/           # Taste-skill v2: design-taste-frontend
│   ├── taste-skill-v1/        # Taste-skill v1 compatibility
│   ├── travel_flights/        # Tìm chuyến bay, khách sạn (Amadeus)
│   └── trolymail/             # Invoice/billing email workflows
├── scripts/
│   ├── add_skill.sh           # Script hỗ trợ thêm skill mới
│   ├── validate_skill.sh      # Kiểm tra skill trước khi chạy
│   ├── list_skills.sh         # Liệt kê tất cả skill hiện tại
│   ├── task_registry.js       # Task registry + approval broker JSONL/state
│   ├── sync_9router_from_vault.js   # Sync 9Router config từ Vault
│   ├── sync_gmail_from_vault.js     # Sync Gmail secrets từ Vault
│   ├── openclaw_gateway_wrapper.sh  # Wrapper khởi động gateway
│   ├── openclaw_self_heal.js        # Auto-restart nếu gateway crash
│   └── setup_himalaya_gmail.js      # Setup himalaya CLI cho Gmail
├── config/
│   ├── policies.yaml          # Security & network policy
│   ├── openclaw.json          # OpenClaw base config
│   └── multi-agent.json       # Policy riêng cho Commander/Workers/approval
├── agents/
│   ├── commander.md           # Role definition cho bot chỉ huy
│   └── workers/               # Role definitions cho worker bots
├── data/
│   ├── tasks/                 # Local task registry state/events
│   └── approvals/             # Approval broker state/events
├── tools/
│   └── figma-mcp/             # Figma MCP tool integration
├── vault/
│   └── config/vault.json      # Vault server config
├── atris/MAP.md               # Codebase navigation map
├── docs/
│   ├── skill-integration-guide.md   # Hướng dẫn tích hợp skill mới
│   ├── skill-security-review.md
│   ├── multi-agent-orchestration.md
│   ├── multi-device-access.md
│   └── openclaw-operations.md
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh              # Docker: fetch Vault secrets → start gateway
├── start_native.sh            # Native macOS: setup env → start gateway
├── patch_openclaw_rate_limit_retry.js
└── openclaw_data/             # Runtime state (gitignored)
```


### Taste Skill Frontend Design Pack

Bộ skill từ [`Leonxlnx/taste-skill`](https://github.com/Leonxlnx/taste-skill) đã được tích hợp vào `skills/` để tăng chất lượng thiết kế UI/frontend:

- `taste-skill/` (`design-taste-frontend`) — default v2 cho premium frontend/UI generation.
- `taste-skill-v1/` (`design-taste-frontend-v1`) — bản v1 để tương thích hành vi cũ.
- `gpt-tasteskill/` (`gpt-taste`) — UX/UI + GSAP motion engineering.
- `image-to-code-skill/`, `imagegen-frontend-web/`, `imagegen-frontend-mobile/` — image-first design/code workflows.
- Visual style packs: `brandkit/`, `redesign-skill/`, `soft-skill/`, `minimalist-skill/`, `brutalist-skill/`, `output-skill/`, `stitch-skill/`.

Các skill này được load qua cơ chế skills chuẩn của OpenClaw sau khi gateway/session reload.

---

## Quick Start — Native macOS (khuyến nghị)

### 1. Clone repo

```bash
git clone <repo-url>
cd openclaw_manager
```

### 2. Cấu hình `.env`

```bash
cp .env.example .env
# Chỉnh sửa .env với các giá trị thực
```

Các biến bắt buộc tối thiểu:

```dotenv
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
TELEGRAM_ALLOWED_USERS=your_telegram_user_id

# 9Router (LLM router local)
NINE_ROUTER_API_KEY=your_9router_api_key
NINE_ROUTER_BASE_URL=http://127.0.0.1:20128/v1
NINE_ROUTER_MODEL=oc1
```

### 3. Khởi động

```bash
./start_native.sh
```

Script sẽ tự động:
- Nạp `.env`
- Fetch secrets từ Vault nếu có `VAULT_TOKEN` hoặc `~/.vault-token`
- Cài `openclaw`, `playwright`, `pnpm` nếu chưa có
- Symlink `skills/` vào agent workspace
- Ghi config vào `openclaw_data/openclaw.json`
- Khởi động gateway trên port `18789`

### 4. Kiểm tra

```bash
# Kiểm tra gateway đang chạy
lsof -nP -iTCP:18789 -sTCP:LISTEN

# Xem log
tail -f openclaw_data/native.log
```

Nếu muốn gateway chạy nền ổn định sau khi đóng terminal, dùng `screen`:

```bash
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
screen -ls
```

Nếu gateway đã được cài bằng launchd, `./start_native.sh` sẽ refresh config/secrets, tự restart service, rồi chờ port `18789` có PID mới. Nếu cần kiểm tra thêm:

```bash
tail -80 ~/.openclaw/logs/gateway.log
```

Restart:

```bash
screen -S openclaw-gateway -X quit
sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

---

## Quick Start — Docker

### 1. Khởi động services

```bash
docker compose up -d --build
docker compose ps
```

Vault UI: `http://127.0.0.1:8200`

### 2. Init Vault (lần đầu)

```bash
docker exec -it openclaw_vault vault operator init
docker exec -it openclaw_vault vault operator unseal <UNSEAL_KEY_1>
docker exec -it openclaw_vault vault operator unseal <UNSEAL_KEY_2>
docker exec -it openclaw_vault vault operator unseal <UNSEAL_KEY_3>
```

Lưu `Initial Root Token` ở nơi an toàn.

### 3. Ghi secrets vào Vault

```bash
docker exec -it openclaw_vault vault login <ROOT_TOKEN>
docker exec -it openclaw_vault vault kv put openclaw_secrets/api_keys \
  TELEGRAM_BOT_TOKEN="xxx" \
  TELEGRAM_ALLOWED_USERS="your_user_id" \
  NINE_ROUTER_API_KEY="xxx" \
  NINE_ROUTER_BASE_URL="http://127.0.0.1:20128/v1" \
  NINE_ROUTER_MODEL="oc1" \
  JIRA_BASE_URL="https://your-domain.atlassian.net" \
  JIRA_USER_EMAIL="you@company.com" \
  JIRA_API_TOKEN="xxx" \
  GMAIL_ACCOUNT="you@gmail.com" \
  GMAIL_USER="you@gmail.com" \
  GMAIL_APP_PASSWORD="xxxx xxxx xxxx xxxx" \
  AZURE_DEVOPS_ORG_URL="https://dev.azure.com/your-org" \
  AZURE_DEVOPS_PAT="xxx" \
  MS_TENANT_ID="xxx" \
  MS_CLIENT_ID="xxx" \
  MS_CLIENT_SECRET="xxx" \
  FIGMA_API_TOKEN="xxx" \
  BROWSERACT_API_KEY="xxx" \
  APIFY_TOKEN="xxx" \
  AMADEUS_API_KEY="xxx" \
  AMADEUS_API_SECRET="xxx"
```

### 4. Khởi động OpenClaw với Vault token

```bash
export VAULT_TOKEN='<VAULT_TOKEN>'
docker compose up -d --build --force-recreate openclaw
```

### 5. Kiểm tra

```bash
docker logs --tail 80 openclaw_agent
# Tìm dòng: "Secrets successfully loaded into RAM environment."
```

---

## LLM — 9Router

Project dùng **9Router** làm LLM router chính. 9Router là một OpenAI-compatible proxy chạy local, quản lý model rotation, fallback, và rate limit tự động.

```dotenv
NINE_ROUTER_API_KEY=your_9router_dashboard_api_key
NINE_ROUTER_BASE_URL=http://127.0.0.1:20128/v1
NINE_ROUTER_MODEL=oc1   # hoặc combo model khác trên 9Router dashboard
```

Sync 9Router config từ Vault vào runtime:

```bash
export VAULT_TOKEN='<token>'
node scripts/sync_9router_from_vault.js
```

---

## Skills (Agents)

### Multi-Agent Orchestration

OpenClaw Manager dùng mô hình **1 Commander + nhiều Worker Agents**:

- Commander nhận lệnh từ Telegram/mobile/web, chia task, chọn worker, tạo approval request, và tổng hợp kết quả.
- Worker chỉ làm việc chuyên môn theo role trong `agents/workers/*.md`.
- Orchestration policy nằm ở `config/multi-agent.json`; không nhét vào `openclaw.json` để tránh lỗi schema gateway.
- Task state được lưu tại `data/tasks/`; approval state được lưu tại `data/approvals/`.
- Các action rủi ro như gửi email, mailbox mutation, post/purchase/booking, deploy, destructive change, git push, hoặc sửa note quan trọng phải đi qua approval broker.
- Subagent concurrency mặc định được nâng lên `4`; main concurrency giữ thấp để Commander vẫn là điểm điều phối.

Tài liệu chi tiết:

- `docs/multi-agent-orchestration.md`
- `docs/multi-device-access.md`
- `docs/openclaw-operations.md`

### Cấu trúc vận hành

Các file chính:

| File/folder | Mục đích |
|-------------|----------|
| `agents/commander.md` | Role của bot chỉ huy |
| `agents/workers/*.md` | Role của từng worker |
| `skills/commander/SKILL.md` | Skill điều phối để OpenClaw biết cách chia việc |
| `config/multi-agent.json` | Policy orchestration/approval, tách khỏi `openclaw.json` |
| `scripts/task_registry.js` | CLI quản lý task registry và approval broker |
| `data/tasks/` | Runtime task state/events |
| `data/approvals/` | Runtime approval state/events |

Các file runtime trong `data/tasks/*.json`, `data/tasks/*.jsonl`, `data/approvals/*.json`, `data/approvals/*.jsonl` đã được `.gitignore`.

### Danh sách Skills (26 skills)

| Skill | Mô tả |
|-------|-------|
| `ai-quota-check` | Unified AI quota monitor, model recommender cho nhiều provider |
| `antigravity-control` | Hand off projects/files sang Google Antigravity IDE |
| `browser_automation` | Browser automation, screenshot, public web research |
| `codebase_intelligence` | Repo map (Atris-style), code navigation |
| `commander` | Điều phối end-to-end qua worker agents, task registry, approval broker |
| `communication` | Telegram, Messenger, Zalo, Gmail đa kênh |
| `cv_job_hunter` | CV management, job hunting, interview prep automation |
| `data-qa-knowledge-curator` | Crawl Reddit/GitHub/Twitter/SO, digest Data QA hàng ngày |
| `devops` | CI/CD, Azure DevOps, Git workflow, build failure analysis |
| `document_analysis` | PDF/image extraction, OCR-style, structured summaries |
| `document_visual_summarizer` | Summarize long docs/websites kèm screenshots |
| `email_assistant` | Gmail triage, draft, send với approval |
| `english_learning_planner` | Kế hoạch học tiếng Anh cá nhân |
| `figma_product_design` | Figma UI design, review, accessibility, design-to-code |
| `google_workspace` | Gmail, Drive, Sheets, Calendar |
| `hanoi-date-spot-finder` | Tìm địa điểm hẹn hò/hangout ở Hà Nội |
| `linkedin` | LinkedIn automation qua browser relay/cookies |
| `memory` | Local memory, không lưu secret |
| `mobile_app_factory` | Build mobile apps end-to-end (1 commander + 8 workers) |
| `planner` | Daily/weekly planning, end-of-day summary |
| `product-finder` | Product search & comparison across marketplaces (VN & global) |
| `research` | Web search, browser automation, source-backed research |
| `shopping_research` | Săn sale, so sánh giá (Amazon/BrowserAct/Apify) |
| `task_manager` | Jira: track, update, transition, assign |
| `travel_flights` | Tìm và so sánh chuyến bay, khách sạn (Amadeus + OTAs) |
| `trolymail` | Invoice/billing email, attachment download, Drive filing |

> Sau khi thêm hoặc sửa skill, restart gateway để OpenClaw nạp lại.

---

## Tích hợp Skill mới

Hướng dẫn chi tiết cách thêm một skill bên ngoài vào OpenClaw Manager.

### Cách OpenClaw nạp skill

OpenClaw scan thư mục `skills/` tìm các folder chứa file `SKILL.md`. File này dùng YAML frontmatter để khai báo metadata:

```yaml
---
name: tên-skill
description: Mô tả ngắn gọn khi nào nên dùng skill này.
tools:
  - tool_name_1
  - tool_name_2
---
```

Phần body Markdown phía dưới frontmatter là instruction cho agent.

### Ví dụ: Tích hợp taste-skill từ GitHub

[taste-skill](https://github.com/Leonxlnx/taste-skill) là một bộ "anti-slop" frontend agent skill giúp AI tạo UI đẹp hơn thay vì generic boilerplate.

#### Bước 1: Clone skill vào thư mục skills

```bash
# Dùng script hỗ trợ (khuyến nghị)
./scripts/add_skill.sh https://github.com/Leonxlnx/taste-skill taste-skill

# Hoặc clone thủ công
cd skills/
git clone https://github.com/Leonxlnx/taste-skill taste-skill
cd ..
```

#### Bước 2: Kiểm tra cấu trúc skill

Mỗi skill hợp lệ phải có ít nhất `SKILL.md` với YAML frontmatter:

```bash
# Dùng script validate
./scripts/validate_skill.sh taste-skill

# Hoặc kiểm tra thủ công
cat skills/taste-skill/skills/taste-skill/SKILL.md | head -10
```

Nếu skill từ GitHub có cấu trúc nested (`skills/<name>/SKILL.md` bên trong repo), cần symlink hoặc copy file `SKILL.md` ra đúng vị trí:

```bash
# Nếu repo có cấu trúc: taste-skill/skills/taste-skill/SKILL.md
# Thì cần tạo SKILL.md ở gốc folder skill
cp skills/taste-skill/skills/taste-skill/SKILL.md skills/taste-skill/SKILL.md
```

#### Bước 3: Thêm network domains vào whitelist (nếu cần)

Nếu skill cần gọi API bên ngoài, thêm domain vào `config/policies.yaml`:

```yaml
security:
  network:
    allowlist_domains:
      # ... existing domains ...
      - "tasteskill.dev"         # Nếu skill cần gọi API
      - "*.tasteskill.dev"
```

> Với `taste-skill` cụ thể thì không cần bước này vì nó chỉ tạo code instructions, không gọi external API.

#### Bước 4: Thêm env vars (nếu skill cần API keys)

Nếu skill cần API key riêng:

1. Thêm vào `.env`:

```dotenv
TASTE_SKILL_API_KEY=your_api_key_here
```

2. Thêm vào Vault (nếu dùng Vault):

```bash
docker exec -it openclaw_vault vault kv patch openclaw_secrets/api_keys \
  TASTE_SKILL_API_KEY="your_api_key_here"
```

3. Thêm key vào danh sách env forwarding trong `start_native.sh` (block `for (const key of [...])`):

```javascript
// Trong start_native.sh, node heredoc, thêm vào mảng env vars:
"TASTE_SKILL_API_KEY",
```

> Với `taste-skill` cụ thể thì không cần bước này vì nó chỉ là prompt instructions.

#### Bước 5: Đăng ký worker mới (nếu cần orchestration)

Nếu skill mới cần được Commander điều phối:

1. Tạo worker role definition tại `agents/workers/<skill-name>-worker.md`:

```markdown
# Taste Worker

You are the Taste Worker. Your job is to apply design-taste-frontend
guidelines to UI code before it ships.

## When to invoke
- User asks for UI polish, anti-slop, or "make it look good"
- Commander routes a frontend design task

## Deliverables
- Refactored UI code with taste-skill guidelines applied
- Before/after diff summary
```

2. Cập nhật `skills/commander/SKILL.md`, thêm vào section Routing:

```markdown
- Frontend polish, anti-slop UI, design taste: `taste-worker`
```

3. Thêm worker vào Required Context:

```markdown
- `agents/workers/taste-worker.md`
```

#### Bước 6: Validate và restart

```bash
# Validate skill
./scripts/validate_skill.sh taste-skill

# Liệt kê tất cả skills để confirm
./scripts/list_skills.sh

# Restart gateway
screen -S openclaw-gateway -X quit
sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

#### Bước 7: Test skill

Nhắn bot Telegram:

```text
Áp dụng taste-skill guidelines cho trang login hiện tại
```

Hoặc nếu Commander điều phối:

```text
Polish UI cho toàn bộ frontend theo anti-slop guidelines
```

### Checklist thêm skill mới

```
□ SKILL.md có YAML frontmatter (name, description)
□ SKILL.md body có instructions rõ ràng
□ Folder nằm trong skills/ (đúng level, không nested quá sâu)
□ Network domains đã whitelist (nếu cần external API)
□ Env vars đã thêm vào .env + Vault + start_native.sh (nếu cần)
□ Worker role file tạo trong agents/workers/ (nếu cần orchestration)
□ Commander SKILL.md đã cập nhật routing (nếu cần)
□ Gateway đã restart
□ Test qua Telegram thành công
```

Xem thêm: `docs/skill-integration-guide.md` cho hướng dẫn chi tiết hơn.

---

## Tích hợp dịch vụ

### Telegram (giao diện chính)
- `TELEGRAM_BOT_TOKEN`: token từ @BotFather
- `TELEGRAM_ALLOWED_USERS`: danh sách user ID được phép (phân cách bằng dấu phẩy)

#### Thêm mobile Telegram mới

Nếu mobile mới dùng **cùng Telegram account**, thường không cần cấu hình thêm vì numeric user ID không đổi.

Nếu mobile mới dùng **Telegram account khác**, làm như sau:

1. Trên mobile mới, mở Telegram.
2. Tìm một bot lấy ID như `@userinfobot`, `@RawDataBot`, hoặc `@getidsbot`.
3. Bấm Start và ghi lại trường `id`, ví dụ:

```text
1234567890
```

4. Thêm ID vào `openclaw_data/openclaw.json`:

```json
"channels": {
  "telegram": {
    "dmPolicy": "allowlist",
    "allowFrom": [
      "1597126604",
      "1234567890"
    ]
  }
}
```

5. Chỉ nếu thiết bị đó được quyền approve hành động rủi ro, thêm vào `ownerAllowFrom`:

```json
"commands": {
  "ownerAllowFrom": [
    "telegram:1597126604",
    "telegram:1234567890"
  ]
}
```

6. Restart gateway:

```bash
screen -S openclaw-gateway -X quit
sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

7. Trên mobile mới, nhắn bot Telegram hiện tại:

```text
@openclaw_2303_bot
```

Gửi:

```text
ping
```

Chi tiết hơn: xem `docs/multi-device-access.md`.

### Jira
- `JIRA_BASE_URL`, `JIRA_USER_EMAIL`, `JIRA_API_TOKEN`
- Task Manager Agent hỗ trợ đọc, transition, assign, comment qua API

### Azure DevOps
- `AZURE_DEVOPS_ORG_URL`, `AZURE_DEVOPS_ORG`, `AZURE_DEVOPS_PROJECT`, `AZURE_DEVOPS_PAT`

### Microsoft Teams / Graph API
- `MS_TENANT_ID`, `MS_CLIENT_ID`, `MS_CLIENT_SECRET`, `TEAMS_USER_EMAIL`
- App Registration trên Entra ID cần admin consent cho Graph permissions

### Gmail / Google Workspace
- Đọc/tóm tắt: `GMAIL_ACCOUNT`
- SMTP/IMAP app-password: `GMAIL_USER`, `GMAIL_APP_PASSWORD`
- Gmail CLI dùng `himalaya` (setup qua `scripts/setup_himalaya_gmail.js`)

### Figma
- `FIGMA_API_TOKEN`, `FIGMA_FILE_KEY`
- Optional: `FIGMA_TEAM_ID`, `FIGMA_ORG_ID`
- MCP tool integration tại `tools/figma-mcp/`

### Shopping
- BrowserAct: `BROWSERACT_API_KEY`
- Apify: `APIFY_TOKEN`
- Bot chỉ nghiên cứu/so sánh giá; checkout cần xác nhận thủ công

### Flights / Travel
- `AMADEUS_API_KEY`, `AMADEUS_API_SECRET`
- Sandbox: `AMADEUS_BASE_URL=https://test.api.amadeus.com`
- Production: `AMADEUS_BASE_URL=https://api.amadeus.com`
- Bot chỉ tìm/so sánh; booking cần xác nhận thủ công

### Data QA Knowledge Curator
- Crawl Reddit, Twitter/X, GitHub, blogs, Stack Overflow
- Gửi digest hàng ngày qua Telegram lúc 7:00 AM (Asia/Saigon)
- Setup: xem `skills/data-qa-knowledge-curator/SETUP_GUIDE.md`

---

## Security & HITL Policy

Tất cả các hành động nhạy cảm đều yêu cầu xác nhận thủ công (Human-In-The-Loop):

| Hành động | HITL |
|-----------|------|
| Xóa file | ✅ |
| System commands | ✅ |
| External API write | ✅ |
| Browser form submit | ✅ |
| Gửi email | ✅ |
| Outbound messaging | ✅ |
| Checkout / payment | ✅ |
| Travel booking | ✅ |
| Git push | ✅ |
| VM execution | ✅ |

Cấu hình trong `.env`:

```dotenv
HITL_FILE_DELETION=1
HITL_SYSTEM_COMMANDS=1
HITL_EXTERNAL_API=1
```

Network policy chỉ cho phép các domain đã whitelist (xem `config/policies.yaml`).

---

## Scripts tiện ích

| Script | Mục đích |
|--------|---------|
| `scripts/add_skill.sh` | Thêm skill mới từ GitHub repo |
| `scripts/validate_skill.sh` | Validate cấu trúc skill trước khi chạy |
| `scripts/list_skills.sh` | Liệt kê tất cả skill và status |
| `start_native.sh` | Khởi động gateway native macOS |
| `scripts/sync_9router_from_vault.js` | Sync 9Router config từ Vault |
| `scripts/sync_gmail_from_vault.js` | Sync Gmail secrets từ Vault |
| `scripts/setup_himalaya_gmail.js` | Setup himalaya CLI cho Gmail |
| `scripts/openclaw_self_heal.js` | Auto-restart gateway nếu crash |
| `scripts/openclaw_gateway_wrapper.sh` | Wrapper script cho gateway |
| `patch_openclaw_rate_limit_retry.js` | Patch rate limit retry cho OpenClaw |
| `restart.js` | Restart gateway |
| `get_logs.js` | Lấy logs từ gateway |

---

## Xử lý lỗi thường gặp

**`VAULT_TOKEN is not set, skipping Vault secret fetch`**

```bash
export VAULT_TOKEN='<token>'
./start_native.sh
# hoặc Docker:
docker compose up -d --build --force-recreate openclaw
```

**Port 18789 đã bị chiếm**

```bash
lsof -nP -iTCP:18789 -sTCP:LISTEN
launchctl kickstart -k gui/$(id -u)/ai.openclaw.gateway
tail -80 ~/.openclaw/logs/gateway.log
```

**Browser tool lỗi trong container**

```bash
docker compose up -d --build --force-recreate openclaw
docker logs --tail 120 openclaw_agent
```

**GitHub push lỗi `Permission denied (publickey)`**

```bash
ssh -T git@github.com
# Kiểm tra SSH key và host alias trong ~/.ssh/config
```

**9Router không kết nối được**

```bash
# Kiểm tra 9Router đang chạy
lsof -nP -iTCP:20128 -sTCP:LISTEN
# Sync lại config
node scripts/sync_9router_from_vault.js
```

**Skill mới không được nạp sau restart**

```bash
# Kiểm tra SKILL.md tồn tại
./scripts/validate_skill.sh <tên-skill>

# Kiểm tra symlink skills/ trong agent workspace
ls -la openclaw_data/.openclaw/workspace/skills/

# Force re-symlink
ln -sfn "$(pwd)/skills" "$(pwd)/openclaw_data/.openclaw/workspace/skills"

# Restart gateway
screen -S openclaw-gateway -X quit
sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

---

## Bảo mật bắt buộc

- Không commit token hoặc secret vào git.
- `openclaw_data/` đã gitignore để tránh đẩy runtime state lên remote.
- Chỉ lưu secrets trong Vault hoặc env runtime; rotate ngay nếu lộ ra log/file.
- File `*.bak` có thể chứa dữ liệu nhạy cảm, không lưu trữ lâu dài.
- Bất kỳ agent nào có quyền đọc workspace đều có thể đọc plaintext trong repo local.

---

## Tham khảo thêm

- `atris/MAP.md` — Codebase navigation map, entry points, và file references
- `docs/skill-integration-guide.md` — Hướng dẫn chi tiết tích hợp skill mới
- `docs/skill-security-review.md` — Security review cho từng skill
- `skills/data-qa-knowledge-curator/SETUP_GUIDE.md` — Hướng dẫn setup Data QA curator
- `config/policies.yaml` — Toàn bộ security & network policy
