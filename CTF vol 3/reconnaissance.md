# Reconnaissance w działaniach Red Team
(C) 2026 CyberPrzem

## 1. Cel dokumentu

Ten dokument opisuje, jak prowadzić zdalny rekonesans  podczas autoryzowanych działań Red Team. Materiał jest przeznaczony dla studentów cyberbezpieczeństwa i ma pomóc w uporządkowanym zbieraniu informacji o maszynie ofiary, usługach sieciowych, aplikacjach webowych oraz potencjalnych wektorach dalszych testów.

> **Ważne:** wszystkie opisane techniki wolno wykonywać wyłącznie wobec systemów, do których masz wyraźną zgodę. Rekonesans wobec cudzej infrastruktury bez upoważnienia może być nielegalny.

---

## 2. Czym jest rekonesans?

Rekonesans to pierwszy etap działań ofensywnych. Jego celem jest zebranie jak największej ilości informacji o celu, zanim zostaną podjęte bardziej inwazyjne działania. Dobrze wykonany rekonesans pozwala ograniczyć zgadywanie i przejść do testów opartych na faktach.

W praktyce rekonesans odpowiada na pytania:

- Jaki adres IP lub zakres IP należy analizować?
- Jakie porty są otwarte?
- Jakie usługi działają na tych portach?
- Jakie są wersje usług i systemu operacyjnego?
- Czy działa aplikacja webowa?
- Czy są widoczne panele administracyjne, katalogi, endpointy API lub pliki konfiguracyjne?
- Czy usługi są błędnie skonfigurowane?
- Czy wykryte wersje mogą mieć znane podatności?
- Jakie informacje można zebrać bez uwierzytelnienia?

---

## 3. Podział rekonesansu

### 3.1. Rekonesans pasywny

Rekonesans pasywny polega na zbieraniu informacji bez bezpośredniej interakcji z badanym systemem lub z minimalną interakcją. W prawdziwych działaniach Red Team obejmuje m.in. OSINT, analizę DNS, repozytoriów, wycieków danych, certyfikatów TLS czy publicznych metadanych.

W środowisku CTF rekonesans pasywny może obejmować:

- analizę opisu zadania,
- analizę dostarczonych plików,
- przegląd informacji widocznych w aplikacji webowej,
- analizę nagłówków HTTP,
- analizę certyfikatu TLS, jeśli usługa używa HTTPS,
- analizę strony głównej, komentarzy HTML i plików statycznych.

### 3.2. Rekonesans aktywny

Rekonesans aktywny wymaga bezpośredniej komunikacji z maszyną ofiary. Obejmuje m.in. skanowanie portów, enumerację usług, wykrywanie technologii webowych, fuzzing katalogów oraz pobieranie banerów usług.

W środowisku laboratoryjnym jest to podstawowa forma rekonesansu.

---

## 4. Minimalny workflow rekonesansu

Zalecana kolejność działań:

1. Ustal adres IP celu.
2. Sprawdź, czy host odpowiada.
3. Wykonaj szybkie skanowanie portów.
4. Wykonaj dokładniejsze skanowanie wykrytych portów.
5. Zidentyfikuj usługi i ich wersje.
6. Sprawdź aplikacje webowe w przeglądarce.
7. Zbierz nagłówki HTTP, tytuły stron, technologie i ścieżki.
8. Wykonaj enumerację katalogów i plików.
9. Sprawdź znane podatności dla wykrytych wersji.
10. Sporządź notatki i wybierz najbardziej prawdopodobne wektory dalszych testów.

---

## 5. Przygotowanie środowiska atakującego

