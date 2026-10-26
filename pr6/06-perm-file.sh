. ~/lab/lib.sh; clear
F=/var/www/devops-site/index.html
r "sudo -u devops ls -la /var/www/devops-site/"
r "sudo -u devops chmod 600 $F"
r "curl -sk -o /dev/null -w '%{http_code}\n' https://localhost/ -H 'Host: devops.local'"
r "sudo -u www-data cat $F"
r "sudo tail -n 1 /var/log/nginx/devops-site.error.log"
r "sudo -u devops chmod 644 $F"
