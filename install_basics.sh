#!/bin/bash
export SCRIPT_HOME=$PWD

cd ~
sudo apt update && sudo apt upgrade -y
sudo apt install zsh neovim git wget curl openssh-client openssh-server -y

echo $SCRIPT_HOME

# ANACONDA INSTALL
echo -n "Configure OH-MY-ZSH? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    cd $SCRIPT_HOME
    ./install_zsh.sh
else
    echo "Skipping OH-MY-ZSH Configuration"
fi

#Nvim Config
echo -n "Config Nvim? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
    cp ./nvim/init.vim ~/.config/nvim/init.vim
    nvim +PlugInstall +qall
else
    echo "Skipping Nvim Configs"
fi

# ANACONDA INSTALL
echo -n "Install Anaconda? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo "Installing Anaconda"
    cd ~
    mkdir Dev_Tools && cd Dev_Tools
    wget https://repo.anaconda.com/archive/Anaconda3-2023.03-1-Linux-x86_64.sh
    chmod +x Anaconda3-2023.03-1-Linux-x86_64.sh
    ./Anaconda3-2023.03-1-Linux-x86_64.sh
    ~/anaconda3/bin/conda init zsh
else
    echo "Skipping Anaconda Install"
fi

# Docker INSTALL
echo -n "Install Docker? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
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


# ANACONDA ENVS Set UP
echo -n "Set Anaconda Envs from backup? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo "Setting Up Conda Envs from Backups"
    cd $SCRIPT_HOME
    ./conda_envs/import_envs.sh
else
    echo "Skipping Anaconda Envs Set Up"
fi
