# Çözüm — Lab 006: Shell Scripting Temeli

Lab shell'i içinde çalıştır (`labctl shell 006`). Üç dosya da
`/usr/local/bin` altında; dizin root'a ait olduğu için **yazarken** `sudo`
gerekir. Çalıştırırken gerekmez — kriter bunu istiyor.

`logsum` bozuk hâlde 0666 modunda, yani student onu sudo'suz da
düzenleyebilir; ama sonunda o yazma bitini kapatman şart.

---

## 1. `logsum`

```bash
sudo tee /usr/local/bin/logsum >/dev/null <<'EOF'
#!/usr/bin/env bash
# Bir log dosyasindaki seviye sayimlarini basar.
# Cikis kodu sozlesmesi: 0 basari | 2 kullanim hatasi | 3 kaynak erisilemedi

if [ "$#" -lt 1 ]; then
    echo "kullanim: logsum <logfile>" >&2
    exit 2
fi

LOG="$1"

if [ ! -r "$LOG" ]; then
    echo "logsum: okunamiyor: $LOG" >&2
    exit 3
fi

awk -F'|' 'NF >= 2 { c[$2]++ } END { for (lvl in c) printf "%s:%d\n", lvl, c[lvl] }' "$LOG"
EOF
```

**Neden `awk -F'|'`.** Log satırı `2026-07-27T03:00:12|ERROR|disk almost full`
biçiminde. `awk`'ın varsayılan ayırıcısı boşluktur; o yüzden bozuk sürümdeki
`awk '{print $2}'` ikinci *kelimeyi* basıyordu (`almost`, `labapp-web` gibi).
`-F'|'` ile alan modeli dosyanın gerçeğine uyar: `$1` zaman, `$2` seviye,
`$3` mesaj. awk programı **tek tırnak** içinde olmalı; yoksa `$2`'yi shell
kendi konumsal parametresi sanıp boş dizgeye çevirir.

**Neden `grep -c ERROR` yanlış.** Bu log'da beş satırın *mesaj gövdesinde*
bir seviye adı geçiyor (`INFO|retrying after ERROR from upstream`,
`DEBUG|WARN threshold set to 90`, `ERROR|INFO channel backlog exceeded` …).
`grep` satırın tamamına bakar, alan bilmez:

```bash
grep -c ERROR /var/log/labapp/app.log   # 9  — YANLIS
awk -F'|' '$2 == "ERROR"' /var/log/labapp/app.log | wc -l   # 6 — dogru
```

Aynı sayımı `awk` dizisi yerine boru hattıyla da yapabilirsin, ama biçimi
sen düzeltmek zorundasın:

```bash
awk -F'|' '{print $2}' /var/log/labapp/app.log | sort | uniq -c | awk '{print $2":"$1}'
```

**Çıkış kodu sözleşmesi.** Bozuk sürüm her yolda `exit 0` yapıyordu. Bu, gece
çalışan bir zincirde felakettir: dosya silinmiş olsa bile üst sistem "her şey
yolunda" sinyali alır ve alarm hiç üretilmez. Sözleşme: `0` başarı, `≠0`
başarısızlık; burada `2` = kullanım hatası (çağıran yanlış çağırdı),
`3` = kaynak erişilemedi (çağrı doğruydu, ortam bozuk). İkisini ayırmak
çağıranın farklı tepki verebilmesi içindir.

**`-f` değil `-r`.** `secure.log` var (`-f` doğru döner) ama modu 0600 ve
root'a ait — student okuyamaz. `-r` "bu süreç bu dosyayı okuyabilir mi"
sorusunu sorar; doğru soru budur. Sadece `-f` ile geçen bir çözüm burada
düşer, çünkü `awk` dosyayı açamayıp kendi hatasını stderr'e basar ve
script yanlış kodla çıkar.

**`>&2` ve stdout kirliliği.** Bozuk sürüm hata mesajını stdout'a basıyordu.
`report`, `logsum`'ın stdout'unu doğrudan raporun içine yazıyor — hata
mesajı stdout'tan giderse `daily.txt`'nin ortasına sızar ve raporu okuyan
sistem onu veri sanır. Veri stdout'tan, teşhis stderr'den gider.

---

## 2. `svccheck`

```bash
sudo tee /usr/local/bin/svccheck >/dev/null <<'EOF'
#!/usr/bin/env bash
# Verilen surec isaretlerinin ayakta olup olmadigini bildirir.
# Cikis kodu: 0 hepsi ayakta | 1 en az biri yok | 2 kullanim hatasi

if [ "$#" -eq 0 ]; then
    echo "kullanim: svccheck <isaret> [isaret...]" >&2
    exit 2
fi

rc=0
for mark in "$@"; do
    # Sade pgrep SUREC ADINA bakar. -f kullanma: o tam komut satirini
    # eslestirir ve isareti argüman olarak tasiyan kendi sureclerini bulur.
    pid="$(pgrep -x "$mark" | head -n 1)"

    if [ -n "$pid" ]; then
        printf '[OK] %s %s\n' "$mark" "$pid"
    else
        printf '[FAIL] %s\n' "$mark"
        rc=1
    fi
done

exit "$rc"
EOF
```

