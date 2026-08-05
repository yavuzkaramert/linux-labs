#!/usr/bin/env bash
# ENV: container
# Container içinde root olarak çalışır. Accumulator pattern: `set -e` YOK, her
# kriter bağımsız değerlendirilir, FAIL varsa sonunda exit 1.
#
# Bu bir TEKRAR labı: her satır hangi kaynak lab'dan geldiğini söyler.
# Biçim:  [OK]   Ticket 2.5 — açıklama (kaynak: lab 002)
#
# İlkeler:
#  * Kullanıcı-perspektifi testleri `su - student -c` ile koşar.
#  * Beklenen değerler HESAPLANIR, sabit yazılmaz — /srv/.orig'ten türetilir.
#  * Hiçbir süreç öldürülmez, hiçbir servis durdurulmaz; temizlik setup'ın işi.
set -u

KLINIK=/srv/klinik
RAPOR=/srv/rapor
ORIG=/srv/.orig
CONFDIR=/etc/klinik
LOGDIR=/var/log/klinik
LISTDIR=/etc/klinik-servis
BINDIR=/usr/local/bin
STUDENT=student

SERVICES="randevu-web randevu-islem randevu-sms"

FAIL=0

# --- Çıktı biçimi ------------------------------------------------------------
# 47 kriterin hepsini tek tek basmak okunmuyor. Varsayılan kip GRUPLU: her
# ticket için bir başlık, altında YALNIZ düşen kriterler, sonda özet tablosu.
# Her kriter yine tek tek değerlendirilir (accumulator korunur); değişen
# sadece ne yazdırıldığı.
#
# Tüm [OK] satırlarını görmek için:
#   docker exec -e CHECK_VERBOSE=1 -u root lab-901-gun-02a bash /lab/check.sh
VERBOSE="${CHECK_VERBOSE:-0}"

SEC=""
SEC_OK=0
SEC_N=0
SUMMARY=""
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
ok()   { SEC_N=$((SEC_N + 1)); SEC_OK=$((SEC_OK + 1))
         [ "$VERBOSE" = "1" ] && echo "[OK]   $1"
         return 0; }