Przykładowy zestaw narzędzi na maszynie atakującej z Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y nmap curl wget netcat-openbsd dnsutils whois traceroute whatweb nikto gobuster dirb jq git python3 python3-pip
```

Dodatkowo warto mieć:

```bash
sudo apt install -y masscan rustscan feroxbuster wafw00f sslscan testssl.sh
```

Nie wszystkie narzędzia muszą być używane. W CTF ważniejsza jest metoda pracy niż liczba uruchomionych skanerów.

---

## 6. Ustalenie adresu IP celu

Jeżeli adres IP maszyny ofiary jest znany, zapisz go w zmiennej środowiskowej:

```bash
export TARGET=192.168.56.101
```

Sprawdzenie:

```bash
echo $TARGET
```

Jeżeli adres nie jest znany, a maszyny są w tej samej sieci laboratoryjnej, można wykonać rozpoznanie lokalnej podsieci.

Najpierw ustal adres swojej maszyny:

```bash
ip addr
ip route
```

Przykładowe skanowanie podsieci:

```bash
sudo nmap -sn 192.168.56.0/24
```

Alternatywnie:

```bash
arp -a
```

lub:

```bash
ip neigh
```

Wynik należy interpretować ostrożnie. Nie każdy host odpowiada na ping, a niektóre systemy mogą filtrować ICMP.

---

## 7. Sprawdzenie dostępności hosta

Podstawowe sprawdzenie:

```bash
ping -c 4 $TARGET
```

Jeżeli host nie odpowiada na ICMP, nie oznacza to automatycznie, że jest wyłączony. Można użyć skanowania TCP:

```bash
sudo nmap -Pn $TARGET
```

Opcja `-Pn` mówi Nmapowi, aby traktował host jako aktywny i nie polegał na odpowiedzi ping.

---

## 8. Skanowanie portów

### 8.1. Szybkie skanowanie podstawowe

```bash
nmap $TARGET
```

To polecenie sprawdza najpopularniejsze porty TCP. Jest dobre na start, ale nie wystarcza do pełnej analizy.

### 8.2. Skanowanie wszystkich portów TCP

```bash
sudo nmap -p- --min-rate 3000 -T4 $TARGET -oN nmap_all_ports.txt
```

Znaczenie opcji:

- `-p-` skanuje wszystkie porty TCP od 1 do 65535,
- `--min-rate 3000` ustala minimalne tempo pakietów,
- `-T4` przyspiesza skanowanie,
- `-oN` zapisuje wynik do pliku tekstowego.

W środowisku labowym można skanować szybciej, ale w prawdziwych testach należy dostosować intensywność do uzgodnionych zasad.

### 8.3. Skanowanie wykrytych portów z detekcją usług

Po znalezieniu otwartych portów wykonaj dokładniejszą enumerację:

```bash
sudo nmap -sV -sC -O -p 22,80,443,8080 $TARGET -oN nmap_services.txt
```

Znaczenie opcji:

- `-sV` wykrywa wersje usług,
- `-sC` uruchamia domyślne skrypty NSE,
- `-O` próbuje wykryć system operacyjny,
- `-p` wskazuje konkretne porty.

### 8.4. Skanowanie UDP

UDP często jest pomijane, a może ujawnić usługi takie jak DNS, SNMP, NTP czy TFTP.

```bash
sudo nmap -sU --top-ports 100 $TARGET -oN nmap_udp_top100.txt
```

Skanowanie UDP jest wolniejsze i mniej jednoznaczne niż TCP.

---

## 9. Alternatywne szybkie skanery

### 9.1. Rustscan

Rustscan szybko wykrywa otwarte porty i może przekazać je do Nmapa.

```bash
rustscan -a $TARGET --ulimit 5000
```

Z przekazaniem do Nmapa:

```bash
rustscan -a $TARGET -- -sV -sC
```

### 9.2. Masscan

Masscan jest bardzo szybki, ale łatwo nim wygenerować zbyt duży ruch. W laboratorium można go użyć ostrożnie.

```bash
sudo masscan $TARGET -p1-65535 --rate 1000 -oL masscan_results.txt
```

Wyniki z Masscana warto później potwierdzić Nmapem.

---

## 10. Pobieranie banerów usług

Baner usługi może zdradzić nazwę oprogramowania, wersję lub błędną konfigurację.

### 10.1. Netcat

```bash
nc -nv $TARGET 80
```

Po połączeniu z portem HTTP można ręcznie wysłać żądanie:

```http
GET / HTTP/1.1
Host: target
Connection: close

