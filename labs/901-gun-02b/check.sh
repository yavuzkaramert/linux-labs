#!/usr/bin/env bash
# ENV: container-systemd
# Root olarak çalışır. Accumulator pattern: `set -e` YOK, her kriter bağımsız
# değerlendirilir, FAIL varsa sonunda exit 1.
#
# Bu bir TEKRAR labı: her satır hangi kaynak lab'dan geldiğini söyler.
# Biçim:  [OK]   Ticket 8.3 — açıklama (kaynak: lab 007b)
#
# Beklenen değerlerin hiçbiri sabit yazılmaz; hepsi /srv/.orig altındaki
# orijinal kopyalardan ya da canlı sistemden türetilir.
set -u

KLINIK=/srv/klinik
TALEP="$KLINIK/talepler"
LOGLAR="$KLINIK/loglar"
IS="$KLINIK/is"
PKGDIR="$KLINIK/paketler"
CONF=/etc/klinik
ORIG=/srv/.orig
ANS=/home/student/cevaplar
BINDIR=/usr/local/bin
UNITS=/etc/systemd/system
PAKET=/opt/paket
STUDENT=student
HOME_STUDENT=/home/student
SSH_DIR="$HOME_STUDENT/.ssh"
SSHD_CONF=/etc/ssh/sshd_config

FAIL=0

# --- Çıktı biçimi ------------------------------------------------------------
# 104 kriterin hepsini tek tek basmak okunmuyor. Varsayılan kip GRUPLU: her
# ticket için bir başlık, altında YALNIZ düşen kriterler, sonda özet tablosu.
#
# Tüm [OK] satırlarını görmek için:
#   docker exec -e CHECK_VERBOSE=1 -u root lab-901-gun-02b bash /lab/check.sh
VERBOSE="${CHECK_VERBOSE:-0}"

SEC=""; SEC_OK=0; SEC_N=0; SUMMARY=""; TOT_OK=0; TOT_N=0

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
ok()   { SEC_N=$((SEC_N + 1)); SEC_OK=$((SEC_OK + 1))
         [ "$VERBOSE" = "1" ] && echo "[OK]   $1"
         return 0; }
bad()  { SEC_N=$((SEC_N + 1)); echo "[FAIL] $1"; FAIL=1; return 0; }

TMP="$(mktemp -d)"
chmod 0755 "$TMP"
trap 'rm -rf "$TMP"' EXIT

nlines()     { [ -f "$1" ] && awk 'END {print NR + 0}' "$1" || echo 0; }
one_value()  { [ -f "$1" ] && tr -d '[:space:]' < "$1" || echo ""; }
as_student() { su - "$STUDENT" -c "$1"; }
prop()       { systemctl show "$1" -p "$2" --value 2>/dev/null; }

# ExecStart struct'ından yalnız program yolunu çeker.
exec_path() {
    systemctl show "$1" -p ExecStart --value 2>/dev/null \
        | sed -n 's/.*path=\([^ ;]*\).*/\1/p' | head -1
}

# systemd süre-zaman property'leri "4d 14h 51min 4.501888s" biçiminde döner;
# ham mikrosaniye DEĞİL. Sayı sanıp aritmetiğe sokmak sessizce boş sonuç verir.
dur_to_sec() {
    printf '%s' "$1" | awk '
    {
        t = 0
        n = split($0, a, /[[:space:]]+/)
        for (i = 1; i <= n; i++) {
            if (a[i] ~ /^[0-9.]+d$/)          { sub(/d$/, "", a[i]);   t += a[i] * 86400 }
            else if (a[i] ~ /^[0-9.]+h$/)     { sub(/h$/, "", a[i]);   t += a[i] * 3600 }
            else if (a[i] ~ /^[0-9.]+min$/)   { sub(/min$/, "", a[i]); t += a[i] * 60 }
            else if (a[i] ~ /^[0-9.]+m?s$/)   { sub(/m?s$/, "", a[i]); t += a[i] }
        }
        printf "%d", t
    }'
}

SO="$TMP/so"; SE="$TMP/se"
run_student() { as_student "$1" > "$SO" 2> "$SE"; echo $?; }

# =============================================================================
section "Ticket 7 — Destek talepleri dökümü (kaynak: lab 007a)"
# =============================================================================
OCSV="$ORIG/talepler.csv"
REF_ADET="$(tail -n +2 "$OCSV" 2>/dev/null | wc -l | tr -d ' ')"
awk -F';' 'NR > 1 && $4 == "open"' "$OCSV" > "$TMP/exp-acik" 2>/dev/null
awk -F';' 'NR > 1 {print $3}' "$OCSV" 2>/dev/null | sort | uniq -c \
    | awk '{print $1, $2}' | sort > "$TMP/exp-oncelik"
# Konu alanında "open" geçen ama durumu open OLMAYAN talepler: tuzak.
awk -F';' 'NR > 1 && $4 != "open" && $6 ~ /open/ {print $1}' "$OCSV" \
    > "$TMP/tuzak-id" 2>/dev/null

# --- 7.1 01-adet.txt tek satır, yalnız sayı ---
r=""
f="$ANS/01-adet.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(nlines "$f")" -ne 1 ]; then
    r="tek satir olmali (su an: $(nlines "$f"))"
else
    v="$(one_value "$f")"
    case "$v" in ''|*[!0-9]*) r="yalniz sayi olmali (su an: '$v')" ;; esac
fi
[ -z "$r" ] && ok "Ticket 7.1 — 01-adet.txt tek satir ve yalniz sayi (kaynak: lab 007a)" \
           || bad "Ticket 7.1 — $r (kaynak: lab 007a)"

# --- 7.2 01-adet.txt değeri veri satırı sayısına eşit (başlık hariç) ---
r=""
v="$(one_value "$ANS/01-adet.txt")"
[ "$v" = "$REF_ADET" ] || \
    r="veri satiri sayisi $REF_ADET olmaliydi (su an: '$v') — baslik satiri sayilmaz"
[ -z "$r" ] && ok "Ticket 7.2 — 01-adet.txt dogru veri satiri sayisini veriyor (kaynak: lab 007a)" \
           || bad "Ticket 7.2 — $r (kaynak: lab 007a)"

# --- 7.3 02-acik.txt yalnız durumu open olan tam satırlar ---
r=""
f="$ANS/02-acik.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    sort "$TMP/exp-acik" > "$TMP/exp-acik-s"
    sort "$f" > "$TMP/got-acik-s"
    cmp -s "$TMP/exp-acik-s" "$TMP/got-acik-s" || \
        r="acik talep kumesi tutmuyor (beklenen $(nlines "$TMP/exp-acik") satir, bulunan $(nlines "$f"))"
fi
[ -z "$r" ] && ok "Ticket 7.3 — 02-acik.txt yalniz durumu open olan talepleri iceriyor (kaynak: lab 007a)" \
           || bad "Ticket 7.3 — $r (kaynak: lab 007a)"

# --- 7.4 02-acik.txt tuzak taleplerini İÇERMİYOR ---
r=""
f="$ANS/02-acik.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    while IFS= read -r tid; do
        [ -n "$tid" ] || continue
        if grep -q "^$tid;" "$f" 2>/dev/null; then
            r="$tid raporda — durumu open DEGIL, yalniz konu alaninda 'open' geciyor"
            break
        fi
    done < "$TMP/tuzak-id"
fi
[ -z "$r" ] && ok "Ticket 7.4 — 02-acik.txt konu alani tuzagina dusmemis (kaynak: lab 007a)" \
           || bad "Ticket 7.4 — $r (kaynak: lab 007a)"

# --- 7.5 02-acik.txt sırası orijinalle aynı ---
r=""
f="$ANS/02-acik.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif ! cmp -s "$TMP/exp-acik" "$f"; then
    r="satir sirasi orijinal dosyadaki sirayla ayni degil"
fi
[ -z "$r" ] && ok "Ticket 7.5 — 02-acik.txt orijinal sirayi koruyor (kaynak: lab 007a)" \
           || bad "Ticket 7.5 — $r (kaynak: lab 007a)"

# --- 7.6 03-oncelik.txt her satır iki alan, öncelik başına tek satır ---
r=""
f="$ANS/03-oncelik.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(awk 'NF && NF != 2' "$f" | wc -l)" -ne 0 ]; then
    r="her satir 'sayi oncelik' biciminde iki alan olmali"
elif [ "$(awk 'NF {print $2}' "$f" | sort -u | wc -l)" -ne "$(nlines "$TMP/exp-oncelik")" ]; then
    r="her oncelik icin tam bir satir olmali (beklenen $(nlines "$TMP/exp-oncelik") oncelik)"
fi
[ -z "$r" ] && ok "Ticket 7.6 — 03-oncelik.txt her oncelik icin tek satir, iki alan (kaynak: lab 007a)" \
           || bad "Ticket 7.6 — $r (kaynak: lab 007a)"

# --- 7.7 03-oncelik.txt sayımları doğru (sıra önemsiz) ---
r=""
f="$ANS/03-oncelik.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    awk 'NF {print $1, $2}' "$f" | sort > "$TMP/got-oncelik"
    cmp -s "$TMP/exp-oncelik" "$TMP/got-oncelik" || \
        r="oncelik dagilimi tutmuyor (beklenen: $(tr '\n' ' ' < "$TMP/exp-oncelik"))"
fi
[ -z "$r" ] && ok "Ticket 7.7 — 03-oncelik.txt oncelik dagilimini dogru veriyor (kaynak: lab 007a)" \
           || bad "Ticket 7.7 — $r (kaynak: lab 007a)"

# --- 7.8 04-kod.txt: geçen bir kelimenin arama çıkış kodu = 0 ---
r=""
v="$(one_value "$ANS/04-kod.txt")"
if [ ! -f "$ANS/04-kod.txt" ]; then
    r="$ANS/04-kod.txt yok"
elif [ "$v" != "0" ]; then
    r="ENGELLENDI erisim.log icinde GECIYOR, arama cikis kodu 0 olmaliydi (su an: '$v')"
fi
[ -z "$r" ] && ok "Ticket 7.8 — 04-kod.txt gecen kelimenin cikis kodunu (0) veriyor (kaynak: lab 007a)" \
           || bad "Ticket 7.8 — $r (kaynak: lab 007a)"

# --- 7.9 05-kod.txt: hiç geçmeyen bir kelimenin çıkış kodu = 1 ---
r=""
v="$(one_value "$ANS/05-kod.txt")"
if [ ! -f "$ANS/05-kod.txt" ]; then
    r="$ANS/05-kod.txt yok"
elif [ "$v" != "1" ]; then
    r="hic gecmeyen kelime icin arama cikis kodu 1 olmaliydi (su an: '$v')"
