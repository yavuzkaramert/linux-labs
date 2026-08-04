#!/usr/bin/env bash
# ENV: container
# Container içinde root olarak çalışır. Her kriter için bir [OK]/[FAIL] satırı.
# set -e YOK: bir kriterin düşmesi diğerlerini durdurmaz (accumulator pattern).
#
# Bu bir TEKRAR labı: her satır hangi kaynak lab'dan geldiğini söyler.
# Biçim:  [OK]   Ticket 2.5 — açıklama (kaynak: lab 002)
#
# İlkeler (mevcut lab kuralları):
#  * Kullanıcı-perspektifi testleri `su - student -c` ile koşar.
#  * Beklenen değerler HESAPLANIR, sabit yazılmaz.
#  * Hiçbir süreç öldürülmez, hiçbir servis durdurulmaz; temizlik setup'ın işi.
set -u

FAIL=0
ok()   { echo "[OK]   $1"; }
bad()  { echo "[FAIL] $1"; FAIL=1; }
note() { echo "[NOTE] $1"; }

VARDIYA=/vardiya
GUNLUK="$VARDIYA/gunluk.md"
PROJE=/srv/proje
R=/srv/reports
GOLDEN=/opt/lab-golden
BINDIR=/usr/local/bin
LOGDIR=/var/log/vardiya
LISTDIR=/etc/vardiya

A="$PROJE/logs/access.log"
P="$PROJE/logs/app.log"
S="$PROJE/etc/settings.conf"
H="$PROJE/etc/hosts.list"
G="$GOLDEN/settings.conf"

APPLOG="$LOGDIR/gunluk.log"
SECURE="$LOGDIR/gizli.log"
LIST="$LISTDIR/servisler.list"
DAILY="$R/daily.txt"

SO="$(mktemp)"; SE="$(mktemp)"; T1F="$(mktemp)"; T2F="$(mktemp)"
LISTBAK="$(mktemp)"
cleanup() { rm -f "$SO" "$SE" "$T1F" "$T2F" "$LISTBAK"; }
trap cleanup EXIT

RC=0
# $1 = student olarak koşacak komut dizgesi. Çıkış kodu hemen RC'ye alınır.
run_student() {
    : > "$SO"; : > "$SE"
    su - student -c "$1" >"$SO" 2>"$SE"
    RC=$?
}

# "other" üçlüsünü mod dizgesinin son hanesinden okur (setgid'li 2770'te de doğru).
other_bits() { local m; m="$(stat -c %a "$1" 2>/dev/null)"; printf '%s' "${m: -1}"; }

# =============================================================================
# TICKET 1 — Vardiya günlüğü (kaynak: lab 001, permissions)
# =============================================================================

# --- 1.1 /vardiya: sahiplik root:root, other'da r-x ---
r=""
if [ ! -d "$VARDIYA" ]; then
    r="$VARDIYA dizini yok"
elif [ "$(stat -c '%U:%G' "$VARDIYA")" != "root:root" ]; then
    r="$VARDIYA sahibi root:root kalmaliydi (su an: $(stat -c '%U:%G' "$VARDIYA"))"
else
    o="$(other_bits "$VARDIYA")"
    if [ $(( o & 5 )) -ne 5 ]; then
        r="$VARDIYA 'other' icin en az r-x olmali (mod $(stat -c %a "$VARDIYA"))"
    elif ! su - student -c "cd $VARDIYA" >/dev/null 2>&1; then
        r="student $VARDIYA dizinine giremiyor"
    fi
fi
[ -z "$r" ] && ok "Ticket 1.1 — /vardiya root:root ve student icin gecilebilir (kaynak: lab 001)" \
             || bad "Ticket 1.1 — $r (kaynak: lab 001)"

# --- 1.2 gunluk.md: root:root, student okur, YAZAMAZ, içerik bozulmamış ---
r=""
if [ ! -f "$GUNLUK" ]; then
    r="$GUNLUK yok"
elif [ "$(stat -c '%U:%G' "$GUNLUK")" != "root:root" ]; then
    r="sahiplik root:root kalmaliydi, chown cozum degil (su an: $(stat -c '%U:%G' "$GUNLUK"))"
elif ! su - student -c "cat $GUNLUK" >/dev/null 2>&1; then
    r="student gunlugu sudo'suz okuyamiyor"
elif su - student -c "echo x >> $GUNLUK" >/dev/null 2>&1; then
    r="student gunlugu degistirebiliyor — yalnizca okuyabilmeliydi"
else
    o="$(other_bits "$GUNLUK")"
    if [ $(( o & 4 )) -eq 0 ]; then
        r="dosya modunda 'other' okuma biti yok (mod $(stat -c %a "$GUNLUK"))"
    elif [ $(( o & 2 )) -ne 0 ]; then
        r="dosya modunda 'other' yazma biti acik (mod $(stat -c %a "$GUNLUK"))"
    elif ! cmp -s "$GUNLUK" "$GOLDEN/gunluk.md"; then
        r="gunluk icerigi degismis — dosyaya dokunulmamaliydi"
    fi
