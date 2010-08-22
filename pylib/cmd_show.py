#!/usr/bin/python
"""Show this user's union mounts"""
import sys
import re
import os

import useraufs

def main():
    for branches, dir in useraufs.get_mounts():
        print "[ %s ]" % dir
        for branch in branches.split(":"):
            print branch
        print
        
if __name__=="__main__":
    main()

