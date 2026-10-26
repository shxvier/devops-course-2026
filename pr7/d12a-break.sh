. ~/lab/lib.sh; cd ~/app
r "sed -i 's/\"127.0.0.1:5000:5000\"/\"5000:5000\"/' docker-compose.yml && grep 5000 docker-compose.yml"
r 'docker compose up -d 2>&1 | tail -1'
