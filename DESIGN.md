# PeerTask design

Utility task app. Tasks are the product. Drawing is a second page on the board.

- Theme: light. Background `#F7F4FF`, surface white, soft violet `#8B7CFF`.
- Public entry is the landing page. Login is the next step.
- Density: comfortable lists, not a marketing landing page.
- Errors: `ApiError.userMessage` via `ErrorDisplay`. Never print the exception object.
- Navigation: workspace shell stays; board opens on the task board, canvas is optional.
- Dialogs fit the screen. Strings come from en/vi l10n. Follow `.cursor/skills/peertask-flutter-ui/SKILL.md`.
