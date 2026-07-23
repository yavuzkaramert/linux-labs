# Solution — Lab 001: File Permissions

## Task 1 — lock down the secret file

```bash
sudo chown root:root /lab/secret/passwords.txt   # ensure root owns it
sudo chmod 600 /lab/secret/passwords.txt         # only root can read/write
```

`600` = owner rw, group none, others none. Since the owner is root,
`student` gets the "others" slot: no access.

## Task 2 — take ownership of the notes

```bash
sudo chown student /lab/shared/notes.txt   # student becomes owner
sudo chmod 644 /lab/shared/notes.txt       # owner rw, everyone else read-only
```

## Task 3 — make the script executable

```bash
sudo chmod +x /lab/scripts/backup.sh   # adds execute bit for all
/lab/scripts/backup.sh                 # verify: prints "backup completed"
```

## Verify

From the host: `labctl check 001` — all criteria should print `[OK]`.
