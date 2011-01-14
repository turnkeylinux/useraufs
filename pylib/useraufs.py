import os
from os.path import *
import re
import pwd
import tempfile
import utils

class Error(Exception):
    pass

from executil import system, ExecError

class UserAufs:
    CONF_FILE="/etc/useraufs.conf"
    
    def _load_conf(self):
        self.allowed_uids = [] # empty array means allow all
        self.allowed_dirs = [] # empty array means allow all

        if not exists(self.CONF_FILE):
            return
        
        for line in file(self.CONF_FILE).readlines():
            line = line.strip()
            
            if not line or line.startswith("#"):
                continue

            op, val = re.split(r'\s+', line, 1)
            if op == 'allow_user':
                self.allowed_uids.append(pwd.getpwnam(val).pw_uid)
            elif op == 'allow_dir':
                if not val.startswith('/'):
                    raise Error("configuration error - relative path `%s' is illegal" % val) 

                self.allowed_dirs.append(realpath(val))
            else:
                raise Error("illegal configuration line: " + line)
        
    def __init__(self):
        self._load_conf()
            
        uid = os.getuid()
        euid = os.geteuid()

        if euid != 0:
            raise Error("suid root privileges required (euid = %d)" % euid)

        if uid == 0 and uid not in self.allowed_uids:
            raise Error("useraufs may not be used by root unless explicitly allowed")

        username = pwd.getpwuid(uid).pw_name
        if self.allowed_uids and uid not in self.allowed_uids:
            raise Error("configuration does not allow user %s" % username)

        self.uid = uid
        self.euid = euid
        self.username = username

        self.temp_symlinks = []

    def __del__(self):
        for symlink in self.temp_symlinks:
            os.remove(symlink)

    def _system(self, command, *args):
        os.setuid(self.euid)
        try:
            try:
                system(command, *args)
            except ExecError, e:
                raise Error(e)
        finally:
            os.setreuid(self.uid, self.euid)

    def _init_aufs_dir(self, dir):
        """Initialize aufs directory by creating user-owned internal files.
        This will prevent aufs from creating these files owned by root"""

        # drop privileges temporarily to create these files
        # as the calling user
        os.seteuid(os.getuid())

        lwh = join(dir, ".wh..wh.aufs")
        if not lexists(lwh):
            file(lwh, "w").close()

        plink = join(dir, ".wh..wh.plink")
        if not lexists(plink):
            os.mkdir(plink)

        os.seteuid(0)

    def _check_is_dir_ok(self, dir):
        if not isdir(dir):
            raise Error("not a directory: %s" % dir)

        if self.uid != 0 and os.stat(dir).st_uid != self.uid:
            raise Error("directory '%s' is not owned by user %s" % (dir, self.username))

        if self.allowed_dirs:
            def is_dir_allowed(dir):
                dir = realpath(dir)
                for allowed_dir in self.allowed_dirs:
                    if dir == allowed_dir or dir.startswith(allowed_dir + '/'):
                        return True

                return False

            if not is_dir_allowed(dir):
                raise Error("configuration disallows operations involving directory '%s'" % dir)

    def _filter_branch(self, branch):
        if ':' not in branch:
            return branch

        if '=' in branch:
            dir, flags = branch.split("=", 1)
        else:
            dir = branch
            flags = None
            
        fd, path = tempfile.mkstemp(prefix="useraufs.")
        os.close(fd)
        os.remove(path)
            
        os.symlink(realpath(dir), path)
        self.temp_symlinks.append(path)

        if flags:
            return path + "=" + flags
        else:
            return path
    
    def mount(self, mnt, branches, udba=None):
        if self.is_mounted(mnt):
            raise Error("`%s' already mounted" % mnt)
        
        branches = map(self._filter_branch, branches)

        dirs = [ re.sub('=.*', '', branch.strip()) for branch in branches ]

        for dir in dirs:
            self._check_is_dir_ok(dir)
            self._init_aufs_dir(dir)

        self._check_is_dir_ok(mnt)

        options = "dirs=" + ":".join(branches)
        if udba:
            options += ",udba=" + udba
        
        self._system("mount -t aufs -o", options, "none", mnt)

    def remount(self, mnt, operations):
        for operation in operations:
            m = re.match(r'(?:ins|mod|append|prepend|del):(.*?)(?:=.*)?$', operation)
            if not m:
                raise Error("illegal operation (%s)" % operation)

            dir = m.group(1)
            self._check_is_dir_ok(dir)
            self._init_aufs_dir(dir)

        options = "remount"
        self._check_is_dir_ok(mnt)
        options += "," + ",".join(operations)
            
        self._system("mount -n -o", options, mnt)

    def umount(self, mnt):
        self._check_is_dir_ok(mnt)

        self._system("umount", mnt)

    def get_mounts(self):
        mounts = []
        for line in file("/proc/mounts").readlines():
            mount = line.strip().split(' ')
            if mount[2] != 'aufs':
                continue

            dir = mount[1]
            if not exists(dir) or \
               (self.uid != 0 and os.lstat(dir).st_uid != self.uid):
                continue

            branches = re.sub(r'.*br:', '', mount[3])
            mounts.append((branches, dir))

        return mounts

    def is_mounted(self, mnt):
        for branches, dir in self.get_mounts():
            if dir == realpath(mnt):
                return True
        return False

# convenience functions
def mount(branches, mnt, **opts):
    UserAufs().mount(branches, mnt, **opts)

def umount(mnt):
    UserAufs().umount(mnt)

def remount(operations, mnt):
    UserAufs().remount(operations, mnt)

def get_mounts():
    return UserAufs().get_mounts()

    

        

    
    
        
