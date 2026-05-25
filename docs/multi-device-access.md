# Hướng Dẫn Kết Nối Nhiều Thiết Bị

Tài liệu này mô tả cách cho nhiều thiết bị/mobile ra lệnh cho OpenClaw qua Telegram hoặc Control UI, và cách phân quyền để tránh thiết bị phụ có quyền quá cao.

## Mô Hình Quyền

Có 2 lớp quyền khác nhau:

- **Được nhắn bot**: user/device nằm trong allowlist, có thể gửi yêu cầu cho OpenClaw.
- **Được approve hành động rủi ro**: user/device có quyền owner/admin, có thể duyệt gửi email, deploy, xóa/move dữ liệu, booking, purchase, post bên ngoài.

Khuyến nghị:

- Thiết bị phụ hoặc người dùng phụ: chỉ thêm vào `allowFrom`.
- Thiết bị chính của Danny: thêm vào cả `allowFrom` và `ownerAllowFrom`.
- Không thêm người khác vào `ownerAllowFrom` nếu không muốn họ duyệt hành động nhạy cảm.

## Kết Nối Mobile Qua Telegram

### Bước 1: Lấy Telegram Numeric User ID

Trên mobile mới:

1. Mở Telegram.
2. Tìm một trong các bot:
   - `@userinfobot`
   - `@RawDataBot`
   - `@getidsbot`
3. Bấm Start hoặc gửi bất kỳ tin nhắn nào.
4. Ghi lại trường `id`.

Ví dụ ID:

```text
1234567890
```

Lưu ý:

- Cần **numeric user ID**, không phải username `@abc`.
- Nếu dùng cùng Telegram account trên nhiều mobile thì ID không đổi, thường không cần cấu hình thêm.
- Nếu là Telegram account khác, bắt buộc phải thêm ID mới vào allowlist.

### Bước 2: Thêm ID Vào Allowlist

File runtime native:

```text
openclaw_data/openclaw.json
```

Tìm:

```json
"channels": {
  "telegram": {
    "dmPolicy": "allowlist",
    "allowFrom": [
      "1597126604"
    ]
  }
}
```

Thêm user ID mới:

```json
"allowFrom": [
  "1597126604",
  "1234567890"
]
```

Với Docker hoặc setup từ `.env`, cũng có thể thêm vào:

```dotenv
TELEGRAM_ALLOWED_USERS=1597126604,1234567890
```

### Bước 3: Chọn Mức Quyền

Chỉ cho phép nhắn bot:

```json
"allowFrom": [
  "1597126604",
  "1234567890"
]
```

Cho phép approve hành động rủi ro:

```json
"commands": {
  "ownerAllowFrom": [
    "telegram:1597126604",
    "telegram:1234567890"
  ]
}
```

Nếu chưa chắc, chỉ thêm vào `allowFrom`.

### Bước 4: Restart Gateway

Nếu gateway đang chạy bằng `screen`:

```bash
screen -S openclaw-gateway -X quit
screen -dmS openclaw-gateway bash -lc './start_native.sh > openclaw_data/native.log 2>&1'
```

Kiểm tra:

```bash
lsof -nP -iTCP:18789 -sTCP:LISTEN
tail -80 openclaw_data/native.log
```

### Bước 5: Test Từ Mobile Mới

Trên mobile mới, mở bot Telegram hiện tại:

```text
@openclaw_2303_bot
```

Gửi:

```text
ping
```

Nếu ID đã đúng trong allowlist, OpenClaw sẽ phản hồi.

## Kết Nối Qua Web/Mobile Control UI

Nếu muốn mobile truy cập Control UI thay vì Telegram:

1. Không mở port gateway trực tiếp ra internet.
2. Dùng một lớp mạng riêng/bảo vệ:
   - Tailscale
   - WireGuard
   - Cloudflare Access
3. Pair từng thiết bị riêng.
4. Gán scope nhỏ nhất có thể.

Các scope thường gặp:

- `operator.read`: chỉ xem trạng thái.
- `operator.write`: tạo command/task.
- `operator.approvals`: approve hành động rủi ro.
- `operator.admin`: admin/pair/config, chỉ nên dùng cho thiết bị chính.

File paired devices:

```text
openclaw_data/.openclaw/devices/paired.json
```

Không nên sửa file này thủ công nếu có thể pair qua UI. Chỉ đọc để kiểm tra thiết bị đã được pair và scope hiện tại.

## Requester Identity

Commander nên lưu người/thiết bị mở task theo format:

```text
telegram:<numeric_id>
device:<device_id>
web:<session_id>
```

Ví dụ:

```text
telegram:1597126604
device:f93043365060...
```

Task nào do thiết bị nào tạo thì kết quả cuối trả về thiết bị/người đó. Quyền approve vẫn tách riêng theo `ownerAllowFrom` hoặc device scope.

## Checklist Khi Thêm Mobile Mới

- Đã lấy đúng numeric Telegram user ID.
- Đã thêm ID vào `allowFrom`.
- Chỉ thêm vào `ownerAllowFrom` nếu thiết bị đó được phép approve.
- Đã restart gateway.
- Đã test `ping` từ mobile mới.
- Nếu dùng Control UI, đã pair device và gán scope nhỏ nhất.

