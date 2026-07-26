# Çözüm — Lab 005: Süreç Yönetimi

Lab shell'i içinde çalıştır (`labctl shell 005`). Sahte süreçler `student`
kullanıcısına ait olduğu için **sudo gerekmez**; `/srv/reports` de student'ın.

## 1. Envanteri çıkar

```bash
pgrep -af LABPROC > /srv/reports/procs.txt
```

`-f` deseni tüm komut satırında arar (varsayılan sadece süreç adına bakar —
`rogue` süreci sahte bir isimle çalıştığı için `-f` olmadan bulunamaz).
`-a` PID + tam komut satırını basar. `pgrep` kendi kendini eşleştirmez,
bu yüzden "grep satırı" hiç oluşmaz.

`ps` ile yapmak istersen grep'i elemek zorundasın:

```bash
ps -eo pid,args | grep LABPROC | grep -v grep > /srv/reports/procs.txt
```

`grep -v grep` unutulursa arama komutunun kendisi listeye girer → FAIL.

## 2. Takılmış süreci kibarca durdur

```bash
pkill -TERM -f LABPROC-hog
```

`TERM` (15) yakalanabilir sinyaldir: süreç isterse temizlik yapıp kapanabilir.
`hog` sinyali yakalamıyor, dolayısıyla anında ölür. Doğrula:

```bash
pgrep -af LABPROC-hog    # çıktı boş olmalı
```

`kill -9` ile başlasaydın da süreç ölürdü ama görev kibar sinyali istiyor —
canlı sistemde varsayılan davranış budur, `KILL` son çaredir.

## 3. Kaçak süreci sert sinyalle öldür

Önce kibar yolu dene ve **başarısız olduğunu gör**:

```bash
pkill -TERM -f LABPROC-rogue
pgrep -af LABPROC-rogue    # hâlâ orada — süreç TERM'i trap ile yok sayıyor
```

```bash
pkill -KILL -f LABPROC-rogue
pgrep -af LABPROC-rogue    # artık boş
```

`KILL` (9) süreç tarafından yakalanamaz, yok sayılamaz, bloklanamaz — sinyali
çekirdek uygular. Bir süreç `trap '' TERM` yapmışsa `TERM`'i kaç kez
göndersen de ölmez; sinyali değiştirmen gerekir.

Süreç `exec -a kworker/u8:3-events ...` ile sahte bir isim taşıyor. Bu yüzden
`pkill LABPROC-rogue` (yani `-f` olmadan) hiçbir şey bulamaz; eşleşme komut
satırı üzerinden yapılmalı.

## 4. Önceliği düşür

```bash
BPID=$(pgrep -f LABPROC-batch)
renice -n 10 -p "$BPID"
```

Süreç `nice -15` ile, yani çok yüksek öncelikle çalışıyordu. `renice` çalışan
bir sürecin önceliğini değiştirir; süreci öldürmeye gerek yok. Nice değerini
**artırmak** (önceliği düşürmek) normal kullanıcı için serbesttir; düşürmek
root ister — bu yüzden 10'a çıkmak sudo'suz çalışır.

`nice` kullanmaya çalışma: o yeni bir süreci belirli öncelikle **başlatır**,
mevcut süreci değiştirmez.

## 5. Kanıtı sabitle

```bash
ps -o ni= -p "$BPID" | tr -d ' ' > /srv/reports/batch-nice.txt
```

`-o ni=` sadece nice sütununu, başlık satırı olmadan basar. `ps` sayıyı sağa
yaslayıp boşluk eklediği için `tr -d ' '` ile temizlenir — dosyada tek bir
sayı kalmalı. Dosyadaki değer check tarafından sürecin **canlı** nice
değeriyle karşılaştırılır; elle "10" yazıp `renice` yapmazsan yakalanırsın.

## Dokunma

`nightly-batch-runner` ve `sleep 4242/4243` süreçlerinde `LABPROC` işareti
yok — bunlar tuzak. `pkill -9 -f sleep` ya da `pkill -f batch` gibi geniş
desenler canlı sistemde alakasız süreçleri götürür. Desenini her zaman
ayırt edici işaret üzerine kur.

## Doğrula

Host'tan: `labctl check 005` — beş kriterin hepsi `[OK]` basmalı.
Sıfırlamak için: `labctl reset 005` (eski sahte süreçler temizlenir).
