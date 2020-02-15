#!/usr/bin/env bash

set -e

# A script to setup dev tools for newly installed linux.
# Don't run via 'sudo'
# For now just suport ubuntu.

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
DOCKER_CONF_FILE=/etc/docker/daemon.json
export PATH

install_requirements(){
    echo '--> Update apt mirrors to Ali mirrors'
    sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
    sudo sed -i 's#\(//\)\([a-zA-Z]*.ubuntu\)#\1mirrors.aliyun#' /etc/apt/sources.list

    echo '--> Initial apt-get update'
    sudo apt-get update -qq >/dev/null

    if ! dpkg -l | grep -q software-properties-common; then
        echo '--> Installing software-properties-common'
        sudo apt-get install -qq -y software-properties-common
    fi

    if ! command -v curl &>/dev/null; then
        echo '--> Installing curl'
        sudo apt-get install curl -y -qq
    fi
}

install_git(){
    if ! command -v git &>/dev/null; then
        echo '--> Installing git'
        sudo apt-get update -qq && apt install git make -y -qq
    fi
}

install_zsh(){
    if ! command -v zsh &>/dev/null; then
        echo '--> Installing zsh'
        sudo apt install zsh -y

        echo '--> Installing oh-my-zsh'
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        echo '--> Installing zsh autosuggestion plugin'
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        sudo sed -i 's/\(^plugins=([^)]*\)/\1 zsh-autosuggestions/' $HOME/.zshrc

        echo '--> Setting default shell to zsh'
        if ! chsh -s "$(which zsh)"; then
            echo '--> chsh command unsuccessfully, change your default shell manually'
        else
            echo '--> Shell successfully changed to zsh, you may logout to use zsh shell'
        fi
    fi
}

install_docker(){
    if ! command -v docker &>/dev/null; then
        echo '--> Installing docker-ce'
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
            "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
            $(lsb_release -cs) \
            stable"
        sudo apt-get update -qq
        sudo apt-get install -y docker-ce

        echo '--> Setting current user to docker group'
        sudo usermod -aG docker $USER

        echo '--> Changing docker registry mirrors'
        if ! test -f "$DOCKER_CONF_FILE"; then
            sudo touch "$DOCKER_CONF_FILE"
        fi
        sudo tee "$DOCKER_CONF_FILE" <<-'EOF' 
{
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com"
  ]
}
EOF

        echo '--> Restarting docker'
        sudo service docker restart

    fi
}

main(){
    install_requirements
    install_git
    install_zsh
    install_docker
}

main "$@"