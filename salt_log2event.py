#!/usr/bin/env python
#
# Author:  Mike Pietruszka
# Date:    Oct 28th, 2016
# Summary: Parse through log files and fire off salt-call event.send so
#          the salt reactor can act on particular log line.
#

import salt.client
import sys
import argparse

__opts__ = salt.config.minion_config('/etc/salt/minion')
minion_id = __opts__['id']
caller = salt.client.Caller()

# Fire off an event to the salt-master
def saltevent(minion_id, tag, msg):
    caller.sminion.functions['event.send'](
        'tags/' + tag,
        {
            'minion': minion_id,
            'log_message': msg
        }
    )

class FileReader:
    def __init__(self, logfile, tag, search_str):
        self.logfile = logfile
        self.tag = tag
        self.search_str = search_str

    def read(self):
        f = self.logfile
        p = 0

        with open(f, 'r') as fh:
            while True:
                fh.seek(p)
                latest_line = fh.read()
                p = fh.tell()
                if latest_line:
                    logline = latest_line.strip('\n')
                    if self.search_str in logline:
                        saltevent(minion_id, self.tag, self.search_str)
        fh.closed


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse logs to send to SaltStack event buss")
    parser.add_argument('-l', '--log', action='store', dest='logfile', help="log file path", required=True)
    parser.add_argument('-t', '--tag', action='store', dest='tag', help="SaltStack event bus tag", required=True)
    parser.add_argument('-s', '--string', action='store', dest='search_str', help="Search string to look for", required=True)
    options = parser.parse_args()

    if not vars(options):
        parser.print_help()
        sys.exit(0)

    if not options.tag:
        options.tag = "log_parser"

    fr = FileReader(options.logfile, options.tag, options.search_str)
    fr.read()
