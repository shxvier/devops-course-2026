. ~/lab/lib.sh; clear; cd ~/app
r 'cd ~/app && cp .env.example .env && chmod 600 .env'
r 'sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$(openssl rand -hex 16)/" .env'
r 'ls -l .env && sed "s/=.*/=***/" .env'