fi
[ -z "$r" ] && ok "Ticket 1.2 — gunluk.md root:root, student okuyor ama yazamiyor, icerik saglam (kaynak: lab 001)" \
             || bad "Ticket 1.2 — $r (kaynak: lab 001)"

# =============================================================================
# TICKET 2 — İşe alımlar ve proje dizini (kaynak: lab 002, users & groups)
# =============================================================================

# --- 2.1 developers grubu, GID tam 4000 ---
r=""
if ! getent group developers >/dev/null 2>&1; then
    r="developers grubu yok"
else
    gid="$(getent group developers | cut -d: -f3)"
    [ "$gid" = "4000" ] || r="developers GID $gid — tam 4000 olmaliydi"
fi
[ -z "$r" ] && ok "Ticket 2.1 — developers grubu var, GID 4000 (kaynak: lab 002)" \
             || bad "Ticket 2.1 — $r (kaynak: lab 002)"

# --- 2.2 ayse ve mehmet: home, sahiplik, shell ---
r=""
for u in ayse mehmet; do
    if ! id "$u" >/dev/null 2>&1; then
        r="$u kullanicisi yok"; break
    fi
    home="$(getent passwd "$u" | cut -d: -f6)"
    shell="$(getent passwd "$u" | cut -d: -f7)"
    if [ "$home" != "/home/$u" ]; then
        r="$u ev dizini /home/$u olmaliydi (su an: $home)"; break
    fi
    if [ ! -d "$home" ]; then
        r="$home dizini yok"; break
    fi
    if [ "$(stat -c %U "$home")" != "$u" ]; then
        r="$home sahibi $u olmaliydi (su an: $(stat -c %U "$home"))"; break
    fi
    if [ "$shell" != "/bin/bash" ]; then
        r="$u kabugu /bin/bash olmaliydi (su an: $shell)"; break
    fi
done
[ -z "$r" ] && ok "Ticket 2.2 — ayse ve mehmet var, ev dizini kendilerinin, kabuk /bin/bash (kaynak: lab 002)" \
             || bad "Ticket 2.2 — $r (kaynak: lab 002)"

# --- 2.3 primary grup kendi adı, developers ikincil ---
r=""
for u in ayse mehmet; do
    if ! id "$u" >/dev/null 2>&1; then
        r="$u kullanicisi yok"; break
    fi
    pg="$(id -gn "$u")"
    if [ "$pg" != "$u" ]; then
        r="$u birincil grubu '$pg' — kendi adiyla ayni olmaliydi"; break
    fi
    if ! id -nG "$u" | tr ' ' '\n' | grep -qx developers; then
        r="$u developers grubunda degil"; break
    fi
done
[ -z "$r" ] && ok "Ticket 2.3 — ayse/mehmet birincil grubu kendi adi, developers ikincil (kaynak: lab 002)" \
             || bad "Ticket 2.3 — $r (kaynak: lab 002)"

# --- 2.4 deploybot: nologin, developers üyesi, ev dizini yok ---
r=""
if ! id deploybot >/dev/null 2>&1; then
    r="deploybot hesabi yok"
else
    sh="$(getent passwd deploybot | cut -d: -f7)"
    case "$sh" in
        *nologin|*/false) ;;
        *) r="deploybot kabugu '$sh' — nologin/false olmaliydi" ;;
    esac
    if [ -z "$r" ] && ! id -nG deploybot | tr ' ' '\n' | grep -qx developers; then
        r="deploybot developers grubunda degil"
    fi
    if [ -z "$r" ] && [ -d /home/deploybot ]; then
        r="/home/deploybot olusturulmamaliydi (servis hesabi)"
    fi
fi
[ -z "$r" ] && ok "Ticket 2.4 — deploybot nologin, developers uyesi, ev dizini yok (kaynak: lab 002)" \
             || bad "Ticket 2.4 — $r (kaynak: lab 002)"

# --- 2.5 /srv/proje: root:developers, mod tam 2770 ---
r=""
if [ ! -d "$PROJE" ]; then
    r="$PROJE dizini yok"
else
    own="$(stat -c '%U:%G' "$PROJE")"
    mode="$(stat -c %a "$PROJE")"
    if [ "$own" != "root:developers" ]; then
        r="$PROJE sahibi root:developers olmaliydi (su an: $own)"
    elif [ "$mode" != "2770" ]; then
        r="$PROJE modu tam 2770 olmaliydi (su an: $mode)"
    fi
fi
[ -z "$r" ] && ok "Ticket 2.5 — /srv/proje sahiplik root:developers, mod 2770 (kaynak: lab 002)" \
             || bad "Ticket 2.5 — $r (kaynak: lab 002)"

