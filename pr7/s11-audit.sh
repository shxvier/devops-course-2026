. ~/lab/lib.sh; clear
git -C ~/repo pull -q
r 'bash ~/repo/scripts/audit.sh; echo "код возврата: $?"'
