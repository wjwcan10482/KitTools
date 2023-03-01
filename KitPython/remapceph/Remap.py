#!/usr/bin/env python
# remap osd.{{id}} {{ targetreweight }} 
# python  remap.py osd.6 0.01559
import os
import math
import time
import sys
def UpdateOsdRemap(osdid,ReweightTmp):
    CephHealth=os.popen('ceph health').read()
    print CephHealth
    while CephHealth != 'HEALTH_OK\n':
        CephHealth=os.popen('ceph health').read()
        print "HEALTH_NOT_OK"
        time.sleep(3)
        print "WAIT sleep 3"
    else:
        CephHealth=os.popen('ceph health').read()
        ReweightTmpF = format(ReweightTmp, '.5f')
        print ReweightTmpF
        a = "ceph osd crush reweight " + " " + osdid + " " + ReweightTmpF
        os.popen(a).read()

def main(osd,end):
    start=0.00000
    step=0.0001
    print "in main"
    while  start < end:
        print "in while"
        UpdateOsdRemap(osd,start)
        start = start + step

if __name__ == "__main__":
    print sys.argv[1]
    print sys.argv[2]
    main(sys.argv[1],float(sys.argv[2]))
