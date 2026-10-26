. ~/lab/lib.sh; clear
r 'systemctl status nginx --no-pager | head -4'
r 'sudo ss -tlnp | grep nginx'
r 'ps -o user,pid,ppid,cmd -C nginx'
r 'sudo ufw status verbose'
r 'sudo ufw app list'
