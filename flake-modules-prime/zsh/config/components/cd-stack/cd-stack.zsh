setopt AUTOCD            # "./dirname" => "cd ./dirname"
setopt AUTO_PUSHD        # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS # Do not store duplicates in the stack.
setopt PUSHD_SILENT      # Do not print the directory stack after

# prints stack of directories
alias d='dirs -v'
# add cd +1..9 aliases for jumping back
for index ({1..9}) alias "$index"="cd +${index}"; unset index
