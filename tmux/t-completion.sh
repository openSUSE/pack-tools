_t-compl() 
{
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    opts=$(tmux list-sessions 2>/dev/null | cut -d: -f1)

    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))  
    return 0

}
complete -F _t-compl t
