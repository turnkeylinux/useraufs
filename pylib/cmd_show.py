#!/usr/bin/python
"""Show this user's union mounts"""
import sys
import re
import os

def main():
    uid = os.getuid()
    os.setuid(uid) # drop privileges, we don't need them here

    for line in file("/proc/mounts").readlines():
        mount = line.strip().split(' ')
        if mount[2] != 'aufs':
            continue

        dir = mount[1]
        if os.lstat(dir).st_uid != uid:
            continue
        
        branches = re.sub(r'.*br:', '', mount[3])
        print "%s\t%s" % (branches, dir)
    
if __name__=="__main__":
    main()

