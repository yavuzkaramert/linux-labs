#!/usr/bin/env bash
# Container içinde root olarak çalışır. Her kriter için bir [OK]/[FAIL] satırı.
# set -e YOK: bir kriterin düşmesi diğerlerini durdurmaz (accumulator pattern).
#
# İlkeler:
#  * Kullanıcı-perspektifi testlerinin HEPSİ `su - student -c` ile koşar.
#  * stdout ve stderr AYRI dosyalara yakalanır; "stdout boş olmalı" diyen
#    kriter gerçekten boyut sıfır kontrol eder.
#  * Beklenen değerler HESAPLANIR, sabit yazılmaz — app.log değişirse check
#    kendini uyarlar.
#  * Her kriter bağımsızdır: script hiç yoksa o kriter FAIL verip devam eder.
set -u

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

BINDIR=/usr/local/bin
APPLOG=/var/log/labapp/app.log
SECURE=/var/log/labapp/secure.log
LIST=/etc/labs/services.list
DAILY=/srv/reports/daily.txt

SO="$(mktemp)"; SE="$(mktemp)"; T1="$(mktemp)"; T2="$(mktemp)"
LISTBAK="$(mktemp)"
cleanup() { rm -f "$SO" "$SE" "$T1" "$T2" "$LISTBAK"; }
trap cleanup EXIT

RC=0
# $1 = student olarak koşacak komut dizgesi. Çıkış kodu hemen RC'ye alınır.
run_student() {
    : > "$SO"; : > "$SE"
    su - student -c "$1" >"$SO" 2>"$SE"
    RC=$?
}

# --- Beklenen seviye sayımları: app.log'dan türetilir ------------------------
EXPECTED="$(awk -F'|' 'NF >= 2 { c[$2]++ } END { for (l in c) printf "%s:%d\n", l, c[l] }' \
            "$APPLOG" 2>/dev/null | sort)"

# --- Gerçek servis PID'leri: comm (surec adi) uzerinden okunur ---------------
# -x tam comm eslesmesi ister. `-f` KULLANILMAZ: o, isareti argüman olarak
# tasiyan su / bash -c / svccheck sureclerini de eslestirir ve referans PID
# rastgele degisir.
WEB_PIDS="$(pgrep -x labapp-web    2>/dev/null || true)"
WRK_PIDS="$(pgrep -x labapp-worker 2>/dev/null || true)"
CCH_PIDS="$(pgrep -x labapp-cache  2>/dev/null || true)"

# pid_in <pid> <pid listesi>
pid_in() {
    local needle="$1" p
    for p in $2; do [ "$p" = "$needle" ] && return 0; done
    return 1
}

# --- 1. logsum başarı yolu ---------------------------------------------------
r=""
if [ ! -x "$BINDIR/logsum" ]; then
    r="$BINDIR/logsum student tarafindan calistirilabilir degil"
elif [ -z "$EXPECTED" ]; then
    r="beklenen sayimlar $APPLOG'dan turetilemedi (lab ortami bozuk)"
else
    run_student "logsum $APPLOG"
    GOT="$(sort "$SO")"
    if [ "$RC" -ne 0 ]; then
        r="logsum $APPLOG cikis kodu $RC — 0 olmaliydi"
    elif [ ! -s "$SO" ]; then
        r="logsum standart cikti uretmedi"
    elif grep -qvE '^[A-Z]+:[0-9]+$' "$SO"; then
        r="logsum ciktisinda SEVIYE:sayi kalibina uymayan satir var: $(grep -m1 -vE '^[A-Z]+:[0-9]+$' "$SO")"
    elif [ "$GOT" != "$EXPECTED" ]; then
        r="logsum sayimlari yanlis. beklenen: $(echo "$EXPECTED" | tr '\n' ' ')| gelen: $(echo "$GOT" | tr '\n' ' ')"
    fi
fi
[ -z "$r" ] && ok "logsum seviye sayimlarini dogru biciminde ve dogru degerlerle basiyor (cikis 0)" || bad "$r"

# --- 2. logsum argümansız ----------------------------------------------------
r=""
if [ ! -x "$BINDIR/logsum" ]; then
    r="$BINDIR/logsum student tarafindan calistirilabilir degil"
