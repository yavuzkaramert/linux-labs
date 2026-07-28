#!/usr/bin/env bash
# ENV: container
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1. mkreport hiç yoksa check
# çökmez; ilgili kriterler FAIL verir ve koşu devam eder.
#
# Beklenen valid/invalid ayrımı burada BAĞIMSIZ bir referans ERE ile
# yeniden hesaplanır; öğrencinin regex'i referans alınmaz.
#
# Sıralama önemli: 1-14 arası kriterler öğrencinin bıraktığı dosyalar
# üzerinde ölçülür, mkreport blogu ONDAN SONRA gelir — çünkü mkreport
# /srv/work altını yeniden üretiyor ve ölçülecek dosyaları eziyor.
set -u

RAW=/srv/raw
WORK=/srv/work
REPORTS=/srv/reports
CONF=/etc/labs
ORIG=/srv/.orig
MKREPORT=/usr/local/bin/mkreport

FAIL=0
ok()  { echo "[OK]   $1"; }
bad() { echo "[FAIL] $1"; FAIL=1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

nlines() { [ -f "$1" ] && awk 'END {print NR + 0}' "$1" || echo 0; }

run_student() {
    : > "$TMP/so"; : > "$TMP/se"
    su - student -c "$1" > "$TMP/so" 2> "$TMP/se"
    RC=$?
}

# --- Referans hesaplar ---------------------------------------------------
# Mesaj alanı `[^|]+` — TASK "baştan sona tam olarak dört alan" diyor, yani
# `.+$` yanlış olur: beş alanlı satırı geçerli sayar. Oktetin 0-255
# aralığında olması İSTENMİYOR ("dört sayı"), o yüzden yalnız `{1,3}`.
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

normalize "$ORIG/merged.log"           > "$TMP/exp-normal"
grep -E  "$REF_ERE" "$TMP/exp-normal"  > "$TMP/exp-valid"   || true
grep -Ev "$REF_ERE" "$TMP/exp-normal"  > "$TMP/exp-invalid" || true
ozet_of "$TMP/exp-valid"               > "$TMP/exp-ozet"
REF_TOTAL="$(nlines "$ORIG/merged.log")"

# --- 1. normal.log satir sayisi merged.log ile ayni ---------------------
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
else
    g="$(nlines "$WORK/normal.log")"
    [ "$g" -eq "$REF_TOTAL" ] ||
        r="normal.log $g satır, merged.log $REF_TOTAL satır"
fi
[ -z "$r" ] && ok "normal.log satır sayısı merged.log ile aynı ($REF_TOTAL)" ||
    bad "$r"

# --- 2. GG/AA/YYYY bicimi kalmamis --------------------------------------
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
else
    n="$(grep -Ec '[0-9]{2}/[0-9]{2}/[0-9]{4}' "$WORK/normal.log" || true)"
    [ "$n" -eq 0 ] || r="normal.log içinde $n satırda GG/AA/YYYY tarih duruyor"
fi
[ -z "$r" ] && ok "normal.log içinde GG/AA/YYYY biçiminde tarih kalmamış" ||
    bad "$r"

# --- 3. Ayirici cevresinde bosluk kalmamis ------------------------------
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
else
    n="$(grep -Ec '[[:space:]]\||\|[[:space:]]' "$WORK/normal.log" || true)"
    [ "$n" -eq 0 ] ||
        r="normal.log içinde $n satırda ayırıcı çevresinde boşluk duruyor"
fi
[ -z "$r" ] && ok "normal.log içinde ayırıcı çevresinde boşluk kalmamış" ||
    bad "$r"

# --- 4. normal.log satir sirasi merged.log ile ayni ---------------------
# Referans normalleştirmeyle birebir cmp: hem içeriği hem sırayı kapsar.
r=""
if [ ! -f "$WORK/normal.log" ]; then
    r="$WORK/normal.log yok"
elif ! cmp -s "$TMP/exp-normal" "$WORK/normal.log"; then
    d="$(diff "$TMP/exp-normal" "$WORK/normal.log" | head -1)"
    r="normal.log beklenen normalleştirmeyle birebir aynı değil (ilk fark: ${d:-?})"
fi
[ -z "$r" ] && ok "normal.log satır sırası merged.log ile aynı" || bad "$r"

# --- 5. valid.log yalniz dort alanli tam eslesen satirlari iceriyor -----
r=""
if [ ! -f "$WORK/valid.log" ]; then
    r="$WORK/valid.log yok"
elif ! cmp -s "$TMP/exp-valid" "$WORK/valid.log"; then
    e="$(nlines "$TMP/exp-valid")"; g="$(nlines "$WORK/valid.log")"
    r="valid.log referans ayrımla uyuşmuyor (beklenen $e, gelen $g satır)"
fi
[ -z "$r" ] && ok "valid.log yalnız dört alanlı, tam eşleşen satırları içeriyor" ||
    bad "$r"

# --- 6. valid.log icinde gecersiz seviye ya da ip yok -------------------
# 5. kriterden bağımsız: "fazla satır aldı mı" ile "aldıklarının hepsi
# biçime uyuyor mu" farklı sorular. Bu kriter yalnız ikincisine bakar.
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
[ -z "$r" ] && ok "valid.log içinde geçersiz seviye ya da geçersiz ip yok" ||
    bad "$r"

# --- 7. invalid.log geri kalan satirlarin hepsini iceriyor --------------
r=""
if [ ! -f "$WORK/invalid.log" ]; then
    r="$WORK/invalid.log yok"
elif ! cmp -s "$TMP/exp-invalid" "$WORK/invalid.log"; then
    e="$(nlines "$TMP/exp-invalid")"; g="$(nlines "$WORK/invalid.log")"
    r="invalid.log referans ayrımla uyuşmuyor (beklenen $e, gelen $g satır)"
fi
[ -z "$r" ] && ok "invalid.log geri kalan satırların hepsini içeriyor" || bad "$r"

# --- 8. valid + invalid = normal ---------------------------------------
# Öğrencinin KENDİ dosyaları üzerinden: hiçbir satır ne kayboldu ne çoğaldı.
r=""
if [ ! -f "$WORK/valid.log" ] || [ ! -f "$WORK/invalid.log" ] ||
   [ ! -f "$WORK/normal.log" ]; then
    r="valid.log / invalid.log / normal.log üçlüsü tam değil, toplam alınamıyor"
else
    v="$(nlines "$WORK/valid.log")"
    i="$(nlines "$WORK/invalid.log")"
    n="$(nlines "$WORK/normal.log")"
    [ $((v + i)) -eq "$n" ] ||
        r="valid ($v) + invalid ($i) = $((v + i)), normal.log $n satır"
fi
[ -z "$r" ] && ok "valid.log ve invalid.log satır toplamı normal.log'a eşit" ||
    bad "$r"

# --- 9. ozet.txt her seviye icin tek satir ve uc alan -------------------
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
[ -z "$r" ] && ok "ozet.txt her seviye için tek satır ve üç alan içeriyor" ||
    bad "$r"

# --- 10. ozet.txt toplam sayilari ---------------------------------------
r=""
if [ ! -f "$WORK/ozet.txt" ]; then
    r="$WORK/ozet.txt yok, toplamlar karşılaştırılamıyor"
else
    awk '{print $1, $2}' "$WORK/ozet.txt" | sort > "$TMP/got-tot"
    awk '{print $1, $2}' "$TMP/exp-ozet"  | sort > "$TMP/exp-tot"
    cmp -s "$TMP/exp-tot" "$TMP/got-tot" ||
        r="ozet.txt toplam sayıları yanlış (beklenen: $(tr '\n' ' ' < "$TMP/exp-tot"))"
fi
[ -z "$r" ] && ok "ozet.txt toplam sayıları valid.log ile uyuşuyor" || bad "$r"

# --- 11. ozet.txt tekil ip sayilari -------------------------------------
# Tuzak burada ısırır: bazı geçerli satırların MESAJINDA da IP geçiyor.
# IP'leri satırın tamamından toplayan çözüm fazla sayar.
r=""
if [ ! -f "$WORK/ozet.txt" ]; then
    r="$WORK/ozet.txt yok, tekil ip sayıları karşılaştırılamıyor"
else
    awk '{print $1, $3}' "$WORK/ozet.txt" | sort > "$TMP/got-uip"
    awk '{print $1, $3}' "$TMP/exp-ozet"  | sort > "$TMP/exp-uip"
    cmp -s "$TMP/exp-uip" "$TMP/got-uip" ||
        r="ozet.txt tekil ip sayıları yanlış (beklenen: $(tr '\n' ' ' < "$TMP/exp-uip")) — ip yalnız 3. alandan sayılır, mesaj alanından değil"
fi
[ -z "$r" ] && ok "ozet.txt tekil ip sayıları doğru" || bad "$r"

# --- 12. report.conf: ^# satirlari gitti, satir ortasindaki # kaldi ----
r=""
if [ ! -f "$CONF/report.conf" ]; then
    r="$CONF/report.conf yok"
else
    left="$(grep -c '^#' "$CONF/report.conf" || true)"
    del="$(grep -c '^#' "$ORIG/report.conf" || true)"
    exp_n=$(( $(nlines "$ORIG/report.conf") - del ))
    got_n="$(nlines "$CONF/report.conf")"
    # Satır ortasında `#` geçen satırlar SİLİNMEMELİ: çapasız kalıbın izi.
    missing=""
    while IFS= read -r line; do
        grep -qxF -- "$line" "$CONF/report.conf" || missing="$line"
    done < <(grep -v '^#' "$ORIG/report.conf" | grep '#' || true)
    if [ "$left" -ne 0 ]; then
        r="report.conf içinde # ile başlayan $left satır duruyor"
    elif [ -n "$missing" ]; then
        r="satır ortasında # geçen satır da silinmiş (çapasız kalıp): $missing"
    elif [ "$got_n" -ne "$exp_n" ]; then
        r="report.conf $got_n satır, beklenen $exp_n ($del yorum satırı silinecekti)"
    fi
fi
[ -z "$r" ] && ok "report.conf içinde # ile başlayan satır kalmamış" || bad "$r"

# --- 13. /opt/eski -> /srv/work -----------------------------------------
# Satır sayısı değil GEÇİŞ sayısı sayılır: bir satırda iki kez geçiyor,
# eksik `g` bayrağı buradan yakalanır.
r=""
if [ ! -f "$CONF/report.conf" ]; then
    r="$CONF/report.conf yok"
else
    ref_hits="$(grep -o '/opt/eski' "$ORIG/report.conf" | wc -l | tr -d ' ')"
    left="$(grep -c '/opt/eski' "$CONF/report.conf" || true)"
    hits="$(grep -o '/srv/work' "$CONF/report.conf" | wc -l | tr -d ' ')"
    if [ "$left" -ne 0 ]; then
        r="report.conf içinde /opt/eski geçen $left satır duruyor"
    elif [ "$hits" -ne "$ref_hits" ]; then
        r="/srv/work $hits kez geçiyor, beklenen $ref_hits (satır içindeki ikinci eşleşme kaçmış olabilir)"
    fi
fi
[ -z "$r" ] && ok "report.conf içinde /opt/eski geçmiyor, hepsi /srv/work olmuş" ||
    bad "$r"

# --- 14. retention = 30 -------------------------------------------------
# Boşluk toleranslı: `retention=30` da `retention = 30` da kabul.
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
[ -z "$r" ] && ok "report.conf retention değeri 30" || bad "$r"

# --- 15. mkreport student tarafindan sudo'suz calisiyor ----------------
# MK_OK, 16-18 arası kriterlerin kapısı: mkreport hiç çalışmadıysa onlar
# FAIL verir ama check çökmez. DIRTY_* önden tanımlı, `set -u` altında
# 17. kriter tanımsız değişkene çarpmasın.
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
[ -z "$r" ] && ok "mkreport student tarafından sudo'suz çalıştırılıyor" || bad "$r"

# --- 16. text-report.txt ilk satiri DIRTY/CLEAN ve dogru --------------
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
        DIRTY) [ "$inv" -gt 0 ] ||
                   r="ilk satır DIRTY ama invalid.log boş" ;;
        CLEAN) [ "$inv" -eq 0 ] ||
                   r="ilk satır CLEAN ama invalid.log $inv satır" ;;
        *)     r="raporun ilk satırı '$DIRTY_FIRST', DIRTY ya da CLEAN olmalı" ;;
    esac
