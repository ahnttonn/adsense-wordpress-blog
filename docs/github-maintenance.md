# GitHub Maintenance Runbook

## Identity
- GitHub SSH host: `github.com`
- SSH key identity: `~/.ssh/ahnttonn`
- Expected GitHub account: `ahnttonn`
- Remote URL format: `git@github.com:ahnttonn/adsense-wordpress-blog.git`

The local `~/.ssh/config` should contain:

```sshconfig
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/ahnttonn
  IdentitiesOnly yes
```

Verify authentication:

```bash
ssh -T git@github.com
```

Expected output:

```text
Hi ahnttonn! You've successfully authenticated, but GitHub does not provide shell access.
```

## Branches
- `main`: production-ready infrastructure, docs, theme/config changes.
- `work/<task-slug>`: implementation branches for Codex work.
- `content/<topic-slug>`: editorial drafts and launch article work.
- `fix/<issue-slug>`: urgent fixes.

## Standard Workflow
```bash
git status --short
git checkout -b work/<task-slug>
git pull --ff-only origin main
git add <files>
git commit -m "<type>(<scope>): <summary>"
git push -u origin work/<task-slug>
```

Use SSH remotes only:

```bash
git remote set-url origin git@github.com:ahnttonn/adsense-wordpress-blog.git
git remote -v
```

Never use an HTTPS remote for this project.

## Release Tags
Tag only after the deployed state is verified:

```bash
git tag -a vYYYY.MM.DD-N -m "Release vYYYY.MM.DD-N"
git push origin vYYYY.MM.DD-N
```

## Rollback By Commit
For documentation/config rollback:

```bash
git log --oneline --decorate -n 20
git revert <bad-commit-sha>
git push origin HEAD
```

For production WordPress rollback, restore files/database from the backup runbook first, then commit the corrected infrastructure/config state.

## Secret Handling
Do not commit:
- Private SSH keys, OCI credentials, registrar/Cloudflare credentials, or GitHub tokens.
- `.env` files, WordPress salts, database credentials, backup archives, SQL dumps, uploaded media, cache files, or AdSense publisher secrets.
- Search Console verification files unless they are intentionally public and documented.

Before every commit:

```bash
git status --short
git diff --cached --name-only
git diff --cached --check
```

If a secret is staged, unstage it and rotate the exposed credential if it ever left the local machine.

## Remote Creation Checkpoint
If the GitHub repository does not exist yet, create an empty private or public repository named `adsense-wordpress-blog` under `ahnttonn`, then run:

```bash
git remote add origin git@github.com:ahnttonn/adsense-wordpress-blog.git
git push -u origin main
```

Do not store a GitHub personal access token in this repository or on the server.
