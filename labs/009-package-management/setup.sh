#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 009'un bozuk durumunu kurar. Idempotent.
#
# Konu: rpm sorgulama (-qf/-ql/-V), dnf provides, dnf history undo, paket
# dosyasını kurmadan inceleme (rpm -qlp/-qip, dpkg-deb -c/-I), EPEL + crb.
#
# Sıfır bedava OK: /etc/vimrc hem içerik hem izin olarak bozuk, lsof kurulu
# değil, bc gerçek bir history işlemiyle kaldırılmış, hesapla kurulu ama
# çalışmıyor, epel-release kurulu değil, crb kapalı, dpkg yok, .rpm ve .deb
# dosyaları kurulu değil, cevaplar/ dizini hiç yok. Tek istisna "kaynak
# dosyalar değişmemiş" korkuluğudur; taze ortamda doğal olarak sağlanır,
# amacı ödül değil yan hasarı yakalamaktır (örn. .rpm'i inceleyeceğine kuran
# çözüm ya da paket dosyasını silen çözüm).
#
# NETWORK GEREKİYOR: bc'nin install/remove işlemleri GERÇEK dnf işlemleridir,
# taklit edilmez — öğrenci gerçek bir history kaydı üzerinde çalışır.
set -euo pipefail

HOME_DIR=/home/student
ASSETS=/opt/lab-assets
PKGDIR=/srv/paketler
ORIG=/srv/.orig-009

# --- 0. Temizlik (idempotens) ---------------------------------------------
# Öğrencinin kurmuş olabileceği her şey geri alınır; setup ikinci kez
# koşturulduğunda başlangıç durumu birebir aynı olmalı.
rm -rf "$PKGDIR" "$ORIG" "$HOME_DIR/cevaplar"
rm -f  /usr/local/bin/hesapla

dnf -y remove lsof bc dpkg ed epel-release >/dev/null 2>&1 || true
# dpkg ile birlikte gelen bağımlılıklar da gitmeli: zlib-ng crb'den gelir,
# bırakılırsa 6. görevin bağımlılık hatası hiç ortaya çıkmaz.
dnf -y remove zlib-ng libmd >/dev/null 2>&1 || true
dnf config-manager --set-disabled crb >/dev/null 2>&1 || true
rm -rf /var/lib/dpkg /var/lib/dpkg-* /etc/dpkg

# /etc/vimrc'yi önce KURULUM hâline döndür, sonra bilinçli olarak boz.
# Aksi hâlde ikinci koşuda bozma satırı iki kez eklenirdi.
#
# `dnf reinstall vim-common` BU İŞİ YAPMAZ: /etc/vimrc paket içinde config (c)
# işaretli, rpm değiştirilmiş bir config dosyasının üzerine yazmaz — yenisini
# /etc/vimrc.rpmnew olarak bırakır ve bozuk dosya yerinde kalır. Bu yüzden
# kurulum anındaki kopya image'da tutuluyor (Dockerfile üretiyor).
cp -p "$ASSETS/vimrc.pristine" /etc/vimrc
chown root:root /etc/vimrc
rm -f /etc/vimrc.rpmnew /etc/vimrc.rpmsave

