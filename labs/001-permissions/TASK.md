# Lab 001 — File Permissions

A previous admin left `/lab` in a mess. Fix the permissions.

## Tasks

1. `/lab/secret/passwords.txt` is world-readable. Lock it down:
   - Owner must be `root`, group `root`.
   - Permissions must be `600` (only root can read/write).
   - The `student` user must NOT be able to read it.

2. `/lab/shared/notes.txt` belongs to root, so you can't edit it:
   - Make `student` the owner.
   - Permissions must be `644`.

3. `/lab/scripts/backup.sh` won't run:
   - Make it executable so `student` can run it successfully.

## Hints

- `ls -l` shows owner, group and permissions.
- You have passwordless `sudo`.
- Check your work anytime from your host terminal: `labctl check 001`
