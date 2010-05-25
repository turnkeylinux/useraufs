import os
import re
import pwd
import utils

class Error(Exception):
    pass

class UserAufs:
    CONF_FILE="/etc/useraufs.conf"
    
    def _load_conf(self):
        self.allowed_uids = [] # empty array means allow all
        self.allowed_dirs = [] # empty array means allow all

        if not os.path.exists(self.CONF_FILE):
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
                    raise Error("relative paths are illegal")

                # I think its better to just ignore non-existent paths
                if not os.path.exists(val):
                    continue

                if not os.path.isdir(val):
                    raise Error("not a directory: '%s'" % val)
                
                self.allowed_dirs.append(os.path.realpath(val))
            else:
                raise Error("illegal configuration line: " + line)
        
    def __init__(self):
        self._load_conf()
            
        uid = os.getuid()
        euid = os.geteuid()

        if euid != 0:
            raise Error("suid root privileges required (euid = %d)" % euid)

        if uid == 0:
            raise Error("useraufs may not be used by root")

        username = pwd.getpwuid(uid).pw_name
        if self.allowed_uids and uid not in self.allowed_uids:
            raise Error("configuration does not allow user %s" % username)

        self.uid = uid
        self.euid = euid
        self.username = username

    def _system(self, command):
        os.setuid(self.euid)
        error = os.system(command)
        os.setreuid(self.uid, self.euid)

        if error != 0:
            raise Error("failed exitcode (%d): %s" % (os.WEXITSTATUS(error), command),
                        error)

    def _check_is_dir_ok(self, dir):
        if not os.path.isdir(dir):
            raise Error("not a directory: %s" % dir)

        if os.lstat(dir).st_uid != self.uid:
            raise Error("directory '%s' is not owned by user %s" % (dir, self.username))

        if self.allowed_dirs:
            def is_dir_allowed(dir):
                dir = os.path.realpath(dir)
                for allowed_dir in self.allowed_dirs:
                    if dir == allowed_dir or dir.startswith(allowed_dir + '/'):
                        return True

                return False

            if not is_dir_allowed(dir):
                raise Error("configuration disallows operations involving directory '%s'" % dir)

    def mount(self, branches, mnt, udba=None):
        dirs = [ re.sub('=.*', '', branch.strip()) for branch in branches.split(':') ]
        dirs.append(mnt)

        for dir in dirs:
            self._check_is_dir_ok(dir)

        options = "dirs=" + branches
        if udba:
            options += ",udba=" + udba
        
        command = "mount -t aufs -o %s none %s" % (utils.mkarg(options),
                                                   utils.mkarg(mnt))
        self._system(command)

    def remount(self, operations, mnt):
        options = "remount"
        if operations:
            dirs = [ re.sub(r'^.*:(.*?)(?:=.*)?$', lambda m: m.group(1), operation.strip())
                     for operation in operations.split(',') ]
            dirs.append(mnt)

            for dir in dirs:
                self._check_is_dir_ok(dir)

            options += "," + operations
            
        command = "mount -o %s %s" % (utils.mkarg(options),
                                      utils.mkarg(mnt))
        self._system(command)

    def umount(self, mnt):
        self._check_is_dir_ok(mnt)

        command = "umount " + utils.mkarg(mnt)
        self._system(command)


# convenience functions
def mount(branches, mnt, **opts):
    UserAufs().mount(branches, mnt, **opts)

def umount(mnt):
    UserAufs().umount(mnt)

def remount(operations, mnt):
    UserAufs().remount(operations, mnt)
    

    

        

    
    
        
