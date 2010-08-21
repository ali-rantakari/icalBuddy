#!/usr/bin/python
# 
# install script for icalBuddy
# Copyright 2010 Ali Rantakari
# 

import os
from subprocess import Popen, PIPE, STDOUT


# search paths configuration
prefixes = ['/usr/local', os.path.expanduser('~')]
bin_paths = ['bin', '.bin']

# exit status values
STATUS_OK = 0
STATUS_ERROR = 1
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


def find_path_under_prefix(name, prefix):
	for path in bin_paths:
		p = os.path.join(prefix,path,name)
		if os.path.exists(p): return p
	return None

def find_path(name):
	ret = None
	for prefix in prefixes:
		ret = find_path_under_prefix(name,prefix)
		if ret != None: return ret
	return None

def find_already_installed_prefix(binfile):
	found_path = find_path(binfile)
	if found_path == None:
		# can't find binary from hardcoded prefix paths;
		# try asking `which`:
		p = Popen(['which',binfile], stdout=PIPE)
		found_path = p.communicate()[0].strip('\n')
		if p.returncode > 0: found_path = None
	
	if found_path != None:
		found_path_dirname = os.path.dirname(found_path)
		found_path_prefix, found_path_leafdir = os.path.split(found_path_dirname)
		if found_path_leafdir == 'bin':
			return found_path_prefix
		return found_path_dirname



if __name__ == '__main__':
	
	import sys
	import shutil
	import errno
	
	homedir = os.path.expanduser('~')
	thispath = sys.path[0]
	
	install_prefix = '/usr/local' # default
	
	existing_prefix = find_already_installed_prefix('icalBuddy')
	if existing_prefix != None:
		install_prefix = existing_prefix
	
	if len(sys.argv) > 1 and sys.argv[1].startswith('--prefix='):
		install_prefix = sys.argv[1][len('--prefix='):]
	
	exit_status = STATUS_OK
	installed = False
	
	while 1 == 1:
		
		try:
			install_prefix = os.path.expanduser(install_prefix)
			
			files_to_install = {
				thispath+'/icalBuddy':					os.path.join(install_prefix, 'bin'),
				thispath+'/icalBuddy.1':				os.path.join(install_prefix, 'share/man/man1'),
				thispath+'/icalBuddyConfig.1':			os.path.join(install_prefix, 'share/man/man1'),
				thispath+'/icalBuddyLocalization.1':	os.path.join(install_prefix, 'share/man/man1'),
				}
			
			files_missing = False
			for filename, path in files_to_install.items():
				if not os.path.exists(filename):
					files_missing = True
					print red('Can not find file: ')+cyan(filename)
			
			if files_missing:
				print 'Make sure you\'re running this script from the distribution'
				print 'folder where the above mentioned files are present.'
				exit_status = STATUS_ERROR
				sys.exit()
			
			print '================================='
			print
			print 'This script will '+green('install')+' icalBuddy and related files:'
			print
			
			if existing_prefix != None and install_prefix == existing_prefix:
				print yellow('(icalBuddy installation found in:')
				print green(' '+existing_prefix)
				print yellow(' -- using same path for updating:)')
				print
			
			for sourcepath, targetpath in files_to_install.items():
				filename = os.path.basename(sourcepath)
				print cyan(os.path.join(targetpath, filename))
			
			if not install_prefix.startswith(homedir):
				print
				print yellow('We might need administrator privileges to install to')
				print yellow('this location so please enter your password if prompted.')
			
			print
			print 'Input '+green('y')+' to continue installing, '+yellow('c')
			print 'to change the installation path or '+red('q')+' to quit.'
			r = ''
			while (r not in ['y','c','q']):
				r = raw_input('['+green('y')+'/'+yellow('c')+'/'+red('q')+']: ').lower()
			
			if r == 'q':
				sys.exit(STATUS_USER_CANCEL)
			elif r == 'c':
				print
				print 'Input new installation prefix:'
				install_prefix = raw_input(': ')
				continue
			
			
			# copy files over
			need_sudo = False
			for sourcepath, targetpath in files_to_install.items():
				filename = os.path.basename(sourcepath)
				print green('- ')+'Copying '+cyan(filename)+' to '+cyan(targetpath)
				
				if not need_sudo:
					try:
						try:
							os.makedirs(targetpath)
						except OSError, (errnum, strerror):
							if errnum == errno.EEXIST: pass # path exists
							else: raise
						shutil.copy(sourcepath, targetpath)
						print green('  copied.')
					except IOError, (errnum, strerror):
						if errnum == errno.EACCES: # permission denied
							need_sudo = True
						elif errnum == errno.ENOENT: # no such file/directory
							need_sudo = True
						else:
							raise
					except:
						raise
				
				if need_sudo:
					e_filename = filename.replace('\\', '\\\\').replace("'", "\\'")
					e_src_filepath = sourcepath.replace('\\', '\\\\').replace("'", "\\'")
					e_dest_dirpath = targetpath.replace('\\', '\\\\').replace("'", "\\'")
					e_dest_filepath = os.path.join(targetpath,filename).replace('\\', '\\\\').replace("'", "\\'")
					
					ret = os.system("sudo mkdir -p '"+e_dest_dirpath+"'")
					exit_status = (ret >> 8) & 0xFF
					if exit_status > 0:
						print red('  error: mkdir exit status '+str(exit_status))
						exit_status = STATUS_ERROR
					
					ret = os.system("sudo cp '"+e_src_filepath+"' '"+e_dest_filepath+"'")
					exit_status = (ret >> 8) & 0xFF
					if exit_status == 0: print green('  copied.')
					else:
						print red('  error: cp exit status '+str(exit_status))
						exit_status = STATUS_ERROR
			
			installed = True
			
		except KeyboardInterrupt:
			exit_status = STATUS_OK
			print
		except SystemExit:
			pass
		except:
			print red('Exception: '+str(sys.exc_info()[0]))
			raise
			exit_status = STATUS_ERROR
		
		if exit_status == STATUS_ERROR:
			print
			print red('There were errors in the installation.')
			print red('icalBuddy may not have been installed correctly.')
			print
		elif installed and exit_status == STATUS_OK:
			print
			print green('icalBuddy has successfully been installed.')
			print
		
		sys.exit(exit_status)