bad()  { SEC_N=$((SEC_N + 1)); echo "[FAIL] $1"; FAIL=1; return 0; }
note() { echo "[NOTE] $1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

nlines()   { [ -f "$1" ] && awk 'END {print NR + 0}' "$1" || echo 0; }
other_bits() { m="$(stat -c %a "$1" 2>/dev/null)"; echo $(( 8#${m:-0} & 7 )); }
as_student() { su - "$STUDENT" -c "$1"; }

# Tek satırlık dosyanın değerini boşluklar kırpılmış olarak döker.
one_value() {
    [ -f "$1" ] || { echo ""; return 0; }
    tr -d '[:space:]' < "$1"
}

in_group() {
    # $1 = kullanıcı, $2 = grup
    id -nG "$1" 2>/dev/null | tr ' ' '\n' | grep -qx "$2"
}

# =============================================================================
section "Ticket 1 — Kurtarılan dosyalarda karışık izin (kaynak: lab 001)"
# =============================================================================
GIZLI="$KLINIK/gizli/hastasahibi-iletisim.csv"
NOTLAR="$KLINIK/ortak/haftalik-notlar.txt"
YEDEKAL="$KLINIK/scriptler/yedek-al.sh"

# student'ın /srv/klinik'e girebilmesi Ticket 2.9'a (vetekip üyeliği) bağlı.
# Giremiyorsa aşağıdaki student-perspektifli kriterler düşer; sebebi burada
# açıkça söylenir ki Ticket 1'in kendi hatası sanılmasın.
if ! as_student "cd $KLINIK" >/dev/null 2>&1; then
    note "student $KLINIK dizinine giremiyor — Ticket 2.5/2.9'a bak (2770 dizinde 'other' hiçbir şey göremez)"
fi

# --- 1.1 gizli dosya sahipliği root:root KALMALI ---
r=""
if [ ! -f "$GIZLI" ]; then
    r="$GIZLI yok"
elif [ "$(stat -c '%U:%G' "$GIZLI")" != "root:root" ]; then
    r="sahiplik root:root kalmaliydi (su an: $(stat -c '%U:%G' "$GIZLI")) — chown cozum degil"
fi
[ -z "$r" ] && ok "Ticket 1.1 — hastasahibi-iletisim.csv sahipligi root:root (kaynak: lab 001)" \
           || bad "Ticket 1.1 — $r (kaynak: lab 001)"

# --- 1.2 gizli dosya modu tam 600 ---
r=""
if [ ! -f "$GIZLI" ]; then
    r="$GIZLI yok"
elif [ "$(stat -c %a "$GIZLI")" != "600" ]; then
    r="mod 600 olmaliydi (su an: $(stat -c %a "$GIZLI"))"
fi
[ -z "$r" ] && ok "Ticket 1.2 — hastasahibi-iletisim.csv modu 600 (kaynak: lab 001)" \
           || bad "Ticket 1.2 — $r (kaynak: lab 001)"

# --- 1.3 student OKUYAMAMALI (negatif test) ---
r=""
if [ ! -f "$GIZLI" ]; then
    r="$GIZLI yok"
elif as_student "cat $GIZLI" >/dev/null 2>&1; then
    r="student dosyayi hala okuyabiliyor — kilitlenmemis"
fi
[ -z "$r" ] && ok "Ticket 1.3 — student hastasahibi-iletisim.csv'yi okuyamiyor (kaynak: lab 001)" \
           || bad "Ticket 1.3 — $r (kaynak: lab 001)"

# --- 1.4 haftalık notlar student'a ait, mod 644 ---
r=""
if [ ! -f "$NOTLAR" ]; then
    r="$NOTLAR yok"
elif [ "$(stat -c %U "$NOTLAR")" != "$STUDENT" ]; then
    r="sahibi $STUDENT olmaliydi (su an: $(stat -c %U "$NOTLAR"))"
elif [ "$(stat -c %a "$NOTLAR")" != "644" ]; then
    r="mod 644 olmaliydi (su an: $(stat -c %a "$NOTLAR"))"
fi
[ -z "$r" ] && ok "Ticket 1.4 — haftalik-notlar.txt student'a ait ve modu 644 (kaynak: lab 001)" \
           || bad "Ticket 1.4 — $r (kaynak: lab 001)"

# --- 1.5 student notları GERÇEKTEN düzenleyebiliyor (işlevsel test) ---
r=""
if [ ! -f "$NOTLAR" ]; then
    r="$NOTLAR yok"
elif ! as_student "printf '' >> $NOTLAR" >/dev/null 2>&1; then
    r="student dosyaya yazamiyor (izin veya dizin gecisi engelli)"
fi
[ -z "$r" ] && ok "Ticket 1.5 — student haftalik-notlar.txt'yi duzenleyebiliyor (kaynak: lab 001)" \
           || bad "Ticket 1.5 — $r (kaynak: lab 001)"

# --- 1.6 yedek-al.sh student tarafından ÇALIŞTIRILABİLİYOR ---
r=""
if [ ! -f "$YEDEKAL" ]; then
    r="$YEDEKAL yok"
elif ! as_student "$YEDEKAL" >/dev/null 2>&1; then
    r="student yedek-al.sh'i calistiramiyor (calistirma biti veya dizin gecisi)"
fi
[ -z "$r" ] && ok "Ticket 1.6 — student yedek-al.sh'i calistirabiliyor (kaynak: lab 001)" \
           || bad "Ticket 1.6 — $r (kaynak: lab 001)"

# --- 1.7 dizinden GEÇEBİLME ayrı bir bit ---
r=""
if [ ! -d "$KLINIK/scriptler" ]; then
    r="$KLINIK/scriptler dizini yok"
elif [ $(( $(other_bits "$KLINIK/scriptler") & 5 )) -ne 5 ]; then
    r="scriptler/ 'other' icin en az r-x olmali (mod $(stat -c %a "$KLINIK/scriptler"))"
elif ! as_student "cd $KLINIK/scriptler" >/dev/null 2>&1; then
    r="student scriptler/ dizinine giremiyor"
fi
[ -z "$r" ] && ok "Ticket 1.7 — scriptler/ dizini student icin gecilebilir (kaynak: lab 001)" \
           || bad "Ticket 1.7 — $r (kaynak: lab 001)"

# =============================================================================
section "Ticket 2 — Personel hesaplarını yedek sunucuda kur (kaynak: lab 002)"
# =============================================================================

# --- 2.1 vetekip grubu, GID tam 4600 ---
r=""
if ! getent group vetekip >/dev/null 2>&1; then
    r="vetekip grubu yok"
else
    g="$(getent group vetekip | cut -d: -f3)"
    [ "$g" = "4600" ] || r="vetekip GID 4600 olmaliydi (su an: $g)"
fi
[ -z "$r" ] && ok "Ticket 2.1 — vetekip grubu var, GID 4600 (kaynak: lab 002)" \
           || bad "Ticket 2.1 — $r (kaynak: lab 002)"

# --- 2.2 derya ve kaan: ev dizini kendilerine ait, kabuk /bin/bash ---
r=""
for u in derya kaan; do
    if ! id "$u" >/dev/null 2>&1; then
        r="$u kullanicisi yok"; break
    fi
    if [ ! -d "/home/$u" ]; then
        r="/home/$u dizini yok"; break
    fi
    if [ "$(stat -c %U "/home/$u")" != "$u" ]; then
        r="/home/$u sahibi $u olmaliydi (su an: $(stat -c %U "/home/$u"))"; break
    fi
    sh="$(getent passwd "$u" | cut -d: -f7)"
    if [ "$sh" != "/bin/bash" ]; then
        r="$u kabugu /bin/bash olmaliydi (su an: $sh)"; break
    fi
done
[ -z "$r" ] && ok "Ticket 2.2 — derya ve kaan var, ev dizini ve kabuk dogru (kaynak: lab 002)" \
           || bad "Ticket 2.2 — $r (kaynak: lab 002)"

# --- 2.3 birincil grup kendi adı, vetekip ikincil ---
r=""
for u in derya kaan; do
    if ! id "$u" >/dev/null 2>&1; then
        r="$u kullanicisi yok"; break
    fi
    pg="$(id -gn "$u" 2>/dev/null)"
    if [ "$pg" != "$u" ]; then
        r="$u birincil grubu $u olmaliydi (su an: $pg)"; break
    fi
    if ! in_group "$u" vetekip; then
        r="$u vetekip grubunda degil (ikincil grup olmali)"; break
    fi
done
[ -z "$r" ] && ok "Ticket 2.3 — derya/kaan birincil grubu kendi adi, vetekip ikincil (kaynak: lab 002)" \
           || bad "Ticket 2.3 — $r (kaynak: lab 002)"

# --- 2.4 randevubot: nologin kabuk, vetekip üyesi ---
r=""
if ! id randevubot >/dev/null 2>&1; then
    r="randevubot hesabi yok"
else
    sh="$(getent passwd randevubot | cut -d: -f7)"
    case "$sh" in
        *nologin|*/false) ;;
        *) r="randevubot kabugu nologin olmaliydi (su an: $sh)" ;;
    esac
    [ -z "$r" ] && ! in_group randevubot vetekip \
        && r="randevubot vetekip grubunda degil"
fi
[ -z "$r" ] && ok "Ticket 2.4 — randevubot servis hesabi: nologin ve vetekip uyesi (kaynak: lab 002)" \
           || bad "Ticket 2.4 — $r (kaynak: lab 002)"

# --- 2.5 randevubot'un ev dizini OLUŞMAMALI (negatif test) ---
r=""
if ! id randevubot >/dev/null 2>&1; then
    r="randevubot hesabi yok"
elif [ -e /home/randevubot ]; then
    r="/home/randevubot olusturulmus — servis hesabina ev dizini acilmaz"
fi
[ -z "$r" ] && ok "Ticket 2.5 — randevubot'un ev dizini yok (kaynak: lab 002)" \
           || bad "Ticket 2.5 — $r (kaynak: lab 002)"

# --- 2.6 /srv/klinik sahiplik root:vetekip, mod tam 2770 ---
r=""
if [ ! -d "$KLINIK" ]; then
    r="$KLINIK dizini yok"
else
    v="$(stat -c '%U:%G:%a' "$KLINIK")"
    [ "$v" = "root:vetekip:2770" ] || \
        r="root:vetekip:2770 olmaliydi (su an: $v) — setgid biti '2' dahil"
fi
[ -z "$r" ] && ok "Ticket 2.6 — /srv/klinik root:vetekip ve modu 2770 (kaynak: lab 002)" \
           || bad "Ticket 2.6 — $r (kaynak: lab 002)"

# --- 2.7 setgid DAVRANIŞI: derya açar, grup vetekip'e düşer, kaan yazar ---
r=""
PROBE="$KLINIK/.setgid-probe.$$"
if ! id derya >/dev/null 2>&1 || ! id kaan >/dev/null 2>&1; then
    r="derya veya kaan yok, davranis sinanamadi"
elif ! su - derya -c "touch $PROBE && chmod 660 $PROBE" >/dev/null 2>&1; then
    r="derya $KLINIK icinde dosya acamiyor"
else
    pg="$(stat -c %G "$PROBE" 2>/dev/null)"
    if [ "$pg" != "vetekip" ]; then
        r="derya'nin actigi dosya vetekip grubuna dusmedi (grup: $pg) — setgid biti yok"
    elif ! su - kaan -c "printf x >> $PROBE" >/dev/null 2>&1; then
        r="kaan derya'nin actigi dosyaya yazamiyor"
    fi
fi
rm -f "$PROBE"
[ -z "$r" ] && ok "Ticket 2.7 — setgid davranisi calisiyor: derya acar, kaan yazar (kaynak: lab 002)" \
           || bad "Ticket 2.7 — $r (kaynak: lab 002)"

# --- 2.8 oguz hesabı ve ev dizini kaldırılmış (negatif test) ---
r=""
if id oguz >/dev/null 2>&1; then
    r="oguz hesabi hala duruyor"
elif [ -e /home/oguz ]; then
    r="/home/oguz dizini hala duruyor"
fi
[ -z "$r" ] && ok "Ticket 2.8 — oguz hesabi ve /home/oguz kaldirilmis (kaynak: lab 002)" \
           || bad "Ticket 2.8 — $r (kaynak: lab 002)"

# --- 2.9 derya wheel grubunda OLMAMALI (negatif test) ---
r=""
if ! id derya >/dev/null 2>&1; then
    r="derya kullanicisi yok"
elif in_group derya wheel; then
    r="derya wheel grubunda — olmamaliydi"
fi
[ -z "$r" ] && ok "Ticket 2.9 — derya wheel grubunda degil (kaynak: lab 002)" \
           || bad "Ticket 2.9 — $r (kaynak: lab 002)"

# --- 2.10 student de vetekip üyesi (2770 dizinde 'other' hiçbir şey göremez) ---
r=""
if ! in_group "$STUDENT" vetekip; then
    r="student vetekip grubunda degil — 2770 dizinde 'other' hicbir sey goremez, Ticket 3 ve 4 kilitlenir"
fi
[ -z "$r" ] && ok "Ticket 2.10 — student vetekip grubuna eklenmis (kaynak: lab 002)" \
           || bad "Ticket 2.10 — $r (kaynak: lab 002)"

# =============================================================================
section "Ticket 3 — Kurtarılan klinik verisini düzenle (kaynak: lab 003)"
# =============================================================================
ARSIV="$KLINIK/arsiv"

# --- 3.1 30 günden eski .log dosyaları arsiv/ altında, yeniler yerinde ---
r=""
for f in nisan-muayene.log mayis-muayene.log asi-eski.log; do
    if [ ! -f "$ARSIV/$f" ]; then
        r="$ARSIV/$f yok — 30 gunden eski loglar arsive tasinmaliydi"; break
    fi
done
if [ -z "$r" ]; then
    kalan="$(find "$KLINIK" -path "$ARSIV" -prune -o \
                 -type f -name '*.log' -mtime +30 -print 2>/dev/null | wc -l)"
    if [ "$kalan" -ne 0 ]; then
        r="arsiv disinda hala 30 gunden eski .log var ($kalan adet)"
    elif [ ! -f "$KLINIK/muayene/guncel-muayene.log" ] || \
         [ ! -f "$KLINIK/laboratuvar/tahlil.log" ]; then
        r="yeni loglar yerinde kalmaliydi, tasinmis veya silinmis"
    fi
fi
[ -z "$r" ] && ok "Ticket 3.1 — eski .log dosyalari arsiv/ altinda, yeniler yerinde (kaynak: lab 003)" \
           || bad "Ticket 3.1 — $r (kaynak: lab 003)"

# --- 3.2 0 byte artıklar silinmiş; dolu dosyalar ve boş dizinler duruyor ---
r=""
bos="$(find "$KLINIK" -type f -empty 2>/dev/null | wc -l)"
if [ "$bos" -ne 0 ]; then
    r="hala $bos adet 0 byte dosya var"
elif [ ! -s "$KLINIK/gecici/onbellek.dat" ] && \
     [ ! -s "$KLINIK/buyuk-dosyalar/onbellek.dat" ]; then
    r="dolu dosya onbellek.dat silinmis — yalniz 0 byte olanlar silinmeliydi"
elif [ ! -s "$KLINIK/laboratuvar/tahlil-saglam.sql" ]; then
    r="dolu dosya tahlil-saglam.sql silinmis"
elif [ ! -d "$KLINIK/bos-klasor" ]; then
    r="bos-klasor/ silinmis — bos DIZINLERE dokunulmayacakti"
fi
[ -z "$r" ] && ok "Ticket 3.2 — 0 byte artiklar silindi, dolu dosyalar ve bos dizin duruyor (kaynak: lab 003)" \
           || bad "Ticket 3.2 — $r (kaynak: lab 003)"

# --- 3.3 ayarlar-yedek/ metadata ve içerik olarak birebir kopya ---
r=""
if [ ! -d "$KLINIK/ayarlar" ] || [ ! -d "$KLINIK/ayarlar-yedek" ]; then
    r="ayarlar/ veya ayarlar-yedek/ dizini yok"
else
    (cd "$KLINIK/ayarlar" && find . -type f | sort) > "$TMP/a-set" 2>/dev/null
    (cd "$KLINIK/ayarlar-yedek" && find . -type f | sort) > "$TMP/b-set" 2>/dev/null
    if ! cmp -s "$TMP/a-set" "$TMP/b-set"; then
        r="iki dizinin dosya kumesi ayni degil"
    else
        while IFS= read -r rel; do
            a="$KLINIK/ayarlar/$rel"
            b="$KLINIK/ayarlar-yedek/$rel"
            sa="$(stat -c '%a %U:%G %Y' "$a" 2>/dev/null)"
            sb="$(stat -c '%a %U:%G %Y' "$b" 2>/dev/null)"
            if [ "$sa" != "$sb" ]; then
                r="$rel metadata farkli (kaynak: $sa / yedek: $sb) — cp -a gerekiyor"
                break
            fi
            if ! cmp -s "$a" "$b"; then
                r="$rel icerigi farkli"
                break
            fi
        done < <(sed 's|^\./||' "$TMP/a-set")
    fi
fi
[ -z "$r" ] && ok "Ticket 3.3 — ayarlar-yedek/ metadata ve icerik olarak birebir kopya (kaynak: lab 003)" \
           || bad "Ticket 3.3 — $r (kaynak: lab 003)"

# --- 3.4 büyük dosyalar buyuk-dosyalar/, küçükler gecici/ altında ---
r=""
if [ ! -d "$KLINIK/buyuk-dosyalar" ]; then
    r="$KLINIK/buyuk-dosyalar dizini yok"
else
    kalan="$(find "$KLINIK/rontgen" -maxdepth 1 -type f -size +1M 2>/dev/null | wc -l)"
    if [ "$kalan" -ne 0 ]; then
        r="rontgen/ altinda hala 1 MB'den buyuk dosya var ($kalan adet)"
    else
        for f in rontgen-ham-01.img rontgen-ham-02.img; do
            [ -f "$KLINIK/buyuk-dosyalar/$f" ] || \
                { r="buyuk-dosyalar/$f yok"; break; }
        done
        if [ -z "$r" ]; then
            for f in onizleme-01.dat onizleme-02.dat; do
                [ -f "$KLINIK/gecici/$f" ] || \
                    { r="gecici/$f yok — kucuk dosyalar gecici/ altinda toplanmaliydi"; break; }
            done
        fi
    fi
fi
[ -z "$r" ] && ok "Ticket 3.4 — buyuk rontgen dosyalari ve kucuk gecici dosyalar dogru dizinde (kaynak: lab 003)" \
           || bad "Ticket 3.4 — $r (kaynak: lab 003)"

# --- 3.5 raporlar/guncel sembolik linki EN YENİ CSV'yi gösteriyor ---
r=""
GUNCEL="$KLINIK/raporlar/guncel"
if [ ! -L "$GUNCEL" ]; then
    r="$GUNCEL sembolik link degil"
else
    yeni="$(find "$KLINIK/raporlar" -maxdepth 1 -type f -name '*.csv' \
              -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
    hedef="$(readlink -f "$GUNCEL" 2>/dev/null)"
    if [ -z "$yeni" ]; then
        r="raporlar/ altinda csv bulunamadi"
    elif [ "$hedef" != "$(readlink -f "$yeni")" ]; then
        r="link $hedef gosteriyor, en yeni csv $yeni — 'en yeni dosya' ile 'en yeni csv' ayni sey degil"
    fi
fi
[ -z "$r" ] && ok "Ticket 3.5 — raporlar/guncel en yeni csv'ye isaret ediyor (kaynak: lab 003)" \
           || bad "Ticket 3.5 — $r (kaynak: lab 003)"

# --- 3.6 tüm .sh student ile çalışabiliyor; diğerlerinde x biti YOK ---
r=""
if [ ! -d "$KLINIK/scriptler" ]; then
    r="$KLINIK/scriptler dizini yok"
else
    while IFS= read -r s; do
        [ -n "$s" ] || continue
        if ! as_student "$s" >/dev/null 2>&1; then
            r="$s student tarafindan calistirilamiyor"
            break
        fi
    done < <(find "$KLINIK/scriptler" -type f -name '*.sh' 2>/dev/null)
    if [ -z "$r" ]; then
        fazla="$(find "$KLINIK/scriptler" -type f ! -name '*.sh' -perm /111 2>/dev/null | wc -l)"
        [ "$fazla" -eq 0 ] || \
            r=".sh olmayan $fazla dosyada calistirma biti var — olmamaliydi"
    fi
fi
[ -z "$r" ] && ok "Ticket 3.6 — tum .sh calistirilabiliyor, digerlerinde x biti yok (kaynak: lab 003)" \
           || bad "Ticket 3.6 — $r (kaynak: lab 003)"

# =============================================================================
section "Ticket 4 — Log ve ayar analizi (kaynak: lab 004)"
# =============================================================================
ERISIM="$KLINIK/loglar/erisim.log"
UYGULAMA="$KLINIK/loglar/uygulama.log"

# --- 4.1 student loglari sudo'suz okuyabiliyor ---
r=""
if ! as_student "cat $ERISIM" >/dev/null 2>&1; then
    r="student erisim.log'u okuyamiyor"
elif ! as_student "cat $UYGULAMA" >/dev/null 2>&1; then
    r="student uygulama.log'u okuyamiyor"
fi
[ -z "$r" ] && ok "Ticket 4.1 — student iki logu da sudo'suz okuyabiliyor (kaynak: lab 004)" \
           || bad "Ticket 4.1 — $r (kaynak: lab 004)"

# --- 4.2 hatalar.log: yalnız durum kodu 500 olan satırlar, orijinal sırada ---
r=""
awk '$(NF-1) == 500' "$ORIG/erisim.log" > "$TMP/exp-hatalar" 2>/dev/null
if [ ! -f "$RAPOR/hatalar.log" ]; then
    r="$RAPOR/hatalar.log yok"
elif ! cmp -s "$TMP/exp-hatalar" "$RAPOR/hatalar.log"; then
    fazla="$(awk '$(NF-1) != 500' "$RAPOR/hatalar.log" 2>/dev/null | wc -l)"
    if [ "$fazla" -gt 0 ]; then
        r="durum kodu 500 OLMAYAN $fazla satir var — boyut alani 500 ve yolunda /500 gecen satirlar tuzak"
    else
        r="satir sayisi/sirasi beklenenle ayni degil (beklenen: $(nlines "$TMP/exp-hatalar"), bulunan: $(nlines "$RAPOR/hatalar.log"))"
    fi
fi
[ -z "$r" ] && ok "Ticket 4.2 — hatalar.log yalniz durum 500 satirlarini iceriyor (kaynak: lab 004)" \
           || bad "Ticket 4.2 — $r (kaynak: lab 004)"

# --- 4.3 en-cok-istek.txt: en çok istek yapan 5 IP, azalan sırada ---
r=""
awk '{print $1}' "$ORIG/erisim.log" | sort | uniq -c | sort -rn | head -5 \
    | awk '{print $1, $2}' > "$TMP/exp-ip" 2>/dev/null
if [ ! -f "$RAPOR/en-cok-istek.txt" ]; then
    r="$RAPOR/en-cok-istek.txt yok"
else
    awk 'NF {print $1, $2}' "$RAPOR/en-cok-istek.txt" > "$TMP/got-ip" 2>/dev/null
    cmp -s "$TMP/exp-ip" "$TMP/got-ip" || \
        r="beklenen ilk 5 IP dokumu tutmuyor (beklenen ilk satir: $(head -1 "$TMP/exp-ip"))"
fi
[ -z "$r" ] && ok "Ticket 4.3 — en-cok-istek.txt en cok istek yapan 5 IP'yi azalan sirada veriyor (kaynak: lab 004)" \
           || bad "Ticket 4.3 — $r (kaynak: lab 004)"

# --- 4.4 tekil-kullanici.txt: doğru tekil kullanıcı sayısı, tek satır ---
r=""
EXP_U="$(awk '$3 != "-" {print $3}' "$ORIG/erisim.log" | sort -u | wc -l | tr -d ' ')"
if [ ! -f "$RAPOR/tekil-kullanici.txt" ]; then
    r="$RAPOR/tekil-kullanici.txt yok"
elif [ "$(nlines "$RAPOR/tekil-kullanici.txt")" -ne 1 ]; then
    r="tek satir olmali (su an: $(nlines "$RAPOR/tekil-kullanici.txt") satir)"
else
    v="$(one_value "$RAPOR/tekil-kullanici.txt")"
    case "$v" in
        ''|*[!0-9]*) r="yalniz sayi olmali (su an: '$v')" ;;
        *) [ "$v" = "$EXP_U" ] || r="tekil kullanici sayisi $EXP_U olmaliydi (su an: $v) — '-' kullanici degildir" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 4.4 — tekil-kullanici.txt dogru tekil kullanici sayisini veriyor (kaynak: lab 004)" \
           || bad "Ticket 4.4 — $r (kaynak: lab 004)"

