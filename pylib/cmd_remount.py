#!/usr/bin/python
"""Remounts a union mount to perform reconfiguration operations

<operation> :=
    ins:<index>:<branch> |
    mod:<branch> |
    append:<branch> |
    prepend:<branch> |
    del:/path/to/branch

<branch> := /path/to/branch[=<permission> [ + <attribute> ]]
    <permission> := rw | ro
    <attribute> := wh | nolwh

See aufs(5) for meaning of remount operations and branch flags.

"""
import sys
import help
import useraufs

@help.usage(__doc__)
def usage():
    print >> sys.stderr, "Syntax: %s <operation>[,<operation> ...] <mount-path>" % sys.argv[0]
    
def main():
    if len(sys.argv) != 3:
        usage()

    operations = sys.argv[1]
    mnt = sys.argv[2]

    useraufs.remount(operations, mnt)
    
if __name__=="__main__":
    main()

