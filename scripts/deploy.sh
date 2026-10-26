#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops"                       # псевдоним из ~/.ssh/config (ПР № 5, шаг 1.6)
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"

err() { echo "deploy: $*" >&2; }

# Требование 2: работа из любого каталога репозитория
REPO_ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
cd "$REPO_ROOT"
LOCAL_DIR="${REPO_ROOT}/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=""
case "${1:-}" in
    "")        ;;
    --dry-run) DRY_RUN="--dry-run" ;;
    *)         err "неизвестный аргумент: $1"; echo "Использование: $0 [--dry-run]" >&2; exit 2 ;;
esac

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    err "файл site/index.html отсутствует, доставка отменена"
    exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
    err "в репозитории есть незафиксированные изменения, доставка отменена:"
    git status --short >&2
    exit 1
fi

# 3. Синхронизация: одно SSH-соединение, без интерактивного ввода пароля
rsync -avz --delete --chmod=D755,F644 $DRY_RUN \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=5" \
    "$LOCAL_DIR" "${REMOTE}:${REMOTE_DIR}/"

# 4. При --dry-run — завершение без проверки доступности
if [[ -n "$DRY_RUN" ]]; then
    echo "deploy: пробный запуск, состояние сервера не изменено"
    exit 0
fi

# 5. Проверка доступности с проверкой сертификата
if ! curl -fsS --cacert "$CA_CERT" -o /dev/null --max-time 10 "$SITE_URL/"; then
    err "ресурс ${SITE_URL} недоступен после доставки"
    exit 1
fi

echo "deploy: доставлен коммит $(git rev-parse --short HEAD)"
exit 0
