#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Lab 006'nın bozuk durumunu kurar. Idempotent.
#
# Bu lab hem DOSYA hem CANLI SÜREÇ üzerinde çalışır:
#  * Üç sahte servis süreci arka planda yaşar; dördüncüsü (labapp-queue)
#    bilerek başlatılmaz → DEGRADED yolu.
#  * İşaret SÜREÇ ADINDA (comm) taşınır: gerçek `sleep` binary'si servis
#    adıyla kopyalanıp çalıştırılır. Böylece sade `pgrep labapp-web` bulur.
#    Sarmalayıcı script kullanılmaz; öyle olsaydı comm "bash" olur, tek yol
#    `pgrep -f` kalırdı ve o da svccheck'in kendi komut satırını eşleştirip
#    labın zorluğunu kapsam dışına taşırdı.
#  * setup başında eski servis süreçleri comm ile öldürülür (`pkill -x`);
#    setup.sh'ın kendi comm'u "bash" olduğu için self-kill riski yok.
set -euo pipefail

LOGDIR=/var/log/labapp
PROCDIR=/usr/local/lib/labprocs
LABSDIR=/etc/labs
REPORTS=/srv/reports
BINDIR=/usr/local/bin
STUDENT=student

SERVICES="labapp-web labapp-worker labapp-cache"

# --- 0. Önceki koşudan kalan sahte süreçleri temizle -------------------------
# -x = tam comm eşleşmesi. Bu setup'ın kendi comm'u "bash", eşleşmez.
for svc in $SERVICES labapp-queue; do
    pkill -9 -x "$svc" 2>/dev/null || true
done
sleep 1
rm -rf "$PROCDIR"

# --- 1. Log dosyası ----------------------------------------------------------
# Sayımlar bilerek FARKLI: INFO 17, WARN 9, ERROR 6, DEBUG 8.
# TUZAK: 5 satırın MESAJ GÖVDESİNDE bir seviye adı geçiyor. `grep -c ERROR`
# gibi alan-farkındalığı olmayan bir çözüm 6 yerine 9 sayar → kriter düşer.
# İçerik sabit (heredoc); debrief tekrarlanabilir olmalı.
mkdir -p "$LOGDIR"
chown root:root "$LOGDIR"
chmod 0755 "$LOGDIR"

cat > "$LOGDIR/app.log" <<'EOF'
2026-07-27T03:00:01|INFO|service labapp-web started
2026-07-27T03:00:03|DEBUG|WARN threshold set to 90
2026-07-27T03:00:04|INFO|worker pool size 8
2026-07-27T03:00:07|WARN|response time above 200ms
2026-07-27T03:00:09|INFO|retrying after ERROR from upstream
2026-07-27T03:00:12|ERROR|disk almost full
2026-07-27T03:00:15|INFO|cache warm up finished
2026-07-27T03:00:18|WARN|DEBUG logging enabled for module cache
2026-07-27T03:00:22|INFO|request 8812 served in 41ms
2026-07-27T03:00:25|DEBUG|entering handler dispatch
2026-07-27T03:00:29|WARN|connection pool at 80 percent
2026-07-27T03:00:31|INFO|ERROR budget for the day is 25
2026-07-27T03:00:34|ERROR|upstream timeout after 5s
2026-07-27T03:00:36|DEBUG|cache key user:4471
2026-07-27T03:00:38|INFO|session store connected
2026-07-27T03:00:41|WARN|retry count 2 for request 8813
2026-07-27T03:00:45|INFO|request 8813 served in 37ms
2026-07-27T03:00:49|ERROR|INFO channel backlog exceeded
2026-07-27T03:00:52|INFO|config reloaded from disk
2026-07-27T03:00:55|DEBUG|gc pause 12ms
2026-07-27T03:00:57|WARN|disk usage 78 percent
2026-07-27T03:01:03|INFO|request 8814 served in 52ms
2026-07-27T03:01:07|ERROR|failed to write session 4471
2026-07-27T03:01:11|INFO|queue depth 3
2026-07-27T03:01:14|WARN|slow query 1.4s on table events
2026-07-27T03:01:19|INFO|request 8815 served in 44ms
2026-07-27T03:01:22|DEBUG|socket buffer 64k
2026-07-27T03:01:27|INFO|healthcheck passed
2026-07-27T03:01:30|WARN|cache miss ratio 0.42
2026-07-27T03:01:35|INFO|request 8816 served in 39ms
2026-07-27T03:01:38|DEBUG|ERROR handler registered
2026-07-27T03:01:40|ERROR|labapp-queue not responding
2026-07-27T03:01:44|INFO|metrics flushed
2026-07-27T03:01:47|WARN|worker restart requested
2026-07-27T03:01:52|INFO|request 8817 served in 48ms
2026-07-27T03:01:55|DEBUG|thread 7 idle
2026-07-27T03:02:01|INFO|nightly rotation scheduled
2026-07-27T03:02:05|WARN|clock drift 40ms
2026-07-27T03:02:09|ERROR|report generation aborted
2026-07-27T03:02:12|DEBUG|flush interval 30s
EOF
chown root:root "$LOGDIR/app.log"
chmod 0644 "$LOGDIR/app.log"

