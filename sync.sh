#!/bin/bash

## DON'T MODIFY !!! ##
CATEGORY=0
PROJECT=1
URL=2
ORGANIZATION=3

getUserInfos
error $? "You have to validate your primary email in github."

error "Retrieving projects list..."
projects=(`getProjectsAndUrls lutece-platform "$CLONETYPE" | grep "^lutece"` `getProjectsAndUrls lutece-secteur-public "$CLONETYPE"`)

for projectandurl in ${projects[@]} ; do
	data=( $(echo "$projectandurl" | sed "s/^\([A-Za-z]*\)\-\([^\-]*\)\(\-\([^;]*\)\)\{0,1\};\(.*\)$/\2 \4 \5 \1/g") )
	if [ "${data[$CATEGORY]}" != "${CHOSEN_CATEGORY}" -a -n "${CHOSEN_CATEGORY}" ]; then
		continue
	fi
	if [ "${data[$CATEGORY]}" = "core" ]; then
		path="${BASEPATH}/lutece-core"
		# project is empty so URL is in PROJECT index
		data[$URL]="${data[$PROJECT]}"
		data[$PROJECT]="lutece-core"
	elif [ "${data[$CATEGORY]}" = "platform.github.io" ]; then
		path="${BASEPATH}/lutece-platform.github.io"
		# project is empty so URL is in PROJECT index
		data[$URL]="${data[$PROJECT]}"
		data[$PROJECT]="lutece-platform.github.io"
	else
		if [ "${data[ORGANIZATION]}" == "lutece" ]; then
			syncPath="${BASEPATH}/plugins"
		else
			syncPath="${BASEPATH}/plugins"
		data[$PROJECT]="${data[$CATEGORY]}-${data[$PROJECT]}"
		data[$CATEGORY]="${data[$ORGANIZATION]}"
		fi
		path="${syncPath}/${data[$CATEGORY]}/${data[$PROJECT]}"
	fi
	# check if category changed...
	projectInfos "${data[$PROJECT]}"
	# if I have project locally...
	if [ ${#PROJECTINFO[@]} -gt 0 ]; then
		error "Updating component : ${data[$PROJECT]}"
		# if category changed...
		if [ "${data[$CATEGORY]}" != "${PROJECTINFO[$CATEGORY]}" ]; then
			if [ -d "$path" ]; then
				MESSAGES[${#MESSAGES[@]}]="Can not moved project ${data[$PROJECT]} from category ${PROJECTINFO[$CATEGORY]} to ${data[$CATEGORY]} because $path already exists!"
			else
				mkdir -p "$(dirname "$path")"
				mv "${PROJECTINFO[$URL]%/}" "$path"
				MESSAGES[${#MESSAGES[@]}]="Moved project ${data[$PROJECT]} from category ${PROJECTINFO[$CATEGORY]} to ${data[$CATEGORY]}"
			fi # end if destination path already exists
		fi
		# try to update...
		# TODO: check if modifications not commited before changing branches...
		currentBranch="$(git --git-dir="${path}/.git" --work-tree="${path}" rev-parse --abbrev-ref HEAD)"
		if [ "$currentBranch" != "master" ]; then
			git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} master
		fi
		git --git-dir="${path}/.git" --work-tree="${path}" pull ${QUIET}
		git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} develop
		git --git-dir="${path}/.git" --work-tree="${path}" pull ${QUIET}
		if [ "$currentBranch" != "develop" ]; then
			git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} "$currentBranch"
		fi
	setUserInfos "${path}"
		continue
	fi
	echo "--------------------------------------------------------------------------------"
	echo " Cloning component : ${data[$PROJECT]}"
	echo "--------------------------------------------------------------------------------"
	git clone ${QUIET} "${data[$URL]}" "${path}"
	currentBranch="$(git --git-dir="${path}/.git" --work-tree="${path}" rev-parse --abbrev-ref HEAD)"
	if [ "$currentBranch" = "master" ]; then
		nextBranch="develop"
	elif [ "$currentBranch" == "develop" ]; then
		nextBranch="master"
	else
		MESSAGES[${#MESSAGES[@]}]="WARNING: No branch master or develop found in project ${data[$PROJECT]}"
		continue
	fi
	git --git-dir="${path}/.git" --work-tree="${path}" checkout ${QUIET} -b "$nextBranch" "origin/$nextBranch"
	status=$?
	if [ "$status" -eq 0 ]; then
		git --git-dir="${path}/.git" --work-tree="${path}" pull ${QUIET}
	elif [ "$status" -eq 128 ]; then
		MESSAGES[${#MESSAGES[@]}]="FATAL: the $nextBranch branch is missing in project ${data[$PROJECT]} in ${data[$CATEGORY]} category."
	else
		MESSAGES[${#MESSAGES[@]}]="FATAL: Unknown error in GIT in project ${data[$PROJECT]} in ${data[$CATEGORY]} category (return $status)."
	fi
	setUserInfos "${path}"
	error $?	"This path is not a git repository"
	echo " "
done
