#!/bin/bash

# Variables
EMAIL=""
USERNAME=""
NAME=""
GITHOOKS=0
BASEPATH="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd -P)"

# display error message in STDERR
# Parameter 1 : return code - if 0 did not display error otherwise display it.
# Parameter 2 : the error message
function error() {
	code="$1"
	# if not a number...
	if [ -z "$(echo "$code" | grep -E "^[0-9]+$")" ]; then
		echo $*
	else
		shift
		if [ $code -gt 0 ]; then
			echo $* >&2
			exit $code
		fi
	fi
}

function getUserInfos() {
	while [ -z "${NAME}" ]; do
		read -p "Enter your first name and your last name : " NAME
	done
	while [ -z "${USERNAME}" ]; do
		read -p "Enter your github's username : " USERNAME
	done
	awkProg='/"email"/ {mail=substr($2, 2, length($2)-3)} /"primary"/ {primary=substr($2, 1, length($2)-1)} /"verified"/ {if ($2 == "true," && primary == "true") print mail}'
	EMAIL="$(curl -s -u "$USERNAME" https://api.github.com/user/emails | awk "$awkProg")"
	if [ -z "${EMAIL}" ]; then
		return 2
	fi
	return 0
}

function setUserInfos() {
	if [ -z "$1" -o ! -d "$1" ]; then
		return 3
	fi
	git --git-dir="$1/.git" --work-tree="$1" config user.email "${EMAIL}"
	git --git-dir="$1/.git" --work-tree="$1" config user.name "${NAME}"
	if [ $GITHOOKS -ne 0 ]; then
		# add custom hooks
		# add new hook in this list; may be better to list folder?
		# check if chmod if allowed with git bash on Windows
		for hook in "commit-msg" "prepare-commit-msg"; do
			cp "${BASEPATH}/hooks/${hook}" "${1}/.git/hooks/${hook}"
			chmod u+x "${1}/.git/hooks/${hook}"
		done
	fi
	return 0
}

# retrieving all projects with url in format :
# project1;url1 project2;url2 ;...
# parameter 1 : the organization
# Parameter 2 : URL type
function getProjectsAndUrls() {
	error "Retrieving projects list..."
	getReposInfo "$1" "/\"name\"/ { project=substr(\$2,2,length(\$2)-3) } /\"$2\"/ { print project \";\" substr(\$2,2,length(\$2)-3)}"
	return $?
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
	return 0
}

function usage {
	echo "Usage: `basename $0` [-h][-k][-t git|ssh|https]"
	echo " -h: this help"
	echo " -k: enable git hooks"
	echo " -t: clone type; available: git, ssh, https, svn; default is https"
}

urltype="clone_url"
while getopts ":hkt:" opt; do
	case $opt in
		h)
			usage
			exit 2
			;;
		k)
			GITHOOKS=1
			;;
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
			error 1 "Option -$OPTARG requires an argument"
			usage
			exit 1
			;;
	esac
done

getUserInfos
error $? "You have to validate your primary email in github."

projects=(`getProjectsAndUrls lutece-platform "$urltype" | grep "^lutece"`)

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
	if [[ -d "$path" ]]
	then
		echo "${project} already cloned in ${path}"
	else
		echo "--------------------------------------------------------------------------------"
		echo " Cloning component : ${project}"
		echo "--------------------------------------------------------------------------------"
		git clone "${url}" "${path}"
		git --git-dir="${path}/.git" --work-tree="${path}" checkout -b develop
		git --git-dir="${path}/.git" --work-tree="${path}" pull origin develop
		git --git-dir="${path}/.git" --work-tree="${path}" branch --set-upstream-to=origin/develop
		setUserInfos "${path}"
		error $?	"This path is not a git repository"
		echo " "
	fi
done;
