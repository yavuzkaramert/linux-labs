#!/usr/bin/env bash
# Container içinde root olarak çalışır. Her kriter için bir [OK]/[FAIL] satırı.
# Beklenen çıktılar log dosyalarından yeniden hesaplanır (hardcoded sayı yok).
set -u

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

A=/srv/logs/access.log
P=/srv/logs/app.log
R=/srv/reports
S=/etc/webapp/settings.conf
H=/etc/webapp/hosts.list
G=/opt/lab-golden/settings.conf

# --- 1. student loglari sudo'suz okuyabiliyor ---
if su - student -c "cat '$A' >/dev/null 2>&1 && cat '$P' >/dev/null 2>&1"; then
    ok "student loglari sudo'suz okuyabiliyor"
else
    bad "student $A veya $P dosyasini okuyamiyor"
fi

# --- 2. errors.log: sadece durum kodu 500, orijinal sirada ---
r=""
if [ ! -f "$R/errors.log" ]; then
    r="$R/errors.log yok"
elif ! diff -q <(awk '$(NF-1)==500' "$A") "$R/errors.log" >/dev/null 2>&1; then
    r="errors.log 500 durum kodlu satirlarla birebir eslesmiyor"
elif [ -n "$(awk '$(NF-1)!=500' "$R/errors.log")" ]; then
    r="errors.log icinde 500 disi durum kodlu satir var"
fi
[ -z "$r" ] && ok "errors.log sadece 500 satirlari, orijinal sirada" || bad "$r"

# --- 3. top-ips.txt: en cok istek yapan 5 IP, azalan sirada ---
r=""
exp="$(awk '{print $1}' "$A" | sort | uniq -c | sort -rn | head -5 | sed 's/^ *//; s/  */ /g')"
if [ ! -f "$R/top-ips.txt" ]; then
    r="$R/top-ips.txt yok"
elif [ "$(grep -c '' "$R/top-ips.txt")" -ne 5 ]; then
    r="top-ips.txt tam 5 satir olmali (bulunan: $(grep -c '' "$R/top-ips.txt"))"
else
    got="$(sed 's/^ *//; s/ *$//; s/  */ /g' "$R/top-ips.txt")"
    [ "$exp" = "$got" ] || r="top-ips.txt beklenen siralamayla eslesmiyor"
fi
[ -z "$r" ] && ok "top-ips.txt en cok istek yapan 5 IP, azalan sirada" || bad "$r"

# --- 4. unique-users.txt: tek satir, dogru farkli kullanici sayisi ---
r=""
exp="$(awk '$3!="-"{print $3}' "$A" | sort -u | wc -l)"
if [ ! -f "$R/unique-users.txt" ]; then
    r="$R/unique-users.txt yok"
elif [ "$(grep -c '' "$R/unique-users.txt")" -ne 1 ]; then
    r="unique-users.txt tek satir olmali"
elif [ "$(tr -d '[:space:]' < "$R/unique-users.txt")" != "$exp" ]; then
    r="unique-users.txt yanlis sayi (beklenen: $exp)"
fi
[ -z "$r" ] && ok "unique-users.txt dogru farkli kullanici sayisi ($exp)" || bad "$r"

# --- 5. warnings.tsv: sadece WARN, zaman<TAB>mesaj, orijinal sira ---
r=""
if [ ! -f "$R/warnings.tsv" ]; then
    r="$R/warnings.tsv yok"
elif ! diff -q <(awk -F'|' '$2=="WARN"{printf "%s\t%s\n", $1, $3}' "$P") "$R/warnings.tsv" >/dev/null 2>&1; then
    r="warnings.tsv WARN satirlariyla birebir eslesmiyor"
elif [ -n "$(awk -F'\t' 'NF!=2{print}' "$R/warnings.tsv")" ]; then
    r="warnings.tsv her satirinda tam bir TAB olmali (bosluk degil)"
elif grep -qE 'INFO|ERROR|DEBUG' "$R/warnings.tsv"; then
    r="warnings.tsv icinde WARN disi seviye satiri var"
fi
[ -z "$r" ] && ok "warnings.tsv sadece WARN, TAB ayrimli, orijinal sirada" || bad "$r"

# --- 6. settings.conf: debug kapali, aktif old-server yok, yorumlar korunmus ---
r=""
if [ ! -f "$R/settings.conf.orig" ]; then
    r="$R/settings.conf.orig yok"
elif ! cmp -s "$R/settings.conf.orig" "$G"; then
    r="settings.conf.orig duzeltme oncesi orijinali tutmuyor"
elif ! grep -v '^#' "$S" | grep -qiE 'debug[[:space:]]*='; then
    r="etkin bir debug satiri bulunamadi"
elif grep -v '^#' "$S" | grep -qiE 'debug[[:space:]]*=[[:space:]]*true'; then
    r="etkin debug ayari hala acik"
elif grep -v '^#' "$S" | grep -q 'old-server\.local'; then
    r="etkin satirlarda hala old-server.local var"
elif ! grep -v '^#' "$S" | grep -q 'web01\.local'; then
    r="old-server.local -> web01.local degisimi yapilmamis"
elif ! diff -q <(grep '^#' "$G") <(grep '^#' "$S") >/dev/null 2>&1; then
    r="yorum satirlari degistirilmis (birebir korunmali)"
fi
[ -z "$r" ] && ok "settings.conf: debug kapali, aktif old-server yok, yorumlar korunmus" || bad "$r"

# --- 7. hosts-clean.txt: bos satir ve # satiri yok, icerik korunmus ---
r=""
if [ ! -f "$R/hosts-clean.txt" ]; then
    r="$R/hosts-clean.txt yok"
elif grep -q '^#' "$R/hosts-clean.txt"; then
    r="hosts-clean.txt icinde # ile baslayan satir var"
elif grep -qE '^[[:space:]]*$' "$R/hosts-clean.txt"; then
    r="hosts-clean.txt icinde bos satir var"
elif ! diff -q <(grep -vE '^[[:space:]]*$' "$H" | grep -v '^#') "$R/hosts-clean.txt" >/dev/null 2>&1; then
    r="hosts-clean.txt beklenen icerik/sirayla eslesmiyor"
fi
[ -z "$r" ] && ok "hosts-clean.txt yorum/bos satir yok, icerik korunmus" || bad "$r"

exit "$FAIL"