else
    run_student "logsum"
    if [ "$RC" -ne 2 ]; then
        r="argumansiz logsum cikis kodu $RC — 2 olmaliydi"
    elif [ -s "$SO" ]; then
        r="argumansiz logsum standart ciktiya yazdi — hicbir sey yazmamaliydi"
    elif [ ! -s "$SE" ]; then
        r="argumansiz logsum standart hataya kullanim mesaji yazmadi"
    fi
fi
[ -z "$r" ] && ok "argumansiz logsum: stdout bos, stderr dolu, cikis kodu 2" || bad "$r"

# --- 3. logsum olmayan dosya -------------------------------------------------
r=""
if [ ! -x "$BINDIR/logsum" ]; then
    r="$BINDIR/logsum student tarafindan calistirilabilir degil"
else
    run_student "logsum /var/log/labapp/yok.log"
    if [ "$RC" -ne 3 ]; then
        r="olmayan dosya icin cikis kodu $RC — 3 olmaliydi"
    elif [ -s "$SO" ]; then
        r="olmayan dosya icin standart ciktiya yazildi — yazilmamaliydi"
    elif [ ! -s "$SE" ]; then
        r="olmayan dosya icin standart hataya mesaj yazilmadi"
    fi
fi
[ -z "$r" ] && ok "olmayan dosya: stdout bos, stderr dolu, cikis kodu 3" || bad "$r"

# --- 4. logsum okunamayan dosya (var ama student okuyamiyor) ----------------
r=""
if [ ! -x "$BINDIR/logsum" ]; then
    r="$BINDIR/logsum student tarafindan calistirilabilir degil"
elif [ ! -f "$SECURE" ]; then
    r="$SECURE yok (lab ortami bozuk)"
else
    run_student "logsum $SECURE"
    if [ "$RC" -ne 3 ]; then
        r="okunamayan dosya icin cikis kodu $RC — 3 olmaliydi (sadece 'dosya var mi' bakiliyor olabilir)"
    elif [ -s "$SO" ]; then
        r="okunamayan dosya icin standart ciktiya yazildi — yazilmamaliydi"
    fi
fi
[ -z "$r" ] && ok "okunamayan dosya: cikis kodu 3, stdout bos (-f degil -r kontrolu)" || bad "$r"

# --- 5. svccheck çıktı biçimi ve PID doğruluğu ------------------------------
# Bu adımın çıktısı 7. kriterde tekrar kullanılır.
: > "$T1"
r=""
if [ ! -x "$BINDIR/svccheck" ]; then
    r="$BINDIR/svccheck yok ya da calistirilabilir degil"
elif [ -z "$WEB_PIDS" ] || [ -z "$WRK_PIDS" ]; then
    r="servis surecleri ayakta degil (lab ortami bozuk — labctl reset 006)"
else
    run_student "svccheck labapp-web labapp-queue labapp-worker"
    cp "$SO" "$T1"
    L1="$(sed -n 1p "$SO")"; L2="$(sed -n 2p "$SO")"; L3="$(sed -n 3p "$SO")"
    N="$(grep -c '' "$SO")"
    if [ "$N" -ne 3 ]; then
        r="svccheck 3 arguman icin $N satir bastı — 3 olmaliydi"
    elif ! printf '%s' "$L1" | grep -qE '^\[OK\] labapp-web [0-9]+$'; then
        r="1. satir '[OK] labapp-web <pid>' bicimde degil: '$L1'"
    elif ! printf '%s' "$L2" | grep -qE '^\[FAIL\] labapp-queue$'; then
        r="2. satir '[FAIL] labapp-queue' olmaliydi: '$L2'"
    elif ! printf '%s' "$L3" | grep -qE '^\[OK\] labapp-worker [0-9]+$'; then
        r="3. satir '[OK] labapp-worker <pid>' bicimde degil: '$L3'"
    elif ! pid_in "${L1##* }" "$WEB_PIDS"; then
        r="labapp-web icin yazilan PID ${L1##* } gercek degil (gercek: $(echo "$WEB_PIDS" | tr '\n' ' '))"
    elif ! pid_in "${L3##* }" "$WRK_PIDS"; then
        r="labapp-worker icin yazilan PID ${L3##* } gercek degil (gercek: $(echo "$WRK_PIDS" | tr '\n' ' '))"
    fi
