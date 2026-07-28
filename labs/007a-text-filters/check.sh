#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1.
#
# Beklenen değerlerin HİÇBİRİ sabit yazılmaz; hepsi /srv/.orig altındaki
# orijinal kopyalardan türetilir. Veri değişirse check kendini uyarlar.
set -u

DATA=/srv/data
ORIG=/srv/.orig
ANS=/home/student/cevaplar

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Dosyanın satır sayısı (son satır newline ile bitmese de sayar).
nlines() { awk 'END {print NR + 0}' "$1"; }

# Tek satırlık dosyanın değerini boşluklar kırpılmış olarak döker.
# Dosya yoksa ya da birden fazla satırsa hiçbir şey basmaz, 1 döner.
one_value() {
    [ -f "$1" ] || return 1
    [ "$(nlines "$1")" -eq 1 ] || return 1
    tr -d '\n' < "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# --- Referans degerler (veriden turetilir) --------------------------------
REF_COUNT="$(tail -n +2 "$ORIG/tickets.csv" | wc -l | tr -d ' ')"

awk -F';' 'NR > 1 && $4 == "open"' "$ORIG/tickets.csv" > "$TMP/exp-acik"

# Tuzak biletler: durumu open DEĞİL ama konu alanında open geçen kayıtlar.
# Satır-temelli `grep open` bunları da alır; doğru cevap almamalı.
awk -F';' 'NR > 1 && $4 != "open" && $6 ~ /open/ {print $1}' \
    "$ORIG/tickets.csv" > "$TMP/trap-ids"

tail -n +2 "$ORIG/tickets.csv" | cut -d';' -f3 | sort | uniq -c |
    awk '{print $1, $2}' | sort > "$TMP/exp-oncelik"
REF_PRIO_LINES="$(nlines "$TMP/exp-oncelik")"

# notlar.txt'nin beklenen son hâli: ^TODO satırları silinmiş, sunucu1'in
# HER geçişi web01 olmuş. Taze ortamda dosya düzenlenmemiş olduğu için
# bu karşılaştırma FAIL verir — kriter bedava değildir.
sed '/^TODO/d; s/sunucu1/web01/g' "$ORIG/notlar.txt" > "$TMP/exp-notlar"
REF_SUNUCU1_HITS="$(grep -o 'sunucu1' "$ORIG/notlar.txt" | wc -l | tr -d ' ')"

# --- 1. 01-adet.txt tek satir ve yalnız sayı ------------------------------
r=""
if [ ! -f "$ANS/01-adet.txt" ]; then
    r="$ANS/01-adet.txt yok"
elif ! v="$(one_value "$ANS/01-adet.txt")"; then
    r="01-adet.txt tek satır değil ($(nlines "$ANS/01-adet.txt") satır)"
elif ! printf '%s' "$v" | grep -qx '[0-9]\+'; then
    r="01-adet.txt yalnız sayı içermiyor: '$v'"
fi
[ -z "$r" ] && ok "01-adet.txt tek satır ve yalnız sayı içeriyor" || bad "$r"

# --- 2. 01-adet.txt sayisi baslik haric veri satiri sayisina esit --------
r=""
if ! v="$(one_value "$ANS/01-adet.txt" 2>/dev/null)"; then
    r="01-adet.txt okunamadı, sayı karşılaştırılamıyor"
elif [ "$v" != "$REF_COUNT" ]; then
    r="01-adet.txt: $v yazılmış, doğrusu $REF_COUNT (başlık satırı sayılmaz)"
fi
[ -z "$r" ] && ok "01-adet.txt'deki sayı veri satırı sayısına eşit ($REF_COUNT)" ||
    bad "$r"

# --- 3. 02-acik.txt yalnız durumu open olan satirlari iceriyor -----------
# Sıra bu kriterin konusu değil (o 5. kriter) → iki taraf da sıralanır.
r=""
if [ ! -f "$ANS/02-acik.txt" ]; then
    r="$ANS/02-acik.txt yok"
else
    sort "$TMP/exp-acik"      > "$TMP/s-exp"
    sort "$ANS/02-acik.txt"   > "$TMP/s-got"
    if ! cmp -s "$TMP/s-exp" "$TMP/s-got"; then
        e="$(nlines "$TMP/exp-acik")"; g="$(nlines "$ANS/02-acik.txt")"
        r="02-acik.txt satır kümesi yanlış (beklenen $e, gelen $g satır)"
    fi
fi
[ -z "$r" ] && ok "02-acik.txt yalnız durumu open olan satırları içeriyor" ||
    bad "$r"

# --- 4. 02-acik.txt konu alaninda open gecen kapali bileti icermiyor ----
r=""
if [ ! -f "$ANS/02-acik.txt" ]; then
    r="$ANS/02-acik.txt yok, tuzak kontrolü yapılamıyor"
else
    found=""
    while read -r tid; do
        [ -n "$tid" ] || continue
        if cut -d';' -f1 "$ANS/02-acik.txt" | grep -qx "$tid"; then
            found="${found:+$found }$tid"
        fi
    done < "$TMP/trap-ids"
    [ -z "$found" ] || r="02-acik.txt tuzak bilet(ler) içeriyor: $found"
fi
[ -z "$r" ] && ok "02-acik.txt konu alanında open geçen kapalı bileti içermiyor" ||
    bad "$r"

# --- 5. 02-acik.txt satir sirasi kaynaktakiyle ayni ---------------------
r=""
if [ ! -f "$ANS/02-acik.txt" ]; then
    r="$ANS/02-acik.txt yok, sıra kontrolü yapılamıyor"
elif ! cmp -s "$TMP/exp-acik" "$ANS/02-acik.txt"; then
    r="02-acik.txt kaynak dosyayla birebir aynı değil (içerik ya da sıra)"
fi
[ -z "$r" ] && ok "02-acik.txt satır sırası kaynak dosyayla aynı" || bad "$r"

# --- 6. 03-oncelik.txt her oncelik icin tek satir -----------------------
r=""
if [ ! -f "$ANS/03-oncelik.txt" ]; then
    r="$ANS/03-oncelik.txt yok"
else
    awk '{print $1, $2}' "$ANS/03-oncelik.txt" | sort > "$TMP/s-prio"
    got="$(nlines "$TMP/s-prio")"
    if [ "$got" -ne "$REF_PRIO_LINES" ]; then
        r="03-oncelik.txt $got satır, öncelik sayısı $REF_PRIO_LINES"
    elif ! cut -d' ' -f2 "$TMP/s-prio" | sort -u |
            cmp -s - <(cut -d' ' -f2 "$TMP/exp-oncelik" | sort -u); then
        r="03-oncelik.txt öncelik adları beklenenle örtüşmüyor"
    elif ! awk 'NF != 2 || $1 !~ /^[0-9]+$/ {exit 1}' "$TMP/s-prio"; then
        r="03-oncelik.txt biçimi bozuk (her satır: sayı boşluk öncelik)"
    fi
fi
[ -z "$r" ] && ok "03-oncelik.txt her öncelik için tek satır içeriyor" || bad "$r"

# --- 7. 03-oncelik.txt sayilari gercek dagilima esit --------------------
r=""
if [ ! -f "$ANS/03-oncelik.txt" ]; then
    r="$ANS/03-oncelik.txt yok, dağılım karşılaştırılamıyor"
else
    awk '{print $1, $2}' "$ANS/03-oncelik.txt" | sort > "$TMP/s-prio"
    if ! cmp -s "$TMP/exp-oncelik" "$TMP/s-prio"; then
        r="03-oncelik.txt sayıları gerçek dağılımla uyuşmuyor (beklenen: $(
            tr '\n' ' ' < "$TMP/exp-oncelik"))"
    fi