# --- 4.5 uyarilar.tsv: yalnız WARN satırları, TAB ayraçlı, orijinal sırada ---
r=""
awk -F'|' '$2 == "WARN" {printf "%s\t%s\n", $1, $3}' "$ORIG/uygulama.log" \
    > "$TMP/exp-warn" 2>/dev/null
if [ ! -f "$RAPOR/uyarilar.tsv" ]; then
    r="$RAPOR/uyarilar.tsv yok"
elif [ "$(awk -F'\t' 'NF != 2' "$RAPOR/uyarilar.tsv" 2>/dev/null | wc -l)" -ne 0 ]; then
    r="her satir TAB ile ayrilmis tam 2 alan olmali"
elif ! cmp -s "$TMP/exp-warn" "$RAPOR/uyarilar.tsv"; then
    r="WARN dokumu tutmuyor (beklenen $(nlines "$TMP/exp-warn") satir, bulunan $(nlines "$RAPOR/uyarilar.tsv")) — mesaj govdesinde gecen seviye adlari tuzak"
fi
[ -z "$r" ] && ok "Ticket 4.5 — uyarilar.tsv yalniz WARN satirlarini TAB ayrali veriyor (kaynak: lab 004)" \
           || bad "Ticket 4.5 — $r (kaynak: lab 004)"

