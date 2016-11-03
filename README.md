# monitoring
This is a collection of various monitoring tools that I have written over the years.

#### check_bacula_tapes.pl
This is a script for Nagios that checks Bacula tapes and their states.

#### check_lsi_megaraid.pl
Requires:
* LSI MegaRAID MegaCLI

This is a script for Nagios/Zenoss that monitor LSI MegaRAID arrays and checks whether the batteries and logical/physical drives are healthy.

#### check_vol_usage.pl
This script checks for any filesystems with runaway utilization.  It's great substitute to individually checking filesystems.

#### check_process_ec2.py
Requires:
* psutil
* boto2

This script monitors specific processes (passed as arguments) running on an EC2 instance and relays the count of them to AWS Cloudwatch.  Good for checking for abnormally large amount of processes running on the EC2 instance.

#### check_http_cw.py
Requires:
* psutil
* boto2
* argparse
* __future__ (available in py 2.6+)

Used for checking a number of http connections made on the server. Requires TCP connection state and process name  as an arguments.

#### salt_log2event.py
Requires:
* salt.client
* argparse

Parse through log files and fire off a salt-call event.send. This is useful for running SaltStack reactors on particular strings found in log files.

#### salt_mail_parser.py
Requires:
* salt.client
* mailbox

Go through Maildir and fire off alerts into SaltStack event bus if a particular subject in an email is found. Useful for parsing Zabbix email alerts. One of the examples checks for out of sync clocks in ```msg['subject']```.

#### check_dns_records.pl
This script checks for missing A and PTR records against DNS forward and reverse zones.
