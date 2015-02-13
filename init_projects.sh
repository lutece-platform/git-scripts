#!/bin/bash

# Variables
EMAIL=""
USERNAME=""
NAME=""

function getUserInfos() {
	while [ -z "${NAME}" ]; do
		read -p "Enter your first name and your last name : " NAME
	done
	while [ -z "${USERNAME}" ]; do
		read -p "Enter your github's username : " USERNAME
	done
	awkProg='/"email"/ {mail=substr($2, 2, length($2)-3)} /"primary"/ {primary=substr($2, 1, length($2)-1)} /"verified"/ {if ($2 == "true" && primary == "true") print mail}'
	EMAIL="$(curl -s -u $USERNAME https://api.github.com/user/emails | awk "$awkProg")"
	if [ -z "${EMAIL}" ]; then
		echo "You have to validate your primary email in github."
		exit 2
	fi
}

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

getUserInfos

awkProg="/\"name\"/ { project=substr(\$2,2,length(\$2)-3) } /\"$urltype\"/ { print project \";\" substr(\$2,2,length(\$2)-3)}"
projects=(`curl -s https://api.github.com/orgs/lutece-platform/repos?per_page=500 | awk "$awkProg" | grep "^lutece"`)

for projectandurl in ${projects[*]} 
do
	project=`echo ${projectandurl} | cut -d ';' -f 1`
	url=`echo ${projectandurl} | cut -d ';' -f 2`
	category=`echo ${project} | cut -d '-' -f 2`
	path="$(pwd -P)"
	if [[ ${category} == "core" ]]
	then
		path="${path}/${project}"
	else
		path="${path}/plugins/${category}/${project}"
	fi
	if [[ -d $path ]]
	then
		echo "${project} already cloned in ${path}"
	else
		echo "--------------------------------------------------------------------------------"
		echo " Cloning component : ${project}"
		echo "--------------------------------------------------------------------------------"
		git clone ${url} ${path}
		git --git-dir="${path}/.git" --work-tree="${path}" checkout -b develop
		git --git-dir="${path}/.git" --work-tree="${path}" pull origin develop
		git --git-dir="${path}/.git" --work-tree="${path}" config user.email "${EMAIL}"
		git --git-dir="${path}/.git" --work-tree="${path}" config user.name "${NAME}"
		echo " "
	fi
done;