# --- 4.6 sistem.conf: debug kapalı, eski sunucu yok, yorumlar KORUNMUŞ ---
r=""
CONF="$CONFDIR/sistem.conf"
if [ ! -f "$CONF" ]; then
    r="$CONF yok"
else
    aktif_debug="$(grep -v '^[[:space:]]*#' "$CONF" | grep -i 'debug' | grep -ci 'true' || true)"
    aktif_eski="$(grep -v '^[[:space:]]*#' "$CONF" | grep -ci 'eskisunucu' || true)"
    grep '^[[:space:]]*#' "$ORIG/sistem.conf" > "$TMP/exp-yorum" 2>/dev/null
    grep '^[[:space:]]*#' "$CONF"             > "$TMP/got-yorum" 2>/dev/null
    if [ "$aktif_debug" -ne 0 ]; then
        r="debug hala acik gorunuyor (aktif satirda 'true')"
    elif [ "$aktif_eski" -ne 0 ]; then
        r="aktif satirlarda hala eskisunucu referansi var ($aktif_eski adet)"
    elif ! cmp -s "$TMP/exp-yorum" "$TMP/got-yorum"; then
        r="yorum satirlari degismis — yalniz aktif satirlar duzeltilecekti"
    fi
fi
[ -z "$r" ] && ok "Ticket 4.6 — sistem.conf: debug kapali, eski sunucu temiz, yorumlar korunmus (kaynak: lab 004)" \
           || bad "Ticket 4.6 — $r (kaynak: lab 004)"

