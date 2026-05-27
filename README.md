# Wprowadzenie do CTF

(C) Cyber Przem 2026

## Materiał podsumowujący dla studentów

**Temat:** Capture The Flag jako praktyczny trening cyberbezpieczeństwa  
**Adresaci:** studenci planujący udział w CTF  
**Cel dokumentu:** uporządkowanie wiedzy po spotkaniu wprowadzającym i przygotowanie do pierwszych ćwiczeń praktycznych  
**Zakres:** typy konkursów CTF, kategorie zadań, narzędzia, metodyka pracy, etyka, dokumentowanie rozwiązań, podstawy ICS/OT Defense CTF

---

## 1. Po co uczymy się CTF?

CTF, czyli **Capture The Flag**, to forma praktycznych zawodów lub ćwiczeń z cyberbezpieczeństwa. Uczestnik rozwiązuje zadania techniczne, a potwierdzeniem rozwiązania jest odnalezienie ukrytej wartości nazywanej **flagą**.

Przykład flagi:

```text
flag{pierwsze_zadanie_rozwiazane}
```

Flaga może być ukryta w:

- kodzie strony internetowej,
- pliku binarnym,
- obrazie graficznym,
- ruchu sieciowym,
- logach systemowych,
- bazie danych,
- zrzucie pamięci RAM,
- podatnej aplikacji,
- źle zaimplementowanym algorytmie kryptograficznym,
- konfiguracji usługi,
- dokumentacji lub danych OSINT.

Najważniejsze nie jest samo znalezienie flagi. Najważniejsze jest dojście do rozwiązania: analiza problemu, wybór metody, testowanie hipotez, praca z narzędziami i dokumentowanie wyników.

CTF rozwija umiejętności, które są bardzo przydatne w realnej pracy związanej z cyberbezpieczeństwem:

- analizę techniczną,
- testowanie aplikacji webowych,
- analizę ruchu sieciowego,
- analizę logów,
- podstawy kryptografii praktycznej,
- reverse engineering,
- podstawy exploit developmentu,
- automatyzację w Pythonie i Bashu,
- pracę z systemem Linux,
- dokumentowanie działań,
- pracę zespołową,
- myślenie pod presją czasu,
- selekcję informacji,
- umiejętność korzystania z dokumentacji.

CTF-y nie zastępują pełnego procesu audytu, testu penetracyjnego, analizy ryzyka czy reagowania na incydenty. Są jednak bardzo dobrym środowiskiem treningowym, ponieważ pozwalają bezpiecznie ćwiczyć techniki, które w realnych systemach wymagają formalnej zgody i precyzyjnie określonego zakresu.

---

## 2. CTF to nie tylko „hakowanie”

Początkujący często utożsamiają CTF z przypadkowym uruchamianiem narzędzi. To błąd. Skuteczny uczestnik CTF nie zaczyna od narzędzia, lecz od zrozumienia problemu.

Poprawne podejście wygląda tak:

1. Czytam opis zadania.
2. Sprawdzam, co otrzymałem: plik, adres URL, usługę, log, obraz, kod źródłowy.
3. Rozpoznaję kategorię zadania.
4. Sprawdzam podstawowe właściwości materiału.
5. Stawiam hipotezy.
6. Testuję jedną hipotezę naraz.
7. Zapisuję wyniki.
8. Jeżeli utknę, proszę zespół o drugą parę oczu.
9. Po rozwiązaniu opisuję metodę w write-upie.

Narzędzie jest tylko środkiem do celu. Przykładowo:

- `file` nie „rozwiązuje” zadania, ale pomaga rozpoznać typ pliku.
- `strings` nie zastępuje reverse engineeringu, ale może szybko ujawnić czytelne ciągi znaków.
- Burp Suite nie znajduje automatycznie wszystkich podatności, ale pozwala analizować i modyfikować ruch HTTP.
- Wireshark nie interpretuje całego incydentu za analityka, ale daje dostęp do pakietów i strumieni komunikacji.
- Ghidra nie myśli za reversera, ale ułatwia analizę programu.

W CTF-ach często wygrywa nie osoba, która zna najwięcej narzędzi, lecz ta, która potrafi szybko rozpoznać, które narzędzie jest właściwe dla danego problemu.

---

## 3. Typy konkursów CTF

### 3.1. Jeopardy-style CTF

To najczęściej spotykany typ konkursu, szczególnie dobry dla początkujących.

Zasady:

- organizator udostępnia zestaw zadań,
- zadania są podzielone na kategorie,
- każde zadanie ma przypisaną liczbę punktów,
- uczestnik lub zespół zdobywa punkty po przesłaniu poprawnej flagi,
- zadania łatwiejsze zwykle mają mniej punktów, trudniejsze więcej.

Typowe kategorie:

- Web,
- Crypto,
- Forensics,
- Reverse Engineering,
- Pwn,
- OSINT,
- Network,
- Misc.

Ten format pozwala spokojnie rozwijać specjalizacje. Jedna osoba może rozwiązywać web, druga crypto, trzecia forensics, a czwarta reverse engineering.

### 3.2. Attack-Defense CTF

W tym formacie każdy zespół otrzymuje własną infrastrukturę. Celem jest jednoczesna obrona własnych usług i atakowanie usług innych zespołów.

Wymaga to umiejętności z zakresu:

- administracji systemami,
- monitoringu,
- patchowania,
- analizy kodu,
- exploit developmentu,
- automatyzacji,
- zarządzania usługami,
- komunikacji w zespole.

