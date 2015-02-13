#!/bin/bash

DEVELOP="develop"

function currentBranch() {
	CURRENTBRANCH=$(git branch -l | grep '*' | cut -d ' ' -f 2)
}

function changeBranch() {
	if [ -z "$1" ]; then
		if [ "${CURRENTBRANCH}" == "master" -o "x${CURRENTBRANCH}" == "x" ]; then
			git checkout ${DEVELOP} -q
		else
			git checkout ${CURRENTBRANCH} -q
		fi
	else
		currentBranch
		gitOpts=""
		if [ -z "$(git branch -l | grep $1)" ]; then
			gitOpts="-b"
		fi
		git checkout ${gitOpts} "$1" -q
	fi
}

function runIt() {
	silence="> /dev/null 2>&1"
	echo -n "${1}... "
	shift
	while [ ! -z "$1" ]; do
		eval "$1 $silence"
		shift
	done
	[[ $? -eq 0 ]] && echo "done." || echo "failed."
}

function usage {
	echo "Usage: `basename $0`"
	echo "Just run !"
	exit 1
}

awkProg="/\"name\"/ { print substr(\$2,2,length(\$2)-3) }"
runIt "Retrieving projects list" "projects=(`curl -s https://api.github.com/orgs/lutece-platform/repos?per_page=1000 | awk "$awkProg" | grep "^lutece"`)"

for project in ${projects[*]} 
do
	echo "project : $project"
	category=`echo ${project} | cut -d '-' -f 2`
	if [[ ${category} == "core" ]]
	then
		path="${project}"
	else
		path="plugins/${category}/${project}"
	fi
	if [ ! -d "${path}" ]; then
		echo "Clone this project before !"
		continue
	fi
	pushd "${path}" > /dev/null
	changeBranch ${DEVELOP}
	if [ -z "$(git branch -r | grep ${DEVELOP})" ]; then
		runIt "Creating ${DEVELOP} branch" "git push origin ${DEVELOP}"
	else
		runIt "Update ${DEVELOP} branch" "git pull origin ${DEVELOP}"
	fi
	changeBranch
	popd > /dev/null
done
