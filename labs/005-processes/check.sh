#!/usr/bin/env bash
# Container içinde root olarak çalışır. Her kriter için bir [OK]/[FAIL] satırı.
# Süreç durumları CANLI okunur (pgrep/ps), dosyadan değil. Süreçler check
# sırasında hâlâ ayakta olmalıdır; check hiçbir süreci öldürmez — temizlik
# setup.sh başında yapılır (labctl reset 005).
set -u

FAIL=0
ok()   { echo "[OK]   $1"; }
bad()  { echo "[FAIL] $1"; FAIL=1; }
note() { echo "[NOTE] $1"; }

R=/srv/reports
PROCS="$R/procs.txt"
NICEF="$R/batch-nice.txt"

# --- Canlı durum: süreçler PID ile degil, komut satiri isaretiyle bulunur ----
# Zombie süreçlerin /proc/PID/cmdline'i bostur → pgrep -f onlari eslemez,
# yani "olduruldu ama reap edilmedi" durumu yanlislikla FAIL uretmez.
HOG_PIDS="$(pgrep -f 'LABPROC-hog'   2>/dev/null || true)"
ROGUE_PIDS="$(pgrep -f 'LABPROC-rogue' 2>/dev/null || true)"
BATCH_PIDS="$(pgrep -f 'LABPROC-batch' 2>/dev/null || true)"
BPID="$(printf '%s\n' "$BATCH_PIDS" | head -n 1)"

BNICE=""
if [ -n "$BPID" ]; then
    BNICE="$(ps -o ni= -p "$BPID" 2>/dev/null | tr -d '[:space:]')"
fi

# --- 1. procs.txt: PID + tam komut satiri, grep kendisi listede yok ----------
r=""
if [ ! -f "$PROCS" ]; then
    r="$PROCS yok"
elif [ ! -s "$PROCS" ]; then
    r="procs.txt bos"
elif grep -qE '(^|[[:space:]]|/)e?grep([[:space:]]|$)' "$PROCS"; then
    r="procs.txt icinde kendi arama komutun (grep) satiri var — elenmeliydi"
elif grep -vE '^[[:space:]]*$' "$PROCS" | grep -qv 'LABPROC'; then
    r="procs.txt icinde LABPROC isareti tasimayan satir var"
elif grep -vE '^[[:space:]]*$' "$PROCS" | grep -qvE '[0-9]'; then
    r="procs.txt satirlarinin hepsinde PID (sayi) yok"
elif [ -z "$BPID" ]; then
    r="LABPROC-batch calismadigi icin liste dogrulanamiyor (bkz. 4. kriter)"
elif ! grep -E "(^|[^0-9])${BPID}([^0-9]|$)" "$PROCS" 2>/dev/null | grep -q 'LABPROC-batch'; then
    r="procs.txt icinde LABPROC-batch sureci PID $BPID ile listelenmemis"
elif ! su - student -c "cat $PROCS" >/dev/null 2>&1; then
    r="procs.txt student tarafindan sudo'suz okunamiyor"
fi
[ -z "$r" ] && ok "procs.txt LABPROC surecleri PID + komut satiri ile listeliyor, grep satiri yok" || bad "$r"

# --- 2. LABPROC-hog artik calismiyor ----------------------------------------
if [ -n "$HOG_PIDS" ]; then
    bad "LABPROC-hog sureci hala calisiyor (PID: $(printf '%s' "$HOG_PIDS" | tr '\n' ' '))"
else
    ok "LABPROC-hog sureci surec tablosunda yok"
fi

# --- 3. LABPROC-rogue artik calismiyor (TERM'i yok sayiyordu) ---------------
if [ -n "$ROGUE_PIDS" ]; then
    bad "LABPROC-rogue sureci hala calisiyor (PID: $(printf '%s' "$ROGUE_PIDS" | tr '\n' ' ')) — kibar sinyali yok sayiyor"
else
    ok "LABPROC-rogue sureci surec tablosunda yok"
fi

# --- 4. LABPROC-batch hala ayakta VE nice >= 10 -----------------------------
r=""
if [ -z "$BPID" ]; then
    r="LABPROC-batch sureci calismiyor — bu surec oldurulmemeliydi, onceligi dusurulmeliydi"
else
    case "$BNICE" in
        ''|*[!0-9-]*) r="LABPROC-batch nice degeri okunamadi (PID $BPID)" ;;
        *)
            if ! [ "$BNICE" -ge 10 ] 2>/dev/null; then
                r="LABPROC-batch nice degeri $BNICE — 10 veya uzeri olmali"
            fi
            ;;
    esac
fi
[ -z "$r" ] && ok "LABPROC-batch calisiyor ve nice degeri $BNICE (>= 10)" || bad "$r"

# --- 5. batch-nice.txt tek sayi ve gercek nice ile ayni ---------------------
r=""
if [ ! -f "$NICEF" ]; then
    r="$NICEF yok"
elif [ "$(grep -c '' "$NICEF")" -ne 1 ]; then
    r="batch-nice.txt tek satir olmali (bulunan: $(grep -c '' "$NICEF"))"
else
    V="$(tr -d '[:space:]' < "$NICEF")"
    case "$V" in
        ''|*[!0-9]*) r="batch-nice.txt tek bir sayi icermeli (bulunan: '$V')" ;;
        *)
            if [ -z "$BPID" ] || [ -z "$BNICE" ]; then
                r="surecin gercek nice degeri okunamadigi icin dosya dogrulanamiyor"
            elif [ "$V" != "$BNICE" ]; then
                r="batch-nice.txt icindeki $V, surecin gercek nice degeri $BNICE ile ayni degil"
            elif ! [ "$V" -ge 10 ] 2>/dev/null; then
                r="batch-nice.txt icindeki $V, 10 veya uzeri olmali"
            elif ! su - student -c "cat $NICEF" >/dev/null 2>&1; then
                r="batch-nice.txt student tarafindan sudo'suz okunamiyor"
            fi
            ;;
    esac
fi
[ -z "$r" ] && ok "batch-nice.txt tek sayi ve surecin gercek nice degeriyle ayni" || bad "$r"

# --- Bilgi: gurultu surecleri kriter degil, ama yanlis hedef gostergesi -----
if pgrep -f 'nightly-batch-runner' >/dev/null 2>&1; then
    note "gurultu sureci (nightly-batch-runner) yasiyor — dogru hedefleme"
else
    note "gurultu sureci (nightly-batch-runner) oldurulmus — LABPROC isareti tasimiyordu, yanlis hedefti"
fi

exit "$FAIL"
