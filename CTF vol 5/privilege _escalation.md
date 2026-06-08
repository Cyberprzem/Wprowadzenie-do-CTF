# Eskalacja uprawnień i obrona przed privilege escalation

(C) 2026 CyberPrzem


---

## Spis treści

1. [Cel zajęć](#1-cel-zajęć)
2. [Czym jest privilege escalation](#2-czym-jest-privilege-escalation)
3. [Eskalacja pionowa i pozioma](#3-eskalacja-pionowa-i-pozioma)
4. [Miejsce eskalacji w łańcuchu ataku](#4-miejsce-eskalacji-w-łańcuchu-ataku)
5. [Podejście Red Team i Blue Team](#5-podejście-red-team-i-blue-team)
6. [Linux privilege escalation](#6-linux-privilege-escalation)
7. [Windows privilege escalation](#7-windows-privilege-escalation)
8. [Privilege escalation w aplikacjach webowych i API](#8-privilege-escalation-w-aplikacjach-webowych-i-api)
9. [Kontenery i Docker](#9-kontenery-i-docker)
10. [Detekcja i monitoring](#10-detekcja-i-monitoring)
11. [Hardening](#11-hardening)
12. [Ściąga komend] (#12- ściąg-komend)


---

## 1. Cel zajęć

Celem zajęć jest zrozumienie, w jaki sposób atakujący po uzyskaniu pierwszego, ograniczonego dostępu do systemu próbuje zwiększyć swoje uprawnienia oraz jak Blue Team może takie działania wykrywać, ograniczać i blokować.

Po zajęciach student powinien umieć:

- wyjaśnić, czym jest eskalacja uprawnień,
- odróżnić eskalację pionową od poziomej,
- przeprowadzić podstawową lokalną enumerację w Linux i Windows,
- wskazać typowe błędy konfiguracyjne prowadzące do eskalacji,
- rozpoznać ryzyka związane z `sudo`, SUID, cron, usługami, prawami plików, kontami serwisowymi i zadaniami zaplanowanymi,
- zaproponować działania hardeningowe,
- zaproponować proste reguły detekcji,
- przygotować techniczny raport z audytu privilege escalation.

---

## 2. Czym jest privilege escalation

**Privilege escalation**, czyli eskalacja uprawnień, to uzyskanie wyższego poziomu dostępu niż pierwotnie przyznany użytkownikowi, procesowi, aplikacji lub usłudze.

Przykłady:

```text
student -> root
user -> Administrator
user -> NT AUTHORITY\SYSTEM
użytkownik aplikacji -> administrator aplikacji
konto serwisowe -> dostęp do zasobów domenowych
kontener -> dostęp do hosta
```

W praktyce początkowy dostęp często jest ograniczony. Atakujący może uzyskać powłokę jako użytkownik `www-data`, konto zwykłego użytkownika systemu, konto aplikacyjne albo konto serwisowe. Dopiero eskalacja uprawnień pozwala mu wykonać działania o większym wpływie, takie jak:

- odczyt plików systemowych,
- dostęp do haseł i sekretów,
- modyfikacja konfiguracji usług,
- instalacja narzędzi,
- wyłączenie zabezpieczeń,
- utrzymanie dostępu,
- przejście na inne hosty w sieci,
- przejęcie danych innych użytkowników.

---

## 3. Eskalacja pionowa i pozioma

### 3.1. Eskalacja pionowa

Eskalacja pionowa oznacza przejście z niższego poziomu uprawnień na wyższy.

Przykłady:

```text
zwykły użytkownik Linux -> root
zwykły użytkownik Windows -> Administrator
Administrator lokalny -> administrator domeny
user aplikacji -> admin aplikacji
```

W CTF najczęściej celem jest uzyskanie roota lub administratora.

### 3.2. Eskalacja pozioma

Eskalacja pozioma oznacza uzyskanie dostępu do zasobów innego użytkownika bez formalnej zmiany roli.

Przykład w aplikacji webowej:

```http
GET /api/users/1001/profile
```

Po zmianie identyfikatora:

```http
GET /api/users/1002/profile
```

Jeżeli użytkownik `1001` może odczytać dane użytkownika `1002`, mamy problem z autoryzacją, często określany jako IDOR lub BOLA.

---

## 4. Miejsce eskalacji w łańcuchu ataku

Typowy uproszczony łańcuch ataku:

```text
1. Reconnaissance
2. Initial Access
3. Execution
4. Local Enumeration
5. Privilege Escalation
6. Credential Access
7. Persistence
8. Lateral Movement
9. Collection / Impact
```

W CTF wygląda to podobnie:

```text
skanowanie -> podatna usługa -> niski dostęp -> enumeracja -> eskalacja -> flaga root/admin
```

Ważna uwaga: skuteczna eskalacja zwykle zaczyna się od dobrej enumeracji. Bez informacji o systemie, użytkowniku, usługach, prawach plików i konfiguracji trudno wybrać właściwą ścieżkę.

---

## 5. Podejście Red Team i Blue Team

### 5.1. Red Team

Red Team pyta:

```text
Kim jestem?
Jakie mam uprawnienia?
Do jakich grup należę?
Co mogę odczytać?
Co mogę zapisać?
Jakie usługi działają?
Czy są błędne reguły sudo?
Czy są nietypowe pliki SUID?
Czy istnieją hasła w plikach?
Czy są skrypty wykonywane cyklicznie przez roota/admina?
```

### 5.2. Blue Team

Blue Team pyta:

```text
Dlaczego dany użytkownik ma takie uprawnienia?
Czy ta usługa musi działać jako root/SYSTEM?
Czy skrypt wykonywany przez roota jest chroniony przed modyfikacją?
Czy reguły sudo są zbyt szerokie?
Czy mamy baseline SUID, usług i zadań cyklicznych?
Czy wykryjemy zmianę uprawnień?
Czy logi pozwolą odtworzyć incydent?
```

### 5.3. Schemat pracy na zajęciach

Dla każdej znalezionej podatności student powinien umieć odpowiedzieć:

```text
1. Jak wykryto problem?
2. Dlaczego jest to ryzykowne?
3. Jaki może być wpływ?
4. Jak to naprawić?
5. Jak wykrywać podobny problem w przyszłości?
```

---

## 6. Linux privilege escalation

### 6.1. Podstawowy model uprawnień Linux

Linux używa między innymi:

- użytkowników,
- grup,
- właścicieli plików,
- praw `rwx`,
- specjalnych bitów SUID, SGID i sticky bit,
- `sudo`,
- Linux capabilities,
- usług systemowych,
- zadań cron i systemd timers,
- mechanizmów kontroli dostępu takich jak AppArmor lub SELinux.

### 6.2. Podstawowa enumeracja Linux

Pierwsze komendy po uzyskaniu legalnego dostępu do maszyny laboratoryjnej:

```bash
whoami
id
groups
hostname
uname -a
cat /etc/os-release
pwd
ls -la
```

Interpretacja:

| Komenda | Po co ją wykonujemy |
|---|---|
| `whoami` | sprawdzenie bieżącego użytkownika |
| `id` | UID, GID i grupy użytkownika |
| `groups` | grupy użytkownika |
| `hostname` | nazwa hosta |
| `uname -a` | wersja jądra i architektura |
| `cat /etc/os-release` | dystrybucja i wersja systemu |
| `pwd` | aktualny katalog |
| `ls -la` | prawa do plików w katalogu |

Przykładowa interpretacja wyniku:

```bash
id
```

```text
uid=1001(student) gid=1001(student) groups=1001(student),27(sudo)
```

Wniosek: użytkownik należy do grupy `sudo`, więc należy sprawdzić, jakie polecenia może uruchamiać z podwyższonymi uprawnieniami.

---

### 6.3. Sudo

Sprawdzenie dostępnych uprawnień `sudo`:

```bash
sudo -l
```

Przykładowy niebezpieczny wynik:

```text
User student may run the following commands on ctf-vm:
    (ALL) NOPASSWD: ALL
```

Wniosek: użytkownik może wykonywać dowolne polecenia jako dowolny użytkownik bez hasła. To w praktyce pełna eskalacja do roota.

Inny przykład:

```text
User student may run the following commands on ctf-vm:
    (root) NOPASSWD: /usr/bin/vim
```

Ryzyko: edytory, interpretery i shelle mogą umożliwiać uruchamianie podprocesów. Taka reguła jest zwykle zbyt szeroka.

#### Dobre praktyki dla sudo

- Unikać `NOPASSWD`, jeżeli nie jest absolutnie konieczne.
- Nie dawać przez `sudo` dostępu do shelli, edytorów, interpreterów i narzędzi ogólnego przeznaczenia.
- Ograniczać polecenia do konkretnych ścieżek.
- Rozważać ograniczanie argumentów poleceń.
- Regularnie audytować:

```bash
sudo visudo
sudo ls -la /etc/sudoers.d/
```

#### Przykład poprawniejszego podejścia

Ryzykowny wpis:

```text
student ALL=(ALL) NOPASSWD: ALL
```

Bezpieczniejszy kierunek:

```text
student ALL=(root) /usr/bin/systemctl restart nginx
```

Nadal należy uważać: nawet konkretne polecenie może mieć skutki uboczne, jeżeli użytkownik może modyfikować konfigurację usługi, pliki unitów lub katalog roboczy.

---

### 6.4. SUID i SGID

SUID powoduje, że program uruchamia się z uprawnieniami właściciela pliku. Jeśli właścicielem jest root, program działa z uprawnieniami roota.

Wyszukiwanie SUID:

```bash
find / -perm -4000 -type f 2>/dev/null
```

Wyszukiwanie SGID:

```bash
find / -perm -2000 -type f 2>/dev/null
```

Przykładowe standardowe pliki SUID:

```text
/usr/bin/passwd
/usr/bin/sudo
/usr/bin/chsh
/usr/bin/su
```

Przykładowe podejrzane lokalizacje:

```text
/opt/backup-tool
/usr/local/bin/custom-admin
/home/student/helper
/var/www/html/tool
```

#### Co ocenić przy pliku SUID

```bash
ls -la /ścieżka/do/pliku
file /ścieżka/do/pliku
stat /ścieżka/do/pliku
```

Pytania:

```text
Kto jest właścicielem pliku?
Czy plik musi mieć SUID?
Czy jest to standardowy plik systemowy?
Czy plik znajduje się w nietypowej lokalizacji?
Czy zwykły użytkownik może go modyfikować?
Czy program wywołuje inne polecenia?
```

#### Obrona

Usuwanie niepotrzebnego SUID:

```bash
sudo chmod u-s /ścieżka/do/pliku
```

Tworzenie baseline:

```bash
find / -perm -4000 -type f 2>/dev/null | sort > suid_baseline.txt
```

Późniejsze porównanie:

```bash
find / -perm -4000 -type f 2>/dev/null | sort > suid_current.txt
diff -u suid_baseline.txt suid_current.txt
```

---

### 6.5. Linux capabilities

Capabilities pozwalają nadać procesowi wybrane uprawnienia administracyjne bez pełnego roota.

Sprawdzenie capabilities:

```bash
getcap -r / 2>/dev/null
```

Przykładowe ryzykowne capabilities:

```text
cap_setuid+ep
cap_setgid+ep
cap_dac_read_search+ep
cap_sys_admin+ep
```

Szczególnie szerokie i ryzykowne jest `cap_sys_admin`.

Usuwanie capability:

```bash
sudo setcap -r /ścieżka/do/pliku
```

Dobra praktyka: capabilities powinny być udokumentowane i ograniczone tylko do plików, które faktycznie ich potrzebują.

---

### 6.6. Prawa do plików i katalogów

Częsty błąd: plik lub katalog używany przez proces uprzywilejowany jest zapisywalny przez zwykłego użytkownika.

Sprawdzenie ważnych plików:

```bash
ls -la /etc/passwd /etc/shadow
```

Typowe poprawne prawa:

```text
/etc/passwd  -> -rw-r--r-- root root
/etc/shadow  -> -rw------- root root
```

Wyszukiwanie plików zapisywalnych:

```bash
find / -writable -type f 2>/dev/null
find / -writable -type d 2>/dev/null
```

Wyszukiwanie katalogów world-writable:

```bash
find / -perm -0002 -type d 2>/dev/null
```

Nie każdy katalog world-writable jest błędem. Przykładem standardowego katalogu jest `/tmp`, który powinien mieć sticky bit:

```bash
ls -ld /tmp
```

Poprawny przykład:

```text
drwxrwxrwt root root /tmp
```

Litera `t` oznacza sticky bit.

---

### 6.7. Cron i systemd timers

Cron i systemd timers często wykonują skrypty z uprawnieniami roota. Problem pojawia się, gdy te skrypty mogą być modyfikowane przez zwykłego użytkownika.

Sprawdzenie cron:

```bash
cat /etc/crontab
ls -la /etc/cron.d/
ls -la /etc/cron.hourly/
ls -la /etc/cron.daily/
crontab -l
```

Przykład ryzykownej konfiguracji:

```text
* * * * * root /opt/scripts/backup.sh
```

Sprawdzenie praw:

```bash
ls -la /opt/scripts/backup.sh
ls -ld /opt/scripts
```

Ryzykowny wynik:

```text
-rwxrwxrwx 1 root root 1200 backup.sh
```

Wniosek: każdy może modyfikować skrypt wykonywany przez roota.

Poprawka:

```bash
sudo chown root:root /opt/scripts/backup.sh
sudo chmod 750 /opt/scripts/backup.sh
sudo chown root:root /opt/scripts
sudo chmod 750 /opt/scripts
```

Sprawdzenie systemd timers:

```bash
systemctl list-timers
systemctl list-unit-files | grep timer
```

Sprawdzenie usługi lub timera:

```bash
systemctl cat nazwa-uslugi.service
systemctl cat nazwa-timera.timer
```

---

### 6.8. Usługi działające jako root

Sprawdzenie procesów:

```bash
ps aux
```

Sprawdzenie usług systemd:

```bash
systemctl list-units --type=service --state=running
systemctl cat nazwa-uslugi.service
```

Ryzykowne sytuacje:

```text
aplikacja webowa działa jako root
skrypt Node/Python działa jako root
katalog roboczy usługi jest zapisywalny przez zwykłych użytkowników
plik unit systemd jest modyfikowalny przez nieuprawnionych
usługa ładuje konfigurację z katalogu zapisywalnego przez użytkownika
```

Bezpieczniejsze ustawienia w unit file:

```ini
[Service]
User=webapp
Group=webapp
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/webapp
CapabilityBoundingSet=
RestrictSUIDSGID=true
```

Uwaga: każdą zmianę w unit file należy testować, bo zbyt agresywny hardening może zepsuć usługę.

---

### 6.9. Sekrety w plikach

Typowe lokalizacje sekretów:

```text
/var/www/html/config.php
/opt/app/.env
/home/*/.bash_history
/home/*/.ssh/
/etc/mysql/
docker-compose.yml
backupy .zip, .tar.gz, .bak
stare katalogi aplikacji
repozytoria .git
```

Przykładowe wyszukiwanie w laboratorium:

```bash
grep -Ri "password" /var/www /opt 2>/dev/null
grep -Ri "passwd" /var/www /opt 2>/dev/null
grep -Ri "secret" /var/www /opt 2>/dev/null
grep -Ri "token" /var/www /opt 2>/dev/null
grep -Ri "api_key" /var/www /opt 2>/dev/null
```

Obrona:

- nie trzymać sekretów w webroot,
- ograniczyć prawa do plików konfiguracyjnych,
- używać menedżera sekretów,
- rotować hasła po incydencie,
- skanować repozytoria narzędziami typu `gitleaks` lub `trufflehog`,
- nie commitować plików `.env`.

---

### 6.10. Automatyczne narzędzia enumeracyjne Linux

W CTF można używać narzędzi pomocniczych, ale nie powinny zastępować rozumienia systemu.

Przykłady narzędzi:

```text
LinPEAS
LinEnum
linux-smart-enumeration
pspy
Lynis
```

Zasada:

```text
Najpierw wykonaj podstawową ręczną enumerację.
Następnie użyj narzędzia automatycznego.
Na końcu zweryfikuj wyniki ręcznie.
```

---

## 7. Windows privilege escalation

### 7.1. Podstawowy model Windows

W Windows ważne są:

- konta lokalne,
- grupy lokalne,
- tokeny dostępu,
- przywileje użytkownika,
- UAC,
- usługi,
- zadania zaplanowane,
- prawa NTFS,
- rejestr,
- konta serwisowe,
- domena Active Directory.

---

### 7.2. Podstawowa enumeracja Windows

CMD:

```cmd
whoami
whoami /priv
whoami /groups
hostname
systeminfo
net user
net localgroup
net localgroup administrators
```

PowerShell:

```powershell
Get-LocalUser
Get-LocalGroup
Get-LocalGroupMember Administrators
Get-Service
Get-ScheduledTask
```

Interpretacja:

| Komenda | Po co ją wykonujemy |
|---|---|
| `whoami /priv` | sprawdzenie przywilejów tokenu |
| `whoami /groups` | sprawdzenie grup użytkownika |
| `net localgroup administrators` | lokalni administratorzy |
| `systeminfo` | wersja systemu i poprawki |
| `Get-Service` | usługi systemowe |
| `Get-ScheduledTask` | zadania zaplanowane |

---

### 7.3. Nadmiarowe grupy i uprawnienia

Częste błędy:

```text
zwykły użytkownik jest lokalnym administratorem
użytkownik należy do Remote Management Users bez potrzeby
konto serwisowe ma prawo logowania interaktywnego
konto helpdesk ma zbyt szerokie uprawnienia
lokalne konto administratora ma to samo hasło na wielu komputerach
```

Sprawdzenie administratorów lokalnych:

```cmd
net localgroup administrators
```

PowerShell:

```powershell
Get-LocalGroupMember Administrators
```

Obrona:

- zasada najmniejszych uprawnień,
- osobne konta administracyjne,
- Windows LAPS,
- regularny audyt grup,
- ograniczenie RDP i WinRM,
- brak pracy codziennej na koncie administratora.

---

### 7.4. Usługi Windows

Sprawdzenie usług:

```cmd
sc query
sc qc NazwaUslugi
```

PowerShell:

```powershell
Get-CimInstance Win32_Service | Select-Object Name, StartName, PathName
```

Ryzykowne sytuacje:

```text
usługa działa jako LocalSystem
katalog usługi jest zapisywalny przez zwykłych użytkowników
ścieżka do pliku wykonywalnego zawiera spacje i nie jest cytowana
użytkownik może zmienić konfigurację usługi
konto usługi ma zbyt szerokie prawa
```

Sprawdzenie ACL katalogu:

```cmd
icacls "C:\Program Files\Aplikacja"
```

Obrona:

- dedykowane konta serwisowe,
- minimalne prawa NTFS,
- cytowanie ścieżek usług,
- brak działania jako `LocalSystem`, jeśli nie jest to konieczne,
- monitorowanie instalacji i modyfikacji usług.

---

### 7.5. Zadania zaplanowane Windows

Sprawdzenie:

```cmd
schtasks /query /fo LIST /v
```

PowerShell:

```powershell
Get-ScheduledTask
```

Ryzykowny scenariusz:

```text
1. Zadanie działa jako SYSTEM.
2. Zadanie uruchamia skrypt z C:\Scripts\backup.ps1.
3. Katalog C:\Scripts jest zapisywalny przez zwykłych użytkowników.
4. Użytkownik może zmienić skrypt.
5. SYSTEM wykonuje zmodyfikowany skrypt.
```

Sprawdzenie praw:

```cmd
icacls "C:\Scripts"
```

Obrona:

- ograniczenie praw do katalogów ze skryptami,
- audyt zadań działających jako SYSTEM lub Administrator,
- usuwanie nieużywanych zadań,
- monitorowanie tworzenia nowych zadań.

---

### 7.6. PowerShell i skrypty

Ryzyka:

```text
hasła w skryptach PowerShell
skrypty uruchamiane z katalogów tymczasowych
brak logowania PowerShell
brak kontroli uruchamianych aplikacji
```

Przykładowe wyszukiwanie sekretów w laboratorium:

```powershell
Get-ChildItem -Path C:\ -Include *.config,*.xml,*.txt,*.ps1,*.bat -Recurse -ErrorAction SilentlyContinue |
Select-String -Pattern "password","passwd","pwd","secret","token"
```

Obrona:

- PowerShell Script Block Logging,
- PowerShell Module Logging,
- Constrained Language Mode tam, gdzie ma sens,
- AppLocker lub WDAC,
- brak haseł w skryptach,
- bezpieczny magazyn sekretów.

---

### 7.7. Automatyczne narzędzia enumeracyjne Windows

Przykłady narzędzi laboratoryjnych:

```text
winPEAS
Seatbelt
PowerUp
PrivescCheck
accesschk z Sysinternals
```

Zasada:

```text
Narzędzie automatyczne jest pomocą, a nie dowodem samo w sobie.
Każde znalezisko trzeba zweryfikować ręcznie.
```

---

## 8. Privilege escalation w aplikacjach webowych i API

### 8.1. Uwierzytelnianie a autoryzacja

```text
Uwierzytelnianie: kim jesteś?
Autoryzacja: co wolno ci zrobić?
```

Aplikacja może poprawnie logować użytkownika, ale nadal błędnie sprawdzać jego uprawnienia.

---

### 8.2. IDOR / BOLA

Przykład żądania:

```http
GET /api/invoices/123
```

Zmiana identyfikatora:

```http
GET /api/invoices/124
```

Jeżeli użytkownik może odczytać cudzą fakturę, to aplikacja ma problem z autoryzacją obiektową.



#### Obrona

Przykład poprawnej kontroli po stronie serwera:

```python
def get_invoice(invoice_id, current_user):
    invoice = db.get_invoice(invoice_id)

    if invoice.owner_id != current_user.id and not current_user.is_admin:
        raise Forbidden("Access denied")

    return invoice
```

Najważniejsze: nie wolno polegać wyłącznie na ukrywaniu elementów w interfejsie użytkownika.

---

### 8.3. Manipulacja rolą

Niebezpieczny wzorzec:

```json
{
  "username": "student",
  "role": "user"
}
```

Jeżeli klient może zmienić wartość na:

```json
{
  "username": "student",
  "role": "admin"
}
```

i serwer to zaakceptuje, mamy krytyczny błąd autoryzacji.

Obrona:

- rola użytkownika powinna pochodzić z zaufanego źródła po stronie serwera,
- każda operacja administracyjna musi mieć kontrolę uprawnień,
- endpointy administracyjne muszą być zabezpieczone niezależnie od interfejsu,
- testy powinny obejmować role i scenariusze negatywne.

---

### 8.4. Checklist testów autoryzacji

```text
Czy zwykły użytkownik może wejść na endpoint admina?
Czy użytkownik może zmienić user_id w żądaniu?
Czy użytkownik może odczytać cudze obiekty?
Czy użytkownik może modyfikować cudze obiekty?
Czy aplikacja ufa parametrowi role/is_admin?
Czy kontrola dostępu jest po stronie serwera?
Czy API zwraca różne dane w zależności od roli?
Czy logowane są próby dostępu do zabronionych zasobów?
```

---

## 9. Kontenery i Docker

### 9.1. Typowe błędy konfiguracji

```text
kontener działa jako root
kontener działa z --privileged
zamontowano /var/run/docker.sock
zamontowano katalog hosta jako read-write
nadmiarowe capabilities
brak profili seccomp/AppArmor
sekrety w zmiennych środowiskowych
sekrety w obrazie kontenera
```

Sprawdzenie kontenera:

```bash
docker inspect nazwa_kontenera
docker exec -it nazwa_kontenera id
docker exec -it nazwa_kontenera env
```

Szczególnie ryzykowne konfiguracje:

```bash
--privileged
-v /var/run/docker.sock:/var/run/docker.sock
-v /:/host
```

---

### 9.2. Bezpieczniejsze ustawienia docker-compose

```yaml
services:
  app:
    image: nginx:latest
    user: "1000:1000"
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /tmp
```

Dobre praktyki:

- nie uruchamiać kontenerów jako root,
- nie używać `--privileged`, jeśli nie jest to absolutnie konieczne,
- nie montować socketu Dockera do kontenera,
- usuwać zbędne capabilities,
- używać obrazów minimalnych,
- skanować obrazy narzędziami typu Trivy,
- nie przechowywać sekretów w obrazie.

---

## 10. Detekcja i monitoring

### 10.1. Co monitorować w Linux

```text
użycie sudo
zmiany /etc/sudoers
zmiany /etc/sudoers.d/
nowe pliki SUID/SGID
zmiany capabilities
zmiany /etc/crontab i /etc/cron.d/
dodanie użytkownika do grupy sudo
odczyt /etc/shadow
nowe usługi systemd
modyfikacje unit file
uruchomienie shelli przez procesy usługowe
```

Przykłady:

```bash
grep "sudo" /var/log/auth.log
journalctl _COMM=sudo
last
lastlog
```

---

### 10.2. Auditd - przykładowe reguły

Zmiany sudoers:

```bash
-w /etc/sudoers -p wa -k sudoers_change
-w /etc/sudoers.d/ -p wa -k sudoers_change
```

Zmiany crona:

```bash
-w /etc/crontab -p wa -k cron_change
-w /etc/cron.d/ -p wa -k cron_change
-w /var/spool/cron/ -p wa -k cron_change
```

Odczyt `/etc/shadow`:

```bash
-w /etc/shadow -p r -k shadow_read
```

Wyszukiwanie zdarzeń:

```bash
ausearch -k sudoers_change
ausearch -k cron_change
ausearch -k shadow_read
```

Uwaga: w środowisku produkcyjnym reguły trzeba testować pod kątem liczby zdarzeń i fałszywych alarmów.

---

### 10.3. Co monitorować w Windows

Ważne zdarzenia:

| Event ID | Znaczenie |
|---:|---|
| 4624 | udane logowanie |
| 4625 | nieudane logowanie |
| 4672 | specjalne uprawnienia przy logowaniu |
| 4720 | utworzenie konta użytkownika |
| 4728 | dodanie członka do globalnej grupy zabezpieczeń |
| 4732 | dodanie członka do lokalnej grupy zabezpieczeń |
| 4698 | utworzenie zadania zaplanowanego |
| 7045 | instalacja nowej usługi |

Przykładowa logika alertu:

```text
Jeżeli zwykły użytkownik zostaje dodany do lokalnej grupy Administrators poza oknem serwisowym, utwórz alert wysokiego ryzyka.
```

---

### 10.4. Przykładowa reguła Sigma

```yaml
title: User Added To Local Administrators Group
status: experimental
description: Detects user addition to local security group, requiring filtering for Administrators group in production.
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 4732
  condition: selection
level: high
```

W praktyce regułę należy doprecyzować o nazwę grupy, hosty krytyczne, konta techniczne i legalne procesy administracyjne.

---

### 10.5. Monitoring aplikacji webowych

Monitorować:

```text
liczne odpowiedzi 403
próby dostępu do cudzych ID
wywołania endpointów admina przez zwykłych użytkowników
zmiany parametrów role, user_id, is_admin
nietypowe sekwencje żądań API
błędy autoryzacji
```

Przykład logiki:

```text
Jeżeli użytkownik w ciągu 1 minuty próbuje odczytać zasoby o wielu kolejnych identyfikatorach, może to wskazywać na test IDOR/BOLA.
```

---

## 11. Hardening

### 11.1. Linux hardening checklist

```text
[ ] Usuń nieużywane konta.
[ ] Zablokuj konta techniczne przed logowaniem interaktywnym.
[ ] Ogranicz członkostwo w grupie sudo.
[ ] Przejrzyj /etc/sudoers i /etc/sudoers.d/.
[ ] Usuń niepotrzebne NOPASSWD.
[ ] Usuń sudo do shelli, edytorów i interpreterów.
[ ] Zrób baseline plików SUID/SGID.
[ ] Usuń niepotrzebne SUID/SGID.
[ ] Sprawdź capabilities.
[ ] Sprawdź cron i systemd timers.
[ ] Zabezpiecz skrypty wykonywane przez roota.
[ ] Uruchamiaj usługi na dedykowanych użytkownikach.
[ ] Usuń sekrety z webroot.
[ ] Ustaw minimalne prawa do plików konfiguracyjnych.
[ ] Aktualizuj system i pakiety.
[ ] Włącz logowanie i monitoring.
```

Przykładowe polecenia:

```bash
getent group sudo
sudo ls -la /etc/sudoers.d/
find / -perm -4000 -type f 2>/dev/null
getcap -r / 2>/dev/null
systemctl list-timers
```

---

### 11.2. Windows hardening checklist

```text
[ ] Ogranicz lokalnych administratorów.
[ ] Wprowadź oddzielne konta administracyjne.
[ ] Wdróż Windows LAPS.
[ ] Ogranicz RDP i WinRM.
[ ] Kontroluj konta serwisowe.
[ ] Sprawdź usługi działające jako LocalSystem.
[ ] Sprawdź ACL katalogów aplikacji.
[ ] Sprawdź zadania zaplanowane.
[ ] Włącz PowerShell logging.
[ ] Rozważ AppLocker lub WDAC.
[ ] Monitoruj Event ID 4732, 4698, 7045, 4672.
[ ] Usuń hasła ze skryptów.
[ ] Stosuj bezpieczny magazyn sekretów.
```

---

### 11.3. Aplikacje webowe hardening checklist

```text
[ ] Autoryzacja po stronie serwera dla każdej operacji.
[ ] Deny by default.
[ ] Kontrola właściciela obiektu.
[ ] Brak zaufania do user_id/role/is_admin z klienta.
[ ] Testy jednostkowe dla ról.
[ ] Testy negatywne autoryzacji.
[ ] Logowanie prób dostępu do zabronionych zasobów.
[ ] Rate limiting dla podejrzanych sekwencji żądań.
[ ] Oddzielenie panelu admina.
[ ] Przegląd endpointów API.
```

---

## 12. Ściąga komend

### Linux - podstawy

```bash
whoami
id
groups
hostname
uname -a
cat /etc/os-release
sudo -l
```

### Linux - SUID/SGID

```bash
find / -perm -4000 -type f 2>/dev/null
find / -perm -2000 -type f 2>/dev/null
```

### Linux - capabilities

```bash
getcap -r / 2>/dev/null
```

### Linux - prawa plików

```bash
ls -la /etc/passwd /etc/shadow
find / -writable -type f 2>/dev/null
find / -writable -type d 2>/dev/null
find / -perm -0002 -type d 2>/dev/null
```

### Linux - cron/systemd

```bash
cat /etc/crontab
ls -la /etc/cron.d/
crontab -l
systemctl list-timers
systemctl list-units --type=service --state=running
```

### Linux - sekrety

```bash
grep -Ri "password" /var/www /opt 2>/dev/null
grep -Ri "secret" /var/www /opt 2>/dev/null
grep -Ri "token" /var/www /opt 2>/dev/null
```

### Windows - podstawy

```cmd
whoami
whoami /priv
whoami /groups
hostname
systeminfo
net user
net localgroup administrators
```

### Windows - PowerShell

```powershell
Get-LocalUser
Get-LocalGroup
Get-LocalGroupMember Administrators
Get-Service
Get-ScheduledTask
Get-CimInstance Win32_Service | Select-Object Name, StartName, PathName
```

### Windows - ACL

```cmd
icacls "C:\Program Files\Aplikacja"
icacls "C:\Scripts"
```

### Docker

```bash
docker inspect nazwa_kontenera
docker exec -it nazwa_kontenera id
docker exec -it nazwa_kontenera env
```

---
