#!/bin/bash

projects=(`curl -s https://api.github.com/orgs/lutece-platform/repos | awk '/"name"/ { project=substr($2,2,length($2)-3) } /"clone_url"/ { print project ";" substr($2,2,length($2)-3)}' | grep "^lutece"`)

for projectandurl in ${projects[*]} 
do
	project=`echo ${projectandurl} | cut -d ';' -f 1`
	url=`echo ${projectandurl} | cut -d ';' -f 2`
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
		git clone ${url} ${path}
		echo " "
	fi
done;
