#!/bin/bash
set -e
if [[ $# -ne 2 ]]
then
       	echo "Not enough arguments"
	exit 1
fi

cd linux

echo "List of merge commits from $1 to $2"
for i in $(git rev-list --merges --reverse $1..$2);
do
	echo "[[https://git.kernel.org/torvalds/c/$i|merge]]";
	git show --pretty=medium --no-patch $i 
	echo
done



