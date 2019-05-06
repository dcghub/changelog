#!/bin/fish
if test (count $argv) != 3
	echo "Not enough parameters"
	exit 1
end

cd $argv[3]

echo "List of Linus merges from $argv[1] to $argv[2]"
for i in (git rev-list --author="Linus Torvalds" --merges --reverse $argv[1]..$argv[2])
	set line (git show --pretty=medium $i | sed -n 8p)
	#echo $i, $line
	set subsys (echo $line | grep -oP "(?<=[Pull|Merge] ).*?(?= from)")
	echo " * [[https://git.kernel.org/torvalds/c/$i|$subsys]]"
end
