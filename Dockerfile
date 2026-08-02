# --- Lab 009 varlığı: ogrenci-arac_1.0_all.deb -----------------------------
# Lab 009 öğrenciden kurulmamış bir .deb dosyasını incelemesini istiyor.
# Gerçek bir Debian paketi indirmek yerine burada sıfırdan üretiliyor:
# paket adı, sürümü ve içeriği bilinen ve SABİT olur, check.sh sürüm
# sürüklenmesine yakalanmaz ve setup.sh network'e bağımlı kalmaz.
# Architecture: all — bu stage'in mimarisi (arm64/amd64) sonucu etkilemez.
FROM debian:stable AS debbuilder
RUN mkdir -p /build/ogrenci-arac/DEBIAN /build/ogrenci-arac/usr/local/bin && \
    printf '%s\n' \
        'Package: ogrenci-arac' \
        'Version: 1.0' \
        'Section: utils' \
        'Priority: optional' \
        'Architecture: all' \
        'Maintainer: linux-labs <lab@example.invalid>' \
        'Description: Lab 009 icin uretilen ornek arac' \
        ' Kurulmadan incelenmek uzere hazirlanmis kucuk bir Debian paketi.' \
      > /build/ogrenci-arac/DEBIAN/control && \
    printf '%s\n' '#!/bin/sh' 'echo "ogrenci-arac 1.0"' \
      > /build/ogrenci-arac/usr/local/bin/ogrenci-arac && \
    chmod 0755 /build/ogrenci-arac/usr/local/bin/ogrenci-arac && \
    dpkg-deb --build /build/ogrenci-arac /build/ogrenci-arac_1.0_all.deb

# Faz A base image — RHCSA hedefi RHEL'e özgü olduğu için RHEL uyumlu
# bir dağıtım gerekiyor. Rocky 10, RHEL 10 (EX200 v10) ile birebir.
#
# Tag çalışmazsa alternatifler:
#   quay.io/rockylinux/rockylinux:10
#   almalinux:10                      (Docker Hub official library image)
FROM rockylinux/rockylinux:10

# RHEL tabanlı container image'leri belgeleri kırpılmış gelir
# (dnf.conf içinde tsflags=nodocs). Bizim yöntemimizin merkezinde
# "önce man'e bak" var, o yüzden bunu geri açıyoruz. Ayarı kaldırmak
# yalnız BUNDAN SONRA kurulan paketleri etkiler; zaten kurulu gelen
# paketlerin (bash, tar, coreutils...) man sayfaları için reinstall şart.
RUN sed -i '/^tsflags=nodocs/d' /etc/dnf/dnf.conf

# --allowerasing: Rocky container image'ı yer kazanmak için `coreutils-single`
# (tek multicall binary) ile gelir; gerçek RHEL sunucusundaki `coreutils` ile
# çakışır. Öğrenilen ortam gerçek sunucuya benzemeli → tam coreutils kurulur,
# single sürüm silinir.
#
# ncurses: /usr/bin/clear, tput, reset ve infocmp bu pakette. vim-enhanced ile
# less yalnız ncurses-libs'i (kütüphane) çekiyor, komutları getirmiyor.
#
# dnf-plugins-core: `dnf download` ve `dnf config-manager` bu pakette (Rocky 10
# dnf-4.20 ile geliyor, dnf5 değil). Build sırasında lab 009'un .rpm varlığını
# indirmek için gerekiyor; gerçek sunucularda da rutin olarak kurulu.
#
# systemd: lab 010 için. Container image'ı systemd'siz gelir (PID 1 sleep).
# Paket KURULUR ama CMD DEĞİŞMEZ — /usr/sbin/init yalnız `# ENV:
# container-systemd` işaretli lablarda entrypoint olarak çağrılır (labctl
# yapar). Normal lablar hâlâ `sleep infinity` PID 1 ile koşar.
#
# chrony: lab 011 için. Saat senkronu görevinde chronyd.service etkinleştirilir
# ve /etc/chrony.conf düzeltilir. Paket kurulur, servis image'da enabled DEĞİL —
# setup.sh onu bilinçli olarak durdurulmuş/devre dışı bırakır.
#
# openssh-server + openssh-clients + gnupg2: lab 012 için. sshd birim olarak
# koşar (container-systemd), öğrenci anahtarla girişi kurar ve sshd_config'i
# sertleştirir; host anahtarları image'da ÜRETİLMEZ, setup.sh `ssh-keygen -A`
# ile üretir — böylece `labctl reset` tertemiz bir sunucu verir. gnupg2
# şifreleme ve imza doğrulama görevlerinin aracı.
#
# BİLİNÇLİ OLARAK KURULMAYANLAR (lab 009 bunları öğrenciye kurdurur):
#   lsof, bc, dpkg, epel-release, ed
RUN dnf -y --allowerasing install \
        man-db man-pages \
        sudo vim-enhanced less which hostname tree file \
        ncurses dnf-plugins-core systemd \
        procps-ng psmisc util-linux findutils diffutils \
        coreutils grep sed gawk \
        passwd shadow-utils \
        tar gzip bzip2 xz cronie chrony tzdata \
        iproute bind-utils curl \
        openssh-server openssh-clients gnupg2 \
        glibc-langpack-en \
    && dnf -y reinstall '*' \
    && mandb -q \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Lab 009 varlıkları. Image'a gömülüyor, setup.sh oradan /srv/paketler'e