# --- 4.7 cihazlar-temiz.txt: yorum ve boş satır yok, içerik korunmuş ---
r=""
grep -v '^[[:space:]]*#' "$ORIG/cihazlar.list" | grep -v '^[[:space:]]*$' \
    > "$TMP/exp-cihaz" 2>/dev/null
if [ ! -f "$RAPOR/cihazlar-temiz.txt" ]; then
    r="$RAPOR/cihazlar-temiz.txt yok"
elif [ "$(grep -c '^[[:space:]]*#' "$RAPOR/cihazlar-temiz.txt" || true)" -ne 0 ]; then
    r="hala yorum satiri var"
elif [ "$(grep -c '^[[:space:]]*$' "$RAPOR/cihazlar-temiz.txt" || true)" -ne 0 ]; then
    r="hala bos satir var"
elif ! cmp -s "$TMP/exp-cihaz" "$RAPOR/cihazlar-temiz.txt"; then
    r="cihaz listesi beklenenle ayni degil (beklenen $(nlines "$TMP/exp-cihaz") satir, bulunan $(nlines "$RAPOR/cihazlar-temiz.txt"))"
fi
[ -z "$r" ] && ok "Ticket 4.7 — cihazlar-temiz.txt yorum ve bos satirdan arindirilmis (kaynak: lab 004)" \
           || bad "Ticket 4.7 — $r (kaynak: lab 004)"

