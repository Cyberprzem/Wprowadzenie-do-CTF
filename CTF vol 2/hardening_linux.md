# Hardening systemów Linux — podsumowanie

(C) Cyberprzem

## 1. Cel dokumentu

Ten dokument jest praktycznym podsumowaniem hardeningu systemów Linux. 

Hardening oznacza ograniczenie powierzchni ataku systemu przy zachowaniu wymaganej funkcjonalności. W praktyce nie chodzi o „maksymalne zablokowanie” maszyny, ale o świadome zarządzanie ryzykiem:

- uruchamianie tylko potrzebnych usług,
- ograniczenie liczby użytkowników i uprawnień,
- zabezpieczenie zdalnego dostępu,
- ochrona plików, katalogów i konfiguracji,
- kontrola ruchu sieciowego,
- monitoring logów,
- aktualizacje,
- testowanie zmian,
- dokumentowanie wyjątków.

W środowisku CTF szczególnie ważne jest zachowanie dostępności usługi. Jeżeli uczestnik wyłączy serwer WWW, bazę danych albo SSH, to nie wykonał poprawnego hardeningu — po prostu zniszczył funkcję systemu.

---

## 2. Podstawowe zasady hardeningu

### 2.1. Minimalizacja

Na systemie powinno działać tylko to, co jest potrzebne.

Przykłady pytań:

- Czy serwer WWW potrzebuje FTP?
- Czy serwer aplikacyjny potrzebuje kompilatorów?
- Czy baza danych musi nasłuchiwać na wszystkich interfejsach?
- Czy konto techniczne musi mieć powłokę `/bin/bash`?
- Czy usługa administracyjna musi być dostępna z całej sieci?

Podstawowe komendy:

```bash
hostnamectl
ip a
ip route
ss -tulpen
systemctl --type=service --state=running
systemctl list-unit-files --type=service
dpkg -l
apt list --installed
```

---

### 2.2. Zasada najmniejszych uprawnień

Użytkownik, usługa lub proces powinny mieć tylko takie uprawnienia, jakie są konieczne do wykonania zadania.

Przykłady:

- aplikacja webowa nie powinna działać jako `root`,
- zwykły użytkownik nie powinien być w grupie `sudo`,
- katalog uploadów powinien być zapisywalny tylko tam, gdzie jest to konieczne,
- konto serwisowe nie powinno mieć pełnych uprawnień administracyjnych,
- baza danych nie powinna być obsługiwana przez konto `root` lub superusera aplikacyjnego.

---

### 2.3. Defense in depth

Nie zakładamy, że pojedyncze zabezpieczenie wystarczy.

Przykład dla serwera WWW:

- firewall dopuszcza tylko porty 80/443,
- Nginx/Apache nie ujawnia wersji,
- aplikacja nie ma zapisywalnego katalogu kodu,
- uploady nie wykonują PHP,
- pliki `.env` i backupy nie są publiczne,
- logi są monitorowane,
- proces webowy działa jako nieuprzywilejowany użytkownik,
- AppArmor lub systemd ogranicza usługę.

---

### 2.4. Zmieniaj pojedynczo i testuj

Dobra procedura:

```text
1. Zrób rozpoznanie.
2. Zapisz stan początkowy.
3. Zrób kopię konfiguracji.
4. Wprowadź jedną zmianę.
5. Przetestuj usługę.
6. Sprawdź logi.
7. Udokumentuj wynik.
8. Przejdź do kolejnej zmiany.
```

Przykład backupu konfiguracji:

```bash
mkdir -p ~/hardening-backup
sudo cp /etc/ssh/sshd_config ~/hardening-backup/sshd_config.bak
sudo cp -r /etc/nginx ~/hardening-backup/nginx.bak 2>/dev/null || true
sudo cp -r /etc/apache2 ~/hardening-backup/apache2.bak 2>/dev/null || true
sudo cp -r /etc/php ~/hardening-backup/php.bak 2>/dev/null || true
```

---

## 3. Rekonesans systemu Linux przed hardeningiem

Hardening zaczyna się od rozpoznania. Nie należy usuwać usług, blokować portów ani zmieniać uprawnień bez zrozumienia, co działa na systemie.

### 3.1. Informacje o systemie

```bash
hostnamectl
uname -a
lsb_release -a 2>/dev/null || cat /etc/os-release
uptime
who
w
last -n 20
```

Co sprawdzić:

- dystrybucja i wersja systemu,
- wersja jądra,
- czas działania systemu,
- aktywne sesje użytkowników,
- ostatnie logowania.

---

### 3.2. Sieć i porty

```bash
ip a
ip route
ss -tulpen
ss -antp
```

Interpretacja:

- `LISTEN` oznacza usługę nasłuchującą,
- `0.0.0.0` oznacza nasłuchiwanie na wszystkich interfejsach IPv4,
- `::` oznacza nasłuchiwanie na wszystkich interfejsach IPv6,
- port lokalny `127.0.0.1` jest dostępny tylko lokalnie.

Przykładowe porty do analizy:

