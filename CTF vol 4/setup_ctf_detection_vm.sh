#!/usr/bin/env bash
set -euo pipefail

# setup_ctf_detection_vm.sh
# Ubuntu VM lab for Red vs Blue: detection, IR, hardening and patching.
# Default user: ubuntu / ubuntu
# Run: chmod +x setup_ctf_detection_vm.sh && sudo ./setup_ctf_detection_vm.sh
# WARNING: intentionally vulnerable lab. Do not expose to the Internet.

CTF_USER="ubuntu"
CTF_PASS="ubuntu"
WEB_ROOT="/var/www/ctf-lab"
BLUE_DIR="/opt/ctf-blue"
CTF_DIR="/opt/ctf-lab"
DOCKER_DIR="/opt/ctf-vulnerable-services"
SITE_CONF="/etc/apache2/sites-available/ctf-lab.conf"

info(){ echo "[+] $*"; }
warn(){ echo "[!] $*"; }

if [ "${EUID}" -ne 0 ]; then
  echo "[ERROR] Run as root: sudo $0" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

info "Updating packages"
apt-get update -y

info "Installing base tools"
apt-get install -y \
  apache2 php libapache2-mod-php openssh-server ufw fail2ban auditd audispd-plugins \
  net-tools lsof tcpdump curl wget jq unzip git vim nano htop tmux tree whois dnsutils \
  iproute2 psmisc procps python3 python3-pip ca-certificates gnupg lynis nmap rsyslog \
  docker.io docker-compose-plugin

systemctl enable --now docker
systemctl enable --now apache2
systemctl enable --now ssh
systemctl enable --now auditd || true
systemctl enable --now rsyslog || true

info "Configuring user ${CTF_USER}/${CTF_PASS}"
if id "${CTF_USER}" >/dev/null 2>&1; then
  echo "${CTF_USER}:${CTF_PASS}" | chpasswd
else
  useradd -m -s /bin/bash "${CTF_USER}"
  echo "${CTF_USER}:${CTF_PASS}" | chpasswd
  usermod -aG sudo "${CTF_USER}"
fi
usermod -aG docker "${CTF_USER}" || true
cat >/etc/sudoers.d/90-ctf-ubuntu <<'SUDOEOF'
ubuntu ALL=(ALL:ALL) ALL
SUDOEOF
chmod 0440 /etc/sudoers.d/90-ctf-ubuntu

info "Configuring SSH for lab"
cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.backup.$(date +%Y%m%d%H%M%S)"
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
grep -q '^MaxAuthTries ' /etc/ssh/sshd_config || echo 'MaxAuthTries 6' >> /etc/ssh/sshd_config
systemctl restart ssh

info "Creating lab directories"
mkdir -p "${WEB_ROOT}/uploads" "${WEB_ROOT}/admin" "${WEB_ROOT}/backup" "${BLUE_DIR}" "${CTF_DIR}" "${DOCKER_DIR}"

