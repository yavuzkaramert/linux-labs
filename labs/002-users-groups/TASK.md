# Lab 002 — Users & Groups

Your company just acquired a small startup, and you inherited their only
server. The previous admin left in a hurry: accounts are half-created,
an ex-employee still has access, and the shared project directory was
never set up properly. Bring the server to the state below.

## Acceptance criteria

1. A group named `developers` exists and its GID is exactly `4000`.

2. Regular users `ayse` and `mehmet` exist. Each has a home directory at
   `/home/<name>` owned by themselves, and their login shell is `/bin/bash`.

3. For both users, the primary group is a group with the same name as the
   user. `developers` is a secondary (supplementary) group for both.

4. A service account `deploybot` exists. Its shell must refuse interactive
   logins (nologin), it is a member of `developers`, and `/home/deploybot`
   must NOT exist.

5. The directory `/srv/project` is owned by user `root` and group
   `developers`, and its permissions are exactly `2770`.

6. `ayse` can create files inside `/srv/project`. Any file she creates
   there automatically gets the group `developers`, and `mehmet` can
   write to that file.

7. The user `tolga` no longer works here. Neither the account `tolga`
   nor `/home/tolga` exists on the system.

8. `ayse` is NOT in the `sudo` group.

## Checking your work

From your host terminal: `labctl check 002`
Stuck? `labctl hint 002 1` (levels 1–3, each more specific).
