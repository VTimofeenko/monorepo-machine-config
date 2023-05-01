# vim style editing
bindkey -v

autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd jk edit-command-line  # jk chord to edit the current line
