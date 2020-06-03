#!/bin/bash

# Flag-enabled options for:
RMD_COMPARE_FILENAMES=false # comparing filenames instead of file content
RMD_REMOVE_DUPLICATE=false  # removing duplicated file
RMD_CHOOSE_REMOVED=false    # chosing which file to remove. (Works only with RMD_REMOVE_DUPLICATE on.)

declare -A checksums

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
	_parent_=$(pwd)
	# echo "Current dir: " $(pwd)
	for _arg_ in $@; do
		echo "Arg: " $_arg_
		if [[ -d $_arg_ ]]; then
			cd $_arg_
			rmd_make_hash_index $(ls)
			cd ..
		elif [[ -f $_arg_ ]]; then
			checksums["$_parent_/$_arg_"]=$(sha256sum $_arg_ | sed 's/ .*$//')
		fi
	done
}

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

echo "Indexed"

for key in "${!checksums[@]}"; do
	echo "$key: ${checksums[$key]}"
done
