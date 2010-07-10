#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
from subprocess import Popen, PIPE, STDOUT


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

md = getFileContents('examples.markdown')
lines = md.splitlines(True)

cmdMarker = '•••'
clearMarker = '•----'
s = ''
for line in lines:
	if line.strip().startswith(cmdMarker):
		cmdToShow = line.strip()[len(cmdMarker):].strip()
		cmdToRun = cmdToShow.replace('/icalBuddy', '/icalBuddy -cf ""')
		cmdToRun = cmdToRun.replace('"', '\\"')
		
		s += '<pre class="command"><code>'
		s += cmdToShow
		s += '</code></pre>\n\n'
		
		s += '<code class="output">\n'
		s += runInShell('./cmdStdoutToHTML "'+cmdToRun+'"')+'\n'
		#s += '</code><div class="clear"></div>\n'
		s += '</code>\n'
		
		continue
	elif line.strip().startswith(clearMarker):
		s += '<div style="clear:both;"></div>'
		continue
	s += line

p = Popen(['utils/discount'], stdin=PIPE, stdout=PIPE, stderr=PIPE)
p_out, p_err = p.communicate(input=s)

print p_out

print "</div></body></html>"