```

### 10.2. Curl

```bash
curl -i http://$TARGET/
```

Tylko nagłówki:

```bash
curl -I http://$TARGET/
```

Z podglądem przekierowań:

```bash
curl -IL http://$TARGET/
```

### 10.3. OpenSSL dla HTTPS

```bash
openssl s_client -connect $TARGET:443 -servername $TARGET
```

Pozwala sprawdzić certyfikat, obsługiwane parametry TLS i informacje o serwerze.

---

## 11. Rekonesans usług webowych

Jeżeli otwarte są porty HTTP/HTTPS, analiza aplikacji webowej jest zwykle jednym z najważniejszych etapów.

Typowe porty webowe:

- `80` HTTP,
- `443` HTTPS,
- `8080`, `8081`, `8000`, `8888` alternatywne porty HTTP,
- `3000`, `5000`, `8000` aplikacje deweloperskie,
- `9090`, `9091` panele monitoringu lub administracji,
- `10000` Webmin,
- `5601` Kibana,
- `3000` Grafana,
- `8080` Jenkins, Tomcat, Uptime Kuma lub inne panele.

### 11.1. Sprawdzenie strony głównej

```bash
curl -i http://$TARGET/
```

Sprawdź:

- kod odpowiedzi HTTP,
- nagłówki `Server`, `X-Powered-By`, `Set-Cookie`,
- przekierowania,
- tytuł strony,
- komentarze HTML,
- linki do plików JavaScript i CSS,
- formularze logowania,
- ścieżki do paneli administracyjnych.

### 11.2. WhatWeb

```bash
whatweb http://$TARGET/
```

Bardziej szczegółowo:

```bash
whatweb -v http://$TARGET/
```

WhatWeb pomaga wykrywać technologie webowe, frameworki, serwery HTTP i biblioteki JavaScript.

### 11.3. Wappalyzer

Wappalyzer to rozszerzenie do przeglądarki pozwalające wykrywać technologie użyte przez stronę. W CTF warto jednak weryfikować jego wyniki ręcznie, ponieważ automatyczna detekcja bywa błędna.

### 11.4. Nikto

```bash
nikto -h http://$TARGET/ -o nikto_http.txt
```

Nikto wykrywa częste błędy konfiguracji, niebezpieczne pliki, domyślne zasoby i znane problemy serwerów webowych.

Nie należy traktować wyniku Nikto jako dowodu podatności. To lista hipotez do ręcznej weryfikacji.

---

## 12. Enumeracja katalogów i plików

### 12.1. Gobuster

```bash
gobuster dir -u http://$TARGET/ -w /usr/share/wordlists/dirb/common.txt -o gobuster_common.txt
```

Z rozszerzeniami plików:

```bash
gobuster dir -u http://$TARGET/ -w /usr/share/wordlists/dirb/common.txt -x php,txt,html,js,bak,old,zip -o gobuster_ext.txt
```

Przykładowe interesujące wyniki:

- `/admin`,
- `/login`,
- `/backup`,
- `/uploads`,
- `/config.php.bak`,
- `/robots.txt`,
- `/.git/`,
- `/server-status`,
- `/phpinfo.php`,
- `/api/`,
- `/health.php`.

### 12.2. Feroxbuster

```bash
feroxbuster -u http://$TARGET/ -w /usr/share/wordlists/dirb/common.txt -o feroxbuster.txt
```

Feroxbuster jest szybki i dobrze radzi sobie z rekursywną enumeracją.

### 12.3. Dirb

```bash
dirb http://$TARGET/
```

Dirb jest prostszy, ale nadal użyteczny na zajęciach wprowadzających.

---

## 13. Pliki specjalne w aplikacjach webowych

Warto ręcznie sprawdzić:

```bash
curl http://$TARGET/robots.txt
curl http://$TARGET/sitemap.xml
curl http://$TARGET/.env
curl http://$TARGET/.git/HEAD
curl http://$TARGET/backup.zip
curl http://$TARGET/config.php.bak
curl http://$TARGET/phpinfo.php
curl http://$TARGET/server-status
```

Typowe błędy:

- pozostawione kopie zapasowe,
- publiczne pliki `.env`,
- katalog `.git` dostępny przez WWW,
- panel statusu Apache bez ograniczeń,
- pliki testowe i diagnostyczne,
- stare archiwa aplikacji,
- endpointy health-check ujawniające zbyt dużo informacji.

---

## 14. Analiza nagłówków HTTP

Polecenie:

```bash
curl -I http://$TARGET/
```

Zwróć uwagę na brak lub obecność nagłówków bezpieczeństwa:

- `Content-Security-Policy`,
- `X-Frame-Options`,
- `X-Content-Type-Options`,
- `Referrer-Policy`,
- `Permissions-Policy`,
- `Strict-Transport-Security` dla HTTPS.

Brak tych nagłówków nie oznacza automatycznie krytycznej podatności, ale jest sygnałem słabego hardeningu aplikacji webowej.

---

## 15. Analiza TLS/SSL

Jeżeli działa HTTPS:

```bash
sslscan $TARGET:443
```

lub:

```bash
testssl.sh https://$TARGET/
```

Sprawdź:

- wersje TLS,
- słabe szyfry,
- poprawność certyfikatu,
- datę ważności,
- CN/SAN w certyfikacie,
- HSTS,
- możliwość użycia starych protokołów.

---

## 16. Enumeracja SSH

Jeżeli port `22/tcp` jest otwarty:

```bash
nmap -sV -p22 $TARGET
```

Sprawdzenie banera:

```bash
nc -nv $TARGET 22
```

Wyniki mogą ujawnić:

- wersję OpenSSH,
- dystrybucję systemu,
- informację o starszej konfiguracji,
- nietypowy port SSH.

Nie wykonuj brute-force bez wyraźnego celu zgody właściciela. W typowym rekonesansie CTF samo wykrycie SSH oznacza możliwość późniejszego użycia znalezionych poświadczeń, kluczy lub kont.

---

## 17. Enumeracja SMB

Jeżeli otwarte są porty `139/tcp` lub `445/tcp`:

```bash
nmap -sV -sC -p139,445 $TARGET
```

Sprawdzenie udziałów anonimowych:

```bash
smbclient -L //$TARGET/ -N
```

Jeżeli znasz login:

```bash
smbclient -L //$TARGET/ -U username
```

Narzędzia pomocnicze:

```bash
enum4linux-ng $TARGET
```

Typowe ustalenia:

- dostęp anonimowy,
- udziały publiczne,
- nazwa hosta,
- nazwa domeny/grupy roboczej,
- lista użytkowników,
- źle ustawione uprawnienia udziałów.

---

## 18. Enumeracja FTP

Jeżeli otwarty jest port `21/tcp`:

```bash
nmap -sV -sC -p21 $TARGET
```

Sprawdzenie logowania anonimowego:

```bash
ftp $TARGET
```

Spróbuj użytkownika:

```text
anonymous
```

Jako hasło często podaje się dowolny adres e-mail, np.:

```text
anonymous@example.com
```

Interesujące są:

- możliwość anonimowego logowania,
- możliwość zapisu plików,
- pliki kopii zapasowych,
- konfiguracje aplikacji,
- logi,
- klucze prywatne.

---

## 19. Enumeracja DNS

Jeżeli cel udostępnia DNS, zwykle port `53/tcp` lub `53/udp`:

```bash
nmap -sV -sU -p53 $TARGET
```

Podstawowe zapytania:

```bash
dig @$TARGET example.local A
```

Próba transferu strefy, jeśli znasz domenę:

```bash
dig @$TARGET example.local AXFR
```

Udany transfer strefy może ujawnić subdomeny i strukturę środowiska.

---

## 20. Enumeracja SNMP

Jeżeli otwarty jest port `161/udp`:

```bash
sudo nmap -sU -p161 --script snmp-info $TARGET
```

Próba z domyślną community string:

```bash
snmpwalk -v2c -c public $TARGET
```

SNMP może ujawnić:

- nazwę hosta,
- użytkowników,
- interfejsy sieciowe,
- uruchomione procesy,
- zainstalowane oprogramowanie,
- informacje o systemie.

---

## 21. Enumeracja paneli administracyjnych i monitoringu

W Twoim scenariuszu maszyna ofiary może zawierać usługę webową oraz monitoring, np. Uptime Kuma.

Warto sprawdzić typowe porty:

```bash
sudo nmap -sV -sC -p80,443,3000,8080,9090,9091 $TARGET
```

Przykładowe panele:

- Uptime Kuma: często `3001/tcp`,
- Grafana: często `3000/tcp`,
- Prometheus: często `9090/tcp`,
- Node Exporter: często `9100/tcp`,
- cAdvisor: często `8080/tcp`,
- Cockpit: często `9090/tcp`,
- Webmin: często `10000/tcp`.

Sprawdź:

- czy panel wymaga logowania,
- czy są domyślne dane dostępowe,
- czy panel ujawnia status usług,
- czy można odczytać adresy endpointów,
- czy monitorowane URL-e zdradzają wewnętrzne ścieżki,
- czy aplikacja ujawnia wersję.

---

## 22. Analiza znanych podatności

Po wykryciu wersji usług można szukać znanych podatności.

### 22.1. Searchsploit

Instalacja:

```bash
sudo apt install -y exploitdb
```

Przykład użycia:

```bash
searchsploit apache 2.4.49
searchsploit nginx 1.18
searchsploit openssh 7.2
```

Wyniki traktuj jako punkt startowy do analizy, a nie gotowy dowód podatności. Sama wersja nie zawsze oznacza podatność, bo dystrybucje Linuksa często backportują poprawki bezpieczeństwa.

### 22.2. Źródła do ręcznej weryfikacji

W autoryzowanych testach warto weryfikować podatności w źródłach takich jak:

- dokumentacja producenta,
- changelogi,
- CVE/NVD,
- GitHub Security Advisories,
- Exploit-DB,
- Packet Storm,
- advisories dystrybucji Linuxa.

---

## 23. Rekonesans z użyciem NSE Nmapa

Nmap Scripting Engine pozwala wykonać wiele testów enumeracyjnych.

Lista skryptów:

```bash
ls /usr/share/nmap/scripts/
```

Przykładowe użycie dla HTTP:

```bash
nmap --script http-title,http-headers,http-server-header -p80,8080 $TARGET
```

Dla SMB:

```bash
nmap --script smb-enum-shares,smb-enum-users -p445 $TARGET
```

Dla SSL/TLS:

```bash
nmap --script ssl-enum-ciphers -p443 $TARGET
```

Dla domyślnych skryptów:

```bash
nmap -sC -sV $TARGET
```

Unikaj bezrefleksyjnego uruchamiania agresywnych skryptów wobec systemów produkcyjnych. W labie można testować szerzej, ale nadal warto rozumieć, co robi dany skrypt.

---

## 24. Dokumentowanie wyników

Rekonesans bez notatek szybko traci wartość. Zalecana struktura notatek:

```text
Cel: 192.168.56.101
Data: 2026-xx-xx
Operator: imię/nick

