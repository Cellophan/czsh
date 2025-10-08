# export ZSH="$HOME/.oh-my-zsh"
# # ZSH_THEME="robbyrussell"
# # ZSH_THEME="self"
# source $ZSH/oh-my-zsh.sh

export HISTFILE=~/.zsh_history
export SAVEHIST=999999

export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Menu in case of tab
# zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' menu select

# CTRL-q
# stty start '^-' stop '^-'
unsetopt flow_control

source /opt/local/zsh/fzf/completion.zsh
source /opt/local/zsh/fzf/key-bindings.zsh
# source /opt/local/zsh/zsh-autosuggestions.zsh


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

if _has fzf && _has ag; then
  export FZF_DEFAULT_OPTS="--layout=reverse"
  export FZF_CTRL_R_OPTS="--sort --exact"

  export FZF_DEFAULT_COMMAND='ag -g ""'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  #export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_DEFAULT_OPTS='--color light --no-mouse'
fi

host_prompt() {
  if [[ -n "${SSH_CLIENT}" || -n "${DOCKER_IMAGE}" ]]; then
    if _has hostname && _has md5sum; then
      number=$(hostname | md5sum | gawk '//{ hex=sprintf("0x%s\n", $1); dec=sprintf("%s", strtonum(hex)); print(substr(dec, 0, 10))}')
      local emojis=(
        "👾" "👽" "👹" "🫀" "🦾" "🦹" "🧙" "🧘" "👣" "👥" 
        "🦍" "🐺" "🦓" "🦄" "🐮" "🦏" "🦇" "🐻" "🐸" "🦕"
        "🐋" "🐚" "🐙" "🐛" "🦠" "🌼" "🍀" "🍁" "🍄" "🍉"
        "🫐" "🥥" "🍏" "🌰" "🥦" "🥐" "🥖" "🥘" "🍵" "🏺"
        "🪵" "🪨" "🚂" "🚢" "✈️" "🚀" "🌀" "🌊" "🌈" "🤿"
      )
      index=$(( ${number} % ${#emojis[@]} ))
      echo -n "${emojis[$index]} "
    fi
  fi
 # "💡" "📎" "⚙️" "🧲" "📡" "♾️" "☣️" "🛄"
}
export HOST_PROMPT=$(host_prompt)

container_prompt() {
  echo -n "%F{grey}%B"

  if [[ -n "${CONTAINER_PROMPT:-}" ]]; then
    echo -n "${CONTAINER_PROMPT:-} "
  elif [[ -n "${DOCKER_IMAGE:-}" ]]; then
    echo -n "📦 "
  fi

  echo -n "%F{clean}%b"
}
export CONTAINER_PROMPT=$(container_prompt)

precmd() {
  # red, blue, green, cyan, yellow, magenta, black, white
  # #008000
  # %F Foreground %K bacKground %U Underline %S
  # PROMPT="%1 %(?:🟩:⭕) %{%F{blue}%B%(4~|%-1~/…/%2~|%3~)%F{clean}%b"

  # STATUS="%(?:🟩:⭕) "
  STATUS="%(?:${HOST_PROMPT}:⭕ )"
  CURRENT_DIR="%{%F{blue}%B%(4~|%-1~/…/%2~|%3~)%F{clean}%b "

  PROMPT="${STATUS}${CONTAINER_PROMPT}${CURRENT_DIR}$(git_prompt)> "
}

git_prompt() {
  git status --show-stash --branch --porcelain=v2 2>/dev/null \
    | gawk '
    BEGIN {
        ORS = "";

        fatal = 0;
        oid = "";
        head = "";
        upstream = "";
        ahead = 0;
        behind = 0;
        untracked = 0;
        unmerged = 0;
        staged = 0;
        unstaged = 0;
        stashed = 0;

        branch = "";
    }

    $1 == "fatal:" {
        fatal = 1;
    }

    $2 == "branch.oid" {
        oid = $3;
    }

    $2 == "branch.head" {
        head = $3;
    }

    $2 == "branch.upstream" {
        upstream = $3;
    }

    $2 == "branch.ab" {
        ahead = $3;
        behind = $4;
    }

    $1 == "?" {
        ++untracked;
    }

    $1 == "u" {
        ++unmerged;
    }

    $1 == "1" || $1 == "2" {
        split($2, arr, "");
        if (arr[1] != ".") {
            ++staged;
        }
        if (arr[2] != ".") {
            ++unstaged;
        }
    }

    $2 == "stash" {
        stashed = $3;
    }

    END {
        if (fatal == 1) {
            exit(1);
        }

	detashed = 0;
        if (head == "(detached)") {
            branch = substr(oid, 0, 7);
	    detashed = 1;
        } else {
            branch = head;
        }

        # tracking_element(BEHIND, behind * -1);
        # tracking_element(AHEAD, ahead * 1);
        # local_element(UNMERGED, unmerged);
        # local_element(STAGED, staged);
        # local_element(UNSTAGED, unstaged);
        # local_element(UNTRACKED, untracked);

	color = ""
	symbol = ""
	clean = unmerged == 0 && staged == 0 && unstaged == 0 && untracked == 0

	if (branch != "") {
	    color = "green";

	    if (! clean) {
		color = "yellow";
		symbol = "±";
            }

	    if (detashed) {
                color = "black";
	    }

	    if (unstaged != 0) {
		color = "red";
		symbol = "±";
	    }

	    printf("%%B%%F{%s}%s%s%%F{clean}%%b ", color, symbol, branch);
        }
    }
    '
}

alias ls='ls --color=tty'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
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
