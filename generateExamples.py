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

configFilePath = 'exampleConfig.plist'

def createConfigFile(formattingAttrs):
	header = """<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>formatting</key>
			<dict>
		"""
	footer = """
			</dict>
		</dict>
		</plist>"""
	contents = header
	if formattingAttrs != None:
		for key, value in formattingAttrs.items():
			contents += '<key>'+key+'</key>\n'
			contents += '<string>'+value+'</string>\n'
	contents += footer
	f = open(configFilePath, 'w')
	f.write(contents)
	f.close()

def createEmptyConfigFile():
	createConfigFile(None)


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

formatMarker = '••f'
cmdMarker = '•••'
clearMarker = '•----'
tocMarker = '¶¶¶ TOC ¶¶¶'

formattingDict = None

if not os.path.exists(configFilePath):
	createEmptyConfigFile()

s = ''
for line in lines:
	if line.strip().startswith(cmdMarker):
		cmdToShow = line.strip()[len(cmdMarker):].strip()
		if cmdToShow.startswith('icalBuddy'):
			cmdToShow = cmdToShow.replace('icalBuddy', '/usr/local/bin/icalBuddy')
		
		cmdToRun = cmdToShow.replace('/icalBuddy', '/icalBuddy -cf "'+configFilePath+'"')
		cmdToRun = cmdToRun.replace('\\', '\\\\')
		cmdToRun = cmdToRun.replace('"', '\\"')
		
		if (formattingDict != None):
			createConfigFile(formattingDict)
		
		s += '<pre class="command"><code>'
		s += cmdToShow
		s += '</code></pre>\n\n'
		
		s += '<code class="output">\n'
		s += runInShell('./cmdStdoutToHTML "'+cmdToRun+'"')+'\n'
		s += '</code>\n'
		
		s += '<img src="arrow-down.png" style="float:right; position:relative; left:150px; top:-25px; z-index:10;" />\n'
		
		if (formattingDict != None):
			s += '<table class="formattingConfig">\n'
			s += '<tr><th colspan="2">Values for config file formatting section</th>'
			s += '    <td rowspan="'+str(len(formattingDict)+1)+'" style="border:none;"><img src="arrow-right.png" /></td></tr>\n'
			for key, value in formattingDict.items():
				s += '<tr><td>'+key+'</td><td>'+value+'</td></tr>\n'
			s += '</table>'
			createEmptyConfigFile()
			formattingDict = None
		
		continue
	elif line.strip().startswith(formatMarker):
		if (formattingDict == None): formattingDict = {}
		formatSpec = line.strip()[len(formatMarker):].split('=')
		formattingDict[formatSpec[0].strip()] = formatSpec[1].strip()
		continue
	elif line.strip().startswith(clearMarker):
		s += '<div style="clear:both;"></div>'
		continue
	s += line

p = Popen(['utils/discount', '-T', '-f', '+toc'], stdin=PIPE, stdout=PIPE, stderr=PIPE)
p_out, p_err = p.communicate(input=s)

html = p_out

# move table of contents into correct spot
toc = ''
gotTOC = False
s = ''
html_lines = html.splitlines(True)
for line in html_lines:
	if not gotTOC:
		if line.strip().find('icalBuddy Usage Examples') != -1:
			gotTOC = True
		else:
			toc += line
			continue
	if line.strip().find(tocMarker) != -1:
		s += '<h1>Table of Contents</h1>\n'
		s += '<div id="toc">\n'
		s += toc
		s += '</div>\n'
		continue
	s += line

print s

print "</div></body></html>"

if os.path.exists(configFilePath):
	os.remove(configFilePath)