**Neden sade `pgrep`, neden `-f` DEĞİL.** Servisler gerçek birer binary
olarak çalışıyor: `sleep` işaretin adıyla kopyalanmış, yani süreç *adı*
(`comm`) doğrudan `labapp-web`. Kontrol et:

```bash
pgrep -x labapp-web        # PID
ps -eo pid,comm | grep '^ *[0-9]* labapp-'
```

`-x` tam eşleşme ister — `labapp-web` ile `labapp-worker` birbirine
karışmasın diye. Sade `pgrep <ad>` alt dizge eşleştirir; bu labda ikisi
birbirinin alt dizgisi olmadığı için o da çalışır, ama `-x` niyeti açık
yazar.

**`-f` burada yanlış araç.** `-f` deseni **tam komut satırında** arar. Peki
`svccheck labapp-queue` çalışırken `labapp-queue` metni nerelerde duruyor?

| süreç | komut satırı | `-f` eşler mi |
|---|---|---|
| gerçek servis | (yok, `labapp-queue` başlatılmadı) | — |
| `svccheck`'in kendisi | `bash /usr/local/bin/svccheck labapp-queue` | **evet** |
| seni çağıran kabuk | `su - student -c svccheck labapp-queue` | **evet** |
| komut ikamesinin alt kabuğu | `svccheck`'in komut satırını miras alır | **evet** |

Yani `pgrep -f labapp-queue` çalışmayan bir servis için PID döndürür ve
`[OK]` basarsın. Rapor her zaman `HEALTHY` çıkar, gece hiç alarm üretilmez.
Sessiz başarısızlık, gürültülü başarısızlıktan tehlikelidir. Kendin gör:

```bash
pgrep -x labapp-queue    # bos, cikis kodu 1  -> dogru cevap
pgrep -f labapp-queue    # PID(ler)           -> kendini bulmus
```

Üçüncü satır en sinsisi: `pid="$(pgrep -f "$mark" | ...)"` yazdığında komut
ikamesi bir **alt kabuk fork eder**, o alt kabuk `svccheck`'in komut satırını
miras alır ve boru hattını kurarken bir an süreç tablosunda durur. `pgrep`
onu bulur, sen de çoktan ölmüş bir PID'i rapora yazarsın (`ps -p <pid>`
boş döner). Yani `$$` ile kendini elemen bile yetmezdi — eleyemediğin şey
kendi *çocuğun*.

Bu, 005'teki `ps aux | grep LABPROC`'un kendi `grep` satırını listelemesiyle
aynı ders: **arama aracın aramanın içine düşmemeli.** Orada `grep -v grep`
ya da `[L]ABPROC` bracket numarasıyla çözülüyordu; burada çözüm daha basit —
doğru alana bakan aracı seç. Süreç *adına* bakarsan komut satırındaki
argümanlar hiç işin içine girmez.

**`rc` accumulator.** Döngü içinde `exit 1` yazarsan ilk `[FAIL]`'de
çıkarsın ve kalan servisler hiç raporlanmaz. Doğru desen: `rc=0` ile başla,
her başarısızlıkta `rc=1` yap, döngü bitince `exit "$rc"`.
`check.sh`'ın kendisi de tam olarak bu deseni kullanıyor — tesadüf değil,
"tüm sonuçları topla, sonunda tek karar ver" bu işin standart biçimidir.

---

## 3. `report`

```bash
sudo tee /usr/local/bin/report >/dev/null <<'EOF'
#!/usr/bin/env bash
# services.list'i okur, her servisi svccheck ile sinar, log ozetini ekler
# ve gunluk raporu sifirdan uretir.
# Cikis kodu: 0 HEALTHY | 1 DEGRADED

LIST=/etc/labs/services.list
LOG=/var/log/labapp/app.log
OUT=/srv/reports/daily.txt

BODY="$(mktemp)"
rc=0

while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
        ''|'#'*) continue ;;
    esac

    svccheck "$line" >> "$BODY" || rc=1
done < "$LIST"

logsum "$LOG" >> "$BODY"

if [ "$rc" -eq 0 ]; then
    status=HEALTHY
else
    status=DEGRADED
fi

{
    printf '%s\n' "$status"
    cat "$BODY"
} > "$OUT"

rm -f "$BODY"
exit "$rc"
EOF
```

