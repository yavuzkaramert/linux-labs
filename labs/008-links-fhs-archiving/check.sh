#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1. Eksik dosya check'i çökertmez;
# ilgili kriter FAIL verir, koşu devam eder.
#
# Hiçbir dosya SİLİNMEZ, hiçbir bağlantı bozulmaz: "orijinali sil, symlink
# kırıldı mı bak" gibi yıkıcı test yok. Bağlantı kimliği inode üzerinden
# ölçülür, davranış üzerinden değil.
set -u

HOME_DIR=/home/student
SRC=/srv/backup-kaynagi
DATA=/srv/data
BACKUP=/srv/backup
ORIG=/srv/.orig
ANS="$HOME_DIR/cevaplar"
ARCHIVE="$BACKUP/data-yedek.tar.gz"

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

nlines() { [ -f "$1" ] && awk 'END {print NR + 0}' "$1" || echo 0; }
ino()    { stat -c '%i' "$1" 2>/dev/null; }

# Cevap dosyaları için normalleştirme: baş/son boşluk kırpılır, iç boşluklar
# teke indirilir, boş satırlar atılır, sıra serbest bırakılır (sort).
# Amaç biçimsel titizlik değil, cevabın kendisi.
norm_answer() {
    sed -e 's/[[:space:]]\+/ /g' -e 's/^ //' -e 's/ $//' -e '/^$/d' "$1" | sort
}

# Öğrenci perspektifi: PATH ve okuma izinleri student olarak sınanır.
run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

# --- 1. uygulama.log /var/log/myapp altinda, eski konumda yok -------------
r=""
if [ ! -f /var/log/myapp/uygulama.log ]; then
    r="/var/log/myapp/uygulama.log yok"
elif ! cmp -s "$ORIG/uygulama.log" /var/log/myapp/uygulama.log; then
    r="/var/log/myapp/uygulama.log içeriği orijinaliyle aynı değil"
elif [ -e "$HOME_DIR/uygulama.log" ]; then
    r="$HOME_DIR/uygulama.log hâlâ duruyor (taşındı değil kopyalandı)"
fi
[ -z "$r" ] && ok "uygulama.log /var/log/myapp/ altında, eski konumda yok" ||
    bad "$r"

# --- 2. myapp.conf /etc/myapp altinda, eski konumda yok -------------------
r=""
if [ ! -f /etc/myapp/myapp.conf ]; then
    r="/etc/myapp/myapp.conf yok"
elif ! cmp -s "$ORIG/myapp.conf" /etc/myapp/myapp.conf; then
    r="/etc/myapp/myapp.conf içeriği orijinaliyle aynı değil"
elif [ -e "$HOME_DIR/myapp.conf" ]; then
    r="$HOME_DIR/myapp.conf hâlâ duruyor (taşındı değil kopyalandı)"
fi
[ -z "$r" ] && ok "myapp.conf /etc/myapp/ altında, eski konumda yok" || bad "$r"

# --- 3. backup-helper /usr/local/bin altinda ve calistirilabilir ---------
# İzin biti kadar PATH da sınanır: 006'da script'in nereden çağrıldığı
# karışmıştı, /usr/local/bin zaten PATH'te.
r=""
if [ ! -f /usr/local/bin/backup-helper ]; then
    r="/usr/local/bin/backup-helper yok"
elif ! cmp -s "$ORIG/backup-helper" /usr/local/bin/backup-helper; then
    r="/usr/local/bin/backup-helper içeriği orijinaliyle aynı değil"
elif [ ! -x /usr/local/bin/backup-helper ]; then
    r="/usr/local/bin/backup-helper çalıştırma izni taşımıyor (chmod +x)"
elif [ -e "$HOME_DIR/backup-helper" ]; then
    r="$HOME_DIR/backup-helper hâlâ duruyor (taşındı değil kopyalandı)"
else
    run_student 'command -v backup-helper >/dev/null'
    [ "$RC" -eq 0 ] || r="backup-helper student'ın PATH'inde bulunamıyor"
fi
[ -z "$r" ] && ok "backup-helper /usr/local/bin/ altında ve çalıştırılabilir" ||
    bad "$r"

# --- 4. baglanti-raporu.txt ----------------------------------------------
r=""
printf '%s\n' 'kaynak1-yedek.txt hardlink' 'kaynak2-kopya.txt bagimsiz' |
    sort > "$TMP/exp-rapor"
if [ ! -f "$ANS/baglanti-raporu.txt" ]; then
    r="$ANS/baglanti-raporu.txt yok"
