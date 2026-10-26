. ~/lab/lib.sh; clear
r 'ls -la /var/www/devops-site/'
r 'find /var/www/devops-site -perm -o+w'
r 'sudo -u www-data touch /var/www/devops-site/index.html'
