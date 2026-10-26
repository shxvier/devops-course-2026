. ~/lab/lib.sh; clear
r 'sudo tail -n 10 /var/log/nginx/devops-site.access.log'
r "sudo awk '{print \$9}' /var/log/nginx/devops-site.access.log | sort | uniq -c | sort -rn"