Ten format jest trudniejszy od Jeopardy, ponieważ wymaga ciągłego utrzymania infrastruktury. Samo znalezienie podatności nie wystarcza. Trzeba jeszcze:

- zrozumieć podatną usługę,
- przygotować poprawkę,
- nie zepsuć działania usługi,
- monitorować ataki innych zespołów,
- automatyzować wykorzystanie podatności u przeciwników.

### 3.3. Blue Team / SOC CTF

Ten format skupia się na analizie incydentów, logów, alarmów i ruchu sieciowego.

Typowe zadania:

- analiza alertu SIEM,
- ustalenie źródła ataku,
- rekonstrukcja osi czasu incydentu,
- analiza logów Windows/Linux,
- analiza PCAP,
- identyfikacja użytej podatności,
- wskazanie konta, które zostało przejęte,
- określenie zakresu wycieku danych,
- przygotowanie raportu incydentu.

To bardzo dobry format dla osób zainteresowanych pracą w SOC, DFIR, threat huntingu i reagowaniu na incydenty.

### 3.4. King of the Hill

W tym formacie zespoły walczą o przejęcie i utrzymanie kontroli nad konkretnym zasobem, usługą lub maszyną.

Najważniejsze umiejętności:

- szybkie rozpoznanie,
- wykorzystanie podatności,
- utrzymanie dostępu,
- usuwanie dostępu przeciwnikom,
- zabezpieczanie przejętej maszyny,
- monitorowanie zmian.

Ten format może być dynamiczny i chaotyczny, dlatego wymaga dobrej organizacji.

### 3.5. ICS/OT Defense CTF

To format związany z obroną środowisk przemysłowych i operacyjnych.

Uczestnicy mogą pracować ze środowiskiem zawierającym:

- HMI,
- SCADA,
- PLC,
- historian,
- serwer inżynierski,
- segment IT,
- segment OT,
- przemysłową DMZ,
- logi procesowe,
- ruch Modbus/OPC UA/S7comm,
- systemy monitoringu.

W takim CTF-ie nie chodzi wyłącznie o zdobycie flagi. Często trzeba:

- utrzymać dostępność usług,
- wykryć nietypowy ruch,
- zidentyfikować próbę manipulacji procesem,
- ograniczyć skutki incydentu,
- zachować bezpieczeństwo procesu,
- przygotować raport.

W środowisku OT najważniejsze jest bezpieczeństwo ludzi, procesu i dostępność systemów. Nie wolno działać impulsywnie.

---

## 4. Kategorie zadań CTF

## 4.1. Web Security

Web to jedna z najlepszych kategorii na start. Zadania dotyczą aplikacji internetowych, API, HTTP, sesji, ciasteczek, tokenów i błędów logiki.

Typowe podatności:

- SQL Injection,
- Cross-Site Scripting,
- Cross-Site Request Forgery,
- Server-Side Request Forgery,
- IDOR,
- path traversal,
- Local File Inclusion,
- Remote File Inclusion,
- command injection,
- template injection,
- insecure deserialization,
- błędy w JWT,
- błędy autoryzacji,
- błędy logiki biznesowej,
- podatności API,
- błędy uploadu plików.

Typowe pierwsze kroki w zadaniu webowym:

1. Otwórz aplikację w przeglądarce.
2. Sprawdź kod źródłowy HTML.
3. Sprawdź pliki JavaScript.
4. Otwórz DevTools.
5. Sprawdź ciasteczka, localStorage i sessionStorage.
6. Przechwyć ruch w Burp Suite albo OWASP ZAP.
7. Sprawdź parametry GET i POST.
8. Sprawdź nagłówki HTTP.
9. Poszukaj ukrytych endpointów.
10. Zidentyfikuj mechanizmy uwierzytelniania i autoryzacji.

Przydatne komendy:

```bash
curl -i http://example.local/
curl -X POST http://example.local/login -d 'user=test&pass=test'
ffuf -u http://example.local/FUZZ -w wordlist.txt
gobuster dir -u http://example.local/ -w wordlist.txt
```

W zadaniach webowych bardzo ważne jest odróżnienie uwierzytelniania od autoryzacji:

- **uwierzytelnianie** odpowiada na pytanie: „kim jesteś?”,
- **autoryzacja** odpowiada na pytanie: „co wolno ci zrobić?”.

Przykład błędu IDOR:

```text
https://app.local/invoice?id=1001
https://app.local/invoice?id=1002
```

Jeśli użytkownik może zmienić `id` i zobaczyć cudzą fakturę, aplikacja ma problem z kontrolą dostępu.

## 4.2. Crypto

Crypto w CTF-ach zwykle nie polega na łamaniu silnych algorytmów. Częściej polega na znalezieniu błędu w sposobie użycia algorytmu.

Typowe tematy:

- Base64,
- hex,
- URL encoding,
- rot13,
- Caesar cipher,
- Vigenere,
- XOR,
- hashe,
- RSA,
- AES w błędnym trybie,
- powtórzony nonce,
- słaba losowość,
- padding oracle,
- złe generowanie kluczy,
- błędne porównywanie sekretów.

Trzeba rozróżniać:

- **kodowanie** — zmiana reprezentacji danych, np. Base64, hex, URL encoding,
- **haszowanie** — jednokierunkowe przekształcenie danych, np. SHA-256,
- **szyfrowanie** — przekształcenie danych z użyciem klucza, możliwe do odwrócenia po posiadaniu klucza.