fi
[ -z "$r" ] && ok "Ticket 7.9 — 05-kod.txt gecmeyen kelimenin cikis kodunu (1) veriyor (kaynak: lab 007a)" \
           || bad "Ticket 7.9 — $r (kaynak: lab 007a)"

# --- 7.10 notlar.txt: ^TODO satırları silinmiş, satır içi TODO korunmuş ---
r=""
f="$TALEP/notlar.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(grep -c '^TODO' "$f" || true)" -ne 0 ]; then
    r="hala ^TODO ile baslayan satir var"
elif [ "$(grep -c 'TODO' "$f" || true)" -eq 0 ]; then
    r="satir ICINDE TODO gecen satir da silinmis — yalniz basta olanlar silinecekti"
fi
[ -z "$r" ] && ok "Ticket 7.10 — notlar.txt: bastaki TODO satirlari silindi, satir ici korundu (kaynak: lab 007a)" \
           || bad "Ticket 7.10 — $r (kaynak: lab 007a)"

# --- 7.11 notlar.txt: sube1 -> merkez-sube, TÜM geçişler ---
r=""
f="$TALEP/notlar.txt"
REF_HIT="$(grep -o 'sube1' "$ORIG/notlar.txt" 2>/dev/null | wc -l | tr -d ' ')"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    kalan="$(grep -o 'sube1' "$f" 2>/dev/null | wc -l | tr -d ' ')"
    yeni="$(grep -o 'merkez-sube' "$f" 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$kalan" -ne 0 ]; then
        r="hala $kalan adet sube1 var — bir satirda IKI kez geciyor, genel degistirme gerekiyor"
    elif [ "$yeni" -ne "$REF_HIT" ]; then
        r="merkez-sube $REF_HIT kez gecmeliydi (su an: $yeni)"
    fi
fi
[ -z "$r" ] && ok "Ticket 7.11 — notlar.txt: tum sube1 gecisleri merkez-sube oldu (kaynak: lab 007a)" \
           || bad "Ticket 7.11 — $r (kaynak: lab 007a)"

# --- 7.12 notlar.txt başka türlü değişmemiş ---
r=""
sed '/^TODO/d; s/sube1/merkez-sube/g' "$ORIG/notlar.txt" > "$TMP/exp-notlar" 2>/dev/null
cmp -s "$TMP/exp-notlar" "$TALEP/notlar.txt" 2>/dev/null || \
    r="dosyada istenenden baska degisiklikler var"
[ -z "$r" ] && ok "Ticket 7.12 — notlar.txt yalnizca istenen iki degisikligi tasiyor (kaynak: lab 007a)" \
           || bad "Ticket 7.12 — $r (kaynak: lab 007a)"

# --- 7.13 talepler.csv ve erisim.log DOKUNULMAMIŞ ---
r=""
for f in talepler.csv erisim.log; do
    cmp -s "$ORIG/$f" "$TALEP/$f" || { r="$f degistirilmis — bu iki dosyaya dokunulmayacakti"; break; }
done
[ -z "$r" ] && ok "Ticket 7.13 — talepler.csv ve erisim.log degistirilmemis (kaynak: lab 007a)" \
           || bad "Ticket 7.13 — $r (kaynak: lab 007a)"

# =============================================================================
section "Ticket 8 — Karışık log'u temizle ve otomatik rapor kur (kaynak: lab 007b)"
# =============================================================================
# ÖNEMLİ: Öğrencinin ÜRETTİĞİ dosyalar ÖNCE ölçülür, rapor-uret SONRA koşar.
# rapor-uret bu dosyaları yeniden ürettiği için sıra tersine dönerse öğrencinin
# kendi işi hiç ölçülmemiş olur.
OKAR="$ORIG/karisik.log"
REF_ERE='^[0-9]{4}-[0-9]{2}-[0-9]{2}\|(INFO|WARN|ERROR)\|([0-9]{1,3}\.){3}[0-9]{1,3}\|[^|]+$'

normalize() {
    sed -E 's#([0-9]{2})/([0-9]{2})/([0-9]{4})#\3-\2-\1#g; s#[[:space:]]*\|[[:space:]]*#|#g' "$1"
}
normalize "$OKAR" > "$TMP/exp-duzenli" 2>/dev/null
grep -E  "$REF_ERE" "$TMP/exp-duzenli" > "$TMP/exp-gecerli"  2>/dev/null || true
grep -Ev "$REF_ERE" "$TMP/exp-duzenli" > "$TMP/exp-gecersiz" 2>/dev/null || true
REF_TOTAL="$(nlines "$TMP/exp-duzenli")"

ozet_of() {
    awk -F'|' '
    {
        n[$2]++
        if (!seen[$2 SUBSEP $3]++) u[$2]++
    }
    END { for (l in n) printf "%s %d %d\n", l, n[l], u[l] }' "$1" | sort
}
ozet_of "$TMP/exp-gecerli" > "$TMP/exp-ozet"

# --- 8.1 duzenli.log satır sayısı karisik.log ile aynı ---
r=""
n="$(nlines "$IS/duzenli.log")"
if [ ! -f "$IS/duzenli.log" ]; then
    r="$IS/duzenli.log yok"
elif [ "$n" -ne "$REF_TOTAL" ]; then
    r="satir sayisi $REF_TOTAL olmaliydi (su an: $n) — hicbir satir silinmeyecek"
fi
[ -z "$r" ] && ok "Ticket 8.1 — duzenli.log satir sayisi karisik.log ile ayni (kaynak: lab 007b)" \
           || bad "Ticket 8.1 — $r (kaynak: lab 007b)"

# --- 8.2 duzenli.log'da GG/AA/YYYY biçimli tarih kalmamış ---
r=""
if [ ! -f "$IS/duzenli.log" ]; then
    r="$IS/duzenli.log yok"
elif [ "$(grep -Ec '[0-9]{2}/[0-9]{2}/[0-9]{4}' "$IS/duzenli.log" || true)" -ne 0 ]; then
    r="hala GG/AA/YYYY bicimli tarih var"
fi
[ -z "$r" ] && ok "Ticket 8.2 — duzenli.log'da eski tarih bicimi kalmamis (kaynak: lab 007b)" \
           || bad "Ticket 8.2 — $r (kaynak: lab 007b)"

# --- 8.3 duzenli.log'da ayraç çevresinde boşluk yok ---
r=""
if [ ! -f "$IS/duzenli.log" ]; then
    r="$IS/duzenli.log yok"
elif [ "$(grep -Ec '[[:space:]]\||\|[[:space:]]' "$IS/duzenli.log" || true)" -ne 0 ]; then
    r="ayrac cevresinde hala bosluk var"
fi
[ -z "$r" ] && ok "Ticket 8.3 — duzenli.log'da ayrac cevresi temiz (kaynak: lab 007b)" \
           || bad "Ticket 8.3 — $r (kaynak: lab 007b)"

# --- 8.4 duzenli.log içerik ve sıra olarak doğru ---
r=""
cmp -s "$TMP/exp-duzenli" "$IS/duzenli.log" 2>/dev/null || \
    r="normalizasyon sonucu beklenenle ayni degil (icerik veya sira)"
[ -z "$r" ] && ok "Ticket 8.4 — duzenli.log icerigi ve sirasi dogru (kaynak: lab 007b)" \
           || bad "Ticket 8.4 — $r (kaynak: lab 007b)"

# --- 8.5 gecerli.log tam 4 alanlı, alanları eşleşen satırlar ---
r=""
cmp -s "$TMP/exp-gecerli" "$IS/gecerli.log" 2>/dev/null || \
    r="gecerli satir kumesi tutmuyor (beklenen $(nlines "$TMP/exp-gecerli"), bulunan $(nlines "$IS/gecerli.log"))"
[ -z "$r" ] && ok "Ticket 8.5 — gecerli.log dogru satirlari iceriyor (kaynak: lab 007b)" \
           || bad "Ticket 8.5 — $r (kaynak: lab 007b)"

# --- 8.6 gecerli.log içinde geçersiz satır yok ---
r=""
if [ ! -f "$IS/gecerli.log" ]; then
    r="$IS/gecerli.log yok"
elif [ "$(grep -Evc "$REF_ERE" "$IS/gecerli.log" || true)" -ne 0 ]; then
    r="gecerli.log icinde kaliba uymayan satir var — cipa (^ ve \$) olmadan bastaki serbest metin kacar"
fi
[ -z "$r" ] && ok "Ticket 8.6 — gecerli.log'da kaliba uymayan satir yok (kaynak: lab 007b)" \
           || bad "Ticket 8.6 — $r (kaynak: lab 007b)"

# --- 8.7 gecersiz.log geri kalan her şeyi içeriyor ---
r=""
cmp -s "$TMP/exp-gecersiz" "$IS/gecersiz.log" 2>/dev/null || \
    r="gecersiz satir kumesi tutmuyor (beklenen $(nlines "$TMP/exp-gecersiz"), bulunan $(nlines "$IS/gecersiz.log"))"
[ -z "$r" ] && ok "Ticket 8.7 — gecersiz.log geri kalan satirlari iceriyor (kaynak: lab 007b)" \
           || bad "Ticket 8.7 — $r (kaynak: lab 007b)"

# --- 8.8 gecerli + gecersiz = duzenli ---
r=""
v="$(nlines "$IS/gecerli.log")"; i="$(nlines "$IS/gecersiz.log")"
n="$(nlines "$IS/duzenli.log")"
[ $(( v + i )) -eq "$n" ] || \
    r="gecerli ($v) + gecersiz ($i) toplami duzenli.log ($n) ile esit degil"
[ -z "$r" ] && ok "Ticket 8.8 — gecerli ve gecersiz toplami duzenli.log'a esit (kaynak: lab 007b)" \
           || bad "Ticket 8.8 — $r (kaynak: lab 007b)"

# --- 8.9 asi-ozet.txt her satır üç alan ---
r=""
f="$IS/asi-ozet.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(awk 'NF && (NF != 3 || $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/)' "$f" | wc -l)" -ne 0 ]; then
    r="her satir 'seviye toplam tekil-ip' biciminde uc alan olmali"
fi
[ -z "$r" ] && ok "Ticket 8.9 — asi-ozet.txt her satiri uc alanli (kaynak: lab 007b)" \
           || bad "Ticket 8.9 — $r (kaynak: lab 007b)"

# --- 8.10 asi-ozet.txt seviye adları gecerli.log ile aynı ---
r=""
f="$IS/asi-ozet.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    awk 'NF {print $1}' "$f" | sort -u > "$TMP/got-sev"
    awk 'NF {print $1}' "$TMP/exp-ozet" | sort -u > "$TMP/exp-sev"
    cmp -s "$TMP/exp-sev" "$TMP/got-sev" || \
        r="seviye kumesi gecerli.log ile ayni degil (beklenen: $(tr '\n' ' ' < "$TMP/exp-sev"))"