else
    norm_answer "$ANS/baglanti-raporu.txt" > "$TMP/got-rapor"
    got_n="$(nlines "$TMP/got-rapor")"
    if [ "$got_n" -ne 2 ]; then
        r="baglanti-raporu.txt $got_n dolu satır içeriyor, 2 olmalı"
    elif ! cmp -s "$TMP/exp-rapor" "$TMP/got-rapor"; then
        r="baglanti-raporu.txt etiketleri yanlış (gelen: $(tr '\n' ' ' < "$TMP/got-rapor"))"
    fi
fi
[ -z "$r" ] && ok "baglanti-raporu.txt iki satır, etiketler doğru" || bad "$r"

# --- 5. kaynak3-hardlink.txt ayni inode ----------------------------------
# Symlink de `cmp` testini geçer, o yüzden inode ve link sayısı sorulur.
r=""
if [ ! -e "$HOME_DIR/kaynak3-hardlink.txt" ]; then
    r="$HOME_DIR/kaynak3-hardlink.txt yok"
elif [ -L "$HOME_DIR/kaynak3-hardlink.txt" ]; then
    r="kaynak3-hardlink.txt sembolik bağlantı, hard link olmalı"
elif [ "$(ino "$HOME_DIR/kaynak3-hardlink.txt")" != "$(ino "$SRC/kaynak3.txt")" ]; then
    r="kaynak3-hardlink.txt farklı inode taşıyor (kopya mı?): \
$(ino "$HOME_DIR/kaynak3-hardlink.txt") vs $(ino "$SRC/kaynak3.txt")"
elif [ "$(stat -c '%h' "$SRC/kaynak3.txt")" -lt 2 ]; then
    r="kaynak3.txt link sayısı 2'den küçük"
fi
[ -z "$r" ] && ok "kaynak3-hardlink.txt kaynak3.txt ile aynı inode" || bad "$r"

# --- 6. kaynak3-symlink.txt dogru hedefe isaret ediyor -------------------
# Göreli ya da mutlak hedef kabul: ölçülen şey nereye VARDIĞI.
r=""
if [ ! -L "$HOME_DIR/kaynak3-symlink.txt" ]; then
    if [ -e "$HOME_DIR/kaynak3-symlink.txt" ]; then
        r="kaynak3-symlink.txt sembolik bağlantı değil"
    else
        r="$HOME_DIR/kaynak3-symlink.txt yok"
    fi
else
    tgt="$(readlink -f "$HOME_DIR/kaynak3-symlink.txt" 2>/dev/null)"
    if [ "$tgt" != "$SRC/kaynak3.txt" ]; then
        r="kaynak3-symlink.txt '$(readlink "$HOME_DIR/kaynak3-symlink.txt")' gösteriyor, hedef $SRC/kaynak3.txt olmalı"
    fi
fi
[ -z "$r" ] && ok "kaynak3-symlink.txt doğru hedefe işaret ediyor" || bad "$r"

# --- 7. disk-kullanimi.txt ------------------------------------------------
# Beklenen değer check anında ölçülür, sabit yazılmaz: blok boyutu ve
# dosya sistemi ortama göre değişebilir. Hard link'i ikinci kez sayan
# çözümün vereceği sayı da hesaplanıp FAIL mesajında adıyla söylenir.
r=""
real_kb="$(du -s "$SRC" | cut -f1)"
# %b 512 baytlık blok sayısıdır; /2 ile KB'ye çevrilir. Hard link'i ikinci
# kez sayan çözüm kaynak1.txt'yi iki kez toplar.
k1_kb=$(( $(stat -c '%b' "$SRC/kaynak1.txt" 2>/dev/null || echo 0) / 2 ))
dup_kb=$(( real_kb + k1_kb ))
if [ ! -f "$ANS/disk-kullanimi.txt" ]; then
    r="$ANS/disk-kullanimi.txt yok"
else
    got_n="$(grep -c '[^[:space:]]' "$ANS/disk-kullanimi.txt" || true)"
    val="$(tr -d '[:space:]' < "$ANS/disk-kullanimi.txt")"
    if [ "$got_n" -ne 1 ]; then
        r="disk-kullanimi.txt $got_n dolu satır içeriyor, 1 olmalı"
    elif ! printf '%s' "$val" | grep -qE '^[0-9]+$'; then
        r="disk-kullanimi.txt '$val' içeriyor, yalnız sayı olmalı (birim harfi yok)"
    elif [ "$val" -eq "$dup_kb" ]; then
        r="disk-kullanimi.txt $val KB diyor, beklenen $real_kb KB — hard link paylaşımı sayılmamış, aynı inode iki kez toplanmış"
    elif [ "$val" -ne "$real_kb" ]; then
        r="disk-kullanimi.txt $val KB diyor, beklenen $real_kb KB"
    fi
