#!/usr/bin/env bash
# 
# install script for icalBuddy
# Copyright 2008-2010 Ali Rantakari
# 
# --------------------------------------
# 
# You can use the --prefix=/path
# argument to specify the prefix where
# the program should be installed.
# 
# 

DN="`dirname \"$0\"`"
THISDIR="`cd \"$DN\"; pwd`"

# default prefix:
PREFIX=/usr/local

BINDIR=bin
MANDIR=share/man/man1

BINFILE="${THISDIR}/icalBuddy"
MANFILE="${THISDIR}/icalBuddy.1"
L10NMANFILE="${THISDIR}/icalBuddyLocalization.1"
CONFIGMANFILE="${THISDIR}/icalBuddyConfig.1"


# check that the required (installable) files can be found
if [ ! -e "${BINFILE}" ];then
	echo "Error: can not find \"${BINFILE}\". Make sure you're running this script from within the distribution directory (the same directory where icalBuddy resides.) If you already are, run 'make' to build icalBuddy and then try running this script again."
	exit 1
fi
if [ ! -e "${MANFILE}" ];then
	echo "Error: can not find \"${MANFILE}\" (the man page.) Make sure you're running this script from within the distribution directory (the same directory where icalBuddy resides.)"
	exit 1
fi
if [ ! -e "${L10NMANFILE}" ];then
	echo "Error: can not find \"${L10NMANFILE}\" (the localization man page.) Make sure you're running this script from within the distribution directory (the same directory where icalBuddy resides.)"
	exit 1
fi
if [ ! -e "${L10NMANFILE}" ];then
	echo "Error: can not find \"${CONFIGMANFILE}\" (the configuration man page.) Make sure you're running this script from within the distribution directory (the same directory where icalBuddy resides.)"
	exit 1
fi


# check --prefix=path argument
if [[ "${1:0:9}" == "--prefix=" ]]; then
	PREFIX="${1:9}"
else
	# (no prefix argument -> ) check if installed already; adjust prefix if so
	which icalBuddy >/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ "`which icalBuddy | xargs -0 dirname | xargs -0 basename | tr -d '\n'`" == "bin" ]]; then
			PREFIX="`which icalBuddy | xargs -0 dirname | xargs -0 dirname | tr -d '\n'`"
		fi
	fi
fi



BINPATH="${PREFIX}/${BINDIR}"
MANPATH="${PREFIX}/${MANDIR}"


echo "================================="
echo
echo "This script will install:"
echo
printf "icalBuddy executable to: \e[36m${BINPATH}\e[m\n"
printf "man pages (icalBuddy, icalBuddyConfig, icalBuddyLocalization) to: \e[36m${MANPATH}\e[m\n"
echo
echo "(If you'd like to specify an installation prefix other than the current (${PREFIX}), you can"
echo "do it with the prefix argument: --prefix=/my/path)"
echo
echo $'We\'ll need administrator rights to install to these locations so \e[33mplease enter your admin password when asked\e[m.'
echo $'\e[1mPress any key to continue installing or Ctrl-C to cancel.\e[m'
read
echo
sudo -v
if [ ! $? -eq 0 ];then echo "error! aborting." >&2; exit 10; fi
echo

echo -n "Creating directories..."
sudo mkdir -p ${BINPATH}
if [ ! $? -eq 0 ];then echo "...error! aborting." >&2; exit 10; fi
sudo mkdir -p ${MANPATH}
if [ ! $? -eq 0 ];then echo "...error! aborting." >&2; exit 10; fi
echo "done."

echo -n "Installing the binary executable..."
sudo cp -f "${BINFILE}" "${BINPATH}"
if [ ! $? -eq 0 ];then echo "...error! aborting." >&2; exit 10; fi
echo "done."

echo -n "Installing the man pages..."
sudo cp -f "${MANFILE}" "${MANPATH}"
sudo cp -f "${L10NMANFILE}" "${MANPATH}"
sudo cp -f "${CONFIGMANFILE}" "${MANPATH}"
if [ ! $? -eq 0 ];then echo "...error! aborting." >&2; exit 10; fi
echo "done."

echo 
echo $'\e[32micalBuddy has been successfully installed.\e[m'
echo