# =============================================================================
section "Ticket 5 — Başıboş süreçler (kaynak: lab 005)"
# =============================================================================
BPID="$(pgrep -f 'KLINIKPROC-toplu' 2>/dev/null | head -1)"
BNICE=""
[ -n "$BPID" ] && BNICE="$(ps -o ni= -p "$BPID" 2>/dev/null | tr -d '[:space:]')"

# --- 5.1 surecler.txt: KLINIKPROC süreçleri PID + komut satırıyla ---
r=""
SUR="$RAPOR/surecler.txt"
if [ ! -f "$SUR" ]; then
    r="$SUR yok"
elif ! as_student "cat $SUR" >/dev/null 2>&1; then
    r="student surecler.txt'yi okuyamiyor"
elif [ "$(nlines "$SUR")" -eq 0 ]; then
    r="surecler.txt bos"
elif grep -qE '(^|[[:space:]]|/)e?grep' "$SUR"; then
    r="kendi arama komutunun satiri listeye karismis (grep self-match)"
elif [ "$(grep -vE 'KLINIKPROC' "$SUR" | grep -c . || true)" -ne 0 ]; then
    r="KLINIKPROC icermeyen satirlar var — yalniz isaretli surecler listelenmeliydi"
elif [ "$(grep -cE '^[[:space:]]*[0-9]+[[:space:]]' "$SUR" || true)" -eq 0 ]; then
    r="satirlar PID ile baslamali (PID + komut satiri)"
fi
[ -z "$r" ] && ok "Ticket 5.1 — surecler.txt KLINIKPROC sureclerini PID ve komutla listeliyor (kaynak: lab 005)" \
           || bad "Ticket 5.1 — $r (kaynak: lab 005)"

# --- 5.2 KLINIKPROC-asili öldürülmüş (TERM yetmez, KILL şart) ---
r=""
pgrep -f 'KLINIKPROC-asili' >/dev/null 2>&1 && \
    r="KLINIKPROC-asili hala calisiyor — TERM'i trap ile yok sayiyor, KILL gerekiyor"
[ -z "$r" ] && ok "Ticket 5.2 — KLINIKPROC-asili surec tablosunda yok (kaynak: lab 005)" \
           || bad "Ticket 5.2 — $r (kaynak: lab 005)"

# --- 5.3 KLINIKPROC-sahte öldürülmüş ---
r=""
pgrep -f 'KLINIKPROC-sahte' >/dev/null 2>&1 && \
    r="KLINIKPROC-sahte hala calisiyor (comm alaninda sahte cekirdek-thread adiyla gorunuyor)"
[ -z "$r" ] && ok "Ticket 5.3 — KLINIKPROC-sahte surec tablosunda yok (kaynak: lab 005)" \
           || bad "Ticket 5.3 — $r (kaynak: lab 005)"

# --- 5.4 KLINIKPROC-toplu hâlâ çalışıyor ve nice >= 10 ---
r=""
if [ -z "$BPID" ]; then
    r="KLINIKPROC-toplu calismiyor — oldurulmeyecekti, yavaslatilacakti"
elif [ -z "$BNICE" ]; then
    r="KLINIKPROC-toplu nice degeri okunamadi"
else
    case "$BNICE" in
        ''|*[!0-9-]*) r="nice degeri sayi degil ('$BNICE')" ;;
        *) [ "$BNICE" -ge 10 ] || r="nice degeri >= 10 olmaliydi (su an: $BNICE)" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 5.4 — KLINIKPROC-toplu calisiyor ve nice >= 10 (kaynak: lab 005)" \
           || bad "Ticket 5.4 — $r (kaynak: lab 005)"

# --- 5.5 toplu-nice.txt: tek satır, gerçek nice değeriyle aynı ---
r=""
TN="$RAPOR/toplu-nice.txt"
if [ ! -f "$TN" ]; then
    r="$TN yok"
elif [ "$(nlines "$TN")" -ne 1 ]; then
    r="tek satir olmali (su an: $(nlines "$TN") satir)"
elif [ -z "$BNICE" ]; then
    r="KLINIKPROC-toplu calismadigi icin karsilastirilamadi"
else
    v="$(one_value "$TN")"
    case "$v" in
        ''|*[!0-9-]*) r="yalniz sayi olmali (su an: '$v')" ;;
        *) [ "$v" -eq "$BNICE" ] || r="gercek nice $BNICE, dosyada $v yaziyor" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 5.5 — toplu-nice.txt gercek nice degeriyle ayni (kaynak: lab 005)" \
           || bad "Ticket 5.5 — $r (kaynak: lab 005)"

# =============================================================================
section "Ticket 6 — Gün sonu özet scriptleri (kaynak: lab 006)"
# =============================================================================
LOGOZET="$BINDIR/logozet.sh"
DURUM="$BINDIR/durumkontrol.sh"
GUNSONU="$BINDIR/gunsonu-rapor.sh"
GLOG="$LOGDIR/gunsonu.log"
DLOG="$LOGDIR/denetim.log"
RAPORTXT="$RAPOR/gunsonu.txt"

SO="$TMP/so"; SE="$TMP/se"
run_student() { as_student "$1" > "$SO" 2> "$SE"; echo $?; }

# Beklenen seviye sayımları CANLI logdan hesaplanır.
awk -F'|' 'NF >= 2 {c[$2]++} END {for (l in c) printf "%s:%d\n", l, c[l]}' \
    "$GLOG" 2>/dev/null | sort > "$TMP/exp-ozet"

# --- 6.1 logozet.sh bir log dosyasıyla doğru sayımı basar, çıkış 0 ---
r=""
rc="$(run_student "logozet.sh $GLOG")"
if [ "$rc" != "0" ]; then
    r="cikis kodu 0 olmaliydi (su an: $rc)"
elif [ ! -s "$SO" ]; then
    r="stdout bos"
else
    sort "$SO" > "$TMP/got-ozet"
    cmp -s "$TMP/exp-ozet" "$TMP/got-ozet" || \
        r="seviye sayimlari tutmuyor — mesaj govdesinde gecen seviye adlari tuzak (beklenen: $(tr '\n' ' ' < "$TMP/exp-ozet"))"