1. Host discovery
- Host aktywny: tak/nie
- MAC/vendor: ...

2. Otwarte porty
- 22/tcp OpenSSH 8.x
- 80/tcp Apache 2.4.x
- 3001/tcp Uptime Kuma

3. HTTP/HTTPS
- Tytuł strony: ...
- Technologie: ...
- Nagłówki: ...
- Interesujące ścieżki: ...

4. Potencjalne problemy
- Brak nagłówków bezpieczeństwa
- Dostępny /server-status
- Dostępny /backup.zip
- Stary Apache/nginx
- Panel monitoringu dostępny bez MFA

5. Hipotezy dalszych testów
- Sprawdzenie backupów
- Sprawdzenie panelu logowania
- Analiza katalogów aplikacji
- Weryfikacja znanych CVE
```

Wyniki narzędzi zapisuj do plików:

```bash
mkdir -p recon/$TARGET
nmap -sV -sC $TARGET -oN recon/$TARGET/nmap_initial.txt
curl -I http://$TARGET/ > recon/$TARGET/http_headers.txt
whatweb http://$TARGET/ > recon/$TARGET/whatweb.txt
gobuster dir -u http://$TARGET/ -w /usr/share/wordlists/dirb/common.txt -o recon/$TARGET/gobuster.txt
```

---

## 25. Przykładowy kompletny przebieg rekonesansu

Załóżmy, że adresem ofiary jest `192.168.56.101`.

```bash
export TARGET=192.168.56.101
mkdir -p recon/$TARGET
```

Sprawdzenie hosta:

```bash
ping -c 4 $TARGET
```

Szybkie wykrycie portów:

```bash
sudo nmap -p- --min-rate 3000 -T4 $TARGET -oN recon/$TARGET/nmap_all_ports.txt
```

Dokładniejsza enumeracja wykrytych portów:

```bash
sudo nmap -sV -sC -O -p22,80,3001 $TARGET -oN recon/$TARGET/nmap_services.txt
```

Analiza HTTP:

```bash
curl -i http://$TARGET/ | tee recon/$TARGET/http_index.txt
curl -I http://$TARGET/ | tee recon/$TARGET/http_headers.txt
whatweb http://$TARGET/ | tee recon/$TARGET/whatweb.txt
```

Enumeracja katalogów:

```bash
gobuster dir -u http://$TARGET/ -w /usr/share/wordlists/dirb/common.txt -x php,txt,html,bak,old,zip -o recon/$TARGET/gobuster.txt
```

Analiza panelu monitoringu, jeśli wykryto np. port `3001`:

```bash
curl -I http://$TARGET:3001/
whatweb http://$TARGET:3001/
```

Sprawdzenie znanych podatności:

```bash
searchsploit apache
searchsploit uptime kuma
searchsploit openssh
```

---

## 26. Typowe błędy

1. Skanowanie tylko domyślnych 1000 portów i pominięcie usług na nietypowych portach.
2. Brak zapisywania wyników do plików.
3. Bezrefleksyjne kopiowanie wyników skanerów bez ręcznej weryfikacji.
4. Pomijanie aplikacji webowej i skupienie tylko na Nmapie.
5. Ignorowanie nagłówków HTTP i plików takich jak `robots.txt`.
6. Brak korelacji informacji, np. wersja usługi plus ścieżka administracyjna plus znaleziony backup.
7. Traktowanie każdego CVE jako potwierdzonej podatności.
8. Zbyt agresywne skanowanie bez zrozumienia wpływu na usługę.
9. Brak rozróżnienia między informacją, hipotezą a potwierdzonym znaleziskiem.
10. Brak uporządkowanego raportu końcowego.

---

## 27. Checklista rekonesansu Red Team/CTF

### Host i sieć

- [ ] Ustalono adres IP celu.
- [ ] Sprawdzono dostępność hosta.
- [ ] Wykonano skan wszystkich portów TCP.
- [ ] Wykonano skan wybranych portów UDP.
- [ ] Zidentyfikowano usługi i wersje.
- [ ] Zapisano wyniki skanowania.

### Web

- [ ] Sprawdzono stronę główną.
- [ ] Sprawdzono nagłówki HTTP.
- [ ] Sprawdzono komentarze HTML.
- [ ] Sprawdzono `robots.txt` i `sitemap.xml`.
- [ ] Wykonano enumerację katalogów.
- [ ] Sprawdzono typowe pliki konfiguracyjne i backupy.
- [ ] Wykryto technologie webowe.
- [ ] Sprawdzono panele administracyjne.

### Usługi

- [ ] Sprawdzono SSH.
- [ ] Sprawdzono FTP, jeśli występuje.
- [ ] Sprawdzono SMB, jeśli występuje.
- [ ] Sprawdzono DNS, jeśli występuje.
- [ ] Sprawdzono SNMP, jeśli występuje.
- [ ] Sprawdzono panele monitoringu.

### Analiza

- [ ] Zebrano wersje usług.
- [ ] Zweryfikowano potencjalne CVE.
- [ ] Odróżniono hipotezy od potwierdzonych znalezisk.
- [ ] Wskazano najbardziej prawdopodobne ścieżki dalszego testowania.
- [ ] Przygotowano krótkie podsumowanie dla zespołu.

---

## 28. Przykładowy szablon raportu

```markdown
# Raport z rekonesansu

