#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1.
#
# Bu bir TEKRAR labı: her satır hangi kaynak lab'dan geldiğini söyler.
# Biçim:  [OK]   Ticket 8.3 — açıklama (kaynak: lab 007b)
#
# Beklenen değerlerin hiçbiri sabit yazılmaz; hepsi /srv/.orig altındaki
# orijinal kopyalardan türetilir.
set -u

PROJE=/srv/proje
DESTEK="$PROJE/destek"
GUNLUKLER="$PROJE/gunlukler"
WORK="$PROJE/work"
CONF=/etc/proje
REPORTS=/srv/reports
ORIG=/srv/.orig
ANS=/home/student/cevaplar
MKREPORT=/usr/local/bin/mkreport

FAIL=0

# --- Çıktı biçimi ------------------------------------------------------------
# 104 kriterin hepsini tek tek basmak okunmuyor. Varsayılan kip GRUPLU:
# her ticket için bir başlık, altında YALNIZ düşen kriterler, sonda özet
# tablosu. Her kriter yine tek tek değerlendirilir (accumulator korunur);
# değişen sadece ne yazdırıldığı.
#
# Tüm [OK] satırlarını görmek için:
#   docker exec -e CHECK_VERBOSE=1 -u root lab-900-vardiya-01b bash /lab/check.sh
VERBOSE="${CHECK_VERBOSE:-0}"

SEC=""          # işlenen ticket'ın başlığı
SEC_OK=0        # o ticket'ta geçen kriter sayısı
SEC_N=0         # o ticket'ta değerlendirilen kriter sayısı
SUMMARY=""      # sonda basılacak özet satırları
TOT_OK=0
TOT_N=0

flush_section() {
    [ -n "$SEC" ] || return 0
    if [ "$SEC_OK" -eq "$SEC_N" ]; then
        printf '       hepsi geçti (%d/%d)\n' "$SEC_OK" "$SEC_N"
    fi
    # Sayı ÖNDE: Türkçe karakterler çok baytlı olduğu için sonda hizalamak
    # (printf %-52s bayt sayar) tabloyu kaydırıyor.
    SUMMARY="${SUMMARY}$(printf '  %3d/%-3d  %s' "$SEC_OK" "$SEC_N" "$SEC")
"
    TOT_OK=$((TOT_OK + SEC_OK))
    TOT_N=$((TOT_N + SEC_N))
}

section() {
    flush_section
    SEC="$1"; SEC_OK=0; SEC_N=0
    printf '\n=== %s %s\n' "$1" '==============================='
}

# ok() MUTLAKA 0 dönmeli: çağrı kalıbı `[ -z "$r" ] && ok ... || bad ...`,
# sıfırdan farklı dönerse aynı kriter için bad() de koşar.
ok()  { SEC_N=$((SEC_N + 1)); SEC_OK=$((SEC_OK + 1))
        [ "$VERBOSE" = "1" ] && echo "[OK]   $1"
        return 0; }
