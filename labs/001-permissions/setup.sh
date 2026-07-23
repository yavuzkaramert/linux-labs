#!/usr/bin/env bash
# Runs as root. Creates the broken state for lab 001.
set -euo pipefail

mkdir -p /lab/secret /lab/shared /lab/scripts

# Task 1: secret file left world-readable
printf 'admin:hunter2\nroot:toor\n' > /lab/secret/passwords.txt
chown root:root /lab/secret/passwords.txt
chmod 644 /lab/secret/passwords.txt
chmod 755 /lab/secret

# Task 2: notes file owned by root instead of student
printf 'Team notes: rotate backups weekly.\n' > /lab/shared/notes.txt
chown root:root /lab/shared/notes.txt
chmod 644 /lab/shared/notes.txt

# Task 3: script missing execute bit
cat > /lab/scripts/backup.sh <<'EOF'
#!/usr/bin/env bash
echo "backup completed"
EOF
chown root:root /lab/scripts/backup.sh
chmod 644 /lab/scripts/backup.sh

echo "setup done"
