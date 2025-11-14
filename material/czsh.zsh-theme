
_has() {
  return $( whence $1 >/dev/null )
}

dir_prompt() {
  echo -n "%F{blue}%B%(4~|%-1~/…/%2~|%3~)%F{clean}%b "
}

host_prompt() {
  if [[ -n ${SSH_CONNECTION} ]]; then
    if _has hostname && _has md5sum; then
      number=$(hostname | md5sum | gawk '//{ hex=sprintf("0x%s\n", $1); dec=sprintf("%s", strtonum(hex)); print(substr(dec, 0, 10))}')
      local emojis=(
        "👾" "👽" "👹" "♾️" "🦾" "🦹" "🧙" "🧘" "👣" "👥" 
        "🦍" "🐺" "🦓" "🦄" "🐮" "🦏" "🦇" "🐻" "🐸" "🦕"
        "🐋" "🐚" "🐙" "🐛" "🦠" "🌼" "🍀" "🍁" "🍄" "🍉"
        "🫐" "🥥" "🍏" "🌰" "🥦" "🥐" "🥖" "🥘" "🍵" "🏺"
        "🪵" "🪨" "🚂" "🚢" "✈️" "🚀" "🌀" "🌊" "🌈" "🤿"
      )
      index=$(( ${number} % ${#emojis[@]} ))
      echo -n "${emojis[$index]} "
    fi
  fi
 # "💡" "📎" "⚙️" "🧲" "📡" "☣️" "🛄"
}
HOST_PROMPT="$(host_prompt)"

container_prompt() {
  # if [[ -n "${CONTAINER_PROMPT:-}" ]]; then
  #   echo -n "${CONTAINER_PROMPT:-} "
  # else
    echo -n "📦 "
  # fi
}
CONTAINER_PROMPT="$(container_prompt)"

asdf_prompt() {
  if [[ -e ".asdf" || -e ".tool-versions" ]]; then
      echo -n "🛠️  "
  fi
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

status_prompt() {
  echo -n "%(?:🟩:⭕) "
}
STATUS_PROMPT="$(status_prompt)"

PROMPT="${STATUS_PROMPT}${HOST_PROMPT}${CONTAINER_PROMPT}$(dir_prompt)$(git_prompt)%B>%b "

