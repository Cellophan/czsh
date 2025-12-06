# https://github.com/ohmyzsh/ohmyzsh/blob/master/templates/zshrc.zsh-template
export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="robbyrussell"
ZSH_THEME="czsh"

# Only for "big" machines...
if [[ "$(uname -m)" ==  "x86_64" ]]; then
    plugins=(
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
else
    plugins=(
        zsh-syntax-highlighting
    )
fi

# https://github.com/ohmyzsh/ohmyzsh?tab=readme-ov-file#advanced-topics
zstyle ':omz:update' frequency 28
zstyle ':omz:plugins:*' aliases no
source $ZSH/oh-my-zsh.sh

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

export HISTFILE=~/.zsh_history
export HISTSIZE=999999
export SAVEHIST=999999

# man zshoptions
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY
# setopt EXTENDED_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS

# # https://github.com/jeffreytse/zsh-vi-mode#initialization-mode
# ZVM_INIT_MODE=sourcing
# 
# # Menu in case of tab
# # zstyle ':completion:*:*:*:*:*' menu select
# zstyle ':completion:*' menu select
# 
# # CTRL-q
# # stty start '^-' stop '^-'
# unsetopt flow_control


# Right prompt
strlen () {
    FOO=$1
    local zero='%([BSUbfksu]|([FB]|){*})'
    LEN=${#${(S%%)FOO//$~zero/}}
    echo $LEN
}
# show right prompt with date ONLY when command is executed
preexec () {
    DATE=$( date +"# %H:%M:%S" )
    local len_right=$( strlen "$DATE" )
    len_right=$(( $len_right+1 ))
    local right_start=$(($COLUMNS - $len_right))

    local len_cmd=$( strlen "$@" )
    local len_prompt=$(strlen "$PROMPT" )
    local len_left=$(($len_cmd+$len_prompt))

    RDATE="\033[${right_start}C ${DATE}"

    if [ $len_left -lt $right_start ]; then
        # command does not overwrite right prompt
        # ok to move up one line
        echo -e "\033[1A${RDATE}"
    else
        echo -e "${RDATE}"
    fi
}


_has() {
  return $( whence $1 >/dev/null )
}

# CtrlR
ctrlr() {
  local selected
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases noglob nobash_rematch 2> /dev/null
  selected="$(printf '%s\t%s\000' "${(kv)history[@]}" | \
      perl -0 -ne 'if (!$seen{(/^\s*[0-9]+\**\t(.*)/s, $1)}++) { s/\n/\n\t/g; print; }' \
      | \
        FZF_DEFAULT_OPTS="--nth=2..,.. --scheme=history --height 40% --min-height 20 --bind=ctrl-z:ignore --bind=ctrl-r:toggle-sort ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} --no-multi --read0 --color light --no-mouse" \
        FZF_DEFAULT_OPTS_FILE='' \
      fzf)"
  ret=$?
  if [[ $ret -eq 0 ]]; then
    zle vi-fetch-history -n $(echo -n "${selected}" | cut -d\t -f1)
  fi
  zle reset-prompt
  return $ret
}
zle -N  ctrlr
bindkey "^r" ctrlr

# Clot
## fill screen with garbage, as visual separator
## taken from http://leahneukirchen.org/dotfiles/.zshrc
clot() {
  head -c $((LINES*COLUMNS)) </dev/urandom |
    LC_ALL=C tr '\0-\377' ${(l:256::.*o@:)} |
    fold -w $COLUMNS
}

# zz - smart directory changer
## inspired from http://leahneukirchen.org/dotfiles/.zshrc
## http://leahneukirchen.org/blog/archive/2017/01/zz-a-smart-and-efficient-directory-changer.html
chpwd_zz() {
  print -P '0\t%D{%s}\t1\t%~' >>~/.zz
}

zz() {
  gawk -v ${(%):-now='%D{%s}'} <~/.zz '
    function r(t,f) {
      age = now - t
      return (age<3600) ? f*4 : (age<86400) ? f*2 : (age<604800) ? f/2 : f/4
    }
    { f[$4]+=$3; if ($2>l[$4]) l[$4]=$2 }
    END { for(i in f) printf("%d\t%d\t%d\t%s\n",r(l[i],f[i]),l[i],f[i],i) }' |
    sort -k2 -n -r | sed 9000q | sort -n -r -o ~/.zz
  if (( $# )); then
    local p=$(fzf --filter="$@" --no-sort < ~/.zz | gawk '{ print $4; exit }')
    [[ $p ]] || return 1
    local op=print
    [[ -t 1 ]] && op=cd
    if [[ -d ${~p} ]]; then
      $op ${~p}
    else
      # clean nonexisting paths and retry
      while read -r line; do
        [[ -d ${~${line#*$'\t'*$'\t'*$'\t'}} ]] && print -r $line
      done <~/.zz | sort -n -r -o ~/.zz
      zz "$@"
    fi
  else
    sed 10q ~/.zz
  fi
}

## collect all chpwd_* hooks
chpwd_functions=( ${(kM)functions:#chpwd?*} )
alias z=' zz'

# Rest
alias ls='ls --color=tty'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias mz=' cd $(mktemp -d) && czsh'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias add='git add'
alias branch='git branch'
alias checkout='git checkout'
alias clean='git clean'
alias clone='git clone'
alias commit='git commit'
alias diff='git diff'
alias fetch='git fetch'
alias merge='git merge'
alias pull='git pull'
alias push='git push'
alias rebase='git rebase'
alias recommit='git recommit'
alias restore='git restore'
alias revert='git revert'
alias stash='git stash'
alias stash-all='git stash-all'
alias status='git status'
alias switch='git switch'
alias undo='git undo'

main() {
    git switch $(git branch -l main master | sed "s/^* //")
}
master() {
    git switch $(git branch -l main master | sed "s/^* //")
}

