#!/usr/bin/env python
#
# Author:  Mike Pietruszka
# Date:    Nov 7th, 2016
# Summary: Multiprocessed ping utility
#

from __future__ import print_function
import multiprocessing
import sys
import subprocess
import platform

def pinger(host):
    ping = None
    if platform.system() == 'Linux':
        ping_cmd = 'ping -n 1 ' + host
    elif platform.system() == 'CYGWIN_NT-6.1' or platform.system() == 'Windows':
        ping_cmd = 'ping -n 1 ' + host
    elif platform.system() == 'FreeBSD':
        ping_cmd = 'ping -c 1 ' + host

    try:
        ping = subprocess.check_output(ping_cmd, shell=True)
    except subprocess.CalledProcessError:
        ping = "Could not reach the site"
    finally:
        for line in ping.splitlines(True):
            line = line.replace('\n', '').replace('\r', '')
            if "Lost" in line: loss = line.split(" ")[14].replace('(', '')
            if "Average" in line: avg = line.split(" ")[9].replace(',', '')
    print("{} | {} | {}".format(host.ljust(width), avg.ljust(width), loss.ljust(width)))
    return 

if __name__ == '__main__':
    jobs = []
    sites = sys.argv[1:]
    width = 20
    print("{} | {} | {}".format("site".ljust(width), "avg roundtrip".ljust(width), "pkt loss".ljust(width)))
    
    for site in sites:
        p = multiprocessing.Process(target=pinger, args=(site,))
        jobs.append(p)
        p.start()