# --- 2.6 ayse dosya olusturuyor, grup developers'a dusuyor, mehmet yazabiliyor ---
r=""
TESTF="$PROJE/.check-setgid-$$"
rm -f "$TESTF"
if ! id ayse >/dev/null 2>&1 || ! id mehmet >/dev/null 2>&1; then
    r="ayse veya mehmet yok, ortak dizin testi yapilamiyor"
elif ! su - ayse -c "touch '$TESTF' && chmod 660 '$TESTF'" >/dev/null 2>&1; then
    r="ayse $PROJE icinde dosya olusturamiyor"
elif [ "$(stat -c %G "$TESTF" 2>/dev/null)" != "developers" ]; then
    r="ayse'nin olusturdugu dosya '$(stat -c %G "$TESTF" 2>/dev/null)' grubunda — setgid ile developers olmaliydi"
elif ! su - mehmet -c "echo satir >> '$TESTF'" >/dev/null 2>&1; then
    r="mehmet ayse'nin olusturdugu dosyaya yazamiyor"
fi
rm -f "$TESTF"
[ -z "$r" ] && ok "Ticket 2.6 — ayse dosya aciyor, grup setgid ile developers, mehmet yazabiliyor (kaynak: lab 002)" \
             || bad "Ticket 2.6 — $r (kaynak: lab 002)"

# --- 2.7 tolga hesabı ve ev dizini yok ---
r=""
if id tolga >/dev/null 2>&1; then
    r="tolga hesabi hala duruyor"
elif [ -d /home/tolga ]; then
    r="/home/tolga hala duruyor"
fi
[ -z "$r" ] && ok "Ticket 2.7 — tolga hesabi ve /home/tolga silinmis (kaynak: lab 002)" \
             || bad "Ticket 2.7 — $r (kaynak: lab 002)"

# --- 2.8 ayse var ve wheel grubunda DEĞİL ---
r=""
if ! id ayse >/dev/null 2>&1; then
    r="ayse kullanicisi yok"
elif id -nG ayse | tr ' ' '\n' | grep -qx wheel; then
    r="ayse wheel grubunda — yonetici yetkisi verilmemeliydi"
fi
[ -z "$r" ] && ok "Ticket 2.8 — ayse var ve wheel grubunda degil (kaynak: lab 002)" \
             || bad "Ticket 2.8 — $r (kaynak: lab 002)"

# --- 2.9 student de developers üyesi (proje dizinine erişebiliyor) ---
# 2770 root:developers, 'other' hicbir sey goremez. Sistem sorumlusu da bu
# grupta olmazsa Ticket 3 ve 4'un kullanici-perspektifi kriterleri gecemez.
r=""
if ! id -nG student | tr ' ' '\n' | grep -qx developers; then
    r="student developers grubunda degil — /srv/proje'ye kendi yetkisiyle giremez"
elif ! su - student -c "cd $PROJE" >/dev/null 2>&1; then
    r="student $PROJE dizinine giremiyor"
fi
[ -z "$r" ] && ok "Ticket 2.9 — student developers uyesi, /srv/proje'ye sudo'suz girebiliyor (kaynak: lab 002)" \
             || bad "Ticket 2.9 — $r (kaynak: lab 002)"

# =============================================================================
# TICKET 3 — Proje dizinini temizle (kaynak: lab 003, finding files)
# =============================================================================

# --- 3.1 Eski loglar arşivde, yeniler yerinde ---
r=""
if [ ! -d "$PROJE/archive" ]; then
    r="$PROJE/archive dizini yok"
else
    stray="$(find "$PROJE" -path "$PROJE/archive" -prune -o -type f -name '*.log' -mtime +30 -print 2>/dev/null | head -1)"
    if [ -n "$stray" ]; then
        r="30 gunden eski log hala arsiv disinda: $stray"
    fi
    if [ -z "$r" ]; then
        for f in nisan.log erisim-eski.log yedek-eski.log; do
            if [ -z "$(find "$PROJE/archive" -type f -name "$f" 2>/dev/null | head -1)" ]; then
                r="$f arsive tasinmaliydi (silinmis olmasin!)"; break
            fi
        done
    fi
    if [ -z "$r" ] && [ ! -f "$PROJE/guncel.log" ]; then
        r="yeni log guncel.log yerinde durmaliydi"
    fi
    if [ -z "$r" ] && [ ! -f "$PROJE/erisim.log" ]; then
        r="yeni log erisim.log yerinde durmaliydi"
    fi
    if [ -z "$r" ] && [ -n "$(find "$PROJE/archive" \( -name 'guncel.log' -o -name 'erisim.log' \) 2>/dev/null | head -1)" ]; then
        r="30 gunden yeni loglar arsive girmemeliydi"
    fi
fi
[ -z "$r" ] && ok "Ticket 3.1 — eski .log dosyalari archive/ altinda, yeniler yerinde (kaynak: lab 003)" \
             || bad "Ticket 3.1 — $r (kaynak: lab 003)"