# KOPYALIYOR — böylece `labctl reset` öğrencinin bozduğu dosyaları gerçekten
# eski hâline döndürür ve setup.sh dosya indirmek için network'e çıkmaz.
#
# ed: küçük (~80 KB), baseos reposunda, image'da KURULU DEĞİL. Öğrenci onu
# kurmadan rpm -qlp/-qip ile inceleyecek. Sürüm sabitlenmiyor; check.sh
# beklenen değerleri dosyanın kendisinden okur, repo güncellemesi kırmaz.
RUN mkdir -p /opt/lab-assets && \
    dnf download --destdir=/opt/lab-assets ed && \
    ! rpm -q ed && \
    chmod 0644 /opt/lab-assets/*.rpm && \
    dnf clean all && rm -rf /var/cache/dnf
# /etc/vimrc'nin kurulum anındaki hâli. Lab 009 setup'ı bu dosyayı bozuyor ve
# her koşuda önce buradan geri yüklüyor. `dnf reinstall` bu işi YAPAMAZ:
# /etc/vimrc paket içinde config (c) işaretli, rpm değiştirilmiş bir config
# dosyasının üzerine yazmaz, yenisini .rpmnew olarak bırakır — setup ikinci
# kez koşturulduğunda bozma satırı ikinci kez eklenirdi. -p ile mtime de
# korunuyor, böylece geri yükleme sonrası rpm -V tertemiz dönüyor.
RUN cp -p /etc/vimrc /opt/lab-assets/vimrc.pristine
COPY --from=debbuilder /build/ogrenci-arac_1.0_all.deb /opt/lab-assets/

# Lab 012 varlıkları. Yayıncı GPG anahtar çifti BUILD sırasında üretilir, iki
# paket imzalanır, sonra GİZLİ ANAHTAR SİLİNİR — image'da yalnız açık anahtar,
# iki arşiv ve iki imza kalır. Öğrenci gizli anahtara ulaşamaz, imzayı yeniden
# üretemez; tek geçerli yol doğru açık anahtarı içe aktarıp doğrulamaktır.
#
# surum-b imzalandıktan SONRA yeniden üretilir: dosya hâlâ geçerli bir .tar.gz
# ama içeriği imzanın atıldığı andaki bayt dizisi değil, bu yüzden gpg --verify
# BAD signature verir. Kurcalanmış paketin gerçek karşılığı budur.
#
# Build sırasında iki doğrulama yapılır (a geçmeli, b geçmemeli); biri tutmazsa
# build çöker ve bozuk varlık image'a girmez.
RUN set -eux; \
    export GNUPGHOME=/tmp/labgpg; \
    mkdir -m 0700 -p "$GNUPGHOME"; \
    mkdir -p /opt/lab-assets/paket /tmp/pkgsrc/surum-a /tmp/pkgsrc/surum-b; \
    gpg --batch --pinentry-mode loopback --passphrase '' \
        --quick-generate-key 'Lab Yayinci <yayinci@lab.local>' default default never; \
    printf 'surum a govdesi\n' > /tmp/pkgsrc/surum-a/icerik.txt; \
    printf 'surum b govdesi\n' > /tmp/pkgsrc/surum-b/icerik.txt; \
    tar czf /opt/lab-assets/paket/surum-a.tar.gz -C /tmp/pkgsrc surum-a; \
    tar czf /opt/lab-assets/paket/surum-b.tar.gz -C /tmp/pkgsrc surum-b; \
    gpg --batch --yes --detach-sign \
        -o /opt/lab-assets/paket/surum-a.tar.gz.sig \
        /opt/lab-assets/paket/surum-a.tar.gz; \
    gpg --batch --yes --detach-sign \
        -o /opt/lab-assets/paket/surum-b.tar.gz.sig \
        /opt/lab-assets/paket/surum-b.tar.gz; \
    printf 'arka kapi\n' >> /tmp/pkgsrc/surum-b/icerik.txt; \
    tar czf /opt/lab-assets/paket/surum-b.tar.gz -C /tmp/pkgsrc surum-b; \
    gpg --batch --yes --armor --export 'yayinci@lab.local' \
        > /opt/lab-assets/paket/yayinci-acik.asc; \
    gpg --batch --verify /opt/lab-assets/paket/surum-a.tar.gz.sig \
        /opt/lab-assets/paket/surum-a.tar.gz; \
    ! gpg --batch --verify /opt/lab-assets/paket/surum-b.tar.gz.sig \
        /opt/lab-assets/paket/surum-b.tar.gz; \
    gpgconf --kill all || true; \
    rm -rf "$GNUPGHOME" /tmp/pkgsrc; \
    chmod 0644 /opt/lab-assets/paket/*

# Saat dilimi host ile aynı olmalı: exitlog ve history damgaları debrief'in
# ham verisi, UTC ile host arasındaki 3 saatlik kayma onları okunmaz yapıyordu.
# /etc/localtime asıl düzeltme — `su - student` login shell'i ortamı sıfırlar,
# ENV TZ'ye güvenilmez. ENV ikinci katman güvence.
RUN ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
ENV TZ=Europe/Istanbul

# Ev dizini izni bilinçli olarak RHEL'in kendi varsayılanına (0700) sabitlenir.
# Ubuntu 0755 veriyordu. RHCSA hedefi RHEL'in gerçek davranışını öğretmeyi
# gerektiriyor; ayrıca 001-005'in hiçbir check.sh'ı /home mode'una bakmıyor
# (yalnız sahiplik), yani regresyon riski yok. Varsayılana bırakılmıyor,
# açıkça yazılıyor ki image'ın davranışı upstream değişikliğine bağlı kalmasın.
RUN sed -i '/^[[:space:]]*HOME_MODE/d' /etc/login.defs && \
    printf 'HOME_MODE\t0700\n' >> /etc/login.defs

# ubuntu:24.04'ten farklı olarak Rocky'de uid 1000'i tutan varsayılan
# kullanıcı yok — silmeye gerek kalmadan student'ı doğrudan açıyoruz.
RUN useradd -m -s /bin/bash -u 1000 student && \
    echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student && \
    chmod 440 /etc/sudoers.d/student

# Oturum kaydı. `history` builtin yalnız o shell'in belleğini okur; container
# silinince ~/.bash_history hiç yazılmadan kaybolur ve debrief verisi gider.
# Çözüm: her prompt'ta diske yaz, o dizini host'a mount et (labctl yapar).
# exitlog her komutun çıkış kodunu tutar → "hangi komut hata verdi" tahmine
# değil kayda dayanır.
RUN mkdir -p /session && chown student:student /session
# NOT: blokta hiç `$` yazılmaz — Dockerfile parser'ı RUN satırındaki `$`'ı
# build değişkeni sanıp yer değiştirir, `\$` ise dosyaya ters bölü ile düşer.
# Bu yüzden `@` yer tutucusu kullanılıp sonunda tr ile `$`'a çevriliyor.
RUN { printf '%s\n' \
        '' \
        '# --- oturum kaydi (debrief icin) ---' \
        'export HISTFILE=/session/history' \
        'export HISTSIZE=100000' \
        'export HISTFILESIZE=100000' \
        'export HISTTIMEFORMAT='\''%F %T  '\''' \
        'shopt -s histappend' \
        'PROMPT_COMMAND='\''__e=@?; history -a; printf "%d\t%s\n" "@__e" "@(history 1)" >> /session/exitlog'\''' \
      | tr '@' '$' ; } >> /home/student/.bashrc && \
    chown student:student /home/student/.bashrc

CMD ["sleep", "infinity"]
