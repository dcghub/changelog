#!/bin/fish

echo "Downloading all changelogs from kernelnewbies"
set baseurl https://kernelnewbies.org/
set suffix "?action=raw"


set urllist LinuxVersions
set urllist $urllist "Linux_2_6_"(seq 0 39)
set urllist $urllist "Linux_3."(seq 0 19)
set urllist $urllist "Linux_4."(seq 0 20)
set urllist $urllist "Linux_5."(seq 0 11)

for url in $urllist
	curl -s $baseurl$url$suffix > archive/$url
	echo "Downloaded $baseurl$url$suffix"
end
