. ~/lab/lib.sh; clear
sudo -iu devops bash -c '. ~/lab/lib.sh; r "docker run -d --rm --name exposed -p 5001:5000 devops-app:1.0"'
r 'sudo ufw status | grep 5001'
r 'sudo iptables -t nat -L DOCKER -n | grep 5001'
