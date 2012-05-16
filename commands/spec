#!/bin/bash
#spec parser (read&write) support by dlovasko@suse.com

#<sbrabec> Po %setup mohou být:
#<sbrabec> translation-update-upstream
#<sbrabec> gnome-patch-translation-prepare
#<sbrabec> A po posledním patchi:
#<sbrabec> gnome-patch-translation-update
#<sbrabec> Poznámka:
#<sbrabec> Uvažuji o spojení obou nástrojů a přejmenování na translation-tool-prepare and translation-tool-update.

#un/comment for debug/release

#set -x

function usage()
{
	echo "usage: spec subcommand [subcommand options]"
	echo "subcommands:"
	echo "   get [tag tagname] [specfile]"
	echo "   set [tag tagname oldval newval] [specfile]"	
	echo "   merge specfile1 specfile2 specfile_out"
	echo "   add [patch [specfile|patch options [specfile]]]"
	echo "   fixsles [specfile]"

	exit 1
}

if [ "$#" = 0 ]
then
	usage
fi

#argument 1 = specfile path
#argument 2 = what to get
function _pkg_spec_get
{
	if [[ "$2" == %* ]]
	then
		if [[ "$2" =~ (description|prep|build|install|clean|pre|post|preun|postun|verifyscript|files)$ ]]
		then
			sed -n '/^'"$2"'/,/^$/p' "$1"
		fi
	fi
	if [ "$2" = "Version" ] 
	then
		grep -e "^$2" "$1" | head -n 1
	else
		grep -e "^$2" "$1"
	fi
}


