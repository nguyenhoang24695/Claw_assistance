# System Spec — Ground Truth (Auto-Maintained)

> File này là "bản đồ tư duy" của hệ thống. Cua đọc để biết hiện có gì, và CẬP
> NHẬT file này ở Bước 3 mỗi lần tự tiến hóa (xem workspace/AGENTS.md).
> Quy ước: thêm dòng vào đúng mục + ghi 1 dòng vào Mutation Logs (ngày tuyệt đối).

## 1. Agents đang hoạt động
- **main** (Cua 🦀) — default. Model `router9/combo-coding`. Vai trò: Core
  Orchestrator & System Architect. Persona: workspace/SOUL.md.

## 2. Channels (cổng giao tiếp)
- **telegram** — ✅ online. `dmPolicy: allowlist`, chỉ owner (id 6302853216).

## 3. Skills tự sinh (workspace/skills/<ten>/SKILL.md)
- **chao-hoi** — Chào người dùng bằng tiếng Việt kèm giờ hiện tại khi gõ `/chao-hoi`. Spec: docs/features/chao-hoi.md

## 4. Plugins (core/openclaw/plugins/<ten>/)
- (trống — vd `zalo` sau khi hoàn tất; spec: docs/features/zalo_spec.md)

## 5. Hạ tầng & năng lực
- LLM routing: 9Router (`claw-9router`, :20138) → combo-coding (Xiaomi),
  combo-reasoning (Nemotron). Cả hai free.
- exec tool: BẬT, `security=full` (container là sandbox). Cua đọc/ghi file +
  chạy lệnh trong container `claw-openclaw`.
- Workspace bootstrap: SOUL/AGENTS/USER/IDENTITY.md (load mỗi session).

## 6. Mutation Logs (lịch sử thay đổi hệ thống)
- **2026-06-26**: Core online (init_plan xong) — Telegram→OpenClaw→9Router→LLM.
- **2026-06-26**: Master Plan v2 — map kiến trúc tự-tiến-hóa sang cơ chế OpenClaw thật.
- **2026-06-26**: v2 Bước 1 — workspace files (persona Cua 🦀). Bước 2 — exec bật, test ghi file OK.
- **2026-06-26**: Thêm skill `chao-hoi` — chào Việt Nam + giờ hiện tại. Spec: docs/features/chao-hoi.md
