#updater commons
#Daniel Lovasko (dlovasko@suse.com)

#add pair to asociative array
function add_pair
{
	key=$1
	value=$2
	pairs[$key]=$value
}

#run every function to replace potentially obsoleted file
function run_pairs
{
	update_string=""

	#try every file
	for i in "${!pairs[@]}"
	do
		echo "file: $i"
		echo "func: ${pairs[$i]}"

		retval=$(${pairs[$i]} $i)

		#if we updated, add file and version info to update string used in osc vc
		if [[ $retval != "false" ]]
		then
			update_string=${update_string}$'\n'"$i updated to version $retval"	
		fi
	done

	#if something was updated
	if [[ -n $update_string ]]
	then
		pck spec set tag Version $retval
		osc ar
		osc vc -m "$update_string"
		osr sr
	fi

}

function do_update
{
	for directory in *
	do
		#skip patchinfo
		if [[ $directory = "patchinfo" ]]
		then
			continue
		fi

		#run tests in selected version
		cd $directory
			run_pairs
		cd ..
	done
}