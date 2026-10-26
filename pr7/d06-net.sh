. ~/lab/lib.sh; clear; cd ~/app
r 'docker network ls'
r 'docker compose exec app getent hosts db'
r "ss -tln | grep -E ':(5000|5432)\b'"
