#!/bin/fish
if test (count $argv) != 3
	echo "Not enough parameters"
	exit 1
end

cd $argv[3]

function parsecommitmsg
	set line (git show --pretty=medium --no-patch $argv[1] | sed -n 8p)
	#echo $i, $line
	set subsys (echo $line | grep -oP "(?<=[Pull|Merge] ).*?(?= from)")
	echo " * [[https://git.kernel.org/torvalds/c/$argv[1]|$subsys]]"
end



set list (git rev-list --author="Linus Torvalds" --merges --reverse $argv[1]..$argv[2])

echo "List of Linus merges from $argv[1] to $argv[2]"
for i in $list
	parsecommitmsg $i
end

echo "Changelog of merges from $argv[1] to $argv[2]"

for i in $list
	parsecommitmsg $i
	git show --pretty=medium --no-patch $i
end
