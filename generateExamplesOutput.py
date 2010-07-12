#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import types
import plistlib
import codecs
from subprocess import Popen, PIPE, STDOUT


def runInShell(cmd):
	o = os.popen(cmd, 'r')
	return o.read()

def getFileContents(path):
	f = open(path,'r')
	s = f.read().strip("\n").strip()
	f.close()
	return s


commandOutputsPlistPath = 'exampleCommandOutputs.plist'
configFilePath = 'exampleConfig.plist'

constArgs = {
	'includeCals':	'ExampleCal-Birthdays, ExampleCal-Home, ExampleCal-Work'
	}

def createConfigFile(formattingAttrs):
	header = """<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
			<key>constantArguments</key>
			<dict>
		"""
	middle = """
			</dict>
			<key>formatting</key>
			<dict>
		"""
	footer = """
			</dict>
		</dict>
		</plist>"""
	contents = header
	
	if constArgs != None:
		for key, value in constArgs.items():
			contents += '<key>'+key+'</key>\n'
			if type(value) is types.StringType:
				contents += '<string>'+value+'</string>\n'
			elif type(value) is types.BooleanType:
				contents += '<boolean>'+('true' if value else 'false')+'</boolean>\n'
	
	contents += middle
	
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


md = getFileContents('examples.markdown')
lines = md.splitlines(True)

formatMarker = '••f'
cmdMarker = '•••'

commands = {}
formattingDict = None

if not os.path.exists(configFilePath):
	createEmptyConfigFile()

for line in lines:
	if line.strip().startswith(cmdMarker):
		cmd = line.strip()[len(cmdMarker):].strip()
		if cmd.startswith('icalBuddy'):
			cmd = cmd.replace('icalBuddy', '/usr/local/bin/icalBuddy')
		
		cmdToRun = cmd.replace('/icalBuddy', '/icalBuddy -cf "'+configFilePath+'"')
		#cmdToRun = cmdToRun.replace('\\', '\\\\')
		#cmdToRun = cmdToRun.replace('"', '\\"')
		
		if (formattingDict != None):
			createConfigFile(formattingDict)
		
		p = Popen(['./cmdStdoutToHTML', '-c', cmdToRun], stdout=PIPE, stderr=PIPE)
		p_out, p_err = p.communicate()
		commands[unicode(cmd, 'utf-8')] = unicode(p_out, 'utf-8')
		
		if (formattingDict != None):
			createEmptyConfigFile()
			formattingDict = None
		
		continue
	elif line.strip().startswith(formatMarker):
		if (formattingDict == None): formattingDict = {}
		formatSpec = line.strip()[len(formatMarker):].split('=')
		formattingDict[formatSpec[0].strip()] = formatSpec[1].strip()
		continue

plistlib.writePlist(commands, commandOutputsPlistPath)

if os.path.exists(configFilePath):
	os.remove(configFilePath)


