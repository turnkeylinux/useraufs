#!/usr/bin/python
# Copyright (c) TurnKey GNU/Linux - http://www.turnkeylinux.org
#
# This file is part of UserAUFS
#
# UserAUFS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.

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