# --- 3.2 Sıfır byte dosya kalmadı; dolu dosyalar ve boş dizinler yerinde ---
r=""
empty="$(find "$PROJE" -type f -empty 2>/dev/null | head -1)"
if [ -n "$empty" ]; then
    r="hala 0 byte dosya var: $empty"
elif [ ! -s "$PROJE/tmp/onbellek.dat" ]; then
    r="dolu dosya onbellek.dat silinmemeliydi"
elif [ ! -s "$PROJE/config/sema.sql" ]; then
    r="dolu dosya sema.sql silinmemeliydi"
elif [ ! -d "$PROJE/spool" ]; then
    r="bos dizin $PROJE/spool silinmemeliydi"
fi
[ -z "$r" ] && ok "Ticket 3.2 — 0 byte dosyalar temiz; dolu dosyalar ve bos dizin yerinde (kaynak: lab 003)" \
             || bad "Ticket 3.2 — $r (kaynak: lab 003)"

# --- 3.3 tmp'deki >1MB dosyalar big/ altında, küçükler tmp'de ---
r=""
if [ ! -d "$PROJE/big" ]; then
    r="$PROJE/big dizini yok"
else
    left="$(find "$PROJE/tmp" -maxdepth 1 -type f -size +1M 2>/dev/null | head -1)"
    if [ -n "$left" ]; then
        r="1 MB'den buyuk dosya hala tmp icinde: $left"
    fi
    for f in buyuk-dokum.bin video-parca.mp4; do
        if [ -z "$r" ] && [ -z "$(find "$PROJE/big" -maxdepth 1 -type f -name "$f" -size +1M 2>/dev/null | head -1)" ]; then
            r="$f big/ altina tasinmaliydi"
        fi
    done
    for f in oturum-01.dat oturum-02.dat; do
        if [ -z "$r" ] && [ ! -f "$PROJE/tmp/$f" ]; then
            r="kucuk dosya $f tmp icinde kalmaliydi"
        fi
    done
fi
[ -z "$r" ] && ok "Ticket 3.3 — buyuk dosyalar big/ altinda, kucukler tmp'de (kaynak: lab 003)" \
             || bad "Ticket 3.3 — $r (kaynak: lab 003)"

# --- 3.4 backup/config: mod, sahip:grup, mtime ve içerik birebir aynı ---
r=""
if [ ! -d "$PROJE/backup/config" ]; then
    r="$PROJE/backup/config dizini yok"
else
    while IFS= read -r f; do
        rel="${f#"$PROJE"/config/}"
        b="$PROJE/backup/config/$rel"
        if [ ! -f "$b" ]; then
            r="kopyada eksik dosya: $rel"; break
        fi
        if [ "$(stat -c '%a %U:%G %Y' "$f")" != "$(stat -c '%a %U:%G %Y' "$b")" ]; then
            r="$rel metadata farkli (izin/sahip/mtime korunmali — orijinal: $(stat -c '%a %U:%G' "$f"), kopya: $(stat -c '%a %U:%G' "$b"))"
            break
        fi
        if ! cmp -s "$f" "$b"; then
            r="$rel icerigi orijinalden farkli"; break
        fi
    done < <(find "$PROJE/config" -type f)
fi
[ -z "$r" ] && ok "Ticket 3.4 — backup/config metadata ve icerik olarak birebir kopya (kaynak: lab 003)" \
             || bad "Ticket 3.4 — $r (kaynak: lab 003)"

# --- 3.5 reports/latest: en yeni .csv'ye giden sembolik link ---
r=""
latest="$PROJE/reports/latest"
newest="$(find "$PROJE/reports" -maxdepth 1 -type f -name '*.csv' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
if [ ! -L "$latest" ]; then
    r="$latest bir sembolik link olmali (kopya degil)"
elif [ -z "$newest" ]; then
    r="reports/ icinde hic .csv kalmamis"
elif [ "$(readlink -f "$latest")" != "$(readlink -f "$newest")" ]; then
    r="latest en yeni csv'yi gostermeli ($(basename "$newest")), su an: $(readlink "$latest")"
fi
[ -z "$r" ] && ok "Ticket 3.5 — reports/latest en yeni csv'ye isaret eden sembolik link (kaynak: lab 003)" \
             || bad "Ticket 3.5 — $r (kaynak: lab 003)"

# --- 3.6 Tüm .sh'ler student ile çalışıyor; .sh olmayanlarda x yok ---
r=""
found=0
while IFS= read -r s; do
    found=1
    if ! su - student -c "$s" >/dev/null 2>&1; then
        r="student su script'i calistiramiyor: $s"; break
    fi
done < <(find "$PROJE/scripts" -type f -name '*.sh' 2>/dev/null)
if [ -z "$r" ] && [ "$found" -eq 0 ]; then
    r="scripts/ altinda hic .sh bulunamadi"
