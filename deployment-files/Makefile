# icalBuddy makefile
# 
# Created by Ali Rantakari on 18 June, 2008
# 


all: icalBuddy


# compile the binary
icalBuddy: icalBuddy.m
	@echo
	@echo ---- Compiling:
	@echo ======================================
	gcc -O2 -Wall -force_cpusubtype_ALL -mmacosx-version-min=10.5 -arch i386 -arch ppc -framework Cocoa -framework CalendarStore -framework AppKit -framework AddressBook -o $@ $?


clean:
	@echo
	@echo ---- Cleaning up:
	@echo ======================================
	-rm icalBuddy



