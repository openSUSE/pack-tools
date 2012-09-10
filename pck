#!/bin/bash
#pkg - master command by dlovasko@suse.com

#un/comment for debug/release
#set -x

#turn off globing - prevents package regexp pattern completion to local directory names, eg. '.*' -> '.osc'
set -f

function pkg_help
{
	echo "master command for packaging utilities"
	echo "try pck --list for list of subcommands"
	exit 1
}

function pkg_list
{
	echo "pck subcommand list:"
	echo "  fastre:unpack sources, build quilt series and apply patches"
	echo "  clean:tries to find out-of-date projects and report that"
	echo "  spec:specfile management - get/set tags, merge conflicting specfile, add patch"
	echo "  getpac:download packages for all or only some products, delete unwanted before checkout"
	echo "  patchinfo:fixed patchinfo, opens editor every time"
	echo "  clean:recursive submit request - first submit to devel project and if everything goes well, submit to factory"
	exit 1
}

#check for 0 args, then print help
if [ "$#" = "0" ] 
then
	pkg_help
fi

#run thru all the args, find first one which is subcommand
for i in `seq $#`
do
	if echo ${!i} | grep -qv '^-'
	then
		subcommand=${!i}
		break
	fi
done

#i now contains index in $@ of subcommand
let k=i-1
verbose=no

#save arguments for subcommand
if [ -n "$subcommand" ] 
then
#FIXME: this breaks escaped arguments - like 'foo "x y"' will end in two arguments 'x' and 'y'
	subargs=${@:$i:$#}
else
	let k=i
fi

#prepare arguments
eval set -- `getopt -a -o v --long verbose -o l --long list  -o h --long 'help' -- "${@:1:$k}"`

#process arguments for master command
while [ -n "$1" ]
do
	case $1 in
		-v|--verbose)
			verbose=yes
			shift
		;;
		-l|--list)
			pkg_list
		;;
		-h|--help)
			pkg_help
		;;
		--)
			break
		;;
	esac
done

#check if any subcommand

#echo "'$subargs'"
if [ -z "$subargs" ] 
then 
	exit 0
fi

#turn globing on for prefix creation
set +f

#check if the subcommand exists
curpath=$(readlink -f $0)
prefix=${curpath%/*}

#turn globing off to prevent unwanted completion in exec call
set -f

if [[ ${prefix} =~ ^/usr ]]
then
    libexecdir="${prefix}/lib/pack-tools/commands/"
else
    libexecdir="${prefix}/commands/"
fi

if [[ ! -e ${libexecdir}/${subcommand} ]]; then
    echo "ERROR: $subcommand does not exists, try ${0} --list for help"
    exit 1
fi

exec ${libexecdir}${subargs}