Base64 nie jest szyfrowaniem. To tylko kodowanie.

Przykład dekodowania Base64:

```bash
echo 'ZmxhZ3twb2RzdGF3eV9jdGZ9' | base64 -d
```

Przykład XOR z jednym bajtem w Pythonie:

```python
data = bytes.fromhex("0f0a1b1b")
for key in range(256):
    result = bytes([b ^ key for b in data])
    if b"flag" in result or b"ctf" in result:
        print(key, result)
```

Dobre podejście do zadań crypto:

1. Rozpoznaj format danych.
2. Sprawdź, czy to kodowanie, hash, czy szyfrogram.
3. Poszukaj wskazówek w opisie zadania.
4. Sprawdź długość danych.
5. Ustal, czy klucz jest znany, powtarzalny lub możliwy do brute-force.
6. Napisz mały skrypt, zamiast robić wszystko ręcznie.
7. Sprawdź, czy wynik wygląda jak tekst, JSON, flaga albo plik.

## 4.3. Forensics

Forensics polega na analizie śladów cyfrowych.

Typowe materiały:

- pliki graficzne,
- archiwa ZIP/RAR/7z,
- dokumenty PDF/DOCX,
- obrazy dysków,
- zrzuty pamięci RAM,
- pliki PCAP,
- logi,
- katalogi użytkowników,
- metadane,
- pliki usunięte lub ukryte.

Pierwsze kroki przy analizie pliku:

```bash
file podejrzany_plik
strings podejrzany_plik | less
xxd podejrzany_plik | head
exiftool podejrzany_plik
binwalk podejrzany_plik
```

Pytania, które należy sobie zadać:

- Czy rozszerzenie pliku odpowiada jego rzeczywistemu typowi?
- Czy plik zawiera czytelne ciągi znaków?
- Czy są metadane?
- Czy na końcu pliku doklejono dodatkowe dane?
- Czy w pliku znajduje się ukryte archiwum?
- Czy plik jest uszkodzony celowo?
- Czy trzeba odtworzyć strukturę pliku?
- Czy są ślady czasu, użytkownika, programu lub systemu?

Przykłady narzędzi:

- `file`,
- `strings`,
- `xxd`,
- `exiftool`,
- `binwalk`,
- `foremost`,
- `scalpel`,
- `steghide`,
- `zsteg`,
- Wireshark,
- Volatility,
- Autopsy.

Forensics jest blisko realnej pracy DFIR. W realnym incydencie trzeba nie tylko znaleźć flagę, ale też odpowiedzieć:

- co się wydarzyło,
- kiedy się wydarzyło,
- kto lub co było źródłem zdarzenia,
- jaki był zakres kompromitacji,
- jakie dane mogły zostać naruszone,
- jakie działania naprawcze należy wykonać.

## 4.4. Network

Zadania sieciowe dotyczą komunikacji między hostami, protokołów, usług i ruchu pakietowego.

Typowe materiały:

- pliki `.pcap`,
- adres IP i port usługi,
- logi proxy,
- logi DNS,
- konfiguracje sieciowe,
- fragmenty ruchu HTTP/FTP/SMB/DNS/TLS.

Podstawowe narzędzia:

- Wireshark,
- tshark,
- tcpdump,
- nmap,
- Zeek,
- NetworkMiner,
- curl,
- netcat.

Przydatne filtry Wiresharka:

```text
http
http.request
http.request.method == "POST"
dns
tcp.port == 80
ip.addr == 192.168.1.10
frame contains "flag"
```

Przydatne komendy:

```bash
nmap -sV 192.168.1.10
nmap -sC -sV -oN scan.txt 192.168.1.10
tcpdump -i eth0 -w ruch.pcap
tshark -r ruch.pcap -Y http.request
```

Dobre pytania podczas analizy PCAP:

- Jakie hosty komunikują się ze sobą?
- Jakie protokoły występują?
- Czy są żądania HTTP POST?
- Czy przesłano login, hasło lub token?
- Czy można odtworzyć plik ze strumienia?
- Czy występują nietypowe zapytania DNS?
- Czy ruch jest szyfrowany?
- Czy flaga jest przesłana jawnie?

## 4.5. Reverse Engineering

Reverse engineering to analiza działania programu bez pełnej dokumentacji lub bez kodu źródłowego.

Typowe zadania:

- program pyta o hasło,
- program sprawdza klucz licencyjny,
- program ukrywa flagę,
- program szyfruje dane,
- program zawiera warunek logiczny,
- trzeba odtworzyć algorytm generowania flagi.

Pierwsze kroki:

```bash
file program
strings program | less
chmod +x program
./program
ltrace ./program
strace ./program
```

Dla programów ELF przydatne są:

```bash
readelf -h program
objdump -d program | less
checksec --file=program
gdb ./program
```

Narzędzia graficzne:

- Ghidra,
- IDA Free,
- Cutter,
- Binary Ninja Free.

W prostych zadaniach reverse engineeringu często wystarczy:

- sprawdzić `strings`,
- znaleźć komunikat „Correct” albo „Wrong”,
- ustalić, jakie porównanie wykonuje program,
- odtworzyć warunek poprawnego hasła,
- uruchomić program z odpowiednim wejściem.

W trudniejszych zadaniach trzeba znać podstawy:

- architektury procesora,
- asemblera,
- stosu,
- rejestrów,
- funkcji,
- debugowania,
- dekompilacji.

