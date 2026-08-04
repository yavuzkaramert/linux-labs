# Kaynak Haritası — Lab 900-vardiya-01a

Bu bir **tekrar labı**. Burada tam komut çözümü YOK ve bilerek yok:
her ticket daha önce çözdüğün bir lab'ın birebir uyarlaması. Takıldığın
yerde ilgili lab'ın kendi `solution.md`'sini aç.

    ./labctl solution 001-permissions
    ./labctl solution 002-users-groups
    ./labctl solution 003-finding-files
    ./labctl solution 004-text-processing
    ./labctl solution 005-processes
    ./labctl solution 006-shell-scripting

## Ticket → kaynak lab tablosu

| Ticket | Kaynak lab | Orijinal karşılığı | Bu labda ne değişti |
|---|---|---|---|
| 1.1 | `001-permissions` | dizin/dosya izin ayrımı | yol `/vardiya`, sahiplik `root:root` KALMALI — chown çözüm değil |
| 1.2 | `001-permissions` | dünyaya açık dosyanın kapatılması | ters yön: kapalı dosya "other"a yalnız okuma açılacak |
| 2.1 | `002-users-groups` | kriter 1 (grup + GID) | GID 5000 değil **4000**; grup hiç yok, yanlış GID'li değil |
| 2.2 | `002-users-groups` | kriter 2 (kullanıcı, home, shell) | `ayse` ve `mehmet` sıfırdan açılacak |
| 2.3 | `002-users-groups` | kriter 3 (birincil/ikincil grup) | birebir |
| 2.4 | `002-users-groups` | kriter 4 (servis hesabı) | birebir |
| 2.5 | `002-users-groups` | kriter 5 (dizin sahiplik + 2770) | yol `/srv/project` → `/srv/proje` |
| 2.6 | `002-users-groups` | kriter 6 (setgid davranışı) | birebir |
| 2.7 | `002-users-groups` | kriter 7 (ayrılan hesap) | birebir |
| 2.8 | `002-users-groups` | kriter 8 (wheel'de olmama) | birebir |
| 2.9 | — | **yeni** | `student`'ın da `developers` üyesi olması; 2770 dizin aksi hâlde Ticket 3-4'ü kilitler |
| 3.1 | `003-finding-files` | kriter 1 (eski log arşivi) | kök `/srv/data` → `/srv/proje` |
| 3.2 | `003-finding-files` | kriter 2 (0 byte temizliği) | aynı, yeni dosya adları |
| 3.3 | `003-finding-files` | kriter 3 (>1MB taşıma) | aynı |
| 3.4 | `003-finding-files` | kriter 4 (metadata korumalı kopya) | aynı |
| 3.5 | `003-finding-files` | kriter 5 (latest symlink) | aynı, `summary.txt` → `ozet.txt` tuzağı |
| 3.6 | `003-finding-files` | kriter 6 (.sh çalıştırma izni) | aynı |
| 4.1 | `004-text-processing` | kriter 1 (log okunabilirliği) | loglar `/srv/proje/logs/` altında |
| 4.2 | `004-text-processing` | kriter 2 (`errors.log`) | aynı tuzaklar: boyut 500 ve yolda `/500` |
| 4.3 | `004-text-processing` | kriter 3 (`top-ips.txt`) | aynı |
| 4.4 | `004-text-processing` | kriter 4 (`unique-users.txt`) | kullanıcı alanında `ayse`/`mehmet` da var |
| 4.5 | `004-text-processing` | kriter 5 (`warnings.tsv`) | aynı |
| 4.6 | `004-text-processing` | kriter 6 (`settings.conf`) | yol `/etc/webapp` → `/srv/proje/etc` |
| 4.7 | `004-text-processing` | kriter 7 (`hosts-clean.txt`) | aynı |
| 5.1 | `005-processes` | kriter 1 (`procs.txt`) | birebir, çıktı `/srv/reports` |
| 5.2 | `005-processes` | kriter 2 (SIGTERM) | birebir |
| 5.3 | `005-processes` | kriter 3 (SIGKILL gerektiren süreç) | birebir |
| 5.4 | `005-processes` | kriter 4 (nice ≥ 10) | birebir |
| 5.5 | `005-processes` | kriter 5 (`batch-nice.txt`) | birebir |
| 6.1 | `006-shell-scripting` | kriter 1 (logsum başarı yolu) | log `/var/log/vardiya/gunluk.log` |
| 6.2 | `006-shell-scripting` | kriter 2 (argümansız, exit 2) | birebir |
| 6.3 | `006-shell-scripting` | kriter 3 (olmayan dosya, exit 3) | birebir |
| 6.4 | `006-shell-scripting` | kriter 4 (okunamayan dosya, `-r`) | birebir |
| 6.5 | `006-shell-scripting` | kriter 5 (svccheck biçim + PID) | servis adları `labapp-*` → `vardiya-*` |
| 6.6 | `006-shell-scripting` | kriter 6 (svccheck çıkış kodları) | birebir |
| 6.7 | `006-shell-scripting` | kriter 7 (kendi arama süreci) | birebir |
| 6.8 | `006-shell-scripting` | kriter 8 (report DEGRADED) | eksik servis `vardiya-queue` |
| 6.9 | `006-shell-scripting` | kriter 9 (daily.txt içeriği) | birebir |
| 6.10 | `006-shell-scripting` | kriter 10 (idempotens) | birebir |
| 6.11 | `006-shell-scripting` | kriter 11 (report HEALTHY) | birebir |
| 6.12 | `006-shell-scripting` | kriter 12 (izinler + PATH) | birebir |

## Bu labın kendine ait tek zorluğu

Ticket 2 → Ticket 3/4 **sahiplik zinciri**. Orijinal lab'larda
`/srv/data` ve `/srv/logs` herkese açıktı; burada aynı ağaç
`2770 root:developers` olacak. Grup üyeliğini halletmeden alt
ticket'ların kullanıcı-perspektifi kriterleri geçmez. Gerisi
tamamen tekrar.