bad() { SEC_N=$((SEC_N + 1)); echo "[FAIL] $1"; FAIL=1; return 0; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

RC=0
nlines() { [ -f "$1" ] && awk 'END {print NR + 0}' "$1" || echo 0; }

# Tek satırlık dosyanın değerini boşluklar kırpılmış olarak döker.
one_value() {
    [ -f "$1" ] || return 1
    [ "$(nlines "$1")" -eq 1 ] || return 1
    tr -d '\n' < "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

# =============================================================================
# TICKET 7 — Destek bileti dökümü (kaynak: lab 007a, text filters)
# =============================================================================
section "Ticket 7  — Destek bileti dökümü (lab 007a)"

OD="$ORIG/destek"

REF_COUNT="$(tail -n +2 "$OD/biletler.csv" | wc -l | tr -d ' ')"
awk -F';' 'NR > 1 && $4 == "open"' "$OD/biletler.csv" > "$TMP/exp-acik"
# Tuzak biletler: durumu open DEĞİL ama konu alanında open geçen kayıtlar.
awk -F';' 'NR > 1 && $4 != "open" && $6 ~ /open/ {print $1}' \
    "$OD/biletler.csv" > "$TMP/trap-ids"
tail -n +2 "$OD/biletler.csv" | cut -d';' -f3 | sort | uniq -c |
    awk '{print $1, $2}' | sort > "$TMP/exp-oncelik"
REF_PRIO_LINES="$(nlines "$TMP/exp-oncelik")"
sed '/^TODO/d; s/sunucu1/web01/g' "$OD/notlar.txt" > "$TMP/exp-notlar"
REF_SUNUCU1_HITS="$(grep -o 'sunucu1' "$OD/notlar.txt" | wc -l | tr -d ' ')"

# --- 7.1 01-adet.txt tek satır ve yalnız sayı ---
r=""
if [ ! -f "$ANS/01-adet.txt" ]; then
    r="$ANS/01-adet.txt yok"
elif ! v="$(one_value "$ANS/01-adet.txt")"; then
    r="01-adet.txt tek satır değil ($(nlines "$ANS/01-adet.txt") satır)"
elif ! printf '%s' "$v" | grep -qx '[0-9]\+'; then
    r="01-adet.txt yalnız sayı içermiyor: '$v'"
fi
[ -z "$r" ] && ok "Ticket 7.1 — 01-adet.txt tek satır ve yalnız sayı içeriyor (kaynak: lab 007a)" \
             || bad "Ticket 7.1 — $r (kaynak: lab 007a)"

# --- 7.2 01-adet.txt sayısı başlık hariç veri satırı sayısına eşit ---
r=""
if ! v="$(one_value "$ANS/01-adet.txt" 2>/dev/null)"; then
    r="01-adet.txt okunamadı, sayı karşılaştırılamıyor"
elif [ "$v" != "$REF_COUNT" ]; then
    r="01-adet.txt: $v yazılmış, doğrusu $REF_COUNT (başlık satırı sayılmaz)"
fi
[ -z "$r" ] && ok "Ticket 7.2 — 01-adet.txt'deki sayı veri satırı sayısına eşit ($REF_COUNT) (kaynak: lab 007a)" \
             || bad "Ticket 7.2 — $r (kaynak: lab 007a)"

# --- 7.3 02-acik.txt yalnız durumu open olan satırları içeriyor ---
r=""
if [ ! -f "$ANS/02-acik.txt" ]; then
    r="$ANS/02-acik.txt yok"
else
    sort "$TMP/exp-acik"    > "$TMP/s-exp"
    sort "$ANS/02-acik.txt" > "$TMP/s-got"
    if ! cmp -s "$TMP/s-exp" "$TMP/s-got"; then
        e="$(nlines "$TMP/exp-acik")"; g="$(nlines "$ANS/02-acik.txt")"
        r="02-acik.txt satır kümesi yanlış (beklenen $e, gelen $g satır)"
    fi
fi
[ -z "$r" ] && ok "Ticket 7.3 — 02-acik.txt yalnız durumu open olan satırları içeriyor (kaynak: lab 007a)" \
             || bad "Ticket 7.3 — $r (kaynak: lab 007a)"

# --- 7.4 02-acik.txt konu alanında open geçen kapalı bileti içermiyor ---
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
[ -z "$r" ] && ok "Ticket 7.4 — 02-acik.txt konu alanında open geçen kapalı bileti içermiyor (kaynak: lab 007a)" \
             || bad "Ticket 7.4 — $r (kaynak: lab 007a)"

# --- 7.5 02-acik.txt satır sırası kaynaktakiyle aynı ---
r=""
if [ ! -f "$ANS/02-acik.txt" ]; then
    r="$ANS/02-acik.txt yok, sıra kontrolü yapılamıyor"
elif ! cmp -s "$TMP/exp-acik" "$ANS/02-acik.txt"; then
    r="02-acik.txt kaynak dosyayla birebir aynı değil (içerik ya da sıra)"
fi
[ -z "$r" ] && ok "Ticket 7.5 — 02-acik.txt satır sırası kaynak dosyayla aynı (kaynak: lab 007a)" \
             || bad "Ticket 7.5 — $r (kaynak: lab 007a)"

# --- 7.6 03-oncelik.txt her öncelik için tek satır ---
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
[ -z "$r" ] && ok "Ticket 7.6 — 03-oncelik.txt her öncelik için tek satır içeriyor (kaynak: lab 007a)" \
             || bad "Ticket 7.6 — $r (kaynak: lab 007a)"

# --- 7.7 03-oncelik.txt sayıları gerçek dağılıma eşit ---
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
[ -z "$r" ] && ok "Ticket 7.7 — 03-oncelik.txt sayıları gerçek dağılıma eşit (kaynak: lab 007a)" \
             || bad "Ticket 7.7 — $r (kaynak: lab 007a)"

# --- 7.8 04-kod.txt tek satır ve değeri 0 ---
r=""
if [ ! -f "$ANS/04-kod.txt" ]; then
    r="$ANS/04-kod.txt yok"
elif ! v="$(one_value "$ANS/04-kod.txt")"; then
    r="04-kod.txt tek satır değil ($(nlines "$ANS/04-kod.txt") satır)"
elif [ "$v" != "0" ]; then
    r="04-kod.txt içeriği '$v', beklenen 0 (DENIED dosyada geçiyor)"
fi
[ -z "$r" ] && ok "Ticket 7.8 — 04-kod.txt tek satır ve değeri 0 (kaynak: lab 007a)" \
             || bad "Ticket 7.8 — $r (kaynak: lab 007a)"

# --- 7.9 05-kod.txt tek satır ve değeri 1 ---
r=""
if [ ! -f "$ANS/05-kod.txt" ]; then
    r="$ANS/05-kod.txt yok"
elif ! v="$(one_value "$ANS/05-kod.txt")"; then
    r="05-kod.txt tek satır değil ($(nlines "$ANS/05-kod.txt") satır)"
elif [ "$v" != "1" ]; then
    r="05-kod.txt içeriği '$v', beklenen 1 (kelime dosyada geçmiyor)"
fi
[ -z "$r" ] && ok "Ticket 7.9 — 05-kod.txt tek satır ve değeri 1 (kaynak: lab 007a)" \
             || bad "Ticket 7.9 — $r (kaynak: lab 007a)"

# --- 7.10 notlar.txt içinde ^TODO kalmamış ---
r=""
if [ ! -f "$DESTEK/notlar.txt" ]; then
    r="$DESTEK/notlar.txt yok"
else
    n="$(grep -c '^TODO' "$DESTEK/notlar.txt" || true)"
    [ "$n" -eq 0 ] || r="notlar.txt içinde TODO ile başlayan $n satır duruyor"
fi
[ -z "$r" ] && ok "Ticket 7.10 — notlar.txt içinde TODO ile başlayan satır kalmamış (kaynak: lab 007a)" \
             || bad "Ticket 7.10 — $r (kaynak: lab 007a)"

# --- 7.11 sunucu1 gitmiş, karşılıkları web01 olmuş ---
# web01 sayısı orijinaldeki sunucu1 GEÇİŞ sayısına eşit olmalı; satır
# sayısına değil. Eksik `g` bayrağı buradan yakalanır.
r=""
if [ ! -f "$DESTEK/notlar.txt" ]; then
    r="$DESTEK/notlar.txt yok"
else
    left="$(grep -c 'sunucu1' "$DESTEK/notlar.txt" || true)"
    hits="$(grep -o 'web01' "$DESTEK/notlar.txt" | wc -l | tr -d ' ')"
    if [ "$left" -ne 0 ]; then
        r="notlar.txt içinde sunucu1 geçen $left satır duruyor"
    elif [ "$hits" -ne "$REF_SUNUCU1_HITS" ]; then
        r="web01 $hits kez geçiyor, beklenen $REF_SUNUCU1_HITS (satır içindeki ikinci eşleşme kaçmış olabilir)"
    fi
fi
[ -z "$r" ] && ok "Ticket 7.11 — notlar.txt'de sunucu1 geçmiyor, $REF_SUNUCU1_HITS geçişin hepsi web01 (kaynak: lab 007a)" \
             || bad "Ticket 7.11 — $r (kaynak: lab 007a)"

# --- 7.12 notlar.txt'nin diğer satırları ve sırası değişmemiş ---
r=""
if [ ! -f "$DESTEK/notlar.txt" ]; then
    r="$DESTEK/notlar.txt yok"
elif ! cmp -s "$TMP/exp-notlar" "$DESTEK/notlar.txt"; then
    e="$(nlines "$TMP/exp-notlar")"; g="$(nlines "$DESTEK/notlar.txt")"
    r="notlar.txt beklenen son hâlle birebir aynı değil (beklenen $e, gelen $g satır) — fazla silinmiş, sıra değişmiş ya da düzenleme eksik"
fi
[ -z "$r" ] && ok "Ticket 7.12 — notlar.txt'nin diğer satırları ve sırası değişmemiş (kaynak: lab 007a)" \
             || bad "Ticket 7.12 — $r (kaynak: lab 007a)"

# --- 7.13 Salt okunur veri dosyaları değişmemiş (korkuluk) ---
r=""
for f in biletler.csv erisim.log; do
    if [ ! -f "$DESTEK/$f" ]; then
        r="${r:+$r; }$f silinmiş"
    elif ! cmp -s "$OD/$f" "$DESTEK/$f"; then
        r="${r:+$r; }$f değiştirilmiş"
    fi
done
[ -z "$r" ] && ok "Ticket 7.13 — biletler.csv ve erisim.log değiştirilmemiş (kaynak: lab 007a)" \
             || bad "Ticket 7.13 — $r (kaynak: lab 007a)"

# =============================================================================
# TICKET 8 — Karışık log'u temizle, otomatik rapor kur (kaynak: lab 007b)
# =============================================================================
# Beklenen valid/invalid ayrımı BAĞIMSIZ bir referans ERE ile yeniden
# hesaplanır; öğrencinin regex'i referans alınmaz.
#
# Sıralama önemli: 8.1-8.14 öğrencinin bıraktığı dosyalar üzerinde ölçülür,
# mkreport bloğu ONDAN SONRA gelir — çünkü mkreport work/ altını yeniden
# üretip ölçülecek dosyaları eziyor.
section "Ticket 8  — Log temizleme + rapor (lab 007b)"

OG="$ORIG/gunlukler"

# Mesaj alanı `[^|]+` — "baştan sona tam olarak dört alan" demek `.+$` değil.
# Oktetin 0-255 aralığında olması İSTENMİYOR ("dört sayı"), o yüzden `{1,3}`.
BODY='[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|([0-9]{1,3}\.){3}[0-9]{1,3}\|'
REF_ERE="^${BODY}[^|]+\$"

normalize() {
    sed -E -e 's#([0-9]{2})/([0-9]{2})/([0-9]{4})#\3-\2-\1#g' \
           -e 's#[[:space:]]*\|[[:space:]]*#|#g' "$1"
}

ozet_of() {
    awk -F'|' '
        { n[$2]++
          k = $2 SUBSEP $3
          if (!(k in seen)) { seen[k] = 1; u[$2]++ } }
        END { for (l in n) print l, n[l], u[l] }
    ' "$1" | sort
}

normalize "$OG/merged.log"            > "$TMP/exp-normal"
grep -E  "$REF_ERE" "$TMP/exp-normal" > "$TMP/exp-valid"   || true
grep -Ev "$REF_ERE" "$TMP/exp-normal" > "$TMP/exp-invalid" || true
ozet_of "$TMP/exp-valid"              > "$TMP/exp-ozet"
REF_TOTAL="$(nlines "$OG/merged.log")"

# --- 8.1 normal.log satır sayısı merged.log ile aynı ---
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
else
    g="$(nlines "$WORK/normal.log")"
    [ "$g" -eq "$REF_TOTAL" ] || r="normal.log $g satır, merged.log $REF_TOTAL satır"
fi
[ -z "$r" ] && ok "Ticket 8.1 — normal.log satır sayısı merged.log ile aynı ($REF_TOTAL) (kaynak: lab 007b)" \
             || bad "Ticket 8.1 — $r (kaynak: lab 007b)"

# --- 8.2 GG/AA/YYYY biçimi kalmamış ---
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
else
    n="$(grep -Ec '[0-9]{2}/[0-9]{2}/[0-9]{4}' "$WORK/normal.log" || true)"
    [ "$n" -eq 0 ] || r="normal.log içinde $n satırda GG/AA/YYYY tarih duruyor"
fi
[ -z "$r" ] && ok "Ticket 8.2 — normal.log içinde GG/AA/YYYY biçiminde tarih kalmamış (kaynak: lab 007b)" \
             || bad "Ticket 8.2 — $r (kaynak: lab 007b)"

# --- 8.3 Ayırıcı çevresinde boşluk kalmamış ---
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
else
    n="$(grep -Ec '[[:space:]]\||\|[[:space:]]' "$WORK/normal.log" || true)"
    [ "$n" -eq 0 ] || r="normal.log içinde $n satırda ayırıcı çevresinde boşluk duruyor"
fi
[ -z "$r" ] && ok "Ticket 8.3 — normal.log içinde ayırıcı çevresinde boşluk kalmamış (kaynak: lab 007b)" \
             || bad "Ticket 8.3 — $r (kaynak: lab 007b)"

# --- 8.4 normal.log satır sırası merged.log ile aynı ---
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
elif ! cmp -s "$TMP/exp-normal" "$WORK/normal.log"; then
    d="$(diff "$TMP/exp-normal" "$WORK/normal.log" | head -1)"
    r="normal.log beklenen normalleştirmeyle birebir aynı değil (ilk fark: ${d:-?})"
fi
[ -z "$r" ] && ok "Ticket 8.4 — normal.log satır sırası merged.log ile aynı (kaynak: lab 007b)" \
             || bad "Ticket 8.4 — $r (kaynak: lab 007b)"

# --- 8.5 valid.log yalnız dört alanlı tam eşleşen satırları içeriyor ---
r=""
if [ ! -f "$WORK/valid.log" ]; then
    r="$WORK/valid.log yok"
elif ! cmp -s "$TMP/exp-valid" "$WORK/valid.log"; then
    e="$(nlines "$TMP/exp-valid")"; g="$(nlines "$WORK/valid.log")"
    r="valid.log referans ayrımla uyuşmuyor (beklenen $e, gelen $g satır)"
fi
[ -z "$r" ] && ok "Ticket 8.5 — valid.log yalnız dört alanlı, tam eşleşen satırları içeriyor (kaynak: lab 007b)" \
             || bad "Ticket 8.5 — $r (kaynak: lab 007b)"

# --- 8.6 valid.log içinde geçersiz seviye ya da ip yok ---
r=""
if [ ! -f "$WORK/valid.log" ]; then
    r="$WORK/valid.log yok"
else
    bads="$(grep -Evc "$REF_ERE" "$WORK/valid.log" || true)"
    if [ "$bads" -ne 0 ]; then
        first="$(grep -Ev "$REF_ERE" "$WORK/valid.log" | head -1)"
        r="valid.log içinde biçime uymayan $bads satır var, ilki: $first"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.6 — valid.log içinde geçersiz seviye ya da geçersiz ip yok (kaynak: lab 007b)" \
             || bad "Ticket 8.6 — $r (kaynak: lab 007b)"

# --- 8.7 invalid.log geri kalan satırların hepsini içeriyor ---
r=""
if [ ! -f "$WORK/invalid.log" ]; then
    r="$WORK/invalid.log yok"
elif ! cmp -s "$TMP/exp-invalid" "$WORK/invalid.log"; then
    e="$(nlines "$TMP/exp-invalid")"; g="$(nlines "$WORK/invalid.log")"
    r="invalid.log referans ayrımla uyuşmuyor (beklenen $e, gelen $g satır)"
fi
[ -z "$r" ] && ok "Ticket 8.7 — invalid.log geri kalan satırların hepsini içeriyor (kaynak: lab 007b)" \
             || bad "Ticket 8.7 — $r (kaynak: lab 007b)"

# --- 8.8 valid + invalid = normal ---
r=""
if [ ! -f "$WORK/valid.log" ] || [ ! -f "$WORK/invalid.log" ] ||
   [ ! -f "$WORK/normal.log" ]; then
    r="valid.log / invalid.log / normal.log üçlüsü tam değil, toplam alınamıyor"
else
    v="$(nlines "$WORK/valid.log")"
    i="$(nlines "$WORK/invalid.log")"
    n="$(nlines "$WORK/normal.log")"
    [ $((v + i)) -eq "$n" ] || r="valid ($v) + invalid ($i) = $((v + i)), normal.log $n satır"
fi
[ -z "$r" ] && ok "Ticket 8.8 — valid.log ve invalid.log satır toplamı normal.log'a eşit (kaynak: lab 007b)" \
             || bad "Ticket 8.8 — $r (kaynak: lab 007b)"

# --- 8.9 ozet.txt her seviye için tek satır ve üç alan ---
r=""
if [ ! -f "$WORK/ozet.txt" ]; then
    r="$WORK/ozet.txt yok"
else
    exp_lv="$(nlines "$TMP/exp-ozet")"
    got_lv="$(nlines "$WORK/ozet.txt")"
    if [ "$got_lv" -ne "$exp_lv" ]; then
        r="ozet.txt $got_lv satır, valid.log içinde $exp_lv seviye geçiyor"
    elif ! awk 'NF != 3 || $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/ {exit 1}' \
            "$WORK/ozet.txt"; then
        r="ozet.txt biçimi bozuk (her satır: seviye sayı sayı)"
    elif ! cut -d' ' -f1 "$WORK/ozet.txt" | sort |
            cmp -s - <(cut -d' ' -f1 "$TMP/exp-ozet" | sort); then
        r="ozet.txt'deki seviye adları valid.log'da geçen seviyelerle örtüşmüyor"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.9 — ozet.txt her seviye için tek satır ve üç alan içeriyor (kaynak: lab 007b)" \
             || bad "Ticket 8.9 — $r (kaynak: lab 007b)"

# --- 8.10 ozet.txt toplam sayıları ---
r=""
if [ ! -f "$WORK/ozet.txt" ]; then
    r="$WORK/ozet.txt yok, toplamlar karşılaştırılamıyor"
else
    awk '{print $1, $2}' "$WORK/ozet.txt" | sort > "$TMP/got-tot"
    awk '{print $1, $2}' "$TMP/exp-ozet"  | sort > "$TMP/exp-tot"
    cmp -s "$TMP/exp-tot" "$TMP/got-tot" ||
        r="ozet.txt toplam sayıları yanlış (beklenen: $(tr '\n' ' ' < "$TMP/exp-tot"))"
fi
[ -z "$r" ] && ok "Ticket 8.10 — ozet.txt toplam sayıları valid.log ile uyuşuyor (kaynak: lab 007b)" \
             || bad "Ticket 8.10 — $r (kaynak: lab 007b)"

# --- 8.11 ozet.txt tekil ip sayıları ---
# Tuzak burada ısırır: bazı geçerli satırların MESAJINDA da IP geçiyor.
r=""
if [ ! -f "$WORK/ozet.txt" ]; then
    r="$WORK/ozet.txt yok, tekil ip sayıları karşılaştırılamıyor"
else
    awk '{print $1, $3}' "$WORK/ozet.txt" | sort > "$TMP/got-uip"
    awk '{print $1, $3}' "$TMP/exp-ozet"  | sort > "$TMP/exp-uip"
    cmp -s "$TMP/exp-uip" "$TMP/got-uip" ||
        r="ozet.txt tekil ip sayıları yanlış (beklenen: $(tr '\n' ' ' < "$TMP/exp-uip")) — ip yalnız 3. alandan sayılır, mesaj alanından değil"
fi
[ -z "$r" ] && ok "Ticket 8.11 — ozet.txt tekil ip sayıları doğru (kaynak: lab 007b)" \
             || bad "Ticket 8.11 — $r (kaynak: lab 007b)"

# --- 8.12 report.conf: ^# satırları gitti, satır ortasındaki # kaldı ---
r=""
if [ ! -f "$CONF/report.conf" ]; then
    r="$CONF/report.conf yok"
else
    left="$(grep -c '^#' "$CONF/report.conf" || true)"
    del="$(grep -c '^#' "$OG/report.conf" || true)"
    exp_n=$(( $(nlines "$OG/report.conf") - del ))
    got_n="$(nlines "$CONF/report.conf")"
    missing=""
    while IFS= read -r line; do
        grep -qxF -- "$line" "$CONF/report.conf" || missing="$line"
    done < <(grep -v '^#' "$OG/report.conf" | grep '#' || true)
    if [ "$left" -ne 0 ]; then
        r="report.conf içinde # ile başlayan $left satır duruyor"
    elif [ -n "$missing" ]; then
        r="satır ortasında # geçen satır da silinmiş (çapasız kalıp): $missing"
    elif [ "$got_n" -ne "$exp_n" ]; then
        r="report.conf $got_n satır, beklenen $exp_n ($del yorum satırı silinecekti)"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.12 — report.conf içinde # ile başlayan satır kalmamış (kaynak: lab 007b)" \
             || bad "Ticket 8.12 — $r (kaynak: lab 007b)"

# --- 8.13 /opt/eski -> /srv/work ---
# Satır sayısı değil GEÇİŞ sayısı sayılır: bir satırda iki kez geçiyor.
r=""
if [ ! -f "$CONF/report.conf" ]; then
    r="$CONF/report.conf yok"
else
    ref_hits="$(grep -o '/opt/eski' "$OG/report.conf" | wc -l | tr -d ' ')"
    left="$(grep -c '/opt/eski' "$CONF/report.conf" || true)"
    hits="$(grep -o '/srv/work' "$CONF/report.conf" | wc -l | tr -d ' ')"
    if [ "$left" -ne 0 ]; then
        r="report.conf içinde /opt/eski geçen $left satır duruyor"
    elif [ "$hits" -ne "$ref_hits" ]; then
        r="/srv/work $hits kez geçiyor, beklenen $ref_hits (satır içindeki ikinci eşleşme kaçmış olabilir)"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.13 — report.conf içinde /opt/eski geçmiyor, hepsi /srv/work olmuş (kaynak: lab 007b)" \
             || bad "Ticket 8.13 — $r (kaynak: lab 007b)"

# --- 8.14 retention = 30 ---
r=""
if [ ! -f "$CONF/report.conf" ]; then
    r="$CONF/report.conf yok"
else
    v="$(awk -F'=' '/^[[:space:]]*retention[[:space:]]*=/ {
             gsub(/[[:space:]]/, "", $2); print $2; exit }' "$CONF/report.conf")"
    if [ -z "$v" ]; then
        r="report.conf içinde retention satırı bulunamadı"
    elif [ "$v" != "30" ]; then
        r="retention değeri '$v', beklenen 30"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.14 — report.conf retention değeri 30 (kaynak: lab 007b)" \
             || bad "Ticket 8.14 — $r (kaynak: lab 007b)"

# --- 8.15 mkreport student tarafından sudo'suz çalışıyor ---
# MK_OK, 8.16-8.18'in kapısı: mkreport hiç çalışmadıysa onlar FAIL verir
# ama check çökmez.
MK_OK=0
DIRTY_RC=0
DIRTY_FIRST=""
r=""
if [ ! -f "$MKREPORT" ]; then
    r="$MKREPORT yok"
elif [ ! -x "$MKREPORT" ]; then
    r="$MKREPORT çalıştırma izni taşımıyor (chmod +x)"
else
    run_student 'command -v mkreport >/dev/null'
    if [ "$RC" -ne 0 ]; then
        r="mkreport student'ın PATH'inde bulunamıyor"
    else
        run_student 'mkreport'
        if [ "$RC" -ge 126 ]; then
            r="mkreport student olarak çalıştırılamadı (rc=$RC): $(head -1 "$TMP/se")"
        else
            MK_OK=1
            DIRTY_RC="$RC"
        fi
    fi
fi
[ -z "$r" ] && ok "Ticket 8.15 — mkreport student tarafından sudo'suz çalıştırılıyor (kaynak: lab 007b)" \
             || bad "Ticket 8.15 — $r (kaynak: lab 007b)"

# --- 8.16 text-report.txt ilk satırı DIRTY/CLEAN ve doğru ---
r=""
if [ "$MK_OK" -eq 0 ]; then
    r="mkreport çalıştırılamadığı için rapor üretilmedi"
elif [ ! -f "$REPORTS/text-report.txt" ]; then
    r="$REPORTS/text-report.txt yok"
else
    DIRTY_FIRST="$(head -1 "$REPORTS/text-report.txt" |
                   sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    inv="$(nlines "$WORK/invalid.log")"
    case "$DIRTY_FIRST" in
        DIRTY) [ "$inv" -gt 0 ] || r="ilk satır DIRTY ama invalid.log boş" ;;
        CLEAN) [ "$inv" -eq 0 ] || r="ilk satır CLEAN ama invalid.log $inv satır" ;;
        *)     r="raporun ilk satırı '$DIRTY_FIRST', DIRTY ya da CLEAN olmalı" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 8.16 — text-report.txt ilk satırı DIRTY/CLEAN ve doğru (kaynak: lab 007b)" \
             || bad "Ticket 8.16 — $r (kaynak: lab 007b)"

