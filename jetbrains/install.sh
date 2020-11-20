#!/bin/bash

# THIS SHOULD BE RUN ONLY AFTER INTELLIJ AND PYCHARM ARE INSTALLED

# set -x
TIME="$(date +%Y%m%d%H%M%S)";
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLEANUPFILE="${1}";
[[ -z $CLEANUPFILE ]] && CLEANUPFILE="/dev/null";

for subdir in keymaps options
do
	pushd "${BASEDIR}/${subdir}";

	/bin/ls -1 *.xml | while read xmlfile
	do
		for pattern in PyCharm IntelliJ Gogland GoLand CLion DataGrip PhpStorm WebStorm ReSharper Rider RubyMine AppCode TeamCity Upsource
		do
            if [[ -e /Applications ]]
            then
			find /Applications -type d -maxdepth 1 -name "${pattern}*.app" | while read appdir
			do
				plist="${appdir}/Contents/Info.plist";
				prefsdir="${HOME}/Library/Preferences/$(/usr/libexec/PlistBuddy "${plist}" -c 'Print :JVMOptions:Properties:idea.paths.selector')"
				mkdir -p "${prefsdir}/${subdir}" &>/dev/null;
				[[ -e "${prefsdir}/${subdir}/${xmlfile}" ]] && mv "${prefsdir}/${subdir}/${xmlfile}" "${prefsdir}/${subdir}/${xmlfile}.dotfilebak.$TIME"  && echo "${prefsdir}/${subdir}/${xmlfile}.dotfilebak.$TIME" >> "${CLEANUPFILE}";
				echo "Linking ${prefsdir}/${subdir}/${xmlfile} to ${BASEDIR}/${subdir}/${xmlfile}";
				ln -sf "${BASEDIR}/${subdir}/${xmlfile}" "${prefsdir}/${subdir}/${xmlfile}";
			done
            fi
		done
	done

	popd
done
