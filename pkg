#!/bin/bash
#pkg - master command by dlovasko@suse.com

#un/comment for debug/release
#set -x

function pkg_help
{
	echo "master command for packaging utilities"
	echo "try pkg --list for list of subcommands"
	exit 1
}

function pkg_list
{
	echo "pkg subcommand list:"
	echo "  fastre/prep/unpack/u:unpack sources, build quilt series and apply patches"
	echo "  cleaner/c:tries to find out-of-date projects and report that"
	echo "  spec/s:specfile management - get/set tags, merge conflicting specfile, add patch"
	echo "  getpac/get/g:download packages for all or only some products, delete unwanted before checkout"
	echo "  patchinfo/p:fixed patchinfo, opens editor every time"
	echo "  waitforbuild/wfb/w:wait for build, checks build results in loop"
	echo "  rsr:recursive submit request - first submit to devel project and if everything goes well, submit to factory"
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

#check if the subcommand exists
curpath=$(readlink -f $0)
prefix=${curpath%/*}

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