case $1 in
	get)
		if [ "$2" = "-h" -o "$2" = "--help" ]
		then
				echo "usage: pkg spec get WHAT [SPECFILE]"
				echo "when no specfile specified, specfile is deduced from .osc/_package"
				exit 1
		fi

		if [ -z "$3" ]
		then
			specfile=`cat .osc/_package | sed 's/\..*//'`.spec
		else
			specfile="$3"
		fi
			
		_pkg_spec_get "$specfile" "$2"
		
		
	;;
	rget)
		if [ "$2" = "-h" -o "$2" = "--help" ]
		then
				echo "usage: pkg spec rget PACKAGE WHAT"
				exit 1
		fi
		
		_spec=$(mktemp)

		_develproject=$(osc -A https://api.opensuse.org meta pkg openSUSE:Factory $2 | xpath /package/devel/@project 2> /dev/null | sed -e 's/project=//' -e 's/"//g' -e 's/^ //')
		osc -A https://api.opensuse.org cat $_develproject/$2/$2.spec > $_spec 2> /dev/null
		echo "$_develproject:"
		_pkg_spec_get "$_spec" "$3"
		echo

		osc -A https://api.opensuse.org cat openSUSE:Factory/$2/$2.spec > $_spec 2> /dev/null
		echo "Factory:"
		_pkg_spec_get "$_spec" "$3"
		echo

		osc -A https://api.opensuse.org cat openSUSE:12.1:Update/$2/$2.spec > $_spec 2> /dev/null
		echo "openSUSE 12.1: "
		_pkg_spec_get "$_spec" "$3"
		echo

		osc -A https://api.opensuse.org cat openSUSE:11.4:Update/$2/$2.spec > $_spec 2> /dev/null
		echo "openSUSE 11.4: "
		_pkg_spec_get "$_spec" "$3"
		echo

		osc -A https://api.suse.de cat SUSE:SLE-11-SP2:Update:Test/$2/$2.spec > $_spec 2> /dev/null
		echo "SUSE-SLE 11-SP2: "
		_pkg_spec_get "$_spec" "$3"
		echo

		osc -A https://api.suse.de cat SUSE:SLE-10-SP4:Update:Test/$2/$2.spec > $_spec 2> /dev/null
		echo "SUSE-SLE 10-SP4: "
		_pkg_spec_get "$_spec" "$3"
		echo

		osc -A https://api.suse.de cat SUSE:SLE-9-SP4:Update:Test/$2/$2.spec > $_spec 2> /dev/null
		echo "SUSE-SLE 9-SP4: "
		_pkg_spec_get "$_spec" "$3"
		echo

		rm -f $_spec
	;;
	set)
		case $2 in
			tag)
				# $3 tag name/--help
				# $4 old value
				# $5 new value
				# $6 specfile

				if [ -z "$6" ]
				then
					specfile=`cat .osc/_package | sed 's/\..*//'`.spec
				else
					specfile="$6"
				fi

				oldval=`grep ^$3 $specfile | tr -s ' ' | sed 's/^'"$3: "'//'`
				if [ "$4" != "$oldval" ] 
				then
					echo "old value supplied does not match the actual value, sorry"
					exit 1
				fi
				sed -r -i s/\(^$3:\\s+\)$4$/\\1$5/g $specfile
				exit 0
			;;
			-h|--help)
				echo "usage: pkg spec set tag [OLD_VALUE] [NEW_VALUE] [SPECFILE]"
				echo "when no specfile specified, specfile is deduced from .osc/_package"
				exit 1
			;;
		esac
	;;
	add)
		case $2 in
			patch)
			#parse arguments
			if [ "$3" = "-h" -o "$3" = "--help" ]
			then
				echo "usage: ..."
				exit 1
			fi 

			patchname="$3"

			if [ -z "$4" ]
			then
				specfile=`cat .osc/_package | sed 's/\..*//'`.spec
			else
				case $4 in
					*.spec)
						specfile="$4"
					;;
					*)
						options="$4"
						if [ -z "$5" ]
						then
							specfile=`cat .osc/_package | sed 's/\..*//'`.spec
						else
							specfile="$5"
						fi
					;;
				esac
			fi

			grep -q '^Patch[0-9]*' $specfile
			retcode=$?

			#if there is no patch yet
			if [ $retcode = 1 ]
			then
				#find last source
				linenum=`cat $specfile | grep -n '^Source[0-9]*' | tail -n 1 | sed 's/:.*$//'`
	
				#edit with sed
				let linenum=linenum+1
				sed -i "${linenum} i Patch0:         $patchname" $specfile

				#find end of prep phase
				linenum=`cat $specfile | grep -n '^%prep' | tail -n 1 | sed 's/:.*$//'`
				while [ -n "`sed -n "${linenum}p" $specfile`" ]
				do 
					let linenum=linenum+1 ; 
				done

				#edit with sed
				sed -i "${linenum} i %patch0 $options" $specfile

			else
				#find last patch
				linenum=""
				patchnum=""

				linenum=`cat $specfile | grep -n '^Patch[0-9]*' | tail -n 1 | sed 's/:.*$//'`
				patchnum=`cat $specfile | grep -o '^Patch[0-9]*' | tail -n 1 | sed 's/^Patch//'`

				let patchnum=patchnum+1
				let linenum=linenum+1
	
				sed -i "${linenum} i Patch$patchnum:         $patchname" $specfile

				#find last patch in prep phase
				linenum=""
				patchnum=""
				linenum=`cat $specfile | grep -n '^%patch[0-9]*' | tail -n 1 | sed 's/:.*$//'`
				patchnum=`cat $specfile | grep -o '^%patch[0-9]*' | tail -n 1 | sed 's/^%patch//'`

				let patchnum=patchnum+1
				let linenum=linenum+1

				sed -i "${linenum} i %patch${patchnum} $options" $specfile
			fi
		esac
	;;
	merge)
		# $2 = specfile 1 - in
		# $3 = specfile 2 - in
		# $4 = specfile 3 - out

		if [ "$2" = '-h' -o "$2" = '--help' ]
		then
			echo "usage: ..."
			exit 1
		fi

		last1="$(cat $2 | grep ^Patch[0-9]* | tail -n 1)"
		last2="$(cat $3 | grep ^Patch[0-9]* | tail -n 1)"

		num1="$(echo $last1 | grep -o ^Patch[0-9]* | sed 's/Patch//')"
		num2="$(echo $last2 | grep -o ^Patch[0-9]* | sed 's/Patch//')"

		name1="$(echo $last1 | tr -s ' ' | grep -o ' .*$')"
		name2="$(echo $last2 | tr -s ' ' | grep -o ' .*$')"

		#if specfiles have the last patch with the same number
		if [ "$num1" = "$num2" ]
		then
			#check if files are different
			if [ "$name1" != "$name2" ]
			then
				#write to $3 both patches, one incremented
				let newnum2=num2+1
		
				cp $2 $4
				newlast2="$(echo "$last2" | sed "s/Patch$num2/Patch$newnum2/")"
				echo "$last1"
				echo "$newlast2"
				sed -i "/$last1/ a\
				$newlast2" $4
			fi
		fi
		exit 0
	;;

	fixsles|fixrelease|fix)
		if [ "$2" = '-h' -o "$2" = '--help' ]
		then
			echo "usage: pkg spec fixsles [specfile]"
			exit 1
		fi

		if [ -n "$2" ]
		then
			specfile="$2"
		else
			specfile=`cat .osc/_package | sed 's/\..*//'`.spec
		fi
		
		sed -i 's/^Release.*$/Release:        0/g' $specfile
	;;

	-h|--help)
		usage
	;;
esac