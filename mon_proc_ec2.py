#!/usr/bin/env python
#
# Author:  Mike Pietruszka
# Date:    Sep 7th, 2015
# Summary: Gather statistics on system processes and relay back to CloudWatch
#

import sys
import psutil
from boto.ec2 import cloudwatch
from boto.utils import get_instance_metadata

def collect_process_list():
    '''
    Collect process list metrics
    '''
    pslist = []
    pscount = {}

    for parg in sys.argv[1:]:
        for proc in psutil.process_iter():
            try:
                pinfo = proc.as_dict(attrs=['pid', 'name'])
            except psutil.NoSuchProcess:
                pass
            else:
                if parg in pinfo['name']:
                    pslist.append(parg)
    pscount['parg'] = len(pslist)
    return pscount

def send_process_list_metrics(instance_id, region, metrics, namespace, unit='Count'):
    '''
    Send multiple metrics to CloudWatch
    metrics is expected to be a map of key -> value pairs of metrics
    '''
    cw = cloudwatch.connect_to_region(region)
    cw.put_metric_data(namespace, metrics.keys(), metrics.values(), unit=unit,
                        dimensions={"InstanceId": instance_id})

if __name__ == '__main__':
    if not sys.argv[1:]:
        print "Please specify process name"
        sys.exit(1)
    else:
        namespace = 'EC2/Process_count_{process}'.format(process=sys.argv[1])
        metadata = get_instance_metadata()
        instance_id = metadata['instance-id']
        region = metadata['placement']['availability-zone'][0:-1]

        metrics = collect_process_list()

        send_process_list_metrics(instance_id, region, metrics, namespace)
