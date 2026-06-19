# Hướng Dẫn Cấu Trúc Multi-Agent

OpenClaw Manager đang dùng mô hình:

```text
Nhiều mobile / Telegram / Web UI
        |
        v
OpenClaw Gateway
        |
        v
Commander Agent
        |
        +--> Worker Agents
        |
        v
Task Registry + Approval Broker + Obsidian Audit
```

Mục tiêu là để chỉ có **Commander** nhận lệnh và điều phối, còn các worker chỉ làm việc chuyên môn.

## Thành Phần Chính

### Commander

File:

```text
agents/commander.md
skills/commander/SKILL.md
```

Commander chịu trách nhiệm:

- Nhận yêu cầu từ user/mobile.
- Hiểu mục tiêu cuối.
- Chia việc thành từng step.
- Chọn worker phù hợp.
- Tạo task registry record.
- Tạo approval request khi có hành động rủi ro.
- Tổng hợp kết quả cuối trả về user.
- Ghi audit log nếu công việc đủ quan trọng.

Commander không nên tự làm hết mọi việc nếu đã có worker phù hợp.

### Workers

Folder:

```text
agents/workers/
```

Các worker hiện có:

- `email-worker`: Gmail, email draft, inbox triage, communication.
- `research-worker`: research có nguồn, trend, public web.
- `browser-worker`: browser automation, logged-in web, screenshot.
- `code-worker`: đọc/sửa code, test, review.
- `devops-worker`: Jira, CI/CD, incident, deployment.
- `commerce-worker`: travel, shopping, price comparison, địa điểm.
- `document-worker`: PDF/image/report extraction.
- `memory-worker`: Obsidian, memory, planning, audit log.

Mỗi worker khai báo:

- role
- skill được dùng
- tool được dùng
- việc được phép làm
- việc phải xin approval
- audit target
- lock cần giữ khi thao tác tài nguyên nhạy cảm

## Task Registry

Task registry ban đầu dùng JSON state và JSONL event log để dễ đọc/debug.

File/folder:

```text
data/tasks/state.json
data/tasks/tasks.jsonl
data/approvals/state.json
data/approvals/approvals.jsonl
scripts/task_registry.js
```

Các file `.json` và `.jsonl` là runtime data, đã được `.gitignore`.

### Tạo Task

```bash
node scripts/task_registry.js create-task '{"requester":"telegram:1597126604","source":"telegram","goal":"Tìm job Flutter remote part-time"}'
```

### Thêm Step Cho Worker

```bash
node scripts/task_registry.js add-step <task_id> '{"worker":"research-worker","instruction":"Tìm job Flutter remote part-time mới nhất và lọc nguồn đáng tin."}'
```

### Update Step

```bash
node scripts/task_registry.js update-step <task_id> <step_id> '{"status":"done","result":"Đã tìm được 5 job phù hợp."}'
```

### Xem Task

```bash
node scripts/task_registry.js list-tasks
```

## Approval Broker

Approval broker dùng chung script:

```text
scripts/task_registry.js
```

Tạo approval request:

```bash
node scripts/task_registry.js request-approval '{"taskId":"<task_id>","requester":"telegram:1597126604","action":"send_email","risk":"high","details":{"summary":"Draft email đã sẵn sàng, cần duyệt trước khi gửi."}}'
```

Duyệt:

```bash
node scripts/task_registry.js decide-approval <approval_id> approved '{"decidedBy":"telegram:1597126604","note":"OK gửi"}'
```

Từ chối:

```bash
node scripts/task_registry.js decide-approval <approval_id> rejected '{"decidedBy":"telegram:1597126604","note":"Chưa gửi"}'
```

Xem approval:

```bash
node scripts/task_registry.js list-approvals
```

## Hành Động Bắt Buộc Approval

Các hành động sau phải tạo approval request trước:

- Gửi, forward, xóa, archive, move, label email.
- Gửi message, react, post, publish ra ngoài.
- Purchase, checkout, booking, thanh toán, subscription.
- Deploy production, restart service, kill process quan trọng.
- Xóa dữ liệu, bulk move note, sửa note quan trọng.
- Git push.
- Thay đổi credential hoặc account setting.

Worker không được tự approve. Commander chỉ cho chạy bước rủi ro sau khi owner/admin approve.

## Cấu Hình Orchestration

Policy multi-agent nằm ở:

```text
config/multi-agent.json
```

Không đặt key `multiAgent` trong `openclaw.json`, vì OpenClaw gateway validate schema và sẽ fail nếu có key lạ.

Config OpenClaw runtime chỉ giữ những field gateway hiểu, ví dụ:

```text
openclaw_data/openclaw.json
```

Các giá trị quan trọng:

```json
{
  "agents": {
    "defaults": {
      "maxConcurrent": 1,
      "subagents": {
        "maxConcurrent": 4
      }
    }
  }
}
```

Ý nghĩa:

- `maxConcurrent = 1`: giữ Commander là điểm điều phối chính.
- `subagents.maxConcurrent = 4`: cho phép tối đa 4 worker chạy song song.

## Browser Profiles

Không dùng một profile browser cho mọi thứ. Các profile hiện có:

```text
facebook-travel
research-default
job-search
shopping-default
```

Ý nghĩa:

- `facebook-travel`: Facebook, Messenger, travel/social context đã login.
- `research-default`: research public web.
- `job-search`: job boards, freelance platforms.
- `shopping-default`: shopping, price comparison.

Khi thêm worker mới có browser, nên gán profile riêng nếu workflow có login/session riêng.

## Audit Vào Obsidian

Các work quan trọng nên ghi vào Obsidian:

```text
~/Documents/Obsidian/OpenClawBrain/70-Logs/Automation
~/Documents/Obsidian/OpenClawBrain/70-Logs/Email
~/Documents/Obsidian/OpenClawBrain/70-Logs/Job-Hunt
~/Documents/Obsidian/OpenClawBrain/70-Logs/Research
```

Sau khi ghi note:

```bash
cd openclaw_data/.openclaw/workspace
node scripts/obsidian_indexer.js
```

## Luồng Ví Dụ

User nhắn:

```text
Tìm job Flutter remote part-time, lọc job tốt, draft email apply.
```

Commander làm:

1. Tạo task.
2. Giao `research-worker` tìm job.
3. Giao `commerce/job-search hoặc cv-job skill` chấm điểm nếu cần.
4. Giao `email-worker` draft email.
5. Tạo approval request nếu user muốn gửi thật.
6. Giao `memory-worker` ghi log vào Obsidian.
7. Trả kết quả cuối cho requester.