info "Creating intentionally vulnerable PHP app"
cat >"${WEB_ROOT}/index.php" <<'PHP'
<?php $ip=$_SERVER['REMOTE_ADDR']??'unknown'; $time=date('Y-m-d H:i:s'); ?>
<!doctype html><html lang="pl"><head><meta charset="utf-8"><title>CTF Red vs Blue Lab</title>
<style>body{font-family:Arial;margin:40px;background:#f6f8fa}.box{background:#fff;padding:20px;border:1px solid #ddd;max-width:950px}code{background:#eee;padding:2px 4px}</style></head><body><div class="box">
<h1>CTF Red vs Blue Lab</h1>
<p>Podatna aplikacja testowa do ćwiczeń detekcji i incident response.</p>
<p>Twój IP: <code><?php echo htmlspecialchars($ip); ?></code></p>
<p>Czas serwera: <code><?php echo htmlspecialchars($time); ?></code></p>
<h2>Endpointy</h2><ul>
<li><a href="/health.php">/health.php</a> - monitoring</li>
<li><a href="/ping.php">/ping.php</a> - command injection</li>
<li><a href="/upload.php">/upload.php</a> - podatny upload</li>
<li><a href="/admin/">/admin/</a> - panel demo</li>
<li><a href="/backup/">/backup/</a> - katalog backup</li>
</ul><p>Flaga publiczna: <code>CTF{service_is_up}</code></p></div></body></html>
PHP

cat >"${WEB_ROOT}/health.php" <<'PHP'
<?php header('Content-Type: text/plain'); echo "OK\nservice=ctf-lab\nflag=CTF{healthcheck_ok}\n"; ?>
PHP

cat >"${WEB_ROOT}/ping.php" <<'PHP'
<?php
// Intentionally vulnerable endpoint for isolated CTF lab only.
$result=''; $host=$_GET['host']??'';
if($host!==''){
  $cmd='ping -c 2 '.$host.' 2>&1';
  $result=shell_exec($cmd);
}
?>
<!doctype html><html lang="pl"><head><meta charset="utf-8"><title>Ping Tool</title></head><body>
<h1>Ping Tool</h1><form method="get"><label>Host/IP:</label><input name="host" value="<?php echo htmlspecialchars($host); ?>"><button>Ping</button></form>
<p>Przykład: <code>?host=127.0.0.1</code></p><pre><?php echo htmlspecialchars($result); ?></pre></body></html>
PHP

cat >"${WEB_ROOT}/upload.php" <<'PHP'
<?php
// Intentionally vulnerable upload for CTF lab only.
$msg='';
if($_SERVER['REQUEST_METHOD']==='POST' && isset($_FILES['file'])){
  $targetDir=__DIR__.'/uploads/';
  $name=basename($_FILES['file']['name']);
  $target=$targetDir.$name;
  if(move_uploaded_file($_FILES['file']['tmp_name'],$target)) $msg='Wgrano plik: /uploads/'.htmlspecialchars($name);
  else $msg='Upload nieudany.';
}
?>
<!doctype html><html lang="pl"><head><meta charset="utf-8"><title>Upload</title></head><body>
<h1>Upload</h1><p>Podatny upload do ćwiczeń wykrywania webshelli.</p>
<form method="post" enctype="multipart/form-data"><input type="file" name="file"><button>Wyślij</button></form><p><?php echo $msg; ?></p></body></html>
PHP

cat >"${WEB_ROOT}/admin/index.php" <<'PHP'
<?php echo '<h1>Admin panel</h1><p>Flaga: <code>CTF{admin_panel_found}</code></p>'; ?>
PHP
cat >"${WEB_ROOT}/backup/readme.txt" <<'EOF2'
Old backup directory.
Flag: CTF{backup_directory_found}
EOF2
cat >"${WEB_ROOT}/.env" <<'EOF2'
APP_ENV=ctf-lab
APP_DEBUG=true
DB_USER=ctf_user
DB_PASS=ctf_password_lab_only
FLAG=CTF{env_file_exposed}
EOF2
cat >"${WEB_ROOT}/uploads/readme.txt" <<'EOF2'
Upload directory. Blue Team should detect PHP/phtml/phar files and recent modifications.
EOF2

chown -R www-data:www-data "${WEB_ROOT}"
chmod -R 775 "${WEB_ROOT}"
chmod 777 "${WEB_ROOT}/uploads"

info "Configuring Apache site"
a2enmod rewrite headers status >/dev/null || true
cat >"${SITE_CONF}" <<EOF2
<VirtualHost *:80>
    ServerName ctf-lab.local
    DocumentRoot ${WEB_ROOT}
    ErrorLog \${APACHE_LOG_DIR}/ctf-lab-error.log
    CustomLog \${APACHE_LOG_DIR}/ctf-lab-access.log combined
    <Directory ${WEB_ROOT}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    <Location /server-status>
        SetHandler server-status
        Require local
    </Location>
</VirtualHost>
EOF2
a2dissite 000-default.conf >/dev/null || true
a2ensite ctf-lab.conf >/dev/null
systemctl restart apache2

info "Creating controlled weak system settings"
if ! id student >/dev/null 2>&1; then useradd -m -s /bin/bash student; fi
echo 'student:student' | chpasswd
if ! id webops >/dev/null 2>&1; then useradd -m -s /bin/bash webops; fi
echo 'webops:webops' | chpasswd
cat >/etc/sudoers.d/91-ctf-webops-weak <<'EOF2'
webops ALL=(root) NOPASSWD: /usr/sbin/service apache2 *
EOF2
chmod 0440 /etc/sudoers.d/91-ctf-webops-weak
if ! id backupsvc >/dev/null 2>&1; then useradd -r -s /usr/sbin/nologin backupsvc; fi
cat >"${CTF_DIR}/weak_permissions_note.txt" <<'EOF2'
Simulated weak permission file.
Flag: CTF{weak_permissions_checked}
EOF2
chmod 666 "${CTF_DIR}/weak_permissions_note.txt"
cat >"${CTF_DIR}/backup_config_old.txt" <<'EOF2'
Old backup config.
db_user=legacy_app
db_password=legacy_password_123
flag=CTF{old_backup_found}
EOF2
chmod 644 "${CTF_DIR}/backup_config_old.txt"

info "Configuring auditd rules"
cat >/etc/audit/rules.d/ctf-lab.rules <<'EOF2'
-w /etc/passwd -p wa -k identity_changes
-w /etc/group -p wa -k group_changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k ssh_config_changes
-w /etc/crontab -p wa -k cron_changes
-w /etc/cron.d/ -p wa -k cron_changes
-w /etc/systemd/system/ -p wa -k systemd_changes
-w /var/www/ctf-lab/ -p wa -k webroot_changes
EOF2
augenrules --load >/dev/null || true
systemctl restart auditd || true

info "Configuring firewall"
ufw --force reset >/dev/null
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow 22/tcp comment 'SSH lab' >/dev/null
ufw allow 80/tcp comment 'Apache CTF app' >/dev/null
ufw allow 8081/tcp comment 'vuln apache 2.4.49' >/dev/null
ufw allow 8082/tcp comment 'DVWA' >/dev/null
ufw allow 8083/tcp comment 'Tomcat demo' >/dev/null
ufw allow 2121/tcp comment 'vuln FTP lab' >/dev/null
ufw allow 1445/tcp comment 'vuln Samba lab' >/dev/null
ufw --force enable >/dev/null

info "Creating Docker vulnerable services"
mkdir -p "${DOCKER_DIR}/apache-2.4.49/conf" "${DOCKER_DIR}/apache-2.4.49/html/cgi-bin" "${DOCKER_DIR}/samba/share"
cat >"${DOCKER_DIR}/apache-2.4.49/html/index.html" <<'EOF2'
<!doctype html><html><head><meta charset="utf-8"><title>Apache 2.4.49 Lab</title></head><body>
<h1>Apache httpd 2.4.49 vulnerable lab</h1>
<p>Port: 8081</p><p>Goal: detect old vulnerable version and patch it.</p>
<p>Flag: CTF{apache_249_detected}</p></body></html>
EOF2
cat >"${DOCKER_DIR}/apache-2.4.49/html/cgi-bin/status.sh" <<'EOF2'
#!/bin/sh
echo "Content-Type: text/plain"
echo
echo "CGI OK"
echo "flag=CTF{cgi_enabled}"
EOF2
chmod +x "${DOCKER_DIR}/apache-2.4.49/html/cgi-bin/status.sh"
cat >"${DOCKER_DIR}/apache-2.4.49/conf/httpd.conf" <<'EOF2'
ServerRoot "/usr/local/apache2"
Listen 80
LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule authz_host_module modules/mod_authz_host.so
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule alias_module modules/mod_alias.so
LoadModule cgid_module modules/mod_cgid.so
User daemon
Group daemon
ServerName localhost
DocumentRoot "/usr/local/apache2/htdocs"
<Directory />
    Require all granted
</Directory>
<Directory "/usr/local/apache2/htdocs">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
DirectoryIndex index.html
ScriptAlias /cgi-bin/ "/usr/local/apache2/htdocs/cgi-bin/"
<Directory "/usr/local/apache2/htdocs/cgi-bin">
    Options +ExecCGI
    AddHandler cgi-script .sh
    Require all granted
</Directory>
ErrorLog /proc/self/fd/2
CustomLog /proc/self/fd/1 common
TypesConfig conf/mime.types
EOF2
cat >"${DOCKER_DIR}/samba/share/readme.txt" <<'EOF2'
Samba vulnerable-style lab share.
Goal: detect SMB, anonymous access and harden configuration.
Flag: CTF{samba_share_found}
EOF2
cat >"${DOCKER_DIR}/samba/smb.conf" <<'EOF2'
[global]
   workgroup = WORKGROUP
   server string = CTF Vulnerable Samba Lab
   map to guest = Bad User
   log file = /var/log/samba/log.%m
   max log size = 50
   dns proxy = no
[public]
   path = /share
   browsable = yes
   writable = yes
   guest ok = yes
   read only = no
EOF2
cat >"${DOCKER_DIR}/docker-compose.yml" <<'EOF2'
services:
  vuln-apache-249:
    image: httpd:2.4.49
    container_name: ctf-vuln-apache-249
    restart: unless-stopped
    ports: ["8081:80"]
    volumes:
      - ./apache-2.4.49/html:/usr/local/apache2/htdocs:ro
      - ./apache-2.4.49/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro
    labels:
      ctf.service: "vulnerable-apache"
      ctf.lesson: "detect-old-version-and-patch"
  dvwa:
    image: vulnerables/web-dvwa
    container_name: ctf-dvwa
    restart: unless-stopped
    ports: ["8082:80"]
    labels:
      ctf.service: "dvwa"
      ctf.lesson: "web-vulnerability-detection"
  vuln-samba:
    image: dperson/samba
    container_name: ctf-vuln-samba
    restart: unless-stopped
    ports: ["1445:445"]
    volumes:
      - ./samba/share:/share
      - ./samba/smb.conf:/etc/samba/smb.conf:ro
    command: "-p"
    labels:
      ctf.service: "samba"
      ctf.lesson: "anonymous-share-hardening"
  vuln-vsftpd:
    image: cyberxsecurity/vsftpd-2.3.4
    container_name: ctf-vuln-vsftpd-234
    restart: unless-stopped
    ports: ["2121:21"]
    labels:
      ctf.service: "vsftpd"
      ctf.lesson: "detect-backdoored-old-service"
  tomcat-demo:
    image: tomcat:8.5-jdk8
    container_name: ctf-tomcat-demo
    restart: unless-stopped
    ports: ["8083:8080"]
    labels:
      ctf.service: "tomcat"
      ctf.lesson: "old-major-version-upgrade"
EOF2
cat >"${DOCKER_DIR}/docker-compose.patched.yml" <<'EOF2'
services:
  patched-apache:
    image: httpd:2.4
    container_name: ctf-patched-apache
    restart: unless-stopped
    ports: ["8081:80"]
    volumes:
      - ./apache-2.4.49/html:/usr/local/apache2/htdocs:ro
  patched-samba:
    image: dperson/samba
    container_name: ctf-patched-samba
    restart: unless-stopped
    ports: ["1445:445"]
    volumes:
      - ./samba/share:/share:ro
    command: "-s 'public;/share;yes;no;no;all;none'"
  patched-tomcat:
    image: tomcat:10-jdk17
    container_name: ctf-patched-tomcat
    restart: unless-stopped
    ports: ["8083:8080"]
EOF2
cat >"${DOCKER_DIR}/README.md" <<'EOF2'
# Vulnerable Docker services

Start:
```bash
cd /opt/ctf-vulnerable-services
sudo docker compose up -d
```

Services:
- Apache httpd 2.4.49: http://IP:8081/
- DVWA: http://IP:8082/
- Tomcat 8: http://IP:8083/
- vsftpd 2.3.4: IP:2121
- Samba anonymous-style share: IP:1445

Patch lab services:
```bash
sudo /opt/ctf-blue/20_patch_vulnerable_services.sh
```

Do not expose this lab to the Internet.
EOF2

cd "${DOCKER_DIR}"
docker compose pull || warn "Some Docker images could not be pulled. Retry later: cd ${DOCKER_DIR} && sudo docker compose pull"
docker compose up -d || warn "Some Docker services could not start. Check: sudo docker ps -a"

info "Creating Blue Team scripts"
cat >"${BLUE_DIR}/01_system_snapshot.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
OUT="/tmp/ctf_snapshot_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
{ date -Is; hostnamectl || hostname; echo; cat /etc/passwd; echo; getent group sudo || true; echo; last -a | head -50 || true; who || true; w || true; } > "$OUT/system.txt"
ps auxf > "$OUT/processes.txt"
ss -tunap > "$OUT/network.txt" 2>/dev/null || ss -tuna > "$OUT/network.txt"
find /var/www/ctf-lab -type f -printf '%TY-%Tm-%Td %TH:%TM %u %g %m %p\n' 2>/dev/null | sort > "$OUT/webroot_files.txt"
cp /var/log/auth.log "$OUT/auth.log" 2>/dev/null || true
cp /var/log/apache2/ctf-lab-access.log "$OUT/ctf-lab-access.log" 2>/dev/null || true
cp /var/log/apache2/ctf-lab-error.log "$OUT/ctf-lab-error.log" 2>/dev/null || true
docker ps -a > "$OUT/docker_ps.txt" 2>/dev/null || true
docker images > "$OUT/docker_images.txt" 2>/dev/null || true
tar -czf "${OUT}.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo "[OK] Snapshot: ${OUT}.tar.gz"
EOF2
cat >"${BLUE_DIR}/02_watch_logs.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
tail -F /var/log/auth.log /var/log/apache2/ctf-lab-access.log /var/log/apache2/ctf-lab-error.log
EOF2
cat >"${BLUE_DIR}/03_detect_ssh_bruteforce.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
LOG="${1:-/var/log/auth.log}"
echo "[+] Top IP with failed SSH logins:"
grep -E "Failed password|Invalid user" "$LOG" 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="from") print $(i+1)}}' | sort | uniq -c | sort -nr | head -20 || true
echo; echo "[+] Successful SSH logins:"
grep -E "Accepted password|Accepted publickey" "$LOG" 2>/dev/null || true
EOF2
cat >"${BLUE_DIR}/04_detect_web_attacks.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
LOG="${1:-/var/log/apache2/ctf-lab-access.log}"
echo "[+] Suspicious HTTP requests:"
grep -Ein "(\.\./|/etc/passwd|cmd=|;id|;whoami|/bin/bash|bash%20|bash\+|nc%20|ncat|python|perl|phpinfo|\.env|\.git|union|select|sleep\(|benchmark\(|shell\.php|uploads|passwd|shadow)" "$LOG" 2>/dev/null || true
echo; echo "[+] Top IPs:"
awk '{print $1}' "$LOG" 2>/dev/null | sort | uniq -c | sort -nr | head -20 || true
echo; echo "[+] Top paths:"
awk '{print $7}' "$LOG" 2>/dev/null | sort | uniq -c | sort -nr | head -30 || true
EOF2
cat >"${BLUE_DIR}/05_detect_webshells.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-/var/www/ctf-lab}"
echo "[+] Files modified in last 24h:"
find "$ROOT" -type f -mtime -1 -ls 2>/dev/null || true
echo; echo "[+] Suspicious PHP functions:"
grep -RInE "system\s*\(|shell_exec\s*\(|passthru\s*\(|exec\s*\(|popen\s*\(|proc_open\s*\(|eval\s*\(|assert\s*\(|base64_decode\s*\(|gzinflate\s*\(" "$ROOT" 2>/dev/null || true
echo; echo "[+] PHP-like files in upload paths:"
find "$ROOT" -path "*upload*" -type f \( -name "*.php" -o -name "*.phtml" -o -name "*.phar" \) -ls 2>/dev/null || true
EOF2
cat >"${BLUE_DIR}/06_check_persistence.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
echo "### authorized_keys"; find /home /root -name authorized_keys -type f -exec ls -la {} \; -exec sed -n '1,5p' {} \; 2>/dev/null || true
echo; echo "### cron"; ls -la /etc/cron* 2>/dev/null || true; grep -RInE "bash|sh|nc|ncat|socat|curl|wget|python|perl|php|/dev/tcp" /etc/cron* /var/spool/cron 2>/dev/null || true
echo; echo "### systemd modified in last 48h"; find /etc/systemd/system -type f -mtime -2 -ls 2>/dev/null || true; grep -RInE "bash|sh|nc|ncat|socat|curl|wget|python|perl|php|/dev/tcp" /etc/systemd/system 2>/dev/null || true
echo; echo "### shell startup files"; find /home /root -maxdepth 2 \( -name ".bashrc" -o -name ".profile" -o -name ".bash_profile" \) -type f -exec grep -HnE "bash|nc|ncat|socat|curl|wget|python|perl|php|/dev/tcp" {} \; 2>/dev/null || true
echo; echo "### temp files"; find /tmp /var/tmp /dev/shm -type f -mtime -2 -ls 2>/dev/null || true
EOF2
cat >"${BLUE_DIR}/07_check_users_privileges.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
echo "### UID 0 accounts"; awk -F: '$3 == 0 {print}' /etc/passwd
echo; echo "### sudo group"; getent group sudo || true
echo; echo "### privileged groups"; for g in sudo adm docker lxd shadow systemd-journal; do getent group "$g" || true; done
echo; echo "### NOPASSWD"; grep -RIn "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null || true
echo; echo "### login shells"; awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1":"$3":"$6":"$7}' /etc/passwd
echo; echo "### lastlog"; lastlog | head -50 || true
EOF2
cat >"${BLUE_DIR}/08_active_intrusion_check.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
echo "### Suspicious processes"; ps auxf | grep -Ei "www-data|apache|bash|sh|nc|ncat|socat|python|perl|php|curl|wget" | grep -v grep || true
echo; echo "### Network connections"; ss -tunap 2>/dev/null || ss -tuna
echo; echo "### Processes running from temp dirs"; find /proc -maxdepth 2 -name exe -type l 2>/dev/null | while read -r e; do t=$(readlink "$e" 2>/dev/null || true); case "$t" in /tmp/*|/var/tmp/*|/dev/shm/*) p=$(echo "$e"|awk -F/ '{print $3}'); echo "PID=$p EXE=$t CMD=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null || true)";; esac; done
EOF2
cat >"${BLUE_DIR}/09_block_ip.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
IP="${1:-}"
[ -n "$IP" ] || { echo "Usage: sudo $0 <ip>"; exit 1; }
[ "$IP" != "127.0.0.1" ] || { echo "Do not block localhost"; exit 1; }
ufw deny from "$IP"
ufw status numbered
EOF2
cat >"${BLUE_DIR}/10_service_test.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
URL="${1:-http://127.0.0.1/health.php}"
curl -i --max-time 5 "$URL"
echo; systemctl --no-pager status apache2 | sed -n '1,12p'
EOF2
cat >"${BLUE_DIR}/11_generate_incident_report.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-incident_report_$(date +%Y%m%d_%H%M%S).md}"
cat > "$OUT" <<'REPORT'
# Raport incydentu - Blue Team

## Dane podstawowe
- Data i czas wykrycia:
- Osoba / zespół:
- Dotknięta maszyna:
- Dotknięta usługa:

## Źródło wykrycia
- [ ] auth.log
- [ ] access.log/error.log
- [ ] procesy
- [ ] połączenia sieciowe
- [ ] auditd
- [ ] monitoring
- [ ] inne:

## Opis incydentu
```text

```

## Adresy i konta
- IP atakującego:
- Konto:
- Proces/PID:
- Port:
- Ścieżka pliku:

## Wektor wejścia
- [ ] brute force SSH
- [ ] podatność web
- [ ] upload webshella
- [ ] command injection
- [ ] stara podatna usługa
- [ ] inne:

## Timeline
| Czas | Zdarzenie | Źródło |
|---|---|---|
| | | |

## Dowody
```text

```

## Podjęte działania
- [ ] zablokowano IP
- [ ] zakończono proces
- [ ] zablokowano konto
- [ ] usunięto webshell
- [ ] usunięto persistence
- [ ] poprawiono konfigurację
- [ ] zaktualizowano/wyłączono starą usługę
- [ ] przywrócono usługę

## Status końcowy
- [ ] usługa działa
- [ ] monitoring pokazuje UP
- [ ] aktywny dostęp atakującego usunięty
- [ ] persistence sprawdzone
- [ ] podatność zamknięta

## Rekomendacje
-
REPORT
echo "[OK] Created: $OUT"
EOF2
cat >"${BLUE_DIR}/12_tmux_blue_dashboard.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
S=blue
if tmux has-session -t "$S" 2>/dev/null; then tmux attach -t "$S"; exit 0; fi
tmux new-session -d -s "$S" -n blue
tmux send-keys -t "$S":0.0 "sudo tail -F /var/log/auth.log" C-m
tmux split-window -h -t "$S":0
tmux send-keys -t "$S":0.1 "sudo tail -F /var/log/apache2/ctf-lab-access.log" C-m
tmux split-window -v -t "$S":0.1
tmux send-keys -t "$S":0.2 "watch -n 2 'ss -tunap 2>/dev/null | head -60'" C-m
tmux select-pane -t "$S":0.0
tmux split-window -v -t "$S":0.0
tmux send-keys -t "$S":0.3 "watch -n 2 'ps auxf | head -40'" C-m
tmux attach -t "$S"
EOF2
cat >"${BLUE_DIR}/13_detect_old_services.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
HOST="${1:-127.0.0.1}"
PORTS="${2:-22,80,8081,8082,8083,2121,1445}"
echo "[+] nmap service versions"; nmap -sV -p "$PORTS" "$HOST" || true
echo; echo "[+] HTTP headers"; for p in 80 8081 8082 8083; do echo "--- http://${HOST}:${p}/"; curl -I --max-time 4 "http://${HOST}:${p}/" 2>/dev/null || true; done
echo; echo "[+] Docker containers"; docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' 2>/dev/null || true
EOF2
cat >"${BLUE_DIR}/14_docker_service_logs.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
docker logs -f ctf-vuln-apache-249 2>&1 & P1=$!
docker logs -f ctf-dvwa 2>&1 & P2=$!
docker logs -f ctf-tomcat-demo 2>&1 & P3=$!
trap 'kill $P1 $P2 $P3 2>/dev/null || true' INT TERM EXIT
wait
EOF2
cat >"${BLUE_DIR}/15_make_timeline.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-timeline_$(date +%Y%m%d_%H%M%S).txt}"
{ echo "### Timeline generated: $(date -Is)"; echo; echo "### SSH"; grep -E "Failed password|Invalid user|Accepted password|session opened|session closed|sudo:" /var/log/auth.log 2>/dev/null || true; echo; echo "### HTTP suspicious"; grep -Ein "(\.\./|cmd=|;id|;whoami|/bin/bash|nc|ncat|python|perl|\.env|\.git|union|select|shell|uploads)" /var/log/apache2/ctf-lab-access.log 2>/dev/null || true; echo; echo "### Recent web files"; find /var/www/ctf-lab -type f -mtime -1 -printf '%TY-%Tm-%Td %TH:%TM:%TS %u %g %m %p\n' 2>/dev/null | sort || true; echo; echo "### Network"; ss -tunap 2>/dev/null || true; echo; echo "### Docker"; docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}' 2>/dev/null || true; } > "$OUT"
echo "[OK] Timeline: $OUT"
EOF2
cat >"${BLUE_DIR}/20_patch_vulnerable_services.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
LAB="/opt/ctf-vulnerable-services"
cd "$LAB"
echo "[+] Stopping vulnerable Docker services"
docker compose down || true
echo "[+] Starting patched variants"
docker compose -f docker-compose.patched.yml up -d
echo "[+] Removing intentionally old/backdoored FTP if present"
docker rm -f ctf-vuln-vsftpd-234 2>/dev/null || true
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
echo "[OK] Lab patching finished"
EOF2
cat >"${BLUE_DIR}/21_harden_local_php_app.sh" <<'EOF2'
#!/usr/bin/env bash
set -euo pipefail
WEB_ROOT="/var/www/ctf-lab"
mkdir -p /opt/ctf-lab/backups
tar -czf "/opt/ctf-lab/backups/webroot_before_hardening_$(date +%Y%m%d_%H%M%S).tar.gz" -C /var/www ctf-lab
if [ -f "$WEB_ROOT/.env" ]; then mv "$WEB_ROOT/.env" "/opt/ctf-lab/env_moved_$(date +%Y%m%d_%H%M%S).bak"; fi
cat >"$WEB_ROOT/uploads/.htaccess" <<'HT'
php_flag engine off
RemoveHandler .php .phtml .phar
RemoveType .php .phtml .phar
<FilesMatch "\.(php|phtml|phar)$">
  Require all denied
</FilesMatch>
HT
chown -R www-data:www-data "$WEB_ROOT"
find "$WEB_ROOT" -type d -exec chmod 755 {} \;
find "$WEB_ROOT" -type f -exec chmod 644 {} \;
chmod 755 "$WEB_ROOT/uploads"
cat >"$WEB_ROOT/ping.php" <<'PHP'
<?php
$result=''; $host=$_GET['host']??'';
if($host!==''){
  if(!preg_match('/^[a-zA-Z0-9.\-]{1,253}$/',$host)) $result='Niepoprawny format hosta.';
  else $result=shell_exec('ping -c 2 '.escapeshellarg($host).' 2>&1');
}
?>
<!doctype html><html lang="pl"><head><meta charset="utf-8"><title>Ping Tool - hardened</title></head><body>
<h1>Ping Tool - hardened</h1><form method="get"><label>Host/IP:</label><input name="host" value="<?php echo htmlspecialchars($host); ?>"><button>Ping</button></form>
<pre><?php echo htmlspecialchars($result); ?></pre></body></html>
PHP
systemctl reload apache2
echo "[OK] Local PHP app hardened"
EOF2
chmod +x "${BLUE_DIR}"/*.sh

info "Creating lab documentation on VM"
cat >"${CTF_DIR}/README_STUDENT.md" <<'EOF2'
# CTF Red vs Blue - student quick guide

Credentials: ubuntu / ubuntu

Main app:
- http://IP/
- http://IP/health.php

Local vulnerable endpoints:
- /ping.php - command injection
- /upload.php - vulnerable upload
- /admin/ - enumeration
- /backup/ - backup directory
- /.env - exposed environment file

Vulnerable Docker services:
- Apache httpd 2.4.49: http://IP:8081/
- DVWA: http://IP:8082/
- Tomcat 8: http://IP:8083/
- vsftpd 2.3.4: IP:2121
- Samba: IP:1445

Blue Team scripts:
```bash
sudo /opt/ctf-blue/01_system_snapshot.sh
sudo /opt/ctf-blue/02_watch_logs.sh
sudo /opt/ctf-blue/03_detect_ssh_bruteforce.sh
sudo /opt/ctf-blue/04_detect_web_attacks.sh
sudo /opt/ctf-blue/05_detect_webshells.sh
sudo /opt/ctf-blue/06_check_persistence.sh
sudo /opt/ctf-blue/07_check_users_privileges.sh
sudo /opt/ctf-blue/08_active_intrusion_check.sh
sudo /opt/ctf-blue/13_detect_old_services.sh 127.0.0.1
```

Patching:
```bash
sudo /opt/ctf-blue/21_harden_local_php_app.sh
sudo /opt/ctf-blue/20_patch_vulnerable_services.sh
```
EOF2
cat >"${CTF_DIR}/README_INSTRUCTOR.md" <<'EOF2'
# Instructor guide

Run setup:
```bash
sudo ./setup_ctf_detection_vm.sh
```

Verify:
```bash
curl http://127.0.0.1/health.php
sudo docker ps
sudo /opt/ctf-blue/13_detect_old_services.sh 127.0.0.1
```

Suggested Blue start:
```bash
sudo /opt/ctf-blue/01_system_snapshot.sh
sudo /opt/ctf-blue/12_tmux_blue_dashboard.sh
```

Safe Red examples in isolated lab:
```bash
nmap -sV -p 22,80,8081,8082,8083,2121,1445 IP
curl http://IP/.env
curl "http://IP/ping.php?host=127.0.0.1;id"
```

Patch phase:
```bash
sudo /opt/ctf-blue/21_harden_local_php_app.sh
sudo /opt/ctf-blue/20_patch_vulnerable_services.sh
```

Report:
```bash
/opt/ctf-blue/11_generate_incident_report.sh raport.md
```

Do not expose this VM to the Internet.
EOF2

info "Final checks"
curl -fsS http://127.0.0.1/health.php >/dev/null && info "Healthcheck works" || warn "Healthcheck failed"
ss -tulpen | grep -E '(:22|:80|:8081|:8082|:8083|:2121|:1445)' || true

cat <<EOF2

==============================================================================
CTF VM READY

Main app:
  http://VM_IP/
  http://VM_IP/health.php

Credentials:
  ${CTF_USER} / ${CTF_PASS}

Blue Team scripts:
  ${BLUE_DIR}

Docs:
  ${CTF_DIR}/README_STUDENT.md
  ${CTF_DIR}/README_INSTRUCTOR.md

Vulnerable Docker services:
  ${DOCKER_DIR}
  ports: 8081, 8082, 8083, 2121, 1445

Useful commands:
  sudo /opt/ctf-blue/12_tmux_blue_dashboard.sh
  sudo /opt/ctf-blue/13_detect_old_services.sh 127.0.0.1
  sudo /opt/ctf-blue/21_harden_local_php_app.sh
  sudo /opt/ctf-blue/20_patch_vulnerable_services.sh

WARNING: intentionally vulnerable lab. Do not expose it to the Internet.
==============================================================================
EOF2
