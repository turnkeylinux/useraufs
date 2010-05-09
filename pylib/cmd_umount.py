#!/usr/bin/python
"""Umount union mount"""
import sys
import help
import useraufs

@help.usage(__doc__)
def usage():
    print >> sys.stderr, "Syntax: %s <mount-path>" % sys.argv[0]
    
def main():
    if len(sys.argv) != 2:
        usage()

    mnt = sys.argv[1]
    useraufs.umount(mnt)
    
if __name__=="__main__":
    main()

