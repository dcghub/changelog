#!/bin/fish

if test (count $argv) != 3
       	echo "Not enough arguments"
	exit 1
end

cd $argv[3]

echo "List of merge commits from $argv[1] to $argv[2]"
for i in (git rev-list --merges --reverse $argv[1]..$argv[2])
	echo "[[https://git.kernel.org/torvalds/c/$i|merge]]";
	git show --pretty=medium --no-patch $i 
	echo
end


