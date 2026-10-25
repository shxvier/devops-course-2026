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

## Контроль

`bash ~/repo/scripts/audit.sh; echo $?` на сервере — `0`.
