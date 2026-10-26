# под student: клонирует хелперы для devops
sudo -iu devops bash -c 'git clone -q -b lab-helpers https://github.com/shxvier/devops-course-2026 ~/lab 2>/dev/null || git -C ~/lab pull -q; ls ~/lab/pr7 | head -3'