# --- 8.17 mkreport çıkış kodu ilk satırla tutarlı ---
# İki yol da sınanır. CLEAN için geçici olarak yalnız geçerli satırlardan
# oluşan bir merged.log konur; sonra ortam ESKİ HÂLİNE geri alınır.
r=""
if [ "$MK_OK" -eq 0 ]; then
    r="mkreport çalıştırılamadığı için çıkış kodu sınanamıyor"
else
    if [ "$DIRTY_FIRST" = "DIRTY" ] && [ "$DIRTY_RC" -ne 1 ]; then
        r="DIRTY raporda çıkış kodu $DIRTY_RC, 1 olmalı"
    elif [ "$DIRTY_FIRST" = "CLEAN" ] && [ "$DIRTY_RC" -ne 0 ]; then
        r="CLEAN raporda çıkış kodu $DIRTY_RC, 0 olmalı"
    fi

    cp "$TMP/exp-valid" "$TMP/clean-merged"
    chmod 0644 "$GUNLUKLER/merged.log"
    cp "$TMP/clean-merged" "$GUNLUKLER/merged.log"
    chmod 0444 "$GUNLUKLER/merged.log"
    rm -f "$WORK/normal.log" "$WORK/valid.log" "$WORK/invalid.log" \
          "$WORK/ozet.txt" "$REPORTS/text-report.txt"
    run_student 'mkreport'
    crc="$RC"
    cfirst="$(head -1 "$REPORTS/text-report.txt" 2>/dev/null |
              sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ "$cfirst" != "CLEAN" ]; then
        r="${r:+$r; }temiz kaynakta rapor '$cfirst' dedi, CLEAN olmalıydı"
    elif [ "$crc" -ne 0 ]; then
        r="${r:+$r; }temiz kaynakta CLEAN raporun çıkış kodu $crc, 0 olmalı"
    fi

    # Ortamı geri al ve DIRTY durumuna döndür (check sonrası determinizm).
    chmod 0644 "$GUNLUKLER/merged.log"
    cp "$OG/merged.log" "$GUNLUKLER/merged.log"
    chown root:root "$GUNLUKLER/merged.log"
    chmod 0444 "$GUNLUKLER/merged.log"
    rm -f "$WORK/normal.log" "$WORK/valid.log" "$WORK/invalid.log" \
          "$WORK/ozet.txt" "$REPORTS/text-report.txt"
    run_student 'mkreport'
fi
[ -z "$r" ] && ok "Ticket 8.17 — mkreport çıkış kodu raporun ilk satırıyla tutarlı (DIRTY ve CLEAN) (kaynak: lab 007b)" \
             || bad "Ticket 8.17 — $r (kaynak: lab 007b)"

# --- 8.18 İki kez çalıştırılınca rapor büyümez ---
r=""
if [ "$MK_OK" -eq 0 ]; then
    r="mkreport çalıştırılamadığı için idempotens sınanamıyor"
elif [ ! -f "$REPORTS/text-report.txt" ]; then
    r="text-report.txt yok, idempotens sınanamıyor"
else
    cp "$REPORTS/text-report.txt" "$TMP/rep1"
    run_student 'mkreport'
    if [ ! -f "$REPORTS/text-report.txt" ]; then
        r="ikinci koşudan sonra text-report.txt yok"
    elif ! cmp -s "$TMP/rep1" "$REPORTS/text-report.txt"; then
        a="$(nlines "$TMP/rep1")"; b="$(nlines "$REPORTS/text-report.txt")"
        r="rapor iki koşuda farklı ($a → $b satır); üstüne eklenmemeli, sıfırdan üretilmeli"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.18 — mkreport iki kez çalıştırıldığında rapor büyümüyor (kaynak: lab 007b)" \
             || bad "Ticket 8.18 — $r (kaynak: lab 007b)"

# --- 8.19 merged.log değişmemiş (korkuluk) ---
r=""
if [ ! -f "$GUNLUKLER/merged.log" ]; then
    r="merged.log silinmiş"
elif ! cmp -s "$OG/merged.log" "$GUNLUKLER/merged.log"; then
    r="merged.log değiştirilmiş"
fi
[ -z "$r" ] && ok "Ticket 8.19 — merged.log değiştirilmemiş (kaynak: lab 007b)" \
             || bad "Ticket 8.19 — $r (kaynak: lab 007b)"

# =============================================================================
# TICKET 9 — Aceleyle atılmış dosyalar ve arşivleme (kaynak: lab 008)
# =============================================================================
# Hiçbir dosya SİLİNMEZ, hiçbir bağlantı bozulmaz: "orijinali sil, symlink
# kırıldı mı bak" gibi yıkıcı test yok. Bağlantı kimliği inode üzerinden
# ölçülür, davranış üzerinden değil.
section "Ticket 9  — Dosya yerleşimi + arşiv (lab 008)"

HOME_DIR=/home/student
SRC=/srv/backup-kaynagi
DATA=/srv/data
BACKUP=/srv/backup
OL="$ORIG/links"
ARCHIVE="$BACKUP/data-yedek.tar.gz"

ino() { stat -c '%i' "$1" 2>/dev/null; }

