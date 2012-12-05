#!/usr/bin/python
# Copyright (c) TurnKey Linux - http://www.turnkeylinux.org
#
# This file is part of UserAUFS
#
# UserAUFS is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.

"""Safe suid root user interface for aufs
"""

from os.path import *
import pyproject

class CliWrapper(pyproject.CliWrapper):
    DESCRIPTION = __doc__
    
    INSTALL_PATH = dirname(__file__)

if __name__ == '__main__':
    CliWrapper.main()
