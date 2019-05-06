#!/bin/fish

set gitrepo ~/código/linux

if test (count $argv) != 2
	echo "Wrong number of parameters"
	echo "\"v5.1 v5.2-rc1\""
	exit 1
end


if test -e changelog.txt
	echo "changelog.txt exist, quitting"
	exit 1
end

echo "Generating lists for changes from $argv[1] to $argv[2]"

./changelog.py > changelog.txt
echo "Merges from $argv[1] to $argv[2]" > listofmerges.txt
./listmergesfromlinus.sh $argv[1] $argv[2] $gitrepo >> listofmerges.txt
./listallmerges.sh $argv[1] $argv[2] $gitrepo >> listofmerges.txt

