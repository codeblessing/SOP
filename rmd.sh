#!/bin/bash

# Flag-enabled options for:
RMD_COMPARE_FILENAMES=false # comparing filenames instead of file content
RMD_REMOVE_DUPLICATE=false  # removing duplicated file
RMD_CHOOSE_REMOVED=false    # chosing which file to remove. (Works only with RMD_REMOVE_DUPLICATE on.)

help() {
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

declare -a checksums

for path in $@; do
    if [ -d $path ]; then
        for subpath in $(ls $path); do
            CHECKSUM=$(sha256sum "$path/$subpath")
			echo $CHECKSUM
        done
    fi
done
CHECK=$(sha256sum test/lolly.txt)

echo $CHECK
