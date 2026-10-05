---
name: peertask-flutter-ui
description: Builds and fixes PeerTask Flutter UI and UX. Use when editing lib/ui, dialogs, theme, l10n, layout overflow, or any user-visible screen in the client repo.
---

# PeerTask Flutter UI

Light utility app. Tasks are the product. Drawing is a second page on the board.

## UX

- One palette: `AppColors` and `AppTextStyles`. Primary `#4A90E2`, background `#F8FBFF`, surface white. No one-off hex and no `Colors.blue` / `Colors.green` / `Colors.red` for chrome.
- Every user-visible string uses `AppLocalizations.of(context)!`. Add the key to both `lib/l10n/app_en.arb` and `app_vi.arb`, then run `flutter gen-l10n`.
- Dialogs use `insetPadding` and a width of at most `screenWidth - 40`. Never set `width: 500` (or any fixed width) on a phone. `TabBarView`, camera, and lists need a parent with a real height (`SizedBox` or `Expanded` inside a bounded box).
- Below 480px, put paired fields and action buttons in a `Column` or `Wrap`. Names and nav labels use `maxLines: 1` and `TextOverflow.ellipsis`.
- A screen with no `AppBar` starts in `SafeArea`.
- Hide actions that do nothing. Do not ship disabled social buttons or menu rows with an empty `onTap`.
- Errors go through `context.showErrorSnackBar` or `ErrorDisplay`. Never show `error.toString()`.
- A dialog pops once, returning a value. The caller navigates after `showDialog` completes. Do not pop in both the dialog and the callback.
- Destructive actions use `AppColors.error` and a confirm step.
- New controls reuse `AppButton`, `AppDialog`, `AppToast`, and `AppCard`.

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

Add routes in `lib/main.dart` and update `redirect`. After login, restore `storage.getLastWorkspace()`.

## Widgets

1. `ConsumerWidget` / `ConsumerStatefulWidget`. Watch providers. Never construct `ApiService(...)` in a widget.
2. Copy, theme, and errors follow the UX rules above.

```dart
AppButton(
  label: l10n.save,
  isLoading: saving,
  isFullWidth: true,
  onPressed: () => ref.read(boardProvider.notifier).save(),
)
```

## Additional resources

- Widget inventory: [reference.md](reference.md)
