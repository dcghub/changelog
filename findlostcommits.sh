#!/bin/bash
# I got unsubscribed to the lkml mailing list; I needed to check which commits
# I don't have in my maildir commit dir. This is it.

readonly DIR='/home/dcg/Correo/.linux-kernel.directory/commits/*/*'
readonly REPO='/home/dcg/código/linux'
export GIT_DIR=$REPO/.git

if [ $# -ne 2 ]; then
	echo "Wrong number of arguments"
	exit -1
fi
readonly REV="$1..$2"

export LANG='C' # It speeds up grep significantly
COMMITS=$(git rev-list $REV --no-merges)
for commit in $COMMITS
do
	found="false"
	if ! grep -F --silent "X-Git-Rev: $commit" $DIR; then
		commitlist+=($commit)
	fi
done

mkdir -p missed

for i in "${commitlist[@]}"; do
	committerdate=$(git show --no-patch --pretty=format:'%cD' $i)
	parent=$(git show --no-patch --pretty=format:"%P" $i)
	author=$(git show --no-patch --pretty=format:"%an" $i);
	author+=" <$(git show --no-patch --pretty=format:"%ae" $i)>"
	authordate=$(git show --no-patch --pretty=format:"%ad" $i)
	committer=$(git show --no-patch --pretty=format:"%cn" $i)
	committer+=" <$(git show --no-patch --pretty=format:"%ce" $i)>"
	subject=$(git show --no-patch --pretty=format:"%s" $i)

	echo "From FINDLOSTCOMMITS $(date +"%a %b %g %H:%M:%S %Y")
Date: $committerdate
From: diegocg@gmail.com
To: diegocg@gmail.com
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 8bit
X-Git-Rev: $i
X-Git-Parent: $parent
Subject: $subject

Commit:     $i
Parent:     $parent
Refname:    refs/heads/master
Web:        https://git.kernel.org/torvalds/c/$i
Author:     $author
AuthorDate: $authordate
Committer:  $committer
CommitDate: $committerdate

$(git show --stat --patch --pretty=format:"%s%n%n%b" $i)" > missed/$i.eml
done
