#!/bin/bash

# Flag-enabled options for:
RMD_COMPARE_FILENAMES=false # comparing filenames instead of file content
RMD_REMOVE_DUPLICATE=false  # removing duplicated file
RMD_CHOOSE_REMOVED=false    # chosing which file to remove. (Works only with RMD_REMOVE_DUPLICATE on.)

RMD_RED='\033[0;31m'
RMD_YELLOW='\033[1;33m'
RMD_LIGHT_BLUE='\033[1;34m'
RMD_RESET_COLOR='\033[0m'
RMD_BRED_ITALIC='\033[3;1;31m'

declare -A checksums
declare -A checksums_copy

# Shows help menu. Enabled by -h flag
rmd_help() {
    echo "RMD is is simple script that removes duplicated files in given directories"
    echo "USAGE:"
    echo "./rmd [-flags] ...args"
    echo "FLAGS:"
    echo "-h	Shows this help page."
    echo "-n	Compare filenames not file content."
    echo "-r	Remove one of duplicated files."
    echo "-c	Specify which file should be removed (Works only with -r enabled)"
    echo "ARGS:"
    echo "Args are files or directories that will be traversed and compared."
    echo ""
} >&1

rmd_make_hash_index() {
	# echo "Current dir: " $(pwd)
	for _arg_ in $@; do
		if [[ -d $_arg_ ]]; then
			cd $_arg_
			rmd_make_hash_index $(ls)
			cd ..
		elif [[ -f $_arg_ ]]; then
			checksums["$(pwd)/$_arg_"]=$(sha256sum $_arg_ | sed 's/ .*$//')
		fi
	done
}

# Displays info about similar files
rmd_info() {
	echo -e "${RMD_YELLOW}Found similar files:${RMD_RESET_COLOR}"
	echo -e "${RMD_LIGHT_BLUE}[1] $1${RMD_RESET_COLOR}"
	echo "$(stat --printf "%A\nOwner: %U\nLast access: %x\nLast modification: %y\nLast change: %z\nSize: %s bytes" $1)"
	echo -e "${RMD_LIGHT_BLUE}[2] $2${RMD_RESET_COLOR}"
	echo "$(stat --printf "%A\nOwner: %U\nLast access: %x\nLast modification: %y\nLast change: %z\nSize: %s bytes" $2)"
}

# Removes file using `rm`. Works only if -r flag is set (RMD_REMOVE_DUPLICATE == true)
# If -c flag is enabled (RMD_CHOOSE_REMOVED == true) it asks to choose file, otherwise removes the 2nd one.
rmd_remove() {
	if [[ $RMD_REMOVE_DUPLICATE == true && $RMD_CHOOSE_REMOVED == true ]]; then
		echo -e "${RMD_RED}Which file to remove? [1/2]${RMD_BRED_ITALIC} (or press other key to skip)${RMD_RESET_COLOR}"
		read -p "> " _option_
		case $_option_ in
			1) $(rm $1) ;;
			2) $(rm $2) ;;
			*) echo "Skipping...";;
		esac
	elif [[ $RMD_REMOVE_DUPLICATE == true ]]; then
		$(rm $2)
	fi
}

rmd_compare() {
	if [[ $RMD_COMPARE_FILENAMES == true ]]; then
		echo "Comparing filenames"
		for _first_ in ${!checksums[@]}; do
			# Set same path in copied array to 0
			checksums_copy[$_first_]=0
			
			for _second_ in ${!checksums_copy[@]}; do
				# Extract filenames from paths
				_trimmed_first_="$(echo $_first_ | sed "s/^.*\\/\\(.*\\)$/\\1/")"
				_trimmed_second_="$(echo $_second_ | sed "s/^.*\\/\\(.*\\)$/\\1/")"

				# If filenames are equal and haven't been compared yet.
				if [[ ("$_trimmed_first_" == "$_trimmed_second_") && (${checksums_copy[$_second_]} != 0) ]]; then
					rmd_info $_first_ $_second_
					rmd_remove $_first_ $_second_
				fi
			done
		done
	else
		for _first_ in ${!checksums[@]}; do
			for _second_ in ${!checksums_copy[@]}; do
				# Set same path in copied array to 0
				checksums_copy[$_first_]=0
				# Get hashes
				_hash_first_="${checksums[$_first_]}"
				_hash_second_="${checksums_copy[$_second_]}"

				# if hashes are equal and files haven't been compared yet.
				if [[ ("$_hash_first_" == "$_hash_second_") && ($_hash_second_ != 0) ]]; then
					rmd_info $_first_ $_second_
					rmd_remove $_first_ $_second_
				fi
			done
		done
	fi
}

# Check for flags in input args
while getopts "hnrc" flag; do
	case "${flag}" in
		h) rmd_help ;;
		n) RMD_COMPARE_FILENAMES=true ;;
		r) RMD_REMOVE_DUPLICATE=true ;;
		c) RMD_CHOOSE_REMOVED=true ;;
	esac
done

for path in $@; do
    rmd_make_hash_index $path
done

for key in "${!checksums[@]}"; do
	checksums_copy[$key]=${checksums[$key]}
done

rmd_compare