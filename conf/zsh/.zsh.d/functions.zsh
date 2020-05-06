# read orgmode files like manpages
#
function org() {
	pandoc -s -f org -t man "$*" | man -l -
}


# read markdown files like manpages
#
unalias md

function md() {
	pandoc -s -f markdown_github -t man "$*" | man -l -
}


# Generate project from Maven Archetype
#
function maven-generate() {
	NAME="$*"
	
	mvn archetype:generate -DgroupId=no.verida.$NAME \
		-DartifactId=$NAME \
		-Dpackage=no.verida.$NAME \
		-Dversion=1.0-SNAPSHOT
}


# FZF
#

export FZF_DEFAULT_OPTS='
  --color fg:15,bg:0,hl:2,fg+:15,bg+:8,hl+:10
  --color info:11,prompt:5,spinner:11,pointer:10,marker:208,header:15
'


fv() {
  local match linum file;
  match=$(\ag \
    --nobreak \
    --smart-case \
    --hidden  \
    -p ~/.agignore \
    --noheading . | fzf +m) &&

    linum=$(echo "$match" | cut -d':' -f2) &&
    file=$(echo "$match" | cut -d':' -f1) &&

    ${EDITOR:-vim} +$linum $file
}


fadd() {
  local files target toplevel
  toplevel=$(git rev-parse --show-toplevel) &&
  files=$(git ls-files --exclude-standard -m -o) &&
  target=$(echo "$files" | fzf -m --height=25%) &&
  while IFS='' read -r line || [[ -n "$line" ]]; do
    git add "${toplevel}/${line}"
  done <<< "$target"
}


# Discard selected files unstaged changes
# supports multiselect via [tab] as default
fdiscard() {
  local files target toplevel
  toplevel=$(git rev-parse --show-toplevel) &&
  files=$(git diff --name-only) &&
  target=$(echo "$files" | fzf -m -d $(( 2 + $(wc -l <<< "$files") ))) &&
  while IFS='' read -r line || [[ -n "$line" ]]; do
    git checkout "${toplevel}/${line}"
  done <<< "$target"
}


# Unstage selected files
# supports multiselect via [tab] as default
funstage() {
  local files target toplevel
  toplevel=$(git rev-parse --show-toplevel) &&
  files=$(git diff --name-only --cached) &&
  target=$(echo "$files" | fzf -m -d $(( 2 + $(wc -l <<< "$files") ))) &&
  while IFS='' read -r line || [[ -n "$line" ]]; do
    git reset HEAD -- "${toplevel}/${line}"
  done <<< "$target"
}


# diff selected file
fdiff() {
  local files target toplevel

  # get project root directory
  toplevel=$(git rev-parse --show-toplevel) &&

  # get modified files
  files=$(git diff --name-only) &&

  # Create tmux split with a height of the list of items
  target=$(echo "$files" | fzf -d $(( 2 + $(wc -l <<< "$files") )) +m) &&

  # run diff
  git diff "$toplevel/$target"
}


# fco - checkout git branch/tag
fco() {
  local tags branches target
  tags=$(
    git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
  branches=$(
    git branch --all | grep -v HEAD             |
    sed "s/.* //"    | sed "s#remotes/[^/]*/##" |
    sort -u          | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
  target=$(
    (echo "$tags"; echo "$branches") |
    fzf -l30 -- --no-hscroll --ansi +m -d "\t" -n 2) || return
  git checkout $(echo "$target" | awk '{print $2}')
}


# fcoc - checkout git commit
fcoc() {
  local commits commit
  commits=$(git log --graph --color=always --pretty=oneline --format="%C(auto)%h%d %s %C(black)%C(white)%cr" --abbrev-commit) &&
  commit=$(echo "$commits" | fzf --ansi +s +m -e) &&
  git checkout $(echo "$commit" | awk '{print $2}')
}


# fshow - git commit browser
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(white)%cr" "$@" |
  fzf --ansi --no-sort --tiebreak=index --bind=ctrl-s:toggle-sort \
    --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | vimpager') << 'FZF-EOF'
                {}
FZF-EOF"
}


# fsha - get git commit sha
# example usage: git rebase -i `fsha`
fsha() {
  local commits commit
  commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
  echo -n $(echo "$commit" | sed "s/ .*//")
}


# fstash - easier way to deal with stashes
# type fstash to get a list of your stashes
# enter shows you the contents of the stash
# ctrl-d shows a diff of the stash against your current HEAD
# ctrl-b checks the stash out as a branch, for easier merging
fstash() {
  local out q k sha
    while out=$(
      git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
      fzf --ansi --no-sort --query="$q" --print-query \
          --expect=ctrl-d,ctrl-b);
    do
      q=$(head -1 <<< "$out")
      k=$(head -2 <<< "$out" | tail -1)
      sha=$(tail -1 <<< "$out" | cut -d' ' -f1)
      [ -z "$sha" ] && continue
      if [ "$k" = 'ctrl-d' ]; then
        git diff $sha
      elif [ "$k" = 'ctrl-b' ]; then
        git stash branch "stash-$sha" $sha
        break;
      else
        git stash show -p $sha
      fi
    done
}


fapt() {
  local pkg=$(apt-cache search $1 | fzf --no-multi -q $1 --ansi --preview="apt-cache show {1}" | awk '{ print $1 }')

  if [[ $pkg ]]; then
    sudo apt-get install $pkg
  fi
}

# fif() {
  #if [ ! "$#" -gte 1 ]; then echo "Need a string to search for!"; return 1; fi
#  rg -i --files-with-matches --no-messages $1 | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 $1 || rg --ignore-case --pretty --context 10 $1 {}"
  #ag --nobreak --nonumbers --noheading --files-with-matches . | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 $1 || rg --ignore-case --pretty --context 10 $1 {}"
#}


#
# Generate random password
#
passgen() {
	passlength=$1

	[ ! -z "$passlength" ] || passlength=15

	< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${passlength};
	echo;
}
