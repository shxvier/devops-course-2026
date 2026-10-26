# Конфигурация виртуальной машины devops-vm

Документ позволяет восстановить конфигурацию со снимка `01-clean-install`.
Команды с пометкой **[VM]** выполняются на сервере (под `student` в консоли VM либо под `devops` по SSH),
**[Хост]** — на хостовой системе (Windows 11, PowerShell).

## 1. Параметры машины

| Параметр | Значение |
|---|---|
| Наименование | devops-vm |
| Гипервизор | Oracle VirtualBox 7.x |
| ОС | Ubuntu Server **26.04.1 LTS** (ядро 7.0), вариант не minimized, featured snaps не выбраны, OpenSSH server установлен |
| ОЗУ | 2048 МБ |
| ЦП | 2 ядра |
| Диск | 25 ГБ VDI, динамически расширяемый; разметка «Use an entire disk» + LVM (`/` 11,5 ГБ, `/boot` 2 ГБ) |
| Имя узла / FQDN | `devops-vm` / `devops-vm.devops.local` |

> Отклонение от методички: вместо 24.04 LTS установлена 26.04.1 LTS. Отличия, влияющие на работу:
> `sudo` реализован `sudo-rs` (приглашение `[sudo: authenticate] Password:`); в `sshd_config.d` есть `50-cloud-init.conf` с `PasswordAuthentication yes`.

## 2. Сетевые интерфейсы

| Адаптер | Тип VirtualBox | Интерфейс | Адрес | Назначение |
|---|---|---|---|---|
| 1 | NAT | `enp0s3` | `10.0.2.15/24` (DHCP) | выход в Интернет (apt, git); входящий SSH только через проброс порта |
| 2 | Виртуальный адаптер хоста (VirtualBox Host-Only Ethernet Adapter, `192.168.56.0/24`) | `enp0s8` | **`192.168.56.101/24`** (DHCP) | прямой доступ с хоста: `devops.local` (SSH 2222, HTTP/HTTPS) |

Проверка: `ip -brief address`.

## 3. Правило проброса портов

VirtualBox → devops-vm → Настроить → Сеть → Адаптер 1 → Проброс портов:

| Имя | Протокол | Адрес хоста | Порт хоста | Адрес гостя | Порт гостя |
|---|---|---|---|---|---|
| ssh | TCP | 127.0.0.1 | 2222 | — | **2222** (до ПР 5 зад. 2 — 22) |

## 4. Учётные записи

| Имя | UID | Группы | Аутентификация |
|---|---|---|---|
| `student` | 1000 | student, sudo (+ стандартные группы установщика) | только локальная консоль VM (по SSH запрещён `AllowUsers devops`); пароль для sudo |
| `devops` | 1001 | devops, sudo, users | SSH только по ключу ed25519 (`C:\Users\Alexey\.ssh\devops_vm`); пароль — только для sudo |

```bash
# [VM] под student (консоль)
sudo adduser devops                 # пароль devops задаётся интерактивно
sudo usermod -aG sudo devops
groups devops                       # devops : devops sudo users
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
# SHA256:nRg1QZMq0dIMwaTYbe3Zzm9m4Tnr0y0sxinwd/I0Gk0 root@devops-vm (ED25519)
```

```powershell
# [Хост] ключевая пара (без passphrase) и копирование открытого ключа (до отключения паролей!)
ssh-keygen -t ed25519 -C "devops-vm-key" -f $env:USERPROFILE\.ssh\devops_vm
ssh student@127.0.0.1 -p 2222      # сверить отпечаток с выводом ssh-keygen -lf на VM, ответить yes
type $env:USERPROFILE\.ssh\devops_vm.pub | ssh devops@127.0.0.1 -p 2222 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
ssh -i $env:USERPROFILE\.ssh\devops_vm -p 2222 devops@127.0.0.1   # без пароля
```

Права на сервере: `~/.ssh` — `700`, `~/.ssh/authorized_keys` — `600`.

`C:\Users\Alexey\.ssh\config` (хост):

```
Host devops
    HostName 127.0.0.1
    Port 2222
    User devops
    IdentityFile ~/.ssh/devops_vm
    IdentitiesOnly yes

Host devops.local
    HostName devops.local
    Port 2222
    User devops
    IdentityFile ~/.ssh/devops_vm
    IdentitiesOnly yes
```

Второй блок нужен для `ssh devops.local`: без него для имени `devops.local` клиент не знает ключ и получает `Permission denied (publickey)`.

## 5. Служба SSH

- Основной файл `/etc/ssh/sshd_config` не изменяется, эталонная копия — `/etc/ssh/sshd_config.backup`.
- Изменения — в `/etc/ssh/sshd_config.d/99-hardening.conf` (в репозитории: `configs/sshd/99-hardening.conf`):

```
Port 2222

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30

AllowUsers devops

X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
```

- В `/etc/ssh/sshd_config.d/50-cloud-init.conf` строка `PasswordAuthentication yes` закомментирована (файлы читаются по алфавиту, действует первое значение, поэтому `50-` перекрывал бы `99-`).
- Активация по сокету отключена: `ssh.socket` — disabled, `ssh.service` — enabled; `sshd` слушает `0.0.0.0:2222` и `[::]:2222`.

```bash
# [VM] действующую сессию не закрывать; проверять новым подключением с хоста
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
git clone -q https://github.com/shxvier/devops-course-2026 ~/repo
sudo cp ~/repo/configs/sshd/99-hardening.conf /etc/ssh/sshd_config.d/
sudo grep -r PasswordAuthentication /etc/ssh/sshd_config.d/ /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes/#&/' /etc/ssh/sshd_config.d/50-cloud-init.conf
sudo sshd -t && echo "sshd -t: OK"
sudo sshd -T | grep -Ei "^(port|permitrootlogin|passwordauthentication|maxauthtries|allowusers)"
sudo systemctl disable --now ssh.socket && sudo systemctl enable --now ssh.service && sudo systemctl restart ssh
sudo ss -tlnp | grep sshd           # 0.0.0.0:2222
```