## 4.6. Pwn / Binary Exploitation

Pwn to wykorzystywanie błędów w programach binarnych.

Typowe tematy:

- buffer overflow,
- format string,
- ret2win,
- ROP,
- heap exploitation,
- integer overflow,
- use-after-free,
- stack canary,
- NX,
- ASLR,
- PIE,
- RELRO.

To jedna z trudniejszych kategorii, dlatego wymaga stopniowego podejścia.

Na początku trzeba rozumieć:

- czym jest stos,
- czym jest bufor,
- czym jest adres powrotu,
- czym jest przepełnienie bufora,
- dlaczego dane wejściowe mogą zmienić przebieg programu,
- jakie zabezpieczenia utrudniają exploitację.

Przykładowy schemat analizy:

```bash
file vuln
checksec --file=vuln
./vuln
gdb ./vuln
```

Pwntools pozwala automatyzować komunikację z procesem lub usługą:

```python
from pwn import *

p = process("./vuln")
p.sendline(b"AAAA")
p.interactive()
```

Pwn jest wymagający, ale bardzo dobrze uczy niskopoziomowego działania programów.

## 4.7. OSINT

OSINT to analiza informacji ze źródeł jawnych.

W CTF-ach OSINT może obejmować:

- analizę zdjęcia,
- geolokalizację,
- metadane,
- analizę domeny,
- historię strony,
- wyszukiwanie profilu,
- korelację pseudonimów,
- analizę publicznych repozytoriów,
- wyszukiwanie fragmentów tekstu,
- analizę map i zdjęć satelitarnych.

Zasady OSINT:

- działamy tylko w zakresie zadania,
- nie nękamy realnych osób,
- nie publikujemy prywatnych informacji,
- nie obchodzimy zabezpieczeń,
- nie logujemy się na cudze konta,
- nie wykonujemy działań niezgodnych z regulaminem.

Największy błąd w OSINT to szybkie przyjęcie pierwszej hipotezy. Trzeba weryfikować informacje z kilku źródeł i uważać na fałszywe tropy.

## 4.8. Misc

Misc to kategoria zbiorcza. Może obejmować wszystko, co nie pasuje do pozostałych kategorii.

Przykłady:

- zadania logiczne,
- nietypowe formaty plików,
- Docker,
- sandbox escape w środowisku testowym,
- blockchain,
- AI security,
- zadania programistyczne,
- automatyzacja,
- protokoły niestandardowe,
- łamigłówki.

W misc szczególnie ważna jest elastyczność. Często trzeba czytać dokumentację, eksperymentować i szybko uczyć się nowego formatu lub narzędzia.

---

## 5. Podstawowe środowisko pracy

Każdy uczestnik koła powinien przygotować środowisko, które pozwoli mu rozwiązywać zadania bez długiej konfiguracji na każdym spotkaniu.

Minimalny zestaw:

- Linux, WSL2 albo maszyna wirtualna,
- Python 3,
- Git,
- Docker,
- edytor kodu,
- Burp Suite Community,
- Wireshark,
- CyberChef,
- podstawowe narzędzia CLI,
- Ghidra,
- konto na platformach treningowych.

Przykładowa struktura katalogów:

```text
ctf/
├── 2026-spotkanie-01/
│   ├── zadanie-01-encoding/
│   │   ├── README.md
│   │   ├── solve.py
│   │   └── artefakty/
│   ├── zadanie-02-web/
│   └── zadanie-03-pcap/
├── writeups/
└── tools/
```

Dobra organizacja plików jest ważna. Jeśli wszystko ląduje w katalogu `Downloads`, po godzinie pracy trudno odtworzyć, co zostało sprawdzone.

---

## 6. Podstawowe komendy, które trzeba znać

### 6.1. Praca z plikami

```bash
pwd
ls -la
cd katalog
mkdir zadanie-01
cp plik kopia
mv stara_nazwa nowa_nazwa
rm plik
cat plik
less plik
head plik
tail plik
```

### 6.2. Rozpoznawanie plików

```bash
file plik
strings plik
xxd plik | head
hexdump -C plik | head
stat plik
```

### 6.3. Szukanie tekstu

```bash
grep 'flag' plik.txt
grep -i 'flag' plik.txt
grep -R 'flag' .
find . -type f
find . -type f -name '*.txt'
```

### 6.4. Archiwa

```bash
unzip plik.zip
7z x plik.7z
tar -xf plik.tar
tar -xzf plik.tar.gz
```

### 6.5. HTTP i API

```bash
curl http://example.local/
curl -i http://example.local/
curl -X POST http://example.local/login -d 'user=admin&pass=admin'
curl -H 'Authorization: Bearer TOKEN' http://example.local/api
```

### 6.6. Sieć

```bash
ip a
ss -tulpen
ping 8.8.8.8
traceroute example.com
nmap -sV 192.168.1.10
nc -vz 192.168.1.10 80
```

### 6.7. Python

```bash
python3
python3 solve.py
python3 -m http.server 8000
python3 -c 'print("test")'
```

---

## 7. Metodyka rozwiązywania zadania CTF

### 7.1. Schemat ogólny

Każde zadanie warto prowadzić według podobnego schematu:

1. **Opis zadania**  
   Przeczytaj dokładnie tytuł, opis, kategorię i wskazówki.

2. **Materiały**  
   Sprawdź, co otrzymałeś: plik, kod, adres, port, log, PCAP.

3. **Rozpoznanie**  
   Ustal typ pliku, usługę, format danych, protokół lub język.

