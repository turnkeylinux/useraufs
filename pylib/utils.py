# Copyright (c) 2010 Liraz Siri <liraz@turnkeylinux.org> - all rights reserved
import os
import sys
import types

def fatal(arg):
    print >> sys.stderr, "fatal: " + str(arg)
    sys.exit(1)

def mkarg(x):
    """escape an argument from shell meta characters"""
    if '\'' not in x:
        return ' \'' + x + '\''
    s = ' "'
    for c in x:
        if c in '\\$"`':
            s = s + '\\'
        s = s + c
    s = s + '"'
    return s

def ignore_oserror_exception(orig, errnum):
    def wrapper(*args, **kws):
        ret = None

        try:
            ret = orig(*args, **kws)
        except OSError, e:
            if isinstance(errnum, types.ListType) or \
               isinstance(errnum, types.TupleType):
                if e[0] not in errnum:
                    raise

            elif e[0] != errnum:
                raise

        return ret
    return wrapper

def autoflush_stdout():
    if not os.isatty(sys.stdout.fileno()):
        sys.stdout.flush()
        sys.stdout = os.fdopen(sys.stdout.fileno(), "w", 0)

def autoflush_stderr():
    if not os.isatty(sys.stderr.fileno()):
        sys.stderr.flush()
        sys.stderr = os.fdopen(sys.stderr.fileno(), "w", 0)
