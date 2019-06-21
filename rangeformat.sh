#!/bin/fish
if test (count $argv) != 2
	echo "Not enough parameters"
	exit 1
end

cd ~/código/linux

set commits (git rev-list $argv[1]..$argv[2])

for i in $commits
	git show -s --pretty='%H %s' $i
end

echo \nFound (count $commits) commits from $argv[1] to $argv[2] \n


for i in $commits
	echo -n "[[https://git.kernel.org/linus/$i|commit]]"
	if test $i != $commits[-1]
		echo -n ", "
	else
		echo -n \n
	end
end

