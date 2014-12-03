#!/bin/bash

projects=(`curl -s https://api.github.com/orgs/lutece-platform/repos | awk '/"name"/ { print substr($2,2,length($2)-3) }' | grep lutece`)

for project in ${projects[*]} 
do
	category=`echo ${project} | cut -d '-' -f 2`
	if [[ ${category} == "core" ]]
	then
		path="${project}"
	else
		path="plugins/${category}/${project}"
	fi
	if [[ -d $path ]]
	then
		echo "${project} already cloned in ${path}"
	else
		echo "--------------------------------------------------------------------------------"
		echo " Cloning component : ${project}"
		echo "--------------------------------------------------------------------------------"
		url="https://github.com/lutece-platform/${project}.git"
		git clone ${url} ${path}
		echo " "
	fi
done;
