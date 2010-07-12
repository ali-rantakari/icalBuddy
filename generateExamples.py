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


default_code_font_size = 11
default_code_font_family = 'Courier New'

print "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>"
print "<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'>"
print "<head><title>icalBuddy Examples</title>"
print "<meta http-equiv='Content-Type' content='text/html; charset=utf-8' />"
print "<style type='text/css'>"
print "code.output { font-size: "+str(default_code_font_size)+"px; font-family: "+default_code_font_family+", monospace; }"
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

print "</div>" # /main 

font_list = getFileContents('font-list.txt')
fonts = font_list.splitlines()
fontJSArr = 'var defaultFontNameArr = ['
for font in fonts:
	fontJSArr += '"'+font+'",'
fontJSArr += '];\n'

print """
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js" type="text/javascript"></script>
<script type="text/javascript" language="javascript">

"""+fontJSArr+"""

$(document).ready(function() {
	populateFontList(defaultFontNameArr);
});

function populateFontList(fontArr)
{
	var s = "";
	for (var key in fontArr)
	{
		var fontName = fontArr[key];
		if (fontName.match(' Italic$')
			|| fontName.match(' (Demi)?Bold$')
			|| fontName.match(' Medium$')
			|| fontName.match(' (Ultra)?Light$')
			|| fontName.match(' Condensed$')
			)
			continue;
		if (fontName.match(' Regular$'))
			fontName = fontName.substr(0, fontName.indexOf('Regular'));
		
		fontName = jQuery.trim(fontName);
		var sel = (fontName == '"""+default_code_font_family+"""') ? ' selected="true"' : '';
		s += "<option value='"+fontName+"'"+sel+">"+fontName+"</option>";
	}
	$('#fontSelection').html(s);
}
function visualParamUpdated()
{
	var props = {
		'font-family': $('#fontSelection').val()+', monospace',
		'font-size': $('#fontSizeSelection').val()+'px'
		};
	var allOutputElements = $('.output');
	allOutputElements.css(props);
}
function adjustFontSize(delta)
{
	var currSize = parseInt($('#fontSizeSelection').val());
	var allOutputElements = $('.output');
	allOutputElements.css('font-size', (currSize+delta)+'px');
	$('#fontSizeSelection').val(currSize+delta);
}
</script>

<div id="visualParams">
<p>You can change the look of all the output examples on this page by changing these values:</p>
<form action="javascript:visualParamUpdated();">
<ul>
	<li><em>Font Family:</em>
		<select id="fontSelection" onchange="visualParamUpdated();">
		</select>
	</li>
	<li><em>Font Size:</em>
		<input type="text" size="3" id="fontSizeSelection" onchange="visualParamUpdated();" value='"""+str(default_code_font_size)+"""' /> px
		<button onclick="adjustFontSize(1);">+</button><button onclick="adjustFontSize(-1);">-</button>
	</li>
</ul>
<input type="submit" value="Update" />
</form>
</div>

<object id="fontListSWF" name="fontListSWF" type="application/x-shockwave-flash" data="FontList.swf" width="1" height="1">
    <param name="movie" value="FontList.swf" />
</object>

"""

print "</body></html>"

if os.path.exists(configFilePath):
	os.remove(configFilePath)


