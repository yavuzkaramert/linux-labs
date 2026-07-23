# Hints — Lab 002: Users & Groups

## Seviye 1

- Every user has exactly one primary group (used for new files by default)
  and can have many secondary groups. Membership in `developers` here is
  the secondary kind — don't replace the primary group.
- A group's numeric ID (GID) can be changed after the group is created;
  you don't need to delete and recreate it.
- Service accounts should not allow interactive logins: they get a special
  shell whose only job is to refuse login. They also usually get no home
  directory at all.
- A shared team directory relies on two things: group ownership plus the
  setgid bit on the directory. Setgid on a directory makes every new file
  inside inherit the directory's group instead of the creator's primary group.
- Permission modes with a special bit are written with four octal digits —
  the leading digit encodes setuid/setgid/sticky.
- Removing a user and removing their home directory are two separate
  concerns; one command can do both if asked to.

## Seviye 2

- Group GID change: `groupmod`
- Modify an existing user (shell, extra groups): `usermod`
- Create users: `useradd`
- Remove a user from a group: `gpasswd` (or `deluser`)
- Delete a user: `userdel`
- Directory ownership and mode: `chown`, `chmod`
- Inspect state: `id`, `getent`, `stat`

## Seviye 3

- `groupmod`: `-g` sets the new GID.
- `usermod`: `-s` changes the shell, `-a` together with `-G` appends
  secondary groups (without `-a` you overwrite the whole list).
- `gpasswd`: `-d` removes a user from a group.
- `useradd`: `-m` creates the home dir, `-M` skips it, `-s` sets the shell,
  `-G` adds secondary groups, `-r` marks a system account.
- `userdel`: `-r` also removes the home directory.
- `chmod`: a leading `2` in a four-digit mode is the setgid bit.
- Verify with `id -nG <user>`, `getent group <group>`, `stat -c '%U %G %a'`.
