# VM Ubuntu do ćwiczeń Red vs Blue
(C) 2026 CyberPrzem

Plik `setup_ctf_detection_vm.sh` przygotowuje maszynę Ubuntu do ćwiczeń z detekcji ataku i incident response w czasie rzeczywistym.

## Uruchomienie

```bash
chmod +x setup_ctf_detection_vm.sh
sudo ./setup_ctf_detection_vm.sh
```

## Dane maszyny

- użytkownik: `ubuntu`
- hasło: `ubuntu`

## Co tworzy skrypt

1. Podatną aplikację PHP na Apache:
   - `/health.php`
   - `/ping.php`
   - `/upload.php`
   - `/admin/`
   - `/backup/`
   - `/.env`

2. Skrypty Blue Team w `/opt/ctf-blue`:
   - snapshot systemu,
   - podgląd logów,
   - detekcja brute force SSH,
   - detekcja ataków web,
   - wykrywanie webshelli,
   - sprawdzanie persistence,
   - audyt użytkowników i uprawnień,
   - wykrywanie starych usług,
   - dashboard tmux,
   - skrypty patchowania.

3. Stare/podatne usługi Docker:
   - Apache httpd 2.4.49 na porcie `8081`,
   - DVWA na porcie `8082`,
   - Tomcat 8 na porcie `8083`,
   - vsftpd 2.3.4 na porcie `2121`,
   - Samba na porcie `1445`.

## Patchowanie podczas ćwiczenia

```bash
sudo /opt/ctf-blue/21_harden_local_php_app.sh
sudo /opt/ctf-blue/20_patch_vulnerable_services.sh
```

## Ostrzeżenie

To środowisko jest celowo podatne. Uruchamiaj je tylko w izolowanym labie, najlepiej w sieci host-only/NAT. Nie wystawiaj tej maszyny do Internetu.