fi
[ -z "$r" ] && ok "Ticket 8.10 — asi-ozet.txt seviye adlari gecerli.log ile ayni (kaynak: lab 007b)" \
           || bad "Ticket 8.10 — $r (kaynak: lab 007b)"

# --- 8.11 asi-ozet.txt toplamları doğru ---
r=""
f="$IS/asi-ozet.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    awk 'NF {print $1, $2}' "$f" | sort > "$TMP/got-tot"
    awk 'NF {print $1, $2}' "$TMP/exp-ozet" | sort > "$TMP/exp-tot"
    cmp -s "$TMP/exp-tot" "$TMP/got-tot" || \
        r="seviye toplamlari gecerli.log ile uyusmuyor (mesaj alaninda gecen seviye adlari tuzak)"
fi
[ -z "$r" ] && ok "Ticket 8.11 — asi-ozet.txt toplamlari gecerli.log ile uyusuyor (kaynak: lab 007b)" \
           || bad "Ticket 8.11 — $r (kaynak: lab 007b)"

# --- 8.12 asi-ozet.txt tekil IP sayıları doğru ---
r=""
f="$IS/asi-ozet.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    awk 'NF {print $1, $3}' "$f" | sort > "$TMP/got-uip"
    awk 'NF {print $1, $3}' "$TMP/exp-ozet" | sort > "$TMP/exp-uip"
    cmp -s "$TMP/exp-uip" "$TMP/got-uip" || \
        r="tekil IP sayilari uyusmuyor — mesaj alaninda gecen adresler sayilmamali"
fi
[ -z "$r" ] && ok "Ticket 8.12 — asi-ozet.txt tekil IP sayilari dogru (kaynak: lab 007b)" \
           || bad "Ticket 8.12 — $r (kaynak: lab 007b)"

# --- 8.13 klinik-ayarlar.conf: ^# yorumlar silinmiş, satır içi # korunmuş ---
r=""
f="$CONF/klinik-ayarlar.conf"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(grep -c '^[[:space:]]*#' "$f" || true)" -ne 0 ]; then
    r="hala # ile baslayan yorum satiri var"
elif [ "$(grep -c '#' "$f" || true)" -eq 0 ]; then
    r="satir ICINDE # gecen satirlar da silinmis — yalniz bastakiler silinecekti"
fi
[ -z "$r" ] && ok "Ticket 8.13 — klinik-ayarlar.conf yorum satirlarindan arindirilmis (kaynak: lab 007b)" \
           || bad "Ticket 8.13 — $r (kaynak: lab 007b)"

# --- 8.14 /opt/eskisistem -> /srv/klinik/veri, TÜM geçişler ---
r=""
f="$CONF/klinik-ayarlar.conf"
REF_ESKI="$(grep -o '/opt/eskisistem' "$ORIG/klinik-ayarlar.conf" 2>/dev/null | wc -l | tr -d ' ')"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    kalan="$(grep -o '/opt/eskisistem' "$f" 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$kalan" -ne 0 ]; then
        r="hala $kalan adet /opt/eskisistem var — bir satirda IKI kez geciyor"
    fi
fi
[ -z "$r" ] && ok "Ticket 8.14 — tum /opt/eskisistem gecisleri degistirilmis (kaynak: lab 007b)" \
           || bad "Ticket 8.14 — $r (kaynak: lab 007b)"

# --- 8.15 retention = 45 ---
r=""
f="$CONF/klinik-ayarlar.conf"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    v="$(awk -F'=' '/^[[:space:]]*retention[[:space:]]*=/ {gsub(/[[:space:]]/, "", $2); print $2; exit}' "$f")"
    [ "$v" = "45" ] || r="retention degeri 45 olmaliydi (su an: '$v')"
fi
[ -z "$r" ] && ok "Ticket 8.15 — klinik-ayarlar.conf retention degeri 45 (kaynak: lab 007b)" \
           || bad "Ticket 8.15 — $r (kaynak: lab 007b)"

# --- 8.16 rapor-uret student tarafından sudo'suz çalıştırılabiliyor ---
r=""
if [ ! -f "$BINDIR/rapor-uret" ]; then
    r="$BINDIR/rapor-uret yok"
elif ! as_student "command -v rapor-uret" >/dev/null 2>&1; then
    r="rapor-uret student'in PATH'inde bulunamiyor"
else
    rc="$(run_student "rapor-uret")"
    [ "$rc" -ge 126 ] && r="rapor-uret calistirilamadi (cikis kodu $rc)"
fi
[ -z "$r" ] && ok "Ticket 8.16 — rapor-uret student tarafindan calistirilabiliyor (kaynak: lab 007b)" \
           || bad "Ticket 8.16 — $r (kaynak: lab 007b)"

# --- 8.17 metin-rapor.txt ilk satırı DIRTY/CLEAN ve doğru değerde ---
r=""
REP="$IS/metin-rapor.txt"
if [ ! -f "$REP" ]; then
    r="$REP uretilmedi"
else
    ilk="$(head -1 "$REP")"
    inv="$(nlines "$IS/gecersiz.log")"
    case "$ilk" in
        DIRTY|CLEAN) ;;
        *) r="ilk satir DIRTY veya CLEAN olmali (su an: '$ilk')" ;;
    esac
    if [ -z "$r" ]; then
        if [ "$inv" -gt 0 ] && [ "$ilk" != "DIRTY" ]; then
            r="gecersiz satir var, ilk satir DIRTY olmaliydi"
        elif [ "$inv" -eq 0 ] && [ "$ilk" != "CLEAN" ]; then
            r="gecersiz satir yok, ilk satir CLEAN olmaliydi"
        fi
    fi
fi
[ -z "$r" ] && ok "Ticket 8.17 — metin-rapor.txt ilk satiri dogru durumu gosteriyor (kaynak: lab 007b)" \
           || bad "Ticket 8.17 — $r (kaynak: lab 007b)"

# --- 8.18 idempotent: ikinci koşu raporu büyütmüyor ---
r=""
if [ ! -f "$REP" ]; then
    r="$REP yok"
else
    cp -p "$REP" "$TMP/rep1"
    run_student "rapor-uret" >/dev/null
    cmp -s "$TMP/rep1" "$REP" || \
        r="ikinci kosuda rapor degisti/buyudu — her seferinde bastan yazilmali"
fi
[ -z "$r" ] && ok "Ticket 8.18 — rapor-uret idempotent (kaynak: lab 007b)" \
           || bad "Ticket 8.18 — $r (kaynak: lab 007b)"

# --- 8.19 çıkış kodu ilk satırla tutarlı (DIRTY=1, CLEAN=0) ---
# Ortam GEÇİCİ olarak temiz veriyle değiştirilir, sonra geri alınır.
r=""
if [ ! -f "$BINDIR/rapor-uret" ]; then
    r="rapor-uret yok"
else
    rc="$(run_student "rapor-uret")"
    if [ "$(head -1 "$REP" 2>/dev/null)" = "DIRTY" ] && [ "$rc" != "1" ]; then
        r="DIRTY durumda cikis kodu 1 olmaliydi (su an: $rc)"
    else
        cp -p "$LOGLAR/karisik.log" "$TMP/karisik-yedek"
        cp "$TMP/exp-gecerli" "$LOGLAR/karisik.log"
        chown root:root "$LOGLAR/karisik.log"; chmod 0644 "$LOGLAR/karisik.log"
        rc2="$(run_student "rapor-uret")"
        ilk2="$(head -1 "$REP" 2>/dev/null)"
        if [ "$ilk2" != "CLEAN" ]; then
            r="tumu gecerli veriyle ilk satir CLEAN olmaliydi (su an: '$ilk2')"
        elif [ "$rc2" != "0" ]; then
            r="CLEAN durumda cikis kodu 0 olmaliydi (su an: $rc2)"
        fi
        cp -p "$TMP/karisik-yedek" "$LOGLAR/karisik.log"
        chown root:root "$LOGLAR/karisik.log"; chmod 0644 "$LOGLAR/karisik.log"
        run_student "rapor-uret" >/dev/null 2>&1 || true
    fi
fi
[ -z "$r" ] && ok "Ticket 8.19 — rapor-uret cikis kodu raporun ilk satiriyla tutarli (kaynak: lab 007b)" \
           || bad "Ticket 8.19 — $r (kaynak: lab 007b)"

# karisik.log'a dokunulmaması ayrı bir kriter değildir: 8.1-8.12'nin beklenen
# değerlerinin hepsi /srv/.orig'teki kopyadan türetilir, dosya değiştirilirse
# o kriterler zaten düşer.

# =============================================================================
section "Ticket 9 — Dosya yerleşimi, bağlantılar, arşiv (kaynak: lab 008)"
# =============================================================================
SRC=/srv/klinik-yedek-kaynagi
ARS=/srv/klinik-arsiv
ino() { stat -c '%i' "$1" 2>/dev/null; }

# --- 9.1 disk-kullanimi.txt: tek satır, doğru KB ---
r=""
f="$ANS/disk-kullanimi.txt"
REAL_KB="$(du -s "$SRC" 2>/dev/null | cut -f1)"
K1_KB=$(( $(stat -c '%b' "$SRC/kayit1.txt" 2>/dev/null || echo 0) / 2 ))
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(nlines "$f")" -ne 1 ]; then
    r="tek satir olmali (su an: $(nlines "$f"))"
else
    v="$(one_value "$f")"
    case "$v" in
        ''|*[!0-9]*) r="yalniz sayi olmali (su an: '$v')" ;;
        *) if [ "$v" != "$REAL_KB" ]; then
               if [ "$v" = "$(( REAL_KB + K1_KB ))" ]; then
                   r="sert baglanti paylasimi sayilmamis, ayni inode iki kez toplanmis (beklenen: $REAL_KB)"
               else
                   r="beklenen $REAL_KB KB (su an: $v)"
               fi
           fi ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 9.1 — disk-kullanimi.txt dogru KB degerini veriyor (kaynak: lab 008)" \
           || bad "Ticket 9.1 — $r (kaynak: lab 008)"

# --- 9.2 kayit3-hardlink.txt aynı inode'u paylaşıyor ---
r=""
HL="$HOME_STUDENT/kayit3-hardlink.txt"
if [ ! -e "$HL" ]; then
    r="$HL yok"
elif [ -L "$HL" ]; then
    r="sembolik link olusturulmus — sert baglanti isteniyordu"
elif [ "$(ino "$HL")" != "$(ino "$SRC/kayit3.txt")" ]; then
    r="inode kaynak dosyayla ayni degil — kopya olusturulmus olabilir"
elif [ "$(stat -c '%h' "$SRC/kayit3.txt" 2>/dev/null || echo 1)" -lt 2 ]; then
    r="kaynak dosyanin baglanti sayisi 2'nin altinda"
