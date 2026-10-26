. ~/lab/lib.sh; clear
git -C ~/repo fetch -q && git -C ~/repo checkout -q feature/docker && git -C ~/repo pull -q
r 'sudo cp ~/repo/configs/nginx/devops-site /etc/nginx/sites-available/devops-site'
r 'grep -A6 "location /app/" /etc/nginx/sites-available/devops-site'
r 'sudo nginx -t && sudo systemctl reload nginx'
