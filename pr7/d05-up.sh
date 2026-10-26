. ~/lab/lib.sh; clear; cd ~/app
r 'docker compose up -d --build 2>&1 | tail -6'
sleep 3
r 'docker compose ps'
r 'for i in 1 2 3; do curl -s http://127.0.0.1:5000/; done'