fi
[ -z "$r" ] && ok "Ticket 9.2 — kayit3-hardlink.txt kaynakla ayni inode'u paylasiyor (kaynak: lab 008)" \
           || bad "Ticket 9.2 — $r (kaynak: lab 008)"

# --- 9.3 kayit3-symlink.txt doğru hedefe işaret ediyor ---
r=""
SL="$HOME_STUDENT/kayit3-symlink.txt"
if [ ! -L "$SL" ]; then
    r="$SL sembolik link degil"
elif [ "$(readlink -f "$SL" 2>/dev/null)" != "$(readlink -f "$SRC/kayit3.txt")" ]; then
    r="link $(readlink -f "$SL" 2>/dev/null) gosteriyor, beklenen $SRC/kayit3.txt"
fi
[ -z "$r" ] && ok "Ticket 9.3 — kayit3-symlink.txt dogru hedefe isaret ediyor (kaynak: lab 008)" \
           || bad "Ticket 9.3 — $r (kaynak: lab 008)"

# --- 9.4 randevu.conf /etc/randevu/ altında, eski konumda yok ---
r=""
if [ ! -f /etc/randevu/randevu.conf ]; then
    r="/etc/randevu/randevu.conf yok"
elif [ -e "$HOME_STUDENT/randevu.conf" ]; then
    r="eski konumda ($HOME_STUDENT/randevu.conf) hala duruyor — tasinacakti, kopyalanmayacakti"
fi
[ -z "$r" ] && ok "Ticket 9.4 — randevu.conf /etc/randevu/ altina tasinmis (kaynak: lab 008)" \
           || bad "Ticket 9.4 — $r (kaynak: lab 008)"

# --- 9.5 klinik-uygulama.log /var/log/randevu/ altında, eski konumda yok ---
r=""
if [ ! -f /var/log/randevu/klinik-uygulama.log ]; then
    r="/var/log/randevu/klinik-uygulama.log yok"
elif [ -e "$HOME_STUDENT/klinik-uygulama.log" ]; then
    r="eski konumda hala duruyor — tasinacakti"
fi
[ -z "$r" ] && ok "Ticket 9.5 — klinik-uygulama.log /var/log/randevu/ altina tasinmis (kaynak: lab 008)" \
           || bad "Ticket 9.5 — $r (kaynak: lab 008)"

# --- 9.6 yedek-yardimcisi /usr/local/bin altında ve çalıştırılabilir ---
r=""
if [ ! -f "$BINDIR/yedek-yardimcisi" ]; then
    r="$BINDIR/yedek-yardimcisi yok"
elif [ ! -x "$BINDIR/yedek-yardimcisi" ]; then
    r="calistirilabilir degil"
elif ! as_student "command -v yedek-yardimcisi" >/dev/null 2>&1; then
    r="student'in PATH'inde bulunamiyor"
elif [ -e "$HOME_STUDENT/yedek-yardimcisi" ]; then
    r="eski konumda hala duruyor — tasinacakti"
fi
[ -z "$r" ] && ok "Ticket 9.6 — yedek-yardimcisi /usr/local/bin altinda ve calistirilabilir (kaynak: lab 008)" \
           || bad "Ticket 9.6 — $r (kaynak: lab 008)"

# --- 9.7 klinik-yedek.tar.gz içinde gecici içerik YOK ---
r=""
ARCH="$HOME_STUDENT/klinik-yedek.tar.gz"
if [ ! -f "$ARCH" ]; then
    r="$ARCH yok"
elif ! as_student "tar -tzf '$ARCH'" > "$TMP/tarlist" 2>/dev/null; then
    r="student arsivi listeleyemiyor"
elif [ "$(grep -cE '(^|/)gecici(/|$)' "$TMP/tarlist" || true)" -ne 0 ]; then
    r="arsivde gecici/ icerigi var — disarida birakilacakti"
fi
[ -z "$r" ] && ok "Ticket 9.7 — klinik-yedek.tar.gz gecici icerik barindirmiyor (kaynak: lab 008)" \
           || bad "Ticket 9.7 — $r (kaynak: lab 008)"

# --- 9.8 klinik-yedek.tar.gz kalıcı dosyaları içeriyor ---
r=""
if [ ! -s "$TMP/tarlist" ]; then
    r="arsiv listesi alinamadi"
else
    grep -qE '(^|/)dosya\.txt$' "$TMP/tarlist" || r="arsivde dosya.txt yok"
    [ -z "$r" ] && ! grep -qE '(^|/)kalici/onemli\.txt$' "$TMP/tarlist" \
        && r="arsivde kalici/onemli.txt yok"
fi
[ -z "$r" ] && ok "Ticket 9.8 — klinik-yedek.tar.gz kalici dosyalari iceriyor (kaynak: lab 008)" \
           || bad "Ticket 9.8 — $r (kaynak: lab 008)"

# --- 9.9 arsiv-dogrulama.txt iki satır, doğru var/yok bilgisi ---
r=""
f="$ANS/arsiv-dogrulama.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(nlines "$f")" -ne 2 ]; then
    r="iki satir olmali (su an: $(nlines "$f"))"
else
    s1="$(sed -n 1p "$f" | tr '[:upper:]' '[:lower:]')"
    s2="$(sed -n 2p "$f" | tr '[:upper:]' '[:lower:]')"
    case "$s1" in *onemli.txt*var*) ;; *) r="1. satir onemli.txt icin 'var' demeli (su an: '$s1')" ;; esac
    [ -z "$r" ] && case "$s2" in
        *silinecek.txt*yok*) ;;
        *) r="2. satir silinecek.txt icin 'yok' demeli (su an: '$s2')" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 9.9 — arsiv-dogrulama.txt dogru var/yok bilgisini veriyor (kaynak: lab 008)" \
           || bad "Ticket 9.9 — $r (kaynak: lab 008)"

# --- 9.10 baglanti-raporu.txt iki satır, doğru etiketlerle ---
r=""
f="$ANS/baglanti-raporu.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(nlines "$f")" -ne 2 ]; then
    r="iki satir olmali (su an: $(nlines "$f"))"
else
    low="$(tr '[:upper:]' '[:lower:]' < "$f")"
    printf '%s' "$low" | grep -q 'kayit1' || r="kayit1 ciftine dair satir yok"
    [ -z "$r" ] && ! printf '%s' "$low" | grep -q 'kayit2' \
        && r="kayit2 ciftine dair satir yok"
    if [ -z "$r" ]; then
        h="$(printf '%s' "$low" | grep 'kayit1')"
        b="$(printf '%s' "$low" | grep 'kayit2')"
        case "$h" in *sert*|*hard*) ;; *) r="kayit1 satiri sert baglanti olarak etiketlenmeli" ;; esac
        [ -z "$r" ] && case "$b" in
            *bagimsiz*|*kopya*) ;;
            *) r="kayit2 satiri bagimsiz kopya olarak etiketlenmeli" ;;
        esac
    fi
fi
[ -z "$r" ] && ok "Ticket 9.10 — baglanti-raporu.txt sert baglanti/kopya ayrimini dogru yapiyor (kaynak: lab 008)" \
           || bad "Ticket 9.10 — $r (kaynak: lab 008)"

# --- 9.11 kaynak dizinler DEĞİŞMEMİŞ ---
r=""
for d in klinik-arsiv klinik-yedek-kaynagi; do
    if ! diff -r "$ORIG/$d" "/srv/$d" >/dev/null 2>&1; then
        r="/srv/$d degistirilmis — kaynak dizinler yalniz okunacakti (arsivden cikarmak icin gecici/ SILINMEZ)"
        break
    fi
done
[ -z "$r" ] && ok "Ticket 9.11 — kaynak dizinler degistirilmemis (kaynak: lab 008)" \
           || bad "Ticket 9.11 — $r (kaynak: lab 008)"

# =============================================================================
section "Ticket 10 — Paket durumu (kaynak: lab 009)"
# =============================================================================

# --- 10.1 EPEL deposu etkin ---
r=""
dnf repolist --enabled 2>/dev/null | grep -qi '^epel' || r="epel deposu etkin degil"
[ -z "$r" ] && ok "Ticket 10.1 — EPEL deposu etkinlestirilmis (kaynak: lab 009)" \
           || bad "Ticket 10.1 — $r (kaynak: lab 009)"

# --- 10.2 CRB deposu etkin ---
r=""
dnf repolist --enabled 2>/dev/null | grep -qi '^crb' || r="crb deposu etkin degil"
[ -z "$r" ] && ok "Ticket 10.2 — CRB deposu etkinlestirilmis (kaynak: lab 009)" \
           || bad "Ticket 10.2 — $r (kaynak: lab 009)"

# --- 10.3 bc paketi kurulu ---
r=""
rpm -q bc >/dev/null 2>&1 || r="bc kurulu degil"
[ -z "$r" ] && ok "Ticket 10.3 — bc paketi kurulu (kaynak: lab 009)" \
           || bad "Ticket 10.3 — $r (kaynak: lab 009)"

# --- 10.4 dozhesapla.sh doğru sonucu üretiyor ---
r=""
if [ ! -x "$BINDIR/dozhesapla.sh" ]; then
    r="$BINDIR/dozhesapla.sh yok veya calistirilabilir degil"
else
    out="$(as_student "echo '12.5 * 2' | dozhesapla.sh" 2>/dev/null | tr -d '[:space:]')"
    case "$out" in
        25|25.0*) ;;
        *) r="beklenen sonuc 25 (su an: '$out') — bc olmadan hesap yapilamiyor" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 10.4 — dozhesapla.sh dogru sonucu uretiyor (kaynak: lab 009)" \
           || bad "Ticket 10.4 — $r (kaynak: lab 009)"

# --- 10.5 lsof komutu student ile çalışıyor ---
r=""
as_student "lsof -v" >/dev/null 2>&1 || r="student lsof calistiramiyor"
[ -z "$r" ] && ok "Ticket 10.5 — lsof komutu calisir durumda (kaynak: lab 009)" \
           || bad "Ticket 10.5 — $r (kaynak: lab 009)"

# --- 10.6 eksik-komut.txt doğru paket adını içeriyor ---
r=""
f="$ANS/eksik-komut.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(nlines "$f")" -ne 1 ]; then
    r="tek satir olmali (su an: $(nlines "$f"))"
else
    v="$(one_value "$f")"
    case "$v" in
        lsof|lsof-*) ;;
        *) r="lsof komutunu saglayan paket adi yazilmaliydi (su an: '$v')" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 10.6 — eksik-komut.txt dogru paket adini iceriyor (kaynak: lab 009)" \
           || bad "Ticket 10.6 — $r (kaynak: lab 009)"

