#!/bin/bash
set -e

if [[ $# -ne 2 ]]
then
	echo "Wrong number of parameters"
	exit 1
fi

if [[ -f changelog.txt ]]
then
	echo "changelog.txt exist, quitting"
	exit 1
fi

echo "Generating lists for changes from $1 to $2"
set -x

./changelog.py > changelog.txt
echo "Merges from $1 to $2" > listofmerges.txt
./listmergesfromlinus.sh $1 $2 >> listofmerges.txt
./listallmerges.sh $1 $2 >> listofmerges.txt

