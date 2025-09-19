
# OH MY ZSH UTILS
{
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
} || {
    echo "Oh OH MY ZSH installed already"
}
{
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
} || {
    echo "Oh P10K cloned already"
}
{
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
} || {
    echo "Oh zsh-autosuggestions cloned already"
}
{
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
} || {
    echo "Oh zsh-syntax-highlighting cloned already"
}

{
    git clone https://github.com/conda-incubator/conda-zsh-completion ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/conda-zsh-completion
} || {
    echo "conda-zsh-completion cloned already"
}



# zshrc CHANGES
## P10K theme
echo -n "Run sed commands? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then # this grammar (the #[] operator) means that the variable $answer where any Y or y in 1st position will be dropped if they exist.
    echo "Running sed"
    sed -i '/ZSH_THEME=/ s/\".*\"/\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc 
    echo "Set theme to P10K"
    ## Plugins
    sed -i '/plugins=(git/ s/)/\n\tdocker\n\tdocker-compose\n\tssh-agent\n\tzsh-autosuggestions\n\tzsh-syntax-highlighting\n\tconda-zsh-completion\n)/' ~/.zshrc 
    echo "Added plugins"
    ## aliases
    sed -i '/# alias zshconfig=\"mate/ s/#//' ~/.zshrc 
    sed -i '/alias zshconfig=\"mate/ s/$/\nalias zshsource=\"source ~\/.zshrc\"/' ~/.zshrc
    echo "Created config and source aliases"
    # Apt aliases and tmux 
    sed -i '/# alias ohmyzsh=\"mate.*/ s/$/\nalias aupd=\"sudo apt update\"\nalias aupg=\"sudo apt upgrade\"\nalias aupi=\"sudo apt install\"\nalias tmux=\"tmux -u\"/' ~/.zshrc
    echo "Created apt and tmux aliases"
    # NumaFix
    sed -i '/apt install\"/a alias numafix=\"sudo echo 0 | sudo tee -a \"/sys/bus/pci/devices/0000:01:00.0/numa_node\"\"' ~/.zshrc
    sed -i 's/mate/nvim/' ~/.zshrc
    echo "Created NumaFix alias"
    # Nvim Update
    sed -i '/tmux -u\"/a alias nvupdate=\"nvim +PlugUpdate +qall\"' ~/.zshrc
    echo "Created Nvim Update alias"
    # git_compush
    sed -i '/tmux -u\"/a #Utility Functions \ngcomp(){\n    git commit -m $1 && git push\n}'~/.zshrc
fi
else
    echo "Skipping sed commands"
fi
source ~/.zshrc