fi
if [ -z "$r" ]; then
    badx="$(find "$PROJE/scripts" -type f ! -name '*.sh' -perm /111 2>/dev/null | head -1)"
    if [ -n "$badx" ]; then
        r=".sh olmayan dosyada calistirma izni olmamali: $badx"
    fi
fi
[ -z "$r" ] && ok "Ticket 3.6 — tum .sh'ler student ile calisiyor; diger dosyalarda x izni yok (kaynak: lab 003)" \
             || bad "Ticket 3.6 — $r (kaynak: lab 003)"

# =============================================================================
# TICKET 4 — Log analizi (kaynak: lab 004, text processing)
# =============================================================================

# --- 4.1 student logları sudo'suz okuyabiliyor ---
if su - student -c "cat '$A' >/dev/null 2>&1 && cat '$P' >/dev/null 2>&1"; then
    ok "Ticket 4.1 — student loglari sudo'suz okuyabiliyor (kaynak: lab 004)"
else
    bad "Ticket 4.1 — student $A veya $P dosyasini okuyamiyor (kaynak: lab 004)"
fi

# --- 4.2 errors.log: sadece durum kodu 500, orijinal sırada ---
r=""
if [ ! -f "$R/errors.log" ]; then
    r="$R/errors.log yok"
elif [ ! -f "$A" ]; then
    r="$A yok (lab ortami bozuk)"
elif ! diff -q <(awk '$(NF-1)==500' "$A") "$R/errors.log" >/dev/null 2>&1; then
    r="errors.log 500 durum kodlu satirlarla birebir eslesmiyor"
elif [ -n "$(awk '$(NF-1)!=500' "$R/errors.log")" ]; then
    r="errors.log icinde 500 disi durum kodlu satir var"
fi
[ -z "$r" ] && ok "Ticket 4.2 — errors.log sadece 500 satirlari, orijinal sirada (kaynak: lab 004)" \
             || bad "Ticket 4.2 — $r (kaynak: lab 004)"

# --- 4.3 top-ips.txt: en çok istek yapan 5 IP, azalan sırada ---
r=""
exp="$(awk '{print $1}' "$A" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | sed 's/^ *//; s/  */ /g')"
if [ ! -f "$R/top-ips.txt" ]; then
    r="$R/top-ips.txt yok"
elif [ "$(grep -c '' "$R/top-ips.txt")" -ne 5 ]; then
    r="top-ips.txt tam 5 satir olmali (bulunan: $(grep -c '' "$R/top-ips.txt"))"
else
    got="$(sed 's/^ *//; s/ *$//; s/  */ /g' "$R/top-ips.txt")"
    [ "$exp" = "$got" ] || r="top-ips.txt beklenen siralamayla eslesmiyor"
fi
[ -z "$r" ] && ok "Ticket 4.3 — top-ips.txt en cok istek yapan 5 IP, azalan sirada (kaynak: lab 004)" \
             || bad "Ticket 4.3 — $r (kaynak: lab 004)"

# --- 4.4 unique-users.txt: tek satır, doğru tekil kullanıcı sayısı ---
r=""
exp="$(awk '$3!="-"{print $3}' "$A" 2>/dev/null | sort -u | wc -l)"
if [ ! -f "$R/unique-users.txt" ]; then
    r="$R/unique-users.txt yok"
elif [ "$(grep -c '' "$R/unique-users.txt")" -ne 1 ]; then
    r="unique-users.txt tek satir olmali"
elif [ "$(tr -d '[:space:]' < "$R/unique-users.txt")" != "$exp" ]; then
    r="unique-users.txt yanlis sayi (beklenen: $exp)"
fi
[ -z "$r" ] && ok "Ticket 4.4 — unique-users.txt dogru tekil kullanici sayisi ($exp) (kaynak: lab 004)" \
             || bad "Ticket 4.4 — $r (kaynak: lab 004)"

# --- 4.5 warnings.tsv: sadece WARN, zaman<TAB>mesaj, orijinal sıra ---
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
[ -z "$r" ] && ok "Ticket 4.5 — warnings.tsv sadece WARN, TAB ayrimli, orijinal sirada (kaynak: lab 004)" \
             || bad "Ticket 4.5 — $r (kaynak: lab 004)"

# --- 4.6 settings.conf: debug kapalı, aktif old-server yok, yorumlar korunmuş ---
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
[ -z "$r" ] && ok "Ticket 4.6 — settings.conf: debug kapali, aktif old-server yok, yorumlar korunmus (kaynak: lab 004)" \
             || bad "Ticket 4.6 — $r (kaynak: lab 004)"

# --- 4.7 hosts-clean.txt: boş satır ve # satırı yok, içerik korunmuş ---
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
[ -z "$r" ] && ok "Ticket 4.7 — hosts-clean.txt yorum/bos satir yok, icerik korunmus (kaynak: lab 004)" \
             || bad "Ticket 4.7 — $r (kaynak: lab 004)"

