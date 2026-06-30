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

## Quy trình triển khai dự án (container-per-project)
`claw-openclaw` là ORCHESTRATOR gọn: chỉ có `git` + `docker` CLI (điều khiển
daemon host qua socket — container tạo ra là ANH EM). **KHÔNG** chứa runtime
(.NET, Node, Python...) và **KHÔNG** chạy app trực tiếp trong nó. Mỗi dự án chạy
container riêng với runtime của chính nó. Đường dẫn tuyệt đối trong container:

1. **Clone** vào `/repo/projects/<ten>` (trong mount → host thấy được, cần cho build context):
   `git clone <url> /repo/projects/<ten>`
2. **Mỗi service một container.** Nếu repo đã có `Dockerfile`/`docker-compose.yml` → dùng luôn.
   Nếu chưa → Cua **sinh Dockerfile** cho từng phần:
   - Backend .NET: `FROM mcr.microsoft.com/dotnet/sdk:8.0` (build) → publish → runtime image `aspnet:8.0`.
   - Frontend React: `FROM node:20` build (`npm ci && npm run build`) → serve bằng `nginx:alpine` (hoặc `npm run preview`).
   - Redis/DB: dùng image chính thức (`redis:7`, `postgres:16`...), KHÔNG tự viết.
   Gom lại bằng `docker-compose.yml` của dự án, rồi `docker compose -f /repo/projects/<ten>/docker-compose.yml up -d --build`.
3. **Mạng & port:** các service CÙNG dự án nói chuyện qua docker network của dự án đó (gọi nhau
   bằng TÊN SERVICE, vd `redis`, `db` — KHÔNG dùng `localhost`/`host.docker.internal`). Chỉ
   service cần truy cập từ ngoài mới publish port; tự chọn dải port host TRỐNG (kiểm tra `ss -ltn`
   trước để tránh đụng dự án khác trên server).
4. **Commit/push:** Cua dùng git ngay trong claw-openclaw (token HTTPS đã cấu hình sẵn):
   `git -C /repo/projects/<ten> add -A && git -C /repo/projects/<ten> commit -m "..." && git -C /repo/projects/<ten> push`.

Lưu ý: clone / `docker compose up --build` / `git push` là thao tác GHI →
theo "Quy tắc dùng tool" bên dưới: nêu rõ ý định, chờ anh Hoang duyệt.

## Bản đồ thư mục cố định
- Dự án clone về → `/repo/projects/<ten>` (mỗi dự án chạy container riêng)
- Spec đặc tả → `/repo/docs/features/<ten>.md`
- Skill tự sinh → `/home/node/.openclaw/workspace/skills/<ten>/SKILL.md`
- Plugin (tool/channel) → `/repo/core/openclaw/plugins/<ten>/`
- Cấu hình lõi (agents, providers, channels) → `/repo/core/openclaw/config/openclaw.json5` (cần duyệt)
- Ground-truth hệ thống → `/repo/docs/system_spec.md`

## Quy tắc dùng tool
- exec: lệnh đọc/an toàn cứ chạy; lệnh ghi/cài đặt/phá hủy → nêu rõ ý định, chờ duyệt.
- Mọi thay đổi `core/` hoặc `config/` đều cần chủ xác nhận.
