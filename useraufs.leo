<?xml version="1.0" encoding="UTF-8"?>
<leo_file>
<leo_header file_format="2" tnodes="0" max_tnode_index="15" clone_windows="0"/>
<globals body_outline_ratio="0.277599142551">
	<global_window_position top="0" left="1345" height="933" width="800"/>
	<global_log_window_position top="0" left="0" height="0" width="0"/>
</globals>
<preferences/>
<find_panel_settings/>
<vnodes>
<v t="zaril.20110127054447" a="E"><vh>Project</vh>
<v t="zaril.20110127054349"><vh>explore aufs</vh>
<v t="zaril.20110127054349.1"><vh>update Linux kernel to support dir inotify</vh>
<v t="zaril.20110127054349.2" a="M"><vh>gradm out of sync with grsecurity kernel</vh></v>
<v t="zaril.20110127054349.3" a="M"><vh>fix broken vmware + test vmware</vh></v>
<v t="zaril.20110127054349.4" a="M"><vh>fix broken sda1</vh></v>
<v t="zaril.20110127054349.5"><vh>test suspend2</vh></v>
</v>
<v t="zaril.20110127054349.6"><vh>suid python</vh></v>
</v>
<v t="zaril.20100509072750" a="ETV"><vh>develop suid wrapper for aufs</vh>
<v t="zaril.20100509072750.1"><vh>modify pyproject to support suid Python scripts</vh></v>
<v t="zaril.20100509072750.2" a="E"><vh>write useraufs wrapper</vh>
<v t="zaril.20100509072750.3"><vh>useraufs-mount</vh></v>
<v t="zaril.20100509072750.4"><vh>useraufs-umount</vh></v>
<v t="zaril.20100509072750.5"><vh>useraufs-remount</vh></v>
<v t="zaril.20100509072750.6"><vh>useraufs-show</vh></v>
<v t="zaril.20100509072750.7"><vh>useraufs.conf limitations</vh></v>
</v>
<v t="zaril.20101120204227"><vh>redesign cli</vh></v>
<v t="zaril.20101120204238"><vh>illegal path workaround</vh></v>
</v>
</v>
</vnodes>
<tnodes>
<t tx="zaril.20100509072750">GOAL: suid wrapper for aufs

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
<t tx="zaril.20101120204227">before
    useraufs-mount a:b c
after
    useraufs-mount c a b


    </t>
<t tx="zaril.20101120204238"></t>
<t tx="zaril.20110127054349">* SUMMARY
unionfs vs aufs
    everyone seems to prefer it to unionfs
    unionfs by contrast 
        has a huge codebase
        highly kernel dependent
        is poorly written
    aufs has many new features over unionfs
    successfully supports NFS-exporting
    
features
    unionfs supports up to 127 branches per mount point by default configuration
    supports adding deleting branches dynamically
    could be used to support rollback at specific points?
        yes, certainly

    psuedo-links
        takes care of modified linked files
            plinks temporary not permanent
            need to use auplink script to make them permamnent

ubuntu edgy uses aufs instead of unionfs

downloading aufs
        $ mkdir aufs.wcvs
        $ cd aufs.wcvs
        $ cvs -d:pserver:anonymous@aufs.cvs.sourceforge.net:/cvsroot/aufs login
        (CVS password is empty)
        $ cvs -z3 -d:pserver:anonymous@aufs.cvs.sourceforge.net:/cvsroot/aufs co aufs
    
    In order to update files after the first checkout.
        $ cd aufs.wcvs/aufs
        $ cvs update

        REMINDER: aufs i~pub/tmp/
    
    In order to see what the difference between two versions (two dates) is,
        $ cd aufs.wcvs/aufs
        $ cvs diff -D20061212 -D20061219
    
build aufs
    kernel required: 2.6.16+

    building aufs into the kernel statically
        make -f local.mk kconfig
        ... follow instructions ...
            copy all ./fs and ./include to your linux kernel source tree.
            add 'obj-$(CONFIG_AUFS) += aufs/' to linux/fs/Makefile.
            add 'source "fs/aufs/Kconfig"' to linux/fs/Kconfig.
            then, try 'make menuconfig' and go to Filesystem menu.

    when configuring kernel
        disable debugging

    building aufs as a module
        make -f local.mk
    or
        make KDIR=/usr/src/linux -f local.mk


    cp aufs.5 /usr/local/man/man5
    install -m 500 -p mount.aufs umount.aufs auplink aulchown /sbin

usage
	$ mkdir /tmp/rw /tmp/aufs
	# mount -t aufs -o dirs=/tmp/rw:${HOME}=ro none /tmp/aufs


    Here is another example.    
        # mount -t aufs -o br:/tmp/rw:${HOME}=ro none /tmp/aufs
        or
        # mount -t aufs -o br:/tmp/rw none /tmp/aufs
        # mount -o remount,append:${HOME}=ro /tmp/aufs
        
    
