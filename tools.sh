#!/bin/bash

# display error message in STDERR
# Parameter 1 : return code - if 0 did not display error otherwise display it.
# Parameter 2 : the error message
function error() {
	code="$1"
	# if not a number...
	if [ -z "$(echo "$code" | grep -E "^[0-9]+$")" ]; then
		echo $@
	else
		shift
		if [ $code -gt 0 ]; then
			echo $@ >&2
			customExit $code
		fi
	fi
}

# Retrieve list of projects already cloned
function getLocalProjects() {
	LOCALPROJECTS=()
	cd "${BASEPATH}"
	IFS=$'\n'; for gitDir in $(find -type d -name .git); do
		unset IFS
		path="$(cd "${BASEPATH}/$gitDir/.." && pwd -P)"
		project="$(basename "$path")"
		# check for old init_projects.sh
		if [ "$project" != "lutece-platform.github.io" -a "$project" != "lutece-core" ]; then
			if [[ "$project" == lutece-* ]]; then
				categoryPath="$(dirname "$path")"
				project="$(echo "$project" | sed 's/^lutece-[^\-]*-//g')"
				mv "$path" "${categoryPath}/$project"
			fi
		fi
		LOCALPROJECTS[${#LOCALPROJECTS[@]}]="${project};$path"
	done; unset IFS
	cd - > /dev/null
}

# get path of already cloned project
# Parameter 1: project name
# return 0 and set variable PROJECTINFO=( "category" "project name" "path" )
# or returns 1 if not cloned yet
function projectInfos() {
	PROJECTINFO=()
	if [ $# -gt 0 -a ${#LOCALPROJECTS[@]} -gt 0 ]; then
		IFS=$'\n'; for projectinfo in ${LOCALPROJECTS[@]}; do
		unset IFS
			project=( $(echo "$projectinfo" | sed "s/^\([^;]*\);\(.*\)$/\1 \2/g") )
			if [ "$1" = "${project[0]}" ]; then
				if [ "${project[0]}" = "lutece-core" ]; then
					category="core"
				elif [ "${project[0]}" = "lutece-platform.github.io" ]; then
					category="platform.github.io"
				else
					category="$(basename "`dirname "${project[1]}"`")"
				fi
				PROJECTINFO=( "$category" ${project[@]} )
				return 0
			fi
		done; unset IFS
	fi
	return 1
}

# retrieving all projects with url in format :
# project1;url1 project2;url2 ;...
# parameter 1 : the organization
# Parameter 2 : URL type
function getProjectsAndUrls() {
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

# add messages 
function addMessage() {
    if [ -n "$1" ]; then
	MESSAGES[${#MESSAGES[@]}]="$1"
    fi
}