# --- 10.7 paket-sorgu.txt ilk satırı doğru paket adı ---
r=""
f="$ANS/paket-sorgu.txt"
TREE_PKG="$(rpm -qf --qf '%{NAME}' /usr/bin/tree 2>/dev/null || true)"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ -z "$TREE_PKG" ]; then
    r="/usr/bin/tree sahibi paket bulunamadi (sistemde tree yok mu?)"
else
    v="$(sed -n 1p "$f" | tr -d '[:space:]')"
    case "$v" in
        "$TREE_PKG"|"$TREE_PKG"-*) ;;
        *) r="ilk satir '$TREE_PKG' olmaliydi (su an: '$v')" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 10.7 — paket-sorgu.txt ilk satirinda dogru paket adi var (kaynak: lab 009)" \
           || bad "Ticket 10.7 — $r (kaynak: lab 009)"

# --- 10.8 paket-sorgu.txt dosya listesi paketin gerçek listesiyle eşleşiyor ---
r=""
f="$ANS/paket-sorgu.txt"
if [ ! -f "$f" ] || [ -z "$TREE_PKG" ]; then
    r="paket-sorgu.txt veya paket adi yok"
else
    rpm -ql "$TREE_PKG" 2>/dev/null | sort > "$TMP/exp-ql"
    tail -n +2 "$f" | sed '/^[[:space:]]*$/d' | sort > "$TMP/got-ql"
    cmp -s "$TMP/exp-ql" "$TMP/got-ql" || \
        r="dosya listesi paketin gercek listesiyle ayni degil (beklenen $(nlines "$TMP/exp-ql") satir)"
fi
[ -z "$r" ] && ok "Ticket 10.8 — paket-sorgu.txt dosya listesi dogru (kaynak: lab 009)" \
           || bad "Ticket 10.8 — $r (kaynak: lab 009)"

# --- 10.9 rpm-inceleme.txt: kurulu OLMAYAN paketin adı ---
r=""
RPMF="$(ls "$PKGDIR"/*.rpm 2>/dev/null | head -1)"
RPM_NAME="$(rpm -qp --qf '%{NAME}' "$RPMF" 2>/dev/null || true)"
RPM_VER="$(rpm -qp --qf '%{VERSION}' "$RPMF" 2>/dev/null || true)"
f="$ANS/rpm-inceleme.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ -z "$RPM_NAME" ]; then
    r="$PKGDIR icindeki .rpm okunamadi"
elif [ "$(sed -n 1p "$f" | tr -d '[:space:]')" != "$RPM_NAME" ]; then
    r="1. satir paket adi '$RPM_NAME' olmaliydi (su an: '$(sed -n 1p "$f")')"
elif rpm -q "$RPM_NAME" >/dev/null 2>&1; then
    r="$RPM_NAME sisteme KURULMUS — kurmadan inceleme isteniyordu"
fi
[ -z "$r" ] && ok "Ticket 10.9 — rpm-inceleme.txt dogru paket adini veriyor, paket kurulmamis (kaynak: lab 009)" \
           || bad "Ticket 10.9 — $r (kaynak: lab 009)"

# --- 10.10 rpm-inceleme.txt sürüm satırı ---
r=""
f="$ANS/rpm-inceleme.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(sed -n 2p "$f" | tr -d '[:space:]')" != "$RPM_VER" ]; then
    r="2. satir surum '$RPM_VER' olmaliydi (su an: '$(sed -n 2p "$f")')"
fi
[ -z "$r" ] && ok "Ticket 10.10 — rpm-inceleme.txt dogru surumu veriyor (kaynak: lab 009)" \
           || bad "Ticket 10.10 — $r (kaynak: lab 009)"

# --- 10.11 rpm-inceleme.txt dosya listesi ---
r=""
f="$ANS/rpm-inceleme.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    rpm -qlp "$RPMF" 2>/dev/null | sort > "$TMP/exp-rpmql"
    tail -n +3 "$f" | sed '/^[[:space:]]*$/d' | sort > "$TMP/got-rpmql"
    cmp -s "$TMP/exp-rpmql" "$TMP/got-rpmql" || \
        r="dosya listesi .rpm icindekiyle ayni degil (beklenen $(nlines "$TMP/exp-rpmql") satir)"
fi
[ -z "$r" ] && ok "Ticket 10.11 — rpm-inceleme.txt dosya listesi dogru (kaynak: lab 009)" \
           || bad "Ticket 10.11 — $r (kaynak: lab 009)"

# --- 10.12 dpkg kurulu ve çalışır durumda ---
r=""
if ! rpm -q dpkg >/dev/null 2>&1; then
    r="dpkg paketi kurulu degil"
elif ! command -v dpkg-deb >/dev/null 2>&1; then
    r="dpkg-deb komutu yok"
elif ! dpkg --version >/dev/null 2>&1; then
    r="dpkg calismiyor"
fi
[ -z "$r" ] && ok "Ticket 10.12 — dpkg kurulu ve calisir durumda (kaynak: lab 009)" \
           || bad "Ticket 10.12 — $r (kaynak: lab 009)"

# --- 10.13 deb-inceleme.txt ad ve sürüm ---
r=""
DEBF="$(ls "$PKGDIR"/*.deb 2>/dev/null | head -1)"
DEB_NAME="$(dpkg-deb -f "$DEBF" Package 2>/dev/null || true)"
DEB_VER="$(dpkg-deb -f "$DEBF" Version 2>/dev/null || true)"
f="$ANS/deb-inceleme.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ -z "$DEB_NAME" ]; then
    r="$PKGDIR icindeki .deb okunamadi (dpkg-deb kurulu mu?)"
elif [ "$(sed -n 1p "$f" | tr -d '[:space:]')" != "$DEB_NAME" ]; then
    r="1. satir paket adi '$DEB_NAME' olmaliydi (su an: '$(sed -n 1p "$f")')"
elif [ "$(sed -n 2p "$f" | tr -d '[:space:]')" != "$DEB_VER" ]; then
    r="2. satir surum '$DEB_VER' olmaliydi (su an: '$(sed -n 2p "$f")')"
fi
[ -z "$r" ] && ok "Ticket 10.13 — deb-inceleme.txt dogru ad ve surumu veriyor (kaynak: lab 009)" \
           || bad "Ticket 10.13 — $r (kaynak: lab 009)"

# --- 10.14 deb-inceleme.txt dosya listesi ---
r=""
f="$ANS/deb-inceleme.txt"
if [ ! -f "$f" ] || [ -z "$DEB_NAME" ]; then
    r="deb-inceleme.txt veya .deb okunamadi"
else
    # İki taraf da AYNI normalizasyondan geçmeli: "./" gibi girdiler ancak
    # sondaki eğik çizgi atıldıktan SONRA boşalır, boş satır elemesi en sonda.
    deb_norm() {
        sed 's|^\./|/|; s|/$||' | sed '/^[[:space:]]*$/d' | sort -u
    }
    dpkg-deb -c "$DEBF" 2>/dev/null | awk '{print $NF}' | deb_norm > "$TMP/exp-debl"
    tail -n +3 "$f" | deb_norm > "$TMP/got-debl"
    cmp -s "$TMP/exp-debl" "$TMP/got-debl" || \
        r="dosya listesi .deb icindekiyle ayni degil (beklenen $(nlines "$TMP/exp-debl") satir)"
fi
[ -z "$r" ] && ok "Ticket 10.14 — deb-inceleme.txt dosya listesi dogru (kaynak: lab 009)" \
           || bad "Ticket 10.14 — $r (kaynak: lab 009)"

# --- 10.15 butunluk-raporu.txt: hem içerik hem izin değişikliği işaretli ---
# rpm -V PAKET ADI bekler, dosya yolu DEĞİL; dosya yolu -Vf ile verilir.
r=""
f="$ANS/butunluk-raporu.txt"
VIM_PKG="$(rpm -qf --qf '%{NAME}' /etc/vimrc 2>/dev/null || true)"
if [ ! -f "$f" ]; then
    r="$f yok"
elif [ "$(nlines "$f")" -lt 3 ]; then
    r="uc satir olmali (paket, dosya, degisenler) — su an: $(nlines "$f")"
else
    p="$(sed -n 1p "$f" | tr -d '[:space:]')"
    d="$(sed -n 2p "$f" | tr -d '[:space:]')"
    g="$(sed -n 3p "$f" | tr '[:upper:]' '[:lower:]')"
    if [ "$p" != "$VIM_PKG" ]; then
        r="1. satir paket adi '$VIM_PKG' olmaliydi (su an: '$p')"
    elif [ "$d" != "/etc/vimrc" ]; then
        r="2. satir /etc/vimrc olmaliydi (su an: '$d')"
    else
        printf '%s' "$g" | grep -q 'icerik' || r="3. satirda 'icerik' degisikligi isaretlenmemis"
        [ -z "$r" ] && ! printf '%s' "$g" | grep -q 'izin' \
            && r="3. satirda 'izin' degisikligi isaretlenmemis"
    fi
fi
[ -z "$r" ] && ok "Ticket 10.15 — butunluk-raporu.txt icerik ve izin degisikligini isaretliyor (kaynak: lab 009)" \
           || bad "Ticket 10.15 — $r (kaynak: lab 009)"

# --- 10.16 /srv/klinik/paketler referans dosyaları DEĞİŞMEMİŞ ---
r=""
diff -r "$ORIG/paketler" "$PKGDIR" >/dev/null 2>&1 || \
    r="$PKGDIR degistirilmis — referans paket dosyalari yalniz incelenecekti"
[ -z "$r" ] && ok "Ticket 10.16 — paketler dizinindeki referans dosyalar degismemis (kaynak: lab 009)" \
           || bad "Ticket 10.16 — $r (kaynak: lab 009)"

# =============================================================================
section "Ticket 11 — Dört systemd işi (kaynak: lab 010)"
# =============================================================================

# --- 11.1 veritabani-hazirla: Type=oneshot ve RemainAfterExit=yes ---
r=""
t="$(prop veritabani-hazirla.service Type)"
ra="$(prop veritabani-hazirla.service RemainAfterExit)"
if [ "$t" != "oneshot" ]; then
    r="Type=oneshot olmaliydi (su an: '$t')"
elif [ "$ra" != "yes" ]; then
    r="RemainAfterExit=yes olmaliydi (su an: '$ra')"
fi
[ -z "$r" ] && ok "Ticket 11.1 — veritabani-hazirla oneshot ve RemainAfterExit ile yazilmis (kaynak: lab 010)" \
           || bad "Ticket 11.1 — $r (kaynak: lab 010)"

# --- 11.2 veritabani-hazirla tamamlanmış durumda kalıyor ---
r=""
if [ "$(systemctl is-active veritabani-hazirla.service 2>/dev/null)" != "active" ]; then
    r="birim aktif degil (oneshot + RemainAfterExit ile 'active (exited)' kalmali)"
