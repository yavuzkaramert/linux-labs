# Solution — Lab 002: Users & Groups

Run inside the lab shell (`labctl shell 002`); `student` has passwordless sudo.

## 1. Fix the developers GID

```bash
sudo groupmod -g 4000 developers   # renumber the existing group to GID 4000
```

## 2–3. Repair ayse, create mehmet

```bash
sudo usermod -s /bin/bash ayse        # give ayse a proper login shell
sudo usermod -aG developers ayse      # append developers as a secondary group
sudo useradd -m -s /bin/bash mehmet   # create mehmet with home dir and bash
sudo usermod -aG developers mehmet    # mehmet joins developers as secondary
```

`useradd` on Ubuntu creates a same-named primary group per user by default,
which satisfies the primary-group criterion.

## 4. Create the deploybot service account

```bash
sudo useradd -r -M -s /usr/sbin/nologin -G developers deploybot
# system account (-r), no home dir (-M), login refused (nologin), in developers
```

## 5–6. Set up the shared project directory

```bash
sudo chown root:developers /srv/project   # root owns it, developers is the group
sudo chmod 2770 /srv/project              # setgid + rwx for owner and group only
```

The setgid bit (the leading `2`) makes every new file inside inherit the
`developers` group, so mehmet can write to files ayse creates there.

## 7. Remove tolga completely

```bash
sudo userdel -r tolga   # delete the account and its home directory
```

## 8. Take ayse out of sudo

```bash
sudo gpasswd -d ayse sudo   # remove ayse from the sudo group
```

## Verify

From the host: `labctl check 002` — all eight criteria should print `[OK]`.
