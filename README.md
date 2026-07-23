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
./labctl hint 002 1       # progressive hint, level 1-3 (default: 1)
./labctl solution 001     # show the solution
```

Stuck? Recommended order: try it yourself → `man <command>` →
`hint 1` → `hint 2` → `hint 3` → `solution`.

Every passed `check` auto-commits your progress (`lab <id> solved`).

Inside the container the lab lives in `/lab` — start with `cat /lab/TASK.md`.
The `student` user has passwordless sudo.

## Adding a new lab

Create `labs/<id>/` (e.g. `labs/002-processes/`) with five files:

| File | Purpose |
|---|---|
| `TASK.md` | Pure requirements: story + tasks + acceptance criteria. No hints section |
| `setup.sh` | Runs as root on start — creates the broken state |
| `check.sh` | Runs as root — one `[OK]`/`[FAIL]` line per criterion, `exit 1` if any FAIL |
| `hints.md` | Three sections: `## Seviye 1` (conceptual, no command names), `## Seviye 2` (command names, no flags), `## Seviye 3` (flags/params, no full command) |
| `solution.md` | Commands + short explanations |

Lab 001 predates `hints.md` and stays in the old 4-file format.

In `check.sh`, test student-perspective criteria with
`su - student -c '...'` (e.g. "student must NOT read this file").
