# vim style editing
bindkey -v

autoload my-edit-command-line; zle -N my-edit-command-line
bindkey -M vicmd jk my-edit-command-line  # jk chord to edit the current line
export CMD_EDITOR="vim-minimal"
