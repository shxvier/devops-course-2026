. ~/lab/lib.sh; clear; cd ~/app
r 'grep Hello app.py'
r 'docker build --progress=plain -t devops-app:1.0 . 2>&1 | grep -E "^#[0-9]+ (\[|CACHED)"'
