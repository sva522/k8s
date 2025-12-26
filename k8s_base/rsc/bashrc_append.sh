PS1='\[\033[01;31m\]\u\[\033[01;32m\]@\[\033[01;33m\]\h\[\033[01;32m\]:\[\033[01;34m\]\w\[\033[00m\]\$'
if [ $(id -u) -eq 0 ]; then
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt"
else
    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/opt"
fi
export PATH

alias k=kubectl
alias ls='ls --color=auto'
alias ll='ls -l'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias bat=batcat
export EDITOR=nano
