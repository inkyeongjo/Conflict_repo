#!/bin/bash
set -e

apt-get install zsh -y
# Install oh-my-zsh.
0>/dev/null sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
export ZSH_CUSTOM
# Configure plugins.
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}"/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git "${ZSH_CUSTOM}"/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-history-substring-search "${ZSH_CUSTOM}"/plugins/zsh-history-substring-search
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
apt install thefuck autojump -y

if ! grep -q "plugins=.*thefuck.*autojump" ${HOME}/.zshrc; then
    sed -i 's/^plugins=.*/plugins=(git\n extract\n thefuck\n autojump\n jsontools\n colored-man-pages\n zsh-autosuggestions\n zsh-syntax-highlighting\n zsh-history-substring-search\n you-should-use\n nvm\n debian\n fzf)/g' ${HOME}/.zshrc
fi

# Enable nvm plugin feature to automatically read `.nvmrc` to toggle node version.
if ! grep -q "zstyle.*omz:plugins:nvm.*autoload yes" ${HOME}/.zshrc; then
    sed -i "1s/^/zstyle ':omz:plugins:nvm' autoload yes\n/" ${HOME}/.zshrc
fi

# Install powerlevel10k and configure it.
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}"/themes/powerlevel10k

if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' ${HOME}/.zshrc; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ${HOME}/.zshrc
fi

# Move ".zcompdump-*" file to "$ZSH/cache" directory.
if ! grep -q "ZSH_COMPDUMP.*ZSH/cache" ${HOME}/.zshrc; then
    sed -i -e '/source \$ZSH\/oh-my-zsh.sh/i export ZSH_COMPDUMP=\$ZSH\/cache\/.zcompdump-\$HOST' ${HOME}/.zshrc
fi

# Configure the default ZSH configuration for new users.
if ! grep -q "p10k.zsh" ${HOME}/.zshrc; then
    echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> ${HOME}/.zshrc
fi

cp ${ZSH_CUSTOM}/themes/powerlevel10k/config/p10k-classic.zsh ${HOME}/.p10k.zsh

git clone https://github.com/junegunn/fzf.git ${HOME}/.fzf
${HOME}/.fzf/install --all

if ! grep -q "source.*devconfig" ${HOME}/.zshrc; then
    echo 'source ${HOME}/.devconfig' >> ${HOME}/.zshrc
fi

if ! grep -q "source.*devconfig" ${HOME}/.bashrc; then
    echo 'source ${HOME}/.devconfig' >> ${HOME}/.bashrc
fi

# .zshrc 상단에 CURSOR_AGENT 환경변수 체크 및 환경설정 추가

if ! grep -q "CURSOR_AGENT" "${HOME}/.zshrc"; then
    # 임시 파일 생성
    cat > /tmp/cursor_agent_check << 'EOF'
if [[ $CURSOR_AGENT ]]; then
  export TERM=xterm-256color
  export LANG=en_US.UTF-8
  return
fi

EOF
    # 기존 .zshrc 내용을 임시 파일에 추가하고 원본으로 복사
    cat /tmp/cursor_agent_check ${HOME}/.zshrc > /tmp/new_zshrc && mv /tmp/new_zshrc ${HOME}/.zshrc
    rm -f /tmp/cursor_agent_check

fi