fi
[ -z "$r" ] && ok "03-oncelik.txt sayıları gerçek dağılıma eşit" || bad "$r"

# --- 8. 04-kod.txt tek satir ve degeri 0 --------------------------------
r=""
if [ ! -f "$ANS/04-kod.txt" ]; then
    r="$ANS/04-kod.txt yok"
elif ! v="$(one_value "$ANS/04-kod.txt")"; then
    r="04-kod.txt tek satır değil ($(nlines "$ANS/04-kod.txt") satır)"
elif [ "$v" != "0" ]; then
    r="04-kod.txt içeriği '$v', beklenen 0 (DENIED dosyada geçiyor)"
fi
[ -z "$r" ] && ok "04-kod.txt tek satır ve değeri 0" || bad "$r"

# --- 9. 05-kod.txt tek satir ve degeri 1 --------------------------------
r=""
if [ ! -f "$ANS/05-kod.txt" ]; then
    r="$ANS/05-kod.txt yok"
elif ! v="$(one_value "$ANS/05-kod.txt")"; then
    r="05-kod.txt tek satır değil ($(nlines "$ANS/05-kod.txt") satır)"
elif [ "$v" != "1" ]; then
    r="05-kod.txt içeriği '$v', beklenen 1 (kelime dosyada geçmiyor)"
