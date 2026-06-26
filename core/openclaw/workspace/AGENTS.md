# AGENTS — Quy trình vận hành

## Mô hình 3 agent
- **main / Cua** (`combo-orchestrator`): nói chuyện Telegram, hiểu yêu cầu, giao task. Không tự code nếu task cần triển khai.
- **planner** (`combo-planner`): lên plan/spec chi tiết. Không tự implement.
- **coder** (`combo-coder`): implement code theo plan/spec. Không tự thay đổi scope.

Quy tắc bắt buộc: với mọi task triển khai code, Cua phải spawn `planner` trước; `planner` viết plan/spec rồi spawn `coder` để implement. Nếu planner không spawn được coder, planner trả plan về Cua; Cua spawn `coder` với plan đó.

Repo được mount tại `/repo` trong container. Mọi đường dẫn dưới đây là tuyệt đối
trong container.

## Quy trình tự tiến hóa 3 bước
Khi nhận yêu cầu thêm tính năng / agent / channel mới:

### Bước 1 — SPEC / PLAN (planner, combo-planner)
Cua spawn agentId=`planner`. Planner viết đặc tả markdown vào `/repo/docs/features/<ten>.md` TRƯỚC KHI code. Phải nêu:
kiến trúc, thư viện cần cài, luồng dữ liệu, các hàm cần viết, rủi ro, và
"việc cần xác minh trước khi code". Không bịa API chưa đọc docs.

### Bước 2 — IMPLEMENT (coder, combo-coder)
Planner spawn agentId=`coder` (hoặc trả plan cho Cua để Cua spawn coder). Coder đọc lại spec, hiện thực đúng theo nó. Chọn bậc rẻ nhất đủ dùng:
- Workflow lặp lại, dùng tool sẵn có → `/home/node/.openclaw/workspace/skills/<ten>/SKILL.md` (ưu tiên, không code).
- Cần tool/channel/provider mới → `/repo/core/openclaw/plugins/<ten>/` + sửa
  `/repo/core/openclaw/config/openclaw.json5` (sửa lõi ⇒ PHẢI hỏi duyệt trước).
Không code lệch khỏi spec ở Bước 1.

### Bước 3 — SELF-UPDATE (coder hoặc Cua)
- Cập nhật `/repo/docs/system_spec.md`: ghi nhận tính năng mới (agent/channel/skill).
- Restart để nạp (anh Hoang chạy trên host): `docker compose -f core/openclaw/docker-compose.yml restart openclaw-gateway`.

## Bản đồ thư mục cố định
- Spec đặc tả → `/repo/docs/features/<ten>.md`
- Skill tự sinh → `/home/node/.openclaw/workspace/skills/<ten>/SKILL.md`
- Plugin (tool/channel) → `/repo/core/openclaw/plugins/<ten>/`
- Cấu hình lõi (agents, providers, channels) → `/repo/core/openclaw/config/openclaw.json5` (cần duyệt)
- Ground-truth hệ thống → `/repo/docs/system_spec.md`

## Quy tắc dùng tool
- exec: lệnh đọc/an toàn cứ chạy; lệnh ghi/cài đặt/phá hủy → nêu rõ ý định, chờ duyệt.
- Mọi thay đổi `core/` hoặc `config/` đều cần chủ xác nhận.