fi
[ -z "$r" ] && ok "text-report.txt ilk satırı DIRTY/CLEAN ve doğru" || bad "$r"

# --- 17. mkreport cikis kodu ilk satirla tutarli ----------------------
# İki yol da sınanır. DIRTY doğal durumdur. CLEAN için geçici olarak
# yalnız geçerli satırlardan oluşan bir merged.log konur; sonra ortam
# ESKİ HÂLİNE geri alınır ve DIRTY durumuna dönülür.
r=""
if [ "$MK_OK" -eq 0 ]; then
    r="mkreport çalıştırılamadığı için çıkış kodu sınanamıyor"
else
    if [ "$DIRTY_FIRST" = "DIRTY" ] && [ "$DIRTY_RC" -ne 1 ]; then
        r="DIRTY raporda çıkış kodu $DIRTY_RC, 1 olmalı"
    elif [ "$DIRTY_FIRST" = "CLEAN" ] && [ "$DIRTY_RC" -ne 0 ]; then
        r="CLEAN raporda çıkış kodu $DIRTY_RC, 0 olmalı"
    fi

    # CLEAN yolu
    cp "$TMP/exp-valid" "$TMP/clean-merged"
    chmod 0644 "$RAW/merged.log"
    cp "$TMP/clean-merged" "$RAW/merged.log"
    chmod 0444 "$RAW/merged.log"
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
    chmod 0644 "$RAW/merged.log"
    cp "$ORIG/merged.log" "$RAW/merged.log"
    chown root:root "$RAW/merged.log"
    chmod 0444 "$RAW/merged.log"
    rm -f "$WORK/normal.log" "$WORK/valid.log" "$WORK/invalid.log" \
          "$WORK/ozet.txt" "$REPORTS/text-report.txt"
    run_student 'mkreport'
fi
[ -z "$r" ] && ok "mkreport çıkış kodu raporun ilk satırıyla tutarlı (DIRTY ve CLEAN)" ||
    bad "$r"

# --- 18. Iki kez calistirilinca rapor buyumez -------------------------
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
[ -z "$r" ] && ok "mkreport iki kez çalıştırıldığında rapor büyümüyor" || bad "$r"

# --- 19. merged.log degismemis (korkuluk) -----------------------------
# Taze ortamda doğal olarak sağlanır; kasıtlı istisna. Amacı ödül değil,
# yan hasarı yakalamak. 17. kriterin geçici takasından sonra geri
# yüklemenin de doğru yapıldığını doğrular.
r=""
if [ ! -f "$RAW/merged.log" ]; then
    r="merged.log silinmiş"
elif ! cmp -s "$ORIG/merged.log" "$RAW/merged.log"; then
    r="merged.log değiştirilmiş"
fi
[ -z "$r" ] && ok "merged.log değiştirilmemiş" || bad "$r"

exit "$FAIL"
