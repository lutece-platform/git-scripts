#!/bin/bash

## DON'T MODIFY !!! ##
CATEGORY=0
PROJECT=1
URL=2

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

getUserInfos
error $? "You have to validate your primary email in github."

projects=(`getProjectsAndUrls lutece-platform $CLONETYPE | grep "^lutece"`)

for projectandurl in ${projects[@]} ; do
	data=( $(echo $projectandurl | sed "s/^lutece\-\([^\-]*\)\(\-\([^;]*\)\)\{0,1\};\(.*\)$/\1 \3 \4/g") )
	if [ "${data[$CATEGORY]}" = "core" ]; then
		path="${BASEPATH}/lutece-core"
		# project is empty so URL is in PROJECT index
		data[$URL]="${data[$PROJECT]}"
		data[$PROJECT]="lutece-core"
	else
		path="${BASEPATH}/plugins/${data[$CATEGORY]}/${data[$PROJECT]}"
	fi
	# check if category changed...
	projectInfos "${data[$PROJECT]}"
	# if I have project locally...
	if [ ${#PROJECTINFO[@]} -gt 0 ]; then
		error "Updating component : ${data[$PROJECT]}"
		# if category changed...
		if [ "${data[$CATEGORY]}" != "${PROJECTINFO[$CATEGORY]}" ]; then
			mv "${PROJECTINFO[$URL]}" "$path"
			MESSAGES[${#MESSAGES[@]}]="Moved project ${data[$PROJECT]} from category ${PROJECTINFO[$CATEGORY]} to ${data[$CATEGORY]}"
		fi
		# try to update...
		# TODO: check if modifications not commited before changing branches...
		currentBranch="$(git rev-parse --abbrev-ref HEAD)"
		git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} master
		git --git-dir="${path}/.git" --work-tree="${path}" pull ${QUIET}
		git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} develop
		git --git-dir="${path}/.git" --work-tree="${path}" pull ${QUIET}
		git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} $currentBranch
echo "$path"
ls "$path"
		continue
	fi
	echo "--------------------------------------------------------------------------------"
	echo " Cloning component : ${data[$PROJECT]}"
	echo "--------------------------------------------------------------------------------"
	git clone ${QUIET} ${data[$URL]} ${path}
	git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} -b develop origin/develop
	git --git-dir="${path}/.git" --work-tree="${path}" pull ${QUIET}
	setUserInfos "${path}"
	error $?	"This path is not a git repository"
	echo " "
done