# =============================================================================
# TICKET 5 — Başıboş süreçler (kaynak: lab 005, processes)
# =============================================================================
# Süreç durumları CANLI okunur. Süreçler PID ile degil komut satiri isaretiyle
# bulunur; zombie sureclerin cmdline'i bos oldugu icin pgrep -f onlari eslemez.
PROCS="$R/procs.txt"
NICEF="$R/batch-nice.txt"

HOG_PIDS="$(pgrep -f 'LABPROC-hog'   2>/dev/null || true)"
ROGUE_PIDS="$(pgrep -f 'LABPROC-rogue' 2>/dev/null || true)"
BATCH_PIDS="$(pgrep -f 'LABPROC-batch' 2>/dev/null || true)"
BPID="$(printf '%s\n' "$BATCH_PIDS" | head -n 1)"

BNICE=""
if [ -n "$BPID" ]; then
    BNICE="$(ps -o ni= -p "$BPID" 2>/dev/null | tr -d '[:space:]')"
fi

# --- 5.1 procs.txt: PID + tam komut satırı, grep kendisi listede yok ---
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
    r="LABPROC-batch calismadigi icin liste dogrulanamiyor (bkz. Ticket 5.4)"
elif ! grep -E "(^|[^0-9])${BPID}([^0-9]|$)" "$PROCS" 2>/dev/null | grep -q 'LABPROC-batch'; then
    r="procs.txt icinde LABPROC-batch sureci PID $BPID ile listelenmemis"
elif ! su - student -c "cat $PROCS" >/dev/null 2>&1; then
    r="procs.txt student tarafindan sudo'suz okunamiyor"
fi
[ -z "$r" ] && ok "Ticket 5.1 — procs.txt LABPROC sureclerini PID + komut satiriyla listeliyor, grep satiri yok (kaynak: lab 005)" \
             || bad "Ticket 5.1 — $r (kaynak: lab 005)"

# --- 5.2 LABPROC-hog artık çalışmıyor ---
if [ -n "$HOG_PIDS" ]; then
    bad "Ticket 5.2 — LABPROC-hog hala calisiyor (PID: $(printf '%s' "$HOG_PIDS" | tr '\n' ' ')) (kaynak: lab 005)"
else
    ok "Ticket 5.2 — LABPROC-hog surec tablosunda yok (kaynak: lab 005)"
fi

# --- 5.3 LABPROC-rogue artık çalışmıyor (TERM'i yok sayıyordu) ---
if [ -n "$ROGUE_PIDS" ]; then
    bad "Ticket 5.3 — LABPROC-rogue hala calisiyor (PID: $(printf '%s' "$ROGUE_PIDS" | tr '\n' ' ')) — kibar sinyali yok sayiyor (kaynak: lab 005)"
else
    ok "Ticket 5.3 — LABPROC-rogue surec tablosunda yok (kaynak: lab 005)"
fi

# --- 5.4 LABPROC-batch hâlâ ayakta VE nice >= 10 ---
r=""
if [ -z "$BPID" ]; then
    r="LABPROC-batch calismiyor — bu surec oldurulmemeliydi, onceligi dusurulmeliydi"
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
[ -z "$r" ] && ok "Ticket 5.4 — LABPROC-batch calisiyor ve nice degeri $BNICE (>= 10) (kaynak: lab 005)" \
             || bad "Ticket 5.4 — $r (kaynak: lab 005)"

# --- 5.5 batch-nice.txt tek sayı ve gerçek nice ile aynı ---
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
[ -z "$r" ] && ok "Ticket 5.5 — batch-nice.txt tek sayi ve surecin gercek nice degeriyle ayni (kaynak: lab 005)" \
             || bad "Ticket 5.5 — $r (kaynak: lab 005)"

if pgrep -f 'nightly-batch-runner' >/dev/null 2>&1; then
    note "gurultu sureci (nightly-batch-runner) yasiyor — dogru hedefleme"
else
    note "gurultu sureci (nightly-batch-runner) oldurulmus — LABPROC isareti tasimiyordu, yanlis hedefti"
fi

# =============================================================================
# TICKET 6 — Gün ortası özet raporu (kaynak: lab 006, shell scripting)
# =============================================================================
EXPECTED="$(awk -F'|' 'NF >= 2 { c[$2]++ } END { for (l in c) printf "%s:%d\n", l, c[l] }' \
            "$APPLOG" 2>/dev/null | sort)"

# Gerçek servis PID'leri comm üzerinden okunur. `-f` KULLANILMAZ: o, işareti
# argüman olarak taşıyan su / bash -c / svccheck süreçlerini de eşleştirir.
WEB_PIDS="$(pgrep -x vardiya-web    2>/dev/null || true)"
WRK_PIDS="$(pgrep -x vardiya-worker 2>/dev/null || true)"
CCH_PIDS="$(pgrep -x vardiya-cache  2>/dev/null || true)"

pid_in() {
    local needle="$1" p
    for p in $2; do [ "$p" = "$needle" ] && return 0; done
    return 1
}

