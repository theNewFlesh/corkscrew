# requires: docker, dockviz, eza, git, parallel, rsync

source $ZSH_SCRIPTS/variables.sh

# generic tools
#alias activate="source activate"
#alias deactivate="source deactivate"
alias cat="bat"
alias pcat="bat --plain --color never"
alias rcat="bat --style rule"
alias xcat="bat --show-all"
alias df="df -h | grep -vE 'snap|tmpfs'"
alias grep="grep --color=auto"
alias l="eza --long --header"
alias ll="eza --long --header --all"
alias parallel="parallel --no-notice"
alias rsync="rsync -auHP"
alias tree="eza --tree --all"

# git
alias git-log-dev="git log --graph --oneline --decorate --all"
alias git-nomerge="git merge --no-commit --no-ff master"
alias git-bump="git commit --allow-empty -m 'bump'"

# docker
alias graph-docker-containers="dockviz containers -d | dot -Tpng -o /tmp/dcg.png && open /tmp/dcg.png"
alias graph-docker-images="dockviz images -d | dot -Tpng -o /tmp/dig.png && open /tmp/dig.png"
alias docker-state="echo 'container>image>network>volume>context>plugin' | sed 's/>/\n/g' | f 'docker {} ls'"
