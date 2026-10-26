. ~/lab/lib.sh; clear; cd ~/app
r 'cd ~/app && ls -la'
r 'docker build -t devops-app:1.0 . 2>&1 | tail -5'
r 'docker image ls devops-app'
r 'docker history devops-app:1.0'
