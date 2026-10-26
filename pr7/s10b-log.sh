. ~/lab/lib.sh
r 'sudo tail -n 3 /var/log/nginx/devops-site.error.log'
sudo -iu devops bash -c '. ~/lab/lib.sh; cd ~/app; r "docker compose start app"'
