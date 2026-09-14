# PeerTask client — Claude Code

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md) before large changes.

Flutter app. This file is always-on project context. Skills load from `.claude/skills/` (invoke with `/skill-name` or when the task matches).

Do not edit `../server`. Commit only in this repo (`peer_task_client`, base `dev`).

## Skills

| Command | When |
| --- | --- |
| `/peertask-flutter-ui` | Screens, widgets, theme, l10n |
| `/peertask-flutter-state` | Riverpod, models, ApiService, Hive |
| `/peertask-realtime-client` | SyncEngine, WebRTC, signaling |
| `/github-commits` | Branch, Conventional Commit, PR |

## Facts

- No `/api` prefix. HTTP only via `lib/services/api_service.dart`.
- Routes in `lib/main.dart`. Public: `/login`, `/forgot-password`, `/reset-password`, `/offline-*`.
- l10n: both `lib/l10n/app_en.arb` and `app_vi.arb`.
- Theme: `AppColors` / `AppTheme` / `AppButton` / `AppDialog` / `AppToast`.
- After freezed/json/riverpod: `dart run build_runner build --delete-conflicting-outputs`.
- Never commit `.env` or hand-edit `*.freezed.dart` / `*.g.dart`.
