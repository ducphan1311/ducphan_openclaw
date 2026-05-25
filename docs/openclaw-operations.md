# Hướng Dẫn Vận Hành OpenClaw Gateway

Tài liệu này dùng cho các thao tác restart, kiểm tra gateway, log, và lỗi thường gặp.

## Native Gateway

Gateway native chạy trên:

```text
127.0.0.1:18789
```

Browser control sidecar thường chạy trên:

```text
127.0.0.1:18791
```

## Start Gateway Bằng Screen

Cách khuyến nghị trên máy hiện tại là chạy qua detached `screen` để tiến trình không chết khi terminal đóng:

```bash
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

Kiểm tra screen:

```bash
screen -ls
```

Attach vào session nếu cần xem trực tiếp:

```bash
screen -r openclaw-gateway
```

Thoát khỏi screen mà không tắt gateway:

```text
Ctrl-A rồi D
```

Tắt gateway:

```bash
screen -S openclaw-gateway -X quit
```

## Kiểm Tra Gateway

Kiểm tra port:

```bash
lsof -nP -iTCP:18789 -sTCP:LISTEN
```

Xem log:

```bash
tail -80 openclaw_data/native.log
```

Log gateway chi tiết:

```bash
ls /tmp/openclaw/
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

## Restart Sau Khi Sửa Config/Skill

Sau khi sửa các file sau, nên restart gateway:

- `openclaw_data/openclaw.json`
- `config/openclaw.json`
- `start_native.sh`
- `scripts/openclaw_self_heal.js`
- `skills/*/SKILL.md`
- thêm/sửa skill mới

Lệnh restart:

```bash
screen -S openclaw-gateway -X quit
sleep 2
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
sleep 8
lsof -nP -iTCP:18789 -sTCP:LISTEN
tail -80 openclaw_data/native.log
```

## Lỗi Thường Gặp

### Gateway fail vì key lạ trong openclaw.json

Triệu chứng:

```text
Invalid config ... Unrecognized key: "multiAgent"
```

Cách xử lý:

- Không đặt custom orchestration policy trong `openclaw.json`.
- Đặt vào `config/multi-agent.json`.

### start_native.sh không chạy do quote lỗi

Kiểm tra syntax:

```bash
bash -n start_native.sh
```

Nếu lỗi ở đoạn Vault export, dùng helper:

```text
scripts/vault_exports.js
```

### Gateway không lên khi dùng nohup

Trong môi trường hiện tại, `nohup ./start_native.sh &` có thể không giữ được tiến trình. Dùng `screen` thay thế:

```bash
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

### Thiếu Gemini key nhưng vẫn có 9Router

Log có thể hiện:

```text
Warning: Gemini API key is not loaded.
nine_router_provider_configured=true
openclaw_default_model=9router/oc1
```

Nếu `nine_router_provider_configured=true` và gateway ready, cảnh báo Gemini không nhất thiết là blocker.

