# 🛸 MASTER PLAN v2 — Self-Evolving Agent Base (OpenClaw + 9Router)

> **v2 note (2026-06-26):** Bản gốc giả định OpenClaw chạy bằng `main.js` + `require()` plugins + `.env` — **sai**, giống lỗi của init_plan. Bản này map lại toàn bộ sang cơ chế THẬT của OpenClaw (đã xác minh qua docs). Triết lý (spec→code→self-update, SOUL.md, docs làm ground-truth) **giữ nguyên** vì nó khớp tốt với OpenClaw; chỉ "cách làm" thay đổi.

## 📌 I. KIẾN TRÚC THẬT (đã xác minh)

Core đã chạy (xong init_plan): **Telegram → OpenClaw gateway (Docker, :18789) → 9Router (`router9/combo-*`, :20138) → LLM free**.

OpenClaw mở rộng theo **thang 3 bậc** (docs khuyên đi từ rẻ nhất — đây chính là "lazy ladder"):

| Bậc | Là gì | Khi nào dùng | Cần code? |
|---|---|---|---|
| **1. SOUL.md / AGENTS.md** | persona + workflow dạng markdown, load mỗi session | đổi hành vi, thêm quy trình | ❌ |
| **2. SKILL.md** | gói hướng dẫn workflow, tự thành slash-command | tác vụ lặp lại dùng tool sẵn có | ❌ chỉ markdown |
| **3. Plugin (SDK)** | typed tool / channel / provider mới (`api.registerTool`) | cần năng lực runtime mới (vd Zalo) | ✅ SDK + manifest |

> Quy tắc: **"require Skill"** là mặc định. Chỉ lên Plugin khi vài dòng SKILL.md không diễn đạt nổi (cần tool/channel mới thật sự). → Vòng "bot tự đẻ tính năng" của plan gốc = bot **tự viết SKILL.md**, không phải tự require `index.js`.

## 🗂️ II. BẢN ĐỒ THƯ MỤC — REPO vs WORKSPACE

Điểm v1 sai nặng nhất: gộp "repo" và "workspace" làm một. Thực tế tách đôi:

```
Repo (git, máy bạn + server)            OpenClaw workspace (trong container)
─────────────────────────────          ──────────────────────────────────────
core/openclaw/                          ~/.openclaw/workspace/   ← mount ra:
  docker-compose.yml                      core/openclaw/openclaw-data/config/workspace/
  config/openclaw.json5  ← agents,         ├── SOUL.md       (persona, load mỗi session)
                            providers,      ├── AGENTS.md     (quy trình 3 bước — KHÔNG để trong SOUL)
                            channels        ├── USER.md       (bạn là ai)
docs/                                       ├── MEMORY.md     (trí nhớ dài hạn)
  update_plan.md   (file này)              ├── memory/YYYY-MM-DD.md
  system_spec.md   (ground-truth tự sinh)  └── skills/<ten>/SKILL.md   ← "tính năng" tự đẻ
  features/<ten>.md (spec tự sinh)
core/openclaw/plugins/<ten>/  (plugin thật, vd zalo — khi cần channel mới)
```

- **`config/openclaw.json5`** = nơi khai báo `agents.list[]`, `models.providers`, `channels`. **Đây là "bất biến lõi"**, không cho agent sửa tự do.
- **`workspace/`** = "bộ não" agent đọc-ghi mỗi session (SOUL/AGENTS/skills/memory).
- **`docs/`** (repo) = tài liệu người + ground-truth; agent ghi spec vào đây qua exec tool.

## 🧠 III. SOUL.md + AGENTS.md (thay cho "SOUL.md" gộp của v1)

docs OpenClaw cảnh báo: **SOUL = tính cách/giới hạn; AGENTS = quy trình đánh số.** Tách ra:

**`workspace/SOUL.md`** (persona):
```markdown
# SOUL — Core Orchestrator & System Architect
Bạn là hạt nhân của một hệ thống AI tự tiến hóa. Giá trị: cẩn trọng, tự lập tài liệu
trước khi code, không phá `core/`. Giới hạn: không sửa `config/openclaw.json5` hay
`core/` khi chưa được duyệt; mọi thay đổi phải qua spec trước.
```

**`workspace/AGENTS.md`** (quy trình 3 bước — giữ nguyên tinh thần v1):
```markdown
# AGENTS — Quy trình tự tiến hóa
Khi nhận yêu cầu thêm tính năng / agent mới:
1. SPEC (combo-reasoning): viết đặc tả markdown vào docs/features/<ten>.md —
   kiến trúc, thư viện, luồng dữ liệu, hàm cần viết.
2. IMPLEMENT (combo-coding): đọc spec, hiện thực đúng theo nó:
   - Tác vụ workflow  → tạo workspace/skills/<ten>/SKILL.md  (ưu tiên)
   - Cần tool/channel → core/openclaw/plugins/<ten>/ + cập nhật config (cần duyệt)
3. SELF-UPDATE: cập nhật docs/system_spec.md (mục đã thêm), rồi
   `docker compose -f core/openclaw/docker-compose.yml restart openclaw-gateway`.
```

