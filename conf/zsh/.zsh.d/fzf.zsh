# Setup fzf
# ---------
if [[ ! "$PATH" == */home/mattis/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/home/mattis/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/mattis/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/mattis/.fzf/shell/key-bindings.zsh"
