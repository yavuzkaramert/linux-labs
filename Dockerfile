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
RUN dnf -y --allowerasing install \
        man-db man-pages \
        sudo vim-enhanced less which hostname tree file \
        procps-ng psmisc util-linux findutils diffutils \
        coreutils grep sed gawk \
        passwd shadow-utils \
        tar gzip bzip2 xz cronie \
        iproute bind-utils curl \
        glibc-langpack-en \
    && dnf -y reinstall '*' \
    && mandb -q \
    && dnf clean all \
    && rm -rf /var/cache/dnf

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
