. ~/lab/lib.sh; clear
sudo -iu devops bash /home/devops/lab/pr7/d12a-break.sh; sleep 2
r 'bash ~/repo/scripts/audit.sh | grep -E "5000|Пройдено"; echo "код возврата: ${PIPESTATUS[0]}"'
sudo -iu devops bash /home/devops/lab/pr7/d12b-restore.sh; sleep 2
r "ss -tln | grep -E ':(5000|5432)\b'"
