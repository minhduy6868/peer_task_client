---
name: github-commits
description: Creates Conventional Commits and GitHub PRs for peer_task_client. Use when the user asks to commit, branch, open a PR, or write a commit message in the Flutter repo.
---

# GitHub & commits (client)

Repo: `minhduy6868/peer_task_client`. Base branch: `dev`. Production branch: `main`. Work only inside `client/`.

## Branch

```bash
git checkout dev
git pull origin dev
git checkout -b feat/invite-qr
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`. Slug: kebab-case.

## Commit

Only when the user asks. Stage Flutter files only. Never `.env`, keystores, `firebase_options` secrets if they contain private keys.

```
feat(ui): show board permission on workspace cards

Viewers were opening edit dialogs they cannot use.
```

Format: `type(scope): summary` (≤72 chars). Body = why. Scopes: `auth`, `workspace`, `board`, `task`, `p2p`, `ui`, `l10n`, `offline`.

On Windows PowerShell:

```powershell
git commit -m @"
feat(ui): show board permission on workspace cards

Viewers were opening edit dialogs they cannot use.
"@
```

Do not use `git commit --amend` unless the user asked and the commit is yours, unpushed, and not on `dev`. Never `--no-verify` or force-push `dev`/`main`.

## PR

```bash
git push -u origin HEAD
gh pr create --base dev --title "feat(ui): show board permission on workspace cards" --body "$(cat <<'EOF'
## Summary
- Surface board permission on workspace cards so viewers do not tap edit

## Test plan
- [ ] Login as viewer — edit control hidden
- [ ] Login as editor — edit still works
- [ ] en + vi strings present
EOF
)"
```

If `gh` heredoc fails on PowerShell, pass `--body-file` with a temp markdown file.

## Additional resources

- Examples: [examples.md](examples.md)
