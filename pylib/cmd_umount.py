#!/usr/bin/python
"""Umount union mount"""
import sys
import help
import useraufs

from utils import fatal

@help.usage(__doc__)
def usage():
    print >> sys.stderr, "Syntax: %s <mount-path>" % sys.argv[0]
    
def main():
    if len(sys.argv) != 2:
        usage()

    mnt = sys.argv[1]
    try:
        useraufs.umount(mnt)
    except useraufs.Error, e:
        fatal(e)
    
if __name__=="__main__":
    main()

