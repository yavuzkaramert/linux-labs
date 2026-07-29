#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 008'in bozuk durumunu kurar. Idempotent.
#
# Konu: inode kimliği (hard link vs bağımsız kopya), symlink, FHS yerleşimi,
# gerçek disk kullanımı (du) ve tar ile arşivleme/doğrulama.
#
# Sıfır bedava OK: üç dosya yanlış dizinde, hedef dizinler (/var/log/myapp,
# /etc/myapp) hiç yok, backup-helper çalıştırma izni taşımıyor, cevaplar/
# dizini hiç yok, arşiv hiç yok. Tek istisna "kaynak dosyalar değişmemiş"
# korkuluğudur; taze ortamda doğal olarak sağlanır, amacı ödül değil yan
# hasarı yakalamaktır (örn. gecici/ dizinini --exclude yerine SİLEN çözüm).
set -euo pipefail

HOME_DIR=/home/student
SRC=/srv/backup-kaynagi
DATA=/srv/data
BACKUP=/srv/backup
ORIG=/srv/.orig

# --- 0. Temizlik (idempotens) ---------------------------------------------
rm -rf "$SRC" "$DATA" "$BACKUP" "$ORIG" /var/log/myapp /etc/myapp
rm -f  /usr/local/bin/backup-helper
rm -rf "$HOME_DIR/cevaplar"
rm -f  "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
       "$HOME_DIR/backup-helper" \
       "$HOME_DIR/kaynak3-hardlink.txt" "$HOME_DIR/kaynak3-symlink.txt"

# --- 1. Yanlış yerleşmiş dosyalar (FHS görevi) ----------------------------
# Üçü de ev dizininde duruyor. Doğru yerleri sırasıyla /var/log/myapp,
# /etc/myapp ve /usr/local/bin. Hedef dizinlerin ikisi de YOK: öğrenci
# sudo ile açacak. /usr/local/bin zaten var, orada iş izin bitinde.
cat > "$HOME_DIR/uygulama.log" <<'EOF'
2026-07-20 09:14:02 INFO  servis basladi
2026-07-20 09:14:07 INFO  yapilandirma okundu
2026-07-20 10:02:41 WARN  onbellek isabet orani dusuk
2026-07-20 11:37:19 ERROR yedek birimine yazilamadi
2026-07-20 11:37:25 INFO  yeniden deneme kuyruga alindi
2026-07-21 08:00:03 INFO  gece isi tamamlandi
EOF

cat > "$HOME_DIR/myapp.conf" <<'EOF'
listen_port = 8080
data_dir = /srv/data
backup_dir = /srv/backup
log_level = info
retention_days = 14
EOF

# İçerik bilinçli olarak 5. görevin cevabını VERMEZ: yalnız mevcut
# arşivleri listeler. Çalıştırma izni yok — 3. kriterin bozuk hâli.
cat > "$HOME_DIR/backup-helper" <<'EOF'
#!/usr/bin/env bash
# Yedek dizinindeki arsivleri listeler.
set -eu
ls -lh /srv/backup
EOF

chown student:student "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
                      "$HOME_DIR/backup-helper"
chmod 0644 "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
           "$HOME_DIR/backup-helper"

# --- 2. Bağlantı kaynakları ------------------------------------------------
# Dizin root'a ait (0755): öğrenci burada dosya yaratamaz, bağlantılarını
# ev dizinine kurar. Dosyaların SAHİBİ student — bu bilinçli:
# fs.protected_hardlinks=1 altında kendine ait olmayan ve yazma izni
# bulunmayan bir dosyaya hard link kurmak EPERM verir; root sahipli
# bırakılsaydı 3. görev öğrenci için imkânsız olurdu.
#
# Boyutlar bilinçli seçildi:
#   kaynak1.txt 100000 B  (+ hard link'i, disk'te bir kez sayılır)
#   kaynak2.txt  60000 B  (+ bağımsız kopyası, iki kez sayılır)
#   kaynak3.txt  40000 B
# du -s → 100+60+60+40 = 260 KB. Görünen boyutları toplayan (hard link'i
# ikinci kez sayan) çözüm 360 KB der. 4. görevin tuzağı tam olarak budur.
mkdir -p "$SRC"
chown root:root "$SRC"
chmod 0755 "$SRC"

# Boru hattı KULLANILMIYOR: `yes ... | head -c N` head çıkınca yes'e SIGPIPE
# yollar, `set -o pipefail` altında pipeline 141 döner ve setup ölür.
# Önce fazlasıyla yaz, sonra truncate ile tam boyuta indir.
gen() {  # gen <dosya> <bayt> <satir metni>
    local f="$1" n="$2" s="$3" i
    : > "$f"
    for ((i = 0; i < n / 20 + 1; i++)); do printf '%s\n' "$s"; done > "$f"
    truncate -s "$n" "$f"
}
gen "$SRC/kaynak1.txt" 100000 'kaynak1 - birincil yedek kaynagi'
gen "$SRC/kaynak2.txt" 60000  'kaynak2 - ikincil yedek kaynagi'
gen "$SRC/kaynak3.txt" 40000  'kaynak3 - arsiv disi kaynak'

# kaynak1-yedek.txt: AYNI inode (hard link).
ln "$SRC/kaynak1.txt" "$SRC/kaynak1-yedek.txt"
# kaynak2-kopya.txt: birebir aynı içerik, FARKLI inode. Tuzak burada:
# diff ve cmp sessiz kalır, ayırt eden tek şey inode karşılaştırmasıdır.
cp "$SRC/kaynak2.txt" "$SRC/kaynak2-kopya.txt"