fi
[ -z "$r" ] && ok "Ticket 6.1 — logozet.sh seviye sayimlarini dogru basiyor, cikis 0 (kaynak: lab 006)" \
           || bad "Ticket 6.1 — $r (kaynak: lab 006)"

# --- 6.2 logozet.sh argümansız: stdout boş, stderr dolu, çıkış 2 ---
r=""
rc="$(run_student "logozet.sh")"
if [ "$rc" != "2" ]; then
    r="argumansiz cagride cikis kodu 2 olmaliydi (su an: $rc)"
elif [ -s "$SO" ]; then
    r="argumansiz cagride stdout bos olmaliydi"
elif [ ! -s "$SE" ]; then
    r="argumansiz cagride stderr'e kullanim mesaji yazilmaliydi"
fi
[ -z "$r" ] && ok "Ticket 6.2 — logozet.sh argumansiz: stdout bos, stderr dolu, cikis 2 (kaynak: lab 006)" \
           || bad "Ticket 6.2 — $r (kaynak: lab 006)"

# --- 6.3 logozet.sh olmayan dosya: çıkış 3 ---
r=""
rc="$(run_student "logozet.sh /var/log/klinik/olmayan.log")"
if [ "$rc" != "3" ]; then
    r="olmayan dosyada cikis kodu 3 olmaliydi (su an: $rc)"
elif [ -s "$SO" ]; then
    r="hata durumunda stdout bos olmaliydi"
fi
[ -z "$r" ] && ok "Ticket 6.3 — logozet.sh olmayan dosyada cikis 3 (kaynak: lab 006)" \
           || bad "Ticket 6.3 — $r (kaynak: lab 006)"

# --- 6.4 logozet.sh okunamayan dosya: çıkış 3 ([ -f ] ile [ -r ] farkı) ---
r=""
rc="$(run_student "logozet.sh $DLOG")"
if [ "$rc" != "3" ]; then
    r="okunamayan dosyada cikis kodu 3 olmaliydi (su an: $rc) — dosya VAR ama okunamiyor, [ -f ] yetmez"
elif [ -s "$SO" ]; then
    r="hata durumunda stdout bos olmaliydi"
fi
[ -z "$r" ] && ok "Ticket 6.4 — logozet.sh okunamayan dosyada cikis 3 (kaynak: lab 006)" \
           || bad "Ticket 6.4 — $r (kaynak: lab 006)"

# --- 6.5 durumkontrol.sh biçim ve sıra: [OK] ad PID / [FAIL] ad ---
r=""
rc="$(run_student "durumkontrol.sh randevu-web randevu-kuyruk randevu-islem")"
if [ "$(nlines "$SO")" -ne 3 ]; then
    r="3 servis icin 3 satir bekleniyordu (su an: $(nlines "$SO"))"
else
    l1="$(sed -n 1p "$SO")"; l2="$(sed -n 2p "$SO")"; l3="$(sed -n 3p "$SO")"
    case "$l1" in
        '[OK] randevu-web '*) ;;
        *) r="1. satir '[OK] randevu-web PID' olmaliydi (su an: '$l1')" ;;
    esac
    [ -z "$r" ] && case "$l2" in
        '[FAIL] randevu-kuyruk'*) ;;
        *) r="2. satir '[FAIL] randevu-kuyruk' olmaliydi (su an: '$l2') — bu servis BILEREK ayakta degil" ;;
    esac
    [ -z "$r" ] && case "$l3" in
        '[OK] randevu-islem '*) ;;
        *) r="3. satir '[OK] randevu-islem PID' olmaliydi (su an: '$l3')" ;;
    esac
fi
[ -z "$r" ] && ok "Ticket 6.5 — durumkontrol.sh dogru bicim ve sirada cikti veriyor (kaynak: lab 006)" \
           || bad "Ticket 6.5 — $r (kaynak: lab 006)"

# --- 6.6 durumkontrol.sh çıkış kodları: 0 / 1 / 2 ---
r=""
rc="$(run_student "durumkontrol.sh $SERVICES")"
if [ "$rc" != "0" ]; then
    r="hepsi ayaktayken cikis 0 olmaliydi (su an: $rc)"
else
    rc="$(run_student "durumkontrol.sh randevu-web randevu-kuyruk")"
    if [ "$rc" != "1" ]; then
        r="eksik servis varken cikis 1 olmaliydi (su an: $rc)"
    else
        rc="$(run_student "durumkontrol.sh")"
        if [ "$rc" != "2" ]; then
            r="argumansiz cagride cikis 2 olmaliydi (su an: $rc)"
        elif [ ! -s "$SE" ]; then
            r="argumansiz cagride stderr'e kullanim mesaji yazilmaliydi"
        fi
    fi
fi
[ -z "$r" ] && ok "Ticket 6.6 — durumkontrol.sh cikis kodlari 0/1/2 dogru (kaynak: lab 006)" \
           || bad "Ticket 6.6 — $r (kaynak: lab 006)"

# --- 6.7 durumkontrol.sh kendi arama sürecini listelemiyor, PID'ler gerçek ---
r=""
rc="$(run_student "durumkontrol.sh $SERVICES")"
# Script yoksa/çıktı boşsa döngü hiç dönmez ve kriter bedava geçerdi.
if [ ! -x "$DURUM" ]; then
    r="$DURUM yok veya calistirilabilir degil"
elif [ "$(nlines "$SO")" -ne 3 ]; then
    r="uc ayakta servis icin uc satir bekleniyordu (su an: $(nlines "$SO"))"
fi
[ -n "$r" ] || while IFS= read -r line; do
    case "$line" in
        '[OK] '*)
            svc="$(printf '%s' "$line" | awk '{print $2}')"
            pid="$(printf '%s' "$line" | awk '{print $3}')"
            case "$pid" in
                ''|*[!0-9]*) r="'$svc' icin gecerli bir PID yazilmamis ('$pid')"; break ;;
            esac
            cm="$(ps -o comm= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
            if [ "$cm" != "$svc" ]; then
                r="PID $pid'in surec adi '$cm', beklenen '$svc' — pgrep -f kendi arama surecini de yakaliyor, -x kullanilmali"
                break
            fi
            ;;
    esac
done < "$SO"
[ -z "$r" ] && ok "Ticket 6.7 — durumkontrol.sh gercek PID'leri basiyor, kendi surecini karistirmiyor (kaynak: lab 006)" \
           || bad "Ticket 6.7 — $r (kaynak: lab 006)"

