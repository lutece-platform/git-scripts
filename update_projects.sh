#!/bin/bash
for filename in lutece-*/; do
	echo "--------------------------------------------------------------------------------"
	echo " Updating $filename "
	echo "--------------------------------------------------------------------------------"
	cd $filename
        git pull origin master
        cd .. 
	echo " "
done