# --- 6.1 logsum başarı yolu ---
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
[ -z "$r" ] && ok "Ticket 6.1 — logsum seviye sayimlarini dogru bicim ve degerlerle basiyor (cikis 0) (kaynak: lab 006)" \
             || bad "Ticket 6.1 — $r (kaynak: lab 006)"

# --- 6.2 logsum argümansız ---
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
[ -z "$r" ] && ok "Ticket 6.2 — argumansiz logsum: stdout bos, stderr dolu, cikis kodu 2 (kaynak: lab 006)" \
             || bad "Ticket 6.2 — $r (kaynak: lab 006)"

# --- 6.3 logsum olmayan dosya ---
r=""
if [ ! -x "$BINDIR/logsum" ]; then
    r="$BINDIR/logsum student tarafindan calistirilabilir degil"
else
    run_student "logsum $LOGDIR/yok.log"
    if [ "$RC" -ne 3 ]; then
        r="olmayan dosya icin cikis kodu $RC — 3 olmaliydi"
    elif [ -s "$SO" ]; then
        r="olmayan dosya icin standart ciktiya yazildi — yazilmamaliydi"
    elif [ ! -s "$SE" ]; then
        r="olmayan dosya icin standart hataya mesaj yazilmadi"
    fi
fi
[ -z "$r" ] && ok "Ticket 6.3 — olmayan dosya: stdout bos, stderr dolu, cikis kodu 3 (kaynak: lab 006)" \
             || bad "Ticket 6.3 — $r (kaynak: lab 006)"

# --- 6.4 logsum okunamayan dosya (var ama student okuyamıyor) ---
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
[ -z "$r" ] && ok "Ticket 6.4 — okunamayan dosya: cikis kodu 3, stdout bos (-f degil -r kontrolu) (kaynak: lab 006)" \
             || bad "Ticket 6.4 — $r (kaynak: lab 006)"

# --- 6.5 svccheck çıktı biçimi ve PID doğruluğu ---
: > "$T1F"
r=""
if [ ! -x "$BINDIR/svccheck" ]; then
    r="$BINDIR/svccheck yok ya da calistirilabilir degil"
elif [ -z "$WEB_PIDS" ] || [ -z "$WRK_PIDS" ]; then
    r="servis surecleri ayakta degil (lab ortami bozuk — labctl reset 900-vardiya-01a)"
else
    run_student "svccheck vardiya-web vardiya-queue vardiya-worker"
    cp "$SO" "$T1F"
    L1="$(sed -n 1p "$SO")"; L2="$(sed -n 2p "$SO")"; L3="$(sed -n 3p "$SO")"
    N="$(grep -c '' "$SO")"
    if [ "$N" -ne 3 ]; then
        r="svccheck 3 arguman icin $N satir basti — 3 olmaliydi"
    elif ! printf '%s' "$L1" | grep -qE '^\[OK\] vardiya-web [0-9]+$'; then
        r="1. satir '[OK] vardiya-web <pid>' bicimde degil: '$L1'"
    elif ! printf '%s' "$L2" | grep -qE '^\[FAIL\] vardiya-queue$'; then
        r="2. satir '[FAIL] vardiya-queue' olmaliydi: '$L2'"
    elif ! printf '%s' "$L3" | grep -qE '^\[OK\] vardiya-worker [0-9]+$'; then
        r="3. satir '[OK] vardiya-worker <pid>' bicimde degil: '$L3'"
    elif ! pid_in "${L1##* }" "$WEB_PIDS"; then
        r="vardiya-web icin yazilan PID ${L1##* } gercek degil (gercek: $(echo "$WEB_PIDS" | tr '\n' ' '))"
    elif ! pid_in "${L3##* }" "$WRK_PIDS"; then
        r="vardiya-worker icin yazilan PID ${L3##* } gercek degil (gercek: $(echo "$WRK_PIDS" | tr '\n' ' '))"
    fi
fi
[ -z "$r" ] && ok "Ticket 6.5 — svccheck sirayi koruyor, bicim dogru ve yazilan PID'ler gercek (kaynak: lab 006)" \
             || bad "Ticket 6.5 — $r (kaynak: lab 006)"

# --- 6.6 svccheck çıkış kodları ---
r=""
if [ ! -x "$BINDIR/svccheck" ]; then
    r="$BINDIR/svccheck yok ya da calistirilabilir degil"
else
    run_student "svccheck vardiya-web vardiya-cache"
    if [ "$RC" -ne 0 ]; then
        r="hepsi ayaktayken cikis kodu $RC — 0 olmaliydi"
    else
        run_student "svccheck vardiya-web vardiya-queue"
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
[ -z "$r" ] && ok "Ticket 6.6 — svccheck cikis kodlari: hepsi ayakta 0, eksik var 1, argumansiz 2 (kaynak: lab 006)" \
             || bad "Ticket 6.6 — $r (kaynak: lab 006)"

