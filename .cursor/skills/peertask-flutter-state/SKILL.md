---
name: peertask-flutter-state
description: Riverpod providers, freezed models, Hive storage, and ApiService patterns for the PeerTask Flutter client. Use when changing client state, models, or HTTP calls.
---

# PeerTask Flutter state

## Layers

```
Widget → Riverpod notifier → ApiService / Signaling / Storage / Config
```

- Providers: `lib/providers/app_providers.dart`, `language_provider.dart`, `offline_board_provider.dart`
- Override `storageServiceProvider` and `configServiceProvider` only in `main.dart`

## Models

| Model | Notes |
| --- | --- |
| `User` | custom `fromJson` (`created_at` / `createdAt`) |
| `Workspace` | `owner_id`, optional `role` |
| `Board` | `permission`, `is_board_owner` |
| `TaskModel` | status/priority/assignees/labels/parent |
| `Operation` | `opId`, `actor`, `timestamp`, `type`, `payload` |
| `ApiError` | `userMessage` (vi) |

Codegen after `@freezed` / json / riverpod annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Do not edit `*.freezed.dart` / `*.g.dart`.

## ApiService

- Base URL from `ConfigService` (Hive → Firebase REST → `assets/config.json` → localhost).
- No `/api` prefix. Headers: Bearer + `ngrok-skip-browser-warning`.
- 401 → `POST /token/refresh` once, then `clearTokens`.
- New methods: `_get`/`_post`/`_put` + `_handleResponse`. Do not `throw Exception(response.body)`.

## Persistence

`StorageService` (Hive): access token, refresh token, user JSON, last workspace. Never store passwords.