4. **Hipotezy**  
   Zapisz możliwe kierunki rozwiązania.

5. **Eksperymenty**  
   Testuj hipotezy po kolei.

6. **Automatyzacja**  
   Jeśli coś wymaga wielu prób, napisz skrypt.

7. **Weryfikacja**  
   Sprawdź, czy uzyskany wynik ma format flagi.

8. **Dokumentacja**  
   Zapisz komendy, skrypty i wnioski.

### 7.2. Przykładowe pytania kontrolne

Dla każdego zadania warto zadać sobie pytania:

- Co jest wejściem?
- Co jest oczekiwanym wyjściem?
- Czy flaga ma znany format?
- Jakiego typu jest materiał?
- Czy zadanie ma oczywistą kategorię?
- Czy w opisie jest ukryta wskazówka?
- Czy próbuję rozwiązać właściwy problem?
- Czy moje działania są powtarzalne?
- Czy zapisuję wyniki?
- Czy nie utknąłem zbyt długo na jednej hipotezie?

### 7.3. Kiedy poprosić o pomoc?

W zespole nie należy siedzieć godzinę nad jednym zadaniem bez komunikacji.

Poproś o pomoc, gdy:

- sprawdziłeś kilka hipotez i żadna nie działa,
- nie rozumiesz formatu danych,
- nie wiesz, jakiego narzędzia użyć,
- podejrzewasz, że źle interpretujesz opis,
- masz częściowy wynik, ale nie wiesz, co dalej,
- zadanie wymaga wiedzy z kategorii, której jeszcze nie znasz.

Dobra prośba o pomoc powinna zawierać:

- nazwę zadania,
- kategorię,
- co dostałeś,
- co już sprawdziłeś,
- jakie komendy uruchomiłeś,
- jaki wynik otrzymałeś,
- gdzie dokładnie utknąłeś.

Przykład dobrej komunikacji:

```text
Zadanie: login-panel, kategoria web.
Mam formularz logowania i endpoint /login.
Sprawdziłem admin/admin, komentarze HTML, cookies i localStorage.
W Burpie widzę POST /login z parametrami username i password.
Próba ' OR '1'='1 daje błąd 500.
Podejrzewam SQLi, ale nie wiem, jak obejść filtr apostrofu.
```

To jest znacznie lepsze niż: „Nie działa, pomóż”.

---

## 8. Praca zespołowa w CTF

Dobry zespół CTF potrzebuje nie tylko osób technicznych, ale też organizacji.

Typowe role:

| Rola | Zadania |
|---|---|
| Team Lead | koordynacja, priorytety, decyzje, komunikacja |
| Web | aplikacje webowe, API, Burp, HTTP |
| Crypto | kodowanie, szyfry, hashe, matematyka |
| Forensics | pliki, PCAP, RAM, obrazy dysków, metadane |
| Reverse | analiza binarek, Ghidra, gdb, dekompilacja |
| Pwn | exploit development, pwntools, ROP, debugowanie |
| Network | nmap, PCAP, protokoły, usługi |
| Blue Team | logi, SIEM, alerty, detekcja |
| ICS/OT | protokoły przemysłowe, bezpieczeństwo procesu |
| Dokumentacja | write-upy, repozytorium, notatki |

Jedna osoba może pełnić kilka ról. Ważne jest jednak, aby zespół wiedział, kto nad czym pracuje.

### 8.1. Zasady pracy zespołu

- Każde zadanie ma przypisaną osobę lub parę.
- Nie dublujemy pracy bez potrzeby.
- Dzielimy się częściowymi odkryciami.
- Notujemy komendy i wyniki.
- Po rozwiązaniu od razu robimy krótki write-up.
- Jeśli zadanie blokuje nas zbyt długo, przechodzimy dalej.
- Po zawodach robimy omówienie.

### 8.2. Tablica pracy

Warto prowadzić prostą tablicę:

| Zadanie | Kategoria | Osoba | Status | Notatki |
|---|---|---|---|---|
| hidden-message | forensics | Anna | w toku | znaleziono dane po IEND |
| login-panel | web | Jan | zablokowane | możliwe SQLi |
| xor-secret | crypto | Zespół 2 | rozwiązane | klucz 0x37 |

Statusy mogą być proste:

- nowe,
- w toku,
- zablokowane,
- rozwiązane,
- do opisania,
- opisane.

---

## 9. Write-up, czyli dokumentacja rozwiązania

Write-up to opis rozwiązania zadania. Jest bardzo ważny, bo bez dokumentacji wiedza znika po zakończeniu spotkania.

Minimalny szablon:

```markdown
# Nazwa zadania

## Kategoria
Web / Crypto / Forensics / Reverse / Pwn / OSINT / Network / ICS

## Opis
Krótki opis zadania własnymi słowami.

## Co otrzymaliśmy
Pliki, adresy, porty, fragmenty kodu, logi.

## Analiza
Co sprawdziliśmy i dlaczego.

## Rozwiązanie
Komendy, skrypty, kroki techniczne.

## Flaga
flag{...}

## Wnioski
Czego nauczyło nas zadanie.
```

Dobry write-up powinien być:

- czytelny,
- powtarzalny,
- konkretny,
- uczciwy,
- zrozumiały dla osoby, która nie rozwiązywała zadania.

Nie trzeba pisać długiego raportu. Wystarczy, żeby inny członek koła mógł odtworzyć rozwiązanie.

---

