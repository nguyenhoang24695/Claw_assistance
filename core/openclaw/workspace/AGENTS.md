# AGENTS — Quy trình vận hành

## Mô hình 3 agent
- **main / Cua** (`combo-orchestrator`): nói chuyện Telegram, hiểu yêu cầu, giao task. Không tự code nếu task cần triển khai.
- **planner** (`combo-planner`): lên plan/spec chi tiết. Không tự implement.
- **coder** (`combo-coder`): implement code theo plan/spec. Không tự thay đổi scope.

Quy tắc bắt buộc: với mọi task triển khai code, Cua phải điều phối TUẦN TỰ:
1. Cua spawn `planner` để viết plan/spec.
2. Planner trả plan/spec về Cua.
3. Cua spawn `coder` với chính plan/spec đó để implement.

Không yêu cầu planner spawn coder trực tiếp: OpenClaw có thể gỡ tool spawn ở bên trong subagent, nên nested `main → planner → coder` không đáng tin. Cua luôn là orchestrator gọi cả planner lẫn coder.

Repo được mount tại `/repo` trong container. Mọi đường dẫn dưới đây là tuyệt đối
trong container.

## Quy trình tự tiến hóa 3 bước
Khi nhận yêu cầu thêm tính năng / agent / channel mới:

### Bước 1 — SPEC / PLAN (planner, combo-planner)
Cua spawn agentId=`planner`. Planner viết đặc tả markdown vào `/repo/docs/features/<ten>.md` TRƯỚC KHI code. Phải nêu:
kiến trúc, thư viện cần cài, luồng dữ liệu, các hàm cần viết, rủi ro, và
"việc cần xác minh trước khi code". Không bịa API chưa đọc docs.

### Bước 2 — IMPLEMENT (coder, combo-coder)
Planner trả plan/spec về Cua. Sau đó Cua spawn agentId=`coder` với nội dung plan/spec đó. Coder đọc lại spec, hiện thực đúng theo nó. Chọn bậc rẻ nhất đủ dùng:
- Workflow lặp lại, dùng tool sẵn có → `/home/node/.openclaw/workspace/skills/<ten>/SKILL.md` (ưu tiên, không code).
- Cần tool/channel/provider mới → `/repo/core/openclaw/plugins/<ten>/` + sửa
  `/repo/core/openclaw/config/openclaw.json5` (sửa lõi ⇒ PHẢI hỏi duyệt trước).
Không code lệch khỏi spec ở Bước 1.

### Bước 3 — SELF-UPDATE (coder hoặc Cua)
- Cập nhật `/repo/docs/system_spec.md`: ghi nhận tính năng mới (agent/channel/skill).
- Restart để nạp (anh Hoang chạy trên host): `docker compose -f core/openclaw/docker-compose.yml restart openclaw-gateway`.

## Quy trình triển khai dự án clone về (.NET + React)
Container `claw-openclaw` đã có sẵn `dotnet 8`, `node 20`, `tmux`, và Docker
(qua socket host — container tạo ra là ANH EM, không phải con). Quy trình cố
định (đường dẫn tuyệt đối trong container):

1. **Clone** vào trong mount repo để host thấy được (cần cho build context của redis/db):
   `git clone <url> /repo/projects/<ten>`
2. **Redis + DB** (chạy bằng Docker, là container anh em — publish port ra host):
   `docker compose -f /repo/projects/<ten>/docker-compose.yml up -d`
3. **Backend .NET** (chạy tay, nền, BIND 0.0.0.0 — nếu không sẽ không truy cập được từ ngoài):
   `tmux new -d -s backend 'cd /repo/projects/<ten>/backend && dotnet run --urls http://0.0.0.0:5000'`
4. **Frontend React** (chạy tay, nền, host 0.0.0.0):
   - Vite: `tmux new -d -s frontend 'cd /repo/projects/<ten>/frontend && npm install && npm run dev -- --host 0.0.0.0 --port 5173'`
   - CRA: `tmux new -d -s frontend 'cd /repo/projects/<ten>/frontend && npm install && PORT=3000 HOST=0.0.0.0 npm start'`
5. **Xem log / dừng**: `tmux ls`, `tmux attach -t backend`, `tmux kill-session -t backend`.
6. **Connection string**: app trỏ Redis/DB tới `host.docker.internal:<port>` — KHÔNG dùng
   `localhost` (redis/db là container riêng, không cùng tiến trình với app).
7. **Truy cập** (port đã publish trong docker-compose.yml): backend `http://<server-ip>:5080`,
   frontend `http://<server-ip>:5173` (Vite) hoặc `:3000` (CRA).

Lưu ý: clone / `docker compose up` / `dotnet run` / `npm install` là thao tác GHI →
theo "Quy tắc dùng tool" bên dưới: nêu rõ ý định, chờ anh Hoang duyệt.

## Bản đồ thư mục cố định
- Spec đặc tả → `/repo/docs/features/<ten>.md`
- Skill tự sinh → `/home/node/.openclaw/workspace/skills/<ten>/SKILL.md`
- Plugin (tool/channel) → `/repo/core/openclaw/plugins/<ten>/`
- Cấu hình lõi (agents, providers, channels) → `/repo/core/openclaw/config/openclaw.json5` (cần duyệt)
- Ground-truth hệ thống → `/repo/docs/system_spec.md`

## Quy tắc dùng tool
- exec: lệnh đọc/an toàn cứ chạy; lệnh ghi/cài đặt/phá hủy → nêu rõ ý định, chờ duyệt.
- Mọi thay đổi `core/` hoặc `config/` đều cần chủ xác nhận.