# Cevap dosyaları için normalleştirme: baş/son boşluk kırpılır, iç boşluklar
# teke indirilir, boş satırlar atılır, sıra serbest (sort). Amaç biçimsel
# titizlik değil, cevabın kendisi.
norm_answer() {
    sed -e 's/[[:space:]]\+/ /g' -e 's/^ //' -e 's/ $//' -e '/^$/d' "$1" | sort
}

# --- 9.1 uygulama.log /var/log/myapp altında, eski konumda yok ---
r=""
if [ ! -f /var/log/myapp/uygulama.log ]; then
    r="/var/log/myapp/uygulama.log yok"
elif ! cmp -s "$OL/uygulama.log" /var/log/myapp/uygulama.log; then
    r="/var/log/myapp/uygulama.log içeriği orijinaliyle aynı değil"
elif [ -e "$HOME_DIR/uygulama.log" ]; then
    r="$HOME_DIR/uygulama.log hâlâ duruyor (taşındı değil kopyalandı)"
fi
[ -z "$r" ] && ok "Ticket 9.1 — uygulama.log /var/log/myapp/ altında, eski konumda yok (kaynak: lab 008)" \
             || bad "Ticket 9.1 — $r (kaynak: lab 008)"

# --- 9.2 myapp.conf /etc/myapp altında, eski konumda yok ---
r=""
if [ ! -f /etc/myapp/myapp.conf ]; then
    r="/etc/myapp/myapp.conf yok"
elif ! cmp -s "$OL/myapp.conf" /etc/myapp/myapp.conf; then
    r="/etc/myapp/myapp.conf içeriği orijinaliyle aynı değil"
elif [ -e "$HOME_DIR/myapp.conf" ]; then
    r="$HOME_DIR/myapp.conf hâlâ duruyor (taşındı değil kopyalandı)"
fi
[ -z "$r" ] && ok "Ticket 9.2 — myapp.conf /etc/myapp/ altında, eski konumda yok (kaynak: lab 008)" \
             || bad "Ticket 9.2 — $r (kaynak: lab 008)"

# --- 9.3 backup-helper /usr/local/bin altında ve çalıştırılabilir ---
r=""
if [ ! -f /usr/local/bin/backup-helper ]; then
    r="/usr/local/bin/backup-helper yok"
elif ! cmp -s "$OL/backup-helper" /usr/local/bin/backup-helper; then
    r="/usr/local/bin/backup-helper içeriği orijinaliyle aynı değil"
elif [ ! -x /usr/local/bin/backup-helper ]; then
    r="/usr/local/bin/backup-helper çalıştırma izni taşımıyor (chmod +x)"
elif [ -e "$HOME_DIR/backup-helper" ]; then
    r="$HOME_DIR/backup-helper hâlâ duruyor (taşındı değil kopyalandı)"
else
    run_student 'command -v backup-helper >/dev/null'
    [ "$RC" -eq 0 ] || r="backup-helper student'ın PATH'inde bulunamıyor"
fi
[ -z "$r" ] && ok "Ticket 9.3 — backup-helper /usr/local/bin/ altında ve çalıştırılabilir (kaynak: lab 008)" \
             || bad "Ticket 9.3 — $r (kaynak: lab 008)"

# --- 9.4 baglanti-raporu.txt ---
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
[ -z "$r" ] && ok "Ticket 9.4 — baglanti-raporu.txt iki satır, etiketler doğru (kaynak: lab 008)" \
             || bad "Ticket 9.4 — $r (kaynak: lab 008)"

# --- 9.5 kaynak3-hardlink.txt aynı inode ---
# Symlink de `cmp` testini geçer, o yüzden inode ve link sayısı sorulur.
r=""
if [ ! -e "$HOME_DIR/kaynak3-hardlink.txt" ]; then
    r="$HOME_DIR/kaynak3-hardlink.txt yok"
elif [ -L "$HOME_DIR/kaynak3-hardlink.txt" ]; then
    r="kaynak3-hardlink.txt sembolik bağlantı, hard link olmalı"
elif [ "$(ino "$HOME_DIR/kaynak3-hardlink.txt")" != "$(ino "$SRC/kaynak3.txt")" ]; then
    r="kaynak3-hardlink.txt farklı inode taşıyor (kopya mı?): $(ino "$HOME_DIR/kaynak3-hardlink.txt") vs $(ino "$SRC/kaynak3.txt")"
elif [ "$(stat -c '%h' "$SRC/kaynak3.txt")" -lt 2 ]; then
    r="kaynak3.txt link sayısı 2'den küçük"
fi
[ -z "$r" ] && ok "Ticket 9.5 — kaynak3-hardlink.txt kaynak3.txt ile aynı inode (kaynak: lab 008)" \
             || bad "Ticket 9.5 — $r (kaynak: lab 008)"

# --- 9.6 kaynak3-symlink.txt doğru hedefe işaret ediyor ---
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
[ -z "$r" ] && ok "Ticket 9.6 — kaynak3-symlink.txt doğru hedefe işaret ediyor (kaynak: lab 008)" \
             || bad "Ticket 9.6 — $r (kaynak: lab 008)"

# --- 9.7 disk-kullanimi.txt ---
# Beklenen değer check anında ölçülür, sabit yazılmaz. Hard link'i ikinci
# kez sayan çözümün vereceği sayı da hesaplanıp FAIL mesajında söylenir.
r=""
real_kb="$(du -s "$SRC" | cut -f1)"
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
[ -z "$r" ] && ok "Ticket 9.7 — disk-kullanimi.txt tek satır, doğru sayı ($real_kb KB) (kaynak: lab 008)" \
             || bad "Ticket 9.7 — $r (kaynak: lab 008)"

# --- Arşiv listesi (9.8, 9.9 ve 9.10 için ortak) ---
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

# --- 9.8 arşiv var, gecici içeriği arşivde yok ---
r=""
if [ ! -f "$ARCHIVE" ]; then
    r="$ARCHIVE yok"
elif [ "$ARCH_OK" -eq 0 ]; then
    r="$ARCHIVE student olarak listelenemedi: $(head -1 "$TMP/se")"
else
    n="$(grep -cE '(^|/)gecici(/|$)' "$TMP/list" || true)"
    [ "$n" -eq 0 ] || r="arşivde gecici ile ilgili $n girdi var"
fi
[ -z "$r" ] && ok "Ticket 9.8 — data-yedek.tar.gz var, gecici içeriği arşivde yok (kaynak: lab 008)" \
             || bad "Ticket 9.8 — $r (kaynak: lab 008)"

# --- 9.9 arşivde dosya.txt ve kalici/onemli.txt var ---
r=""
if [ "$ARCH_OK" -eq 0 ]; then
    r="arşiv listelenemediği için içerik sınanamıyor"
else
    grep -qE '(^|/)dosya\.txt$' "$TMP/list" || r="arşivde dosya.txt yok"
    grep -qE '(^|/)kalici/onemli\.txt$' "$TMP/list" ||
        r="${r:+$r; }arşivde kalici/onemli.txt yok"
fi
[ -z "$r" ] && ok "Ticket 9.9 — data-yedek.tar.gz içinde dosya.txt ve kalici/onemli.txt var (kaynak: lab 008)" \
             || bad "Ticket 9.9 — $r (kaynak: lab 008)"

# --- 9.10 arsiv-dogrulama.txt ---
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
[ -z "$r" ] && ok "Ticket 9.10 — arsiv-dogrulama.txt iki satır, doğru var/yok (kaynak: lab 008)" \
             || bad "Ticket 9.10 — $r (kaynak: lab 008)"

# --- 9.11 Kaynaklar değişmemiş (korkuluk) ---
# gecici/ dizinini --exclude yerine SİLEN çözüm buradan düşer.
r=""
for f in kaynak1.txt kaynak2.txt kaynak3.txt; do
    if [ ! -f "$SRC/$f" ]; then
        r="${r:+$r; }$SRC/$f silinmiş"
    elif ! cmp -s "$OL/$f" "$SRC/$f"; then
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
if ! diff -r -q "$OL/data" "$DATA" >/dev/null 2>&1; then
    d="$(diff -r -q "$OL/data" "$DATA" 2>&1 | head -1)"
    r="${r:+$r; }/srv/data değişmiş (${d:-?})"
fi
[ -z "$r" ] && ok "Ticket 9.11 — /srv/data ve /srv/backup-kaynagi kaynakları değişmemiş (kaynak: lab 008)" \
             || bad "Ticket 9.11 — $r (kaynak: lab 008)"

# =============================================================================
# TICKET 10 — Paket durumu (kaynak: lab 009, package management)
# =============================================================================
# Beklenen değerler SABİT YAZILMAZ: paket adı, sürüm ve dosya listeleri
# check anında dosyanın kendisinden okunur.
# Hiçbir paket kurulmaz/kaldırılmaz: check sistemin durumunu değiştirmez.
section "Ticket 10 — Paket durumu (lab 009)"

PKGDIR=/srv/paketler
OP="$ORIG/paketler"

# Cevap dosyaları için normalleştirme (boşluklar teke, boş satırlar atılır).
norm() {
    sed -e 's/[[:space:]]\+/ /g' -e 's/^ //' -e 's/ $//' -e '/^$/d' "$1"
}

RPM_FILE="$(ls "$PKGDIR"/*.rpm 2>/dev/null | head -1)"
DEB_FILE="$(ls "$PKGDIR"/*.deb 2>/dev/null | head -1)"

# --- 10.1 paket-sorgu.txt ilk satırında doğru paket adı ---
r=""
TREE_PKG="$(rpm -qf --qf '%{NAME}' /usr/bin/tree 2>/dev/null)"
if [ -z "$TREE_PKG" ]; then
    r="/usr/bin/tree hiçbir pakete ait değil (ortam bozuk)"
elif [ ! -f "$ANS/paket-sorgu.txt" ]; then
    r="$ANS/paket-sorgu.txt yok"
else
    got_pkg="$(norm "$ANS/paket-sorgu.txt" | head -1)"
    case "$got_pkg" in
        "$TREE_PKG"|"$TREE_PKG"-[0-9]*) ;;
        *) r="paket-sorgu.txt ilk satırı '$got_pkg', beklenen '$TREE_PKG'" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 10.1 — paket-sorgu.txt ilk satırında doğru paket adı var (kaynak: lab 009)" \
             || bad "Ticket 10.1 — $r (kaynak: lab 009)"

# --- 10.2 paket-sorgu.txt dosya listesi eşleşiyor ---
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
[ -z "$r" ] && ok "Ticket 10.2 — paket-sorgu.txt dosya listesi paketin gerçek listesiyle eşleşiyor (kaynak: lab 009)" \
             || bad "Ticket 10.2 — $r (kaynak: lab 009)"

# --- 10.3 butunluk-raporu.txt paket ve dosya ---
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
[ -z "$r" ] && ok "Ticket 10.3 — butunluk-raporu.txt doğru paket ve dosya yolunu içeriyor (kaynak: lab 009)" \
             || bad "Ticket 10.3 — $r (kaynak: lab 009)"

# --- 10.4 butunluk-raporu.txt içerik + izin ---
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
[ -z "$r" ] && ok "Ticket 10.4 — butunluk-raporu.txt hem icerik hem izin değişikliğini işaretlemiş (kaynak: lab 009)" \
             || bad "Ticket 10.4 — $r (kaynak: lab 009)"

# --- 10.5 eksik-komut.txt doğru paket adı ---
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
[ -z "$r" ] && ok "Ticket 10.5 — eksik-komut.txt doğru paket adını içeriyor (kaynak: lab 009)" \
             || bad "Ticket 10.5 — $r (kaynak: lab 009)"