## 10. Etyka i bezpieczeństwo

Umiejętności zdobywane podczas CTF są realne. Dlatego obowiązują jasne zasady.

### 10.1. Zasady obowiązujące w kole

- Ćwiczymy tylko na środowiskach, do których mamy zgodę.
- Nie skanujemy przypadkowych adresów publicznych.
- Nie testujemy infrastruktury uczelni bez formalnej autoryzacji.
- Nie próbujemy logować się na cudze konta.
- Nie obchodzimy zabezpieczeń usług, które nie są częścią zadania.
- Nie publikujemy flag przed zakończeniem konkursu.
- Nie kopiujemy bezmyślnie write-upów innych zespołów.
- Nie wykorzystujemy narzędzi poza labem bez zgody właściciela systemu.
- Nie nękamy realnych osób w zadaniach OSINT.
- Nie publikujemy danych osobowych.

### 10.2. Granica między labem a realnym światem

W labie można testować podatną aplikację, bo została do tego przygotowana. W realnym świecie ten sam test bez zgody może być naruszeniem prawa lub regulaminu usługi.

Przykład:

- Test SQL Injection w zadaniu CTF: dozwolony.
- Test SQL Injection na przypadkowym sklepie internetowym: niedozwolony.

Zawsze pytamy:

- Czy mam zgodę?
- Czy znam zakres testu?
- Czy wiem, czego nie wolno robić?
- Czy moje działanie może zakłócić usługę?

---

## 11. Wprowadzenie do ICS/OT Defense CTF

### 11.1. Czym jest ICS/OT?

ICS to Industrial Control Systems, czyli systemy sterowania przemysłowego. OT to Operational Technology, czyli technologia operacyjna sterująca procesami fizycznymi.

Przykładowe środowiska:

- energetyka,
- wodociągi,
- przemysł wydobywczy,
- transport,
- automatyka budynkowa,
- produkcja,
- magazyny automatyczne,
- infrastruktura krytyczna.

Typowe elementy:

| Element | Rola |
|---|---|
| PLC | sterownik logiczny sterujący procesem |
| HMI | interfejs operatora |
| SCADA | nadzór i sterowanie procesem |
| Historian | baza danych procesowych |
| Engineering Workstation | stacja inżynierska do konfiguracji urządzeń |
| OPC Server | wymiana danych przemysłowych |
| RTU | zdalna jednostka terminalowa |
| Czujniki | pomiar parametrów procesu |
| Aktuatory | wykonanie działania fizycznego, np. zawór, silnik |
| DMZ przemysłowa | strefa pośrednia między IT i OT |

### 11.2. Różnica między IT a OT

W klasycznym IT często mówi się o triadzie CIA:

1. Confidentiality — poufność,
2. Integrity — integralność,
3. Availability — dostępność.

W OT priorytety często wyglądają inaczej:

1. bezpieczeństwo ludzi i procesu,
2. dostępność,
3. integralność,
4. poufność.

To oznacza, że w środowisku przemysłowym nie wolno działać impulsywnie. Restart systemu, agresywne skanowanie albo odcięcie hosta może zatrzymać proces lub pozbawić operatora widoczności.

### 11.3. Typowe protokoły przemysłowe

Na poziomie wstępnym warto znać nazwy i ogólne zastosowanie:

- Modbus TCP,
- OPC UA,
- DNP3,
- S7comm,
- Profinet,
- EtherNet/IP,
- MQTT,
- SNMP,
- Syslog.

Na początku nie trzeba znać szczegółów każdego protokołu. Trzeba umieć:

- rozpoznać protokół w ruchu sieciowym,
- ustalić, które hosty się komunikują,
- odróżnić odczyt od zapisu,
- wskazać nietypową komunikację,
- ocenić wpływ zdarzenia na proces.

### 11.4. Jak wygląda zadanie ICS/OT Defense?

Przykładowy scenariusz:

> Zakład przemysłowy posiada HMI, sterownik PLC, historian i stację inżynierską. W logach pojawiły się nietypowe próby logowania, a w ruchu sieciowym widać zapis do rejestru sterownika. Zadaniem zespołu jest ustalić, kto wykonał działanie, jaki parametr został zmieniony, czy miało to wpływ na proces oraz jak należy zareagować.

W takim zadaniu należy odpowiedzieć na pytania:

- Jakie hosty występują w środowisku?
- Który host jest HMI?
- Który host jest PLC?
- Czy wystąpiło logowanie administracyjne?
- Czy ktoś wykonał zapis do rejestru?
- Jaki parametr procesu został zmieniony?
- Czy zdarzenie jest incydentem?
- Jaki jest wpływ na bezpieczeństwo procesu?
- Jaka reakcja będzie bezpieczna?
- Jak udokumentować incydent?

### 11.5. Bezpieczna reakcja w OT

Prosta procedura:

1. Wykryj zdarzenie.
2. Potwierdź, czy to incydent.
3. Oceń wpływ na proces.
4. Skonsultuj działania z osobą odpowiedzialną za proces.
5. Izoluj ostrożnie, jeśli jest to konieczne.
6. Zabezpiecz dowody.
7. Przywróć poprawne działanie.
8. Udokumentuj zdarzenie.
9. Wyciągnij wnioski.

W OT nie wolno przyjmować założenia, że „najbezpieczniej odciąć wszystko”. Czasem odcięcie może pogorszyć sytuację.

---


## Jak uczyć się dalej?

### Pierwsze 4 tygodnie

