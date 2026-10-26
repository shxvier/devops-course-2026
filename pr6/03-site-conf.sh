. ~/lab/lib.sh; clear
git -C ~/repo fetch -q && git -C ~/repo checkout -q feature/web-deploy && git -C ~/repo pull -q
r 'sudo cp ~/repo/configs/nginx/devops-site.http /etc/nginx/sites-available/devops-site'
r 'sudo ln -s /etc/nginx/sites-available/devops-site /etc/nginx/sites-enabled/'
r 'sudo rm /etc/nginx/sites-enabled/default'
r 'sudo nginx -t && sudo systemctl reload nginx'
r 'ls -l /etc/nginx/sites-enabled/'
