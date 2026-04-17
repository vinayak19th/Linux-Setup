#!/bin/bash
export SCRIPT_HOME=$PWD

# --- Arguments and Configuration ---
INSTALL_ZSH=true
INSTALL_NVIM=true
INSTALL_ANACONDA=true
INSTALL_CONDA_CONFIG=true
INSTALL_DOCKER=true
INSTALL_GHOSTTY=true
INSTALL_CONDA_ENVS=true
INSTALL_CORE=true
INSTALL_UV=true
SELECTIVE_MODE=false

show_help() {
    echo "Usage: ./install_basics.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --omz           Configure OH-MY-ZSH"
    echo "  --nvim          Config Nvim"
    echo "  --anaconda      Install Anaconda"
    echo "  --conda-config  Setup Conda libmamba solver"
    echo "  --docker        Install Docker"
    echo "  --ghostty       Install Ghostty"
    echo "  --uv            Install UV"
    echo "  --conda-envs    Set Anaconda Envs from backup"
    echo "  --core          Update brew and install basic packages"
    echo "  --all           Run all sections (default)"
    echo "  --interactive   Prompt for each section"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "If no options are provided, the script runs all sections by default."
}

# Parse flags
if [[ $# -gt 0 ]]; then
    # If any specific flags are provided, we start with everything disabled
    # Unless one of the flags is --all, in which case everything stays true
    
    # Check if --all or -h/--help is present to avoid disabling everything immediately
    if [[ ! "$*" == *"--all"* ]] && [[ ! "$*" == *"-h"* ]] && [[ ! "$*" == *"--help"* ]]; then
        INSTALL_ZSH=false
        INSTALL_NVIM=false
        INSTALL_ANACONDA=false
        INSTALL_CONDA_CONFIG=false
        INSTALL_DOCKER=false
        INSTALL_GHOSTTY=false
        INSTALL_UV=false
        INSTALL_CONDA_ENVS=false
        INSTALL_CORE=false
        SELECTIVE_MODE=true
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --omz)          INSTALL_ZSH=true; shift ;;
            --nvim)         INSTALL_NVIM=true; shift ;;
            --anaconda)     INSTALL_ANACONDA=true; shift ;;
            --conda-config) INSTALL_CONDA_CONFIG=true; shift ;;
            --docker)       INSTALL_DOCKER=true; shift ;;
            --ghostty)      INSTALL_GHOSTTY=true; shift ;;
            --uv)           INSTALL_UV=true; shift ;;
            --conda-envs)   INSTALL_CONDA_ENVS=true; shift ;;
            --core)         INSTALL_CORE=true; shift ;;
            --interactive)  SELECTIVE_MODE=false; INTERACTIVE=true; shift ;;
            --all)
                INSTALL_ZSH=true
                INSTALL_NVIM=true
                INSTALL_ANACONDA=true
                INSTALL_CONDA_CONFIG=true
                INSTALL_DOCKER=true
                INSTALL_GHOSTTY=true
                INSTALL_UV=true
                INSTALL_CONDA_ENVS=true
                INSTALL_CORE=true
                shift
                ;;
            -h|--help)      show_help; exit 0 ;;
            *)              echo "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
fi

should_run() {
    local flag_val=$1
    local prompt_msg=$2
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n "$prompt_msg (y/n)? "
        read answer
        if [ "$answer" != "${answer#[Yy]}" ] ;then
            return 0
        else
            return 1
        fi
    elif [[ "$SELECTIVE_MODE" == "true" ]]; then
        [[ "$flag_val" == "true" ]]
        return $?
    else
        # Default: Run everything
        return 0
    fi
}

# Ensure we are on the correct branch for the detected OS
./git-switch-by-os.sh || true

# --- Installation Steps ---


if should_run "$INSTALL_CORE" "Update brew and install core tools"; then
    cd ~
    brew update && brew upgrade
    brew install zsh neovim git wget curl
fi

echo -n "Script Home: "
echo $SCRIPT_HOME

if should_run "$INSTALL_ZSH" "Configure OH-MY-ZSH"; then
    cd $SCRIPT_HOME
    ./install_zsh.sh
fi

if should_run "$INSTALL_NVIM" "Config Nvim"; then
    cp ./nvim/init.vim ~/.config/nvim/init.vim
    nvim +PlugInstall +qall
    git config --global core.editor "nano"
fi

if should_run "$INSTALL_ANACONDA" "Install Anaconda"; then
    echo "Installing Anaconda"
    cd ~
    mkdir -p Dev_Tools && cd Dev_Tools
    OS_ARCH=$(uname -m)
    if [ "$OS_ARCH" = "arm64" ]; then
        CONDA_SCRIPT="Miniconda3-latest-MacOSX-arm64.sh"
    else
        CONDA_SCRIPT="Miniconda3-latest-MacOSX-x86_64.sh"
    fi
    wget https://repo.anaconda.com/miniconda/$CONDA_SCRIPT
    chmod +x $CONDA_SCRIPT
    ./$CONDA_SCRIPT
    ~/miniconda3/bin/conda init zsh
fi

if should_run "$INSTALL_CONDA_CONFIG" "Setup Conda Solver"; then
    echo "Setting up Conda to use mamba solver"
    source ~/.bashrc
    conda update -n base conda -y
    conda install -n base conda-libmamba-solver -y 
    conda config --set solver libmamba
fi

if should_run "$INSTALL_DOCKER" "Install Docker"; then
    echo "Installing Docker"
    cd ~/Dev_Tools
    brew install --cask docker
fi

if should_run "$INSTALL_GHOSTTY" "Install Ghostty"; then
    echo "Installing Ghostty"
    brew install --cask ghostty
    mkdir -p ~/.config/ghostty
    cp "$SCRIPT_HOME/ghosty_config.txt" ~/.config/ghostty/config
fi

if should_run "$INSTALL_UV" "Install UV"; then
    echo "Installing UV"
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi


if should_run "$INSTALL_CONDA_ENVS" "Set Anaconda Envs from backup"; then
    echo "Setting Up Conda Envs from Backups"
    cd $SCRIPT_HOME
    ./conda_envs/import_envs.sh
fi
