#!/usr/bin/python
# 
# uninstall script for icalBuddy
# Copyright 2010 Ali Rantakari
# 

import os
from subprocess import Popen, PIPE, STDOUT


# search paths configuration
prefixes = ['/usr/local', os.path.expanduser('~')]
bin_paths = ['bin', '.bin']
man_paths = ['man/man1', 'share/man/man1', '.man/man1', '.share/man/man1']

# exit status values
STATUS_OK = 0
STATUS_ERROR = 1
STATUS_NOTHING_TO_UNINSTALL = 10
STATUS_USER_CANCEL = 11


def wrap_ansi(s, start_code, end_code):
	return '\x1b['+str(start_code)+'m'+s+'\x1b['+str(end_code)+'m'
def wrap_ansi_sgr(s, sgr):
	return wrap_ansi(s, sgr, (sgr-(sgr%10)+9))
def red(s): return wrap_ansi_sgr(s, 31)
def green(s): return wrap_ansi_sgr(s, 32)
def yellow(s): return wrap_ansi_sgr(s, 33)
def blue(s): return wrap_ansi_sgr(s, 34)
def magenta(s): return wrap_ansi_sgr(s, 35)
def cyan(s): return wrap_ansi_sgr(s, 36)
def bold(s): return wrap_ansi(s,1,22)


def find_path_under_prefix(name, prefix, bin=True):
	paths = bin_paths if bin else man_paths
	for path in paths:
		p = os.path.join(prefix,path,name)
		if os.path.exists(p): return p
	return None

def find_path(name, bin=True):
	ret = None
	for prefix in prefixes:
		ret = find_path_under_prefix(name,prefix,bin=bin)
		if ret != None: return ret
	return None


def move_to_trash(paths):
	applescript_format = 'tell application "Finder" to delete every item of {%(paths)s}'
	paths_strs = []
	for path in paths:
		paths_strs.append('(POSIX file "'+path.replace('"','\\"')+'")')
	applescript = applescript_format % {'paths': ','.join(paths_strs)}
	
	p = Popen(['osascript', '-s','s'], stdin=PIPE, stdout=PIPE, stderr=PIPE)
	p_out, p_err = p.communicate(input=applescript)
	return STATUS_OK


def uninstall(bin_filenames, man_filenames):
	all_found_paths = []
	found_bin_paths = {}
	found_man_paths = {}
	num_found_files = 0
	
	for b in bin_filenames:
		found_path = find_path(bin_filenames[b], bin=True)
		if found_path == None:
			# can't find binary from hardcoded prefix paths;
			# try asking `which`:
			p = Popen(['which',bin_filenames[b]], stdout=PIPE)
			found_path = p.communicate()[0].strip('\n')
			if p.returncode > 0:
				found_path = None
			else:
				# if we find a binary in a directory called "bin"
				# through `which`, add the parent of that dir into
				# our search prefix path list (so that we'd search
				# this prefix for the man pages as well).
				found_path_prefix, found_path_leafdir = os.path.split(os.path.dirname(found_path))
				if found_path_leafdir == 'bin':
					prefixes.append(found_path_prefix)
		if found_path != None:
			num_found_files += 1
			all_found_paths.append(found_path)
		found_bin_paths[b] = found_path
	
	for m in man_filenames:
		found_path = find_path(man_filenames[m], bin=False)
		if found_path != None:
			num_found_files += 1
			all_found_paths.append(found_path)
		found_man_paths[m] = found_path
	
	print 'The following installed files were found:'
	print
	for b in found_bin_paths:
		p = found_bin_paths[b]
		print b+': '+(green(p) if p != None else red('Not found'))
	for m in found_man_paths:
		p = found_man_paths[m]
		print m+': '+(green(p) if p != None else red('Not found'))
	print
	
	if num_found_files == 0:
		print 'Nothing to uninstall.'
		return STATUS_NOTHING_TO_UNINSTALL
	
	print 'Move the above files to trash?'
	r = ''
	while (r.lower() not in ['y','n']):
		r = raw_input('[y/n]: ')
	if r.lower() == 'n':
		return STATUS_USER_CANCEL
	
	return move_to_trash(all_found_paths)



if __name__ == '__main__':
	
	import sys
	
	# uninstallable items
	man_files = {
		'Man page':	'icalBuddy.1',
		'Config man page': 'icalBuddyConfig.1',
		'Localization man page': 'icalBuddyLocalization.1'
		}
	bin_files = {'Main executable binary': 'icalBuddy'}
	
	print '================================='
	print
	print 'This script will '+red('remove')+' icalBuddy and related files from your system'
	print '(the icalBuddy binary executable, the man pages as well as configuration'
	print 'and localization files).'
	print
	print 'We might need administrator rights to remove some of these files so '+yellow('please')
	print yellow('enter your admin password when asked')+'.'
	print bold('Press any key to continue uninstalling or Ctrl-C to cancel.')
	print
	
	exit_status = STATUS_OK
	try:
		r = raw_input()
		exit_status = uninstall(bin_files, man_files)
		if exit_status == STATUS_OK:
			print
			print green('icalBuddy has successfully been uninstalled.')
			print
	except KeyboardInterrupt:
		exit_status = STATUS_OK
		print
	except:
		exit_status = STATUS_ERROR
	
	sys.exit(exit_status)