```text
22/tcp    SSH
80/tcp    HTTP
443/tcp   HTTPS
3306/tcp  MySQL/MariaDB
5432/tcp  PostgreSQL
6379/tcp  Redis
8080/tcp  aplikacje testowe/proxy
9090/tcp  monitoring
```

---

### 3.3. Aktywne usługi

```bash
systemctl --type=service --state=running
systemctl list-unit-files --type=service
```

Dla konkretnej usługi:

```bash
systemctl status ssh
systemctl status apache2
systemctl status nginx
systemctl status mysql
systemctl status postgresql
```

Zatrzymanie i wyłączenie usługi:

```bash
sudo systemctl stop nazwa_uslugi
sudo systemctl disable nazwa_uslugi
```

Uwaga: nie należy wyłączać usług, których roli nie rozumiemy. W środowisku produkcyjnym każda zmiana powinna mieć właściciela i procedurę przywrócenia.

---

### 3.4. Procesy i zasoby

```bash
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
top
htop
free -m
df -h
du -sh /var/log/* 2>/dev/null
```

Co analizować:

- procesy zużywające CPU,
- procesy zużywające RAM,
- nietypowe procesy uruchomione jako `root`,
- brak miejsca na dysku,
- rosnące logi,
- skrypty uruchomione z `/tmp`, `/dev/shm`, `/var/tmp`.

---

## 4. Aktualizacje i zarządzanie pakietami

### 4.1. Ubuntu/Debian

```bash
sudo apt update
sudo apt list --upgradable
sudo apt upgrade
```

Usunięcie niepotrzebnych pakietów:

```bash
sudo apt autoremove
sudo apt autoclean
```

Sprawdzenie pakietów:

```bash
dpkg -l
apt list --installed
```

Przykładowe pakiety, które zwykle nie powinny być potrzebne na serwerze produkcyjnym:

```bash
sudo apt purge telnet ftp rsh-client talk -y
```

Uwaga: nie należy usuwać pakietów „na ślepo”. Czasem stare narzędzia są zależnością aplikacji legacy albo wykorzystywane są w specyficznych procedurach administracyjnych.

---

### 4.2. RHEL/Rocky/Alma/Fedora

```bash
sudo dnf check-update
sudo dnf upgrade
sudo dnf autoremove
```

Sprawdzenie zainstalowanych pakietów:

```bash
rpm -qa
dnf list installed
```

---

### 4.3. Restart po aktualizacjach

Na Ubuntu przydatne jest narzędzie `needrestart`:

```bash
sudo apt install needrestart
sudo needrestart
```

Sprawdzenie, czy wymagany jest reboot:

```bash
test -f /var/run/reboot-required && cat /var/run/reboot-required
```

---

## 5. Użytkownicy, grupy i konta administracyjne

### 5.1. Przegląd użytkowników

```bash
cat /etc/passwd
awk -F: '$3 >= 1000 {print}' /etc/passwd
grep -E "/bin/bash|/bin/sh|/usr/bin/zsh" /etc/passwd
```

Konta systemowe zwykle nie powinny mieć powłoki logowania. Zamiast tego powinny mieć:

```text
/usr/sbin/nologin
/bin/false
```

Zmiana powłoki:

```bash
sudo usermod -s /usr/sbin/nologin nazwa_uzytkownika
```

---

### 5.2. Grupy administracyjne

```bash
getent group sudo
getent group adm
getent group docker
getent group lxd
```

Szczególnie ważne grupy:

```text
sudo    — możliwość wykonywania poleceń jako root
adm     — dostęp do części logów
docker  — praktycznie możliwość przejęcia hosta przez kontrolę Dockera
lxd     — możliwość eskalacji przez kontenery
```

Usunięcie użytkownika z grupy:

```bash
sudo deluser nazwa_uzytkownika sudo
```

Blokada konta:

```bash
sudo passwd -l nazwa_uzytkownika
```

Wymuszenie zmiany hasła:

```bash
sudo passwd -e nazwa_uzytkownika
```

---

### 5.3. Polityka haseł

Instalacja `pam_pwquality`:

```bash
sudo apt install libpam-pwquality
```

Plik konfiguracyjny:

```bash
sudo nano /etc/security/pwquality.conf
```

Przykład:

```text
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
retry = 3
```

Sprawdzenie wieku hasła:

```bash
sudo chage -l nazwa_uzytkownika
```

Uwaga: sama złożoność hasła nie wystarcza. W administracji serwerami lepszym standardem jest używanie kluczy SSH, MFA tam, gdzie możliwe, oraz unikanie współdzielonych kont.

---

## 6. Hardening sudo

Do edycji konfiguracji sudo używamy:

```bash
sudo visudo
```

Nie edytujemy `/etc/sudoers` zwykłym edytorem bez walidacji składni.

Ryzykowny przykład:

```text
backup ALL=(ALL) NOPASSWD: ALL
```

Lepszy przykład, ale nadal wymagający analizy:

```text
backup ALL=(root) NOPASSWD: /usr/bin/rsync
```

Trzeba pamiętać, że wiele programów może umożliwiać wykonanie dodatkowych poleceń. Narzędzia takie jak `vim`, `less`, `find`, `tar`, `rsync`, `python`, `perl`, `bash` mogą być niebezpieczne w regułach sudo.