# --- 2. Okunamayan log -------------------------------------------------------
# `[ -f ]` ile `[ -r ]` farkını zorlayan TEK nokta. Silme.
cat > "$LOGDIR/secure.log" <<'EOF'
2026-07-27T02:59:00|INFO|audit channel opened
2026-07-27T02:59:30|WARN|root login from console
EOF
chown root:root "$LOGDIR/secure.log"
chmod 0600 "$LOGDIR/secure.log"

# --- 3. Bozuk logsum ---------------------------------------------------------
# Taşıdığı kusurlar (hepsi ayrı kriter kırar): shebang yok · çalıştırma izni
# yok · $1 yok sayılıyor · varsayılan (boşluk) alan ayırıcısı · çıktı biçimi
# SEVIYE:sayı değil · hata mesajı stdout'a gidiyor · kontrol iş bittikten
# SONRA yapılıyor · -r kontrolü hiç yok · her yolda exit 0.
cat > "$BINDIR/logsum" <<'EOF'
# gece raporu icin log ozeti - devam edilecek
LOG=/var/log/labapp/app.log
awk '{print $2}' $LOG | sort | uniq -c
if [ ! -f "$LOG" ]; then
  echo "logsum: dosya yok"
fi
exit 0
EOF
chown root:root "$BINDIR/logsum"
chmod 0666 "$BINDIR/logsum"

# --- 4. Yazılmamış scriptler -------------------------------------------------
rm -f "$BINDIR/svccheck" "$BINDIR/report"

# --- 5. Servis süreçleri -----------------------------------------------------
# labapp-queue BİLEREK yok: services.list'te var, süreci yok → [FAIL] → DEGRADED.
# Gerçek `sleep` binary'si servis adıyla kopyalanır → comm = servis adı.
# comm 15 karaktere kırpılır; en uzun ad labapp-worker (13) — sığıyor.
# labapp-web ile labapp-worker birbirinin alt dizgisi değil → çapraz eşleşme yok.
install -d -m 755 "$PROCDIR"
for svc in $SERVICES; do
    cp -f /usr/bin/sleep "$PROCDIR/$svc"
    chown root:root "$PROCDIR/$svc"
    chmod 0755 "$PROCDIR/$svc"
done

# setsid → yeni oturum, denetim terminali yok → setup bitince SIGHUP gelmez.
# `infinity` → süreç container ömrü boyunca uyur, CPU yakmaz.
for svc in $SERVICES; do
    su "$STUDENT" -s /bin/bash -c \
      "setsid nohup $PROCDIR/$svc infinity >/dev/null 2>&1 </dev/null &"
done

sleep 1

# --- 6. Servis listesi -------------------------------------------------------
# Boş satır, yorum satırı ve yorumlanmış servis-benzeri satır bilerek var.
# labapp-legacy süreci YOK; yorum atlanmazsa fazladan bir [FAIL] üretir.
mkdir -p "$LABSDIR"
chown root:root "$LABSDIR"
chmod 0755 "$LABSDIR"

cat > "$LABSDIR/services.list" <<'EOF'
# gece raporunda izlenen servisler
labapp-web
labapp-worker

labapp-queue
#labapp-legacy
labapp-cache
EOF
chown root:root "$LABSDIR/services.list"
chmod 0644 "$LABSDIR/services.list"

# --- 7. Çıktı dizini ---------------------------------------------------------
mkdir -p "$REPORTS"
chown "$STUDENT:$STUDENT" "$REPORTS"
chmod 0755 "$REPORTS"
rm -f "$REPORTS/daily.txt"

# --- 8. Kurulum doğrulaması --------------------------------------------------
for svc in $SERVICES; do
    if ! pgrep -x "$svc" >/dev/null 2>&1; then
        echo "setup HATA: $svc sureci baslatilamadi (comm eslesmesi yok)" >&2
        exit 1
    fi
done
if pgrep -x labapp-queue >/dev/null 2>&1; then
    echo "setup HATA: labapp-queue calisiyor — calismamaliydi" >&2
    exit 1
fi
N="$(ps -eo comm | grep -c '^labapp-' || true)"
if [ "$N" -ne 3 ]; then
    echo "setup HATA: comm alaninda 3 labapp-* sureci bekleniyordu, $N bulundu" >&2
    exit 1
fi

echo "setup done"
