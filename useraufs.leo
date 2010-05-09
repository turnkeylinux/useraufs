<?xml version="1.0" encoding="UTF-8"?>
<leo_file>
<leo_header file_format="2" tnodes="0" max_tnode_index="8" clone_windows="0"/>
<globals body_outline_ratio="0.5">
	<global_window_position top="237" left="1404" height="600" width="800"/>
	<global_log_window_position top="0" left="0" height="0" width="0"/>
</globals>
<preferences/>
<find_panel_settings/>
<vnodes>
<v t="zaril.20100509072750" a="ETV"><vh>useraufs: suid wrapper for aufs</vh>
<v t="zaril.20100509072750.1"><vh>modify pyproject to support suid Python scripts</vh></v>
<v t="zaril.20100509072750.2" a="E"><vh>write useraufs wrapper</vh>
<v t="zaril.20100509072750.3"><vh>useraufs-mount</vh></v>
<v t="zaril.20100509072750.4"><vh>useraufs-umount</vh></v>
<v t="zaril.20100509072750.5"><vh>useraufs-remount</vh></v>
<v t="zaril.20100509072750.6"><vh>useraufs-show</vh></v>
<v t="zaril.20100509072750.7"><vh>useraufs.conf limitations</vh></v>
</v>
</v>
</vnodes>
<tnodes>
<t tx="zaril.20100509072750">@nocolor

* NOTES
    aufs is a security risk       

Q: how do I test a suid pyproject?
A:
    I could "install" it first
    modify the Makefile to install wrapper suid

* SUMMARY
    
* IDEAS
    add built-in suid support to execproxy?

    sanitize environment variables
        look at setuid-wrapper in Python distribution

        set safe PATH
            /sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

        unset PATH
            force program to set PATH explicitly?

        sanitize PATH of any directories not owned by root?
            we would also have to check with parents, etc.
                
        IFS
        ENV
        LD_*
        PYTHON*        
        CDPATH
        
        set umask
            to 077 or 022 if you want files to be readable

    allow mount sudo for now?
        that would be a huge gaping security hole

    instead of using the suid bit, use sudo?
        detect original user via sudo's environment variables?
        pros
            leverage sudo's configuration ability? (i.e., which users are allowed)
            leverage sudo's environmental sanitation?
            we don't have to modify pyproject in any way to support suidness

        cons
            sudo requires more configuration
            wants password unless configured otherwise
            requires an extra dependency for sumo?
            will make installing sumo more difficult?
                hard to auto-configure?
                    OTOH, we can configure by group...
    
    check that executed file is owned by root
       </t>
<t tx="zaril.20100509072750.1">install execproxy suid
    
add "make suidinit target?"
    no, if you want to make a suid program, you better know what to do
        add commented Makefile target

execproxy, sanitizes environment if run suid:
    look at setuid-wrapper in Python distribution

    set safe PATH
        /sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

    unset PATH
        force program to set PATH explicitly?

    sanitize PATH of any directories not owned by root?
        we would also have to check with parents, etc.
            
    IFS
    ENV
    LD_*
    PYTHON*        
    CDPATH
    
    set umask
        to 077 or 022 if you want files to be readable

Q: what's euid for a suid program?
A: the owner of the suid program

E: test that clean_environ really does its job
R: it does
    DISCOVERY: the Linux kernel filters LD_PRELOAD for suid files
    clean_environ never gets a chance to filter LD_PRELOAD
        but it does filter LD_PRELOAD_FOO, or whatever
            because it filters any environment variable beginning with LD_

IDEA: ipython as an interactive exploration/testing environment for suid test

    GOTCHA: system("ipython") won't work -&gt; os.geteuid == os.getuid()
        DISCOVERY: bash shell cancels suid effect (sets real uid to uid)
            this means you can't use system to execute a command as suid root
        SOLUTION: execl("/usr/bin/ipython", "ipython",  NULL);    

HYPO: maybe the shell is screwing with my euid credentials?

Q: how do I drop privileges in a suid python program?
A: 
    either
        os.setuid(os.getuid())
            loose privileges permanently

            equivalent to: os.setreuid(os.getuid(), os.getuid())

        os.seteuid(os.getuid())
            drop privileges temporarily
            can still regain privileges by executing os.seteuid(0)
    
    a fuller version - rom connagent/pylib/popen4.py
    
        def _drop_privileges(self, user):
            pwent = pwd.getpwnam(user)
            uid, gid, home = pwent[2], pwent[3], pwent[5]
            del os.environ["XAUTHORITY"]
            os.environ["USER"] = user
            os.environ["HOME"] = home
    
            usergroups = []
            groups = grp.getgrall()
            for group in groups:
                if user in group[3]:
                    usergroups.append(group[2])
            
            os.setgroups(usergroups)
            os.setgid(gid)
            os.setuid(uid)</t>
