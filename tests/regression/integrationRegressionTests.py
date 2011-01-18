#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import os
import sys
import subprocess
from datetime import datetime
from ansihelper import *


def read_commands_file(path):
    f = open(path, 'r')
    ret = []
    for line in f.readlines():
        stripped = line.strip()
        if stripped.startswith('#') or len(stripped) == 0:
            continue
        ret.append(stripped)
    f.close()
    return ret


def run_command(command_str):
    process = subprocess.Popen(command_str, shell=True,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    return stdout


def write_failure_log(logfile_path, failed_commands, ok_icalbuddy,
                      tested_icalbuddy):
    if os.path.exists(logfile_path):
        os.unlink(logfile_path)
    f = open(logfile_path, 'w')
    
    f.write('icalBuddy integration regression test failures log\n')
    f.write('%s\n' % datetime.now())
    f.write('\n')
    f.write('"ok" icalBuddy at: %s\n' % ok_icalbuddy)
    f.write('"tested" icalBuddy at: %s\n' % tested_icalbuddy)
    f.write('\n')
    
    for command_dict in failed_commands:
        f.write('========================================================='
                '==========================\n')
        f.write('COMMAND: %s\n' % command_dict['command'])
        f.write('\n')
        f.write('OK-OUTPUT: -----------------------------------------------\n')
        f.write(command_dict['ok-out'])
        f.write('\n\n')
        f.write('TESTED-OUTPUT: -------------------------------------------\n')
        f.write(command_dict['tested-out'])
        f.write('\n\n')
    
    f.close()


if __name__ == '__main__':
    
    my_path = sys.path[0]
    
    ok_icalbuddy_path = '/usr/local/bin/icalBuddy'
    tested_icalbuddy_path = os.path.abspath(my_path + '/../../icalBuddy')
    commands_path = os.path.abspath(my_path
                                    + '/integrationRegressionTestCommands.txt')
    logfile_path = os.path.abspath(my_path + '/last-failures.log')
    
    commands = read_commands_file(commands_path)
    
    num_commands = len(commands)
    num_failed = 0
    
    print
    print 'Using "ok" icalBuddy at:', blue('%s' % ok_icalbuddy_path)
    print 'Using "tested" icalBuddy at:', cyan('%s' % tested_icalbuddy_path)
    print
    print bold('%i commands to test. press enter to start.' % num_commands)
    print bold('--------------------------------------------')
    print
    try:
        raw_input()
    except KeyboardInterrupt:
        sys.exit(2)
    
    failure_log_data = []
    
    for command in commands:
        sys.stdout.write(blue(command))
        sys.stdout.flush()
        
        ok_icalbuddy_command = command.replace('icalBuddy', ok_icalbuddy_path)
        tested_icalbuddy_command = command.replace('icalBuddy',
                                                   tested_icalbuddy_path)
        
        ok_icalbuddy_out = run_command(ok_icalbuddy_command)
        tested_icalbuddy_out = run_command(tested_icalbuddy_command)
        
        failed = (ok_icalbuddy_out != tested_icalbuddy_out)
        
        sys.stdout.write(' - %s\n' % (red('FAIL') if failed else green('OK')))
        sys.stdout.flush()
        
        if (failed):
            num_failed += 1
            failure_log_data.append({'command': command,
                                     'ok-out': ok_icalbuddy_out,
                                     'tested-out': tested_icalbuddy_out})
    
    print
    if num_failed == 0:
        print bold('All commands succeeded.')
    else:
        write_failure_log(logfile_path, failure_log_data, ok_icalbuddy_path,
                          tested_icalbuddy_path)
        print red('%i/%i commands failed.' % (num_failed, num_commands))
        print 'Failure log written to: %s' % logfile_path
        sys.exit(1)

