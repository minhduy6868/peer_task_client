# PeerTask Client

Ứng dụng Flutter cho PeerTask: whiteboard cộng tác, Kanban, workspace, và chế độ offline P2P.

Upstream: [minhduy6868/peer_task_client](https://github.com/minhduy6868/peer_task_client) · branch mặc định `dev`.

## Tài liệu

| Doc | Nội dung |
| --- | --- |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Lớp UI / state / P2P, routing, sync |
| [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) | Yêu cầu chức năng và phi chức năng |
| [AGENTS.md](AGENTS.md) | Hướng dẫn agent (Cursor / Codex) |
| [CLAUDE.md](CLAUDE.md) | Hướng dẫn Claude Code |

Cần API: clone và chạy [peer_task_server](https://github.com/minhduy6868/peer_task_server). Client **không** gọi `/api/...` — chỉ `/auth`, `/token`, `/workspaces`, `/boards`, `/tasks`, `/operations`, `/ai`.

## Yêu cầu

- Flutter SDK ^3.8.1
- Dart 3
- Backend PeerTask đang chạy (hoặc URL hợp lệ trong config)

## Cài đặt

```bash
flutter pub get
flutter run
```

Codegen sau khi sửa freezed / json / riverpod:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Cấu hình URL

`ConfigService` chọn backend theo thứ tự:

1. Override trong Hive (settings)
2. Firebase Realtime Database (REST)
3. `assets/config.json` (`api_base_url`, `ollama_url`)
4. Fallback `http://localhost:3000`

## Platforms

`android`, `ios`, `web`, `windows`, `macos`, `linux`.

## Cấu trúc `lib/`

```
lib/
├── main.dart                 go_router + auth redirect
├── core/sync_engine.dart     CRDT apply, dedup, LWW
├── models/                   freezed (User, Workspace, Board, Task, Operation)
├── providers/                Riverpod
├── services/                 ApiService, signaling, WebRTC, Hive, config, AI
├── ui/screens/               login, workspace, board, offline
├── ui/widgets/               AppButton, AppDialog, task panel, canvas helpers
├── ui/theme/                 AppColors, AppTheme
└── l10n/                     app_en.arb, app_vi.arb
```

## Routes

| Path | Màn hình | Auth |
| --- | --- | --- |
| `/login` | Đăng nhập / đăng ký | public |
| `/forgot-password` | Quên mật khẩu | public |
| `/reset-password` | Đặt lại mật khẩu | public |
| `/workspaces` | Danh sách workspace | JWT |
| `/workspace/:id/boards` | Board trong workspace | JWT |
| `/board/:id` | Canvas + Kanban | JWT |
| `/offline-username` | Tên offline | không |
| `/offline-boards` | Board local | không |
| `/offline-board/:id` | Canvas offline / P2P | không |

## Git

- Branch: `feat/<slug>`, `fix/<slug>`, … từ `dev`
- Commit: Conventional Commits, ví dụ `feat(board): show assignee chips on task cards`
- PR template: `.github/pull_request_template.md`
- Không commit `.env`, không đưa file server vào PR này
