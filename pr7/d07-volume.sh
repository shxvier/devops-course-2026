. ~/lab/lib.sh; clear; cd ~/app
r 'curl -s http://127.0.0.1:5000/'
r 'docker compose down'
r 'docker volume ls'
r 'docker compose up -d 2>&1 | tail -2'; sleep 5
r 'curl -s http://127.0.0.1:5000/'
r 'docker compose down -v'
r 'docker compose up -d 2>&1 | tail -2'; sleep 6
r 'curl -s http://127.0.0.1:5000/'
