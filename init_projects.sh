#!/bin/bash

projects=( lutece-core \
lutece-dev-plugin-codewizard \ 
lutece-dev-plugin-pluginwizard \
lutece-document-module-cmis \ 
lutece-elk-module-elasticsearch-head \
lutece-elk-module-elasticsearch-statsfilter \
lutece-elk-plugin-elasticsearch \ 
lutece-elk-plugin-kibana \
lutece-multimedia-plugin-phraseanet \
lutece-report-plugin-dataviz \
lutece-report-plugin-graphite \
lutece-seo-plugin-seo \
lutece-seo-module-seo-crm \
lutece-seo-module-seo-digglike \
lutece-seo-module-seo-document \
lutece-seo-module-seo-robots \
lutece-seo-module-seo-wiki \
lutece-seo-plugin-searchstats \
lutece-search-library-lucene \
lutece-site-plugin-gtools \
lutece-site-plugin-sitelabels \
lutece-system-plugin-jmx \
lutece-system-plugin-jmxtrans \
lutece-system-plugin-updater
);

for project in ${projects[*]} 
do
	category=`echo ${project} | cut -d '-' -f 2`
	if [[ ${category} == "core" ]]
	then
		path="${project}"
	else
		path="plugins/${category}/${project}"
	fi
	if [[ -d $path ]]
	then
		echo "${project} already cloned in ${path}"
	else
		echo "--------------------------------------------------------------------------------"
		echo " Cloning component : ${project}"
		echo "--------------------------------------------------------------------------------"
		url="https://github.com/lutece-platform/${project}.git"
		git clone ${url} ${path}
		echo " "
	fi
done;
