#!/usr/bin/python
"""Show this user's union mounts"""
import sys
import re
import os

import useraufs

def main():
    for branches, dir in useraufs.get_mounts():
        print "%s\t%s" % (branches, dir)
        
if __name__=="__main__":
    main()

