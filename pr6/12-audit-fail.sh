. ~/lab/lib.sh; clear
r 'CERT_MIN_DAYS=400 bash ~/repo/scripts/audit.sh | grep -E "Сертификат|Пройдено"; echo "код возврата: ${PIPESTATUS[0]}"'
r 'sudo -u devops chmod 666 /var/www/devops-site/index.html'
r 'bash ~/repo/scripts/audit.sh | grep -E "записью|Пройдено"; echo "код возврата: ${PIPESTATUS[0]}"'
r 'sudo -u devops chmod 644 /var/www/devops-site/index.html'
