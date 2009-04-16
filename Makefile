# icalBuddy makefile
# 
# Created by Ali Rantakari on 18 June, 2008
# 

SHELL=/bin/bash

APP_VERSION=$(shell ./icalBuddy -V)
TEMP_DEPLOYMENT_DIR=deployment/$(APP_VERSION)
TEMP_DEPLOYMENT_ZIPFILE=$(TEMP_DEPLOYMENT_DIR)/icalBuddy-v$(APP_VERSION).zip
TEMP_DEPLOYMENT_MANFILE="deployment/man.html"
TEMP_DEPLOYMENT_L10NMANFILE="deployment/localization-man.html"
TEMP_DEPLOYMENT_CONFIGMANFILE="deployment/config-man.html"
TEMP_DEPLOYMENT_FAQFILE="deployment/faq.html"
VERSIONCHANGELOGFILELOC="$(TEMP_DEPLOYMENT_DIR)/changelog.html"
GENERALCHANGELOGFILELOC="changelog.html"
SCP_TARGET=$(shell cat ./deploymentScpTarget)
DEPLOYMENT_INCLUDES_DIR="./deployment-files"







all: icalBuddy



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# compile the binary itself
#-------------------------------------------------------------------------
icalBuddy: icalBuddy.m
	@echo
	@echo ---- Compiling:
	@echo ======================================
	gcc -O2 -Wall -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -framework Cocoa -framework CalendarStore -framework AppKit -framework AddressBook -o $@ ANSIEscapeHelper.m icalBuddy.m




#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# generate configuration man page from POD syntax file
#-------------------------------------------------------------------------
icalBuddyConfig.1: icalBuddyConfig.pod
	@echo
	@echo ---- Generating configuration manpage
	@echo      from pod file:
	@echo ======================================
	pod2man --section=1 --release=1.0 --center="icalBuddy configuration" --date="2009-03-23" icalBuddyConfig.pod > icalBuddyConfig.1



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# generate localization man page from POD syntax file
#-------------------------------------------------------------------------
icalBuddyLocalization.1: icalBuddyLocalization.pod
	@echo
	@echo ---- Generating localization manpage
	@echo      from pod file:
	@echo ======================================
	pod2man --section=1 --release=1.0 --center="icalBuddy localization" --date="2009-03-16" icalBuddyLocalization.pod > icalBuddyLocalization.1



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# generate HTML from manpages and faq
#-------------------------------------------------------------------------
docs: icalBuddy.1 faq.markdown icalBuddyLocalization.1 icalBuddyConfig.1
	@echo
	@echo ---- Generating HTML from manpages:
	@echo ======================================
	utils/manserver.pl icalBuddy.1 | sed -e 's/<BODY .*>/<BODY>/' > $(TEMP_DEPLOYMENT_MANFILE)
	utils/manserver.pl icalBuddyLocalization.1 | sed -e 's/<BODY .*>/<BODY>/' > $(TEMP_DEPLOYMENT_L10NMANFILE)
	utils/manserver.pl icalBuddyConfig.1 | sed -e 's/<BODY .*>/<BODY>/' > $(TEMP_DEPLOYMENT_CONFIGMANFILE)
	
	@echo
	@echo ---- Generating HTML from FAQ:
	@echo ======================================
	echo "<html><head><title>icalBuddy FAQ</title>" > $(TEMP_DEPLOYMENT_FAQFILE)
	echo "<style type='text/css'>#main{width:600px; margin:30 auto 300 auto;} p{margin-bottom:30px;}</style>" >> $(TEMP_DEPLOYMENT_FAQFILE)
	echo "</head><body><div id='main'>" >> $(TEMP_DEPLOYMENT_FAQFILE)
	perl utils/markdown/Markdown.pl faq.markdown >> $(TEMP_DEPLOYMENT_FAQFILE)
	echo "</div></body></html>" >> $(TEMP_DEPLOYMENT_FAQFILE)



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# make release package (prepare for deployment)
#-------------------------------------------------------------------------
package: icalBuddy docs
	@echo
	@echo ---- Preparing for deployment:
	@echo ======================================
	
# create zip archive
	mkdir -p $(TEMP_DEPLOYMENT_DIR)
	echo "-D -j $(TEMP_DEPLOYMENT_ZIPFILE) icalBuddy icalBuddy.1 icalBuddyLocalization.1 icalBuddyConfig.1 icalBuddy.m ANSIEscapeHelper.h ANSIEscapeHelper.m" | xargs zip
	cd "$(DEPLOYMENT_INCLUDES_DIR)"; echo "-g -R ../$(TEMP_DEPLOYMENT_ZIPFILE) *" | xargs zip
	
# if changelog doesn't already exist in the deployment dir
# for this version, get 'general' changelog file from root if
# one exists, and if not, create an empty changelog file
	@( if [ ! -e $(VERSIONCHANGELOGFILELOC) ];then\
		if [ -e $(GENERALCHANGELOGFILELOC) ];then\
			cp $(GENERALCHANGELOGFILELOC) $(VERSIONCHANGELOGFILELOC);\
			echo "Copied existing changelog.html from project root into deployment dir - opening it for editing";\
		else\
			echo "<ul>\
		<li></li>\
	</ul>\
	" > $(VERSIONCHANGELOGFILELOC);\
			echo "Created new empty changelog.html into deployment dir - opening it for editing";\
		fi; \
	else\
		echo "changelog.html exists for $(APP_VERSION) - opening it for editing";\
	fi )
	@open -a Smultron $(VERSIONCHANGELOGFILELOC)




#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# deploy to server
#-------------------------------------------------------------------------
deploy: package
	@echo
	@echo ---- Deploying to server:
	@echo ======================================
	
	@echo "Checking latest version number vs. current version number..."
	@( if [ "`./icalBuddy -u | grep -c \"latest: $(APP_VERSION)\"`" == "0" ];then\
		echo "Version number is $(APP_VERSION). Press enter to continue uploading to server or Ctrl-C to cancel.";\
		read INPUTSTR;\
		scp -r $(TEMP_DEPLOYMENT_DIR) $(TEMP_DEPLOYMENT_MANFILE) $(TEMP_DEPLOYMENT_L10NMANFILE) $(TEMP_DEPLOYMENT_CONFIGMANFILE) $(TEMP_DEPLOYMENT_FAQFILE) $(SCP_TARGET);\
	else\
		echo "It looks like you haven't remembered to increment the version number ($(APP_VERSION)).";\
		echo "Cancelling deployment.";\
		echo "";\
	fi )




#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
clean:
	@echo
	@echo ---- Cleaning up:
	@echo ======================================
	-rm -Rf icalBuddy
	-rm -Rf icalBuddyLocalization.1
	-rm -Rf deployment/*



