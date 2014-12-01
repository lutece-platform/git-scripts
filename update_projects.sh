#!/bin/bash
for filename in lutece-*/; do
	echo Update $filename
	cd $filename
        git pull origin master
        cd .. 
done
