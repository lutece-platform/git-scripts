#!/bin/sh

git filter-branch --env-filter '

n=$GIT_AUTHOR_NAME
m=$GIT_AUTHOR_EMAIL

case ${GIT_AUTHOR_NAME} in
        "ILE") n="isabelle-lenain" ; m="isabelle-lenain@users.noreply.github.com" ;;
        "PLE") n="pierrelevy" ; m="pierrelevy@users.noreply.github.com" ;;
        "JGO") n="jgoulley" ; m="jgoulley@users.noreply.github.com" ;;
        "EJO") n="elysajouve" ; m="elysajouve@users.noreply.github.com" ;;
        "LHO") n="hohll" ; m="hohll@users.noreply.github.com" ;;
        "FME") n="FrancoisEricMerlin" ; m="FrancoisEricMerlin@users.noreply.github.com" ;;
        "LLI") n="l-lin" ; m="l-lin@users.noreply.github.com" ;;
        "TLA") n="tla-dev" ; m="tla-dev@users.noreply.github.com" ;;
        "RZA") n="rzara" ; m="rzara@users.noreply.github.com" ;;
        "PVN") n="varin-pierre" ; m="varin-pierre@users.noreply.github.com" ;;
        "MEV") n="evrard-maxime" ; m="evrard-maxime@users.noreply.github.com" ;;
        "MPR") n="MPROUX" ; m="MPROUX@users.noreply.github.com" ;;
        "ADU") n="adrien-duchemin" ; m="adrien-duchemin@users.noreply.github.com" ;;
        "ESO") n="esouquet" ; m="esouquet@users.noreply.github.com" ;;
        "NMO") n="NMO-SOPRA" ; m="NMO-SOPRA@users.noreply.github.com" ;;
        "VVO") n="V-V-" ; m="V-V-@users.noreply.github.com" ;;
        "VBR") n="vbroussard" ; m="vbroussard@users.noreply.github.com" ;;
        "VNO") n="vashista" ; m="vashista@users.noreply.github.com" ;;
        "AVA") n="arthur-vary-sinamale" ; m="arthur-vary-sinamale@users.noreply.github.com" ;;
        "JCH") n="jchaline" ; m="jchaline@users.noreply.github.com" ;;
esac

export GIT_AUTHOR_NAME="$n"
export GIT_AUTHOR_EMAIL="$m"
export GIT_COMMITTER_NAME="$n"
export GIT_COMMITTER_EMAIL="$m"
'