interesting options
    udba
    xino
        if you want an external inode table
            useful to keep from burning flash drives (xino table has lots of writes)

default permissions
    readwrite on first mount
    readonly on remount
    
first to last dir index can be thought of top to bottom (higher-to-lower)
    0
    1
    2
    3   

order of aufs branches matters
    only the top/first branch is writeable
        if its readonly - the entire filesystem is readonly

    whiteout branches must precede whited out files
    
its possible to dynamically reconfigure aufs
    it doesn't matter if files are open
        not like umount

    mount -o remount,&lt;options&gt; /path/to/aufs
    options
        prepend:/path/to/new_top_branch
        append:/path/to/bottom_branch
        mod:/path/to/existing_branch=&lt;newprivs&gt;
            newprivs can be
                =ro
                =rw

    aufs allows arbitrary reconfiguration of branches
        
see current branch structure and configuration
    cat /proc/mounts

directly modifying the branches
    not safe by default
    alternatives
        after modifying the branches directly do
            mount -o remount none /path/to/aufs
        udba option
            udba=inotify requires Linux kernel 2.6.18
  
renaming directories is very expensive
    creates a whiteout and then copies the files

mount --bind
    under the following configurations aufs behaves very similar to mount --bind of directories
        mount -t aufs -o dirs=/path/to/source none /path/to/dest

trick preventing direct access (udba)
    principle: mount --bind over branches

    # d=/tmp/.aufs.hide
    # mkdir $d
    # for i in $branches_you_want_to_hide
    &gt; do
    &gt;    mount -n --bind $d $i
    &gt; done
    
clearing dentry and inode caches
    udba=inotify needs kernel 2.6.18+
    unreliable
        mount -o remount /path/to/unionmount
    reliable (this is only reliable for the overlay)
        mount -o remount,mod:/path/to/overlay=rw /path/to/unionmount

* IDEAS
    its possible to implement an filesystem undo stack with aufs
    temporary non-persistance
    run out of space hack
    instead of udba
        we can reconfigure the sumo overlay
            and write directly to arena
            before restoring arena default configuration
      
* QUESTIONS
Q: what is the default access mode?
A: 
rw (read-write) if in dirs
ro 
    in remount
        prepend
---
Q:  can we write safely to different unioned branches?
A:
    yes, if we remount after changing the branches
        OR...
    if we use UDBA option - User's Direct Branch Access
    aufs is designed and implemented to be safe after UDBA
    
        udba=none
            disable udba (aufs is free to cache dentries)
            use this if you never do udba
        udba=reval
            tests only the existence of a file which existed
            use this if outer modification (UDBA) is rare and 
            you can ignore temporary and minor differences
    
        udba=inotify
            safest option - aufs uses inotify to detect direct changes on any of the branch directories
    
---    
Q: what happens if I change file's metadata? (touch, chown)
A:
    touch and chown copy the file to the overlay
    but, access time does not
---
Q: how do I find out who is accessing an overlay?
A:
    lsof -n |grep /path/to/overlay
---
Q: does the order of dirs matter?
A: yes!
    whiteouts have to precede whited out directory
        writeable branch should precede readonly branch

    deleted files that exist in the currently writeable branch    
---
Q: how do deletes work?
A:
    if the deleted file is in the writeable overlay, its deleted (unlinked)
    if the deleted file is in a lower readonly branch, its whited out
---
Q: how does aufs decide which overlay to write to?
    Is it order?
    Write permissions?
A:
    the top-most unionfs is the only 
---
Q: how do branch file inodes change after being unionized?
A:
    inodes inside the overlay are always different from inodes in the branches
    even if the overlay consists of only one branch
---
Q: can we effect which types of changes go to which layer? 
    e.g., redirect metadata changes to fat...
A: aufs doesn't support that
---
Q: can we dynamically change which branch is written to?
    maybe with mod:...
A: you can 
---
Q: how do we allow aufs overlay to be setup by a non-root user?
    I thnk aufs needs root privileges

* EXPERIMENTS
E: can we remount an aufs while in use?
R: yes we can
what happens to opened file?

    nothing happens - its recreated in overlay if we save it
        e.g., if we remove /root from the bottom of the aufs

    if we remove the writeable overlay and the aufs is readonly - it won't save
        readonly filesystem
        
---
E: try mounting only readonly branches
R: works, but becomes a read-only filesystem
---
E: try manipulating an aufs overlay dynamcically (without unmounting)
R: 
    mount -t aufs -o dirs=/tmp/rw:$HOME=ro none /tmp/aufs

    deleting a branch
        mount -t aufs -o remount,del:/tmp/rw none /tmp/aufs
    adding a branch
        mount -t aufs -o remount,prepend:/tmp/rw none /tmp/aufs
    changing branch to writeable
        mount -t aufs -o remount,mod:/tmp/rw=rw none /tmp/aufs

