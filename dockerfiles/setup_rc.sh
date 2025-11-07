# PS1 설정

##################
# Color & PS1 #
##################

COLOR_NONE="\e[0m"
BLACK="\033[0;30m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
GRAY="\033[0;37m"
BOLD_RED="\033[1;31m"
BOLD_GREEN="\033[1;32m"
BOLD_YELLOW="\033[1;33m"
BOLD_BLUE="\033[1;34m"
BOLD_PURPLE="\033[1;35m"
BOLD_CYAN="\033[1;36m"
WHITE="\033[1;37m"

# git_branch 함수와 PS1 설정을 /etc/skel/.bashrc에 추가 (기본 설정만)
if [ ! -f /etc/skel/.bashrc ] || ! grep -q "git_branch()" /etc/skel/.bashrc; then
    cat << 'EOF' >> /etc/skel/.bashrc
source /usr/share/bash-completion/completions/git
git_branch() {
	local git_branch=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'`
	echo -en "$git_branch"
}
EOF
fi

PS1="\[$BOLD_GREEN\][\[$BOLD_YELLOW\]\u\[$BOLD_GREEN\]@\[$BOLD_BLUE\]\h:\[$BOLD_RED\]"'`pwd`'"\[$BOLD_GREEN\]] "'`git_branch`'" \[$GRAY\]\t\n\[$BOLD_GREEN\]"'\$'"\[$COLOR_NONE\] "

if [ ! -f /etc/skel/.bashrc ] || ! grep -q "PS1=" /etc/skel/.bashrc; then
    echo "PS1='${PS1}'" >> /etc/skel/.bashrc
fi

if [ ! -f /etc/skel/.zshrc ] || ! grep -q "TERM=xterm-256color" /etc/skel/.zshrc; then
    echo "export TERM=xterm-256color" >> /etc/skel/.zshrc
fi

if [ ! -f /etc/skel/.zshrc ] || ! grep -q "LANG=en_US.UTF-8" /etc/skel/.zshrc; then
    echo "export LANG=en_US.UTF-8" >> /etc/skel/.zshrc
fi

if [ ! -f /etc/skel/.bashrc ] || ! grep -q "LANG=en_US.UTF-8" /etc/skel/.bashrc; then
    echo "export LANG=en_US.UTF-8" >> /etc/skel/.bashrc
fi

chmod -R 777 /etc/skel/