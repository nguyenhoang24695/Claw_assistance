# Feature Spec — Zalo Channel Plugin (zca-js)

> Spec-trước-code, theo AGENTS.md bước 1. Đây là ca **Plugin bậc 3** (không phải
> Skill) vì cần một **channel mới** OpenClaw chưa có sẵn.
> Nguồn: https://github.com/RFS-ADRENO/zca-js · https://zca-js.tdung.com/vi/

## 1. Mục tiêu & phạm vi
Cho phép Core Agent nhận/gửi tin nhắn Zalo cá nhân, song song với Telegram —
cùng một agent (`router9/combo-coding`), khác channel.

- **Trong scope**: nhận DM text, gửi text trả lời, lọc tin tự gửi/non-text.
- **Ngoài scope (v1)**: ảnh/sticker/file, group, kết bạn tự động, gọi điện.

## 2. ⚠️ Rủi ro & ràng buộc (đọc trước khi code)
- zca-js **KHÔNG chính thức** — giả lập Zalo Web. "Using this API could get your
  account locked or banned." → **dùng tài khoản phụ**, không dùng số chính.
- **Một listener/tài khoản tại một thời điểm**: mở Zalo trên trình duyệt khi
  listener đang chạy sẽ **ngắt** listener.
- Login bằng **QR** (README chỉ minh hoạ QR) → cần quét tay 1 lần; phải **persist
  session** để khỏi quét lại mỗi lần restart container.
- Chạy trong container `claw-openclaw` (Linux, headless) → QR phải in ra **log/
  terminal** hoặc lưu file ảnh đọc được.

## 3. Kiến trúc
```
Zalo (web) ⇄ zca-js listener  ──►  OpenClaw plugin channel "zalo"  ──►  Core Agent
                                         │                                  │
                                         └──────── api.sendMessage() ◄───────┘ (reply)
```
Plugin đăng ký một **channel** qua OpenClaw Plugin SDK; nhận tin → đẩy vào agent
runtime; agent trả lời → plugin gọi `api.sendMessage`.

## 4. Thư viện cần cài
```bash
npm install zca-js        # trong core/openclaw/plugins/zalo/
```
- Node 22+ (image OpenClaw đã có).
- v2 zca-js: bỏ `sharp` — nếu sau này gửi ảnh phải tự cấp `imageMetadataGetter`
  (ngoài scope v1).

## 5. Luồng dữ liệu & các hàm cần viết
```js
// core/openclaw/plugins/zalo/index.js  (phác thảo — KHÔNG phải code cuối)
import { Zalo, ThreadType } from "zca-js";

// (a) Đăng nhập + persist session
//     - lần đầu: zalo.loginQR() → in QR ra log; lưu credential/cookie ra
//       /home/node/.openclaw/zalo-session.json (nằm trong bind mount → bền)
//     - lần sau: nạp lại session, tránh quét QR
const api = await new Zalo().loginQR();   // ponytail: QR-only; thêm cookie-login khi zca-js hỗ trợ ổn định

// (b) Nhận tin → đẩy vào OpenClaw agent
api.listener.on("message", async (m) => {
  const isText = typeof m.data.content === "string";
  if (m.isSelf || !isText) return;                 // bỏ tin tự gửi / non-text
  if (m.type !== ThreadType.User) return;          // v1: chỉ DM, bỏ group
  // → gọi OpenClaw API: tạo/đẩy message vào agent runtime, nhận reply
  const reply = await pushToAgent(m.data.content, { threadId: m.threadId });
  // (c) Gửi trả
  await api.sendMessage({ msg: reply, quote: m.data }, m.threadId, m.type);
});
api.listener.start();
```
Hàm cần hiện thực:
- `loadOrLoginSession()` — nạp session đã lưu, fallback `loginQR()`, ghi lại session.
- `pushToAgent(text, ctx)` — cầu nối vào OpenClaw agent runtime (theo Plugin SDK
  channel contract — **cần đọc docs Plugin SDK trước khi code**).
- `onMessage()` / `sendReply()` — như trên.
- **Allowlist**: chỉ xử lý từ Zalo user id của chủ (đối xứng Telegram `allowFrom`).

## 6. Bảo mật
- Session Zalo lưu trong bind mount (gitignored) — **không commit**.
- Allowlist Zalo uid chủ; bỏ qua mọi nguồn khác.
- exec/tool theo chính sách chung (`security=ask`) — plugin không tự nâng quyền.

## 7. Định nghĩa Hoàn thành (DoD)
1. Container restart → plugin nạp session, **không** cần quét QR lại.
2. Nhắn DM Zalo cho tài khoản bot → Core Agent trả lời đúng (route qua
   `router9/combo-coding`, thấy log ở 9Router :20138).
3. Tin từ uid lạ → bị bỏ qua (allowlist).
4. Cập nhật `docs/system_spec.md`: thêm `zalo` vào mục Channels.

## 8. Việc CẦN xác minh trước khi hiện thực (đừng đoán)
- **OpenClaw Plugin SDK**: contract đăng ký channel (`api.registerChannel`?),
  cách đẩy inbound vào agent + nhận outbound. → đọc docs/tools + Plugin SDK.
- Cách OpenClaw nạp plugin trong Docker (thư mục plugin, manifest, build step).
- zca-js persist session: API lưu/khôi phục credential cụ thể (README chỉ show QR).

> ponytail: spec v1 chỉ DM-text. Mở rộng (group, ảnh, sticker, auto-accept friend
> qua `api.acceptFriendRequest`) thêm khi luồng cơ bản đã chạy ổn.
