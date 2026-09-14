---
name: peertask-flutter-ui
description: Builds PeerTask Flutter screens with Riverpod, go_router, AppTheme, shared widgets, and en/vi l10n. Use when editing lib/ui, theme, dialogs, or localization in the client repo.
---

# PeerTask Flutter UI

## Screen map

| Route | Screen | Auth |
| --- | --- | --- |
| `/login` | `LoginScreen` | public |
| `/forgot-password` | `ForgotPasswordScreen` | public |
| `/reset-password` | `ResetPasswordScreen` | public (`?token=`) |
| `/workspaces` | `WorkspaceSelectionScreen` | yes |
| `/workspace/:id/boards` | `WorkspaceHomeScreen` | yes |
| `/board/:id` | `BoardScreen` | yes |
| `/offline-username` | `OfflineUsernameScreen` | no |
| `/offline-boards` | `OfflineBoardsScreen` | no |
| `/offline-board/:id` | `OfflineBoardScreen` | no |

Add routes in `lib/main.dart` **and** update `redirect`. After login, restore `storage.getLastWorkspace()`.

## UI rules

1. `ConsumerWidget` / `ConsumerStatefulWidget`. Watch providers — never `ApiService(...)` in widgets.
2. `AppColors`, `AppTextStyles`, `AppTheme`. Shared: `AppButton`, `AppDialog`, `AppToast`, `AppCard`.
3. Copy: `AppLocalizations.of(context)!`. Keys in **both** `lib/l10n/app_en.arb` and `app_vi.arb`.
4. Errors: `ApiError.userMessage` or `utils/error_display.dart`.
5. Deletes: `AppDialog.showConfirm(..., isDanger: true)`.

```dart
AppButton(
  label: l10n.save,
  isLoading: saving,
  isFullWidth: true,
  onPressed: () => ref.read(boardProvider.notifier).save(),
)
```

## Habits already in the app

- Surfaces: background `#F8FBFF`, cards white, radius 16–24
- Board cards: `AppColors.getBoardGradient(index)`
- Task colors: semantic `success` / `warning` / `info`
- Canvas + tasks: `BoardScreen`, `task_list_panel.dart`, `task_dialog.dart`

## Additional resources

- Widget inventory: [reference.md](reference.md)