# --- 10.6 lsof çalışıyor ---
r=""
if ! rpm -q lsof >/dev/null 2>&1; then
    r="lsof paketi kurulu değil"
else
    run_student 'lsof -v'
    [ "$RC" -eq 0 ] || r="student olarak lsof çalışmıyor: $(head -1 "$TMP/se")"
fi
[ -z "$r" ] && ok "Ticket 10.6 — lsof komutu artık çalışıyor (kaynak: lab 009)" \
             || bad "Ticket 10.6 — $r (kaynak: lab 009)"

# --- 10.7 bc kurulu ---
r=""
rpm -q bc >/dev/null 2>&1 || r="bc paketi kurulu değil (dnf history undo yapıldı mı?)"
[ -z "$r" ] && ok "Ticket 10.7 — bc paketi kurulu (kaynak: lab 009)" \
             || bad "Ticket 10.7 — $r (kaynak: lab 009)"

# --- 10.8 hesapla doğru sonucu üretiyor ---
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
[ -z "$r" ] && ok "Ticket 10.8 — hesapla scripti doğru sonucu üretiyor (kaynak: lab 009)" \
             || bad "Ticket 10.8 — $r (kaynak: lab 009)"

# --- 10.9 rpm-inceleme.txt ad, sürüm, dosya listesi ---
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
[ -z "$r" ] && ok "Ticket 10.9 — rpm-inceleme.txt doğru paket adı, sürüm ve dosya listesi içeriyor (kaynak: lab 009)" \
             || bad "Ticket 10.9 — $r (kaynak: lab 009)"

# --- 10.10 rpm-inceleme.txt'deki paket KURULU DEĞİL (negatif test) ---
r=""
if [ -z "$RPM_FILE" ]; then
    r="$PKGDIR içinde .rpm dosyası yok"
else
    n="$(rpm -qp --qf '%{NAME}' "$RPM_FILE" 2>/dev/null)"
    if rpm -q "$n" >/dev/null 2>&1; then
        r="$n sisteme KURULMUŞ; görev incelemekti, kurmak değil"
    fi
fi
[ -z "$r" ] && ok "Ticket 10.10 — rpm-inceleme.txt'deki paket sistemde kurulu değil (kaynak: lab 009)" \
             || bad "Ticket 10.10 — $r (kaynak: lab 009)"

# --- 10.11 EPEL deposu etkin ---
r=""
dnf repolist --enabled 2>/dev/null | grep -qiE '^epel[[:space:]]' ||
    r="epel deposu etkin değil"
[ -z "$r" ] && ok "Ticket 10.11 — EPEL deposu etkin (kaynak: lab 009)" \
             || bad "Ticket 10.11 — $r (kaynak: lab 009)"

# --- 10.12 crb deposu etkin ---
# Rocky 10'da dpkg'nin bağımlılığı zlib-ng crb reposunda; crb açılmadan
# .deb görevi tamamlanamaz. Ayrı kriter, çünkü ayrı bir kavram.
r=""
dnf repolist --enabled 2>/dev/null | grep -qiE '^crb[[:space:]]' ||
    r="crb deposu etkin değil"
[ -z "$r" ] && ok "Ticket 10.12 — crb deposu etkin (kaynak: lab 009)" \
             || bad "Ticket 10.12 — $r (kaynak: lab 009)"

# --- 10.13 dpkg kurulu ve çalışıyor ---
r=""
if ! rpm -q dpkg >/dev/null 2>&1; then
    r="dpkg paketi kurulu değil"
else
    run_student 'dpkg-deb --version'
    [ "$RC" -eq 0 ] || r="student olarak dpkg-deb çalışmıyor: $(head -1 "$TMP/se")"
fi
[ -z "$r" ] && ok "Ticket 10.13 — dpkg kurulu ve çalışıyor (kaynak: lab 009)" \
             || bad "Ticket 10.13 — $r (kaynak: lab 009)"

# --- 10.14 deb-inceleme.txt ad, sürüm, dosya listesi ---
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
    # dpkg-deb -c çıktısındaki yollar ./ ile başlar; dizinler atılır.
    dpkg-deb -c "$DEB_FILE" 2>/dev/null |
        awk '$1 !~ /^d/ {print $NF}' | sed 's#^\./#/#' | sort > "$TMP/exp-deb-l"

    norm "$ANS/deb-inceleme.txt" > "$TMP/deb-ins"
    got_name="$(awk '$1 == "paket-adi:" {print $2; exit}' "$TMP/deb-ins")"
    got_ver="$(awk  '$1 == "surum:"     {print $2; exit}' "$TMP/deb-ins")"
    awk 'f {print} $1 == "dosyalar:" {f = 1}' "$TMP/deb-ins" |
        sed 's#^\./#/#' | sort > "$TMP/got-deb-raw"
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
[ -z "$r" ] && ok "Ticket 10.14 — deb-inceleme.txt doğru paket adı, sürüm ve dosya listesi içeriyor (kaynak: lab 009)" \
             || bad "Ticket 10.14 — $r (kaynak: lab 009)"

# --- 10.15 deb-inceleme.txt'deki paket KURULU DEĞİL (negatif test) ---
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
[ -z "$r" ] && ok "Ticket 10.15 — deb-inceleme.txt'deki paket sistemde kurulu değil (kaynak: lab 009)" \
             || bad "Ticket 10.15 — $r (kaynak: lab 009)"

# --- 10.16 Kaynak dosyalar değişmemiş (korkuluk) ---
r=""
for f in "$OP"/*; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    if [ ! -f "$PKGDIR/$b" ]; then
        r="${r:+$r; }$PKGDIR/$b silinmiş"
    elif ! cmp -s "$f" "$PKGDIR/$b"; then
        r="${r:+$r; }$PKGDIR/$b değiştirilmiş"
    fi
done
[ -z "$r" ] && ok "Ticket 10.16 — /srv/paketler altındaki dosyalar değiştirilmemiş (kaynak: lab 009)" \
             || bad "Ticket 10.16 — $r (kaynak: lab 009)"

# =============================================================================
# TICKET 11 — Dört systemd işi (kaynak: lab 010, systemd)
# =============================================================================
# Durum systemd'ye SORULUR, dosyadan okunmaz: öğrenci unit dosyasını düzeltip
# daemon-reload yapmadıysa dosya doğru görünür ama sistem eski tanımı taşır.
# Hiçbir servis başlatılmaz/durdurulmaz: check sistemin durumunu değiştirmez.
section "Ticket 11 — systemd servisleri (lab 010)"

UNITS=/etc/systemd/system
READY=/var/lib/veritabani/.ready

# `systemctl show -p A -p B --value` çıktıyı systemd'nin kendi sırasında
# basar, verdiğin sırada değil. Bu yüzden her özellik TEK TEK sorulur.
prop() { systemctl show "$1" -p "$2" --value 2>/dev/null; }
# ExecStart değeri "{ path=/x ; argv[]=... }" biçiminde gelir; yalnız yol.
exec_path() {
    prop "$1" ExecStart | sed -n 's/.*path=\([^ ;]*\).*/\1/p' | head -1
}
known() { systemctl cat "$1" >/dev/null 2>&1; }

# --- 11.1 gorevci.service doğru tip ve ExecStart ---
r=""
if ! known gorevci.service; then
    r="gorevci.service diye bir birim yok"
else
    t="$(prop gorevci.service Type)"
    e="$(exec_path gorevci.service)"
    if [ "$t" != "simple" ]; then
        r="gorevci.service Type='$t', beklenen 'simple' (script ön planda kalıyor)"
    elif [ "$e" != "/opt/app/gorevci" ]; then
        r="gorevci.service ExecStart '$e', beklenen '/opt/app/gorevci'"
    fi
fi
[ -z "$r" ] && ok "Ticket 11.1 — gorevci.service doğru tip ve doğru ExecStart ile yazılmış (kaynak: lab 010)" \
             || bad "Ticket 11.1 — $r (kaynak: lab 010)"

# --- 11.2 gorevci aktif ve enabled ---
r=""
a="$(systemctl is-active  gorevci.service 2>/dev/null || true)"
en="$(systemctl is-enabled gorevci.service 2>/dev/null || true)"
[ "$a"  = "active" ]  || r="gorevci.service aktif değil (durum: ${a:-yok})"
[ "$en" = "enabled" ] || r="${r:+$r; }gorevci.service enabled değil (durum: ${en:-yok})"
[ -z "$r" ] && ok "Ticket 11.2 — gorevci.service hem aktif hem enabled (kaynak: lab 010)" \
             || bad "Ticket 11.2 — $r (kaynak: lab 010)"

# --- 11.3 gorevci süreci gerçekten koşuyor ---
r=""
pid="$(prop gorevci.service MainPID)"
sub="$(prop gorevci.service SubState)"
if [ -z "${pid:-}" ] || [ "$pid" = "0" ]; then
    r="gorevci.service MainPID 0 (systemd'ye göre çalışan süreç yok)"
elif [ "$sub" != "running" ]; then
    r="gorevci.service SubState '$sub', beklenen 'running'"
else
    run_student 'systemctl show gorevci.service -p SubState --value'
    got="$(tr -d '[:space:]' < "$TMP/so")"
    [ "$RC" -eq 0 ] && [ "$got" = "running" ] ||
        r="student olarak sorgulandığında durum doğrulanamıyor: ${got:-$(head -1 "$TMP/se")}"
fi
[ -z "$r" ] && ok "Ticket 11.3 — gorevci süreci systemd'ye göre gerçekten koşuyor (kaynak: lab 010)" \
             || bad "Ticket 11.3 — $r (kaynak: lab 010)"

# --- 11.4 raporcu ExecStart doğru yol ---
r=""
if ! known raporcu.service; then
    r="raporcu.service diye bir birim yok"
else
    e="$(exec_path raporcu.service)"
    [ "$e" = "/opt/raporcu/bin/raporcu" ] ||
        r="raporcu.service ExecStart '$e', beklenen '/opt/raporcu/bin/raporcu'"
fi
[ -z "$r" ] && ok "Ticket 11.4 — raporcu.service ExecStart gerçek program yoluna işaret ediyor (kaynak: lab 010)" \
             || bad "Ticket 11.4 — $r (kaynak: lab 010)"

# --- 11.5 raporcu User çözülebiliyor ---
# İki geçerli çözüm: raporcu kullanıcısını yaratmak ya da User'ı var olan
# bir kullanıcıya çevirmek (boş User = root). Sınanan şey, systemd'nin o
# kullanıcıyı gerçekten çözebilmesi.
r=""
if ! known raporcu.service; then
    r="raporcu.service diye bir birim yok"
else
    u="$(prop raporcu.service User)"
    if [ -z "$u" ]; then
        :
    elif ! getent passwd "$u" >/dev/null 2>&1; then
        r="raporcu.service User='$u' ama böyle bir kullanıcı sistemde yok"
    fi
fi
[ -z "$r" ] && ok "Ticket 11.5 — raporcu.service User var olan bir kullanıcıya işaret ediyor (kaynak: lab 010)" \
             || bad "Ticket 11.5 — $r (kaynak: lab 010)"

# --- 11.6 raporcu aktif ve bellekteki tanım taze ---
# NeedDaemonReload, diskteki dosya ile systemd'nin bellekteki kopyası
# ayrıştığında 'yes' döner. daemon-reload atlanmışsa bu kriter FAIL verir.
r=""
a="$(systemctl is-active raporcu.service 2>/dev/null || true)"
nd="$(prop raporcu.service NeedDaemonReload)"
[ "$a" = "active" ] || r="raporcu.service aktif değil (durum: ${a:-yok})"
[ "$nd" = "no" ] ||
    r="${r:+$r; }raporcu.service için daemon-reload gerekiyor (NeedDaemonReload=$nd)"
