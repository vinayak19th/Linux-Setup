
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
echo -n "Update .zshrc with aliases and themes? (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Updating .zshrc"
    sed -i '' 's/^ZSH_THEME=".*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc 
    echo "Set theme to P10K"
    
    ## Plugins
    sed -i '' 's/^plugins=(git.*/plugins=(git docker docker-compose ssh-agent zsh-autosuggestions zsh-syntax-highlighting conda-zsh-completion)/' ~/.zshrc 
    echo "Added plugins"
    
    ## editors
    sed -i '' 's/mate/nvim/g' ~/.zshrc
    
    cat << 'EOF' >> ~/.zshrc

# Custom Aliases & Functions
alias zshsource="source ~/.zshrc"
alias bupd="brew update"
alias bupg="brew upgrade"
alias bupi="brew install"
alias tmux="tmux -u"
alias nvupdate="nvim +PlugUpdate +qall"

#Utility Functions 
gcomp(){
    git commit -m "$1" && git push
}
EOF
    echo "Appended custom aliases and functions"
else
    echo "Skipping .zshrc updates"
fi
source ~/.zshrc
