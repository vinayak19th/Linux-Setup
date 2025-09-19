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
    git config --global core.editor "nano"
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
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    chmod +x Miniconda3-latest-Linux-x86_64.sh
    ./Miniconda3-latest-Linux-x86_64.sh
    ~/miniconda3/bin/conda init zsh
else
    echo "Skipping Anaconda Install"
fi

echo -n "Setup Conda Solver? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then 
    echo "Setting up Conda to use mamba solver"
    source ~/.bashrc
    conda update -n base conda -y
    conda install -n base conda-libmamba-solver -y 
    conda config --set solver libmamba
else
    echo "Skipping Anaconda configuration"
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