[ -z "$r" ] && ok "Ticket 11.6 — raporcu.service aktif ve systemd bellekteki tanımı tazelenmiş (kaynak: lab 010)" \
             || bad "Ticket 11.6 — $r (kaynak: lab 010)"

# --- 11.7 api -> veritabani sıralama VE gereklilik ---
# Yalnız After yeterli değildir: After sırayı belirler, ama veritabani hiç
# başlatılmazsa api yine .ready dosyasını bulamaz. Requires onu da çeker.
r=""
if ! known api.service; then
    r="api.service diye bir birim yok"
else
    aft="$(prop api.service After)"
    req="$(prop api.service Requires)"
    case "$aft" in *veritabani.service*) ;; *)
        r="api.service After= veritabani.service içermiyor" ;;
    esac
    case "$req" in *veritabani.service*) ;; *)
        r="${r:+$r; }api.service Requires= veritabani.service içermiyor" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 11.7 — api.service veritabani.service'e sıralama ve gereklilik ile bağlı (kaynak: lab 010)" \
             || bad "Ticket 11.7 — $r (kaynak: lab 010)"

# --- 11.8 veritabani tamamlanmış durumda ---
# active (exited) = oneshot işini yaptı ve RemainAfterExit sayesinde
# "tamamlandı" olarak duruyor. ExecStart ve .ready da sınanır ki birim
# /bin/true ile taklit edilmesin.
r=""
a="$(systemctl is-active veritabani.service 2>/dev/null || true)"
sub="$(prop veritabani.service SubState)"
e="$(exec_path veritabani.service)"
if [ "$a" != "active" ]; then
    r="veritabani.service aktif değil (durum: ${a:-yok})"
elif [ "$sub" != "exited" ]; then
    r="veritabani.service SubState '$sub', beklenen 'exited'"
elif [ "$e" != "/opt/db/veritabani-init" ]; then
    r="veritabani.service ExecStart '$e', beklenen '/opt/db/veritabani-init'"
elif [ ! -e "$READY" ]; then
    r="$READY yok: veritabani.service işini gerçekten yapmamış"
fi
[ -z "$r" ] && ok "Ticket 11.8 — veritabani.service tamamlanmış durumda duruyor (kaynak: lab 010)" \
             || bad "Ticket 11.8 — $r (kaynak: lab 010)"

# --- 11.9 api başarıyla başlıyor ve aktif kalıyor ---
r=""
a="$(systemctl is-active api.service 2>/dev/null || true)"
sub="$(prop api.service SubState)"
res="$(prop api.service Result)"
e="$(exec_path api.service)"
if [ "$e" != "/opt/api/api" ]; then
    r="api.service ExecStart '$e', beklenen '/opt/api/api'"
elif [ "$a" != "active" ]; then
    r="api.service aktif değil (durum: ${a:-yok})"
elif [ "$sub" != "running" ]; then
    r="api.service SubState '$sub', beklenen 'running'"
elif [ "$res" != "success" ]; then
    r="api.service Result '$res', beklenen 'success'"
fi
[ -z "$r" ] && ok "Ticket 11.9 — api.service başarıyla başlıyor ve aktif kalıyor (kaynak: lab 010)" \
             || bad "Ticket 11.9 — $r (kaynak: lab 010)"

# --- 11.10 varsayılan target ---
r=""
d="$(systemctl get-default 2>/dev/null || true)"
[ "$d" = "multi-user.target" ] ||
    r="varsayılan target '$d', beklenen 'multi-user.target'"
[ -z "$r" ] && ok "Ticket 11.10 — varsayılan target multi-user.target (kaynak: lab 010)" \
             || bad "Ticket 11.10 — $r (kaynak: lab 010)"

# --- 11.11 birimler kalıcı konumda ---
# FragmentPath systemd'nin gerçekten okuduğu dosyadır. /run altındaki
# geçici birimler reboot'ta kaybolur; RHCSA'nın kalıcılık şartı bunu eler.
r=""
for u in gorevci raporcu api veritabani; do
    fp="$(prop "$u.service" FragmentPath)"
    if [ -z "$fp" ]; then
        r="${r:+$r; }$u.service için birim dosyası bulunamadı"
        continue
    fi
    case "$fp" in
        "$UNITS"/*) ;;
        *) r="${r:+$r; }$u.service $fp konumundan okunuyor, $UNITS altında olmalı" ;;
    esac
done
[ -z "$r" ] && ok "Ticket 11.11 — dört servis dosyası da $UNITS altında kalıcı (kaynak: lab 010)" \
             || bad "Ticket 11.11 — $r (kaynak: lab 010)"

# =============================================================================
# TICKET 12 — Log, cron ve saat (kaynak: lab 011, journalctl/cron/zaman)
# =============================================================================
section "Ticket 12 — Log, cron ve saat (lab 011)"

LISANS=/etc/bekci/lisans.key
CEVAP=/home/student/cevap-bekci.txt
CRONF=/etc/cron.d/yedek
YEDEK_LOG=/var/log/yedek/yedek.log
TEMIZLIK_LOG=/var/log/temizlik.log
WAIT_MAX=90

cron_job_line() {
    grep -vE '^[[:space:]]*(#|$)' "$CRONF" 2>/dev/null |
        grep -vE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' | head -1
}
have_yedek()    { [ -s "$YEDEK_LOG" ]; }
have_temizlik() { [ -s "$TEMIZLIK_LOG" ]; }

# Zamanlanmış işler dakikada bir tetikleniyor; check hemen koşarsa log henüz
# oluşmamış olabilir. Sınırlı süre beklenir, sonsuz değil.
if ! have_yedek || ! have_temizlik; then
    echo "... zamanlanmış işlerin tetiklenmesi bekleniyor (en fazla ${WAIT_MAX}s)"
    waited=0
    while [ "$waited" -lt "$WAIT_MAX" ]; do
        have_yedek && have_temizlik && break
        sleep 5
        waited=$((waited + 5))
    done
fi

# --- 12.1 kalıcı günlük dizini var ve günlük oraya yazılıyor ---
r=""
if [ ! -d /var/log/journal ]; then
    r="/var/log/journal dizini yok, günlük hâlâ yalnız bellekte"
elif [ -z "$(find /var/log/journal -name '*.journal' -print -quit 2>/dev/null)" ]; then
    r="/var/log/journal var ama içinde günlük dosyası yok (journald oraya yazmıyor)"
else
    run_student 'sudo -n journalctl -u bekci.service -n 20 --no-pager'
    grep -q 'bekci' "$TMP/so" || r="student sudo ile bekci.service günlüğünü okuyamıyor"
fi
[ -z "$r" ] && ok "Ticket 12.1 — kalıcı günlük dizini var ve günlük oraya yazılıyor (kaynak: lab 011)" \
             || bad "Ticket 12.1 — $r (kaynak: lab 011)"

# --- 12.2 cevap dosyasında eksik dosyanın yolu ve çıkış kodu ---
r=""
if [ ! -f "$CEVAP" ]; then
    r="$CEVAP yok"
else
    grep -q '/etc/bekci/lisans\.key' "$CEVAP" ||
        r="$CEVAP eksik dosyanın tam yolunu içermiyor"
    grep -Eq '(^|[^0-9])3([^0-9]|$)' "$CEVAP" ||
        r="${r:+$r; }$CEVAP servisin çıkış kodunu içermiyor"
fi
[ -z "$r" ] && ok "Ticket 12.2 — cevap dosyasında eksik dosyanın yolu ve çıkış kodu yazılı (kaynak: lab 011)" \
             || bad "Ticket 12.2 — $r (kaynak: lab 011)"

# --- 12.3 bekci.service hatasız çalışıyor ve enabled ---
r=""
if ! known bekci.service; then
    r="bekci.service diye bir birim yok"
else
    a="$(systemctl is-active  bekci.service 2>/dev/null || true)"
    en="$(systemctl is-enabled bekci.service 2>/dev/null || true)"
    sub="$(prop bekci.service SubState)"
    res="$(prop bekci.service Result)"
    [ "$a" = "active" ] || r="bekci.service aktif değil (durum: ${a:-yok})"
    [ "$sub" = "running" ] ||
        r="${r:+$r; }bekci.service alt durumu '$sub', beklenen 'running'"
    [ "$res" = "success" ] ||
        r="${r:+$r; }bekci.service Result='$res', servis hâlâ hata ile ölüyor"
    [ "$en" = "enabled" ] ||
        r="${r:+$r; }bekci.service enabled değil (durum: ${en:-yok})"
    [ -s "$LISANS" ] || r="${r:+$r; }$LISANS yok ya da boş"
fi
[ -z "$r" ] && ok "Ticket 12.3 — bekci.service hatasız çalışıyor ve enabled (kaynak: lab 011)" \
             || bad "Ticket 12.3 — $r (kaynak: lab 011)"

# --- 12.4 zamanlanmış iş servisi hem aktif hem enabled ---
r=""
a="$(systemctl is-active  crond.service 2>/dev/null || true)"
en="$(systemctl is-enabled crond.service 2>/dev/null || true)"
[ "$a"  = "active" ]  || r="crond.service aktif değil (durum: ${a:-yok})"
[ "$en" = "enabled" ] || r="${r:+$r; }crond.service enabled değil (durum: ${en:-yok})"
[ -z "$r" ] && ok "Ticket 12.4 — zamanlanmış iş servisi hem aktif hem enabled (kaynak: lab 011)" \
             || bad "Ticket 12.4 — $r (kaynak: lab 011)"

# --- 12.5 yedek işi her dakika çalışacak biçimde tanımlı ---
job="$(cron_job_line)"
r=""
if [ -z "$job" ]; then
    r="$CRONF içinde çalışan bir iş satırı yok"
else
    set -f
    set -- $job
    set +f
    if [ "$#" -lt 7 ]; then
        r="$CRONF iş satırı eksik alanlı: $job"
    else
        case "$1" in
            '*'|'*/1') ;;
            *) r="dakika alanı '$1', iş her dakika çalışmıyor" ;;
        esac
        for f in "$2" "$3" "$4" "$5"; do
            [ "$f" = '*' ] || r="${r:+$r; }zamanlama alanı '$f' her dakika çalışmayı engelliyor"
        done
    fi
fi
[ -z "$r" ] && ok "Ticket 12.5 — yedek işi her dakika çalışacak biçimde tanımlı (kaynak: lab 011)" \
             || bad "Ticket 12.5 — $r (kaynak: lab 011)"

# --- 12.6 yedek işinin komutu zamanlayıcının ortamında bulunabiliyor ---
r=""
if [ -z "$job" ]; then
    r="$CRONF içinde çalışan bir iş satırı yok"
else
    cmd="$(printf '%s\n' "$job" | awk '{print $7}')"
    case "$cmd" in
        /*)
            [ -x "$cmd" ] || r="komut '$cmd' çalıştırılabilir bir dosya değil"
            ;;
        *)
            pathline="$(grep -E '^[[:space:]]*PATH=' "$CRONF" 2>/dev/null | tail -1)"
            if [ -z "$pathline" ]; then
                r="komut '$cmd' mutlak yol değil ve dosyada PATH ataması yok"
            else
                case "${pathline#*=}" in
                    */usr/local/bin*) ;;
                    *) r="PATH ataması /usr/local/bin dizinini kapsamıyor" ;;
                esac
                command -v "$cmd" >/dev/null 2>&1 ||
                    r="${r:+$r; }komut '$cmd' sistemde bulunamıyor"
            fi
            ;;
    esac
    printf '%s\n' "$job" | grep -q 'yedekle' ||
        r="${r:+$r; }iş satırı yedekle programını çağırmıyor"
