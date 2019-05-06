#!/bin/bash
set -e
if [[ $# -ne 2 ]]
then
	echo "Not enough parameters"
	exit 1
fi

cd linux

echo "List of Linus merges from $1 to $2"
for i in $(git rev-list --author="Linus Torvalds" --merges --reverse $1..$2); do
	line=$(git show --pretty=medium $i | sed -n 8p)
	#echo $i, $line
	subsys=$(echo $line | grep -oP "(?<=[Pull|Merge] ).*?(?= from)")
	echo " * [[https://git.kernel.org/torvalds/c/$i|$subsys]]"
done
