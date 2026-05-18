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
- **Skills**: Các agent chuyên biệt, mỗi skill là một thư mục trong `skills/`.

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
├── skills/                    # Các agent skill
│   ├── browser_automation/    # Browser automation, screenshot, web research
│   ├── codebase_intelligence/ # Repo map, code navigation (Atris-style)
│   ├── communication/         # Telegram, Messenger, Zalo, Gmail
│   ├── data-qa-knowledge-curator/ # Crawl & digest Data QA knowledge hàng ngày
│   ├── devops/                # CI/CD, Azure DevOps, Git workflow
│   ├── document_analysis/     # PDF/image extraction, OCR-style
│   ├── email_assistant/       # Gmail triage, draft, send
│   ├── english_learning_planner/ # Kế hoạch học tiếng Anh
│   ├── google_workspace/      # Gmail, Drive, Sheets, Calendar
│   ├── memory/                # Local memory, không lưu secret
│   ├── planner/               # Daily/weekly planning
│   ├── research/              # Web search, browser automation
│   ├── shopping_research/     # Săn sale, so sánh giá
│   ├── task_manager/          # Jira integration
│   ├── travel_flights/        # Tìm chuyến bay (Amadeus)
│   └── trolymail/             # Invoice/billing email workflows
├── scripts/
│   ├── sync_9router_from_vault.js   # Sync 9Router config từ Vault
│   ├── sync_gmail_from_vault.js     # Sync Gmail secrets từ Vault
│   ├── openclaw_gateway_wrapper.sh  # Wrapper khởi động gateway
│   ├── openclaw_self_heal.js        # Auto-restart nếu gateway crash
│   └── setup_himalaya_gmail.js      # Setup himalaya CLI cho Gmail
├── config/
│   ├── policies.yaml          # Security & network policy
│   └── openclaw.json          # OpenClaw base config
├── vault/
│   └── config/vault.json      # Vault server config
├── atris/MAP.md               # Codebase navigation map
├── docs/skill-security-review.md
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh              # Docker: fetch Vault secrets → start gateway
├── start_native.sh            # Native macOS: setup env → start gateway
├── patch_openclaw_rate_limit_retry.js
└── openclaw_data/             # Runtime state (gitignored)
```

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

| Skill | Mô tả |
|-------|-------|
| `browser_automation` | Browser automation, screenshot, public web research |
| `codebase_intelligence` | Repo map (Atris-style), code navigation |
| `communication` | Telegram, Messenger, Zalo, Gmail đa kênh |
| `data-qa-knowledge-curator` | Crawl Reddit/GitHub/Twitter/SO, digest Data QA hàng ngày |
| `devops` | CI/CD, Azure DevOps, Git workflow, build failure analysis |
| `document_analysis` | PDF/image extraction, OCR-style, structured summaries |
| `email_assistant` | Gmail triage, draft, send với approval |
| `english_learning_planner` | Kế hoạch học tiếng Anh cá nhân |
| `google_workspace` | Gmail, Drive, Sheets, Calendar |
| `memory` | Local memory, không lưu secret |
| `planner` | Daily/weekly planning, end-of-day summary |
| `research` | Web search, browser automation, source-backed research |
| `shopping_research` | Săn sale, so sánh giá (Amazon/BrowserAct/Apify) |
| `task_manager` | Jira: track, update, transition, assign |
| `travel_flights` | Tìm và so sánh chuyến bay (Amadeus) |
| `trolymail` | Invoice/billing email, attachment download, Drive filing |

> Sau khi thêm hoặc sửa skill, restart gateway để OpenClaw nạp lại.

---

## Tích hợp dịch vụ

### Telegram (giao diện chính)
- `TELEGRAM_BOT_TOKEN`: token từ @BotFather
- `TELEGRAM_ALLOWED_USERS`: danh sách user ID được phép (phân cách bằng dấu phẩy)

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
kill $(lsof -tiTCP:18789 -sTCP:LISTEN) && sleep 3 && ./start_native.sh
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
- `docs/skill-security-review.md` — Security review cho từng skill
- `skills/data-qa-knowledge-curator/SETUP_GUIDE.md` — Hướng dẫn setup Data QA curator
- `config/policies.yaml` — Toàn bộ security & network policy