fi
[ -z "$r" ] && ok "svccheck sirayi koruyor, bicim dogru ve yazilan PID'ler gercek" || bad "$r"

# --- 6. svccheck çıkış kodları ----------------------------------------------
r=""
if [ ! -x "$BINDIR/svccheck" ]; then
    r="$BINDIR/svccheck yok ya da calistirilabilir degil"
else
    run_student "svccheck labapp-web labapp-cache"
    if [ "$RC" -ne 0 ]; then
        r="hepsi ayaktayken cikis kodu $RC — 0 olmaliydi"
    else
        run_student "svccheck labapp-web labapp-queue"
        if [ "$RC" -ne 1 ]; then
            r="aralarinda ayakta olmayan varken cikis kodu $RC — 1 olmaliydi"
        else
            run_student "svccheck"
            if [ "$RC" -ne 2 ]; then
                r="argumansiz cikis kodu $RC — 2 olmaliydi"
            elif [ -s "$SO" ]; then
                r="argumansiz svccheck standart ciktiya yazdi"
            elif [ ! -s "$SE" ]; then
                r="argumansiz svccheck standart hataya kullanim mesaji yazmadi"
            fi
        fi
    fi
fi
[ -z "$r" ] && ok "svccheck cikis kodlari: hepsi ayakta 0, eksik var 1, argumansiz 2" || bad "$r"

# --- 7. svccheck kendi arama sürecini listelemiyor ---------------------------
r=""
if [ ! -s "$T1" ]; then
    r="svccheck ciktisi alinamadi (bkz. 5. kriter)"
elif grep -qE '(svccheck|pgrep|grep)' "$T1"; then
    r="svccheck ciktisinda kendi arama sureci gorunuyor: $(grep -m1 -E '(svccheck|pgrep|grep)' "$T1")"
elif [ "$(grep -c '' "$T1")" -ne 3 ]; then
    r="svccheck satir sayisi arguman sayisina esit degil"
else
    # Her [OK] satirinin PID'i GERCEKTEN o servisin sureci mi? Tam komut
    # satirinda arayan bir cozum, isareti argüman olarak tasiyan kendi
    # sureclerini (svccheck, su, bash -c, komut ikamesinin alt kabugu)
    # eslestirir ve hayalet bir PID basar; comm karsilastirmasi onu yakalar.
    while IFS= read -r line; do
        case "$line" in
            '[OK] '*) ;;
            *) continue ;;
        esac
        m="$(printf '%s' "$line" | awk '{print $2}')"
        p="$(printf '%s' "$line" | awk '{print $3}')"
        c="$(ps -o comm= -p "$p" 2>/dev/null | tr -d '[:space:]')"
        if [ -z "$c" ]; then
            r="svccheck '$m' icin PID $p yazdi ama boyle bir surec yok — kendi arama zincirinden gelen hayalet PID"
            break
        elif [ "$c" != "$m" ]; then
            r="svccheck '$m' icin PID $p yazdi ama o surecin adi '$c' — kendi arama zincirinden gelen PID"
            break
        fi
    done < "$T1"
fi
[ -z "$r" ] && ok "svccheck kendi arama sureci ciktiya karismiyor" || bad "$r"

# --- 8. report — DEGRADED yolu ----------------------------------------------
r=""
if [ ! -x "$BINDIR/report" ]; then
    r="$BINDIR/report yok ya da calistirilabilir degil"
else
    rm -f "$DAILY"
    run_student "report"
    if [ "$RC" -ne 1 ]; then
        r="report cikis kodu $RC — labapp-queue ayakta olmadigi icin 1 olmaliydi"
    elif [ ! -f "$DAILY" ]; then
        r="$DAILY olusmadi"
    elif [ "$(sed -n 1p "$DAILY")" != "DEGRADED" ]; then
        r="$DAILY ilk satiri 'DEGRADED' degil: '$(sed -n 1p "$DAILY")'"
    fi
fi
[ -z "$r" ] && ok "report DEGRADED yolunda 1 ile cikiyor ve daily.txt ilk satiri DEGRADED" || bad "$r"

# --- 9. report — içerik ------------------------------------------------------
r=""
if [ ! -f "$DAILY" ]; then
    r="$DAILY yok (bkz. 8. kriter)"
