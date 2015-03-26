#!/bin/bash
set -u

## variables
EMAIL=""
USERNAME=""
NAME=""
GITHOOKS=0
QUIET=("-q")
LOCALPROJECTS=()
PROJECTINFOS=()

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

# display usage then exit with code 2
function usage() {
	cat "${TMPDIR}/usage.txt"
	error 2 $@
}

function parseParams() {
	ACTION=""
	if [ $# -gt 0 ]; then
		act="$(echo $1 | tr '[A-Z]' '[a-z]')"
	else
		act=""
	fi
	for action in sync config; do
		if [ "$action" = "$act" ]; then
			ACTION="$action"
			break
		fi
	done
	if [  -z "$ACTION" ]; then
		usage "Unknown action: $act"
	fi
	shift
	CLONETYPE="clone_url"
	while getopts ":de:kt:u:" opt; do
		case $opt in
		d)
			QUIET=""
			;;
		e)
			EMAIL="$OPTARG"
			USERNAME="unused"
			;;
		k)
			GITHOOKS=1
			;;
		u)
			NAME="$OPTARG"
			;;
		t)
			case $(echo $OPTARG | tr '[A-Z]' '[a-z]') in
				git)
					CLONETYPE="git_url"
					;;
				ssh)
					CLONETYPE="ssh_url"
					;;
				http|https)
					CLONETYPE="clone_url"
					;;
				*)
					error 10 "$OPTARG is an invalid clone type"
			esac
			;;
		:)
			rror 2 "The option -$OPTARG requires an argument"
			;;
		h)
			usage
			;;
		esac
	done
	return $OPTIND
}

# get the path that we want to clone
# param1: number of the last argument
# param2: all arguments
function getPath() {
	let number=$1+1
	shift $number
	BASEPATH="`pwd -P`"
	if [ $# -gt 0 ]; then
		if [ -n "$1" -a -d "$1" ]; then
			BASEPATH="$( cd "$1" && pwd -P)"
		fi
	fi
}

function getUserInfos() {
	while [ -z "${NAME}" ]; do
		read -p "Enter your first name and your last name : " NAME
	done
	while [ -z "${EMAIL}" -a -z "${USERNAME}" ]; do
		read -p "Enter your github's username : " USERNAME
	done
	for attempt in 1 2 3; do
		if [ -n "${EMAIL}" ]; then
			break
		fi
		awkProg='/"email"/ {mail=substr($2, 2, length($2)-3)} /"primary"/ {primary=substr($2, 1, length($2)-1)} /"verified"/ {if ($2 == "true" && primary == "true") print mail}'
		EMAIL="$(curl -s -u $USERNAME https://api.github.com/user/emails | awk "$awkProg")"
	done
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
			cp "${TMPDIR}/hooks/${hook}" "${1}/.git/hooks/${hook}"
			chmod u+x "${1}/.git/hooks/${hook}"
		done
	fi
	return 0
}

# Retrieve list of projects already cloned
function getLocalProjects() {
	LOCALPROJECTS=()
	cd "${BASEPATH}"
	IFS=$'\n'; for gitDir in $(find -type d -name .git); do
		unset IFS
		path="$(cd "${BASEPATH}/$gitDir/.." && pwd -P)"
		project="$(basename "$path")"
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

## Starting scripts...
parseParams $@
nextParameter=$?
getPath $nextParameter $@
getLocalProjects
# set NAME and EMAIL with first already cloned repository if not set in command line
if [ -z "${NAME}" -a -z "${EMAIL}" -a ${#LOCALPROJECTS[@]} -gt 0 ]; then
	path="$(echo "${LOCALPROJECTS[0]}" | cut -d ';' -f 2)"
	NAME="$(git --git-dir="${path}/.git" --work-tree="${path}" config user.name)"
	EMAIL="$(git --git-dir="${path}/.git" --work-tree="${path}" config user.email)"
fi
source "${TMPDIR}/${ACTION}.sh"
