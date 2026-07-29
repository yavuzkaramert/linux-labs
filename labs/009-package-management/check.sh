#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1. Eksik dosya check'i çökertmez;
# ilgili kriter FAIL verir, koşu devam eder.
#
# Beklenen değerler SABİT YAZILMAZ: paket adı, sürüm ve dosya listeleri
# check anında dosyanın kendisinden okunur. Repo güncellenip .rpm'in sürümü
# değişse bile lab kırılmaz.
#
# Hiçbir paket kurulmaz/kaldırılmaz: check sistemin durumunu değiştirmez.
set -u

HOME_DIR=/home/student
PKGDIR=/srv/paketler
ORIG=/srv/.orig-009
ANS="$HOME_DIR/cevaplar"

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

nlines() { [ -f "$1" ] && awk 'END {print NR + 0}' "$1" || echo 0; }

# Cevap dosyaları için normalleştirme: baş/son boşluk kırpılır, iç boşluklar
# teke indirilir, boş satırlar atılır. Amaç biçimsel titizlik değil, cevabın
# kendisi.
norm() {
    sed -e 's/[[:space:]]\+/ /g' -e 's/^ //' -e 's/ $//' -e '/^$/d' "$1"
}

# Öğrenci perspektifi: PATH ve komut erişilebilirliği student olarak sınanır.
run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

RPM_FILE="$(ls "$PKGDIR"/*.rpm 2>/dev/null | head -1)"
DEB_FILE="$(ls "$PKGDIR"/*.deb 2>/dev/null | head -1)"

# --- 1. paket-sorgu.txt ilk satirinda dogru paket adi ---------------------
# tree'nin geldiği paket rpm'e sorulur, sabit yazılmaz.
r=""
TREE_PKG="$(rpm -qf --qf '%{NAME}' /usr/bin/tree 2>/dev/null)"
if [ -z "$TREE_PKG" ]; then
    r="/usr/bin/tree hiçbir pakete ait değil (ortam bozuk)"
elif [ ! -f "$ANS/paket-sorgu.txt" ]; then
    r="$ANS/paket-sorgu.txt yok"
else
    got_pkg="$(norm "$ANS/paket-sorgu.txt" | head -1)"
    # Sürüm ekli tam ad da (tree-2.1.0-8.el10.aarch64) kabul edilir.
    case "$got_pkg" in
        "$TREE_PKG"|"$TREE_PKG"-[0-9]*) ;;
        *) r="paket-sorgu.txt ilk satırı '$got_pkg', beklenen '$TREE_PKG'" ;;
    esac
fi
[ -z "$r" ] && ok "paket-sorgu.txt ilk satırında doğru paket adı var" || bad "$r"

# --- 2. paket-sorgu.txt dosya listesi eslesiyor ---------------------------
# Sıra serbest: iki liste de sıralanıp karşılaştırılır.
r=""
if [ ! -f "$ANS/paket-sorgu.txt" ]; then
    r="$ANS/paket-sorgu.txt yok"
elif [ -z "$TREE_PKG" ]; then
    r="paket adı çözülemediği için liste sınanamıyor"
else
    rpm -ql "$TREE_PKG" 2>/dev/null | sort > "$TMP/exp-ql"
    norm "$ANS/paket-sorgu.txt" | tail -n +2 | sort > "$TMP/got-ql"
    if [ ! -s "$TMP/got-ql" ]; then
        r="paket-sorgu.txt ilk satırdan sonra dosya listesi içermiyor"
    elif ! cmp -s "$TMP/exp-ql" "$TMP/got-ql"; then
        miss="$(comm -23 "$TMP/exp-ql" "$TMP/got-ql" | head -1)"
        extra="$(comm -13 "$TMP/exp-ql" "$TMP/got-ql" | head -1)"
        r="paket-sorgu.txt listesi rpm -ql çıktısıyla eşleşmiyor"
        [ -n "$miss" ]  && r="$r (eksik: $miss)"
        [ -n "$extra" ] && r="$r (fazla: $extra)"
    fi
fi
[ -z "$r" ] && ok "paket-sorgu.txt dosya listesi paketin gerçek listesiyle eşleşiyor" ||
    bad "$r"

# --- 3. butunluk-raporu.txt paket ve dosya ------------------------------
r=""
VIMRC_PKG="$(rpm -qf --qf '%{NAME}' /etc/vimrc 2>/dev/null)"
if [ ! -f "$ANS/butunluk-raporu.txt" ]; then
    r="$ANS/butunluk-raporu.txt yok"