elif [ "$(prop veritabani-hazirla.service SubState)" != "exited" ]; then
    r="SubState 'exited' olmaliydi (su an: '$(prop veritabani-hazirla.service SubState)')"
elif [ ! -e /var/lib/klinik/.hazir ]; then
    r="/var/lib/klinik/.hazir olusmamis — is gercekten kosmamis"
fi
[ -z "$r" ] && ok "Ticket 11.2 — veritabani-hazirla tamamlanmis durumda kaliyor (kaynak: lab 010)" \
           || bad "Ticket 11.2 — $r (kaynak: lab 010)"

# --- 11.3 randevu-api sıralama bağı (After) ---
r=""
prop randevu-api.service After | grep -q 'veritabani-hazirla.service' || \
    r="After=veritabani-hazirla.service tanimlanmamis"
[ -z "$r" ] && ok "Ticket 11.3 — randevu-api veritabani-hazirla'dan SONRA baslayacak sekilde bagli (kaynak: lab 010)" \
           || bad "Ticket 11.3 — $r (kaynak: lab 010)"

# --- 11.4 randevu-api gereklilik bağı (Requires) ---
r=""
prop randevu-api.service Requires | grep -q 'veritabani-hazirla.service' || \
    r="Requires=veritabani-hazirla.service tanimlanmamis (BindsTo bu is icin dogru tercih degil)"
[ -z "$r" ] && ok "Ticket 11.4 — randevu-api veritabani-hazirla'ya Requires ile bagli (kaynak: lab 010)" \
           || bad "Ticket 11.4 — $r (kaynak: lab 010)"

# --- 11.5 randevu-api başarıyla başlıyor ve aktif kalıyor ---
r=""
if [ "$(systemctl is-active randevu-api.service 2>/dev/null)" != "active" ]; then
    r="birim aktif degil"
elif [ "$(prop randevu-api.service SubState)" != "running" ]; then
    r="SubState 'running' olmaliydi (su an: '$(prop randevu-api.service SubState)')"
elif [ "$(prop randevu-api.service MainPID)" = "0" ]; then
    r="MainPID 0 — surec gercekten kosmuyor"
fi
[ -z "$r" ] && ok "Ticket 11.5 — randevu-api aktif ve gercekten kosuyor (kaynak: lab 010)" \
           || bad "Ticket 11.5 — $r (kaynak: lab 010)"

# --- 11.6 hatirlatici doğru Type ve ExecStart ile yazılmış ---
r=""
t="$(prop hatirlatici.service Type)"
e="$(exec_path hatirlatici.service)"
if [ "$t" != "simple" ] && [ "$t" != "exec" ]; then
    r="surekli kosan bir servis icin Type simple/exec olmali (su an: '$t')"
elif [ ! -x "$e" ]; then
    r="ExecStart var olan bir programa isaret etmiyor ('$e')"
fi
[ -z "$r" ] && ok "Ticket 11.6 — hatirlatici dogru Type ve ExecStart ile yazilmis (kaynak: lab 010)" \
           || bad "Ticket 11.6 — $r (kaynak: lab 010)"

# --- 11.7 hatirlatici hem aktif hem enabled ---
r=""
if [ "$(systemctl is-active hatirlatici.service 2>/dev/null)" != "active" ]; then
    r="birim aktif degil"
elif ! systemctl is-enabled hatirlatici.service >/dev/null 2>&1; then
    r="birim enabled degil"
fi
[ -z "$r" ] && ok "Ticket 11.7 — hatirlatici hem aktif hem enabled (kaynak: lab 010)" \
           || bad "Ticket 11.7 — $r (kaynak: lab 010)"

# --- 11.8 hatirlatici systemd'ye göre GERÇEKTEN koşuyor ---
r=""
pid="$(prop hatirlatici.service MainPID)"
if [ -z "$pid" ] || [ "$pid" = "0" ]; then
    r="MainPID 0 — systemd bu birimi kosan bir surec olarak gormuyor"
elif [ "$(prop hatirlatici.service SubState)" != "running" ]; then
    r="SubState 'running' olmaliydi (su an: '$(prop hatirlatici.service SubState)')"
elif ! ps -p "$pid" >/dev/null 2>&1; then
    r="MainPID $pid surec tablosunda yok"
fi
[ -z "$r" ] && ok "Ticket 11.8 — hatirlatici PID 1 altinda gercekten kosuyor (kaynak: lab 010)" \
           || bad "Ticket 11.8 — $r (kaynak: lab 010)"

# --- 11.9 stok-raporu ExecStart ve User geçerli ---
r=""
e="$(exec_path stok-raporu.service)"
u="$(prop stok-raporu.service User)"
if [ ! -x "$e" ]; then
    r="ExecStart var olan bir programa isaret etmiyor ('$e')"
elif [ -z "$u" ]; then
    r="User tanimli degil"
elif ! getent passwd "$u" >/dev/null 2>&1; then
    r="User '$u' sistemde yok"
fi
[ -z "$r" ] && ok "Ticket 11.9 — stok-raporu ExecStart ve User degerleri gecerli (kaynak: lab 010)" \
           || bad "Ticket 11.9 — $r (kaynak: lab 010)"

# --- 11.10 stok-raporu aktif ve tanım tazelenmiş ---
r=""
if [ "$(systemctl is-active stok-raporu.service 2>/dev/null)" != "active" ]; then
    r="birim aktif degil"
elif [ "$(prop stok-raporu.service NeedDaemonReload)" != "no" ]; then
    r="birim dosyasi diskte degismis ama daemon-reload yapilmamis"
fi
[ -z "$r" ] && ok "Ticket 11.10 — stok-raporu aktif ve systemd tanimi tazelenmis (kaynak: lab 010)" \
           || bad "Ticket 11.10 — $r (kaynak: lab 010)"

# --- 11.11 varsayılan target ve dört birim dosyasının kalıcı konumu ---
r=""
dt="$(systemctl get-default 2>/dev/null)"
if [ "$dt" != "multi-user.target" ]; then
    r="varsayilan target multi-user.target olmaliydi (su an: '$dt')"
else
    for u in veritabani-hazirla randevu-api hatirlatici stok-raporu; do
        p="$(systemctl show "$u.service" -p FragmentPath --value 2>/dev/null)"
        case "$p" in
            /etc/systemd/system/*|/usr/lib/systemd/system/*) ;;
            *) r="$u.service birim dosyasi kalici bir konumda degil ('$p')"; break ;;
        esac
    done
fi
[ -z "$r" ] && ok "Ticket 11.11 — varsayilan target multi-user, dort birim kalici konumda (kaynak: lab 010)" \
           || bad "Ticket 11.11 — $r (kaynak: lab 010)"

# =============================================================================
section "Ticket 12 — Log, cron ve saat (kaynak: lab 011)"
# =============================================================================

# --- 12.1 kalıcı journal dizini var ve gerçekten kullanılıyor ---
r=""
if [ ! -d /var/log/journal ]; then
    r="/var/log/journal yok"
elif [ "$(find /var/log/journal -name '*.journal' 2>/dev/null | wc -l)" -eq 0 ]; then
    r="/var/log/journal altinda .journal dosyasi yok — dizin acildi ama gunlukler bosaltilmamis"
fi
[ -z "$r" ] && ok "Ticket 12.1 — kalici journal dizini kurulmus ve kullaniliyor (kaynak: lab 011)" \
           || bad "Ticket 12.1 — $r (kaynak: lab 011)"

# --- 12.2 journald kalıcı depolamaya ayarlanmış ---
r=""
st="$(journalctl --header 2>/dev/null | grep -c '/var/log/journal' || true)"
if [ "$st" -eq 0 ]; then
    r="journald hala /var/log/journal'a yazmiyor (Storage= ayari ve servis yeniden baslatma gerekiyor)"
fi
[ -z "$r" ] && ok "Ticket 12.2 — journald kalici depolamayi kullaniyor (kaynak: lab 011)" \
           || bad "Ticket 12.2 — $r (kaynak: lab 011)"

# --- 12.3 gozcu.service enabled ---
r=""
systemctl is-enabled gozcu.service >/dev/null 2>&1 || r="gozcu.service enabled degil"
[ -z "$r" ] && ok "Ticket 12.3 — gozcu.service enabled (kaynak: lab 011)" \
           || bad "Ticket 12.3 — $r (kaynak: lab 011)"

# --- 12.4 gozcu.service hatasız çalışıyor ---
r=""
if [ "$(systemctl is-active gozcu.service 2>/dev/null)" != "active" ]; then
    r="gozcu.service aktif degil — eksik lisans dosyasi olusturulmali"
elif [ "$(prop gozcu.service Result)" != "success" ]; then
    r="son kosu basarisiz (Result: '$(prop gozcu.service Result)')"
fi
[ -z "$r" ] && ok "Ticket 12.4 — gozcu.service hatasiz calisiyor (kaynak: lab 011)" \
           || bad "Ticket 12.4 — $r (kaynak: lab 011)"

# --- 12.5 cevap.txt eksik dosyanın yolunu içeriyor ---
r=""
f="$ANS/cevap.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif ! grep -q '/etc/klinik/lisans.anahtar' "$f"; then
    r="eksik dosyanin tam yolu (/etc/klinik/lisans.anahtar) yazilmamis"
fi
[ -z "$r" ] && ok "Ticket 12.5 — cevap.txt eksik dosyanin yolunu iceriyor (kaynak: lab 011)" \
           || bad "Ticket 12.5 — $r (kaynak: lab 011)"

# --- 12.6 cevap.txt çıkış kodunu içeriyor ---
r=""
f="$ANS/cevap.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
elif ! grep -qE '(^|[^0-9])3([^0-9]|$)' "$f"; then
    r="gozcu'nun dondugu cikis kodu (3) yazilmamis"
fi
[ -z "$r" ] && ok "Ticket 12.6 — cevap.txt cikis kodunu iceriyor (kaynak: lab 011)" \
           || bad "Ticket 12.6 — $r (kaynak: lab 011)"

# --- 12.7 crond aktif ---
r=""
[ "$(systemctl is-active crond.service 2>/dev/null)" = "active" ] || \
    r="crond.service aktif degil"
[ -z "$r" ] && ok "Ticket 12.7 — crond servisi aktif (kaynak: lab 011)" \
           || bad "Ticket 12.7 — $r (kaynak: lab 011)"

# --- 12.8 crond enabled ---
r=""
systemctl is-enabled crond.service >/dev/null 2>&1 || r="crond.service enabled degil"
[ -z "$r" ] && ok "Ticket 12.8 — crond servisi enabled (kaynak: lab 011)" \
           || bad "Ticket 12.8 — $r (kaynak: lab 011)"

# --- 12.9 yedek cron işi her dakika çalışacak biçimde tanımlı ---
# `*` içeren satır alanlara bölünürken `set -f` şart; yoksa dosya adlarına
# genişler ve alan sayısı sessizce değişir.
r=""
CRONLINE="$(grep -hE '(^|[[:space:]])(root[[:space:]]+)?[^#]*yedekle' \
             /etc/cron.d/* /var/spool/cron/root /var/spool/cron/student \
             2>/dev/null | grep -v '^[[:space:]]*#' | head -1)"
if [ -z "$CRONLINE" ]; then
    r="yedekle isini calistiran bir cron satiri bulunamadi"
else
    set -f
    set -- $CRONLINE
    dak="$1"; saat="$2"
    set +f
    case "$dak" in
        '*'|'*/1') ;;
        *) r="dakika alani her dakika calisacak sekilde olmali (su an: '$dak')" ;;
    esac
    [ -z "$r" ] && [ "$saat" != "*" ] && \
        r="saat alani '*' olmali (su an: '$saat') — is her dakika calisacak"