## Cel

- Adres IP:
- Zakres testu:
- Data:
- Operator:

## Podsumowanie

Krótki opis najważniejszych ustaleń.

## Otwarte porty

| Port | Protokół | Usługa | Wersja | Uwagi |
|------|----------|--------|--------|-------|
| 22   | TCP      | SSH    | ...    | ...   |
| 80   | TCP      | HTTP   | ...    | ...   |

## Aplikacje webowe

- URL:
- Tytuł strony:
- Technologie:
- Nagłówki:
- Interesujące ścieżki:

## Potencjalne podatności i błędy konfiguracji

| Znalezisko | Dowód | Ryzyko | Status |
|-----------|-------|--------|--------|
| ...       | ...   | ...    | hipoteza/potwierdzone |

## Rekomendowane dalsze testy

1. ...
2. ...
3. ...

## Elementy do hardeningu

1. ...
2. ...
3. ...
```

---

## 29. Najważniejsza zasada

Dobry rekonesans nie polega na uruchomieniu jednego skanera. Polega na stopniowym budowaniu obrazu celu, łączeniu informacji z wielu źródeł i świadomym wybieraniu kolejnych działań.

W CTF najczęściej wygrywa nie ten, kto uruchamia najwięcej narzędzi, ale ten, kto najlepiej interpretuje wyniki.