Kontrola uprawnień sudo:

```bash
sudo -l
getent group sudo
sudo grep -R "NOPASSWD" /etc/sudoers /etc/sudoers.d 2>/dev/null
```

Dobre praktyki:

```text
[ ] minimalna liczba użytkowników w grupie sudo,
[ ] brak reguł NOPASSWD bez uzasadnienia,
[ ] osobne konta administracyjne,
[ ] logowanie użycia sudo,
[ ] przegląd plików /etc/sudoers.d,
[ ] brak poleceń pozwalających łatwo uruchomić powłokę.
```

---

## 7. Hardening SSH

SSH jest jedną z najważniejszych usług administracyjnych. Błąd w konfiguracji SSH może doprowadzić do przejęcia systemu albo odcięcia administratora.

Plik konfiguracyjny:

```bash
sudo nano /etc/ssh/sshd_config
```

Przykładowe ustawienia:

```text
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowUsers ubuntu admin
```

Test konfiguracji:

```bash
sudo sshd -t
```

Restart:

```bash
sudo systemctl restart ssh
```

Uwaga krytyczna: nie wyłączaj `PasswordAuthentication`, dopóki nie potwierdzisz, że logowanie kluczem SSH działa. Najlepiej zostawić aktywną drugą sesję SSH podczas zmian.

### 7.1. Klucze SSH

Katalog i plik:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Uprawnienia katalogu domowego również mają znaczenie:

```bash
chmod 750 ~
```

### 7.2. Ograniczenie dostępu po adresach IP

Przykład z UFW:

```bash
sudo ufw allow from 192.168.56.0/24 to any port 22 proto tcp
```

### 7.3. Fail2Ban dla SSH

Instalacja:

```bash
sudo apt install fail2ban
```

Przykładowy plik:

```bash
sudo nano /etc/fail2ban/jail.local
```

Przykład:

```ini
[sshd]
enabled = true
port = ssh
maxretry = 5
findtime = 10m
bantime = 1h
```

Restart:

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

---

## 8. Firewall lokalny

### 8.1. UFW — Ubuntu/Debian

Podstawowa konfiguracja dla serwera WWW z SSH:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Zawężenie SSH do konkretnej podsieci:

```bash
sudo ufw delete allow 22/tcp
sudo ufw allow from 192.168.56.0/24 to any port 22 proto tcp
```

Błąd częsty w CTF:

```bash
sudo ufw default deny incoming
sudo ufw enable
```

Jeżeli nie dopuszczono SSH i HTTP, można odciąć się od maszyny i wyłączyć punktowaną usługę.

---

### 8.2. firewalld — RHEL/Rocky/Alma/Fedora

Sprawdzenie:

```bash
sudo firewall-cmd --state
sudo firewall-cmd --list-all
```

Dopuszczenie HTTP/HTTPS:

```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

Dopuszczenie SSH tylko z podsieci wymaga bardziej szczegółowych reguł rich rules.

---

## 9. Uprawnienia plików i katalogów

### 9.1. Podstawy

Linux używa modelu:

```text
właściciel — grupa — inni
read       — write — execute
```

Sprawdzenie:

```bash
ls -la
stat plik
```

Szukaj katalogów zapisywalnych przez wszystkich:

```bash
find / -type d -perm -0002 2>/dev/null
```

Szukaj plików zapisywalnych przez wszystkich:

```bash
find / -type f -perm -0002 2>/dev/null
```

---

### 9.2. Katalog aplikacji webowej

Dla statycznej strony:

```bash
sudo chown -R root:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 750 {} \;
sudo find /var/www/html -type f -exec chmod 640 {} \;
```

Dla aplikacji z uploadem należy rozdzielić kod i dane:

```text
/var/www/app/public      — publiczny katalog aplikacji
/var/www/app/storage     — dane aplikacji
/var/www/app/uploads     — uploady
/etc/app/config          — konfiguracja i sekrety poza katalogiem publicznym
```

Zasady:

```text
[ ] kod aplikacji nie powinien być zapisywalny przez proces webowy,
[ ] sekrety nie powinny być w katalogu publicznym,
[ ] backupy nie powinny być w katalogu publicznym,
[ ] uploady nie powinny wykonywać skryptów,
[ ] katalogi powinny mieć minimalne uprawnienia.
```

---

### 9.3. Pliki podejrzane w katalogu webowym

Szukaj:

```bash
sudo find /var/www -name "*.bak" -o -name "*.old" -o -name "*.zip" -o -name "*.sql" -o -name ".env"
sudo find /var/www -name ".git" -type d
grep -R "password\|secret\|token\|apikey" /var/www 2>/dev/null
```

Typowe ryzykowne pliki:

```text
.env
config.php.bak
backup.zip
database.sql
id_rsa
.git/
admin_old.php
test.php
phpinfo.php
```

---

## 10. Pliki SUID i SGID

SUID i SGID mogą być potrzebne, ale bywają drogą eskalacji uprawnień.

SUID:

```bash
find / -perm -4000 -type f 2>/dev/null
```

SGID:

```bash
find / -perm -2000 -type f 2>/dev/null
```

Typowe pliki systemowe:

```text
/usr/bin/passwd
/usr/bin/sudo
/usr/bin/su
/usr/bin/mount
/usr/bin/umount
```

Podejrzane lokalizacje:

```text
/tmp/
/var/tmp/
/dev/shm/
/home/*/
/var/www/
```

Nie usuwaj standardowych plików SUID bez analizy. W CTF-ach często celowo dodaje się podejrzany plik SUID w nietypowej lokalizacji.

---

## 11. sysctl i parametry jądra

Plik:

```bash
sudo nano /etc/sysctl.d/99-hardening.conf
```

Przykładowe ustawienia:

```text
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
```

Zastosowanie:

```bash
sudo sysctl --system
```

Uwaga: `net.ipv4.ip_forward = 0` jest dobre dla zwykłego serwera, ale złe dla routera, bramy VPN lub hosta pełniącego funkcję routingu.

---

## 12. AppArmor i SELinux

### 12.1. AppArmor

Ubuntu domyślnie używa AppArmor. Sprawdzenie statusu:

```bash
sudo aa-status
```

Instalacja narzędzi:

```bash
sudo apt install apparmor apparmor-utils
```

Tryby:

```text
enforce  — profil wymusza ograniczenia,
complain — profil tylko loguje naruszenia,
disable  — profil wyłączony.
```

Zmiana trybu:

```bash
sudo aa-complain /etc/apparmor.d/nazwa_profilu
sudo aa-enforce /etc/apparmor.d/nazwa_profilu
```

Zasada: dla istniejących aplikacji warto najpierw użyć trybu `complain`, przeanalizować logi, a dopiero później wymuszać.

---

### 12.2. SELinux

Systemy z rodziny RHEL używają SELinux.

Status:

```bash
getenforce
sestatus
```

Tryby:

```text
Enforcing   — wymuszanie polityki,
Permissive  — logowanie naruszeń bez blokowania,
Disabled    — wyłączone.
```

Tymczasowa zmiana trybu:

```bash
sudo setenforce 0
sudo setenforce 1
```

Uwaga: wyłączanie SELinux „bo coś nie działa” jest złym nawykiem. Lepsze jest ustalenie, jaka reguła blokuje aplikację.

---

## 13. systemd hardening

Systemd pozwala ograniczyć działanie usług bez modyfikacji samej aplikacji.

Analiza bezpieczeństwa usługi:

```bash
systemd-analyze security nazwa-uslugi.service
```

Override:

```bash
sudo systemctl edit nazwa-uslugi.service
```

Przykład:

```ini
[Service]
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/nazwa-uslugi
CapabilityBoundingSet=
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
```

Po zmianie:

```bash
sudo systemctl daemon-reload
sudo systemctl restart nazwa-uslugi
systemctl status nazwa-uslugi
```

Znaczenie wybranych opcji:

```text
NoNewPrivileges=true        — proces nie może uzyskać nowych uprawnień,
PrivateTmp=true             — osobny /tmp dla usługi,
ProtectSystem=strict        — system plików głównie tylko do odczytu,
ProtectHome=true            — blokada dostępu do katalogów domowych,
ReadWritePaths=             — wyjątki dla zapisu,
CapabilityBoundingSet=      — ograniczenie capabilities.
```

Uwaga: te ustawienia łatwo mogą zepsuć usługę. Wdrażać stopniowo i testować.

---

## 14. Logowanie i audyt

### 14.1. Podstawowe logi

```bash
journalctl
journalctl -xe
journalctl -u ssh
journalctl -u apache2
journalctl -u nginx
```

Logi klasyczne:

```bash
tail -f /var/log/auth.log
tail -f /var/log/syslog
tail -f /var/log/kern.log
tail -f /var/log/apache2/access.log
tail -f /var/log/apache2/error.log
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

Co wykrywać:

```text
[ ] nieudane logowania SSH,
[ ] logowania roota,
[ ] użycie sudo,
[ ] błędy aplikacji,
[ ] skanowanie katalogów webowych,
[ ] próby dostępu do .env, .git, backup.zip,
[ ] restarty usług,
[ ] nietypowe procesy,
[ ] błędy dysku i kernela.
```

---

### 14.2. auditd

Instalacja:

```bash
sudo apt install auditd audispd-plugins
sudo systemctl enable --now auditd
```

Reguła monitorująca `/etc/sudoers`:

```bash
sudo auditctl -w /etc/sudoers -p wa -k sudoers_change
```

Wyszukiwanie zdarzeń:

```bash
sudo ausearch -k sudoers_change
```

Przykładowe obszary audytu:

```text
/etc/passwd
/etc/shadow
/etc/group
/etc/sudoers
/etc/sudoers.d/
/etc/ssh/sshd_config
/var/www/
/etc/nginx/
/etc/apache2/
```

---

### 14.3. logrotate

Sprawdzenie konfiguracji:

```bash
ls -la /etc/logrotate.d/
cat /etc/logrotate.conf
```

Brak rotacji logów może doprowadzić do zapełnienia dysku, a to często oznacza awarię usług.

---

## 15. Integralność plików

### 15.1. AIDE

Instalacja:

```bash
sudo apt install aide
sudo aideinit
```

Sprawdzenie:

```bash
sudo aide --check
```

Zastosowanie:

- wykrywanie zmian w plikach systemowych,
- kontrola modyfikacji konfiguracji,
- wykrywanie podmienionych plików aplikacji,
- wsparcie analizy incydentów.

---

## 16. Hardening Apache

Apache HTTP Server jest częstym elementem środowisk Linux. W hardeningu Apache najważniejsze są: ograniczenie informacji ujawnianych przez serwer, poprawne uprawnienia katalogów, wyłączenie listowania katalogów, kontrola metod HTTP, nagłówki bezpieczeństwa, TLS oraz monitoring logów.

### 16.1. Ograniczenie informacji o serwerze

Plik:

```bash
sudo nano /etc/apache2/conf-available/security.conf
```

Ustawienia:

```apache
ServerTokens Prod
ServerSignature Off
TraceEnable Off
```

Test:

```bash
sudo apache2ctl configtest
sudo systemctl reload apache2
curl -I http://127.0.0.1/
```

---

### 16.2. Wyłączenie listowania katalogów

Niebezpieczny wariant:

```apache
Options Indexes FollowSymLinks
```

Bezpieczniejszy wariant:

```apache
<Directory /var/www/html>
    Options -Indexes
    AllowOverride None
    Require all granted
</Directory>
```

Test:

```bash
curl http://127.0.0.1/uploads/
```

---

### 16.3. Ograniczenie metod HTTP

```apache
<Directory /var/www/html>
    <LimitExcept GET POST HEAD>
        Require all denied
    </LimitExcept>
</Directory>
```

Test:

```bash
curl -X OPTIONS -I http://127.0.0.1/
curl -X TRACE -I http://127.0.0.1/
```

---

### 16.4. Nagłówki bezpieczeństwa

Aktywacja modułu:

```bash
sudo a2enmod headers
```

Przykład:

```apache
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

Dla HTTPS:

```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
```

Uwaga: HSTS należy włączać świadomie. Jeżeli subdomeny nie są gotowe na HTTPS, można spowodować problemy.

---

### 16.5. Moduły Apache

Lista modułów:

```bash
apache2ctl -M
```

Wyłączenie modułu:

```bash
sudo a2dismod nazwa_modulu
sudo systemctl reload apache2
```

Moduły do oceny:

```text
autoindex
status
userdir
cgi
dav
dav_fs
proxy
proxy_http
```

Nie wyłączaj modułów bez testowania aplikacji.

---

## 17. Hardening Nginx

Nginx jest często używany jako serwer WWW, reverse proxy i terminator TLS.

### 17.1. Ukrycie wersji

W pliku `/etc/nginx/nginx.conf`:

```nginx
http {
    server_tokens off;
}
```

Test:

```bash
sudo nginx -t
sudo systemctl reload nginx
curl -I http://127.0.0.1/
```

---

### 17.2. Bezpieczny server block

```nginx
server {
    listen 80;
    server_name example.local;

    root /var/www/example/public;
    index index.html index.php;

    access_log /var/log/nginx/example_access.log;
    error_log /var/log/nginx/example_error.log;

    autoindex off;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }

    location ~* \.(bak|old|orig|save|sql|zip|tar|gz)$ {
        deny all;
    }
}
```

---

### 17.3. Nagłówki bezpieczeństwa

```nginx
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

Dla HTTPS:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

Uwaga: w Nginx `add_header` ma istotne zasady dziedziczenia. Trzeba testować finalne odpowiedzi przez `curl -I`.

---

### 17.4. Reverse proxy

```nginx
server {
    listen 80;
    server_name app.local;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 5s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
```

Ryzyka:

```text
[ ] backend dostępny publicznie z pominięciem proxy,
[ ] brak limitów requestów,
[ ] zaufanie do nagłówka X-Forwarded-For od klienta,
[ ] brak timeoutów,
[ ] brak logów per aplikacja.
```

---

### 17.5. Rate limiting

W sekcji `http`:

```nginx
limit_req_zone $binary_remote_addr zone=req_limit:10m rate=10r/s;
```

W `server` lub `location`:

```nginx
location / {
    limit_req zone=req_limit burst=20 nodelay;
    try_files $uri $uri/ =404;
}
```

---

### 17.6. Nginx i PHP-FPM

```nginx
location ~ \.php$ {
    try_files $uri =404;
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php8.3-fpm.sock;
}
```

Blokada wykonywania PHP w uploadach:

```nginx
location ~* /uploads/.*\.php$ {
    deny all;
}
```

---

## 18. Hardening PHP i PHP-FPM

### 18.1. php.ini

Pliki:

```text
/etc/php/*/apache2/php.ini
/etc/php/*/fpm/php.ini
```

Przykład ustawień:

```ini
expose_php = Off
display_errors = Off
log_errors = On
memory_limit = 256M
max_execution_time = 30
upload_max_filesize = 10M
post_max_size = 12M
allow_url_fopen = Off
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = Lax
```

Ostrożnie z:

```ini
disable_functions = exec,passthru,shell_exec,system,proc_open,popen
```

Może to poprawić bezpieczeństwo, ale może też zepsuć aplikacje.

---

### 18.2. Pule PHP-FPM

Plik:

```text
/etc/php/8.3/fpm/pool.d/www.conf
```

Przykład:

```ini
user = www-data
group = www-data

listen = /run/php/php8.3-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 20
pm.start_servers = 4
pm.min_spare_servers = 2
pm.max_spare_servers = 8
```

Dobra praktyka: dla wielu aplikacji używaj osobnych puli PHP-FPM i osobnych użytkowników systemowych.

---

## 19. Hardening baz danych

### 19.1. MariaDB/MySQL

Podstawowe zabezpieczenie:

```bash
sudo mariadb-secure-installation
```

Sprawdzenie nasłuchiwania:

```bash
ss -tulpen | grep 3306
```

Konfiguracja:

```ini
bind-address = 127.0.0.1
```

Przykład konta aplikacyjnego:

```sql
CREATE DATABASE appdb;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'bardzo_silne_haslo';
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
```

Zły przykład:

```sql
GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'%' WITH GRANT OPTION;
```

Zasady:

```text
[ ] baza nie nasłuchuje publicznie bez potrzeby,
[ ] aplikacja nie używa konta root,
[ ] konta mają minimalne uprawnienia,
[ ] backupy są chronione,
[ ] logi błędów są monitorowane,
[ ] dostęp zdalny ograniczony po IP i firewallu.
```

---

### 19.2. PostgreSQL

Pliki:

```text
/etc/postgresql/*/main/postgresql.conf
/etc/postgresql/*/main/pg_hba.conf
```

Sprawdzenie:

```bash
ss -tulpen | grep 5432
```

`postgresql.conf`:

```conf
listen_addresses = 'localhost'
```

`pg_hba.conf`:

```conf
local   all             postgres                                peer
local   appdb           appuser                                 scram-sha-256
host    appdb           appuser          127.0.0.1/32            scram-sha-256
```

Reload:

```bash
sudo systemctl reload postgresql
```

Zasady:

```text
[ ] nie używać superusera w aplikacji,
[ ] ograniczyć listen_addresses,
[ ] ograniczyć adresy w pg_hba.conf,
[ ] stosować silne metody uwierzytelniania,
[ ] monitorować logi,
[ ] backupować i testować odtwarzanie.
```

---

### 19.3. Redis

Redis nie powinien być publicznie dostępny bez bardzo świadomej architektury bezpieczeństwa.

Konfiguracja:

```conf
bind 127.0.0.1
protected-mode yes
requirepass bardzo_silne_haslo
```

Firewall:

```bash
sudo ufw deny 6379/tcp
```

Zasady:

```text
[ ] Redis lokalnie, jeśli to możliwe,
[ ] brak publicznego portu 6379,
[ ] silne hasło,
[ ] ograniczenie komend administracyjnych, jeśli potrzebne,
[ ] monitoring logów,
[ ] backupy chronione.
```

---

## 20. Hardening Docker i kontenerów

### 20.1. Grupa docker

Sprawdzenie:

```bash
getent group docker
```

Użytkownik w grupie `docker` ma w praktyce bardzo szerokie możliwości na hoście. Nie należy dodawać tam przypadkowych użytkowników.

---

### 20.2. Unikanie privileged

Niebezpieczne:

```bash
docker run --privileged ubuntu
```

Lepsze podejście:

```bash
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE nginx
```

---

### 20.3. Non-root user

Dockerfile:

```dockerfile
FROM nginx:alpine

RUN adduser -D appuser
USER appuser
```

W praktyce trzeba dostosować porty i uprawnienia katalogów.

---

### 20.4. Read-only filesystem

```bash
docker run --read-only --tmpfs /tmp nginx
```

Docker Compose:

```yaml
services:
  app:
    image: nginx:alpine
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
```

---

### 20.5. Limity zasobów

```yaml
services:
  app:
    image: nginx:alpine
    mem_limit: 256m
    cpus: "0.5"
```

W CTF jest to ważne, bo ataki degradujące usługę często próbują wyczerpać CPU, RAM, deskryptory plików albo liczbę procesów.

---

### 20.6. Sekrety

Zły przykład:

```yaml
environment:
  DB_PASSWORD: supertajnehaslo
```

Lepsze podejście:

```text
[ ] Docker secrets,
[ ] pliki z ograniczonymi uprawnieniami,
[ ] zewnętrzny manager sekretów,
[ ] brak sekretów w repozytorium,
[ ] brak sekretów w obrazach Docker.
```

---

## 21. Cron i zadania cykliczne

Cron jest częstym miejscem błędów bezpieczeństwa.

Sprawdzenie:

```bash
crontab -l
sudo crontab -l
ls -la /etc/cron*
ls -la /var/spool/cron/crontabs
```

Błąd:

```cron
* * * * * root /tmp/backup.sh
```

Lepszy wariant:

```cron
* * * * * root /usr/local/sbin/backup.sh
```

Uprawnienia:

```bash
sudo chown root:root /usr/local/sbin/backup.sh
sudo chmod 700 /usr/local/sbin/backup.sh
```

Zasady:

```text
[ ] skrypty uruchamiane przez roota nie mogą być zapisywalne przez zwykłych użytkowników,
[ ] używaj ścieżek absolutnych,
[ ] nie wykonuj skryptów z /tmp,
[ ] loguj wynik zadań,
[ ] sprawdzaj katalogi /etc/cron.d i /etc/systemd/system.
```

---

## 22. TLS i HTTPS

Dla usług webowych standardem powinien być HTTPS.

Obszary:

```text
[ ] ważny certyfikat,
[ ] poprawny łańcuch certyfikatów,
[ ] automatyczne odnawianie,
[ ] przekierowanie HTTP na HTTPS,
[ ] wyłączenie starych protokołów,
[ ] HSTS po testach,
[ ] bezpieczna konfiguracja reverse proxy.
```

Nginx:

```nginx
server {
    listen 80;
    server_name example.local;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.local;

    ssl_certificate /etc/letsencrypt/live/example.local/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.local/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

Apache:

```apache
<VirtualHost *:80>
    ServerName example.local
    Redirect permanent / https://example.local/
</VirtualHost>

<VirtualHost *:443>
    ServerName example.local

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.local/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.local/privkey.pem

    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
</VirtualHost>
```

---

## 23. Backup i odtwarzanie

Hardening bez backupu jest niepełny. System może być dobrze zabezpieczony, ale nadal może ulec awarii, błędnej aktualizacji, atakowi ransomware albo błędowi administratora.

Zasada 3-2-1:

```text
3 kopie danych,
2 różne nośniki,
1 kopia poza głównym środowiskiem.
```

Dobre praktyki:

```text
[ ] backup konfiguracji,
[ ] backup danych aplikacji,
[ ] backup baz danych,
[ ] backup poza hostem,
[ ] ograniczony dostęp do backupów,
[ ] test odtworzenia,
[ ] dokumentacja procedury recovery,
[ ] monitoring powodzenia backupu.
```

Przykład kopii konfiguracji:

```bash
sudo tar czf /root/etc-backup-$(date +%F).tar.gz /etc
```

Przykład backupu katalogu webowego:

```bash
sudo tar czf /root/www-backup-$(date +%F).tar.gz /var/www
```

---

## 24. Narzędzia wspierające audyt i hardening

### 24.1. Lynis

Instalacja:

```bash
sudo apt install lynis
```

Audyt:

```bash
sudo lynis audit system
```

Lynis daje sugestie, ale nie należy traktować ich bezkrytycznie. Wynik trzeba interpretować w kontekście roli serwera.

---

### 24.2. Inne narzędzia

```text
OpenSCAP      — audyt zgodności,
CIS-CAT       — ocena względem CIS Benchmark,
Wazuh         — agent HIDS/SIEM,
osquery       — zapytania SQL do stanu systemu,
auditd        — audyt zdarzeń systemowych,
AIDE          — integralność plików,
rkhunter      — detekcja znanych śladów rootkitów,
chkrootkit    — detekcja znanych śladów rootkitów,
Trivy         — skanowanie obrazów kontenerów i zależności,
Dockle        — audyt Dockerfile/obrazów.
```

---

## 25. Checklist hardeningu Linux

### 25.1. System

```text
[ ] System jest aktualny.
[ ] Wymagany restart po aktualizacji został zaplanowany.
[ ] Zbędne pakiety zostały usunięte.
[ ] Zbędne usługi zostały wyłączone.
[ ] Otwarte porty zostały zweryfikowane.
[ ] Firewall jest aktywny.
[ ] Czas systemowy jest synchronizowany.
[ ] Logrotate działa.
[ ] Backup działa.
[ ] Odtwarzanie backupu zostało przetestowane.
```

---

### 25.2. Użytkownicy i dostęp

```text
[ ] Niepotrzebne konta są zablokowane.
[ ] Konta techniczne mają /usr/sbin/nologin.
[ ] Grupa sudo jest ograniczona.
[ ] Brak nieuzasadnionych reguł NOPASSWD.
[ ] Hasła są zgodne z polityką.
[ ] SSH root login jest wyłączony.
[ ] Logowanie kluczem SSH działa.
[ ] PasswordAuthentication jest wyłączone, jeśli organizacja jest na to gotowa.
[ ] Dostęp SSH jest ograniczony po adresach IP.
[ ] Fail2Ban lub inny mechanizm ochrony logowania działa.
```

---

### 25.3. Pliki i katalogi

```text
[ ] Katalogi world-writable zostały przeanalizowane.
[ ] Pliki world-writable zostały przeanalizowane.
[ ] Pliki SUID/SGID zostały zweryfikowane.
[ ] Katalog aplikacji webowej ma poprawnego właściciela i grupę.
[ ] Proces webowy nie ma zapisu do kodu aplikacji.
[ ] Sekrety nie są w katalogu publicznym.
[ ] Backupy nie są w katalogu publicznym.
[ ] Uploady nie wykonują kodu.
```

---

### 25.4. Apache/Nginx

```text
[ ] Serwer nie ujawnia szczegółowej wersji.
[ ] Listowanie katalogów jest wyłączone.
[ ] Niepotrzebne moduły są wyłączone.
[ ] Metody HTTP są ograniczone.
[ ] Nagłówki bezpieczeństwa są ustawione.
[ ] HTTPS działa.
[ ] HTTP przekierowuje na HTTPS, jeśli wymagane.
[ ] Logi access/error działają.
[ ] Pliki .env, .git i backupy są zablokowane.
[ ] Endpoint health-check działa.
```

---

### 25.5. Bazy danych

```text
[ ] Baza nie nasłuchuje publicznie bez potrzeby.
[ ] Konto aplikacyjne ma minimalne uprawnienia.
[ ] Aplikacja nie używa konta root/superuser.
[ ] Hasła są silne i rotowane zgodnie z polityką.
[ ] Backup bazy działa.
[ ] Odtwarzanie bazy zostało przetestowane.
[ ] Logi błędnych logowań są monitorowane.
```

---

### 25.6. Docker

```text
[ ] Tylko zaufani użytkownicy są w grupie docker.
[ ] Kontenery nie działają jako root, jeśli nie muszą.
[ ] Brak --privileged.
[ ] Capabilities są ograniczone.
[ ] Obrazy są aktualne.
[ ] Obrazy są skanowane.
[ ] Sekrety nie są w obrazie ani repozytorium.
[ ] Read-only filesystem jest używany tam, gdzie możliwe.
[ ] Limity CPU/RAM są ustawione.
[ ] Wolumeny mają minimalny zakres.
```

---

## 26. Typowe błędy podczas hardeningu

### Błąd 1: Zablokowanie sobie SSH

Przed restartem SSH zawsze wykonaj:

```bash
sudo sshd -t
```

I utrzymaj drugą sesję administracyjną.

---

### Błąd 2: `chmod -R 777`

```bash
sudo chmod -R 777 /var/www/html
```

To nie jest naprawa problemu. To usunięcie kontroli dostępu.

---

### Błąd 3: Wyłączenie wymaganej usługi

W CTF często gracze wyłączają Apache, Nginx, bazę danych albo endpoint monitoringu i tracą punkty za niedostępność.

---

### Błąd 4: Usunięcie aplikacji zamiast jej zabezpieczenia

Jeżeli plik jest ryzykowny, najpierw zrozum jego rolę. Czasem należy ograniczyć uprawnienia, przenieść plik, dodać regułę serwera WWW albo poprawić konfigurację, a nie usuwać.

---

### Błąd 5: Brak dokumentacji

Minimalna dokumentacja zmiany:

```text
Co znaleziono?
Jakie było ryzyko?
Co zmieniono?
Jak przetestowano?
Jaki był efekt?
Czy są skutki uboczne?
```

---

## 27. Minimalny zestaw komend diagnostycznych

```bash
hostnamectl
ip a
ip route
ss -tulpen
systemctl --type=service --state=running
ps aux --sort=-%mem | head
ps aux --sort=-%cpu | head
df -h
free -m
getent group sudo
getent group docker
cat /etc/passwd
sudo -l
find / -perm -4000 -type f 2>/dev/null
find / -writable -type d 2>/dev/null
journalctl -xe
tail -f /var/log/auth.log
curl -I http://127.0.0.1/
```

---

## 28. Wzór raportu z hardeningu

```text
1. Nazwa zespołu:
2. Adres IP maszyny:
3. Data i czas rozpoczęcia:
4. Wykryte podatności:
5. Wykonane zmiany:
6. Uzasadnienie zmian:
7. Testy po zmianach:
8. Incydenty podczas ćwiczenia:
9. Nierozwiązane problemy:
10. Wnioski:
```

Przykład wpisu:

```text
Podatność:
Użytkownik test1 był członkiem grupy sudo.

Ryzyko:
Przejęcie konta test1 umożliwiało pełną eskalację uprawnień.

Działanie:
Usunięto użytkownika test1 z grupy sudo.

Weryfikacja:
Polecenie getent group sudo pokazuje wyłącznie użytkownika ubuntu.
```

---

## 29. Podsumowanie

Hardening Linuksa jest procesem, nie jednorazową komendą. Dobry administrator lub uczestnik CTF powinien umieć:

```text
[ ] rozpoznać system,
[ ] zrozumieć rolę usług,
[ ] ograniczyć powierzchnię ataku,
[ ] zabezpieczyć użytkowników i SSH,
[ ] poprawić uprawnienia plików,
[ ] utwardzić Apache/Nginx/PHP/bazy danych,
[ ] monitorować logi,
[ ] testować każdą zmianę,
[ ] nie zepsuć dostępności,
[ ] udokumentować wykonane działania.
```

Najważniejsza zasada:

```text
Hardening nie polega na tym, żeby wszystko wyłączyć.
Hardening polega na tym, żeby system robił tylko to, co powinien, i nic więcej.
```
