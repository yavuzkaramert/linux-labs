# İpuçları — Lab 003: Dosya Bulma ve Yönetme

## Seviye 1

- Ağacın tamamında arama yapmak, elle gezmekten farklı bir araç ister.
  Bu araca "neyi" aradığını kriterlerle söylersin: dosyanın yaşı, boyutu,
  tipi ve boş olup olmaması ayrı ayrı arama kriteri olabilir.
- Aynı araç, bulduğu her dosya üzerinde senin adına başka bir komut da
  çalıştırabilir — bulup elle tek tek işlem yapmana gerek yok.
- "30 günden eski" bir dosyayı değiştirilme zamanı (mtime) belirler;
  dosyayı taşımak bu zamanı değiştirmez.
- Kopyalamanın, dosyanın izinlerini, sahibini ve zaman damgalarını
  olduğu gibi koruyan bir "arşiv" modu vardır; düz kopyalama bunları korumaz.
- Sembolik link, dosyanın kendisi değil ona işaret eden bir işarettir;
  link mi kopya mı olduğu dosya tipinden anlaşılır.
- Çalıştırma izni dosya bazında verilir; bir kalıba (ör. uzantıya) göre
  seçerek izin vermek yine arama aracıyla olur.

## Seviye 2

- Ağaçta kriterle arama ve toplu işlem: `find`
- Taşıma: `mv` — Silme: `rm` (ya da find'ın kendi silme yeteneği)
- Metadata koruyan kopya: `cp` (arşiv modu)
- Sembolik link: `ln`
- Çalıştırma izni: `chmod`
- Zaman/izin/sahiplik incelemek: `stat`, `ls -lt`
- Link hedefini görmek: `readlink`

## Seviye 3

- `find` yaş filtresi: `-mtime +30` (30 günden eski)
- `find` boyut filtresi: `-size +1M` (1 MB'den büyük)
- `find` boş dosya: `-empty` ile `-type f` birlikte (yalnız normal dosyalar)
- `find` isim kalıbı: `-name '*.log'`, `-name '*.sh'`
- Bir dizini aramanın dışında tutmak: `-path ... -prune -o ... -print`
- Bulunanlara komut uygulamak: `-exec komut {} +` (ya da `-delete`)
- `cp`: `-a` arşiv modu — izin, sahiplik ve mtime'ı korur (sahiplik için root gerekir)
- `ln`: `-s` sembolik link yaratır
- En yeni dosyayı bulmak: `ls -t` mtime'a göre yeniden eskiye sıralar
- Tam komutlar hiçbir seviyede verilmez — birleştirmek sende.
