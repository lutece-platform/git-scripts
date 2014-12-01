#!/bin/bash

if [ -z "$1" ]
  then
    echo "Arguments manquants :"
    echo " 1 - nom de la catégorie du SVN - ex : cms"
    echo " 2 - nom du plugin - ex : plugin-document"
    echo " 3 - (Facultatif) catégorie du repo dans Github - si absent utilisation de la catégorie SVN. "
    echo "Exemple de ligne de commande"
    echo "./import.sh cms plugin-document"
    exit
fi

category=$1

if [ ! -z "$3" ]
  then
      category=$3
fi

url="http://dev.lutece.paris.fr/svn/lutece/portal/trunk/plugins/$1/$2"
repo="https://github.com/lutece-platform/lutece-${category}-$2.git"
dir="lutece-$3-$2"

echo "Récupération du SVN ${url}"
git svn clone ${url} ${dir}
cd ${dir}
echo "Liste de auteurs"
git shortlog -s
echo "Conversion des auteurs"
../change_authors.sh
echo "Liste de auteurs"
git shortlog -s
git remote add origin ${repo}
git push -u origin master
cd ..