Cel: podstawy pracy w środowisku CTF.

Zakres:

- Linux CLI,
- Python,
- podstawy HTTP,
- podstawy sieci,
- CyberChef,
- Wireshark,
- podstawy web security,
- proste zadania forensics.

Efekt po 4 tygodniach:

- umiesz rozwiązać proste zadania encoding,
- umiesz znaleźć flagę w pliku tekstowym,
- umiesz analizować prosty PCAP,
- umiesz użyć podstawowych komend Linux,
- umiesz napisać prosty skrypt Python,
- umiesz przygotować prosty write-up.

### Tygodnie 5–8

Cel: wejście w specjalizacje.

Zakres:

- web: SQLi, XSS, IDOR, JWT,
- crypto: XOR, hashe, RSA basics,
- forensics: metadane, archiwa, steganografia,
- reverse: strings, Ghidra, gdb,
- sieci: Wireshark, DNS, HTTP, FTP,
- blue team: logi, alerty, timeline.

Efekt po 8 tygodniach:

- potrafisz wybrać kategorię, która Cię interesuje,
- rozumiesz typowe zadania początkujące i średnie,
- umiesz pracować w zespole,
- umiesz dokumentować rozwiązania.

### Tygodnie 9–12

Cel: przygotowanie do udziału w pierwszym CTF jako zespół.

Zakres:

- trening zespołowy,
- symulacja zawodów,
- podział ról,
- praca na czas,
- write-upy,
- omówienie po zawodach,
- podstawy ICS/OT Defense.

Efekt po 12 tygodniach:

- zespół jest gotowy do startu w prostym CTF online,
- każdy zna swoją preferowaną rolę,
- grupa ma wspólne repozytorium wiedzy,
- umiemy analizować własne błędy po zawodach.

---

## Minimalna lista narzędzi według kategorii

### Ogólne

- Linux,
- Bash,
- Python 3,
- Git,
- Docker,
- VS Code,
- CyberChef.

### Web

- Burp Suite Community,
- OWASP ZAP,
- DevTools,
- curl,
- ffuf,
- gobuster,
- sqlmap w legalnym labie.

### Crypto

- CyberChef,
- Python,
- SageMath,
- hashid,
- John the Ripper,
- hashcat.

### Forensics

- file,
- strings,
- xxd,
- exiftool,
- binwalk,
- foremost,
- steghide,
- zsteg,
- Wireshark,
- Volatility,
- Autopsy.

### Reverse

- Ghidra,
- IDA Free,
- Cutter,
- radare2,
- gdb,
- pwndbg,
- strace,
- ltrace,
- objdump,
- readelf.

### Pwn

- gdb,
- pwndbg,
- pwntools,
- checksec,
- ROPgadget,
- one_gadget,
- Docker.

### Network

- nmap,
- tcpdump,
- Wireshark,
- tshark,
- Zeek,
- NetworkMiner,
- netcat.

### Blue Team / ICS

- Wireshark,
- Zeek,
- Suricata,
- Wazuh,
- ELK/OpenSearch,
- Grafana,
- MITRE ATT&CK,
- MITRE ATT&CK for ICS.

---

## Przydatne platformy i źródła

### Platformy CTF

- CTFtime: https://ctftime.org/event/list/
- CyLab Security Academy / picoCTF: https://learn.cylabacademy.org/
- picoCTF: https://www.picoctf.org/
- Hack The Box CTF: https://ctf.hackthebox.com/events/upcoming
- Google CTF: https://capturetheflag.withgoogle.com/

### Web security

- PortSwigger Web Security Academy: https://portswigger.net/web-security
- PortSwigger Web Security Academy — All Labs: https://portswigger.net/web-security/all-labs
- PortSwigger Learning Paths: https://portswigger.net/web-security/learning-paths
- Burp Suite: https://portswigger.net/burp

### Narzędzia

- CyberChef: https://github.com/gchq/CyberChef
- Wireshark: https://www.wireshark.org/docs/
- Nmap: https://nmap.org/book/
- Ghidra: https://github.com/NationalSecurityAgency/ghidra
- pwntools: https://docs.pwntools.com/en/stable/
- John the Ripper: https://www.openwall.com/john/
- hashcat: https://hashcat.net/hashcat/
- Volatility 3: https://github.com/volatilityfoundation/volatility3

### ICS/OT

- MITRE ATT&CK for ICS: https://attack.mitre.org/matrices/ics/
- MITRE ATT&CK ICS Techniques: https://attack.mitre.org/techniques/ics/
- NIST SP 800-82 Rev. 3: https://csrc.nist.gov/pubs/sp/800/82/r3/final
- CISA ICS Training: https://www.cisa.gov/resources-tools/training/ics-virtual-learning-portal
- ISA/IEC 62443: https://www.isa.org/standards-and-publications/isa-standards/isa-iec-62443-series-of-standards

---

## Słownik podstawowych pojęć

**Flag** — ukryty ciąg znaków potwierdzający rozwiązanie zadania.

**Challenge** — pojedyncze zadanie CTF.

**Write-up** — opis rozwiązania zadania.

**Payload** — dane wejściowe przygotowane w celu wywołania określonego zachowania aplikacji lub programu.

**Exploit** — sposób wykorzystania podatności.

**Vulnerability** — podatność, czyli błąd umożliwiający naruszenie bezpieczeństwa.

**Recon** — rozpoznanie celu lub materiałów.

**Enumeration** — szczegółowe wyliczanie zasobów, usług, użytkowników, endpointów lub parametrów.

