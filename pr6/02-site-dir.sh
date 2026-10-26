. ~/lab/lib.sh; clear
r 'sudo mkdir -p /var/www/devops-site'
r 'sudo chown -R devops:devops /var/www/devops-site'
r 'echo "<h1>devops.local: placeholder</h1>" | sudo -u devops tee /var/www/devops-site/index.html'
r 'namei -l /var/www/devops-site/index.html'
r 'sudo -u www-data cat /var/www/devops-site/index.html'
r 'sudo -u www-data touch /var/www/devops-site/test.html'