# --- 1. Paket dosyaları (görev 5 ve 6) ------------------------------------
# Varlıklar image'da /opt/lab-assets altında duruyor (Dockerfile üretiyor).
# Buradan KOPYALANIYOR: öğrenci /srv/paketler'i bozsa bile reset gerçekten
# eski hâle döndürür ve setup network'ten dosya indirmez.
mkdir -p "$PKGDIR"
cp "$ASSETS"/*.rpm "$ASSETS"/*.deb "$PKGDIR/"
chown -R root:root "$PKGDIR"
chmod 0755 "$PKGDIR"
chmod 0644 "$PKGDIR"/*

# --- 2. /etc/vimrc bütünlük bozma (görev 2) -------------------------------
# İçerik + izin birlikte bozulur: rpm -V çıktısı 5 (md5) ve M (mode)
# bayraklarını birlikte göstersin, cevabın iki bileşeni de gerçek olsun.
printf '%s\n' '" elle eklenmis satir - paket disi degisiklik' >> /etc/vimrc
chmod 0666 /etc/vimrc

# --- 3. hesapla script'i (görev 4) ----------------------------------------
# bc'ye dayanır. bc kaldırılmış olduğu için şu an sıfırdan farklı kod döner.
cat > /usr/local/bin/hesapla <<'EOF'
#!/usr/bin/env bash
# Standart girdiden okudugu aritmetik ifadeyi hesaplar.
# Hesaplamayi kendisi yapmaz, bc'ye devreder.
set -eu
exec bc -l
EOF
chmod 0755 /usr/local/bin/hesapla
chown root:root /usr/local/bin/hesapla

# --- 4. Gerçek history işlemleri (görev 4) --------------------------------
# İki AYRI gerçek dnf işlemi: önce kurulum, sonra kaldırma. Öğrenci
# `dnf history undo` ile kaldırma işlemini geri alacak.
dnf -y install bc >/dev/null
dnf -y remove  bc >/dev/null
# Kaldırma işlemi listenin en üstünde kalmasın: aksi hâlde "en son işlemi
# geri al" refleksi doğru cevabı kazara verir, geçmişi okuma gereği kalkar.
dnf -y reinstall tree >/dev/null

# --- 5. Orijinal kopyalar (check referansı) -------------------------------
# 0700/0400 root: student okuyamaz, paket dosyalarını buradan kurtaramaz.
mkdir -p "$ORIG"
cp "$PKGDIR"/* "$ORIG/"
chown -R root:root "$ORIG"
chmod 0700 "$ORIG"
find "$ORIG" -type f -exec chmod 0400 {} +

# --- 6. Kendi kendini doğrulama -------------------------------------------
err=0
say() { echo "setup HATA: $*" >&2; err=1; }

# Varlıklar yerinde mi?
ls "$PKGDIR"/*.rpm >/dev/null 2>&1 || say "$PKGDIR icinde .rpm yok"
ls "$PKGDIR"/*.deb >/dev/null 2>&1 || say "$PKGDIR icinde .deb yok"

rpm_pkg="$(rpm -qp --qf '%{NAME}' "$PKGDIR"/*.rpm 2>/dev/null || true)"
[ -n "$rpm_pkg" ] || say ".rpm dosyasi okunamiyor (rpm -qp bos dondu)"
[ -n "$rpm_pkg" ] && rpm -q "$rpm_pkg" >/dev/null 2>&1 &&
    say "$rpm_pkg zaten kurulu, 5. gorev anlamsiz"

# Bozuk başlangıç gerçekten bozuk mu?
# NOT: `rpm -V ... | grep` YAZILMAZ. rpm fark bulunca 1 döner ve `set -o
# pipefail` altında grep eşleşse bile pipeline 1 verir — kontrol her zaman
# ters sonuç üretirdi. Çıktı önce değişkene alınır.
vimrc_v="$(rpm -V vim-common 2>/dev/null || true)"
[ -n "$vimrc_v" ] || say "rpm -V vim-common temiz dondu, /etc/vimrc bozulmamis"
case "$vimrc_v" in
    ??5*) ;;
    *) say "rpm -V icerik (5) degisikligini gostermiyor: $vimrc_v" ;;
esac
case "$vimrc_v" in
    ?M*) ;;
    *) say "rpm -V izin (M) degisikligini gostermiyor: $vimrc_v" ;;
esac

command -v lsof >/dev/null 2>&1 && say "lsof kurulu olmamali"
rpm -q bc   >/dev/null 2>&1 && say "bc kurulu olmamali"
rpm -q dpkg >/dev/null 2>&1 && say "dpkg kurulu olmamali"
rpm -q epel-release >/dev/null 2>&1 && say "epel-release kurulu olmamali"
dnf repolist --enabled 2>/dev/null | grep -qi '^epel' &&
    say "epel deposu etkin olmamali"
dnf repolist --enabled 2>/dev/null | grep -qi '^crb' &&
    say "crb deposu etkin olmamali"

[ -x /usr/local/bin/hesapla ] || say "hesapla kurulu degil"
if su - student -c 'echo "2+2" | hesapla' >/dev/null 2>&1; then
    say "hesapla calisiyor, bc kaldirilmis olmali"
fi

# bc'yi kaldıran gerçek bir history işlemi var mı?
dnf history list 2>/dev/null | grep -q 'remove bc' ||
    say "history icinde 'remove bc' islemi yok"

[ ! -e "$HOME_DIR/cevaplar" ] || say "cevaplar/ var olmamali"

# student paket dizinine yazamamalı (kaynak korunsun).
if su - student -c "touch $PKGDIR/.probe" >/dev/null 2>&1; then
    rm -f "$PKGDIR/.probe"
    say "student $PKGDIR icine yazabiliyor, dizin root:root 0755 olmali"
fi

[ "$err" -eq 0 ] || exit 1
echo "setup done: 009-package-management"
