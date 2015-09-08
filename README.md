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

#### process_monitor.py
Requires:
* psutil
* boto2
This script monitors specific processes (passed as arguments) and relays the count of them to AWS Cloudwatch.  Good for checking for abnormally large amount of processes running on the EC2 instance.

#### check_dns_records.pl
This script checks for missing A and PTR records against DNS forward and reverse zones.
