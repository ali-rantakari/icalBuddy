#!/usr/bin/env python

import os

def runInShell(cmd):
	o = os.popen(cmd, 'r')
	return o.read()

def getFileContents(path):
	f = open(path,'r')
	s = f.read().strip("\n").strip()
	f.close()
	return s


print "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
print "<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'>"
print "<head><title>icalBuddy Examples</title>"
print "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
print "<style type='text/css'>"
print getFileContents('examples.css')
print "</style>"
print "</head><body><div id='main'>"

print "<code>"
cmd = "icalBuddy -cf '' -f eventsToday+10"
print runInShell('./cmdStdoutToHTML "'+cmd+'"')
print "</code>"

print "</div></body></html>"
