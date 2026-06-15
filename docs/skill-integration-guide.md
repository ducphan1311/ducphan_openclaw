# Hướng dẫn tích hợp Skill mới vào OpenClaw Manager

Tài liệu chi tiết cách thêm, cấu hình, và vận hành một skill bên ngoài trong hệ thống OpenClaw Manager.

---

## 1. Skill là gì?

Trong OpenClaw, một **skill** là một agent chuyên biệt được khai báo qua file `SKILL.md`. Gateway scan thư mục `skills/` khi khởi động và nạp tất cả các skill hợp lệ.

### Cấu trúc tối thiểu

```
skills/
└── my-new-skill/
    └── SKILL.md          # BẮT BUỘC — khai báo skill
```

### Cấu trúc đầy đủ (recommended)

```
skills/
└── my-new-skill/
    ├── SKILL.md          # Khai báo skill + instructions
    ├── README.md         # Docs cho developers
    ├── index.js          # Script thực thi (nếu có)
    ├── _meta.json        # Metadata bổ sung (optional)
    ├── references/       # Tài liệu tham khảo
    ├── templates/        # Template files
    └── scripts/          # Helper scripts riêng
```

---

## 2. Anatomy của SKILL.md

```markdown
---
name: my-new-skill
description: Mô tả ngắn gọn. OpenClaw dùng description này để quyết định khi nào invoke skill.
tools:
  - web_search
  - web_fetch
  - browser_automation
metadata: {"emoji": "🔧", "requires": {"bins": ["node"]}}
---

# My New Skill

Body content — instructions chi tiết cho agent khi skill được invoke.

## Khi nào dùng
- User hỏi X
- Commander route task Y

## Cách thực thi
1. Bước 1...
2. Bước 2...

## Output format
- Trả kết quả dạng markdown
- Include source links
```

### Giải thích các field

| Field | Required | Mô tả |
|-------|----------|-------|
| `name` | ✅ | Tên unique của skill (lowercase, dashes OK) |
| `description` | ✅ | OpenClaw dùng để routing — viết rõ ràng khi nào nên dùng |
| `tools` | ❌ | Danh sách tool được phép dùng. Bỏ trống = dùng tất cả |
| `metadata` | ❌ | JSON object cho custom config (emoji, dependencies...) |

> **Tip**: `description` cực kỳ quan trọng — đây là cách OpenClaw quyết định có invoke skill hay không. Viết mô tả giống user intent, include keywords user hay nói.

---

## 3. Thêm skill từ GitHub (ví dụ taste-skill)

### Bước 1: Dùng script add_skill.sh

```bash
./scripts/add_skill.sh https://github.com/Leonxlnx/taste-skill taste-skill
```

Script sẽ:
- Clone repo (shallow, depth=1)
- Xóa `.git` (tránh nested repo)
- Tìm và copy `SKILL.md` nếu nằm ở subdirectory
- Chạy validation cơ bản
- In checklist các bước tiếp theo

### Bước 2: Xử lý cấu trúc nested

Nhiều skill repo trên GitHub có cấu trúc:

```
taste-skill/                    # ← repo root
├── skills/
│   ├── taste-skill/
│   │   └── SKILL.md           # ← skill thực sự ở đây
│   └── taste-skill-v1/
│       └── SKILL.md
├── README.md
└── assets/
```

OpenClaw cần `SKILL.md` ở **root** của folder skill:

```
skills/taste-skill/SKILL.md    # ← OpenClaw tìm ở đây
```

`add_skill.sh` tự động xử lý case này. Nếu cần thủ công:

```bash
# Chọn skill cụ thể từ repo có nhiều skills
cp skills/taste-skill/skills/taste-skill/SKILL.md skills/taste-skill/SKILL.md
```

### Bước 3: Validate

```bash
./scripts/validate_skill.sh taste-skill
```

Output mẫu:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Validating: taste-skill
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ PASS  Folder exists: skills/taste-skill/
  ✓ PASS  SKILL.md exists
  ✓ PASS  YAML frontmatter detected
  ✓ PASS  name: design-taste-frontend
  ✓ PASS  description: Reads the brief, infers design language...
  ✓ PASS  Frontmatter properly closed
  ✓ PASS  Body content: 85 non-empty lines
  ✓ PASS  No nested .git directory
  ✓ PASS  README.md present
  ✓ PASS  Structure: 12 files in 4 directories
  ✓ PASS  SKILL.md size: 4200 bytes

  Summary: 11 passed, 0 warnings, 0 failed
```

---

## 4. Cấu hình network (nếu skill gọi external API)

OpenClaw enforce network whitelist qua `config/policies.yaml`. Nếu skill mới cần gọi API bên ngoài:

```yaml
# config/policies.yaml
security:
  network:
    allowlist_domains:
      # ... existing domains ...
      - "api.newservice.com"
      - "*.newservice.com"
