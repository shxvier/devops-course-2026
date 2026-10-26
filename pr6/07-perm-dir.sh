. ~/lab/lib.sh; clear
D=/var/www/devops-site
for p in 755 750 744 711; do
  r "sudo chmod $p $D && curl -sk -o /dev/null -w '$p -> %{http_code}\n' https://localhost/ -H 'Host: devops.local'"
  if [ $p = 744 ] || [ $p = 711 ]; then
    r "sudo -u www-data ls $D"
    r "sudo -u www-data cat $D/index.html | head -1"
  fi
done
r "sudo tail -n 1 /var/log/nginx/devops-site.error.log"
r "sudo chmod 755 $D && ls -ld $D"
