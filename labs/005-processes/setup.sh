#!/usr/bin/env bash
# Root olarak çalışır. Lab 005'in bozuk durumunu kurar. Idempotent.
#
# DİKKAT — bu lab dosya değil CANLI SÜREÇ üzerinde çalışır:
#  * Sahte süreçler setsid + nohup ile başlatılır; setup bittikten sonra da
#    yaşamaya devam ederler.
#  * Süreçler `student` kullanıcısına aittir → student sudo'suz sinyalleyebilir.
#  * Her sürecin komut satırında ayırt edici bir LABPROC-* işareti vardır;
#    check.sh süreçleri PID ile değil bu işaretle bulur.
#  * Setup başında eski işaretli süreçler öldürülür → `labctl reset 005`
#    çağrıldığında kalıntı süreç birikmez.
set -euo pipefail

PROCDIR=/opt/lab-procs
REPORTS=/srv/reports
STUDENT=student

# --- 0. Önceki koşudan kalan sahte süreçleri temizle -------------------------
pkill -9 -f 'LABPROC'            2>/dev/null || true
pkill -9 -f "$PROCDIR"           2>/dev/null || true
pkill -9 -f 'nightly-batch-runner' 2>/dev/null || true
sleep 1

rm -rf "$PROCDIR" "$REPORTS"
mkdir -p "$PROCDIR" "$REPORTS"
chown "$STUDENT:$STUDENT" "$REPORTS"
chmod 755 "$REPORTS"

# --- 1. Süreç gövdeleri ------------------------------------------------------
# İşaret ($1) bilerek kullanılmaz; tek amacı komut satırında görünmek.

# hog: CPU'yu boşuna meşgul eden takılmış süreç. Sinyal yakalamaz → TERM öldürür.
cat > "$PROCDIR/hog.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = LABPROC isareti (komut satirinda gorunmesi icin)
while :; do
    i=0
    while [ "$i" -lt 40000 ]; do i=$((i + 1)); done
    sleep 0.2
done
EOF

# rogue: TERM'i trap ile YOK SAYAR. Öğrenci kibar sinyalin yetmediğini yaşar,
# KILL'e geçmek zorunda kalır. Negatif ders tam olarak budur.
cat > "$PROCDIR/rogue.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = LABPROC isareti. TERM yok sayilir; sadece KILL bu sureci bitirir.
trap '' TERM
trap '' INT
trap '' HUP
while :; do
    sleep 5
done
EOF

# batch: gece batch işi. Çok düşük nice ile başlar, öldürülmemeli.
cat > "$PROCDIR/batch.sh" <<'EOF'
#!/usr/bin/env bash
# $1 = LABPROC isareti
while :; do
    sleep 5
done
EOF

# noise: LABPROC işareti YOK. İsmi batch'e benziyor → yanlış hedef tuzağı.
cat > "$PROCDIR/noise.sh" <<'EOF'
#!/usr/bin/env bash
while :; do
    sleep 7
done
EOF

chmod 755 "$PROCDIR"/*.sh
chown root:root "$PROCDIR"/*.sh

# --- 2. Sahte süreçleri student adına, kalıcı olarak başlat ------------------
# setsid → yeni oturum, denetim terminali yok → setup/docker exec bitince
#          SIGHUP gelmez. nohup ikinci güvence.

# hog: nice 19 ile başlar (container'ı boğmasın); kriter nice'ına bakmaz.
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup nice -n 19 bash $PROCDIR/hog.sh LABPROC-hog >/dev/null 2>&1 </dev/null &"

# rogue: exec -a ile sahte bir çekirdek-thread ismi takar; işaret argümanda kalır.
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash -c 'exec -a kworker/u8:3-events bash $PROCDIR/rogue.sh LABPROC-rogue' >/dev/null 2>&1 </dev/null &"

# batch: nice -n -15 root tarafından uygulanır, ardından yetki student'a düşer.
# Nice değeri fork/exec üzerinden miras kalır → süreç student'a ait ve nice -15.
# student nice'ı ARTIRABİLİR (düşüremez) — görev zaten artırmayı istiyor.
nice -n -15 su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/batch.sh LABPROC-batch >/dev/null 2>&1 </dev/null &"

# gürültü: LABPROC içermeyen sahte süreçler (yanlış süreci öldürme tuzağı).
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup bash $PROCDIR/noise.sh nightly-batch-runner >/dev/null 2>&1 </dev/null &"
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup sleep 4242 >/dev/null 2>&1 </dev/null &"
su "$STUDENT" -s /bin/bash -c \
  "setsid nohup sleep 4243 >/dev/null 2>&1 </dev/null &"

sleep 1

# --- 3. Kurulum doğrulaması: üç sürecin de ayakta olması şart ---------------
for mark in LABPROC-hog LABPROC-rogue LABPROC-batch; do
    if ! pgrep -f "$mark" >/dev/null 2>&1; then
        echo "setup HATA: $mark sureci baslatilamadi" >&2
        exit 1
    fi
done

echo "setup done"