fi
[ -z "$r" ] && ok "disk-kullanimi.txt tek satır, doğru sayı ($real_kb KB)" ||
    bad "$r"

# --- Arsiv listesi (8, 9 ve 10 icin ortak) -------------------------------
# Listeleme student olarak yapılır: arşivin okunabilir olması da kriterin
# parçası. Yol öneki serbest (data/, ./data/, çıplak) — sonek eşleşmesi.
ARCH_OK=0
if [ -f "$ARCHIVE" ]; then
    run_student "tar -tzf '$ARCHIVE'"
    if [ "$RC" -eq 0 ]; then
        ARCH_OK=1
        cp "$TMP/so" "$TMP/list"
    fi
fi

# --- 8. arsiv var, gecici iceriği arsivde yok ---------------------------
r=""
if [ ! -f "$ARCHIVE" ]; then
    r="$ARCHIVE yok"
elif [ "$ARCH_OK" -eq 0 ]; then
    r="$ARCHIVE student olarak listelenemedi: $(head -1 "$TMP/se")"
else
    n="$(grep -cE '(^|/)gecici(/|$)' "$TMP/list" || true)"
    [ "$n" -eq 0 ] || r="arşivde gecici ile ilgili $n girdi var"
fi
[ -z "$r" ] && ok "data-yedek.tar.gz var, gecici içeriği arşivde yok" || bad "$r"

# --- 9. arsivde dosya.txt ve kalici/onemli.txt var ----------------------
r=""
if [ "$ARCH_OK" -eq 0 ]; then
    r="arşiv listelenemediği için içerik sınanamıyor"
else
    grep -qE '(^|/)dosya\.txt$' "$TMP/list" ||
        r="arşivde dosya.txt yok"
    grep -qE '(^|/)kalici/onemli\.txt$' "$TMP/list" ||
        r="${r:+$r; }arşivde kalici/onemli.txt yok"
fi
[ -z "$r" ] && ok "data-yedek.tar.gz içinde dosya.txt ve kalici/onemli.txt var" ||
    bad "$r"

# --- 10. arsiv-dogrulama.txt --------------------------------------------
r=""
printf '%s\n' 'kalici/onemli.txt var' 'gecici/silinecek.txt yok' |
    sort > "$TMP/exp-dog"
if [ ! -f "$ANS/arsiv-dogrulama.txt" ]; then
    r="$ANS/arsiv-dogrulama.txt yok"
else
    norm_answer "$ANS/arsiv-dogrulama.txt" > "$TMP/got-dog"
    got_n="$(nlines "$TMP/got-dog")"
    if [ "$got_n" -ne 2 ]; then
        r="arsiv-dogrulama.txt $got_n dolu satır içeriyor, 2 olmalı"
    elif ! cmp -s "$TMP/exp-dog" "$TMP/got-dog"; then
        r="arsiv-dogrulama.txt içeriği yanlış (gelen: $(tr '\n' ' ' < "$TMP/got-dog"))"
    fi
fi
[ -z "$r" ] && ok "arsiv-dogrulama.txt iki satır, doğru var/yok" || bad "$r"

# --- 11. Kaynaklar degismemis (korkuluk) --------------------------------
# gecici/ dizinini --exclude yerine SİLEN çözüm buradan düşer. Ayrıca
# kaynak dosyalarının içeriği ve kaynak1 hard link ilişkisi korunmalı.
r=""
for f in kaynak1.txt kaynak2.txt kaynak3.txt; do
    if [ ! -f "$SRC/$f" ]; then
        r="${r:+$r; }$SRC/$f silinmiş"
    elif ! cmp -s "$ORIG/$f" "$SRC/$f"; then
        r="${r:+$r; }$SRC/$f değiştirilmiş"
    fi
done
for f in kaynak1-yedek.txt kaynak2-kopya.txt; do
    [ -e "$SRC/$f" ] || r="${r:+$r; }$SRC/$f silinmiş"
done
if [ -e "$SRC/kaynak1.txt" ] && [ -e "$SRC/kaynak1-yedek.txt" ] &&
   [ "$(ino "$SRC/kaynak1.txt")" != "$(ino "$SRC/kaynak1-yedek.txt")" ]; then
    r="${r:+$r; }kaynak1-yedek.txt artık kaynak1.txt ile aynı inode değil"
fi
if ! diff -r -q "$ORIG/data" "$DATA" >/dev/null 2>&1; then
    d="$(diff -r -q "$ORIG/data" "$DATA" 2>&1 | head -1)"
    r="${r:+$r; }/srv/data değişmiş (${d:-?})"
fi
[ -z "$r" ] && ok "/srv/data ve /srv/backup-kaynagi kaynakları değişmemiş" ||
    bad "$r"

exit "$FAIL"
