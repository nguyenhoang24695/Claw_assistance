# AGENTS — Quy trình vận hành

## Quy trình tự tiến hóa 3 bước
Khi nhận yêu cầu thêm tính năng / agent / channel mới:

### Bước 1 — SPEC (dùng tư duy combo-reasoning)
Viết đặc tả markdown vào `docs/features/<ten>.md` TRƯỚC KHI code. Phải nêu:
kiến trúc, thư viện cần cài, luồng dữ liệu, các hàm cần viết, rủi ro, và
"việc cần xác minh trước khi code". Không bịa API chưa đọc docs.

### Bước 2 — IMPLEMENT (dùng tư duy combo-coding)
Đọc lại spec, hiện thực đúng theo nó. Chọn bậc rẻ nhất đủ dùng:
- Workflow lặp lại, dùng tool sẵn có → `workspace/skills/<ten>/SKILL.md` (ưu tiên, không code).
- Cần tool/channel/provider mới → `core/openclaw/plugins/<ten>/` + sửa `config/openclaw.json5`
  (sửa lõi ⇒ PHẢI hỏi duyệt trước).
Không code lệch khỏi spec ở Bước 1.

### Bước 3 — SELF-UPDATE
- Cập nhật `docs/system_spec.md`: ghi nhận tính năng mới (agent/channel/skill).
- Restart để nạp: `docker compose -f core/openclaw/docker-compose.yml restart openclaw-gateway`.

## Bản đồ thư mục cố định
- Spec đặc tả → `docs/features/<ten>.md`
- Skill tự sinh → `workspace/skills/<ten>/SKILL.md`
- Plugin (tool/channel) → `core/openclaw/plugins/<ten>/`
- Cấu hình lõi (agents, providers, channels) → `core/openclaw/config/openclaw.json5` (cần duyệt)
- Ground-truth hệ thống → `docs/system_spec.md`

## Quy tắc dùng tool
- exec: lệnh đọc/an toàn cứ chạy; lệnh ghi/cài đặt/phá hủy → nêu rõ ý định, chờ duyệt.
- Mọi thay đổi `core/` hoặc `config/` đều cần chủ xác nhận.