elif [ -z "$EXPECTED" ]; then
    r="beklenen sayimlar turetilemedi (lab ortami bozuk)"
else
    for svc in labapp-web labapp-worker labapp-cache labapp-queue; do
        grep -q "$svc" "$DAILY" || { r="$DAILY icinde $svc icin durum satiri yok"; break; }
    done
    if [ -z "$r" ] && grep -q 'labapp-legacy' "$DAILY"; then
        r="$DAILY icinde labapp-legacy geciyor — yorum satiri servis sayilmis"
    fi
    if [ -z "$r" ] && grep -q '^#' "$DAILY"; then
        r="$DAILY icinde ham yorum satiri var — suzulmeliydi"
    fi
    if [ -z "$r" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            grep -qxF "$line" "$DAILY" || { r="$DAILY icinde log seviye sayimi '$line' yok"; break; }
        done <<EOF
$EXPECTED
EOF
    fi
fi
[ -z "$r" ] && ok "daily.txt servis durumlarini ve log sayimlarini iceriyor, yorum/bos satir suzulmus" || bad "$r"

# --- 10. report — idempotens -------------------------------------------------
r=""
if [ ! -x "$BINDIR/report" ] || [ ! -f "$DAILY" ]; then
    r="report calistirilamadigi icin idempotens dogrulanamiyor"
else
    cp "$DAILY" "$T2"
    run_student "report"
    if ! cmp -s "$T2" "$DAILY"; then
        r="report ikinci kez calisinca daily.txt degisti ($(wc -c <"$T2") -> $(wc -c <"$DAILY") bayt) — rapor sifirdan uretilmeliydi"
    fi
fi
[ -z "$r" ] && ok "report iki kez calisinca daily.txt buyumuyor, icerik tekrarlanmiyor" || bad "$r"

# --- 11. report — HEALTHY yolu ----------------------------------------------
# services.list geçici olarak yalnız ayakta olan servislerle değiştirilir,
# sonra MUTLAKA geri yüklenir ve ortam DEGRADED hâline döndürülür.
r=""
if [ ! -x "$BINDIR/report" ]; then
    r="$BINDIR/report yok ya da calistirilabilir degil"
elif [ ! -f "$LIST" ]; then
    r="$LIST yok (lab ortami bozuk)"
else
    cp "$LIST" "$LISTBAK"
    printf 'labapp-web\nlabapp-worker\nlabapp-cache\n' > "$LIST"
    run_student "report"
    HRC="$RC"
    HFIRST="$(sed -n 1p "$DAILY" 2>/dev/null || true)"
    cp "$LISTBAK" "$LIST"
    chown root:root "$LIST"; chmod 0644 "$LIST"
    su - student -c report >/dev/null 2>&1 || true

    if [ "$HRC" -ne 0 ]; then
        r="hepsi ayaktayken report cikis kodu $HRC — 0 olmaliydi"
    elif [ "$HFIRST" != "HEALTHY" ]; then
        r="hepsi ayaktayken daily.txt ilk satiri 'HEALTHY' degil: '$HFIRST'"
    fi
fi
[ -z "$r" ] && ok "report HEALTHY yolunda 0 ile cikiyor ve daily.txt ilk satiri HEALTHY" || bad "$r"

# --- 12. İzinler -------------------------------------------------------------
r=""
for s in logsum svccheck report; do
    f="$BINDIR/$s"
    if [ ! -f "$f" ]; then
        r="$f yok"; break
    fi
    if [ ! -x "$f" ]; then
        r="$f calistirma izni tasimiyor"; break
    fi
    if [ -z "$(su - student -c "command -v $s" 2>/dev/null)" ]; then
        r="$s student icin tam yol yazmadan calistirilabilir degil"; break
    fi
    mode="$(stat -c %a "$f" 2>/dev/null)"
    other="${mode: -1}"
    if [ $(( other & 2 )) -ne 0 ]; then
        r="$f 'other' icin yazilabilir (mod $mode) — kapatilmali"; break
    fi
done
[ -z "$r" ] && ok "uc script de student tarafindan tam yolsuz calistirilabiliyor ve other-yazma biti kapali" || bad "$r"

exit "$FAIL"