# --- 6.8 gunsonu-rapor.sh DEGRADED yolu: çıkış 1, ilk satır DEGRADED ---
r=""
rc="$(run_student "gunsonu-rapor.sh")"
if [ ! -f "$RAPORTXT" ]; then
    r="$RAPORTXT uretilmedi"
elif [ "$(head -1 "$RAPORTXT")" != "DEGRADED" ]; then
    r="ilk satir DEGRADED olmaliydi (randevu-kuyruk ayakta degil) — su an: '$(head -1 "$RAPORTXT")'"
elif [ "$rc" != "1" ]; then
    r="DEGRADED durumda cikis kodu 1 olmaliydi (su an: $rc)"
fi
[ -z "$r" ] && ok "Ticket 6.8 — gunsonu-rapor.sh DEGRADED durumunu dogru raporluyor (kaynak: lab 006)" \
           || bad "Ticket 6.8 — $r (kaynak: lab 006)"

# --- 6.9 gunsonu.txt içeriği: servis durumları + seviye sayımları ---
r=""
if [ ! -f "$RAPORTXT" ]; then
    r="$RAPORTXT yok"
else
    for svc in $SERVICES randevu-kuyruk; do
        grep -q "$svc" "$RAPORTXT" || { r="$svc raporda gecmiyor"; break; }
    done
    if [ -z "$r" ] && grep -q 'randevu-eski' "$RAPORTXT"; then
        r="randevu-eski raporda gecmis — yorum satiri atlanmaliydi"
    fi
    if [ -z "$r" ] && grep -q '^[[:space:]]*#' "$RAPORTXT"; then
        r="ham yorum satiri rapora kopyalanmis"
    fi
    if [ -z "$r" ]; then
        while IFS= read -r sat; do
            grep -qF "$sat" "$RAPORTXT" || { r="seviye sayimi '$sat' raporda yok"; break; }
        done < "$TMP/exp-ozet"
    fi
fi
[ -z "$r" ] && ok "Ticket 6.9 — gunsonu.txt servis durumlari ve seviye sayimlarini iceriyor (kaynak: lab 006)" \
           || bad "Ticket 6.9 — $r (kaynak: lab 006)"

# --- 6.10 gunsonu-rapor.sh idempotent: ikinci koşu dosyayı büyütmüyor ---
r=""
if [ ! -f "$RAPORTXT" ]; then
    r="$RAPORTXT yok"
else
    cp -p "$RAPORTXT" "$TMP/rapor1"
    run_student "gunsonu-rapor.sh" >/dev/null
    if ! cmp -s "$TMP/rapor1" "$RAPORTXT"; then
        r="ikinci kosuda dosya degisti/buyudu — rapor her seferinde bastan yazilmali, eklenmemeli"
    fi
fi
[ -z "$r" ] && ok "Ticket 6.10 — gunsonu-rapor.sh idempotent, ikinci kosuda dosya buyumuyor (kaynak: lab 006)" \
           || bad "Ticket 6.10 — $r (kaynak: lab 006)"

# --- 6.11 gunsonu-rapor.sh HEALTHY yolu: liste gecici olarak degistirilir ---
# Servis listesi kısa süreliğine yalnız ayakta olan üç servise indirilir; koşu
# sonrası ORİJİNAL hâline geri alınır. Süreçlere dokunulmaz.
r=""
LISTE="$LISTDIR/servisler.list"
if [ ! -f "$LISTE" ]; then
    r="$LISTE yok"
else
    cp -p "$LISTE" "$TMP/liste-yedek"
    printf '%s\n' $SERVICES > "$LISTE"
    chown root:root "$LISTE"; chmod 0644 "$LISTE"
    rc="$(run_student "gunsonu-rapor.sh")"
    if [ ! -f "$RAPORTXT" ]; then
        r="HEALTHY yolunda rapor uretilmedi"
    elif [ "$(head -1 "$RAPORTXT")" != "HEALTHY" ]; then
        r="hepsi ayaktayken ilk satir HEALTHY olmaliydi (su an: '$(head -1 "$RAPORTXT")')"
    elif [ "$rc" != "0" ]; then
        r="HEALTHY durumda cikis kodu 0 olmaliydi (su an: $rc)"
    fi
    cp -p "$TMP/liste-yedek" "$LISTE"
    run_student "gunsonu-rapor.sh" >/dev/null 2>&1 || true
fi
[ -z "$r" ] && ok "Ticket 6.11 — gunsonu-rapor.sh HEALTHY durumunu dogru raporluyor (kaynak: lab 006)" \
           || bad "Ticket 6.11 — $r (kaynak: lab 006)"

# --- 6.12 üç script: pathless çalışır, other-yazma biti kapalı ---
r=""
for s in logozet.sh durumkontrol.sh gunsonu-rapor.sh; do
    p="$BINDIR/$s"
    if [ ! -f "$p" ]; then
        r="$p yok"; break
    fi
    if [ ! -x "$p" ]; then
        r="$s calistirilabilir degil"; break
    fi
    o="$(other_bits "$p")"
    if [ $(( o & 2 )) -ne 0 ]; then
        r="$s 'other' icin yazilabilir (mod $(stat -c %a "$p")) — kapatilmali"; break
    fi
    if ! as_student "command -v $s" >/dev/null 2>&1; then
        r="$s student'in PATH'inde bulunamiyor"; break
    fi
done
[ -z "$r" ] && ok "Ticket 6.12 — uc script pathless calisiyor, other-yazma biti kapali (kaynak: lab 006)" \
           || bad "Ticket 6.12 — $r (kaynak: lab 006)"

# =============================================================================
flush_section
printf '\n=== ÖZET %s\n' '======================================================'
printf '%s' "$SUMMARY"
printf '  %s\n' '-------------------------------------------------'
printf '  %3d/%-3d  TOPLAM\n' "$TOT_OK" "$TOT_N"
if [ "$FAIL" -eq 0 ]; then
    printf '\nGEÇTİ — 901-gun-02a tamamlandi.\n'
else
    printf '\nKALDI — yukaridaki [FAIL] satirlarina bak.\n'
    printf 'Tum [OK] satirlarini gormek icin: CHECK_VERBOSE=1\n'
fi
exit "$FAIL"
