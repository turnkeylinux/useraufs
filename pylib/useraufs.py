import os
import re
import pwd
import utils

class Error(Exception):
    pass

class UserAufs:
    def __init__(self):
        uid = os.getuid()
        euid = os.geteuid()

        if euid != 0:
            raise Error("suid root privileges required (euid = %d)" % euid)

        if uid == 0:
            raise Error("useraufs may not be used by root")

        self.uid = uid
        self.euid = euid
        self.username = pwd.getpwuid(uid).pw_name

    def _system(self, command):
        os.setuid(self.euid)
        error = os.system(command)
        os.setreuid(self.uid, self.euid)

        if error != 0:
            raise Error("failed exitcode (%d): %s" % (os.WEXITSTATUS(error), command),
                        error)

    def mount(self, branches, mnt):
        dirs = [ re.sub('=.*', '', branch.strip()) for branch in branches.split(':') ]
        dirs.append(mnt)

        for dir in dirs:
            if not os.path.isdir(dir):
                raise Error("not a directory: %s" % dir)

            if os.lstat(dir).st_uid != self.uid:
                raise Error("directory '%s' is not owned by user %s" % (dir, self.username))

        options = "dirs=" + branches
        command = "mount -t aufs -o %s none %s" % (utils.mkarg(options),
                                                   utils.mkarg(mnt))
        self._system(command)

    def remount(self, operations, mnt):
        dirs = [ re.sub(r'^.*:(.*?)(?:=.*)?$', lambda m: m.group(1), operation.strip())
                 for operation in operations.split(',') ]
        dirs.append(mnt)

        for dir in dirs:
            if not os.path.isdir(dir):
                raise Error("not a directory: %s" % dir)

            if os.lstat(dir).st_uid != self.uid:
                raise Error("directory '%s' is not owned by user %s" % (dir, self.username))

        options = "remount," + operations
        command = "mount -o %s %s" % (utils.mkarg(options),
                                      utils.mkarg(mnt))
        self._system(command)

    def umount(self, mnt):
        if os.lstat(mnt).st_uid != self.uid:
            raise Error("directory '%s' is not owned by user %s" % (mnt, self.username))

        command = "umount " + utils.mkarg(mnt)
        self._system(command)


# convenience functions
def mount(branches, mnt):
    UserAufs().mount(branches, mnt)

def umount(mnt):
    UserAufs().umount(mnt)

def remount(operations, mnt):
    UserAufs().remount(operations, mnt)
    

    

        

    
    
        