---
E: try mounting an empty aufs (no branches)
    try removing the last branch in an aufs
R: error, doesn't work
---
E: try removing a directory
    what happens if we delete a directory?
R:
    rm -rf directory
        firsts whiteouts directory contents 
        then creates whiteout for directory

        
    rm bar/*
        creates whiteouts in directory bar in overlay

    rmdir bar
        creates whitehout for bar directory (deletes bar directory)

    mkdir bar
        creates a directory with a global whiteout (.wh..wh..opq)
            its called an opaque directory

---
E: try moving a directory to another name
R:
    it whites out the old directory and creates new copies
    from hardlinks? (how expensive is this operation?)
        Q: are these new inodes?
        A: yes, these look like new inodes, so movnig a directory is an expensive operation
            not an atomic operation
            like moving directories between filesystems
---
E: try adding a readonly layer
R: it works perfectly
    mount -t aufs -o dirs=/root none /tmp/aufs
    mount -o remount,append:/home/z none /tmp/aufs
---
E: try writing directly to branch with udba
R:
    GOTCHA: udba=inotify doesn't work with kernels &lt; 2.6.18
    udba=reval works, but its not totally reliable

cd /tmp
ls aufs/; touch rw/PLAYBOY; ls aufs/
ls aufs/; rm rw/PLAYBOY; ls aufs/
---
E: test mount -o remount /tmp/aufs fix
    ls aufs/;touch rw/PLAYBOY;mount -o remount /tmp/aufs/; ls aufs/
    ls aufs/;rm rw/PLAYBOY;mount -o remount /tmp/aufs/; ls aufs/
R: unreliable!
---
E: test remove/add branch as a workaround for clearing the cache
operation: 
    mount -o remount,del:/tmp/rw tmp/aufs; 
    mount -o remount,add:/tmp/rw /tmp/aufs;

test
    ls aufs/;echo ---; touch rw/PLAYBOY;mount -o remount,del:/tmp/rw none /tmp/aufs; mount -o remount,prepend:/tmp/rw=rw none /tmp/aufs/; ls aufs/
    
    ls aufs/;echo ---; rm rw/PLAYBOY;mount -o remount,del:/tmp/rw none /tmp/aufs; mount -o remount,prepend:/tmp/rw=rw none /tmp/aufs/; ls aufs/
    
R: seems to work reliably
    could it just be the increased time?
---
E: test if mod operation clears the cache
    operation
        mount -o remount,mod:/tmp/rw=ro aufs/
        mount -o remount,mod:/tmp/rw=rw aufs/
        
        ls aufs/; touch rw/PLAYBOY; mount -o remount,mod:/tmp/rw=ro aufs/; mount -o remount,mod:/tmp/rw=rw aufs/; ls aufs/
        ls aufs/; rm rw/PLAYBOY; mount -o remount,mod:/tmp/rw=ro aufs/; mount -o remount,mod:/tmp/rw=rw aufs/; ls aufs/  
R: seems to work reliably
---
E: test if simple mod operation works
    operations
        1)  mount -o remount,mod:/tmp/rw=rw aufs/
        
        ls aufs/; touch rw/PLAYBOY; mount -o remount,mod:/tmp/rw=rw aufs/; ls aufs/
        ls aufs/; rm rw/PLAYBOY; mount -o remount,mod:/tmp/rw=rw aufs/; ls aufs/

        R: works reliably

        2) mount -o remount,udba=none aufs/

        ls aufs/; touch rw/PLAYBOY; mount -o remount,udba=none aufs/; ls aufs/
        ls aufs/; rm rw/PLAYBOY; mount -o remount,udba=none aufs/; ls aufs/

        R: error
 
R: works reliably
---
E: test overlay hardlinking behavior
R:
    by default, aufs doesn't remember hardlinks
        cd /root
        ln file file-hardlink

        cd /tmp/aufs
        ln file-hardink file-hardlink2

        umount /tmp/aufs
        mount -t aufs -o dirs=/tmp/rw:/root none /tmp/aufs

        stat file-hardlink2 != stat-filehardlink
---
E: try setting up a nested overlay
R: it works, but its not recursive

cd /tmp
mount -t aufs -o dirs=/tmp/rw:/root none /tmp/aufs
mount -t aufs -o dirs=/tmp none /tmp/aufs/tmp

cd /tmp/aufs/tmp # is equivalent to /tmp
cd /tmp/aufs/tmp/tmp # is empty (doesn't show mount)
---

E: try performing aufs ops as regular user
R:
    investigate user fstab

    IDEA: write a simple wrapper
---
E: try to evade policy with aufs
R: its possible. aufs is like mount --bind
    
</t>
<t tx="zaril.20110127054349.1">DEFERRED
    lets just use the remount workaround for now

* IDEA: maybe we should just use the remount option after updating the branches directly?
    because otherwise Alon will also have to update his kernel...

Q: what kernel version 
* REMINDER: installing kernel 2.6.17	
	linked udev_* commands from /lib/udev to /sbin
	vmware-config.pl
	emerged new gradm
	emerge nvidia-drivers
	fixed broken grsecurity rules
	compile custom modules
		cil, cloop, icfs, unionfs
	emerge alsa-driver

* LOG

emerge -pv hardened-sources
relinked /usr/src/linux to new hardened sources
downloaded appropriate suspend2 patch from their website
	+ verified signature

tried to apply suspend2 patch to hardened sources
	cd linux-2.6.20-hardened*
	patch -p1 &lt; ../suspend2-2.2.10*

	manually fixed failed chunks
		arch/i386/mm/fault.c
			missing include line &lt;linux/suspend.h&gt;

		init/do_mounts.c
			failed to apply due to a missing cast
				(char __user *)"string"

		kernel/printk.c
			missing include line &lt;linux/suspend.h&gt;

copy .config from old kernel to new kernel
	make oldconfig

make bzImage &amp;&amp; make modules
mount /boot &amp;&amp; install arch/i386/boot/bzImage into /boot/kernel-2.6.20-hardened-r2
make modules_install

emerge gradm
	broken (incompatible with kernel)
		ACCEPT_KEYWORDS=~x86 emerge gradm

emerge nvidia-drivers
    eselect opengl list
        eselect opengl set 1

    test 3d
        paxctl -pemrxs `which glxgears`
        glxgears
        
emerge alsa-driver

download updated version of vmware 5.5

compile aufs as kernel module
	cd/ usr/src/aufs
	make -f local.mk 
	cp aufs.ko /lib/modules/`uname -r`/misc
	depmod -a
	
</t>
<t tx="zaril.20110127054349.2">I have 2.1.9
    unstable ebuilds exist or 2.6.10

what is my grsecurity version?

solution: ACCEPT_KEYWORDS=~x86 emerge gradm
</t>
<t tx="zaril.20110127054349.3">downloaded updated vmware workstation 5.5 from Vmware archive section in downloaded page

cd /root/software/vmware
rm -rf vmware-distrib
extracted tarball
./vmware-install

GOTCHA: vmmon build from source still broken
    the culprit: includes/compat_kernel.h

RESOURCE: http://www.debuntu.org/how-to-vmware-server-workstation-under-ubuntu-feisty
    they recommend just commenting out the offending line

#if LINUX_VERSION_CODE &lt; KERNEL_VERSION(2,6,19)
static inline _syscall1(int, compat_exit, int, exit_code);
#endif

created a patch in /root/software/vmware

IDEA: we can just go back to previous vmware version
    UPDATE: don't need to. Everything works now perfectly.
</t>
<t tx="zaril.20110127054349.4">Q: how do I add support for SATA in my new kernel?

INSIGHT: old configuration still accessible + old dmesg logs should be in /var/log

old dmesg stuff not logged

TIP: lspci shows which SATA/PATA controller I have
    SiS RAID
        Silicon Integrated Systems

DISCOVERY: this new kernel moves SATA support into its own field

old kernel conf (SCSI low-level drivers)

CONFIG_SCSI_SATA=y
# CONFIG_SCSI_SATA_AHCI is not set
# CONFIG_SCSI_SATA_SVW is not set
CONFIG_SCSI_ATA_PIIX=y
# CONFIG_SCSI_SATA_MV is not set
# CONFIG_SCSI_SATA_NV is not set
# CONFIG_SCSI_PDC_ADMA is not set
# CONFIG_SCSI_SATA_QSTOR is not set
# CONFIG_SCSI_SATA_PROMISE is not set
CONFIG_SCSI_SATA_SX4=m
# CONFIG_SCSI_SATA_SIL is not set
# CONFIG_SCSI_SATA_SIL24 is not set
CONFIG_SCSI_SATA_SIS=m
# CONFIG_SCSI_SATA_ULI is not set
# CONFIG_SCSI_SATA_VIA is not set
# CONFIG_SCSI_SATA_VITESSE is not set
CONFIG_SCSI_SATA_INTEL_COMBINED=y

RESOURCE: http://gentoo-wiki.com/HARDWARE_SATA

    DISCOVERY: 2.6.18 changes kernel configuration of SATA

my driver: SiS 964/180 SATA support
</t>
<t tx="zaril.20110127054349.5">works
</t>
<t tx="zaril.20110127054349.6">Q: how do I run python safely as a setuid script?
A: ./Python-2.4.3/Misc/setuid-prog.c 
in Python distribution




</t>
<t tx="zaril.20110127054447">@nocolor
</t>
</tnodes>
</leo_file>
