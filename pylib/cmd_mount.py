#!/usr/bin/python
"""Creates a union mount

<branch> := /path/to/branch[=<permission> [ + <attribute> ]]
    <permission> := rw | ro
    <attribute> := wh | nolwh

See aufs(5) for branch flag meanings.

"""
import sys
import help
import useraufs

@help.usage(__doc__)
def usage():
    print >> sys.stderr, "Syntax: %s <branch>[:<branch> ...] <mount-path>" % sys.argv[0]
    
def main():
    if len(sys.argv) != 3:
        usage()

    branches = sys.argv[1]
    mnt = sys.argv[2]

    useraufs.mount(branches, mnt)
    
if __name__=="__main__":
    main()

