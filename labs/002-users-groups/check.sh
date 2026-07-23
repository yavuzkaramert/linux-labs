#!/usr/bin/env bash
# Runs as root inside the container. One [OK]/[FAIL] line per criterion.
set -u

FAIL=0

ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

# True if user $1 is in group $2 (primary or secondary).
in_group() {
    case " $(id -nG "$1" 2>/dev/null) " in
        *" $2 "*) return 0 ;;
        *)        return 1 ;;
    esac
}

user_shell() { getent passwd "$1" | cut -d: -f7; }

# --- 1. developers group, GID exactly 4000 ---
gid="$(getent group developers | cut -d: -f3)"
if [ "$gid" = "4000" ]; then
    ok "developers group exists with GID 4000"
else
    bad "developers group must have GID exactly 4000 (found: ${gid:-missing})"
fi

# --- 2. ayse and mehmet: home dir + bash shell ---
r=""
for u in ayse mehmet; do
    if ! id "$u" >/dev/null 2>&1; then
        r="user $u does not exist"; break
    fi
    if [ "$(stat -c '%U' "/home/$u" 2>/dev/null)" != "$u" ]; then
        r="/home/$u must exist and be owned by $u"; break
    fi
    if [ "$(user_shell "$u")" != "/bin/bash" ]; then
        r="$u login shell must be /bin/bash (found: $(user_shell "$u"))"; break
    fi
done
if [ -z "$r" ]; then
    ok "ayse and mehmet exist with /bin/bash and own their home dirs"
else
    bad "$r"
fi

# --- 3. primary group = own name, developers as secondary ---
r=""
for u in ayse mehmet; do
    if ! id "$u" >/dev/null 2>&1; then
        r="user $u does not exist"; break
    fi
    if [ "$(id -gn "$u")" != "$u" ]; then
        r="$u primary group must be $u (found: $(id -gn "$u"))"; break
    fi
    if ! in_group "$u" developers; then
        r="$u must have developers as a secondary group"; break
    fi
done
if [ -z "$r" ]; then
    ok "primary groups are per-user; developers is secondary for both"
else
    bad "$r"
fi

# --- 4. deploybot: nologin shell, in developers, no home ---
r=""
if ! id deploybot >/dev/null 2>&1; then
    r="service account deploybot does not exist"
else
    case "$(user_shell deploybot)" in
        *nologin) ;;
        *) r="deploybot shell must be nologin (found: $(user_shell deploybot))" ;;
    esac
    if [ -z "$r" ] && ! in_group deploybot developers; then
        r="deploybot must be a member of developers"
    fi
    if [ -z "$r" ] && [ -e /home/deploybot ]; then
        r="/home/deploybot must not exist"
    fi
fi
if [ -z "$r" ]; then
    ok "deploybot: nologin shell, in developers, no home dir"
else
    bad "$r"
fi

# --- 5. /srv/project: root:developers, mode exactly 2770 ---
state="$(stat -c '%U:%G:%a' /srv/project 2>/dev/null)"
if [ "$state" = "root:developers:2770" ]; then
    ok "/srv/project is root:developers with mode 2770"
else
    bad "/srv/project must be root:developers with mode exactly 2770 (found: ${state:-missing})"
fi

# --- 6. functional test: ayse creates, group auto-set, mehmet writes ---
probe=/srv/project/.checkprobe
rm -f "$probe"
r=""
if ! su - ayse -c "touch $probe && chmod 660 $probe" >/dev/null 2>&1; then
    r="ayse cannot create files in /srv/project"
elif [ "$(stat -c '%G' "$probe" 2>/dev/null)" != "developers" ]; then
    r="new files in /srv/project must automatically get group developers (found: $(stat -c '%G' "$probe" 2>/dev/null))"
elif ! su - mehmet -c "printf x >> $probe" >/dev/null 2>&1; then
    r="mehmet cannot write to a file ayse created in /srv/project"
fi
rm -f "$probe"
if [ -z "$r" ]; then
    ok "ayse creates in /srv/project, group auto-developers, mehmet can write"
else
    bad "$r"
fi

# --- 7. negative: tolga fully removed ---
r=""
if id tolga >/dev/null 2>&1; then
    r="user tolga must not exist"
elif [ -e /home/tolga ]; then
    r="/home/tolga must not exist"
fi
if [ -z "$r" ]; then
    ok "tolga account and /home/tolga are gone"
else
    bad "$r"
fi

# --- 8. negative: ayse not in sudo ---
if in_group ayse sudo; then
    bad "ayse must not be in the sudo group"
else
    ok "ayse is not in the sudo group"
fi

exit "$FAIL"
