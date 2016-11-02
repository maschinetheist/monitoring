#!/usr/bin/env python
#
# Author:  Mike Pietruszka
# Date:    Nov 2nd, 2016
# Summary: Gather http stats and relay back to CloudWatch
#

from __future__ import print_function
import sys
import socket
import psutil
import argparse
from boto.ec2 import cloudwatch
from boto.utils import get_instance_metadata

def connection_states(proc_name, n_state):
    '''
    Collect a count of TCP connections for a given process.

    :param str proc_name:       process name
    :param list n_state:        list of given TCP states
    '''
    nginx_procs = []
    connections = []
    metrics = {'connections': None}

    for proc in psutil.process_iter():
        try:
            pinfo = proc.as_dict(attrs=['pid', 'name'])
        except psutil.NoSuchProcess:
            pass
        else:
            if proc_name in pinfo['name']:
                nginx_procs.append(pinfo['pid'])

    for pid in nginx_procs:
        p = psutil.Process(pid)
        conns = [c for c in p.connections() for state in n_state if c.status == state]
        if len(conns) >= 1:
            connections.append(len(conns))
        elif len(conns) == 0:
            connections.append(0)
        else:
            connections.append(None)

    metrics['connections'] = sum(i for i in connections)
    return metrics

def send_conn_metrics(instance_id, region, metrics, namespace, unit='Count'):
    '''
    Send connection metrics to CloudWatch.

    :param str instance_id:     EC2 instance id that awe are monitoring
    :param str region:          AWS region
    :param dict metrics:        connection metrics
    :param str namespace:       name of the metrics
    :param str unit:            unit of the monitored metric
    '''
    cw = cloudwatch.connect_to_region(region)
    cw.put_metric_data(namespace, metrics.keys(), metrics.values(), unit=unit,
        dimensions={"InstanceId": instance_id})

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Gather TCP connection states for a given process")
    parser.add_argument('-s', action='append', dest='n_state', help="TCP state", required=True)
    parser.add_argument('-p', action='store', dest='proc_name', nargs='*', help="Process name", required=True)
    results = parser.parse_args()

    if not vars(results):
        parser.print_help()
        sys.exit(0)

    proc_name = ''.join(results.proc_name)
    metrics = connection_states(proc_name, results.n_state)

    if metrics['connections'] is not None:
        try:
            namespace = 'EC2/http_connections_{proc_name}'.format(proc_name=proc_name)
            metadata = get_instance_metadata()
            instance_id = metadata['instance-id']
            region = metadata['placement']['availability-zone'][0:-1]
            send_conn_metrics(instance_id, region, metrics, namespace)
            print(metrics)
        except boto.exception.BotoServerError:
            print("ERROR: Could not submit latest metric")
    else:
        print("ERROR: Latest metric is None")