**PCAP** — plik zawierający przechwycony ruch sieciowy.

**Hash** — wynik jednokierunkowej funkcji skrótu.

**Encoding** — kodowanie, czyli zmiana reprezentacji danych.

**Encryption** — szyfrowanie z użyciem klucza.

**Reverse engineering** — analiza działania programu bez pełnego kodu źródłowego.

**Pwn** — kategoria związana z wykorzystaniem błędów binarnych.

**OSINT** — pozyskiwanie i analiza informacji ze źródeł jawnych.

**HMI** — Human-Machine Interface, interfejs operatora w systemie przemysłowym.

**PLC** — Programmable Logic Controller, sterownik przemysłowy.

**SCADA** — system nadzoru i sterowania procesem.

**Historian** — baza danych procesowych w środowisku przemysłowym.

**DMZ** — strefa pośrednia między sieciami o różnym poziomie zaufania.

---

## Najczęstsze błędy początkujących

1. Uruchamianie losowych narzędzi bez planu.
2. Brak notatek.
3. Praca nad jednym zadaniem zbyt długo bez konsultacji.
4. Ignorowanie opisu zadania.
5. Zakładanie, że rozszerzenie pliku mówi prawdę.
6. Mylenie kodowania z szyfrowaniem.
7. Brak podstaw Linuxa.
8. Nieczytanie komunikatów błędów.
9. Kopiowanie payloadów bez rozumienia.
10. Nieprzygotowane środowisko pracy.
11. Brak write-upów.
12. Zbyt szybkie przyjmowanie hipotez w OSINT.
13. Agresywne skanowanie tam, gdzie może ono zaszkodzić.
14. Brak komunikacji w zespole.
15. Traktowanie CTF jako celu samego w sobie, a nie jako treningu.

---

## Checklista przed pierwszym CTF

### Środowisko

- [ ] Mam działający Linux, WSL2 albo maszynę wirtualną.
- [ ] Mam Python 3.
- [ ] Mam Git.
- [ ] Mam Docker.
- [ ] Mam Burp Suite Community.
- [ ] Mam Wireshark.
- [ ] Mam CyberChef.
- [ ] Mam edytor kodu.
- [ ] Mam katalog roboczy na zadania.

### Umiejętności podstawowe

- [ ] Umiem użyć `file`.
- [ ] Umiem użyć `strings`.
- [ ] Umiem użyć `grep`.
- [ ] Umiem uruchomić prosty skrypt Python.
- [ ] Umiem wykonać żądanie `curl`.
- [ ] Umiem otworzyć PCAP w Wiresharku.
- [ ] Umiem napisać prosty write-up.

### Organizacja

- [ ] Wiem, gdzie zapisuję notatki.
- [ ] Wiem, kto jest w moim zespole.
- [ ] Wiem, jak komunikujemy status zadań.
- [ ] Wiem, kiedy prosić o pomoc.
- [ ] Wiem, jakie są zasady etyczne.

---

## Najważniejsze wnioski

1. CTF to praktyczny trening cyberbezpieczeństwa.
2. Flaga jest tylko potwierdzeniem rozwiązania, nie głównym celem nauki.
3. Najpierw rozumiemy problem, potem wybieramy narzędzie.
4. Dobre notatki są równie ważne jak samo rozwiązanie.
5. Nie każdy musi znać wszystkie kategorie.
6. Skuteczny zespół potrzebuje specjalizacji i koordynacji.
7. Zadania webowe są dobrym punktem startu.
8. Forensics i network rozwijają umiejętności analizy incydentów.
9. Crypto w CTF-ach często dotyczy błędów implementacyjnych, nie łamania silnej matematyki.
10. Reverse i pwn wymagają cierpliwości oraz podstaw niskopoziomowych.
11. OSINT wymaga weryfikacji, ostrożności i etyki.
12. W ICS/OT najważniejsze jest bezpieczeństwo procesu i dostępność.
13. Każde rozwiązane zadanie powinno zakończyć się write-upem.
14. Działamy wyłącznie legalnie i w uzgodnionych środowiskach.
15. Najlepszym sposobem nauki jest regularna praktyka.

---

## Zadanie domowe po spotkaniu wprowadzającym

Do wykonania przed kolejnym spotkaniem:

1. Przygotuj środowisko Linux/WSL/VM.
2. Zainstaluj Python 3, Git, Docker, Wireshark i Burp Suite Community.
3. Załóż konto na jednej platformie treningowej, np. CyLab Security Academy/picoCTF albo PortSwigger Web Security Academy.
4. Rozwiąż minimum trzy proste zadania:
   - jedno encoding/general skills,
   - jedno web,
   - jedno forensics albo network.
5. Do każdego zadania przygotuj krótki write-up w Markdown.
6. Przynieś na kolejne spotkanie jedno pytanie techniczne, które pojawiło się podczas pracy.

---

## Propozycja krótkiego write-upu po zadaniu domowym

```markdown
# Tytuł zadania

## Platforma
Nazwa platformy.

## Kategoria
Np. Web / Crypto / Forensics.

## Poziom trudności
Łatwe / średnie / trudne.

## Opis problemu
Krótko: co było celem zadania?

## Analiza
Jakie kroki wykonałem?

## Komendy / kod
```bash
# tutaj komendy
```

## Rozwiązanie
Jak uzyskałem flagę?

## Flaga
flag{...}

## Wnioski
Czego się nauczyłem?
```