fi
[ -z "$r" ] && ok "Ticket 12.6 — yedek işinin komutu zamanlayıcının ortamında bulunabiliyor (kaynak: lab 011)" \
             || bad "Ticket 12.6 — $r (kaynak: lab 011)"

# --- 12.7 yedek log dosyasında gerçek bir çalışma satırı var ---
r=""
if [ ! -f "$YEDEK_LOG" ]; then
    r="$YEDEK_LOG yok — iş hiç çalışmamış"
elif ! grep -q 'yedek alindi' "$YEDEK_LOG"; then
    r="$YEDEK_LOG içinde gerçek bir çalışma satırı yok"
fi
[ -z "$r" ] && ok "Ticket 12.7 — yedek log dosyasında gerçek bir çalışma satırı var (kaynak: lab 011)" \
             || bad "Ticket 12.7 — $r (kaynak: lab 011)"

# --- 12.8 zamanlayıcı servisin günlüğü işi çalıştırdığını gösteriyor ---
r=""
journalctl -u crond.service --no-pager 2>/dev/null | grep -q 'CMD.*yedekle' ||
    r="journalctl -u crond çıktısında yedekle işini çalıştıran bir CMD kaydı yok"
[ -z "$r" ] && ok "Ticket 12.8 — zamanlayıcı servisin günlüğü işi çalıştırdığını gösteriyor (kaynak: lab 011)" \
             || bad "Ticket 12.8 — $r (kaynak: lab 011)"

# --- 12.9 temizlik.service bir kez çalışan tipte ve doğru programı çağırıyor ---
r=""
if ! known temizlik.service; then
    r="temizlik.service diye bir birim yok"
else
    t="$(prop temizlik.service Type)"
    e="$(exec_path temizlik.service)"
    [ "$t" = "oneshot" ] ||
        r="temizlik.service Type='$t', beklenen 'oneshot' (iş bir kez çalışıp biter)"
    [ "$e" = "/usr/local/bin/temizlik" ] ||
        r="${r:+$r; }temizlik.service ExecStart '$e', beklenen '/usr/local/bin/temizlik'"
    fp="$(prop temizlik.service FragmentPath)"
    case "$fp" in
        "$UNITS"/*) ;;
        *) r="${r:+$r; }temizlik.service $fp konumundan okunuyor, $UNITS altında olmalı" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 12.9 — temizlik.service bir kez çalışan tipte ve doğru programı çağırıyor (kaynak: lab 011)" \
             || bad "Ticket 12.9 — $r (kaynak: lab 011)"

# --- 12.10 temizlik.timer enabled ve kalıcı ---
r=""
if ! known temizlik.timer; then
    r="temizlik.timer diye bir birim yok"
else
    en="$(systemctl is-enabled temizlik.timer 2>/dev/null || true)"
    [ "$en" = "enabled" ] || r="temizlik.timer enabled değil (durum: ${en:-yok})"
    fp="$(prop temizlik.timer FragmentPath)"
    case "$fp" in
        "$UNITS"/*) ;;
        *) r="${r:+$r; }temizlik.timer $fp konumundan okunuyor, $UNITS altında olmalı" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 12.10 — temizlik.timer enabled (kaynak: lab 011)" \
             || bad "Ticket 12.10 — $r (kaynak: lab 011)"

# --- 12.11 temizlik.timer aktif ve tetiklemeyi bekliyor ---
r=""
a="$(systemctl is-active temizlik.timer 2>/dev/null || true)"
sub="$(prop temizlik.timer SubState)"
[ "$a" = "active" ] || r="temizlik.timer aktif değil (durum: ${a:-yok})"
case "$sub" in
    waiting|running) ;;
    *) r="${r:+$r; }temizlik.timer alt durumu '$sub', beklenen 'waiting'" ;;
esac
[ -z "$r" ] && ok "Ticket 12.11 — temizlik.timer aktif ve tetiklemeyi bekliyor (kaynak: lab 011)" \
             || bad "Ticket 12.11 — $r (kaynak: lab 011)"

# --- 12.12 temizlik.timer temizlik.service birimini tetikliyor ---
r=""
u="$(prop temizlik.timer Unit)"
[ "$u" = "temizlik.service" ] ||
    r="temizlik.timer '$u' birimini tetikliyor, beklenen 'temizlik.service'"
[ -z "$r" ] && ok "Ticket 12.12 — temizlik.timer temizlik.service birimini tetikliyor (kaynak: lab 011)" \
             || bad "Ticket 12.12 — $r (kaynak: lab 011)"

# --- 12.13 bir sonraki tetiklemeye en fazla bir dakika ---
dur_to_sec() {
    awk '{
        t = 0
        for (i = 1; i <= NF; i++) {
            f = $i
            if (!match(f, /^[0-9.]+/)) continue
            num  = substr(f, RSTART, RLENGTH)
            unit = substr(f, RSTART + RLENGTH)
            if      (unit == "y")             m = 31557600
            else if (unit == "M")             m = 2629800
            else if (unit == "w")             m = 604800
            else if (unit == "d")             m = 86400
            else if (unit == "h")             m = 3600
            else if (unit == "min" || unit == "m") m = 60
            else if (unit == "s"  || unit == "")   m = 1
            else if (unit == "ms")            m = 0.001
            else if (unit == "us")            m = 0.000001
            else                              m = 0
            t += num * m
        }
        printf "%.0f", t
    }'
}
r=""
now_mono="$(awk '{printf "%.0f", $1}' /proc/uptime 2>/dev/null)"
nm="$(prop temizlik.timer NextElapseUSecMonotonic)"
nr="$(prop temizlik.timer NextElapseUSecRealtime)"
delta=""
if [ -n "$nm" ]; then
    nm_s="$(printf '%s\n' "$nm" | dur_to_sec)"
    [ "${nm_s:-0}" -gt 0 ] && delta=$(( nm_s - now_mono ))
fi
if [ -z "$delta" ] && [ -n "$nr" ]; then
    nr_epoch="$(date -d "$nr" +%s 2>/dev/null || true)"
    [ -n "$nr_epoch" ] && delta=$(( nr_epoch - $(date +%s) ))
fi
if [ -z "$delta" ]; then
    r="temizlik.timer için bir sonraki tetikleme zamanı okunamıyor (timer kurulu mu?)"
elif [ "$delta" -gt 75 ]; then
    r="bir sonraki tetiklemeye ${delta}s var, en fazla bir dakika olmalı"
fi
[ -z "$r" ] && ok "Ticket 12.13 — temizlik.timer bir sonraki tetiklemeye en fazla bir dakika var (kaynak: lab 011)" \
             || bad "Ticket 12.13 — $r (kaynak: lab 011)"

# --- 12.14 temizlik log dosyasında gerçek bir çalışma satırı var ---
r=""
if [ ! -f "$TEMIZLIK_LOG" ]; then
    r="$TEMIZLIK_LOG yok — iş hiç çalışmamış"
elif ! grep -q 'temizlik yapildi' "$TEMIZLIK_LOG"; then
    r="$TEMIZLIK_LOG içinde gerçek bir çalışma satırı yok"
fi
[ -z "$r" ] && ok "Ticket 12.14 — temizlik log dosyasında gerçek bir çalışma satırı var (kaynak: lab 011)" \
             || bad "Ticket 12.14 — $r (kaynak: lab 011)"

# --- 12.15 sistem saat dilimi Europe/Istanbul ---
r=""
tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
[ "$tz" = "Europe/Istanbul" ] || r="sistem saat dilimi '$tz', beklenen 'Europe/Istanbul'"
[ -z "$r" ] && ok "Ticket 12.15 — sistem saat dilimi Europe/Istanbul (kaynak: lab 011)" \
             || bad "Ticket 12.15 — $r (kaynak: lab 011)"

# --- 12.16 saat dilimi kalıcı biçimde ayarlanmış ---
r=""
lt="$(readlink -f /etc/localtime 2>/dev/null || true)"
case "$lt" in
    */Europe/Istanbul) ;;
    '') r="/etc/localtime okunamıyor" ;;
    *)  r="/etc/localtime '$lt' dosyasına bakıyor, Europe/Istanbul olmalı" ;;
esac
[ -z "$r" ] && ok "Ticket 12.16 — saat dilimi kalıcı biçimde ayarlanmış (kaynak: lab 011)" \
             || bad "Ticket 12.16 — $r (kaynak: lab 011)"

# --- 12.17 chrony yapılandırmasında geçerli bir zaman sunucusu satırı ---
r=""
grep -Eq '^[[:space:]]*(pool|server)[[:space:]]+[^[:space:]#]+' /etc/chrony.conf 2>/dev/null ||
    r="/etc/chrony.conf içinde geçerli bir pool/server satırı yok"
[ -z "$r" ] && ok "Ticket 12.17 — chrony yapılandırmasında geçerli bir zaman sunucusu satırı var (kaynak: lab 011)" \
             || bad "Ticket 12.17 — $r (kaynak: lab 011)"

# --- 12.18 senkron servisi hem aktif hem enabled ---
r=""
a="$(systemctl is-active  chronyd.service 2>/dev/null || true)"
en="$(systemctl is-enabled chronyd.service 2>/dev/null || true)"
[ "$a"  = "active" ]  || r="chronyd.service aktif değil (durum: ${a:-yok})"
[ "$en" = "enabled" ] || r="${r:+$r; }chronyd.service enabled değil (durum: ${en:-yok})"
[ -z "$r" ] && ok "Ticket 12.18 — senkron servisi hem aktif hem enabled (kaynak: lab 011)" \
             || bad "Ticket 12.18 — $r (kaynak: lab 011)"

# --- 12.19 sistem saat senkronunu açık raporluyor ---
r=""
ntp="$(timedatectl show -p NTP --value 2>/dev/null || true)"
[ "$ntp" = "yes" ] || r="timedatectl NTP='$ntp', sistem saat senkronunu açık raporlamıyor"
[ -z "$r" ] && ok "Ticket 12.19 — sistem saat senkronunu açık olarak raporluyor (kaynak: lab 011)" \
             || bad "Ticket 12.19 — $r (kaynak: lab 011)"

# =============================================================================
# TICKET 13 — Nöbet devri: SSH sertleştirme ve GPG (kaynak: lab 012)
# =============================================================================
# Kriterlerin çoğu KULLANICI PERSPEKTİFİNDEN ölçülür: SSH girişi gerçekten
# denenir, GPG işlemleri student olarak koşar. Dosya izinlerine bakmak
# yetmez — StrictModes reddi yalnız gerçek bir giriş denemesinde görünür.
# Hiçbir servis başlatılmaz/durdurulmaz, hiçbir anahtar üretilmez.
section "Ticket 13 — SSH sertleştirme + GPG (lab 012)"

HOME_STUDENT=/home/student
SSH_DIR="$HOME_STUDENT/.ssh"
SSHD_CONF=/etc/ssh/sshd_config
PAKET=/opt/paket
GIZLI="$HOME_STUDENT/gizli.txt"
DUYURU="$HOME_STUDENT/duyuru.txt"
CEVAP_PAKET="$HOME_STUDENT/cevap-paket.txt"

# `sshd -T` çalışan yapılandırmanın ETKİN değerlerini basar; dosyadaki satırı
# değil. Diskteki düzeltmenin servise yansıyıp yansımadığı buradan görünür.
sshd_eff() { sshd -T 2>/dev/null | awk -v k="$1" '$1 == k {print $2; exit}'; }

