# Hardening systemów Windows i Active Directory

(C)2026 Cyberprzem

Dokument opisuje hardening systemów Windows, Windows Server, popularnych usług Microsoft oraz Active Directory.

Hardening Windows i Active Directory nie powinien być rozumiany jako jednorazowe „włączenie wszystkich zabezpieczeń”. W praktyce jest to proces: inwentaryzacja, analiza ryzyka, tryb audytu, pilotaż, wdrożenie, monitoring i obsługa wyjątków.

---

## Spis treści

1. [Cel hardeningu Windows](#1-cel-hardeningu-windows)
2. [Założenia i model wdrożenia](#2-założenia-i-model-wdrożenia)
3. [Podstawowy rekonesans systemu Windows](#3-podstawowy-rekonesans-systemu-windows)
4. [Aktualizacje i zarządzanie poprawkami](#4-aktualizacje-i-zarządzanie-poprawkami)
5. [Minimalizacja ról, funkcji i usług](#5-minimalizacja-ról-funkcji-i-usług)
6. [Konta lokalne i lokalni administratorzy](#6-konta-lokalne-i-lokalni-administratorzy)
7. [Windows LAPS](#7-windows-laps)
8. [Polityki haseł i blokad kont](#8-polityki-haseł-i-blokad-kont)
9. [Ochrona poświadczeń](#9-ochrona-poświadczeń)
10. [Microsoft Defender, EDR i ASR](#10-microsoft-defender-edr-i-asr)
11. [Firewall Windows](#11-firewall-windows)
12. [Hardening RDP](#12-hardening-rdp)
13. [Hardening WinRM i PowerShell Remoting](#13-hardening-winrm-i-powershell-remoting)
14. [Hardening PowerShell](#14-hardening-powershell)
15. [Application Control: AppLocker i WDAC](#15-application-control-applocker-i-wdac)
16. [Hardening SMB](#16-hardening-smb)
17. [Hardening NTLM](#17-hardening-ntlm)
18. [Audyt i logowanie zdarzeń](#18-audyt-i-logowanie-zdarzeń)
19. [Sysmon i centralizacja logów](#19-sysmon-i-centralizacja-logów)
20. [BitLocker i ochrona danych](#20-bitlocker-i-ochrona-danych)
21. [Hardening IIS](#21-hardening-iis)
22. [Hardening Microsoft SQL Server](#22-hardening-microsoft-sql-server)
23. [Hardening serwerów plików](#23-hardening-serwerów-plików)
24. [Hardening DNS i DHCP na Windows Server](#24-hardening-dns-i-dhcp-na-windows-server)
25. [Hardening Active Directory](#25-hardening-active-directory)
26. [Model Tier 0 / Tier 1 / Tier 2 i Enterprise Access Model](#26-model-tier-0--tier-1--tier-2-i-enterprise-access-model)
27. [Kontrolery domeny](#27-kontrolery-domeny)
28. [Grupy uprzywilejowane w AD](#28-grupy-uprzywilejowane-w-ad)
29. [Konta administracyjne i PAW](#29-konta-administracyjne-i-paw)
30. [Konta serwisowe i gMSA](#30-konta-serwisowe-i-gmsa)
31. [Kerberos hardening](#31-kerberos-hardening)
32. [LDAP signing i channel binding](#32-ldap-signing-i-channel-binding)
33. [GPO hardening](#33-gpo-hardening)
34. [Delegacje w AD](#34-delegacje-w-ad)
35. [AdminSDHolder, adminCount i chronione obiekty](#35-adminsdholder-admincount-i-chronione-obiekty)
36. [DCSync i uprawnienia replikacji](#36-dcsync-i-uprawnienia-replikacji)
37. [AD CS jako Tier 0](#37-ad-cs-jako-tier-0)
38. [Backup i odtwarzanie AD](#38-backup-i-odtwarzanie-ad)
39. [Checklisty końcowe](#39-checklisty-końcowe)
40. [Przykładowe laboratorium CTF](#40-przykładowe-laboratorium-ctf)
41. [Źródła i punkty odniesienia](#41-źródła-i-punkty-odniesienia)

---

# 1. Cel hardeningu Windows

Hardening systemów Windows polega na zmniejszeniu powierzchni ataku, ograniczeniu skutków kompromitacji oraz poprawie możliwości wykrywania incydentów. W środowisku firmowym dotyczy to zarówno stacji roboczych, serwerów członkowskich, kontrolerów domeny, jak i usług takich jak IIS, SQL Server, SMB, DNS, DHCP, RDP, WinRM oraz Active Directory.

Najważniejsze cele:

```text
1. Ograniczyć liczbę zbędnych usług i otwartych portów.
2. Ograniczyć lokalnych administratorów.
3. Chronić poświadczenia przed kradzieżą.
4. Zmniejszyć ryzyko ruchu lateralnego.
5. Zabezpieczyć dostęp zdalny.
6. Wymusić kontrolowane uruchamianie aplikacji i skryptów.
7. Włączyć skuteczny audyt.
8. Centralizować logi.
9. Utwardzić Active Directory jako krytyczną warstwę tożsamości.
10. Zachować funkcjonalność systemów biznesowych.
```

W środowisku domenowym Active Directory jest zwykle najważniejszym elementem bezpieczeństwa. Przejęcie AD często oznacza przejęcie całego środowiska Windows.

---

# 2. Założenia i model wdrożenia

Nie należy wdrażać wszystkich ustawień hardeningowych jednocześnie na całą organizację. Windows i AD często obsługują aplikacje legacy, integracje przemysłowe, systemy finansowe, drukarki, skanery, systemy backupowe i rozwiązania vendorów, które mogą mieć zależności od starszych mechanizmów.

Zalecana kolejność:

```text
1. Inwentaryzacja systemów.
2. Klasyfikacja: stacje robocze, serwery, kontrolery domeny, serwery aplikacyjne, systemy krytyczne.
3. Zebranie aktualnej konfiguracji.
4. Włączenie trybu audytu tam, gdzie to możliwe.
5. Pilotaż na małej grupie.
6. Analiza zdarzeń i wyjątków.
7. Stopniowe wymuszanie ustawień.
8. Monitoring skutków.
9. Dokumentowanie wyjątków.
10. Regularny przegląd konfiguracji.
```

Zła praktyka:

```text
Import gotowego baseline'u i wymuszenie go na całej domenie bez testów.
```

Dobra praktyka:

```text
Baseline jako punkt odniesienia, nie jako bezkrytyczna recepta.
```

---

# 3. Podstawowy rekonesans systemu Windows

## 3.1. Informacje o systemie

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, CsDomain, CsName
systeminfo
whoami /all
hostname
```

## 3.2. Użytkownicy i grupy lokalne

```powershell
Get-LocalUser
Get-LocalGroup
Get-LocalGroupMember -Group "Administrators"
Get-LocalGroupMember -Group "Remote Desktop Users"
```

## 3.3. Usługi

```powershell
Get-Service | Sort-Object Status, DisplayName
Get-Service | Where-Object Status -eq "Running"
```

## 3.4. Porty i połączenia

```powershell
Get-NetTCPConnection | Sort-Object LocalPort
netstat -ano
```

## 3.5. Firewall

```powershell
Get-NetFirewallProfile
Get-NetFirewallRule -Direction Inbound | Where-Object Enabled -eq True |
Select-Object DisplayName, Profile, Direction, Action
```

## 3.6. Defender

```powershell
Get-MpComputerStatus
Get-MpPreference
```

## 3.7. Udziały SMB

```powershell
Get-SmbShare
Get-SmbServerConfiguration
Get-SmbClientConfiguration
```

## 3.8. Zdarzenia bezpieczeństwa

```powershell
Get-WinEvent -LogName Security -MaxEvents 20
```

---

# 4. Aktualizacje i zarządzanie poprawkami

Aktualizacje powinny obejmować:

```text
[ ] Windows i Windows Server.
[ ] Microsoft Defender.
[ ] .NET Framework / .NET.
[ ] Microsoft Edge.
[ ] Microsoft Office.
[ ] SQL Server.
[ ] IIS i komponenty webowe.
[ ] Sterowniki.
[ ] Firmware, BIOS/UEFI.
[ ] Agenty bezpieczeństwa, backupu i monitoringu.
```

Podstawowe komendy:

```powershell
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 20
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber
```

W środowisku zarządzanym używa się zwykle:

```text
- Windows Update for Business,
- WSUS,
- Microsoft Configuration Manager,
- Microsoft Intune,
- Azure Update Manager,
- narzędzi EDR/XDR,
- narzędzi klasy patch management.
```

Dobre praktyki:

```text
[ ] Testuj aktualizacje na grupie pilotażowej.
[ ] Pilnuj restartów po aktualizacjach.
[ ] Monitoruj nieudane aktualizacje.
[ ] Nie ignoruj aktualizacji .NET, SQL Server i Office.
[ ] Dokumentuj wyjątki.
```

---

# 5. Minimalizacja ról, funkcji i usług

Każda dodatkowa rola, funkcja lub usługa zwiększa powierzchnię ataku.

## 5.1. Sprawdzenie ról i funkcji Windows Server

```powershell
Get-WindowsFeature | Where-Object Installed -eq $true
```

## 5.2. Przykładowe funkcje do przeglądu

```text
[ ] SMB 1.0/CIFS.
[ ] Telnet Client.
[ ] TFTP Client.
[ ] Windows PowerShell 2.0 Engine.
[ ] IIS, jeśli niepotrzebny.
[ ] FTP Server.
[ ] WebDAV.
[ ] Print and Document Services.
[ ] Remote Differential Compression.
[ ] Niepotrzebne komponenty Hyper-V.
```

## 5.3. Wyłączenie SMBv1

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
```

## 5.4. Usługi do przeglądu

```powershell
Get-Service | Where-Object Status -eq "Running" |
Sort-Object DisplayName |
Select-Object DisplayName, Name, StartType, Status
```

Nie należy wyłączać usług bez zrozumienia zależności. Przykładowo, wyłączenie usługi DNS Client, Netlogon, Workstation, Server, Windows Event Log czy RPC może poważnie uszkodzić system lub domenę.

---

# 6. Konta lokalne i lokalni administratorzy

Lokalni administratorzy są jedną z najważniejszych powierzchni ataku w środowisku Windows. Jeśli zwykły użytkownik ma lokalnego administratora, malware lub atakujący po przejęciu jego sesji zyskuje znacznie większe możliwości.

## 6.1. Sprawdzenie lokalnych administratorów

```powershell
Get-LocalGroupMember -Group "Administrators"
```

## 6.2. Dobre praktyki

```text
[ ] Zwykli użytkownicy nie są lokalnymi administratorami.
[ ] Konta lokalne są ograniczone.
[ ] Hasła lokalnych administratorów są unikalne per urządzenie.
[ ] Hasła są rotowane automatycznie.
[ ] Dostęp do haseł lokalnych adminów jest audytowany.
[ ] Lokalni admini nie są używani do codziennej pracy.
```

## 6.3. Częsty błąd

```text
To samo hasło lokalnego Administratora na wszystkich komputerach.
```

Konsekwencja: przejęcie jednej stacji umożliwia ruch lateralny na inne systemy.

---

# 7. Windows LAPS

Windows LAPS służy do zarządzania hasłami lokalnych kont administratora na urządzeniach dołączonych do Active Directory albo Microsoft Entra ID. Pozwala na automatyczną rotację i kontrolowany odczyt hasła.

## 7.1. Dlaczego LAPS jest ważny

Bez LAPS organizacje często używają:

```text
- jednego hasła lokalnego admina dla wielu komputerów,
- haseł zapisanych w dokumentacji,
- haseł znanych wielu osobom,
- haseł nierotowanych latami.
```

LAPS ogranicza skutki kompromitacji jednego urządzenia.

## 7.2. Elementy wdrożenia

```text
[ ] Wybór modelu: AD DS lub Microsoft Entra ID.
[ ] Przygotowanie polityk.
[ ] Określenie konta lokalnego do zarządzania.
[ ] Ograniczenie, kto może odczytywać hasła.
[ ] Audyt odczytu haseł.
[ ] Test rotacji hasła.
[ ] Procedura awaryjnego dostępu.
```

## 7.3. Kontrola w środowisku AD

Przykładowe polecenia zależą od konfiguracji, ale wstępnie warto sprawdzić:

```powershell
Get-Command *Laps*
```

## 7.4. Błędy wdrożeniowe

```text
[ ] Zbyt szerokie uprawnienia do odczytu haseł.
[ ] Brak audytu odczytu.
[ ] Brak testu rotacji.
[ ] Nieobjęcie stacji roboczych.
[ ] Nieobjęcie serwerów członkowskich tam, gdzie jest to zasadne.
```

---

# 8. Polityki haseł i blokad kont

W środowisku domenowym polityki haseł są zarządzane centralnie. Dla wybranych grup można stosować Fine-Grained Password Policies.

## 8.1. Sprawdzenie polityki domenowej

```powershell
Get-ADDefaultDomainPasswordPolicy
```

## 8.2. Elementy polityki

```text
[ ] Minimalna długość hasła.
[ ] Historia haseł.
[ ] Minimalny i maksymalny wiek hasła.
[ ] Blokada konta po wielu błędnych próbach.
[ ] Czas blokady.
[ ] Próg resetowania licznika błędnych prób.
```

## 8.3. Rekomendacje praktyczne

```text
[ ] Preferuj długie hasła.
[ ] Blokuj znane/słabe hasła, jeśli infrastruktura to umożliwia.
[ ] Włącz MFA tam, gdzie to możliwe.
[ ] Nie wymuszaj zbyt częstej zmiany haseł bez powodu.
[ ] Oddziel polityki dla kont zwykłych, administracyjnych i serwisowych.
```

---

# 9. Ochrona poświadczeń

Ataki na Windows bardzo często skupiają się na poświadczeniach: hashach NTLM, biletach Kerberos, tokenach, sesjach RDP i danych w pamięci LSASS.

## 9.1. Mechanizmy ochronne

```text
[ ] Credential Guard.
[ ] LSASS jako proces chroniony.
[ ] Wyłączenie WDigest.
[ ] Protected Users.
[ ] Zakaz logowania administratorów domeny na zwykłe stacje.
[ ] Oddzielne konta administracyjne.
[ ] PAW — Privileged Access Workstations.
[ ] Ograniczenie RDP i WinRM.
```

## 9.2. Sprawdzenie Credential Guard / VBS

```powershell
Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
```

## 9.3. WDigest

WDigest historycznie mógł powodować przechowywanie haseł w postaci możliwej do odzyskania z pamięci.

Sprawdzenie ustawienia:

```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name UseLogonCredential -ErrorAction SilentlyContinue
```

Ustawienie powinno uniemożliwiać przechowywanie haseł w pamięci:

```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
-Name UseLogonCredential -Value 0 -PropertyType DWord -Force
```

## 9.4. Zasada

```text
Nie pytaj tylko: „czy hasło jest silne?”.
Pytaj także: „gdzie to konto się logowało i gdzie zostały jego poświadczenia?”.
```

---

# 10. Microsoft Defender, EDR i ASR

Microsoft Defender Antivirus i Microsoft Defender for Endpoint mogą pełnić rolę zarówno antymalware, jak i elementu redukcji powierzchni ataku.

## 10.1. Kontrola statusu

```powershell
Get-MpComputerStatus
Get-MpPreference
```

## 10.2. Elementy do sprawdzenia

```text
[ ] Real-time protection.
[ ] Cloud-delivered protection.
[ ] Automatic sample submission.
[ ] Tamper Protection.
[ ] EDR in block mode.
[ ] Network Protection.
[ ] Controlled Folder Access.
[ ] Exploit Protection.
[ ] Attack Surface Reduction rules.
```

## 10.3. Wykluczenia Defendera

Sprawdzenie:

```powershell
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
Get-MpPreference | Select-Object -ExpandProperty ExclusionProcess
Get-MpPreference | Select-Object -ExpandProperty ExclusionExtension
```

Podejrzane wykluczenia:

```text
C:\Users\Public\
C:\Temp\
C:\Windows\Tasks\
C:\ProgramData\
powershell.exe
cmd.exe
wscript.exe
cscript.exe
rundll32.exe
```

Nie każde wykluczenie jest złośliwe, ale każde powinno mieć uzasadnienie.

## 10.4. ASR — Attack Surface Reduction

Reguły ASR ograniczają zachowania często wykorzystywane przez malware, np. uruchamianie obfuskowanych skryptów, tworzenie procesów przez Office, kradzież poświadczeń z LSASS czy nadużywanie PSExec/WMI.

Dobre podejście:

```text
1. Włącz tryb audytu.
2. Zbierz zdarzenia.
3. Zidentyfikuj aplikacje konfliktujące.
4. Ogranicz wyjątki.
5. Wymuś reguły na grupie pilotażowej.
6. Stopniowo rozszerz wdrożenie.
```

---

# 11. Firewall Windows

Firewall powinien być aktywny dla profili Domain, Private i Public. W środowisku domenowym reguły powinny być zarządzane przez GPO lub Intune.

## 11.1. Sprawdzenie profili

```powershell
Get-NetFirewallProfile
```

## 11.2. Włączenie profili

```powershell
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True
```

## 11.3. Reguły przychodzące

```powershell
Get-NetFirewallRule -Direction Inbound | Where-Object Enabled -eq True |
Select-Object DisplayName, Profile, Action, Enabled
```

## 11.4. Zasady

```text
[ ] Domyślnie blokuj ruch przychodzący.
[ ] Dopuszczaj tylko potrzebne porty.
[ ] Ograniczaj reguły po adresach źródłowych.
[ ] Stacje, serwery i kontrolery domeny powinny mieć różne polityki.
[ ] Nie stosuj reguł Any/Any bez bardzo dobrego powodu.
```

---

# 12. Hardening RDP

RDP powinien być traktowany jako kanał administracyjny wysokiego ryzyka.

## 12.1. Zasady

```text
[ ] RDP tylko przez VPN, jump host albo PAW.
[ ] Network Level Authentication włączone.
[ ] Dostęp tylko dla konkretnych grup.
[ ] Brak Domain Users w Remote Desktop Users.
[ ] Brak Domain Adminów na zwykłych serwerach i stacjach.
[ ] MFA dla zdalnego dostępu, jeśli infrastruktura to wspiera.
[ ] Ograniczenie przekierowania dysków, schowka i drukarek.
[ ] Logowanie zdarzeń RDP.
```

## 12.2. Kontrola grupy RDP

```powershell
Get-LocalGroupMember -Group "Remote Desktop Users"
```

## 12.3. Zdarzenia RDP

Przydatne logi:

```text
Security.evtx:
- 4624 — udane logowanie
- 4625 — nieudane logowanie
- 4778 — ponowne połączenie sesji RDP
- 4779 — rozłączenie sesji RDP

Microsoft-Windows-TerminalServices-LocalSessionManager/Operational
Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational
```

---

# 13. Hardening WinRM i PowerShell Remoting

WinRM jest przydatny administracyjnie, ale może być nadużywany do ruchu lateralnego.

## 13.1. Sprawdzenie

```powershell
Get-Service WinRM
winrm enumerate winrm/config/listener
```

## 13.2. Zasady

```text
[ ] WinRM tylko tam, gdzie potrzebny.
[ ] Dostęp ograniczony firewallem.
[ ] Dostęp tylko dla uprawnionych grup.
[ ] Preferuj HTTPS w scenariuszach wymagających dodatkowej ochrony.
[ ] Loguj użycie PowerShell Remoting.
[ ] Rozważ JEA — Just Enough Administration.
```

## 13.3. Częsty błąd

```text
WinRM dostępny szeroko z całej sieci użytkowników, bez segmentacji i monitoringu.
```

---

# 14. Hardening PowerShell

Nie należy „wyłączać PowerShella”, bo zwykle jest potrzebny administracyjnie. Należy go kontrolować i logować.

## 14.1. Sprawdzenie wersji

```powershell
$PSVersionTable
```

## 14.2. Wyłączenie PowerShell 2.0

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart
```

## 14.3. Logowanie PowerShell

Warto włączyć:

```text
[ ] Script Block Logging.
[ ] Module Logging.
[ ] PowerShell Transcription.
[ ] Process Creation Logging.
[ ] AMSI.
```

## 14.4. Przykładowe ścieżki GPO

```text
Computer Configuration →
Administrative Templates →
Windows Components →
Windows PowerShell
```

Ustawienia:

```text
- Turn on PowerShell Script Block Logging.
- Turn on PowerShell Transcription.
- Turn on Module Logging.
```

## 14.5. Czego szukać w logach

```text
- EncodedCommand.
- DownloadString.
- Invoke-Expression.
- Add-MpPreference.
- Wyłączanie Defendera.
- Uruchamianie narzędzi z C:\Users\Public lub C:\Temp.
```

---

# 15. Application Control: AppLocker i WDAC

Kontrola aplikacji ogranicza uruchamianie nieautoryzowanych plików EXE, MSI, skryptów i bibliotek.

## 15.1. Typowe ryzykowne lokalizacje

```text
C:\Users\*\Downloads\
C:\Users\*\AppData\
C:\Users\Public\
C:\Temp\
C:\Windows\Temp\
```

## 15.2. Zalecany proces

```text
1. Tryb audytu.
2. Zbieranie zdarzeń.
3. Budowa reguł.
4. Pilotaż.
5. Wymuszenie.
6. Obsługa wyjątków.
```

## 15.3. AppLocker

AppLocker jest prostszy do wdrożenia, ale mniej odporny niż WDAC w scenariuszach wysokiego bezpieczeństwa.

## 15.4. WDAC

Windows Defender Application Control jest silniejszym mechanizmem kontroli kodu. Wymaga jednak większej dojrzałości operacyjnej.

Nie należy wdrażać WDAC od razu w trybie blokowania na całej organizacji.

---

# 16. Hardening SMB

SMB jest krytyczne w Windows: obsługuje udziały plikowe, SYSVOL, NETLOGON i wiele operacji administracyjnych.

## 16.1. Sprawdzenie konfiguracji

```powershell
Get-SmbServerConfiguration
Get-SmbClientConfiguration
```

## 16.2. Wyłączenie SMBv1

```powershell
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
```

## 16.3. SMB signing

Na kontrolerach domeny podpisywanie SMB powinno być wymagane. W nowszych wersjach Windows Microsoft wzmacnia domyślne ustawienia podpisywania SMB.

Kontrola:

```powershell
Get-SmbServerConfiguration | Select-Object EnableSecuritySignature, RequireSecuritySignature
Get-SmbClientConfiguration | Select-Object EnableSecuritySignature, RequireSecuritySignature
```

## 16.4. Udziały SMB

```powershell
Get-SmbShare
Get-SmbShareAccess -Name "NazwaUdzialu"
```

## 16.5. Dobre praktyki

```text
[ ] SMBv1 wyłączone.
[ ] SMB signing włączone lub wymagane zgodnie z rolą systemu.
[ ] Brak dostępu gościa.
[ ] Brak Everyone: Full Control bez uzasadnienia.
[ ] Dostęp do udziałów ograniczony.
[ ] Audyt dostępu do udziałów wrażliwych.
[ ] SMB nie jest wystawiane do Internetu.
```

---

# 17. Hardening NTLM

NTLM jest mechanizmem legacy. Celem powinno być ograniczanie NTLM i przechodzenie na Kerberos/Negotiate, ale nie należy wyłączać NTLM bez audytu.

## 17.1. Proces

```text
1. Włącz audyt NTLM.
2. Zidentyfikuj aplikacje, serwery i urządzenia używające NTLM.
3. Przenieś integracje na Kerberos/Negotiate.
4. Wyłącz NTLMv1.
5. Ogranicz NTLM dla wybranych systemów.
6. Monitoruj skutki.
```

## 17.2. Dlaczego nie od razu blokować?

Z NTLM mogą korzystać:

```text
- starsze aplikacje webowe,
- stare systemy NAS,
- drukarki i skanery,
- systemy przemysłowe,
- integracje vendorów,
- stare aplikacje domenowe,
- niestandardowe usługi.
```

Nagłe wyłączenie NTLM może zatrzymać procesy biznesowe.

---

# 18. Audyt i logowanie zdarzeń

Audyt Windows powinien być centralnie zarządzany przez GPO.

## 18.1. Kluczowe kategorie

```text
[ ] Account Logon.
[ ] Account Management.
[ ] Logon/Logoff.
[ ] Object Access.
[ ] Policy Change.
[ ] Privilege Use.
[ ] Process Creation.
[ ] Directory Service Access.
[ ] Kerberos Authentication Service.
[ ] Kerberos Service Ticket Operations.
```

## 18.2. Przydatne Event ID

```text
4624 — udane logowanie
4625 — nieudane logowanie
4634 — wylogowanie
4648 — logowanie z jawnymi poświadczeniami
4672 — specjalne uprawnienia przypisane do nowego logowania
4688 — utworzenie procesu
4719 — zmiana polityki audytu
4720 — utworzenie konta użytkownika
4722 — włączenie konta użytkownika
4726 — usunięcie konta użytkownika
4728 — dodanie członka do grupy globalnej
4732 — dodanie członka do grupy lokalnej
4738 — zmiana konta użytkownika
4740 — blokada konta
4768 — żądanie biletu TGT Kerberos
4769 — żądanie biletu usługi Kerberos
4771 — Kerberos pre-authentication failed
4776 — uwierzytelnienie NTLM
1102 — wyczyszczenie logu bezpieczeństwa
```

## 18.3. Process Creation z linią poleceń

Warto włączyć logowanie tworzenia procesów wraz z linią poleceń. Pozwala to wykrywać nadużycia PowerShell, cmd, rundll32, regsvr32, mshta, wscript i narzędzi administracyjnych.

---

# 19. Sysmon i centralizacja logów

Sysmon dostarcza bardziej szczegółowe zdarzenia niż standardowy Windows Event Log.

## 19.1. Co daje Sysmon

```text
[ ] Tworzenie procesów.
[ ] Połączenia sieciowe.
[ ] Tworzenie plików.
[ ] Zmiany rejestru.
[ ] Ładowanie sterowników.
[ ] Tworzenie zadań WMI.
[ ] Zdarzenia związane z DNS.
```

## 19.2. Centralizacja logów

Logi lokalne są niewystarczające. Atakujący może próbować je czyścić.

Rozwiązania:

```text
- Windows Event Forwarding,
- Microsoft Sentinel,
- Microsoft Defender XDR,
- Wazuh,
- Splunk,
- Elastic,
- QRadar,
- Graylog,
- inne SIEM.
```

## 19.3. Dobra praktyka

```text
Logi z kontrolerów domeny, serwerów krytycznych i PAW powinny trafiać centralnie.
```

---

# 20. BitLocker i ochrona danych

BitLocker chroni dane w przypadku kradzieży lub utraty urządzenia.

## 20.1. Zastosowanie

```text
[ ] Laptopy.
[ ] Stacje robocze.
[ ] Serwery w lokalizacjach o podwyższonym ryzyku fizycznym.
[ ] Nośniki zewnętrzne — BitLocker To Go.
```

## 20.2. Kontrola

```powershell
manage-bde -status
Get-BitLockerVolume
```

## 20.3. Dobre praktyki

```text
[ ] Klucze odzyskiwania przechowywane centralnie.
[ ] TPM używany tam, gdzie możliwe.
[ ] Procedura odzyskiwania klucza.
[ ] Audyt odczytu kluczy odzyskiwania.
```

---

# 21. Hardening IIS

IIS powinien być utwardzany z uwzględnieniem ról, modułów, Application Pool, .NET, TLS, logów i uprawnień katalogów.

## 21.1. Sprawdzenie komponentów IIS

```powershell
Get-WindowsFeature Web-*
```

## 21.2. Zasady

```text
[ ] Instaluj tylko potrzebne moduły IIS.
[ ] Używaj osobnych Application Pool dla aplikacji.
[ ] Application Pool uruchamiaj na minimalnych uprawnieniach.
[ ] Wyłącz directory browsing.
[ ] Ogranicz metody HTTP.
[ ] Włącz HTTPS.
[ ] Skonfiguruj bezpieczne nagłówki.
[ ] Włącz logi IIS.
[ ] Ogranicz uploady.
[ ] Nie przechowuj sekretów w katalogu publicznym.
[ ] Blokuj wykonywanie skryptów w katalogach upload.
```

## 21.3. Typowe błędy

```text
[ ] Aplikacja działa jako konto z nadmiernymi uprawnieniami.
[ ] Konto aplikacyjne ma dostęp do zbyt wielu zasobów.
[ ] Web.config zawiera sekrety w postaci jawnej.
[ ] Directory browsing jest włączone.
[ ] Upload pozwala wykonywać pliki.
[ ] Brak separacji aplikacji w osobnych pulach.
```

## 21.4. Pliki i katalogi

```text
Kod aplikacji:
- odczyt dla konta aplikacji,
- zapis tylko tam, gdzie konieczny.

Katalog upload:
- zapis kontrolowany,
- brak wykonywania skryptów,
- walidacja rozszerzeń i MIME,
- skanowanie antymalware.
```

---

# 22. Hardening Microsoft SQL Server

SQL Server wymaga hardeningu na poziomie systemu Windows, instancji SQL, kont usług, sieci i backupów.

## 22.1. Obszary

```text
[ ] Aktualizacje SQL Server.
[ ] Minimalne uprawnienia kont usług.
[ ] Brak aplikacji działających jako sysadmin.
[ ] Preferowanie Windows Authentication.
[ ] Silne hasła dla kont SQL, jeśli Mixed Mode jest konieczny.
[ ] Ograniczenie portu SQL firewallem.
[ ] Wyłączenie nieużywanych funkcji.
[ ] Audyt logowań i zmian uprawnień.
[ ] Szyfrowanie połączeń.
[ ] Backupy szyfrowane i testowane.
```

## 22.2. Typowe błędy

```text
[ ] Konto aplikacji ma rolę sysadmin.
[ ] Konto sa ma słabe hasło.
[ ] Port SQL dostępny z całej sieci.
[ ] Backupy dostępne dla szerokich grup.
[ ] SQL Server uruchomiony na koncie Domain Admin.
```

---

# 23. Hardening serwerów plików

Serwery plików wymagają kontroli SMB, ACL, klasyfikacji danych i audytu.

## 23.1. Sprawdzenie udziałów

```powershell
Get-SmbShare
Get-SmbShareAccess -Name "NazwaUdzialu"
```

## 23.2. Zasady

```text
[ ] SMBv1 wyłączone.
[ ] SMB signing.
[ ] Access-Based Enumeration.
[ ] Brak Everyone: Full Control bez uzasadnienia.
[ ] Uprawnienia NTFS zgodne z zasadą minimalnych uprawnień.
[ ] Audyt dostępu do danych wrażliwych.
[ ] Backup i test odtwarzania.
[ ] Monitorowanie masowego odczytu/modyfikacji plików.
```

## 23.3. Ransomware

Serwery plików są częstym celem ransomware. Warto wdrożyć:

```text
[ ] Kontrolę uprawnień.
[ ] Kopie offline/immutable.
[ ] Monitoring masowych zmian plików.
[ ] Ograniczenie uprawnień użytkowników.
[ ] Segmentację.
[ ] EDR.
```

---

# 24. Hardening DNS i DHCP na Windows Server

## 24.1. DNS

DNS w AD jest krytyczny dla logowania, lokalizacji kontrolerów domeny i usług.

Zasady:

```text
[ ] Secure dynamic updates dla stref AD-integrated.
[ ] Ograniczenie zone transfer.
[ ] Kontrola grupy DNSAdmins.
[ ] Audyt zmian rekordów.
[ ] Oddzielenie DNS wewnętrznego od publicznego.
[ ] Monitoring podejrzanych rekordów.
```

## 24.2. DHCP

DHCP może wpływać na konfigurację klientów: DNS, gateway, WPAD i inne opcje.

Zasady:

```text
[ ] Tylko autoryzowane serwery DHCP.
[ ] Audyt zmian zakresów.
[ ] Kontrola opcji DHCP.
[ ] Ograniczenie administratorów DHCP.
[ ] Segmentacja VLAN.
[ ] Monitoring konfliktów adresów.
```

---

# 25. Hardening Active Directory

Active Directory to fundament klasycznej infrastruktury Windows. Jeżeli AD zostanie przejęte, większość zabezpieczeń pojedynczych serwerów traci znaczenie.

Najważniejsze obszary:

```text
[ ] Kontrolery domeny.
[ ] Grupy uprzywilejowane.
[ ] Konta administracyjne.
[ ] Konta serwisowe.
[ ] GPO.
[ ] Kerberos.
[ ] LDAP.
[ ] SMB/SYSVOL/NETLOGON.
[ ] DNS.
[ ] AD CS.
[ ] Backup i odtwarzanie.
[ ] Audyt.
```

---

# 26. Model Tier 0 / Tier 1 / Tier 2 i Enterprise Access Model

Model warstwowy pomaga ograniczyć kradzież poświadczeń i ruch lateralny.

## 26.1. Klasyczny podział

```text
Tier 0:
- kontrolery domeny,
- AD DS,
- AD CS,
- ADFS,
- Entra Connect / Azure AD Connect,
- konta Domain Admins, Enterprise Admins, Schema Admins,
- systemy zarządzające tożsamością.

Tier 1:
- serwery członkowskie,
- serwery aplikacyjne,
- SQL Server,
- file server,
- serwery backupu,
- wirtualizacja.

Tier 2:
- stacje robocze,
- laptopy,
- komputery użytkowników.
```

## 26.2. Zasada

```text
Konto z wyższego poziomu nie powinno logować się na system niższego poziomu.
```

Przykład:

```text
Domain Admin nie loguje się na zwykłą stację roboczą.
Administrator serwerów nie administruje laptopem użytkownika kontem serwerowym.
Helpdesk nie ma dostępu do kontrolerów domeny.
```

---

# 27. Kontrolery domeny

Kontroler domeny powinien być traktowany jako system krytyczny.

## 27.1. Zasady dla DC

```text
[ ] Tylko rola kontrolera domeny i niezbędne komponenty.
[ ] Brak aplikacji biznesowych na DC.
[ ] Brak przeglądania Internetu z DC.
[ ] Brak poczty i pakietów biurowych.
[ ] Dostęp administracyjny tylko z PAW lub jump hosta.
[ ] Regularne aktualizacje.
[ ] Ograniczona liczba administratorów.
[ ] Monitoring logów bezpieczeństwa.
[ ] Backup System State.
[ ] Test odtwarzania.
```

## 27.2. Czego nie robić na DC

```text
[ ] Nie instalować przypadkowych aplikacji.
[ ] Nie używać DC jako file servera dla użytkowników.
[ ] Nie używać DC jako serwera aplikacyjnego.
[ ] Nie przeglądać Internetu.
[ ] Nie wykonywać codziennej pracy administracyjnej niezwiązanej z AD.
```

---

# 28. Grupy uprzywilejowane w AD

## 28.1. Grupy do kontroli

```text
Enterprise Admins
Domain Admins
Schema Admins
Administrators
Account Operators
Backup Operators
Server Operators
Print Operators
DNSAdmins
Group Policy Creator Owners
Remote Desktop Users na serwerach
Lokalni Administrators na serwerach i stacjach
```

## 28.2. Sprawdzenie członkostwa

```powershell
Get-ADGroupMember "Domain Admins"
Get-ADGroupMember "Enterprise Admins"
Get-ADGroupMember "Schema Admins"
Get-ADGroupMember "Administrators"
```

## 28.3. Zasady

```text
[ ] Domain Admins powinno być prawie puste.
[ ] Enterprise Admins puste poza wyjątkowymi operacjami.
[ ] Schema Admins puste poza zmianami schematu.
[ ] Konto uprzywilejowane nie służy do poczty i Internetu.
[ ] Każdy administrator ma osobne konto zwykłe i administracyjne.
[ ] Członkostwo w grupach uprzywilejowanych jest monitorowane.
```

---

# 29. Konta administracyjne i PAW

## 29.1. Oddzielenie kont

Każdy administrator powinien mieć co najmniej dwa konta:

```text
Konto zwykłe:
- poczta,
- Internet,
- komunikatory,
- dokumenty,
- codzienna praca.

Konto administracyjne:
- tylko administracja,
- brak poczty,
- brak Internetu,
- logowanie tylko na właściwych systemach,
- silny audyt.
```

W większych środowiskach:

```text
admin-t0 — tylko Tier 0,
admin-t1 — serwery,
admin-t2 — stacje robocze.
```

## 29.2. PAW — Privileged Access Workstation

PAW to stacja przeznaczona do administracji systemami uprzywilejowanymi.

Zasady:

```text
[ ] Brak poczty.
[ ] Brak zwykłego Internetu.
[ ] Tylko narzędzia administracyjne.
[ ] Credential Guard.
[ ] BitLocker.
[ ] Kontrola aplikacji.
[ ] Silne logowanie.
[ ] Dostęp tylko do systemów odpowiedniego poziomu.
[ ] Centralne logowanie zdarzeń.
```

---

# 30. Konta serwisowe i gMSA

Konta serwisowe są częstym źródłem ryzyka w AD.

## 30.1. Typowe problemy

```text
[ ] Hasło niezmieniane od lat.
[ ] Hasło znane wielu administratorom.
[ ] Konto ma Domain Admin.
[ ] Konto ma SPN i słabe hasło.
[ ] Konto używane na wielu serwerach.
[ ] Konto może logować się interaktywnie.
[ ] Konto nie ma ograniczeń logowania.
```

## 30.2. Przegląd kont

```powershell
Get-ADUser -Filter {PasswordNeverExpires -eq $true} -Properties PasswordNeverExpires |
Select-Object SamAccountName, Enabled, PasswordNeverExpires

Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties ServicePrincipalName |
Select-Object SamAccountName, ServicePrincipalName
```

## 30.3. Dobre praktyki

```text
[ ] Używaj gMSA tam, gdzie aplikacja to wspiera.
[ ] Konta serwisowe mają minimalne uprawnienia.
[ ] Zakaz logowania interaktywnego.
[ ] Logowanie tylko na konkretnych serwerach.
[ ] Regularna rotacja haseł dla zwykłych kont serwisowych.
[ ] Monitoring zmian SPN.
[ ] Brak członkostwa w grupach uprzywilejowanych.
```

---

# 31. Kerberos hardening

Kerberos jest podstawowym mechanizmem uwierzytelniania w domenie AD.

## 31.1. Obszary

```text
[ ] Preferowanie AES zamiast RC4.
[ ] Audyt użycia RC4.
[ ] Silne hasła kont serwisowych.
[ ] gMSA dla usług.
[ ] Kontrola SPN.
[ ] Ograniczenie delegacji.
[ ] Monitorowanie żądań TGT i TGS.
[ ] Eliminacja kont bez Kerberos pre-authentication, jeśli nie ma uzasadnienia.
```

## 31.2. Konta bez Kerberos pre-authentication

```powershell
Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} -Properties DoesNotRequirePreAuth |
Select-Object SamAccountName, Enabled, DoesNotRequirePreAuth
```

Takie konta są podatniejsze na ataki offline na hasła. Nie każde wystąpienie oznacza incydent, ale każde wymaga wyjaśnienia.

## 31.3. Konta ze SPN

```powershell
Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties ServicePrincipalName |
Select-Object SamAccountName, Enabled, ServicePrincipalName
```

Konta ze SPN i słabym hasłem są ryzykowne w kontekście Kerberoastingu.

---

# 32. LDAP signing i channel binding

LDAP signing i LDAP channel binding ograniczają ryzyko manipulacji i ataków relay na komunikację LDAP.

## 32.1. Docelowe cele

```text
[ ] LDAP signing.
[ ] LDAP channel binding.
[ ] LDAPS tam, gdzie wymagane.
[ ] Brak simple bind bez TLS.
[ ] Audyt klientów niezgodnych.
```

## 32.2. Kolejność wdrożenia

```text
1. Włącz audyt.
2. Zidentyfikuj aplikacje używające niebezpiecznego LDAP.
3. Popraw konfigurację aplikacji.
4. Wdróż wymaganie podpisywania.
5. Monitoruj błędy.
```

Nie należy wymuszać LDAP signing/channel binding bez testów, ponieważ starsze aplikacje mogą przestać działać.

---

# 33. GPO hardening

GPO jest jednym z najpotężniejszych mechanizmów zarządzania w AD. Błędne delegacje GPO mogą dać atakującemu możliwość wykonania kodu na wielu komputerach.

## 33.1. Zasady

```text
[ ] Ogranicz, kto może tworzyć GPO.
[ ] Ogranicz, kto może edytować GPO.
[ ] Regularnie przeglądaj delegacje.
[ ] Monitoruj zmiany GPO.
[ ] Backupuj GPO.
[ ] Stosuj osobne GPO dla DC, serwerów i stacji.
[ ] Nie wrzucaj wszystkich ustawień do jednego gigantycznego GPO.
```

## 33.2. Backup GPO

```powershell
Backup-GPO -All -Path "D:\BackupGPO"
```

## 33.3. Częsty błąd

```text
Authenticated Users ma prawo odczytu GPO — to normalne.
Authenticated Users ma prawo edycji GPO — to bardzo poważny problem.
```

---

# 34. Delegacje w AD

Delegacje są potrzebne, ale źle skonfigurowane mogą prowadzić do eskalacji uprawnień.

## 34.1. Obszary

```text
[ ] Unconstrained delegation.
[ ] Constrained delegation.
[ ] Resource-Based Constrained Delegation.
[ ] Delegacje na kontach komputerów.
[ ] Delegacje kont serwisowych.
[ ] Konta uprzywilejowane oznaczone jako sensitive.
```

## 34.2. Dobra praktyka

Konta uprzywilejowane powinny mieć ustawienie:

```text
Account is sensitive and cannot be delegated
```

Nie rozwiązuje to wszystkich problemów, ale ogranicza część ryzyka.

---

# 35. AdminSDHolder, adminCount i chronione obiekty

Obiekty uprzywilejowane są chronione mechanizmem AdminSDHolder/SDProp. Po odebraniu uprawnień konto może nadal mieć `adminCount=1`, co wymaga przeglądu.

## 35.1. Kontrola

```powershell
Get-ADUser -LDAPFilter "(adminCount=1)" -Properties adminCount |
Select-Object SamAccountName, Enabled, adminCount
```

## 35.2. Interpretacja

`adminCount=1` nie oznacza automatycznie incydentu, ale wskazuje konto, które było lub jest powiązane z uprzywilejowanymi grupami. Warto sprawdzić:

```text
[ ] aktualne członkostwa w grupach,
[ ] dziedziczenie ACL,
[ ] historię zmian,
[ ] czy konto nadal powinno mieć status uprzywilejowany.
```

---

# 36. DCSync i uprawnienia replikacji

DCSync polega na nadużyciu uprawnień replikacji katalogu. Konta z takimi uprawnieniami mogą odpytywać kontroler domeny o sekrety.

## 36.1. Uprawnienia do kontroli

```text
Replicating Directory Changes
Replicating Directory Changes All
Replicating Directory Changes In Filtered Set
```

## 36.2. Zasady

```text
[ ] Uprawnienia replikacji tylko dla kontrolerów domeny i uzasadnionych usług.
[ ] Monitoring zmian ACL na obiekcie domeny.
[ ] Alerty na nietypowe użycie replikacji.
[ ] Kontrola narzędzi synchronizujących tożsamości.
```

---

# 37. AD CS jako Tier 0

Active Directory Certificate Services często jest pomijane, a może być krytyczne dla bezpieczeństwa domeny.

## 37.1. Dlaczego AD CS jest ważne

Błędna konfiguracja szablonów certyfikatów może pozwolić na podszywanie się pod inne konta, w tym konta uprzywilejowane.

## 37.2. Obszary kontroli

```text
[ ] Kto może wydawać certyfikaty?
[ ] Kto może modyfikować szablony?
[ ] Czy zwykli użytkownicy mogą zapisywać się na ryzykowne szablony?
[ ] Czy szablony pozwalają podać dowolny Subject Alternative Name?
[ ] Czy certyfikaty mogą służyć do logowania klienta?
[ ] Czy CA jest odpowiednio zabezpieczone?
[ ] Czy klucz prywatny CA jest chroniony?
[ ] Czy AD CS jest traktowane jako Tier 0?
```

## 37.3. Dobra praktyka

AD CS powinno być objęte takim samym poziomem ochrony jak inne systemy Tier 0.

---

# 38. Backup i odtwarzanie AD

Backup AD musi być testowany. Sam fakt posiadania kopii zapasowej nie oznacza, że środowisko można odtworzyć.

## 38.1. Elementy

```text
[ ] Backup System State kontrolerów domeny.
[ ] Backup GPO.
[ ] Backup DNS, jeśli wymagany.
[ ] Procedura DSRM.
[ ] Test odtwarzania w środowisku izolowanym.
[ ] Procedura authoritative restore.
[ ] Procedura non-authoritative restore.
[ ] AD Recycle Bin.
```

## 38.2. Krytyczny błąd

```text
Organizacja ma backupy, ale nigdy nie testowała odtworzenia kontrolera domeny.
```

---

# 39. Checklisty końcowe

## 39.1. Checklist hardeningu Windows

```text
[ ] System aktualny.
[ ] Zbędne role i funkcje usunięte.
[ ] SMBv1 wyłączone.
[ ] Firewall aktywny.
[ ] Defender aktywny.
[ ] Brak podejrzanych wykluczeń Defendera.
[ ] ASR wdrożone przynajmniej w trybie audytu.
[ ] Credential Guard włączony tam, gdzie możliwe.
[ ] BitLocker włączony na laptopach i stacjach.
[ ] Lokalne hasła adminów zarządzane przez Windows LAPS.
[ ] Zwykli użytkownicy nie są lokalnymi administratorami.
[ ] RDP ograniczone.
[ ] WinRM ograniczony.
[ ] PowerShell 2.0 wyłączony.
[ ] PowerShell logging włączony.
[ ] Audyt logowania i zmian kont włączony.
[ ] Application Control rozważone.
[ ] Backupy działają i są testowane.
```

## 39.2. Checklist hardeningu Active Directory

```text
[ ] Domain Admins ograniczone do minimum.
[ ] Enterprise Admins puste poza wyjątkowymi pracami.
[ ] Schema Admins puste poza zmianami schematu.
[ ] Konta administracyjne oddzielone od zwykłych.
[ ] Model Tier 0 / Tier 1 / Tier 2 wdrożony lub zaplanowany.
[ ] PAW dla administratorów Tier 0.
[ ] Protected Users dla wybranych kont po testach.
[ ] Windows LAPS wdrożony.
[ ] Konta serwisowe przejrzane.
[ ] gMSA używane tam, gdzie możliwe.
[ ] Konta z PasswordNeverExpires uzasadnione.
[ ] Konta bez Kerberos pre-auth wyeliminowane lub uzasadnione.
[ ] NTLM audytowany.
[ ] NTLMv1 wyłączany po testach.
[ ] LDAP signing i channel binding wdrażane po audycie.
[ ] SMB signing wymagany na DC.
[ ] Delegacje Kerberos przejrzane.
[ ] GPO delegacje przejrzane.
[ ] SYSVOL/NETLOGON zabezpieczone.
[ ] AD CS przeanalizowane jako Tier 0.
[ ] Backup System State DC działa.
[ ] Odtwarzanie AD przetestowane.
[ ] Zdarzenia bezpieczeństwa centralnie zbierane.
```

## 39.3. Checklist dla kontrolera domeny

```text
[ ] DC nie pełni roli serwera aplikacyjnego.
[ ] DC nie jest używany do pracy biurowej.
[ ] Na DC nie przegląda się Internetu.
[ ] Dostęp administracyjny tylko z PAW/jump hosta.
[ ] Firewall aktywny.
[ ] SMB signing wymagany.
[ ] LDAP hardening zaplanowany lub wdrożony.
[ ] Audyt Kerberos i zmian kont włączony.
[ ] Backup System State działa.
[ ] Monitorowane są zmiany w grupach uprzywilejowanych.
```

---

# 40. Źródła i punkty odniesienia

Poniższe materiały są dobrym punktem startowym do dalszego pogłębiania tematu. Przed wdrożeniem ustawień w środowisku produkcyjnym należy zweryfikować aktualność dokumentacji i zgodność z konkretną wersją systemu.

1. Microsoft Learn — Configure security baselines for Windows Server 2025  
   https://learn.microsoft.com/en-us/windows-server/security/osconfig/osconfig-how-to-configure-security-baselines

2. Microsoft Learn — Windows LAPS overview  
   https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview

3. Microsoft Learn — Attack surface reduction rules reference  
   https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference

4. Microsoft Learn — SMB security hardening in Windows Server and Windows Client  
   https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-security-hardening

5. Microsoft Learn — Enterprise access model / securing privileged access  
   https://learn.microsoft.com/en-us/security/privileged-access-workstations/privileged-access-access-model

6. Microsoft Learn — Protected Users Security Group  
   https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/protected-users-security-group

7. Microsoft Learn — LDAP signing for Active Directory Domain Services  
   https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/ldap-signing

8. Microsoft Learn — Detect and remediate RC4 usage in Kerberos  
   https://learn.microsoft.com/en-us/windows-server/security/kerberos/detect-remediate-rc4-kerberos

9. Microsoft Learn — Active Directory privileged accounts and groups  
   https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/appendix-b--privileged-accounts-and-groups-in-active-directory

10. Microsoft Learn — Audit policy recommendations  
   https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/audit-policy-recommendations

---

## Najważniejsze przesłanie

W Windows bezpieczeństwo systemu końcowego jest ważne, ale bezpieczeństwo tożsamości jest ważniejsze. Jeżeli przejęte zostanie Active Directory, pojedynczy dobrze zahardeningowany serwer nie uratuje całej organizacji.

Najważniejsze zasady:

```text
1. Ogranicz lokalnych administratorów.
2. Wdróż Windows LAPS.
3. Oddziel konta zwykłe od administracyjnych.
4. Nie loguj Domain Adminów na zwykłe stacje.
5. Włącz i monitoruj Defendera.
6. Ogranicz RDP, WinRM, SMB i NTLM.
7. Wdrażaj LDAP signing, SMB signing i Kerberos hardening po audycie.
8. Traktuj kontrolery domeny, AD CS i systemy tożsamości jako Tier 0.
9. Monitoruj zmiany w grupach uprzywilejowanych i GPO.
10. Testuj backup i odtwarzanie AD.
```