chown student:student "$SRC"/*
chmod 0644 "$SRC"/*

# --- 3. Arşivlenecek ağaç --------------------------------------------------
# gecici/ arşive girmeyecek. --exclude yerine dizini SİLEN çözüm 11.
# kriterden düşer; arşivleme kaynağı değiştirmez.
mkdir -p "$DATA/kalici" "$DATA/gecici"
printf '%s\n' 'kalici veri govdesi' 'ikinci satir' > "$DATA/dosya.txt"
printf '%s\n' 'bu dosya yedege girmeli' > "$DATA/kalici/onemli.txt"
printf '%s\n' 'bu dosya yedege girmemeli' > "$DATA/gecici/silinecek.txt"
chown -R student:student "$DATA"
chmod 0755 "$DATA" "$DATA/kalici" "$DATA/gecici"
chmod 0644 "$DATA/dosya.txt" "$DATA/kalici/onemli.txt" \
           "$DATA/gecici/silinecek.txt"

# Hedef dizin boş açılır: odak tar'da, mkdir'de değil (mkdir zaten 1.
# görevde iki kez yapılıyor).
mkdir -p "$BACKUP"
chown student:student "$BACKUP"
chmod 0755 "$BACKUP"

# --- 4. Orijinal kopyalar (check referansı) --------------------------------
# 0700/0400 root: student okuyamaz, cevabı buradan kopyalayamaz.
mkdir -p "$ORIG/data"
cp "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
   "$HOME_DIR/backup-helper" "$ORIG/"
cp "$SRC/kaynak1.txt" "$SRC/kaynak2.txt" "$SRC/kaynak3.txt" "$ORIG/"
cp -a "$DATA/." "$ORIG/data/"
chown -R root:root "$ORIG"
chmod -R go-rwx "$ORIG"
chmod 0700 "$ORIG" "$ORIG/data"
find "$ORIG" -type f -exec chmod 0400 {} +

# --- 5. Kendi kendini doğrulama --------------------------------------------
err=0
say() { echo "setup HATA: $*" >&2; err=1; }

ino() { stat -c '%i' "$1"; }

# Bozuk başlangıç gerçekten bozuk mu?
[ ! -e /var/log/myapp ] || say "/var/log/myapp var olmamali"
[ ! -e /etc/myapp ]     || say "/etc/myapp var olmamali"
[ ! -e /usr/local/bin/backup-helper ] || say "backup-helper /usr/local/bin'de olmamali"
[ ! -e "$HOME_DIR/cevaplar" ]         || say "cevaplar/ var olmamali"
[ ! -e "$BACKUP/data-yedek.tar.gz" ]  || say "arsiv var olmamali"
[ ! -x "$HOME_DIR/backup-helper" ]    || say "backup-helper x biti tasimamali"
for f in "$HOME_DIR/uygulama.log" "$HOME_DIR/myapp.conf" \
         "$HOME_DIR/backup-helper" "$SRC/kaynak1.txt" "$SRC/kaynak1-yedek.txt" \
         "$SRC/kaynak2.txt" "$SRC/kaynak2-kopya.txt" "$SRC/kaynak3.txt" \
         "$DATA/dosya.txt" "$DATA/kalici/onemli.txt" \
         "$DATA/gecici/silinecek.txt"; do
    [ -f "$f" ] || say "$f yok"
done
[ -d "$BACKUP" ] || say "$BACKUP yok"

# Hard link ve bağımsız kopya tuzağı gerçekten kuruldu mu?
[ "$(ino "$SRC/kaynak1.txt")" = "$(ino "$SRC/kaynak1-yedek.txt")" ] ||
    say "kaynak1-yedek.txt hard link degil"
[ "$(stat -c '%h' "$SRC/kaynak1.txt")" -ge 2 ] ||
    say "kaynak1.txt link sayisi 2'den kucuk"
[ "$(ino "$SRC/kaynak2.txt")" != "$(ino "$SRC/kaynak2-kopya.txt")" ] ||
    say "kaynak2-kopya.txt bagimsiz kopya degil"
cmp -s "$SRC/kaynak2.txt" "$SRC/kaynak2-kopya.txt" ||
    say "kaynak2-kopya.txt icerigi kaynak2.txt ile ayni degil (tuzak etkisiz)"

# du tuzağı: gerçek kullanım ile görünen boyut toplamı FARKLI olmalı.
real_kb=$(du -s "$SRC" | cut -f1)
apparent_kb=$(stat -c '%s' "$SRC"/* | awk '{t += $1} END {print int((t + 1023) / 1024)}')
[ "$real_kb" -lt "$apparent_kb" ] ||
    say "du tuzagi etkisiz (gercek $real_kb KB, gorunen $apparent_kb KB)"

# student gerçekten hard link kurabiliyor mu? (protected_hardlinks kontrolü)
if ! su - student -c "ln /srv/backup-kaynagi/kaynak3.txt /tmp/.hl-probe.\$\$ \
                      && rm -f /tmp/.hl-probe.\$\$" >/dev/null 2>&1; then
    say "student kaynak3.txt'ye hard link kuramiyor (protected_hardlinks?)"
fi

# student kaynak dizininde dosya yaratamamalı (bağlantılar ev dizinine).
if su - student -c "touch $SRC/.probe" >/dev/null 2>&1; then
    rm -f "$SRC/.probe"
    say "student $SRC icine yazabiliyor, dizin root:root 0755 olmali"
fi

[ "$err" -eq 0 ] || exit 1
echo "setup done: 008-links-fhs-archiving"
