#!/bin/bash

if [ -z "${USERNAME}" ]; then
	NAME=""
	EMAIL=""
fi
getUserInfos
error $? "You have to validate your primary email in github."

for i in ${!LOCALPROJECTS[@]}; do
	path="$(echo "${LOCALPROJECTS[$i]}" | cut -d ';' -f 2)"
	setUserInfos "$path"
done
