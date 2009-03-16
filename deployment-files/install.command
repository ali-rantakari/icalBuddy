#!/bin/bash
# 
# install script for icalBuddy
# (c) 2008-2009 Ali Rantakari
# 

DN=`dirname $0`
THISDIR="`cd $DN; pwd`"

BINDIR=/usr/local/bin
MANDIR=/usr/local/share/man/man1

BINFILE="${THISDIR}/icalBuddy"
MANFILE="${THISDIR}/icalBuddy.1"
L10NMANFILE="${THISDIR}/icalBuddyLocalization.1"



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
echo
echo "This script will install:"
echo
echo "icalBuddy executable to: ${BINDIR}"
echo "icalBuddy man page to: ${MANDIR}"
echo "icalBuddyLocalization man page to: ${MANDIR}"
echo
echo "We'll need administrator rights to install to these locations so please enter your admin password when asked."
echo "Press any key to continue installing or Ctrl-C to cancel."
read
echo
sudo -v
if [ ! $? -eq 0 ];then echo "error! aborting."; exit 10; fi
echo

echo -n "Creating directories..."
sudo mkdir -p ${BINDIR}
if [ ! $? -eq 0 ];then echo "...error! aborting."; exit 10; fi
sudo mkdir -p ${MANDIR}
if [ ! $? -eq 0 ];then echo "...error! aborting."; exit 10; fi
echo "done."

echo -n "Installing the binary executable..."
sudo cp -f "${BINFILE}" "${BINDIR}"
if [ ! $? -eq 0 ];then echo "...error! aborting."; exit 10; fi
echo "done."

echo -n "Installing the man pages..."
sudo cp -f "${MANFILE}" "${MANDIR}"
sudo cp -f "${L10NMANFILE}" "${MANDIR}"
if [ ! $? -eq 0 ];then echo "...error! aborting."; exit 10; fi
echo "done."

echo 
echo "icalBuddy has been successfully installed."
echo

