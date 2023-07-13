# Quick Set up for Fresh Distro Installs

This script installs the following:
- Basic Apt Packages
- Nvim (and configs)
- ZSH (and configs)
- Ancaconda (and exported envs)
- Docker

A complete set of details can be found in the [Full Installation Details](#full-installation-details) section

---


## Usage Instructions:
#### Step 1: cd into and give run permissions to both scripts:
```bash
git clone https://github.com/vinayak19th/Linux-Setup.git
chmod +x ./install_bash.sh
```

#### Step 2: Install Meslo NF font:
You can find the font [here](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Meslo). Installation differs based on Distro

---

### Additional (Optional) Steps:
#### 1. VSCode Integrated Terminal Font:
You can find the detailed instructions [here](https://youngstone89.medium.com/how-to-change-font-for-terminal-in-visual-studio-code-c3305fe6d4c2). Remember to name the font as "Meslo NF" in the settings.json file. 
**EX:**
```json
{
    "terminal.integrated.fontFamily": "MesloLGS NF",
}
```

---
## Full installation Details:

* **Apt packages:**
  *  zsh 
  *  neovim 
  *  git 
  *  wget 
  *  curl 
  *  openssh-client 
  *  openssh-server

* **Nvim Configuration:**
  * Basic Key-Binds (see [init.vim](./nvim/init.vim))
  * Plug Install will run automatically with the following plugins:
    - Plug 'tpope/vim-sensible'
    - Plug 'junegunn/seoul256.vim'
    - Plug 'ryanoasis/vim-devicons'
    - Plug 'SirVer/ultisnips'
    - Plug 'honza/vim-snippets'
    - Plug 'scrooloose/nerdtree'
    - Plug 'preservim/nerdcommenter'
    - Plug 'mhinz/vim-startify'
    - Plug 'davidhalter/jedi-vim'
    - Plug 'jiangmiao/auto-pairs'
    - Plug 'neoclide/coc.nvim', {'branch': 'release'}
    - Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
    - Plug 'vim-airline/vim-airline'
    - Plug 'vim-airline/vim-airline-themes'

* **ZSH Configuration:**
  * Installs [Oh-My-Zsh](https://ohmyz.sh/)
  * Installs the following extensitions:
    - git
	- docker
	- docker-compose 
	- ssh-agent
	- conda-zsh-completion
	- zsh-autosuggestions
	- zsh-syntax-highlighting   
  * Install the [P10k Theme](https://github.com/romkatv/powerlevel10k)
  * Creates the following alias:
    - zshconfig="nvim ~/.zshrc"
    - zshsource="source ~/.zshrc"
    - aupd="sudo apt update"
    - aupg="sudo apt upgrade"
    - aupi="sudo apt install"
    - tmux="tmux -u"

* **Anaconda:**
    * Install Anaconda3-2023.03-1
    * Can set up all the envs exported to the [conda_env](./conda_env) folder, marked by the ENV_* files
    * Does the Conda init for ZSH

* **Docker:**
  * Installs docker using the convienient script from [get.docker.com](https://get.docker.com/)
    `curl -fsSL https://get.docker.com -o get-docker.sh`
  * Creates docker group and adds the current user to it