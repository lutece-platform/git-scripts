#!/bin/bash

function usage {
	echo "Usage: `basename $0` [-t git|ssh|https]"
	echo " -t: clone type; default is https"
}

urltype="clone_url"
while getopts ":t:" opt; do
	case $opt in
		t)
			case $OPTARG in
				git)
					urltype="git_url"
					;;
				ssh)
					urltype="ssh_url"
					;;
				https)
					urltype="clone_url"
					;;
				*)
					echo "Invalid clone type $OPTARG" >&2
					usage
					exit 1
			esac
			;;
		:)
			echo "Option -$OPTARG requires an argument" >&2
			usage
			exit 1
			;;
	esac
done

awkProg="/\"name\"/ { project=substr(\$2,2,length(\$2)-3) } /\"$urltype\"/ { print project \";\" substr(\$2,2,length(\$2)-3)}"
projects=(`curl -s https://api.github.com/orgs/lutece-platform/repos?per_page=100 | awk "$awkProg" | grep "^tools"`)

for projectandurl in ${projects[*]} 
do
	project=`echo ${projectandurl} | cut -d ';' -f 1`
	url=`echo ${projectandurl} | cut -d ';' -f 2`
	category=`echo ${project} | cut -d '-' -f 2`
	if [[ "${category}" == "core" ]]
	then
		path="${project}"
	else
		path="tools/${category}/${project}"
	fi
	if [[ -d "$path" ]]
	then
		echo "${project} already cloned in ${path}"
	else
		echo "--------------------------------------------------------------------------------"
		echo " Cloning component : ${project}"
		echo "--------------------------------------------------------------------------------"
		git clone "${url}" "${path}"
		echo " "
	fi
done;
