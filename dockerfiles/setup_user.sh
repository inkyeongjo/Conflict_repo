#!/bin/bash

set -e

# 홈 디렉토리 생성
if [ ! -d "${HOME}" ]; then
    mkdir -p "${HOME}"
fi
    
# Only copy /etc/skel files if they don't exist in HOME
# This prevents overwriting user's custom settings
for item in /etc/skel/.*; do
    if [ -e "$item" ] && [ "$(basename "$item")" != "." ] && [ "$(basename "$item")" != ".." ]; then
        item_name=$(basename "$item")
        target_path="${HOME}/${item_name}"
        
        # Only copy if target doesn't exist
        if [ ! -e "$target_path" ]; then
            cp -r "$item" "$target_path"
        fi
    fi
done

# Create symbolic links for user files from /tmp/user to ${HOME}
if [ -d "/tmp/user" ]; then
    # Handle dotfiles specifically
    for item in /tmp/user/.*; do
        if [ -e "$item" ] && [ "$(basename "$item")" != "." ] && [ "$(basename "$item")" != ".." ]; then
            item_name=$(basename "$item")
            target_path="${HOME}/${item_name}"
            
            # Only create symlink if target doesn't exist
            if [ ! -e "$target_path" ]; then
                ln -s "$item" "$target_path"
            fi
        fi
    done
    
    # Handle regular files
    for item in /tmp/user/*; do
        if [ -e "$item" ]; then
            item_name=$(basename "$item")
            target_path="${HOME}/${item_name}"
            
            # Only create symlink if target doesn't exist
            if [ ! -e "$target_path" ]; then
                ln -s "$item" "$target_path"
            fi
        fi
    done
fi

# 기본 쉘 설정
echo SHELL_IN_CONTAINER: ${SHELL_IN_CONTAINER}
echo USER_NAME: ${USER_NAME}
echo GROUP_NAME: ${GROUP_NAME}
echo GROUP_ID: ${GROUP_ID}
echo USER_ID: ${USER_ID}

# chsh -s /bin/${SHELL_IN_CONTAINER} ${USER_NAME:-$USER}
exec /bin/${SHELL_IN_CONTAINER}