else
    norm "$ANS/butunluk-raporu.txt" > "$TMP/rapor"
    got_n="$(nlines "$TMP/rapor")"
    got_pkg="$(awk '$1 == "paket" {print $2; exit}' "$TMP/rapor")"
    got_file="$(awk '$1 == "dosya" {print $2; exit}' "$TMP/rapor")"
    if [ "$got_n" -ne 3 ]; then
        r="butunluk-raporu.txt $got_n dolu satır içeriyor, 3 olmalı"
    elif [ -z "$got_pkg" ]; then
        r="butunluk-raporu.txt 'paket <ad>' satırı içermiyor"
    else
        case "$got_pkg" in
            "$VIMRC_PKG"|"$VIMRC_PKG"-[0-9]*) ;;
            *) r="butunluk-raporu.txt paketi '$got_pkg', beklenen '$VIMRC_PKG'" ;;
        esac
        [ -z "$r" ] && [ "$got_file" != "/etc/vimrc" ] &&
            r="butunluk-raporu.txt dosyası '$got_file', beklenen /etc/vimrc"
    fi
fi
[ -z "$r" ] && ok "butunluk-raporu.txt doğru paket ve dosya yolunu içeriyor" ||
    bad "$r"

# --- 4. butunluk-raporu.txt icerik + izin -------------------------------
# İki token da aranır, sıraları serbesttir.
r=""
if [ ! -f "$ANS/butunluk-raporu.txt" ]; then
    r="$ANS/butunluk-raporu.txt yok"
else
    deg="$(awk '$1 == "degisen" {print tolower($2); exit}' "$TMP/rapor")"
    if [ -z "$deg" ]; then
        r="butunluk-raporu.txt 'degisen ...' satırı içermiyor"
    else
        printf '%s' "$deg" | tr ',' '\n' | grep -qx 'icerik' ||
            r="degisen alanında 'icerik' yok (gelen: $deg)"
        printf '%s' "$deg" | tr ',' '\n' | grep -qx 'izin' ||
            r="${r:+$r; }degisen alanında 'izin' yok (gelen: $deg)"
    fi
fi
[ -z "$r" ] && ok "butunluk-raporu.txt hem icerik hem izin değişikliğini işaretlemiş" ||
    bad "$r"

# --- 5. eksik-komut.txt dogru paket adi ---------------------------------
r=""
if [ ! -f "$ANS/eksik-komut.txt" ]; then
    r="$ANS/eksik-komut.txt yok"
else
    norm "$ANS/eksik-komut.txt" > "$TMP/eksik"
    got_n="$(nlines "$TMP/eksik")"
    got="$(head -1 "$TMP/eksik")"
    if [ "$got_n" -ne 1 ]; then
        r="eksik-komut.txt $got_n dolu satır içeriyor, 1 olmalı"
    else
        case "$got" in
            lsof|lsof-[0-9]*) ;;
            *) r="eksik-komut.txt '$got' içeriyor, beklenen 'lsof'" ;;
        esac
    fi
fi
[ -z "$r" ] && ok "eksik-komut.txt doğru paket adını içeriyor" || bad "$r"

# --- 6. lsof calisiyor ---------------------------------------------------
# Kurulu olması yetmez: student'ın PATH'inden çalışması sınanır.
r=""
if ! rpm -q lsof >/dev/null 2>&1; then
    r="lsof paketi kurulu değil"
else
    run_student 'lsof -v'
    [ "$RC" -eq 0 ] || r="student olarak lsof çalışmıyor: $(head -1 "$TMP/se")"
fi
[ -z "$r" ] && ok "lsof komutu artık çalışıyor" || bad "$r"

# --- 7. bc kurulu --------------------------------------------------------
r=""
rpm -q bc >/dev/null 2>&1 || r="bc paketi kurulu değil (dnf history undo yapıldı mı?)"
[ -z "$r" ] && ok "bc paketi kurulu" || bad "$r"

# --- 8. hesapla dogru sonucu uretiyor ------------------------------------
r=""
if [ ! -x /usr/local/bin/hesapla ]; then
    r="/usr/local/bin/hesapla yok ya da çalıştırılabilir değil"
else
    run_student 'echo "2+2" | hesapla'
    got="$(tr -d '[:space:]' < "$TMP/so")"
    if [ "$RC" -ne 0 ]; then
        r="hesapla sıfırdan farklı kod döndü ($RC): $(head -1 "$TMP/se")"
    elif [ "$got" != "4" ]; then
        r="hesapla '$got' bastı, beklenen '4'"
    fi