<t tx="zaril.20100509072750.2">* IDEAS:
/etc/useraufs.conf: configuration file that determines which branches we allow?
    limit_path /home/z/branches
    limit_user z

if no configuration file: all users and all paths allowed by default
    so long as they follow policy

check that all branches and the mountpoint owned by user and exist?
    or writeable by user/group?
        except for root...

don't let suid wrapper be run as root?

options are coma separated tokens, possibly prepended

Q: what cli interface?
A:
alternatives
    use "native" aufs mount, and merely pass it along to mount command?
        we only raise exceptions if we detect any security violations
        e.g.,
            useraufs dirs=/tmp/rw:/root /tmp/aufs

        cons
            the native interface is terrible
                inconsistent, complex
            parsing it "perfectly" is a pain
                        
    reimplement saner interface
    
"new" cli interface

useraufs-mount &lt;options&gt;  BRANCH[:BRANCH ...] &lt;mntpoint&gt;
    udba=none | reval | inotify
#    xino=&lt;filename&gt; noxino
#    plink noplink clean_plink
#    diropq=whiteouted | w | always | a
    
useraufs-remount &lt;operation&gt; &lt;mntpoint&gt;
    &lt;operation&gt;
        ins:index:BRANCH
        del:dir
        mod:BRANCH
        append:BRANCH
        prepend:BRANCH

useraufs-umount &lt;mntpoint&gt;
useraufs-show

BRANCH Syntax
    dir/path[=permission [ + attribute ] ]
        permission := rw | ro
        attribute := wh | nolwh
 
* MILESTONES
    useraufs-mount
    useraufs-umount
    useraufs-remount
    useraufs-show
    useraufs.conf limitations


    </t>
<t tx="zaril.20100509072750.3">cli
    useraufs-mount &lt;options&gt;  BRANCH[:BRANCH ...] &lt;mntpoint&gt;
        udba=none | reval | inotify
    #    xino=&lt;filename&gt; noxino
    #    plink noplink clean_plink
    #    diropq=whiteouted | w | always | a
    
logic
    if we don't have effective root privileges: exception
    if uid is root: exception

    parse branches to extract list of branch directory names
    if branch directories or mount path are not owned by user: exception
    mount -t aufs -o dirs=&lt;BRANCHES&gt; none &lt;mountpath&gt;


DISCOVERY:
    to drop privileges temporarily
        os.seteuid(1000)
            you can regain privileges with os.seteuid(0)
    
    to drop privileges permanently
        os.setuid(1000)
        os.setreuid(1000, 1000)

    to reset effective uid = 0, real uid != 0 (simulate suid): 
        os.setreuid(1000, 0)

    

    
    </t>
<t tx="zaril.20100509072750.4">cli
    useraufs-umount &lt;mntpoint&gt;

Q: who owns a mounted union mount?
    is it the owner of the original mountpoint or the owner of the branches?
A: 
    it's the owner of the branches
    so if the mount point is owned by the current user, we can umount it safely

logic
    check if mount point owned by current user, umount if it is</t>
<t tx="zaril.20100509072750.5">cli    
    useraufs-remount &lt;operation&gt;[,&lt;operation&gt; ... ] &lt;mntpoint&gt;
        &lt;operation&gt;
            ins:index:BRANCH
            del:dir
            mod:BRANCH
            append:BRANCH
            prepend:BRANCH
    
logic
    parse directory for each operation
        determine that directory and mntpoint are owned by user</t>
<t tx="zaril.20100509072750.6">cli
    useraufs-show

logic
    drop privileges (we don't need them for this command)
    parse /proc/mounts
    output branches owned by current user
        &lt;branch&gt;[:&lt;branch&gt; ...]     /path/to/mount






</t>
<t tx="zaril.20100509072750.7">logic
    /etc/useraufs.conf: configuration file that determines security limitations for useraufs

    if no configuration file: all users and all paths allowed by default
        so long as they follow policy

format
    # comment

    allow_dir /path/to/allowed/parent/dir
    allow_user z

</t>
</tnodes>
</leo_file>
