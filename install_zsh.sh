
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

# zshrc CHANGES
## P10K theme
echo -n "Run sed commands? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then # this grammar (the #[] operator) means that the variable $answer where any Y or y in 1st position will be dropped if they exist.
    echo "Running sed"
    sed -i '/ZSH_THEME=/ s/\".*\"/\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc 
    ## Plugins
    sed -i '/plugins=(git/ s/)/\n\tdocker\n\tdocker-compose\n\tssh-agent\n\tzsh-autosuggestions\n\tzsh-syntax-highlighting\n)/' ~/.zshrc 
    ## aliases
    sed -i '/# alias zshconfig=\"mate/ s/#//' ~/.zshrc 
    sed -i '/alias zshconfig=\"mate/ s/$/\nalias zshsource=\"source ~\/.zshrc\"/' ~/.zshrc
    sed -i '/# alias ohmyzsh=\"mate.*/ s/$/\nalias aupd=\"sudo apt update\"\nalias aupg=\"sudo apt upgrade\"/' ~/.zshrc
    sed -i 's/mate/nvim/' ~/.zshrc
else
    echo "Skipping Sed commands"
fi
source ~/.zshrc

