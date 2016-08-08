#!/bin/bash

## Globals variables
# differring messages
MESSAGES=()
# quiet !
QUIET="-q"

# check if all utils are installed
function checkEnv() {
	for app in cp mv rm chmod find awk sed tr cut curl git; do
		if [ -z "`which $app 2>/dev/null`" ]; then
			printf "%-20s%s\n" "$app" "[!!]"
			echo "You have to install $app for running this script correctly." >&2
			customExit 2
		else
			printf "%-20s%s\n" "$app" "[ok]"
		fi
	done
}

# retrieve git tools in temp folder
function getScripts() {
	url="https://github.com/lutece-platform/tools-git-scripts"
	TMPDIR="/tmp/tmp.$$"
	git clone "$url" "${TMPDIR}" ${QUIET}
	# TODO: Comment it !
	# during development
	git --git-dir="${TMPDIR}/.git" --work-tree="${TMPDIR}" checkout -b develop origin/develop
#	rsync -a /home/cmarneux/svn/lutece/tools-git-scripts/ "${TMPDIR}"
	return $?
}

# clear temp folders/files then exit
# Param1: exit code
function customExit() {
	if [ ${#MESSAGES[@]} -gt 0 ]; then
		for i in ${!MESSAGES[@]}; do
			echo "${MESSAGES[i]}"
		done
	fi
	if [ -s "${TMPDIR}/`basename "$0"`" ]; then
		mode=`stat -c "%a" "$0"`
		cp "${TMPDIR}/`basename "$0"`" "$0"
		chmod $mode "$0"
	fi
	rm -Rf "${TMPDIR}"
	exit $1
}

checkEnv
getScripts
if [ $? -eq 0 ]; then
	if [ -s "${TMPDIR}/main.sh" ]; then
		source "${TMPDIR}/main.sh"
		customExit 0
	else
		echo "Error to find main script." >&2
		customExit 3
	fi
else
	echo "Error occured during git clone." >&2
	customExit 4
fi