fi
[ -z "$r" ] && ok "hesapla scripti doğru sonucu üretiyor" || bad "$r"

# --- 9. rpm-inceleme.txt ad, surum, dosya listesi -----------------------
r=""
if [ -z "$RPM_FILE" ]; then
    r="$PKGDIR içinde .rpm dosyası yok"
elif [ ! -f "$ANS/rpm-inceleme.txt" ]; then
    r="$ANS/rpm-inceleme.txt yok"
else
    exp_name="$(rpm -qp --qf '%{NAME}' "$RPM_FILE" 2>/dev/null)"
    exp_ver="$(rpm -qp --qf '%{VERSION}' "$RPM_FILE" 2>/dev/null)"
    exp_rel="$(rpm -qp --qf '%{VERSION}-%{RELEASE}' "$RPM_FILE" 2>/dev/null)"
    rpm -qlp "$RPM_FILE" 2>/dev/null | sort > "$TMP/exp-rpm-l"

    norm "$ANS/rpm-inceleme.txt" > "$TMP/rpm-ins"
    got_name="$(awk '$1 == "paket-adi:" {print $2; exit}' "$TMP/rpm-ins")"
    got_ver="$(awk  '$1 == "surum:"     {print $2; exit}' "$TMP/rpm-ins")"
    awk 'f {print} $1 == "dosyalar:" {f = 1}' "$TMP/rpm-ins" | sort > "$TMP/got-rpm-l"

    if [ "$got_name" != "$exp_name" ]; then
        r="rpm-inceleme.txt paket-adi '$got_name', beklenen '$exp_name'"
    elif [ "$got_ver" != "$exp_ver" ] && [ "$got_ver" != "$exp_rel" ]; then
        r="rpm-inceleme.txt surum '$got_ver', beklenen '$exp_ver' (ya da '$exp_rel')"
    elif [ ! -s "$TMP/got-rpm-l" ]; then
        r="rpm-inceleme.txt 'dosyalar:' satırından sonra liste içermiyor"
    elif ! cmp -s "$TMP/exp-rpm-l" "$TMP/got-rpm-l"; then
        miss="$(comm -23 "$TMP/exp-rpm-l" "$TMP/got-rpm-l" | head -1)"
        r="rpm-inceleme.txt dosya listesi rpm -qlp çıktısıyla eşleşmiyor"
        [ -n "$miss" ] && r="$r (eksik: $miss)"
    fi
fi
[ -z "$r" ] && ok "rpm-inceleme.txt doğru paket adı, sürüm ve dosya listesi içeriyor" ||
    bad "$r"

# --- 10. rpm-inceleme.txt'deki paket KURULU DEGIL (negatif test) --------
r=""
if [ -z "$RPM_FILE" ]; then
    r="$PKGDIR içinde .rpm dosyası yok"
else
    n="$(rpm -qp --qf '%{NAME}' "$RPM_FILE" 2>/dev/null)"
    if rpm -q "$n" >/dev/null 2>&1; then
        r="$n sisteme KURULMUŞ; görev incelemekti, kurmak değil"
    fi
fi
[ -z "$r" ] && ok "rpm-inceleme.txt'deki paket sistemde kurulu değil" || bad "$r"

# --- 11. EPEL deposu etkin ----------------------------------------------
r=""
dnf repolist --enabled 2>/dev/null | grep -qiE '^epel[[:space:]]' ||
    r="epel deposu etkin değil"
[ -z "$r" ] && ok "EPEL deposu etkin" || bad "$r"

# --- 12. crb deposu etkin -----------------------------------------------
# Rocky 10'da dpkg'nin bağımlılığı zlib-ng crb reposunda; crb açılmadan
# 6. görev tamamlanamaz. Ayrı kriter, çünkü ayrı bir kavram.
r=""
dnf repolist --enabled 2>/dev/null | grep -qiE '^crb[[:space:]]' ||
    r="crb deposu etkin değil"
[ -z "$r" ] && ok "crb deposu etkin" || bad "$r"

# --- 13. dpkg kurulu ve calisiyor ---------------------------------------
r=""
if ! rpm -q dpkg >/dev/null 2>&1; then
    r="dpkg paketi kurulu değil"