fi
[ -z "$r" ] && ok "Ticket 12.9 — yedek cron isi her dakika calisacak sekilde tanimli (kaynak: lab 011)" \
           || bad "Ticket 12.9 — $r (kaynak: lab 011)"

# --- 12.10 cron komutu cron'un minimal ortamında bulunabilir ---
r=""
if [ -z "$CRONLINE" ]; then
    r="cron satiri bulunamadi"
else
    case "$CRONLINE" in
        */usr/local/bin/yedekle*|*/usr/bin/yedekle*|*/bin/yedekle*) ;;
        *) r="komut mutlak yolla yazilmamis — cron'un PATH'i /usr/bin:/bin'dir, /usr/local/bin orada YOKTUR" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 12.10 — cron komutu mutlak yolla yazilmis (kaynak: lab 011)" \
           || bad "Ticket 12.10 — $r (kaynak: lab 011)"

# --- 12.11 yedek log dosyasında gerçek bir çalışma satırı var ---
r=""
if [ ! -s /var/log/klinik-yedek.log ]; then
    r="/var/log/klinik-yedek.log bos veya yok — is hic calismamis (cron bir dakika beklemeyi gerektirir)"
fi
[ -z "$r" ] && ok "Ticket 12.11 — yedek isi gercekten calismis, log satiri var (kaynak: lab 011)" \
           || bad "Ticket 12.11 — $r (kaynak: lab 011)"

# --- 12.12 temizlik.service bir kez çalışan tipte ve doğru programı çağırıyor ---
r=""
t="$(prop temizlik.service Type)"
e="$(exec_path temizlik.service)"
if [ -z "$t" ]; then
    r="temizlik.service tanimli degil"
elif [ "$t" != "oneshot" ]; then
    r="Type=oneshot olmaliydi (su an: '$t')"
elif [ ! -x "$e" ]; then
    r="ExecStart var olan bir programa isaret etmiyor ('$e')"
fi
[ -z "$r" ] && ok "Ticket 12.12 — temizlik.service tek seferlik ve dogru programi cagiriyor (kaynak: lab 011)" \
           || bad "Ticket 12.12 — $r (kaynak: lab 011)"

# --- 12.13 temizlik.timer aktif ve tetiklemeyi bekliyor ---
r=""
if [ "$(systemctl is-active temizlik.timer 2>/dev/null)" != "active" ]; then
    r="temizlik.timer aktif degil"
elif [ "$(prop temizlik.timer SubState)" != "waiting" ]; then
    r="timer SubState 'waiting' olmaliydi (su an: '$(prop temizlik.timer SubState)')"
fi
[ -z "$r" ] && ok "Ticket 12.13 — temizlik.timer aktif ve tetiklemeyi bekliyor (kaynak: lab 011)" \
           || bad "Ticket 12.13 — $r (kaynak: lab 011)"

# --- 12.14 temizlik.timer enabled ---
r=""
systemctl is-enabled temizlik.timer >/dev/null 2>&1 || r="temizlik.timer enabled degil"
[ -z "$r" ] && ok "Ticket 12.14 — temizlik.timer enabled (kaynak: lab 011)" \
           || bad "Ticket 12.14 — $r (kaynak: lab 011)"

# --- 12.15 timer doğru service birimini tetikliyor ---
r=""
u="$(prop temizlik.timer Unit)"
[ "$u" = "temizlik.service" ] || \
    r="timer 'temizlik.service' birimini tetiklemeli (su an: '$u')"
[ -z "$r" ] && ok "Ticket 12.15 — temizlik.timer dogru service birimini tetikliyor (kaynak: lab 011)" \
           || bad "Ticket 12.15 — $r (kaynak: lab 011)"

# --- 12.16 bir sonraki tetiklemeye en fazla bir dakika var ---
# NextElapseUSec* --value ile HAM mikrosaniye DEĞİL, insan-okur biçimde döner.
# Realtime bir zaman damgası, Monotonic bir süredir; ikisi ayrı ayrı ele alınır.
r=""
NEXT=""
# Var olmayan bir birimde systemctl show 0 döner; bunu "0 saniye kaldi" sanmak
# kriteri bedava geçirir. Önce birimin gerçekten yüklü olduğu doğrulanır.
if [ "$(prop temizlik.timer LoadState)" != "loaded" ]; then
    r="temizlik.timer birimi yuklu degil"
fi
rt="$(prop temizlik.timer NextElapseUSecRealtime)"
if [ -n "$rt" ] && [ "$rt" != "n/a" ]; then
    e="$(date -d "$rt" +%s 2>/dev/null || true)"
    [ -n "$e" ] && NEXT=$(( e - $(date +%s) ))
fi
if [ -z "$NEXT" ]; then
    mono="$(prop temizlik.timer NextElapseUSecMonotonic)"
    if [ -n "$mono" ] && [ "$mono" != "n/a" ]; then
        ms="$(dur_to_sec "$mono")"
        up="$(awk '{printf "%d", $1}' /proc/uptime)"
        # Monotonic -> epoch yuvarlamasinda 1 saniyelik tolerans birakilir.
        NEXT=$(( ms - up + 1 ))
    fi
fi
if [ -n "$r" ]; then
    :
elif [ -z "$NEXT" ]; then
    r="bir sonraki tetikleme zamani okunamadi (timer tanimli mi?)"
elif [ "$NEXT" -lt 0 ]; then
    r="bir sonraki tetikleme zamani gecmiste gorunuyor ($NEXT sn) — timer beklemiyor"
elif [ "$NEXT" -gt 61 ]; then
    r="bir sonraki tetiklemeye $NEXT saniye var — en fazla bir dakika olmali"
fi
[ -z "$r" ] && ok "Ticket 12.16 — bir sonraki tetiklemeye en fazla bir dakika var (kaynak: lab 011)" \
           || bad "Ticket 12.16 — $r (kaynak: lab 011)"

# --- 12.17 temizlik işi gerçekten çalışmış ---
r=""
if [ ! -s /var/log/klinik-temizlik.log ]; then
    r="/var/log/klinik-temizlik.log bos veya yok — timer henuz tetiklememis"
fi
[ -z "$r" ] && ok "Ticket 12.17 — temizlik isi calismis, log satiri var (kaynak: lab 011)" \
           || bad "Ticket 12.17 — $r (kaynak: lab 011)"

# --- 12.18 sistem saat dilimi Europe/Istanbul, kalıcı ---
r=""
tz="$(timedatectl show -p Timezone --value 2>/dev/null)"
if [ "$tz" != "Europe/Istanbul" ]; then
    r="saat dilimi Europe/Istanbul olmaliydi (su an: '$tz')"
elif ! readlink /etc/localtime 2>/dev/null | grep -q 'Europe/Istanbul'; then
    r="/etc/localtime Europe/Istanbul'a isaret etmiyor — ayar kalici degil"
fi
[ -z "$r" ] && ok "Ticket 12.18 — sistem saat dilimi Europe/Istanbul ve kalici (kaynak: lab 011)" \
           || bad "Ticket 12.18 — $r (kaynak: lab 011)"

# --- 12.19 chrony: sunucu satırı, servis aktif+enabled, NTP raporlaniyor ---
r=""
if ! grep -qE '^[[:space:]]*(server|pool)[[:space:]]+[^[:space:]]+' /etc/chrony.conf 2>/dev/null; then
    r="/etc/chrony.conf icinde gecerli bir zaman sunucusu satiri yok"
elif [ "$(systemctl is-active chronyd.service 2>/dev/null)" != "active" ]; then
    r="chronyd.service aktif degil"
elif ! systemctl is-enabled chronyd.service >/dev/null 2>&1; then
    r="chronyd.service enabled degil"
elif [ "$(timedatectl show -p NTP --value 2>/dev/null)" != "yes" ]; then
    r="sistem saat senkronunu acik olarak raporlamiyor"
fi
[ -z "$r" ] && ok "Ticket 12.19 — chrony yapilandirilmis, servis aktif ve senkron acik (kaynak: lab 011)" \
           || bad "Ticket 12.19 — $r (kaynak: lab 011)"

# =============================================================================
section "Ticket 13 — Erişim sertleştirme: SSH + GPG (kaynak: lab 012)"
# =============================================================================
sshd_eff() { sshd -T 2>/dev/null | awk -v k="$1" '$1 == k {print $2; exit}'; }
gpg_st()   { as_student "gpg --batch $1" >/dev/null 2>&1; }

# --- 13.1 .ssh dizini yalnız sahibine açık ve student'a ait ---
r=""
if [ ! -d "$SSH_DIR" ]; then
    r="$SSH_DIR yok"
elif [ "$(stat -c %a "$SSH_DIR")" != "700" ]; then
    r="mod 700 olmaliydi (su an: $(stat -c %a "$SSH_DIR"))"
elif [ "$(stat -c %U "$SSH_DIR")" != "$STUDENT" ]; then
    r="sahibi student olmaliydi (su an: $(stat -c %U "$SSH_DIR"))"
fi
[ -z "$r" ] && ok "Ticket 13.1 — .ssh dizini 0700 ve student'a ait (kaynak: lab 012)" \
           || bad "Ticket 13.1 — $r (kaynak: lab 012)"

# --- 13.2 authorized_keys doğru izinde ve student'a ait ---
r=""
AK="$SSH_DIR/authorized_keys"
if [ ! -f "$AK" ]; then
    r="$AK yok"
else
    m="$(stat -c %a "$AK")"
    case "$m" in
        600|400) ;;
        *) r="mod 600 (veya 400) olmaliydi (su an: $m)" ;;
    esac
    [ -z "$r" ] && [ "$(stat -c %U "$AK")" != "$STUDENT" ] \
        && r="sahibi student olmaliydi (su an: $(stat -c %U "$AK"))"
