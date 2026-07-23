#!/usr/bin/env bash
# Runs as root. Creates the broken state for lab 002. Idempotent.
set -euo pipefail

# Criterion 1: developers group exists but with the wrong GID
if getent group developers >/dev/null; then
    groupmod -g 5000 developers
else
    groupadd -g 5000 developers
fi

# Criteria 2/3/8: ayse exists but half-configured — wrong shell,
# not in developers, and wrongly added to sudo
if ! id ayse >/dev/null 2>&1; then
    useradd -m ayse
fi
usermod -s /bin/sh ayse
gpasswd -d ayse developers >/dev/null 2>&1 || true
usermod -aG sudo ayse

# Criteria 2/3: mehmet was never created
userdel -r mehmet >/dev/null 2>&1 || true

# Criterion 4: deploybot was never created
userdel deploybot >/dev/null 2>&1 || true
rm -rf /home/deploybot

# Criteria 5/6: project dir left with default ownership and permissions
rm -rf /srv/project
mkdir -p /srv/project
chown root:root /srv/project
chmod 0755 /srv/project

# Criterion 7: tolga left the company but his account is still around
if ! id tolga >/dev/null 2>&1; then
    useradd -m -s /bin/bash tolga
fi
printf 'deploy notes from 2024, probably outdated\n' > /home/tolga/notes.txt
printf '#!/bin/sh\necho "old deploy script"\n' > /home/tolga/deploy.sh
chown -R tolga:tolga /home/tolga

echo "setup done"
