#!/usr/bin/env bash

set -e

# A script to setup dev tools for newly installed linux.
# For now just suport debian buster.

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

install_requirements(){
    echo '--> Update apt mirrors to Ali mirrors'
    mv /etc/apt/sources.list /etc/apt/sources.list.bak

    echo 'deb http://mirrors.aliyun.com/ubuntu/ xenial main
deb-src http://mirrors.aliyun.com/ubuntu/ xenial main
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main
deb http://mirrors.aliyun.com/ubuntu/ xenial universe
deb-src http://mirrors.aliyun.com/ubuntu/ xenial universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates universe
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main
deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe
deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security universe' > /etc/apt/sources.list

    #echo '--> Installing apt-transport-https'
    # debian buster alreay has https package
    # apt-get install -qq -y apt-transport-https

    echo '--> Initial apt-get update'
    apt-get update -qq >/dev/null

    if ! dpkg -l | grep -q software-properties-common; then
        echo '--> Installing software-properties-common'
        apt-get install -qq -y software-properties-common
    fi

    if ! command -v curl &>/dev/null; then
        echo '--> Installing curl'
        apt-get install curl -y -qq
    fi
}

install_git(){
    if ! command -v git &>/dev/null; then
        echo '--> Installing git'
        apt-get update -qq && apt install git make -y -qq
    fi
}

install_zsh(){
    if ! command -v zsh &>/dev/null; then
        echo '--> Installing zsh'
        apt install zsh -y

        echo '--> Installing oh-my-zsh'
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        echo '--> Installing zsh autosuggestion plugin'
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        sed -i 's/\(^plugins=([^)]*\)/\1 zsh-autosuggestions/' $HOME/.zshrc
    fi
}

install_docker(){
    if ! command -v docker &>/dev/null; then
        echo '--> Installing docker'
        curl -fsSL https://get.docker.com | sh
        usermod -aG docker $USER

        echo '--> Starting docker'
        service docker start

        # Change docker mirrors
        echo '{
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com"
  ]
}' > /etc/docker/daemon.json

        echo '--> Restarting docker'
        service docker restart
    fi
}

main(){
    install_requirements
    install_git
    install_zsh
    install_docker

    chsh -s $(which zsh)
    echo '--> You SHOULD logout to change default shell to zsh!'
}

main "$@"