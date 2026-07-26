# İpuçları — Lab 005: Süreç Yönetimi

## Seviye 1

- Bu lab dosyalarla değil, **o anda çalışan süreçlerle** uğraşıyor. Önce
  "şu an ne çalışıyor?" sorusunu cevaplayacak bir araca ihtiyacın var; sonra
  o listeden sadece ilgilendiğin satırları süzeceksin.
- Bir süreci PID'siyle hedeflemek kırılgandır: PID her kurulumda değişir.
  Süreçleri **komut satırındaki işaretle** bulmak daha sağlam. Süreç
  listesini komut satırı dahil gösteren bir görünüm seç, ya da doğrudan
  komut satırına göre arama yapan bir araç kullan.
- Bir süreci "öldürmek" tek bir şey değildir: sürece **sinyal** gönderirsin.
  Bazı sinyaller süreçten "lütfen kapan, temizliğini yap" diye rica eder —
  süreç bunu yakalayabilir, hatta yok sayabilir. Bir sinyal ise çekirdek
  tarafından uygulanır ve süreç ona hiçbir şekilde karışamaz.
- Süreç kibar sinyale cevap vermiyorsa, aynı sinyali tekrar tekrar göndermenin
  faydası yok. Sinyali değiştirmen gerekiyor.
- Öncelik ayrı bir kavram: bir süreç *çalışırken* önceliği değiştirilebilir,
  öldürmek gerekmez. Linux'ta öncelik "nice" değeriyle ifade edilir ve
  ters çalışır: **nice değeri büyüdükçe süreç daha nazik, yani daha düşük
  öncelikli** olur.
- Normal bir kullanıcı kendi sürecinin nice değerini **artırabilir**
  (önceliği düşürebilir), ama düşüremez. Bu görevde istenen zaten artırmak.
- Süreç listesinde işaret taşımayan sahte süreçler de var. İşareti olmayan
  hiçbir şeye dokunma.

## Seviye 2

- Çalışan süreçleri listelemek: `ps` (komut satırını da göstermesi için
  uygun çıktı seçenekleri gerekir) ya da `pgrep`.
- Komut satırına göre süreç aramak/sinyallemek: `pgrep` ve `pkill` ailesinin
  "tam komut satırında ara" davranışı.
- Sinyal göndermek: `kill` (PID ile), `pkill` / `killall` (isim veya komut
  satırı deseni ile). Hangi sinyalleri gönderebileceğini `kill -l` listeler.
- İlgili sinyaller: kibar/yakalanabilir sonlandırma sinyali ile
  yakalanamayan, kesin sonlandırma sinyali. İkisinin adını ve numarasını
  öğren — hangi görevde hangisinin istendiği TASK'te açıkça yazıyor.
- Çalışan bir sürecin önceliğini değiştirmek: `renice`. Yeni bir süreci
  belirli öncelikle başlatmak `nice`'tır — bu görevde süreç zaten çalışıyor,
  o yüzden başlatma aracı değil, değiştirme aracı lazım.
- Bir sürecin nice değerini okumak: `ps`'in çıktı sütunu seçme özelliği
  (`-o` ile alan seçimi), veya `/proc/PID/` altındaki durum dosyaları.
- Görev eşleşmesi: envanter → listele + süz + dosyaya yaz; hog → kibar
  sinyal; rogue → sert sinyal; batch → önceliği değiştir; kanıt → nice'ı
  oku + dosyaya yaz.

## Seviye 3

- `ps` seçenekleri: `-e` tüm süreçler, `-f` tam biçim, `-o` ile sütun seç
  (`pid`, `ni`, `args` gibi; `=` ekleyerek başlık satırını bastırabilirsin),
  `-p` ile tek bir PID'yi hedefle.
- `pgrep` / `pkill`: `-f` deseni **tüm komut satırında** arar (varsayılan
  sadece süreç adına bakar), `-a` PID ile birlikte komut satırını da yazar,
  `-l` sadece ismi yazar. `pgrep` kendi kendini eşleştirmez — bu yüzden
  `ps | grep` yaklaşımındaki "grep kendini listeler" tuzağını yaşamazsın.
  `ps | grep` kullanacaksan grep satırını `grep -v` ile elemen gerekir.
- Sinyaller: `TERM` (15) yakalanabilir/yok sayılabilir, varsayılan sinyaldir;
  `KILL` (9) yakalanamaz, yok sayılamaz, çekirdek uygular. `HUP` (1) ve
  `INT` (2) de yakalanabilir. `kill -SIGNAL PID` ya da `pkill -SIGNAL -f desen`
  biçiminde sinyal seçilir; sinyalin adı da numarası da kabul edilir.
- Bir süreç `trap` ile sinyali yok saymışsa, o sinyali kaç kez gönderdiğin
  fark etmez. Süreç hâlâ listede görünüyorsa sinyali değiştir.
- `renice`: hedef PID ve yeni nice değeri alır (`-n` ile değer, `-p` ile
  PID). Değeri **artırmak** yetki gerektirmez, düşürmek root ister.
- Nice okumak: `ps -o ni= -p PID` tek başına nice değerini basar;
  `/proc/PID/stat` dosyasında da 19. alan nice değeridir. Dosyaya yazarken
  başında/sonunda boşluk kalmaması için çıktıyı sadeleştirmen gerekebilir.
- `>` ile yönlendirme dosyayı sıfırlayıp yazar; `>>` ekler. Tek satırlık
  sayı için birincisini kullan.
- Hiçbir seviyede tam komut verilmez — zinciri sen kur.
