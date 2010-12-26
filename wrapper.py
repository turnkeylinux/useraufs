#!/usr/bin/python
# Copyright (c) 2010 TurnKey Linux - all rights reserved
"""Safe suid root user interface for aufs
"""

from os.path import *
import pyproject

class CliWrapper(pyproject.CliWrapper):
    DESCRIPTION = __doc__
    
    INSTALL_PATH = dirname(__file__)

if __name__ == '__main__':
    CliWrapper.main()