else
    run_student 'dpkg-deb --version'
    [ "$RC" -eq 0 ] || r="student olarak dpkg-deb çalışmıyor: $(head -1 "$TMP/se")"
fi
[ -z "$r" ] && ok "dpkg kurulu ve çalışıyor" || bad "$r"

# --- 14. deb-inceleme.txt ad, surum, dosya listesi ----------------------
# Beklenen liste dosyanın kendisinden okunur; dpkg-deb yoksa (13. kriter
# zaten FAIL) bu kriter de FAIL verir, check çökmez.
r=""
if [ -z "$DEB_FILE" ]; then
    r="$PKGDIR içinde .deb dosyası yok"
elif [ ! -f "$ANS/deb-inceleme.txt" ]; then
    r="$ANS/deb-inceleme.txt yok"
elif ! command -v dpkg-deb >/dev/null 2>&1; then
    r="dpkg-deb kurulu değil, .deb içeriği sınanamıyor"
else
    exp_name="$(dpkg-deb -f "$DEB_FILE" Package 2>/dev/null)"
    exp_ver="$(dpkg-deb -f "$DEB_FILE" Version 2>/dev/null)"
    # dpkg-deb -c çıktısındaki yollar ./ ile başlar; sondaki dizinler atılır,
    # yalnız dosyalar karşılaştırılır ve ./ öneki normalleştirilir.
    dpkg-deb -c "$DEB_FILE" 2>/dev/null |
        awk '$1 !~ /^d/ {print $NF}' | sed 's#^\./#/#' | sort > "$TMP/exp-deb-l"

    norm "$ANS/deb-inceleme.txt" > "$TMP/deb-ins"
    got_name="$(awk '$1 == "paket-adi:" {print $2; exit}' "$TMP/deb-ins")"
    got_ver="$(awk  '$1 == "surum:"     {print $2; exit}' "$TMP/deb-ins")"
    awk 'f {print} $1 == "dosyalar:" {f = 1}' "$TMP/deb-ins" |
        sed 's#^\./#/#' | sort > "$TMP/got-deb-raw"
    # Öğrenci dizin satırlarını da yazmış olabilir; dosya satırları yeterli.
    grep -Fxf "$TMP/exp-deb-l" "$TMP/got-deb-raw" | sort -u > "$TMP/got-deb-l"

    if [ "$got_name" != "$exp_name" ]; then
        r="deb-inceleme.txt paket-adi '$got_name', beklenen '$exp_name'"
    elif [ "$got_ver" != "$exp_ver" ]; then
        r="deb-inceleme.txt surum '$got_ver', beklenen '$exp_ver'"
    elif ! cmp -s "$TMP/exp-deb-l" "$TMP/got-deb-l"; then
        miss="$(comm -23 "$TMP/exp-deb-l" "$TMP/got-deb-l" | head -1)"
        r="deb-inceleme.txt dosya listesi eksik (beklenen: ${miss:-?})"
    fi
fi
[ -z "$r" ] && ok "deb-inceleme.txt doğru paket adı, sürüm ve dosya listesi içeriyor" ||
    bad "$r"

# --- 15. deb-inceleme.txt'deki paket KURULU DEGIL (negatif test) --------
# dpkg veritabanı hiç yoksa da paket kurulu değildir; bu durum geçerli sayılır.
r=""
if [ -z "$DEB_FILE" ]; then
    r="$PKGDIR içinde .deb dosyası yok"
elif command -v dpkg-query >/dev/null 2>&1; then
    n="$(dpkg-deb -f "$DEB_FILE" Package 2>/dev/null)"
    if [ -n "$n" ] && dpkg-query -W -f '${Status}' "$n" 2>/dev/null |
         grep -q 'install ok installed'; then
        r="$n sisteme KURULMUŞ; görev incelemekti, kurmak değil"
    fi
fi
[ -z "$r" ] && ok "deb-inceleme.txt'deki paket sistemde kurulu değil" || bad "$r"

# --- 16. Kaynak dosyalar degismemis (korkuluk) --------------------------
r=""
for f in "$ORIG"/*; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    if [ ! -f "$PKGDIR/$b" ]; then
        r="${r:+$r; }$PKGDIR/$b silinmiş"
    elif ! cmp -s "$f" "$PKGDIR/$b"; then
        r="${r:+$r; }$PKGDIR/$b değiştirilmiş"
    fi
done
[ -z "$r" ] && ok "/srv/paketler altındaki dosyalar değiştirilmemiş" || bad "$r"

exit "$FAIL"
