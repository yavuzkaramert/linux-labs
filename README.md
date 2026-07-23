# linux-labs

Terminal-only, hands-on Linux practice labs. Each lab runs in a disposable
Docker container — break things freely, `reset` and start over.

## Prerequisites

- Docker (Docker Desktop, OrbStack or Colima)

## Usage

```bash
./labctl list             # list available labs
./labctl start 001        # start lab (fresh container, broken state applied)
./labctl shell 001        # enter the lab as the "student" user
./labctl check 001        # run checks — GEÇTİ / KALDI
./labctl reset 001        # wipe and rebuild the lab
./labctl solution 001     # show the solution
```

Inside the container the lab lives in `/lab` — start with `cat /lab/TASK.md`.
The `student` user has passwordless sudo.

## Adding a new lab

Create `labs/<id>/` (e.g. `labs/002-processes/`) with four files:

| File | Purpose |
|---|---|
| `TASK.md` | What the student must do |
| `setup.sh` | Runs as root on start — creates the broken state |
| `check.sh` | Runs as root — one `[OK]`/`[FAIL]` line per criterion, `exit 1` if any FAIL |
| `solution.md` | Commands + short explanations |

In `check.sh`, test student-perspective criteria with
`su - student -c '...'` (e.g. "student must NOT read this file").
