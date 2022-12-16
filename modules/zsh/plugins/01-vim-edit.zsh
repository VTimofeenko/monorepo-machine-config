# vim style editing
bindkey -v

autoload edit-command-line; zle -N edit-command-line
bindkey -M vicmd E edit-command-line  # uppercase E to edit the current line
