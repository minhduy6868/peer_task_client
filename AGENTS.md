# PeerTask client — agent guide

Flutter app. This repo only — do not edit `../server`.

Product docs: [README.md](README.md) · [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) · [docs/REQUIREMENTS.md](docs/REQUIREMENTS.md).

## Tool paths

| Tool | Always-on | Skills |
| --- | --- | --- |
| Cursor | `.cursor/rules/` | `.cursor/skills/` |
| Codex | `AGENTS.md` | `.agents/skills/` ([docs](https://developers.openai.com/codex/skills)) |
| Claude Code | `CLAUDE.md` | `.claude/skills/` ([docs](https://code.claude.com/docs/en/skills)) |

Keep the three skill trees in sync (same `SKILL.md` names and body).

## Skills

| Skill | When |
| --- | --- |
| `peertask-flutter-ui` | Screens, widgets, theme, l10n |
| `peertask-flutter-state` | Riverpod, models, ApiService, Hive |
| `peertask-realtime-client` | SyncEngine, WebRTC, signaling client |
| `github-commits` | Branches, commits, PRs |

Codex: `$peertask-flutter-ui` or `/skills`. Claude: `/peertask-flutter-ui`.

## Facts

- API has **no** `/api` prefix. Use `ApiService` only.
- Routes in `lib/main.dart`. Public: `/login`, `/forgot-password`, `/reset-password`, `/offline-*`.
- l10n: both `lib/l10n/app_en.arb` and `app_vi.arb`.
- Theme: `AppColors` / `AppTheme` / `AppButton` / `AppDialog` / `AppToast`.
- After freezed/json/riverpod changes: `dart run build_runner build --delete-conflicting-outputs`.

## Git

Upstream: `https://github.com/minhduy6868/peer_task_client` (`dev`).
