. ~/lab/lib.sh; clear
r 'sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/devops.key -out /etc/ssl/certs/devops.crt -subj "/CN=devops.local" -addext "subjectAltName=DNS:devops.local" 2>&1 | tail -2'
r 'sudo ls -l /etc/ssl/private/devops.key /etc/ssl/certs/devops.crt'
r 'sudo -u www-data cat /etc/ssl/certs/devops.crt > /dev/null && echo "сертификат: доступен"'
r 'sudo -u www-data cat /etc/ssl/private/devops.key > /dev/null || echo "ключ: недоступен"'
git -C ~/repo pull -q
r 'sudo cp ~/repo/configs/nginx/devops-site /etc/nginx/sites-available/devops-site'
r 'sudo nginx -t && sudo systemctl reload nginx'
r 'sudo ss -tlnp | grep nginx'