# --- 6.7 svccheck kendi arama sürecini listelemiyor ---
r=""
if [ ! -s "$T1F" ]; then
    r="svccheck ciktisi alinamadi (bkz. Ticket 6.5)"
elif grep -qE '(svccheck|pgrep|grep)' "$T1F"; then
    r="svccheck ciktisinda kendi arama sureci gorunuyor: $(grep -m1 -E '(svccheck|pgrep|grep)' "$T1F")"
elif [ "$(grep -c '' "$T1F")" -ne 3 ]; then
    r="svccheck satir sayisi arguman sayisina esit degil"
else
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
    done < "$T1F"
fi
[ -z "$r" ] && ok "Ticket 6.7 — svccheck kendi arama sureci ciktiya karismiyor (kaynak: lab 006)" \
             || bad "Ticket 6.7 — $r (kaynak: lab 006)"

# --- 6.8 report — DEGRADED yolu ---
r=""
if [ ! -x "$BINDIR/report" ]; then
    r="$BINDIR/report yok ya da calistirilabilir degil"
else
    rm -f "$DAILY"
    run_student "report"
    if [ "$RC" -ne 1 ]; then
        r="report cikis kodu $RC — vardiya-queue ayakta olmadigi icin 1 olmaliydi"
    elif [ ! -f "$DAILY" ]; then
        r="$DAILY olusmadi"
    elif [ "$(sed -n 1p "$DAILY")" != "DEGRADED" ]; then
        r="$DAILY ilk satiri 'DEGRADED' degil: '$(sed -n 1p "$DAILY")'"
    fi
fi
[ -z "$r" ] && ok "Ticket 6.8 — report DEGRADED yolunda 1 ile cikiyor, daily.txt ilk satiri DEGRADED (kaynak: lab 006)" \
             || bad "Ticket 6.8 — $r (kaynak: lab 006)"

# --- 6.9 report — içerik ---
r=""
if [ ! -f "$DAILY" ]; then
    r="$DAILY yok (bkz. Ticket 6.8)"
elif [ -z "$EXPECTED" ]; then
    r="beklenen sayimlar turetilemedi (lab ortami bozuk)"
else
    for svc in vardiya-web vardiya-worker vardiya-cache vardiya-queue; do
        grep -q "$svc" "$DAILY" || { r="$DAILY icinde $svc icin durum satiri yok"; break; }
    done
    if [ -z "$r" ] && grep -q 'vardiya-legacy' "$DAILY"; then
        r="$DAILY icinde vardiya-legacy geciyor — yorum satiri servis sayilmis"
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
[ -z "$r" ] && ok "Ticket 6.9 — daily.txt servis durumlarini ve log sayimlarini iceriyor, yorum/bos satir suzulmus (kaynak: lab 006)" \
             || bad "Ticket 6.9 — $r (kaynak: lab 006)"

# --- 6.10 report — idempotens ---
r=""
if [ ! -x "$BINDIR/report" ] || [ ! -f "$DAILY" ]; then
    r="report calistirilamadigi icin idempotens dogrulanamiyor"
else
    cp "$DAILY" "$T2F"
    run_student "report"
    if ! cmp -s "$T2F" "$DAILY"; then
        r="report ikinci kez calisinca daily.txt degisti ($(wc -c <"$T2F") -> $(wc -c <"$DAILY") bayt) — rapor sifirdan uretilmeliydi"
    fi
fi
[ -z "$r" ] && ok "Ticket 6.10 — report iki kez calisinca daily.txt buyumuyor, icerik tekrarlanmiyor (kaynak: lab 006)" \
             || bad "Ticket 6.10 — $r (kaynak: lab 006)"

# --- 6.11 report — HEALTHY yolu ---
# servisler.list geçici olarak yalnız ayakta olanlarla değiştirilir, sonra
# MUTLAKA geri yüklenir ve ortam DEGRADED hâline döndürülür.
r=""
if [ ! -x "$BINDIR/report" ]; then
    r="$BINDIR/report yok ya da calistirilabilir degil"
elif [ ! -f "$LIST" ]; then
    r="$LIST yok (lab ortami bozuk)"
else
    cp "$LIST" "$LISTBAK"
    printf 'vardiya-web\nvardiya-worker\nvardiya-cache\n' > "$LIST"
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
[ -z "$r" ] && ok "Ticket 6.11 — report HEALTHY yolunda 0 ile cikiyor, daily.txt ilk satiri HEALTHY (kaynak: lab 006)" \
             || bad "Ticket 6.11 — $r (kaynak: lab 006)"

# --- 6.12 İzinler ---
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
[ -z "$r" ] && ok "Ticket 6.12 — uc script de student ile tam yolsuz calisiyor, other-yazma biti kapali (kaynak: lab 006)" \
             || bad "Ticket 6.12 — $r (kaynak: lab 006)"

exit "$FAIL"