fi
[ -z "$r" ] && ok "05-kod.txt tek satır ve değeri 1" || bad "$r"

# --- 10. notlar.txt icinde ^TODO kalmamis -------------------------------
r=""
if [ ! -f "$DATA/notlar.txt" ]; then
    r="$DATA/notlar.txt yok"
else
    n="$(grep -c '^TODO' "$DATA/notlar.txt" || true)"
    [ "$n" -eq 0 ] || r="notlar.txt içinde TODO ile başlayan $n satır duruyor"
fi
[ -z "$r" ] && ok "notlar.txt içinde TODO ile başlayan satır kalmamış" || bad "$r"

# --- 11. sunucu1 gitmis, karsiliklari web01 olmus -----------------------
# web01 sayısı orijinaldeki sunucu1 GEÇİŞ sayısına eşit olmalı; satır
# sayısına değil. Bir satırda iki kez geçtiği için eksik `g` bayrağı
# buradan yakalanır.
r=""
if [ ! -f "$DATA/notlar.txt" ]; then
    r="$DATA/notlar.txt yok"
else
    left="$(grep -c 'sunucu1' "$DATA/notlar.txt" || true)"
    hits="$(grep -o 'web01' "$DATA/notlar.txt" | wc -l | tr -d ' ')"
    if [ "$left" -ne 0 ]; then
        r="notlar.txt içinde sunucu1 geçen $left satır duruyor"
    elif [ "$hits" -ne "$REF_SUNUCU1_HITS" ]; then
        r="web01 $hits kez geçiyor, beklenen $REF_SUNUCU1_HITS (satır içindeki ikinci eşleşme kaçmış olabilir)"
    fi
fi
[ -z "$r" ] && ok "notlar.txt'de sunucu1 geçmiyor, $REF_SUNUCU1_HITS geçişin hepsi web01" ||
    bad "$r"

# --- 12. notlar.txt'nin diger satirlari ve sirasi degismemis ------------
r=""
if [ ! -f "$DATA/notlar.txt" ]; then
    r="$DATA/notlar.txt yok"
elif ! cmp -s "$TMP/exp-notlar" "$DATA/notlar.txt"; then
    e="$(nlines "$TMP/exp-notlar")"; g="$(nlines "$DATA/notlar.txt")"
    r="notlar.txt beklenen son hâlle birebir aynı değil (beklenen $e, gelen $g satır) — fazla silinmiş, sıra değişmiş ya da düzenleme eksik"
fi
[ -z "$r" ] && ok "notlar.txt'nin diğer satırları ve sırası değişmemiş" || bad "$r"

# --- 13. Salt okunur veri dosyalari degismemis (korkuluk) --------------
# Bu kriter taze ortamda doğal olarak sağlanır; kasıtlı bir istisnadır.
# Amacı ödül değil, yan hasarı yakalamak: veri dosyasını düzenleyip
# cevabı kolaylaştıran çözümü reddeder.
r=""
for f in tickets.csv access.log; do
    if [ ! -f "$DATA/$f" ]; then
        r="${r:+$r; }$f silinmiş"
    elif ! cmp -s "$ORIG/$f" "$DATA/$f"; then
        r="${r:+$r; }$f değiştirilmiş"
    fi
done
[ -z "$r" ] && ok "tickets.csv ve access.log değiştirilmemiş" || bad "$r"

exit "$FAIL"