## 🤖 IV. MULTI-AGENT (thay cho "agents/[ten].md" của v1)

OpenClaw có sẵn multi-agent — khai trong `config/openclaw.json5`:

```json5
agents: {
  defaults: { workspace: "~/.openclaw/workspace", model: { primary: "router9/combo-coding" } },
  list: [
    { id: "main", default: true, name: "Core", model: { primary: "router9/combo-coding" },
      tools: { profile: "coding" } },
    // Agent mới "tự đẻ" thêm vào đây — vd agent chuyên reasoning:
    { id: "architect", name: "Architect", model: { primary: "router9/combo-reasoning" },
      workspace: "~/.openclaw/workspace-architect", tools: { profile: "read-only" } },
  ],
},
bindings: [ /* route channel/account → agentId nếu cần */ ],
```

→ Đúng ý đồ v1 "combo-reasoning cho tài liệu, combo-coding cho code" — nhưng bằng cơ chế `agents.list[].model` có sẵn.

## ⚙️ V. EXEC TOOL & BẢO MẬT (v1 bỏ sót — bắt buộc quyết định)

Để agent **tự ghi file & chạy lệnh** (cốt lõi của self-evolution) cần `exec` tool. **Mặc định OpenClaw: sandbox TẮT, `security=full`, `ask=off` ("YOLO")** — agent chạy shell tùy ý trên host gateway. Với hệ tự sửa mình, đây là rủi ro thật.

Khuyến nghị (đặt trong `config/openclaw.json5` → `tools.exec`):
```json5
tools: {
  exec: {
    host: "gateway",          // hoặc "sandbox" nếu bật Docker-in-Docker sandbox
    security: "ask",          // hỏi duyệt thay vì auto chạy
    ask: "on-miss",           // chạy lệnh quen, hỏi lệnh lạ
    timeoutSec: 120,
  },
},
```
- Vì container đã cô lập (`no-new-privileges`, cap drops) → blast radius giới hạn trong container `claw-openclaw` + bind mounts.
- `ponytail: security="ask"` là ceiling an toàn ban đầu. Nâng lên `full` khi đã tin quy trình; hoặc bật `sandbox` thật khi cho agent chạy code không kiểm soát.

## 🔄 VI. WALKTHROUGH — "Tích hợp Zalo" (map lại đúng OpenClaw)

OpenClaw **không có channel Zalo sẵn** → đây là ca cần **Plugin bậc 3** (không phải skill). Chi tiết kỹ thuật: [features/zalo_spec.md](features/zalo_spec.md).

```
[Yêu cầu: Tích hợp Zalo]
   │
   ▼ 1. SPEC (combo-reasoning) → docs/features/zalo_spec.md  ✅ (đã tạo sẵn làm mẫu)
   ▼ 2. IMPLEMENT (combo-coding) → core/openclaw/plugins/zalo/ (plugin channel dùng zca-js)
   ▼ 3. EXEC: npm i zca-js trong plugin; login QR (quét 1 lần)
   ▼ 4. CONFIG: bật channel zalo trong openclaw.json5 (cần người duyệt — sửa lõi)
   ▼ 5. RESTART: docker compose restart openclaw-gateway → channel Zalo online
```

⚠️ zca-js **không chính thức** — rủi ro khóa tài khoản Zalo. Cân nhắc dùng tài khoản phụ.

## 🗂️ VII. system_spec.md — GROUND TRUTH TỰ SINH

`docs/system_spec.md` là file agent đọc để biết "hệ thống đang có gì" và tự cập nhật. Cấu trúc:

```markdown
# System Spec (Auto-Generated)
## 1. Agents đang hoạt động
- main (Core): router9/combo-coding, profile=coding
## 2. Channels
- telegram: allowlist [6302853216]  ✅ online
## 3. Skills tự sinh
- (trống — agent nối thêm sau mỗi lần tạo skill)
## 4. Plugins
- (trống — vd zalo sau khi hoàn tất)
## 5. Mutation Logs
- 2026-06-26: Core online (init_plan xong). Master Plan v2 map lại kiến trúc thật.
```

## 🚀 VIII. THỨ TỰ TRIỂN KHAI v2

1. **Tạo workspace files**: `SOUL.md`, `AGENTS.md`, `USER.md` vào `core/openclaw/openclaw-data/config/workspace/` (mount sẵn). Restart gateway → xác nhận load (log session).
2. **Bật exec với `security=ask`** trong `openclaw.json5`; test agent ghi 1 file vào docs/.
3. **Khởi tạo `docs/system_spec.md`** (mục VII) làm ground-truth.
4. **Thử vòng tự tiến hóa nhẹ**: ra lệnh Telegram "tạo skill X" → kiểm tra agent viết spec → SKILL.md → cập nhật system_spec.
5. **(Tùy chọn) Zalo**: theo [features/zalo_spec.md](features/zalo_spec.md) — ca plugin đầy đủ, làm khi cần.

> Khác cốt lõi vs v1: bỏ `main.js`/`require`; "plugin" → ưu tiên Skill; "agent .md" → `agents.list[]`; thêm tầng exec/sandbox bảo mật; tách repo vs workspace.
