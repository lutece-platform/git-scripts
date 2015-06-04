#!/bin/bash
for filename in `find . -type d -name "lutece-*"`; do
	echo "--------------------------------------------------------------------------------"
	echo " Updating $filename "
	echo "--------------------------------------------------------------------------------"
	pushd $filename
	git checkout master && git pull origin master
	git checkout develop && git pull origin develop
        popd
	echo " "
done
