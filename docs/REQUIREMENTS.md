# Requirements — PeerTask Client

Phạm vi: ứng dụng Flutter. API do server đảm bảo; client phải tuân contract hiện tại (không `/api`).

Ưu tiên: **P0** phải có · **P1** đã có / cần giữ · **P2** mở rộng.

## 1. Mục tiêu

Người dùng vẽ và quản lý task trên cùng một board, cộng tác gần realtime, hoặc làm offline rồi (khi online) dựa vào backend.

## 2. Actors

| Actor | Mô tả |
| --- | --- |
| Guest | Chưa login; chỉ public auth + offline |
| Member | JWT hợp lệ; quyền theo workspace/board từ API |
| Offline peer | Chỉ có `userName` + `roomCode` |

Client **không** tự nâng quyền. Mọi mutate đi qua API; UI ẩn/disable theo `role`, `permission`, `is_board_owner`.

## 3. Functional — Auth (P0)

| ID | Yêu cầu | Chấp nhận |
| --- | --- | --- |
| C-AUTH-01 | Đăng ký email + password ≥ 6, name tùy chọn | 201, lưu tokens + user, vào workspace list |
| C-AUTH-02 | Đăng nhập | Sai credential hiện `ApiError.userMessage`, không crash |
| C-AUTH-03 | Khôi phục session | Mở app: Hive token → `/auth/me` hoặc refresh; fail thì `/login` |
| C-AUTH-04 | Refresh | 401 → một lần `POST /token/refresh`; fail → logout local |
| C-AUTH-05 | Forgot / reset password | `/forgot-password`, `/reset-password?token=` |
| C-AUTH-06 | Profile | Đổi name, avatar, mật khẩu qua dialog hiện có |
| C-AUTH-07 | Logout | Xóa Hive tokens trước, `POST /token/logout` best-effort |

## 4. Functional — Workspace & board (P0)

| ID | Yêu cầu | Chấp nhận |
| --- | --- | --- |
| C-WS-01 | List / create / rename / delete workspace | Delete chỉ owner; confirm `AppDialog` danger |
| C-WS-02 | Invite email + invite link / QR + join token | Join xong workspace xuất hiện trong list |
| C-WS-03 | Members: list, đổi role, xóa | Role `owner\|editor\|viewer`; viewer không tạo board |
| C-WS-04 | List board theo workspace | Owner thấy tất cả; editor/viewer chỉ board được add |
| C-WS-05 | CRUD board + members `edit\|view` | Board owner / workspace owner quản lý member |
| C-WS-06 | Last workspace | Sau login mở `/workspace/:id/boards` nếu Hive còn id |

## 5. Functional — Board online (P0)

| ID | Yêu cầu | Chấp nhận |
| --- | --- | --- |
| C-BD-01 | Canvas: pen, eraser, text | Op local + peer trong vài trăm ms khi P2P ok |
| C-BD-02 | Hiện stroke đang vẽ kèm tên user | Xóa khi stroke commit |
| C-BD-03 | Undo local | Không xóa op đã apply của người khác |
| C-BD-04 | Cursor P2P | Không `POST /operations` |
| C-BD-05 | Catch-up | Vào board: pull ops `since` rồi mới tin live op |
| C-BD-06 | Dedup / LWW | Trùng `opId` bỏ qua; update cũ hơn `updatedAt` bỏ qua |
| C-BD-07 | Mic status | `update_mic_status` phản ánh trên peer list |
| C-BD-08 | Screenshot board | Dùng `ScreenshotController` hiện có; fail thì toast, không crash |

## 6. Functional — Task / Kanban (P0)

| ID | Yêu cầu | Chấp nhận |
| --- | --- | --- |
| C-TK-01 | Cột `todo`, `doing`, `done` | Filter/reorder gọi API tương ứng |
| C-TK-02 | Task: title, description, assignees, priority, deadline, labels, parent, estimate | Enum khớp server |
| C-TK-03 | Assignee phải là member board (hoặc workspace owner) | API reject → hiện lỗi, không silent |
| C-TK-04 | Move / reorder | `POST /tasks/:id/move`, `POST /tasks/reorder` |
| C-TK-05 | Viewer | Không create/edit/delete task |
| C-TK-06 | Panel Kanban đóng/mở, đổi width | State UI, không mất task list |

Priority: `low` \| `medium` \| `high` \| `urgent`.

## 7. Functional — Offline (P0)

| ID | Yêu cầu | Chấp nhận |
| --- | --- | --- |
| C-OFF-01 | `/offline-username` → boards local Hive | Không gọi `/workspaces` |
| C-OFF-02 | Tạo/vào phòng `roomCode` | Signaling không JWT |
| C-OFF-03 | Vẽ P2P trong phòng | Mất mạng signaling: báo lỗi, không xóa board local |

## 8. Functional — i18n, a11y, AI (P1)

| ID | Yêu cầu | Chấp nhận |
| --- | --- | --- |
| C-I18N-01 | `en` và `vi` | Mọi chuỗi mới có **cả hai** ARB |
| C-I18N-02 | Đổi ngôn ngữ trong settings | `languageProvider` persist |
| C-AI-01 | Brainstorm panel | `/ai` hoặc Ollama URL; 503 → message rõ, app vẫn dùng được |
| C-UI-01 | Theme AppColors / AppButton / AppDialog / AppToast | Không hex rải trong screen mới |

## 9. Non-functional

| ID | Hạng | Yêu cầu |
| --- | --- | --- |
| C-NFR-01 | Tương thích | Flutter ^3.8.1; android, ios, web, windows, macos, linux |
| C-NFR-02 | Bảo mật | Không log password / refresh token; không commit secret |
| C-NFR-03 | Mạng | Timeout 30s; phân biệt network / 401 / 403 / 5xx qua `ApiError` |
| C-NFR-04 | UX lỗi | `userMessage` tiếng Việt khi locale `vi` |
| C-NFR-05 | Hiệu năng board | Apply op O(1) theo `opId`; không rebuild cả app mỗi nét |
| C-NFR-06 | Offline storage | Hive only cho token, user, last workspace, board offline — không password |
| C-NFR-07 | Codegen | PR không chứa `*.freezed.dart` lệch tay; runner phải generate |

## 10. Ngoài phạm vi client

- Schema PostgreSQL, migration, JWT secret
- Relay full board qua Socket.IO
- Dark theme (chưa có `AppTheme.dark`)
- Thanh toán / multi-tenant billing

## 11. Phụ thuộc bên ngoài

| Hệ thống | Dùng để |
| --- | --- |
| peer_task_server | REST + signaling |
| Firebase (core + REST URL) | Init + optional remote URL |
| Ollama (qua server hoặc URL) | AI brainstorm |
| Cloudinary (nếu bật) | Avatar — server/client service hiện có |
