#!/usr/bin/env bash
# Runs as root inside the container. One [OK]/[FAIL] line per criterion.
set -uo pipefail

fail=0

ok()   { echo "[OK]   $1"; }
bad()  { echo "[FAIL] $1"; fail=1; }

# --- Task 1: /lab/secret/passwords.txt ---
f=/lab/secret/passwords.txt
if [ "$(stat -c '%U:%G' "$f" 2>/dev/null)" = "root:root" ]; then
    ok "$f owned by root:root"
else
    bad "$f must be owned by root:root"
fi

if [ "$(stat -c '%a' "$f" 2>/dev/null)" = "600" ]; then
    ok "$f permissions are 600"
else
    bad "$f permissions must be 600"
fi

# Negative criterion: student must NOT be able to read the file
if su - student -c "cat $f" >/dev/null 2>&1; then
    bad "student can still read $f — must be unreadable"
else
    ok "student cannot read $f"
fi

# --- Task 2: /lab/shared/notes.txt ---
f=/lab/shared/notes.txt
if [ "$(stat -c '%U' "$f" 2>/dev/null)" = "student" ]; then
    ok "$f owned by student"
else
    bad "$f must be owned by student"
fi

if [ "$(stat -c '%a' "$f" 2>/dev/null)" = "644" ]; then
    ok "$f permissions are 644"
else
    bad "$f permissions must be 644"
fi

# --- Task 3: /lab/scripts/backup.sh ---
f=/lab/scripts/backup.sh
if su - student -c "$f" >/dev/null 2>&1; then
    ok "student can execute $f"
else
    bad "student cannot execute $f"
fi

exit "$fail"
