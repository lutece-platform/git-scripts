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

function setUserInfos() {
	if [ -z "$1" -o ! -d "$1" ]; then
		echo "This path is not a git repository"
	fi
		git --git-dir="$1/.git" --work-tree="$1" config user.email "${EMAIL}"
		git --git-dir="$1/.git" --work-tree="$1" config user.name "${NAME}"
}

# retrieving all projects with url in format :
# project1;url1 project2;url2 ;...
# parameter 1 : the organization
# Parameter 2 : URL type
function getProjectsAndUrls() {
	getReposInfo "$1" "/\"name\"/ { project=substr(\$2,2,length(\$2)-3) } /\"$2\"/ { print project \";\" substr(\$2,2,length(\$2)-3)}"

}

# Retrieving all repos informations
# Parameter 1 : the organization
# Parameter 2 : awk argument
function getReposInfo() {
	if [ $# -lt 2 ]; then
		echo -n
		return 1
	fi
	org="$1"
	awkProg="$2"
	i=1
	# loop due to github API limitation (only 100 projects per request)
	while [ $i -ne 0 ]; do
		tmp=$(curl -s "https://api.github.com/orgs/${org}/repos?per_page=100&page=$i" | awk "${awkProg}")
		if [ "x$tmp" = "x" ]; then
		# no more result or max request exceeded
		# TODO: check if max limite is reacheed
			i=0
		else
			echo -n "$tmp "
			let i=$i+1
		fi
	done
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

projects=(`getProjectsAndUrls lutece-platform $urltype | grep "^lutece"`)

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
		git --git-dir="${path}/.git" --work-tree="${path}" branch --set-upstream-to=origin/develop
		setUserInfos "${path}"
		echo " "
	fi
done;