fi
[ -z "$r" ] && ok "Ticket 13.2 — authorized_keys dogru izinde ve student'a ait (kaynak: lab 012)" \
           || bad "Ticket 13.2 — $r (kaynak: lab 012)"

# --- 13.3 authorized_keys student'ın açık anahtarını içeriyor ---
r=""
if [ ! -f "$AK" ]; then
    r="$AK yok"
elif [ ! -f "$SSH_DIR/id_ed25519.pub" ]; then
    r="student'in acik anahtari bulunamadi"
else
    key="$(awk '{print $2}' "$SSH_DIR/id_ed25519.pub")"
    grep -qF "$key" "$AK" || r="authorized_keys student'in acik anahtarini icermiyor"
fi
[ -z "$r" ] && ok "Ticket 13.3 — authorized_keys student'in acik anahtarini iceriyor (kaynak: lab 012)" \
           || bad "Ticket 13.3 — $r (kaynak: lab 012)"

# --- 13.4 ev dizini gruba ve diğerlerine yazılabilir DEĞİL ---
r=""
m="$(stat -c %a "$HOME_STUDENT" 2>/dev/null || echo 777)"
[ $(( 8#$m & 022 )) -ne 0 ] && \
    r="ev dizini gruba/digerlerine yazilabilir (mod $m) — sshd StrictModes bunu sessizce reddeder"
[ -z "$r" ] && ok "Ticket 13.4 — student ev dizini gruba/digerlerine yazilabilir degil (kaynak: lab 012)" \
           || bad "Ticket 13.4 — $r (kaynak: lab 012)"

# --- 13.5 parola ile giriş kapalı ---
r=""
v="$(sshd_eff passwordauthentication)"
[ "$v" = "no" ] || r="PasswordAuthentication no olmaliydi (etkin deger: '$v')"
[ -z "$r" ] && ok "Ticket 13.5 — parola ile giris kapali (kaynak: lab 012)" \
           || bad "Ticket 13.5 — $r (kaynak: lab 012)"

# --- 13.6 root girişi kapalı ---
r=""
v="$(sshd_eff permitrootlogin)"
[ "$v" = "no" ] || r="PermitRootLogin no olmaliydi (etkin deger: '$v')"
[ -z "$r" ] && ok "Ticket 13.6 — root girisi kapali (kaynak: lab 012)" \
           || bad "Ticket 13.6 — $r (kaynak: lab 012)"

# --- 13.7 sshd yapılandırması sözdizimi sınamasından temiz geçiyor ---
r=""
sshd -t 2>"$TMP/sshd-err" || r="sshd -t hata verdi: $(head -1 "$TMP/sshd-err")"
[ -z "$r" ] && ok "Ticket 13.7 — sshd yapilandirmasi sozdizimi sinamasindan temiz geciyor (kaynak: lab 012)" \
           || bad "Ticket 13.7 — $r (kaynak: lab 012)"

# --- 13.8 sshd ayakta ve YENİ yapılandırmayla çalışıyor ---
# Servis başlangıç zamanı config mtime'ından yeni olmalı: monotonik saat
# epoch'a çevrilir, yuvarlama için 1 saniyelik tolerans bırakılır.
r=""
if [ "$(systemctl is-active sshd.service 2>/dev/null)" != "active" ]; then
    r="sshd.service aktif degil"
else
    # Önce MUTLAK zaman damgası denenir: monotonik saati epoch'a çevirmek
    # yuvarlama hatası getirir ve tolerans gerektirir.
    svc_epoch=""
    ae="$(prop sshd.service ActiveEnterTimestamp)"
    if [ -n "$ae" ] && [ "$ae" != "n/a" ]; then
        svc_epoch="$(date -d "$ae" +%s 2>/dev/null || true)"
    fi
    if [ -z "$svc_epoch" ]; then
        svc_us="$(prop sshd.service ExecMainStartTimestampMonotonic)"
        if [ -n "$svc_us" ] && [ "$svc_us" != "0" ]; then
            boot_us="$(awk '{printf "%.0f", $1 * 1000000}' /proc/uptime)"
            # Monotonik -> epoch yuvarlamasi icin 1 saniyelik tolerans.
            svc_epoch=$(( $(date +%s) - (boot_us - svc_us) / 1000000 + 1 ))
        fi
    fi
    if [ -n "$svc_epoch" ]; then
        conf_m="$(stat -c %Y "$SSHD_CONF")"
        [ "$svc_epoch" -ge "$conf_m" ] || \
            r="sshd yapilandirma degistikten sonra yeniden baslatilmamis"
    fi
fi
[ -z "$r" ] && ok "Ticket 13.8 — sshd ayakta ve yeni yapilandirmayla calisiyor (kaynak: lab 012)" \
           || bad "Ticket 13.8 — $r (kaynak: lab 012)"

# --- 13.9 student parola kullanmadan yalnız anahtarla giriş yapabiliyor ---
r=""
out="$(as_student "ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no \
        -o ConnectTimeout=10 student@localhost 'echo GIRIS_OK'" 2>/dev/null || true)"
printf '%s' "$out" | grep -q 'GIRIS_OK' || \
    r="anahtarla giris basarisiz — authorized_keys, ev dizini izni veya sshd yeniden baslatma eksik"
[ -z "$r" ] && ok "Ticket 13.9 — student parolasiz, anahtarla giris yapabiliyor (kaynak: lab 012)" \
           || bad "Ticket 13.9 — $r (kaynak: lab 012)"

# --- 13.10 student'ın gizli GPG anahtarı var ve kimliği doğru ---
# NOT: `gpg --list-secret-keys` argümansız çağrıldığında BOŞ anahtarlıkta da 0
# döner; kimlik verilerek sorulmalı.
r=""
if ! gpg_st "--list-secret-keys bt@pativet.local"; then
    r="student'in 'PatiVet BT <bt@pativet.local>' kimlikli gizli gpg anahtari yok"
elif ! as_student "gpg --batch --list-secret-keys bt@pativet.local" 2>/dev/null \
        | grep -q 'PatiVet BT'; then
    r="anahtar kimligi 'PatiVet BT <bt@pativet.local>' olmaliydi"
fi
[ -z "$r" ] && ok "Ticket 13.10 — student'in gizli GPG anahtari var, kimligi dogru (kaynak: lab 012)" \
           || bad "Ticket 13.10 — $r (kaynak: lab 012)"

# --- 13.11 tedarikçinin açık anahtarı student'ın anahtarlığında ---
r=""
gpg_st "--list-keys yayinci@lab.local" || \
    r="tedarikcinin acik anahtari ice aktarilmamis"
[ -z "$r" ] && ok "Ticket 13.11 — tedarikcinin acik anahtari anahtarlikta (kaynak: lab 012)" \
           || bad "Ticket 13.11 — $r (kaynak: lab 012)"

# --- 13.12 sağlam paketin imzası student olarak doğrulanabiliyor ---
r=""
gpg_st "--verify $PAKET/surum-a.tar.gz.sig $PAKET/surum-a.tar.gz" || \
    r="surum-a imzasi student olarak dogrulanamiyor"
[ -z "$r" ] && ok "Ticket 13.12 — saglam paketin imzasi dogrulaniyor (kaynak: lab 012)" \
           || bad "Ticket 13.12 — $r (kaynak: lab 012)"

# --- 13.13 kurcalanmış paket cevap dosyasında doğru işaretlenmiş ---
r=""
f="$ANS/06-paket.txt"
if [ ! -f "$f" ]; then
    r="$f yok"
else
    low="$(tr '[:upper:]' '[:lower:]' < "$f")"
    a="$(printf '%s' "$low" | grep 'surum-a' | head -1)"
    b="$(printf '%s' "$low" | grep 'surum-b' | head -1)"
    if [ -z "$a" ] || [ -z "$b" ]; then
        r="her iki paket icin de birer satir olmali (surum-a ve surum-b)"
    else
        case "$a" in *gecerli*|*saglam*|*ok*) ;; *) r="surum-a saglam olarak isaretlenmeli (su an: '$a')" ;; esac
        [ -z "$r" ] && case "$b" in
            *gecersiz*|*bozuk*|*kurcalan*|*basarisiz*) ;;
            *) r="surum-b kurcalanmis olarak isaretlenmeli (su an: '$b')" ;;
        esac
    fi
fi
[ -z "$r" ] && ok "Ticket 13.13 — kurcalanmis paket cevap dosyasinda dogru isaretlenmis (kaynak: lab 012)" \
           || bad "Ticket 13.13 — $r (kaynak: lab 012)"

# --- 13.14 gizli-hasta-notu.txt.gpg student'ın anahtarına şifrelenmiş ---
r=""
ENC="$HOME_STUDENT/gizli-hasta-notu.txt.gpg"
if [ ! -f "$ENC" ]; then
    r="$ENC yok"
elif ! as_student "gpg --batch --yes --decrypt $ENC" > "$TMP/cozulen" 2>/dev/null; then
    r="dosya student'in anahtariyla cozulemiyor"
elif ! cmp -s "$TMP/cozulen" "$HOME_STUDENT/gizli-hasta-notu.txt"; then
    r="cozulen icerik orijinaliyle ayni degil"
fi
[ -z "$r" ] && ok "Ticket 13.14 — sifreli hasta notu cozuluyor ve icerik ayni (kaynak: lab 012)" \
           || bad "Ticket 13.14 — $r (kaynak: lab 012)"

# --- 13.15 devir-notu.txt ayrık imzayla imzalanmış ve doğrulanıyor ---
r=""
SIG=""
for c in "$HOME_STUDENT/devir-notu.txt.sig" "$HOME_STUDENT/devir-notu.txt.asc"; do
    [ -f "$c" ] && { SIG="$c"; break; }
done
if [ -z "$SIG" ]; then
    r="devir-notu.txt icin ayrik imza dosyasi (.sig veya .asc) yok"
elif ! gpg_st "--verify $SIG $HOME_STUDENT/devir-notu.txt"; then
    r="ayrik imza dogrulanamiyor"
fi
[ -z "$r" ] && ok "Ticket 13.15 — devir-notu.txt ayrik imzayla imzalanmis ve dogrulaniyor (kaynak: lab 012)" \
           || bad "Ticket 13.15 — $r (kaynak: lab 012)"

# =============================================================================
flush_section
printf '\n=== ÖZET %s\n' '======================================================'
printf '%s' "$SUMMARY"
printf '  %s\n' '-------------------------------------------------'
printf '  %3d/%-3d  TOPLAM\n' "$TOT_OK" "$TOT_N"
if [ "$FAIL" -eq 0 ]; then
    printf '\nGEÇTİ — 901-gun-02b tamamlandi.\n'
else
    printf '\nKALDI — yukaridaki [FAIL] satirlarina bak.\n'
    printf 'Tum [OK] satirlarini gormek icin: CHECK_VERBOSE=1\n'
fi
exit "$FAIL"
