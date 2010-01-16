#!/usr/bin/env bash
# 
# uninstall script for icalBuddy
# (c) 2008-2010 Ali Rantakari
# 

BINFILE="icalBuddy"
MANFILE="icalBuddy.1"
L10NMANFILE="icalBuddyLocalization.1"
CONFIGMANFILE="icalBuddyConfig.1"


echo "================================="
echo
echo $'This script will \e[31mremove\e[m icalBuddy and related files from your system'
echo "(the icalBuddy binary executable, the man pages as well as configuration"
echo "and localization files)."
echo
echo $'We\'ll need administrator rights to remove some of these files so \e[33mplease'
echo $'enter your admin password when asked\e[m.'
echo $'\e[1mPress any key to continue uninstalling or Ctrl-C to cancel.\e[m'
read
echo
sudo -v
if [ ! $? -eq 0 ];then echo "error! aborting." >&2; exit 10; fi
echo


remove_if_exists()
{
	if [ -e "${1}" ]; then
		sudo rm -f "${1}"
		echo "${1}"
	else
		echo "false"
	fi
}


ERRORS="false"


REMOVED="false"
echo "* Removing executable..."
REMOVED=$(remove_if_exists "/usr/local/bin/${BINFILE}")
[ "${REMOVED}" == "false" ] && REMOVED=$(remove_if_exists "/Users/${USER}/bin/${BINFILE}")
[ "${REMOVED}" == "false" ] && REMOVED=$(remove_if_exists "/opt/local/bin/${BINFILE}")
[ "${REMOVED}" == "false" ] && REMOVED=$(remove_if_exists "`which ${BINFILE}`")
if [ "${REMOVED}" == "false" ]; then
	echo $'\e[31m  error: could not find executable in any standard location.\e[m'
	ERRORS="true"
else
	printf "\e[32m  removed from: ${REMOVED}\e[m\n"
fi


REMOVED="false"
echo "* Removing icalBuddy man page..."
REMOVED=$(remove_if_exists "/usr/local/share/man/man1/${MANFILE}")
[ "${REMOVED}" == "false" ] && REMOVED=$(remove_if_exists "/usr/share/man/man1/${MANFILE}")
if [ "${REMOVED}" == "false" ]; then
	echo $'\e[31m  error: could not find man page in any standard location.\e[m'
	ERRORS="true"
else
	printf "\e[32m  removed from: ${REMOVED}\e[m\n"
fi


REMOVED="false"
echo "* Removing icalBuddyConfig man page..."
REMOVED=$(remove_if_exists "/usr/local/share/man/man1/${CONFIGMANFILE}")
[ "${REMOVED}" == "false" ] && REMOVED=$(remove_if_exists "/usr/share/man/man1/${CONFIGMANFILE}")
if [ "${REMOVED}" == "false" ]; then
	echo $'\e[31m  error: could not find man page in any standard location.\e[m'
	ERRORS="true"
else
	printf "\e[32m  removed from: ${REMOVED}\e[m\n"
fi


REMOVED="false"
echo "* Removing icalBuddyLocalization man page..."
REMOVED=$(remove_if_exists "/usr/local/share/man/man1/${L10NMANFILE}")
[ "${REMOVED}" == "false" ] && REMOVED=$(remove_if_exists "/usr/share/man/man1/${L10NMANFILE}")
if [ "${REMOVED}" == "false" ]; then
	echo $'\e[31m  error: could not find man page in any standard location.\e[m'
	ERRORS="true"
else
	printf "\e[32m  removed from: ${REMOVED}\e[m\n"
fi


REMOVED="false"
echo "* Removing user configuration file..."
REMOVED=$(remove_if_exists "/Users/${USER}/.icalBuddyConfig.plist")
if [ "${REMOVED}" == "false" ]; then
	echo $'\e[33m  no config file found.\e[m'
else
	printf "\e[32m  removed from: ${REMOVED}\e[m\n"
fi


REMOVED="false"
echo "* Removing user localization file..."
REMOVED=$(remove_if_exists "/Users/${USER}/.icalBuddyLocalization.plist")
if [ "${REMOVED}" == "false" ]; then
	echo $'\e[33m  no localization file found.\e[m'
else
	printf "\e[32m  removed from: ${REMOVED}\e[m\n"
fi

echo 
if [ "${ERRORS}" == "false" ];then
	echo $'\e[32micalBuddy has been successfully uninstalled.\e[m'
	echo 
else
	echo $'\e[31muninstallation finished with some error(s).\e[m'
	echo 
	exit 1
fi

