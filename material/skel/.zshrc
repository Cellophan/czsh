# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="robbyrussell"
PRIMARY_FG='white'
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(docker fzf-zsh zsh-autosuggestions zsh-syntax-highlighting kubectl asdf)

#docker-compose
#z zsh-syntax-highlighting zsh-autosuggestions

source ${ZSH}/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='cvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

DEFAULT_USER=${USER}
VIRTUAL_ENV_DISABLE_PROMPT=true

# https://statico.github.io/vim3.html
# https://github.com/statico/dotfiles/blob/340c01d0970bc2cd6a27284ddb87774131c00e5c/.zshrc#L812-L829
_has() {
  return $( whence $1 >/dev/null )
}

# fzf + ag configuration
if _has fzf && _has ag; then
  export FZF_DEFAULT_COMMAND='ag -g ""'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  #export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='
  --color light
  --no-mouse
  '
fi

# # Python
# if [ -x "${PYENV_ROOT}/bin/pyenv" ]; then
#   export PYENV_ROOT="${HOME}/.pyenv"
#   export PATH="${PYENV_ROOT}/bin:${PATH}"
#   eval "$(pyenv init -)"
#   eval "$(pyenv virtualenv-init -)"
#   eval "$(pyenv init --path)"
# fi

# https://stackoverflow.com/questions/13125825/zsh-update-prompt-with-current-time-when-a-command-is-started
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

# clot - fill screen with garbage, as visual separator
# taken from http://leahneukirchen.org/dotfiles/.zshrc
clot() {
  head -c $((LINES*COLUMNS)) </dev/urandom |
    LC_ALL=C tr '\0-\377' ${(l:256::.*o@:)} |
    fold -w $COLUMNS
}

# zz - smart directory changer
# inspired from http://leahneukirchen.org/dotfiles/.zshrc
# http://leahneukirchen.org/blog/archive/2017/01/zz-a-smart-and-efficient-directory-changer.html
chpwd_zz() {
  print -P '0\t%D{%s}\t1\t%~' >>~/.zz
}

zz() {
  awk -v ${(%):-now='%D{%s}'} <~/.zz '
    function r(t,f) {
      age = now - t
      return (age<3600) ? f*4 : (age<86400) ? f*2 : (age<604800) ? f/2 : f/4
    }
    { f[$4]+=$3; if ($2>l[$4]) l[$4]=$2 }
    END { for(i in f) printf("%d\t%d\t%d\t%s\n",r(l[i],f[i]),l[i],f[i],i) }' |
      sort -k2 -n -r | sed 9000q | sort -n -r -o ~/.zz
  if (( $# )); then
    local p=$(fzf --filter="$@" --no-sort < ~/.zz | awk '{ print $4; exit }')
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

# collect all chpwd_* hooks
chpwd_functions=( ${(kM)functions:#chpwd?*} )
alias z=' zz'

setopt no_beep

# aliases
alias qr='qrencode -t UTF8'

alias add='git add'
alias branch='git branch'
alias checkout='git checkout'
alias clean='git clean'
alias clone='git clone'
alias commit='git commit'
alias cherry-pick 'git cherry-pick'
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
    git switch $(git branch -l master main | sed "s/^* //")
}

master() {
    git switch $(git branch -l master main | sed "s/^* //")
}

alias deploy='docker stack deploy'
alias down='docker-compose down'
alias logs='docker-compose logs'
alias service='docker service'
alias up='docker-compose up'

# alias aws='awsudo2 aws'
# alias terraform='awsudo2 terraform'
# alias plan='awsudo2 terraform plan -out the.tfplan'
# alias apply='awsudo2 terraform apply the.tfplan'

# inspired by https://www.atlassian.com/git/tutorials/dotfiles
alias dotfiles='git --git-dir=${HOME}/.dotfiles/ --work-tree=${HOME}'

alias jqcsv2json="jq --from-file /opt/payload/baggage/csv2json.jq"
alias jqflatten="jq --raw-output --from-file /opt/payload/baggage/flatten.jq"

#Customize Agnoster
prompt_dir() {
    prompt_segment blue $PRIMARY_FG ' %(4~|%-1~/…/%2~|%3~) '
}

prompt_container() {
    prompt_segment 'green' "$PRIMARY_FG" "${CONTAINER_PROMPT:- }"
}

prompt_asdf() {
    if [ -n "${ASDF_DATA_DIR:-}" ]; then
        if [ -d "${ASDF_DATA_DIR:-}" ]; then
            prompt_segment 'cyan' "$PRIMARY_FG" " asdf "
        elif [ -f ".tool-versions" ]; then
            prompt_segment 'cyan' "$PRIMARY_FG" " .tool-versions "
        fi
    fi

}

export AGNOSTER_PROMPT_SEGMENTS=("prompt_status" "prompt_container" "prompt_asdf" "${AGNOSTER_PROMPT_SEGMENTS[@]/prompt_status}")

SEGMENT_SEPARATOR="◤"
PLUSMINUS="±"
# BRANCH="\ue0a0"
BRANCH=""
DETACHED="➦"
CROSS="✘"
LIGHTNING="⚡"
GEAR="⚙"


# from shell to git repo in browser
alias wgh='xdg-open https://$(git config remote.origin.url | sed -e "s#^[^@]*@##" -e "s#\.git##" -e "s#:#/#")'


