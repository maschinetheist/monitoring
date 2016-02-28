#!/usr/bin/python
#
# Author:  Mike Pietruszka
# Date:    Aug 21st, 2015
# Summary: Parse through Zabbix mail and fire off salt-call event.send so 
#          the salt reactor can act on the alert.
#

import salt.client 
import mailbox

__opts__ = salt.config.minion_config('/etc/salt/minion')
caller = salt.client.Caller()
md = mailbox.Maildir('/home/username/Maildir/.Zabbix')

# Fire off an event to the salt-master; in this example we use 'tags/ntp' tag,
# you can change this or add more tags
def saltevent(minion):
    caller.sminion.functions['event.send'](
        'tags/ntp',
        {
            'id_from_zbx': minion
        }
    )

# Parse the zabbix mailbox for any issues
for key, msg in md.items():
    if "PROBLEM: Out of sync clock on " in msg['subject']:
        minion = msg['subject'].split("clock on ", 1)[1]
        saltevent(minion)
        to_remove.append(key)

# Remove old alert mail on the spot
try:
    for key in to_remove:
        md.remove(key)
finally:
    md.flush()
    md.close()
