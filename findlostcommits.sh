#!/bin/bash
# I got unsubscribed to the lkml mailing list; I needed to check which commits
# I don't have in my maildir commit dir. This is it.

readonly DIR='/home/dcg/Correo/.linux-kernel.directory/commits/*/*'
readonly REPO='/home/dcg/código/linux'
export GIT_DIR=$REPO/.git
readonly REV='v5.8..v5.9-rc1'

COMMITS=$(git rev-list $REV --no-merges)
for commit in $COMMITS
do
	found="false"
	if ! grep --silent "X-Git-Rev: $commit" $DIR; then
		commitlist+=($commit)
	fi
done

mkdir -p missed

for i in "${commitlist[@]}"; do
	date=$(git show --no-patch --pretty=format:'%cD' $i)
	parent=$(git show --no-patch --pretty=format:"%P" $i)
	author=$(git show --no-patch --pretty=format:"%an" $i)
	comitter=$(git show --no-patch --pretty=format:"%cn" $i)
	subject=$(git show --no-patch --pretty=format:"%s" $i)

	echo "From FINDLOSTCOMMITS $(date +"%a %b %g %H:%M:%S %Y")
Date: $date
From: diegocg@gmail.com
To: diegocg@gmail.com
MIME-Version: 1.0
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
AuthorDate: 
Committer:  $comitter
CommitDate: 
$(git show --stat --patch $i)" > missed/$i.eml
done
