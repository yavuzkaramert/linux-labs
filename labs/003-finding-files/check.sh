#!/usr/bin/env bash
# Container içinde root olarak çalışır. Her kriter için bir [OK]/[FAIL] satırı.
set -u

FAIL=0
D=/srv/data

ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

# --- 1. Eski loglar arşivde, yeniler yerinde ---
r=""
if [ ! -d "$D/archive" ]; then
    r="$D/archive dizini yok"
else
    stray="$(find "$D" -path "$D/archive" -prune -o -type f -name '*.log' -mtime +30 -print 2>/dev/null | head -1)"
    if [ -n "$stray" ]; then
        r="30 günden eski log hâlâ arşiv dışında: $stray"
    fi
    if [ -z "$r" ]; then
        for f in app-2026-04.log access-old.log old-backup.log; do
            if [ -z "$(find "$D/archive" -type f -name "$f" 2>/dev/null | head -1)" ]; then
                r="$f arşive taşınmalıydı (silinmiş olmasın!)"; break
            fi
        done
    fi
    if [ -z "$r" ] && [ ! -f "$D/app/logs/app-current.log" ]; then
        r="yeni log app-current.log yerinde durmalıydı"
    fi
    if [ -z "$r" ] && [ ! -f "$D/web/logs/nginx/access.log" ]; then
        r="yeni log access.log yerinde durmalıydı"
    fi
    if [ -z "$r" ] && [ -n "$(find "$D/archive" -name 'app-current.log' -o -name 'access.log' 2>/dev/null | head -1)" ]; then
        r="30 günden yeni loglar arşive girmemeliydi"
    fi
fi
if [ -z "$r" ]; then
    ok "eski .log dosyaları arşivde, yeniler yerinde"
else
    bad "$r"
fi

# --- 2. Sıfır byte dosya kalmadı; dolu dosyalar ve boş dizinler yerinde ---
r=""
empty="$(find "$D" -type f -empty 2>/dev/null | head -1)"
if [ -n "$empty" ]; then
    r="hâlâ 0 byte dosya var: $empty"
elif [ ! -s "$D/app/cache.dat" ]; then
    r="dolu dosya cache.dat silinmemeliydi"
elif [ ! -s "$D/db/dumps/dump-good.sql" ]; then
    r="dolu dosya dump-good.sql silinmemeliydi"
elif [ ! -d "$D/app/spool" ]; then
    r="boş dizin $D/app/spool silinmemeliydi"
fi
if [ -z "$r" ]; then
    ok "0 byte dosyalar temiz; dolu dosyalar ve boş dizinler yerinde"
else
    bad "$r"
fi

# --- 3. tmp'deki >1MB dosyalar big/ altında, küçükler tmp'de ---
r=""
if [ ! -d "$D/big" ]; then
    r="$D/big dizini yok"
else
    left="$(find "$D/tmp" -maxdepth 1 -type f -size +1M 2>/dev/null | head -1)"
    if [ -n "$left" ]; then
        r="1 MB'den büyük dosya hâlâ tmp içinde: $left"
    fi
    for f in big-dump.bin video-frag.mp4; do
        if [ -z "$r" ] && [ -z "$(find "$D/big" -maxdepth 1 -type f -name "$f" -size +1M 2>/dev/null | head -1)" ]; then
            r="$f big/ altına taşınmalıydı"
        fi
    done
    for f in session-01.dat session-02.dat; do
        if [ -z "$r" ] && [ ! -f "$D/tmp/$f" ]; then
            r="küçük dosya $f tmp içinde kalmalıydı"
        fi
    done
fi
if [ -z "$r" ]; then
    ok "büyük dosyalar big/ altında, küçükler tmp'de"
else
    bad "$r"
fi

# --- 4. backup/config: mod, sahip:grup, mtime ve içerik birebir aynı ---
r=""
if [ ! -d "$D/backup/config" ]; then
    r="$D/backup/config dizini yok"
else
    while IFS= read -r f; do
        rel="${f#"$D"/config/}"
        b="$D/backup/config/$rel"
        if [ ! -f "$b" ]; then
            r="kopyada eksik dosya: $rel"; break
        fi
        if [ "$(stat -c '%a %U:%G %Y' "$f")" != "$(stat -c '%a %U:%G %Y' "$b")" ]; then
            r="$rel metadata farklı (izin/sahip/mtime korunmalı — orijinal: $(stat -c '%a %U:%G' "$f"), kopya: $(stat -c '%a %U:%G' "$b"))"
            break
        fi
        if ! cmp -s "$f" "$b"; then
            r="$rel içeriği orijinalden farklı"; break
        fi
    done < <(find "$D/config" -type f)
fi
if [ -z "$r" ]; then
    ok "backup/config metadata ve içerik olarak birebir kopya"
else
    bad "$r"
fi

# --- 5. reports/latest: en yeni .csv'ye giden sembolik link ---
r=""
latest="$D/reports/latest"
newest="$(find "$D/reports" -maxdepth 1 -type f -name '*.csv' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
if [ ! -L "$latest" ]; then
    r="$latest bir sembolik link olmalı (kopya değil)"
elif [ -z "$newest" ]; then
    r="reports/ içinde hiç .csv kalmamış"
elif [ "$(readlink -f "$latest")" != "$(readlink -f "$newest")" ]; then
    r="latest en yeni csv'yi göstermeli ($(basename "$newest")), şu an: $(readlink "$latest")"
fi
if [ -z "$r" ]; then
    ok "reports/latest en yeni csv'ye işaret eden sembolik link"
else
    bad "$r"
fi

# --- 6. Tüm .sh'ler student tarafından çalışıyor; .sh olmayanlar çalışmıyor ---
r=""
found=0
while IFS= read -r s; do
    found=1
    if ! su - student -c "$s" >/dev/null 2>&1; then
        r="student şu script'i çalıştıramıyor: $s"; break
    fi
done < <(find "$D/scripts" -type f -name '*.sh')
if [ -z "$r" ] && [ "$found" -eq 0 ]; then
    r="scripts/ altında hiç .sh bulunamadı"
fi
if [ -z "$r" ]; then
    badx="$(find "$D/scripts" -type f ! -name '*.sh' -perm /111 2>/dev/null | head -1)"
    if [ -n "$badx" ]; then
        r=".sh olmayan dosyada çalıştırma izni olmamalı: $badx"
    fi
fi
if [ -z "$r" ]; then
    ok "tüm .sh'ler student ile çalışıyor; diğer dosyalarda x izni yok"
else
    bad "$r"
fi

exit "$FAIL"
