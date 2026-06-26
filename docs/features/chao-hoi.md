# Feature Spec: /chao-hoi

> Ngày: 2026-06-26
> Tác giả: Cua 🦀

## Mục tiêu
Khi người dùng gõ `/chao-hoi`, Cua chào bằng tiếng Việt kèm giờ hiện tại.

## Cách hoạt động
- OpenClaw nhận lệnh `/chao-hoi` từ Telegram.
- Skill `chao-hoi` được trigger, Cua thực hiện:
  1. Lấy giờ hiện tại (Asia/Ho_Chi_Minh, UTC+7).
  2. Trả lời chào bằng tiếng Việt, ví dụ:
     > "Chào buổi sáng anh Hoang! 🦀 Hôm nay là Thứ Sáu, 26/06/2026, 16:11."

## Chi tiết kỹ thuật
- **Loại skill**: Workflow tự động (không cần plugin mới).
- **Thư viện**: Không cần cài thêm — dùng `exec` chạy `date` hoặc `TZ=Asia/Ho_Chi_Minh date`.
- **Đầu ra**: Message text trả về Telegram.

## Rủi ro
- Không có rủi ro — skill chỉ đọc giờ và gửi tin nhắn.
- Không cần sửa core hay config.

## Việc cần xác minh trước khi code
- ✅ OpenClaw hỗ trợ skill trigger qua `/command` (xác minh: SKILL.md với trigger là `/chao-hoi`).
- ✅ Giờ UTC+7 hiển thị đúng qua `TZ=Asia/Ho_Chi_Minh date`.