# --- 13.1 .ssh dizini yalnız sahibine açık ---
r=""
if [ ! -d "$SSH_DIR" ]; then
    r="$SSH_DIR dizini yok"
else
    m="$(stat -c %a "$SSH_DIR")"
    o="$(stat -c %U "$SSH_DIR")"
    [ "$m" = "700" ] || r=".ssh izni $m, beklenen 700"
    [ "$o" = "student" ] || r="${r:+$r; }.ssh sahibi $o, beklenen student"
fi
[ -z "$r" ] && ok "Ticket 13.1 — .ssh dizini yalnız sahibine açık ve student'a ait (kaynak: lab 012)" \
             || bad "Ticket 13.1 — $r (kaynak: lab 012)"

# --- 13.2 authorized_keys doğru izinde ve anahtarı içeriyor ---
r=""
AK="$SSH_DIR/authorized_keys"
if [ ! -f "$AK" ]; then
    r="$AK yok"
else
    m="$(stat -c %a "$AK")"
    o="$(stat -c %U "$AK")"
    case "$m" in
        600|400) ;;
        *) r="authorized_keys izni $m, sahibi dışında kimse okuyamamalı (600)" ;;
    esac
    [ "$o" = "student" ] || r="${r:+$r; }authorized_keys sahibi $o, beklenen student"
    if [ -s "$SSH_DIR/id_ed25519.pub" ]; then
        body="$(awk '{print $2}' "$SSH_DIR/id_ed25519.pub")"
        grep -qF "$body" "$AK" ||
            r="${r:+$r; }authorized_keys student'ın açık anahtarını içermiyor"
    else
        r="${r:+$r; }$SSH_DIR/id_ed25519.pub yok"
    fi
fi
[ -z "$r" ] && ok "Ticket 13.2 — authorized_keys doğru izinde, student'a ait ve anahtarı içeriyor (kaynak: lab 012)" \
             || bad "Ticket 13.2 — $r (kaynak: lab 012)"

# --- 13.3 ev dizini gruba ve diğerlerine yazılabilir değil ---
r=""
m="$(stat -c %a "$HOME_STUDENT" 2>/dev/null || echo '')"
if [ -z "$m" ]; then
    r="$HOME_STUDENT okunamıyor"
elif [ $(( 8#$m & 022 )) -ne 0 ]; then
    r="ev dizini izni $m — gruba/diğerlerine yazılabilir, sshd bu durumda girişi reddeder"
fi
[ -z "$r" ] && ok "Ticket 13.3 — ev dizini gruba ve diğerlerine yazılabilir değil (kaynak: lab 012)" \
             || bad "Ticket 13.3 — $r (kaynak: lab 012)"

# --- 13.4 student parolasız, yalnız anahtarla giriş yapabiliyor ---
r=""
run_student "ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no \
    -o ConnectTimeout=10 student@localhost 'echo GIRIS_OK'"
grep -q 'GIRIS_OK' "$TMP/so" ||
    r="student anahtarla giriş yapamıyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
[ -z "$r" ] && ok "Ticket 13.4 — student parola kullanmadan yalnız anahtarla giriş yapabiliyor (kaynak: lab 012)" \
             || bad "Ticket 13.4 — $r (kaynak: lab 012)"

# --- 13.5 sshd yapılandırması sözdizimi sınamasından temiz geçiyor ---
r=""
if ! sshd -t 2>"$TMP/se"; then
    r="sshd -t hata veriyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
fi
[ -z "$r" ] && ok "Ticket 13.5 — sshd yapılandırması sözdizimi sınamasından temiz geçiyor (kaynak: lab 012)" \
             || bad "Ticket 13.5 — $r (kaynak: lab 012)"

# --- 13.6 root girişi kapalı ---
r=""
v="$(sshd_eff permitrootlogin)"
[ "$v" = "no" ] || r="PermitRootLogin etkin değeri '${v:-okunamadi}', beklenen 'no'"
[ -z "$r" ] && ok "Ticket 13.6 — root girişi kapalı (kaynak: lab 012)" \
             || bad "Ticket 13.6 — $r (kaynak: lab 012)"

# --- 13.7 parola ile giriş kapalı ---
r=""
v="$(sshd_eff passwordauthentication)"
[ "$v" = "no" ] || r="PasswordAuthentication etkin değeri '${v:-okunamadi}', beklenen 'no'"
[ -z "$r" ] && ok "Ticket 13.7 — parola ile giriş kapalı (kaynak: lab 012)" \
             || bad "Ticket 13.7 — $r (kaynak: lab 012)"

# --- 13.8 sshd ayakta ve YENİ yapılandırmayla çalışıyor ---
# Düzeltmeyi yazmak yetmez: servis eski ayarları belleğinde tutar.
r=""
a="$(systemctl is-active sshd.service 2>/dev/null || true)"
if [ "$a" != "active" ]; then
    r="sshd.service aktif değil (durum: ${a:-yok})"
else
    svc_us="$(prop sshd.service ExecMainStartTimestampMonotonic)"
    case "$svc_us" in
        ''|*[!0-9]*) r="sshd.service başlangıç zamanı okunamadı" ;;
        *)
            boot_us="$(awk '{printf "%.0f", $1 * 1000000}' /proc/uptime)"
            svc_epoch=$(( $(date +%s) - (boot_us - svc_us) / 1000000 ))
            conf_m="$(stat -c %Y "$SSHD_CONF")"
            # 1 saniyelik tolerans: monotonic → epoch çevirimi saniyeye
            # yuvarlar, düzenleme ile restart aynı saniyeye düşerse kriter
            # haksız yere düşerdi. Yakalamak istediğimiz hata ("restart
            # unutuldu") dakikalar mertebesinde, bu pencere onu kaçırmaz.
            [ "$((svc_epoch + 1))" -ge "$conf_m" ] ||
                r="sshd, yapılandırma dosyası değiştikten sonra yeniden başlatılmamış — diskteki düzeltme uygulanmamış"
            ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 13.8 — sshd servisi ayakta ve yeni yapılandırmayla çalışıyor (kaynak: lab 012)" \
             || bad "Ticket 13.8 — $r (kaynak: lab 012)"

# --- 13.9 student'ın gizli GPG anahtarı var ---
r=""
run_student "gpg --batch --list-secret-keys student@lab.local"
[ "$RC" -eq 0 ] || r="student@lab.local kimliğini taşıyan gizli anahtar bulunamadı"
[ -z "$r" ] && ok "Ticket 13.9 — student'ın gizli GPG anahtarı var ve doğru kimliği taşıyor (kaynak: lab 012)" \
             || bad "Ticket 13.9 — $r (kaynak: lab 012)"

# --- 13.10 gizli.txt.gpg student'ın anahtarına şifrelenmiş ---
r=""
if [ ! -s "$GIZLI.gpg" ]; then
    r="$GIZLI.gpg yok"
else
    run_student "gpg --batch --yes --decrypt $GIZLI.gpg"
    [ "$RC" -eq 0 ] ||
        r="$GIZLI.gpg student'ın anahtarıyla çözülemiyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
    cp "$TMP/so" "$TMP/cozulen" 2>/dev/null || true
fi
[ -z "$r" ] && ok "Ticket 13.10 — gizli.txt.gpg student'ın anahtarına şifrelenmiş (kaynak: lab 012)" \
             || bad "Ticket 13.10 — $r (kaynak: lab 012)"

# --- 13.11 şifreli dosya çözüldüğünde içerik orijinaliyle aynı ---
r=""
if [ ! -s "$GIZLI" ]; then
    r="$GIZLI yok — karşılaştırma yapılamıyor"
elif [ ! -f "$TMP/cozulen" ]; then
    r="şifreli dosya çözülemediği için içerik karşılaştırılamadı"
elif ! cmp -s "$TMP/cozulen" "$GIZLI"; then
    r="çözülen içerik $GIZLI ile aynı değil"
fi
[ -z "$r" ] && ok "Ticket 13.11 — şifreli dosya çözüldüğünde içerik orijinaliyle aynı (kaynak: lab 012)" \
             || bad "Ticket 13.11 — $r (kaynak: lab 012)"

# --- 13.12 yayıncının açık anahtarı student'ın anahtarlığında ---
r=""
run_student "gpg --batch --list-keys yayinci@lab.local"
[ "$RC" -eq 0 ] || r="yayıncının açık anahtarı student'ın anahtarlığında değil"
[ -z "$r" ] && ok "Ticket 13.12 — yayıncının açık anahtarı student'ın anahtarlığında (kaynak: lab 012)" \
             || bad "Ticket 13.12 — $r (kaynak: lab 012)"

# --- 13.13 sağlam paketin imzası student olarak doğrulanıyor ---
r=""
run_student "gpg --batch --verify $PAKET/surum-a.tar.gz.sig $PAKET/surum-a.tar.gz"
[ "$RC" -eq 0 ] ||
    r="surum-a.tar.gz imzası student olarak doğrulanamıyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
[ -z "$r" ] && ok "Ticket 13.13 — sağlam paketin imzası student olarak doğrulanıyor (kaynak: lab 012)" \
             || bad "Ticket 13.13 — $r (kaynak: lab 012)"

# --- 13.14 cevap dosyası kurcalanmış paketi doğru işaretliyor ---
r=""
if [ ! -s "$CEVAP_PAKET" ]; then
    r="$CEVAP_PAKET yok"
else
    grep -q 'surum-b' "$CEVAP_PAKET" || r="$CEVAP_PAKET kurcalanmış paketin adını içermiyor"
    grep -q 'surum-a' "$CEVAP_PAKET" &&
        r="${r:+$r; }$CEVAP_PAKET sağlam paketi de işaretlemiş, tek bir cevap bekleniyor"
fi
[ -z "$r" ] && ok "Ticket 13.14 — cevap dosyası kurcalanmış paketi doğru işaretliyor (kaynak: lab 012)" \
             || bad "Ticket 13.14 — $r (kaynak: lab 012)"

# --- 13.15 duyuru.txt ayrık imzayla imzalanmış ---
r=""
if [ ! -s "$DUYURU" ]; then
    r="$DUYURU yok"
elif [ ! -s "$DUYURU.sig" ]; then
    r="$DUYURU.sig yok — ayrık imza üretilmemiş"
else
    run_student "gpg --batch --verify $DUYURU.sig $DUYURU"
    [ "$RC" -eq 0 ] ||
        r="$DUYURU.sig doğrulanamıyor: $(tr '\n' ' ' < "$TMP/se" | tail -c 200)"
fi
[ -z "$r" ] && ok "Ticket 13.15 — duyuru.txt ayrık imzayla imzalanmış ve imza doğrulanıyor (kaynak: lab 012)" \
             || bad "Ticket 13.15 — $r (kaynak: lab 012)"

# =============================================================================
# ÖZET
# =============================================================================
flush_section
printf '\n=== ÖZET ==================================================\n'
printf '%s' "$SUMMARY"
printf '  ------------------------------------------------------\n'
printf '  %3d/%-3d  TOPLAM\n' "$TOT_OK" "$TOT_N"
if [ "$FAIL" -ne 0 ]; then
    printf '\n  Düşen kriterler yukarıda [FAIL] satırlarında listelendi.\n'
    printf '  Tüm [OK] satırlarını da görmek için:\n'
    printf '    docker exec -e CHECK_VERBOSE=1 -u root lab-900-vardiya-01b bash /lab/check.sh\n'
fi

exit "$FAIL"