Затем в VirtualBox: порт гостя правила `ssh` 22 → 2222. Проверка с хоста:
`ssh devops` — вход; `ssh -p 2222 root@127.0.0.1` и `ssh -p 2222 -o PubkeyAuthentication=no devops@127.0.0.1` — `Permission denied (publickey)`.

## 6. Правила межсетевого экрана

Политики: `deny (incoming)`, `allow (outgoing)`, `disabled (routed)`; журналирование `on (medium)`, журнал `/var/log/ufw.log`.

| Порт | Действие | Комментарий |
|---|---|---|
| 2222/tcp | LIMIT IN | SSH rate-limited |
| 80/tcp | ALLOW IN | HTTP |
| 443/tcp | ALLOW IN | HTTPS |

(для каждого правила есть дубль `(v6)`)

```bash
# [VM] разрешающее правило для 2222 — ДО ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw allow 80/tcp  comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
sudo ufw enable
sudo ufw delete allow 2222/tcp
sudo ufw limit 2222/tcp comment 'SSH rate-limited'
sudo ufw logging medium
sudo ufw status verbose
```

`ufw allow ssh` не используется: по `/etc/services` это порт 22.

### Локальное имя devops.local

```powershell
# [Хост] PowerShell от имени администратора
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "192.168.56.101`tdevops.local"
ipconfig /flushdns
ping devops.local
ssh devops.local                    # блок Host devops.local из раздела 4
```

```bash
# [VM]
sudo hostnamectl set-hostname devops-vm
sudo sed -i 's/^127.0.1.1.*/127.0.1.1 devops-vm.devops.local devops-vm/' /etc/hosts
hostname -f                         # devops-vm.devops.local
```

## 7. Снимки состояния

| Снимок | Момент создания (25.10.2026, MSK) | Состояние |
|---|---|---|
| `01-clean-install` | 03:39 | ОС установлена, `apt upgrade`, VM выключена |
| `02-keys-configured` | 04:01 | `devops` в sudo, ключ ed25519, `~/.ssh/config` |
| `03-ssh-hardened` | 04:40 | `99-hardening.conf`, порт 2222, `ssh.socket` отключён, проброс 2222→2222 |
| `04-nginx-https` | 26.10.2026 14:19 | Nginx, ресурс devops-site, самоподписанный сертификат, HTTP → HTTPS |

## 8. Веб-сервер

- Пакеты: `nginx` 1.28.3 и `rsync` из репозитория Ubuntu: `sudo apt update && sudo apt install -y nginx rsync`.
- Конфигурация ресурса: `/etc/nginx/sites-available/devops-site` (источник — `configs/nginx/devops-site` в репозитории; HTTP-вариант первого этапа — `configs/nginx/devops-site.http`), символическая ссылка в `/etc/nginx/sites-enabled/devops-site`. Ссылка `sites-enabled/default` удалена, файл `sites-available/default` сохранён.
- Каталог ресурса: `/var/www/devops-site`, владелец `devops:devops`, каталоги `755`, файлы `644`. Права приводятся при каждой доставке: `rsync --chmod=D755,F644` (`scripts/deploy.sh`).
- Сертификат: `/etc/ssl/certs/devops.crt`, `644 root:root`. Закрытый ключ: `/etc/ssl/private/devops.key`, `600 root:root` (читает только master-процесс nginx от root).
- Сертификат самоподписанный, RSA 2048, `CN=devops.local`, SAN `DNS:devops.local`, срок 365 дней (26.10.2026 — 26.10.2027).
- Журналы: `/var/log/nginx/devops-site.access.log`, `/var/log/nginx/devops-site.error.log`. HSTS не включается.

```bash
# [VM] каталог ресурса
sudo mkdir -p /var/www/devops-site
sudo chown -R devops:devops /var/www/devops-site

# [VM] сертификат
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt \
  -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local"

# [VM] конфигурация (репозиторий склонирован в ~/repo, ветка с конфигами)
sudo cp ~/repo/configs/nginx/devops-site /etc/nginx/sites-available/devops-site
sudo ln -s /etc/nginx/sites-available/devops-site /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

Итоговый `/etc/nginx/sites-available/devops-site`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name devops.local;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name devops.local;

    ssl_certificate     /etc/ssl/certs/devops.crt;
    ssl_certificate_key /etc/ssl/private/devops.key;
    ssl_protocols       TLSv1.2 TLSv1.3;

    root /var/www/devops-site;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    error_page 404 /404.html;

    access_log /var/log/nginx/devops-site.access.log;
    error_log  /var/log/nginx/devops-site.error.log;
}
```

```bash
# [Хост, WSL 1] окружение для доставки (один раз)
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /mnt/c/Users/Alexey/.ssh/devops_vm ~/.ssh/
tr -d '\r' < /mnt/c/Users/Alexey/.ssh/config > ~/.ssh/config   # убрать CRLF
chmod 600 ~/.ssh/devops_vm ~/.ssh/config
sudo apt install -y rsync git
git clone https://github.com/shxvier/devops-course-2026 ~/devops-course-2026   # не на /mnt/c

# [Хост, WSL 1] доверие сертификату и доставка
scp devops:/etc/ssl/certs/devops.crt ~/devops.crt
scripts/deploy.sh            # или scripts/deploy.sh --dry-run
```

## Контроль

`bash ~/repo/scripts/audit.sh; echo $?` на сервере — `0`.