**`while IFS= read -r line` — ve `for line in $(cat file)` neden yanlış.**
`for` döngüsü dosyayı önce tek bir dizgeye çevirir, sonra onu **kelimelere**
böler. Satır yapısı kaybolur: içinde boşluk olan bir satır iki ayrı öğe
olur, ayrıca kabuk `*` gibi karakterleri dosya adlarıyla eşleştirmeye
çalışır. `while read` satırı satır olarak korur. `IFS=` baştaki/sondaki
boşlukların kırpılmasını engeller, `-r` ters bölü karakterlerinin kaçış
olarak yorumlanmasını engeller. `|| [ -n "$line" ]` ise dosyanın son
satırında yeni satır karakteri yoksa o satırın sessizce yutulmasını önler:
`read` veriyi okur ama EOF gördüğü için başarısız döner.

**Yorum ve boş satır süzme.** `services.list` bilerek kirli:

```
# gece raporunda izlenen servisler
labapp-web
labapp-worker

labapp-queue
#labapp-legacy
labapp-cache
```

`case` içindeki `''` boş satırı, `'#'*` ise `#` ile başlayan her satırı
yakalar — yani hem başlıktaki yorumu hem de `#labapp-legacy` satırını.
Süzmezsen `svccheck '#labapp-legacy'` çağırırsın, o da doğal olarak
`[FAIL]` döner: rapora olmayan bir servis girer ve iki kriter birden düşer.

**Neden geçici dosya.** Raporun **ilk satırı** durum özeti, ama o özeti
ancak tüm servisleri gezdikten sonra biliyorsun. Gövdeyi `mktemp` ile
geçici bir yerde biriktirip sonunda `{ ... } > "$OUT"` ile tek seferde
yazmak bu sırayı çözer.

**Idempotens.** `> "$OUT"` dosyayı sıfırlayıp yazar. `>>` kullanırsan ikinci
koşuda rapor iki katına çıkar — kriter tam olarak bunu yakalıyor. "Rapor her
çalıştırmada sıfırdan üretilir" cümlesi bu yüzden görevde yazıyor.

**Çıkış kodu raporu izler.** `svccheck` başarısız olduğunda `|| rc=1` ile
işaretlenir; `rc` hem dosyanın ilk satırını hem script'in çıkış kodunu
belirler. İkisi aynı kaynaktan türediği için tutarsız olamazlar.

---

## 4. İzinler

```bash
sudo chown root:root /usr/local/bin/logsum /usr/local/bin/svccheck /usr/local/bin/report
sudo chmod 755 /usr/local/bin/logsum /usr/local/bin/svccheck /usr/local/bin/report
```

`755` = sahibi yazar/çalıştırır, herkes okur ve çalıştırır, **kimse başkası
yazamaz**. Bozuk `logsum` 0666 ile geliyordu: hem çalıştırılamaz (x biti yok)
hem de herkes tarafından yazılabilir. `PATH` üstündeki bir script'in herkese
yazılabilir olması klasik bir yetki yükseltme yoludur — student'ın
çalıştırdığı bir dosyayı başka bir kullanıcı sessizce değiştirebilir.

`/usr/local/bin` zaten `PATH`'te olduğu için tam yol yazmadan çalışırlar:

```bash
command -v logsum svccheck report
```

---

## 5. Deyimsel not: `die()` — kriter değildir

Aynı `mesaj + çıkış` kalıbını birden çok yerde yazıyorsan bir fonksiyona
alabilirsin:

```bash
die() {
    echo "logsum: $2" >&2
    exit "$1"
}

[ "$#" -ge 1 ] || die 2 "kullanim: logsum <logfile>"
[ -r "$1" ]    || die 3 "okunamiyor: $1"
```

`check.sh` böyle bir fonksiyon aramıyor; yukarıdaki açık `if` blokları da
tamamen geçerlidir. Bu yalnızca gerçek script'lerde sık göreceğin bir kalıp —
fonksiyonun ilk argümanı `$1`, gövdesi kendi konumsal parametrelerini alır ve
`exit` fonksiyonun içinden çağrıldığında **script'i** sonlandırır (`return`
yalnız fonksiyondan çıkar; ikisini karıştırmak yaygın bir hatadır).

---

## Doğrula

```bash
logsum /var/log/labapp/app.log; echo "rc=$?"
logsum; echo "rc=$?"
logsum /var/log/labapp/secure.log; echo "rc=$?"
svccheck labapp-web labapp-queue labapp-worker; echo "rc=$?"
report; echo "rc=$?"
cat /srv/reports/daily.txt
```

Host'tan: `labctl check 006` — on iki kriterin hepsi `[OK]` basmalı.
Sıfırlamak için: `labctl reset 006`.
