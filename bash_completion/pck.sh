_pck() 
{
	#init some variables
	#cur = last command
	#prev = previous command
	#compreply = completion result
	#comp_words = array of commands and subcommands and options
	local cur prev opts base
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	#list of basic commands
	opts="getpac bubble spec fastre"

	#try to match with basic
	case "${prev}" in
		getpac)
			#check if ~/.mypackages exists, if not, generate one
			test -e ~/.mypackages || osc -A https://api.opensuse.org my pkg > ~/.mypackages

			#check if ~/.mypackages is more than one day old, if yes, generate new one
			test $(find ~/.mypackages -mtime 1) && osc -A https://api.opensuse.org my pkg > ~/.mypackages

			local mypackages=$(cut -d'/' -f2 ~/.mypackages)
			COMPREPLY=( $(compgen -W "${mypackages}" -- ${cur}) )
			return 0
		;;
		bubble)
			local bubble_options="-t"
			COMPREPLY=( $(compgen -W "${bubble_options}" -- ${cur}) )
			return 0
		;;
		spec)
			local spec_commands="get rget set add merge"
			COMPREPLY=( $(compgen -W "${spec_commands}" -- ${cur}) )
			return 0
		;;
		fastre)
			local fastre_options="-v"
			COMPREPLY=( $(compgen -W "${fastre_options}" -- ${cur}) )
			return 0
		;;
		*)
		;;
	esac

	#if one before previous
	case "${COMP_WORDS[COMP_CWORD-2]}" in
		#was spec
		spec)
			#and previous
			case "${prev}" in
				#was add
				add)
					local add_commands="patch"
					COMPREPLY=( $(compgen -W "${add_commands}" -- ${cur}) )
					return 0
				;;
				#was set
				set)
					local set_commands="tag"
					COMPREPLY=( $(compgen -W "${set_commands}" -- ${cur}) )
					return 0
				;;
			esac
		;;
		*)
		;;
	esac

	#if second
	case "${COMP_WORDS[1]}" in
		#was getpac
		getpac)
			#and previous one
			case "${prev}" in
				#was --opensuse or -o
				--opensuse|-o)
					local opensuse_options="11 11.4 12 12.1"
					COMPREPLY=( $(compgen -W "${opensuse_options}" -- ${cur}) )
					return 0
				;;
				#was --suse or -s
				--suse|-s)
					local suse_options="9 10 11"
					COMPREPLY=( $(compgen -W "${suse_options}" -- ${cur}) )
					return 0	
				;;
				*)
				;;
			esac
			
			local getpac_options="-s --suse -o --opensuse -r --remove -f --factory -d --devel"
			COMPREPLY=( $(compgen -W "${getpac_options}" -- ${cur}) )
			return 0
		;;
		spec)
			case "${prev}" in
				patch)
					local patch_files=$(ls *.patch *.dif *.diff 2> /dev/null)
					COMPREPLY=( $(compgen -W "${patch_files}" -- ${cur}) )
					return 0
				;;
				*)
				;;
			esac
		;;
		*)
		;;
	esac

	#if none of previous match, but the command is not pck, exit
	if [[ $prev != "pck" ]]
	then
		return 0
	fi

	#complete basic commands
	COMPREPLY=($(compgen -W "${opts}" -- ${cur}))  
	return 0
}
complete -F _pck pck