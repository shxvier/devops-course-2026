. ~/lab/lib.sh; clear; cd ~/app
r 'docker run -d --name app-test -p 127.0.0.1:5000:5000 devops-app:1.0'
sleep 2
r 'docker ps'
r 'curl -i http://127.0.0.1:5000/health'
r 'curl -si http://127.0.0.1:5000/ | head -1'
r 'docker logs app-test 2>&1 | grep -E "Error|refused|localhost" | tail -4'
r 'docker exec app-test id'
r 'docker rm -f app-test'
