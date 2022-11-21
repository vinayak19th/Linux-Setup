#!/bin/bash
export SCRIPT_HOME=$PWD

cd ~
sudo apt update && sudo apt upgrade -y
sudo apt install zsh neovim git wget curl openssh-client openssh-server -y

echo $SCRIPT_HOME

# ANACONDA INSTALL
echo -n "Configure OH-MY-ZSH? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then # this grammar (the #[] operator) means that the variable $answer where any Y or y in 1st position will be dropped if they exist.
    cd $SCRIPT_HOME
    ./install_zsh.sh
else
    echo "Skipping OH-MY-ZSH Configuration"
fi

# ANACONDA INSTALL
echo -n "Install Anaconda? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then # this grammar (the #[] operator) means that the variable $answer where any Y or y in 1st position will be dropped if they exist.
    echo "Installing Anaconda"
    cd ~
    mkdir Dev_Tools && cd Dev_Tools
    wget https://repo.anaconda.com/archive/Anaconda3-2021.11-Linux-x86_64.sh
    chmod +x Anaconda3-2021.11-Linux-x86_64.sh
    ./Anaconda3-2021.11-Linux-x86_64.sh
    ~/anaconda3/bin/conda init zsh
else
    echo "Skipping Anaconda Install"
fi

# Docker INSTALL
echo -n "Install Docker? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then # this grammar (the #[] operator) means that the variable $answer where any Y or y in 1st position will be dropped if they exist.
    echo "Installing Docker"
    cd ~/Dev_Tools
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo groupadd docker
    sudo usermod -aG docker $USER
    sudo apt install docker-compose -y
else
    echo "Skipping Docker Install"
fi
