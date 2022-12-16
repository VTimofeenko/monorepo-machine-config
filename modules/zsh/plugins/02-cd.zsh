# File that sets the behavior of cd command
setopt autocd

# dirs stack manipulation
setopt AUTO_PUSHD           # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after

# Enabled cd +X to change directory to somewhere in stack
alias d='dirs -v' # prints stack of directories
for index ({1..9}) alias "$index"="cd +${index}"; unset index