```

> Với `taste-skill`, bước này **không cần** vì nó chỉ generate prompt/code, không gọi API.

---

## 5. Thêm environment variables

Nếu skill cần API keys hoặc config qua env vars:

### a. Thêm vào `.env`

```dotenv
# Trong .env
NEW_SKILL_API_KEY=your_key_here
NEW_SKILL_CONFIG=some_value
```

### b. Thêm vào `.env.example` (cho documentation)

```dotenv
# New Skill
NEW_SKILL_API_KEY=your_api_key
NEW_SKILL_CONFIG=default_value
```

### c. Thêm vào Vault (nếu dùng Vault)

```bash
docker exec -it openclaw_vault vault kv patch openclaw_secrets/api_keys \
  NEW_SKILL_API_KEY="your_key_here"
```

### d. Forward env vào runtime

Trong `start_native.sh`, tìm block `for (const key of [` và thêm:

```javascript
for (const key of [
  // ... existing keys ...
  "NEW_SKILL_API_KEY",      // ← thêm
  "NEW_SKILL_CONFIG",       // ← thêm
]) {
```

> Với `taste-skill`, bước này **không cần**.

---

## 6. Đăng ký Commander orchestration (optional)

Nếu muốn Commander điều phối skill mới:

### a. Tạo worker role

Tạo file `agents/workers/<skill-name>-worker.md`:

```markdown
# Taste Worker

You are the Taste Worker. Apply design-taste-frontend guidelines to
produce premium, anti-slop UIs.

## Khi nào
- User yêu cầu UI polish, anti-slop, premium design
- Commander route frontend beautification

## Deliverables
- Refactored UI code
- Before/after diff
- Design rationale
```

### b. Cập nhật Commander routing

Trong `skills/commander/SKILL.md`, thêm vào section **Routing**:

```markdown
## Routing

# ... existing entries ...
- Frontend polish, anti-slop UI, design taste: `taste-worker`
```

Thêm vào **Required Context**:

```markdown
## Required Context
# ... existing entries ...
- `agents/workers/taste-worker.md`
```

---

## 7. Restart và test

```bash
# Restart gateway
screen -S openclaw-gateway -X quit
sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'

# Kiểm tra gateway đã lên
lsof -nP -iTCP:18789 -sTCP:LISTEN

# Xem log để confirm skill loaded
tail -40 openclaw_data/native.log
```

Test qua Telegram:

```text
Áp dụng taste-skill cho component Button
```

---

## 8. Tạo skill mới từ đầu

Nếu muốn tạo skill hoàn toàn mới (không clone từ GitHub):

```bash
# Tạo folder
mkdir -p skills/my-awesome-skill

# Tạo SKILL.md
cat > skills/my-awesome-skill/SKILL.md << 'EOF'
---
name: my-awesome-skill
description: Does awesome things when user asks for X, Y, or Z.
---

# My Awesome Skill

Instructions cho agent...

## Khi nào dùng
- User hỏi...

## Cách thực thi
1. ...
2. ...
EOF

# Validate
./scripts/validate_skill.sh my-awesome-skill

# Restart gateway
screen -S openclaw-gateway -X quit && sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

---

## 9. Xóa skill

```bash
# Xóa folder
rm -rf skills/skill-to-remove

# Nếu có worker role, xóa luôn
rm -f agents/workers/skill-to-remove-worker.md

# Cập nhật Commander routing (bỏ entry tương ứng)
# Edit skills/commander/SKILL.md

# Restart gateway
screen -S openclaw-gateway -X quit && sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

---

## 10. Troubleshooting

### Skill không được nạp

```bash
# 1. Kiểm tra SKILL.md
./scripts/validate_skill.sh <skill-name>

# 2. Kiểm tra symlink
ls -la openclaw_data/.openclaw/workspace/skills/<skill-name>/

# 3. Force re-symlink
ln -sfn "$(pwd)/skills" "$(pwd)/openclaw_data/.openclaw/workspace/skills"

# 4. Restart gateway
screen -S openclaw-gateway -X quit && sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

### Skill bị invoke sai lúc

Cải thiện `description` trong frontmatter:
- Thêm trigger keywords cụ thể
- Dùng negative triggers: "Do NOT invoke for..."
- Test lại qua Telegram

### Skill cần binary/dependency

Khai báo trong `metadata`:

```yaml
metadata: {"requires": {"bins": ["node", "python3"]}}
```

Và đảm bảo binary đã cài trên máy host.

---

## Quick Reference

| Bước | File cần sửa | Khi nào |
|------|-------------|---------|
| Clone/tạo skill | `skills/<name>/SKILL.md` | Luôn luôn |
| Whitelist domain | `config/policies.yaml` | Skill gọi external API |
| Env vars | `.env` + `start_native.sh` | Skill cần API keys |
| Vault secrets | Vault KV store | Dùng Vault |
| Worker role | `agents/workers/<name>-worker.md` | Cần Commander routing |
| Commander routing | `skills/commander/SKILL.md` | Cần Commander routing |
| Restart gateway | N/A | Luôn luôn |
