# PeerTask design

Utility task app. Tasks are the product. Drawing is a second page on the board.

- Theme: light. Background `#F8FBFF`, surface white, accent `#4A90E2`.
- Density: comfortable lists, not a marketing landing page.
- Errors: `ApiError.userMessage` via `ErrorDisplay`. Never print the exception object.
- Navigation: workspace shell stays; board opens on the task board, canvas is optional.
