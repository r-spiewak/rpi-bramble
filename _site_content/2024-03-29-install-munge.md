---
title: "Munge Installation"
date: 2024-03-29
order: 5
id: install-munge
---

## Initial Setup

First, we need to set up on each node the munge user and group, with the home directory on the shared drive.

We must create the home directory on the shared drive (this only must be done once, from one node):
```
sudo mkdir -p -m777 /clusterfs/var/lib
```

Then, on each nodecreate the group and user:
```
export MUNGEUSER=1002
sudo groupadd -g $MUNGEUSER munge
sudo useradd -m -c "MUNGE Uid 'N' Gid Emporium" -d /clusterfs/var/lib/munge -u $MUNGEUSER -g munge -s /sbin/nologin munge
```
(Ignore the warnings on all nodes after the first that the directory already exists and that it won't copy any file from skel directory into it. Also one can remove the "/clusterfs" from the last command if installing munge through package managers one ach individual node.)

The number on the first line should be the same for all nodes (according to a warning on the Munge installation site), so if a group already exists with that GID or a user already exists with that UID then remove the newly-created ones (with `sudo groupdel munge` and `sudo userdel munge`) and re-create them with a new number. To avoid this, one can also do `grep $MUNGEUSER /etc/group` and `grep $MUNGEUSER /etc/passwd` (both after the `export` command in the first block) on each node and ensure there is no output.

## Installation

Munge can be installed through package managers individually on each node, or once through a shared installation on the shared storage. The advantage of the second method is that it only has to be installed once, and only one installation has to be kept updated.

### Through Package Managers

As noted above, this sequence would require repeating these steps on each node individually, and this would require each installation to be kept updated and versions in sync. So it may be more beneficial to install a single shared version for all nodes.

Munge can be installed through the distribution's package managers, in this case `apt`, through `sudo apt-get install munge libmunge-dev`. 

On one node only, create a munge key with `sudo -u munge mungekey` and set permissions `sudo chmod 600 /etc/munge/munge.key`. 
This munge key then needs to be shared amongst all the nodes (via `scp` or the like). 

### Through Build From Source

First, login to the head node (through `ssh`) and perform these operations on that node (unless otherwise specified).

#### Install Dependencies

<!--
Then, check that some of the dependencies are present:
```
pkg-config --version
openssl version
bzip2 --version
```
Each of these commands should return something other than `-bash: XXXX: command not found` if the dependency is present. If it's not present, install it (through package manager, or from source on the shared drive as we're doing here for munge).
-->

Install the dev version of bz2: `sudo apt-get install libbz2-dev`.

Install the dev version of openssl: `sudo apt-get install libssl-dev`.

Create the following directories on the shared drive for munge:
```
sudo mkdir /clusterfs/scratch
sudo mkdir /clusterfs/usr
sudo mkdir /clusterfs/etc
sudo mkdir /clusterfs/run
sudo mkdir /clusterfs/log
```

#### Get Munge Release

Next, get the latest munge release (find the url of the latest release [here](https://github.com/dun/munge/releases)): 
```
sudo wget -P /clusterfs/scratch https://github.com/dun/munge/releases/download/munge-0.5.16/munge-0.5.16.tar.xz
```

#### Start Munge Configure

Then `cd` into the scratch directory (`cd /clusterfs/scratch`), and run the following (changing the release version to match the latest release acquired above) to start the configuration:
```
sudo tar xJf munge-0.5.16.tar.xz --no-same-owner
cd munge-0.5.16
sudo ./configure --prefix=/clusterfs/usr --sysconfdir=/clusterfs/etc --localstatedir=/clusterfs/var --runstatedir=/run --with-crypto-lib=openssl
```
(If anything comes back with a line beginning with `configure: error:`, stop and install the dev version of whatever it couldn't find.)
Note: the path for the `configure` arg `--runstatedir` is not on the shared drive, since each instance of the service (on each node) needs to use the same socket number, which is only possibe if each instance has an individual file, so the file should be local to the instance and not on the shared drive.

#### Make Munge

Then run the following commands to make and install it:
```
sudo make
make check
sudo make install
```
<!-- If there are any errors, you're on your own... I just ignored some errors. -->
When running `make install`, some issues may arise with files or directories not existing or with permission errors. If a directory doesn't exist, create the directory with `sudo mkdir -p /clusterfs/dir-to-be-created` (and if the directory has `mung` in its name, change the ownership of those directories to `munge` with `sudo chown munge: /clusterfs/path-that-was-just-created/munge`) and run `make install` again.

Note that these file permissions won't work for exfat type filesystems, and possibly also for other fuse-mounted filesystems (such as `sshfs`).

<!-- 
exFAT doesn't have file permissions... so I can't actually change the permissions on the exFat formatted drive. So either I have to reformat the drive (to something more friendly, like ext4, and then I can use NFS to mount it too, I guess), or I can't put anything on the drive that needs to have specific file permissions...

```
sudo mkdir /clusterfs/etc/munge
sudo src/mungekey/mungekey
sudo chmod 755 /clusterfs/etc/munge/munge.key
```
-->

#### Link Munge Service Files

<!--
Can I install it on each node by running make install from each node? No. make install just installs it to the prefix dir from the configure script. But maybe I can symlink to the installation/add the bin dir to path? Or symlink the service to `/etc/systemd/system/munge.service`? It looks like the service was installed to `'/clusterfs/usr/lib/systemd/system/munge.service'`. Like `sudo ln -s /clusterfs/usr/lib/systemd/system/munge.service /lib/systemd/system/munge.service` (and then do a `sudo systemctl daemon-reload` so it knows about the service).
-->

For each node (both head and compute), link the `munge.service` file into the local directory:
```
sudo ln -s /clusterfs/usr/lib/systemd/system/munge.service /lib/systemd/system/munge.service
```
Then reload the daemon so it knows about the service:
`sudo systemctl daemon-reload`.

One can now manually start the munge daemon with 
`sudo systemctl start munge`,
and stop it with 
`sudo systemctl stop munge`.
(See later in the Head/Compute Node Services section regarding why `systemctl enable` will not work here, and what to do instead.)

#### Add to PATH

<!--
Dirs to add to PATH? `/clusterfs/usr/bin/`, `/clusterfs/usr/sbin/` But where to add to path? Not in .bashrc, since that's only for logins, and we'd need to add for even when there's no login... Actually, that's not true, `/etc/bash.bashrc` is also for non login shells, so it should work! Actually, based on the comments in the `bash.bashrc` file, the edits should probably go in `/etc/profile`, since that seems to be what actually sets the PATH. Specifically, i
-->
In the `/etc/profile` file (towards the beginning of the file on mine), there is a place where it actually sets the PATH variable:
```
if [ "$(id -u)" -eq 0 ]; then
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"
fi
export PATH
```
Just before the `export PATH` line, add in the line `PATH="/clusterfs/usr/bin:/clusterfs/usr/sbin:$PATH"`, so the file now looks like this:
```
if [ "$(id -u)" -eq 0 ]; then
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
  PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"
fi
PATH="/clusterfs/usr/bin:/clusterfs/usr/sbin:$PATH"
export PATH
```
(Remember to edit it with `sudo`.)

This is good, but by itself it actually doesn't change the PATH in a no-login non-interactive `ssh` session (for example, `ssh node-01 env` shows that the PATH variable is the default, not what was added here).

So we must also enable `PermitUserEnvironment` (uncomment it and set it to `yes` instead of `no`) in `/etc/ssh/sshd_config` (edit with `sudo`), and also add `PATH=/clusterfs/usr/bin:/clusterfs/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games` to a file `~/.ssh/environment`. 

Then restart the sshd service with `sudo systemctl restart sshd.service`.

##### Head/Compute Node Services

`sudo systemctl enable munge` will not work here for the following logical reasons:
 - On compute nodes, because this needs to be run only after the shared drive is available (or else it will not be able to follow the links to the actual service file). 
 - On the head node, because there is nothing in the `munge.service` file preventing it from trying to start before the shared drive (with the installation) is actually mounted (in which case, the service will fail to load).

{% comment %}
<!--
Maybe make a bash script to run on boot, check if shared drive is available, load shared drive, then start this and anything else?)
The enable command results in the following:
```
Created symlink /etc/systemd/system/munge.service → /clusterfs/usr/lib/systemd/system/munge.service.
Created symlink /etc/systemd/system/multi-user.target.wants/munge.service → /clusterfs/usr/lib/systemd/system/munge.service.
```
-->
{% endcomment %}

For the compute nodes, since we already have a service and script to load the shared drive after the connection to the head node is available (from the previous instruction, [Shared Storage Setup](2024-03-28-shared-storage.md)), just add the following to the end of that script file:
`sudo systemctl daemon-reload` (if not already there), and 
`sudo systemctl start munge.service`. 
Then reboot the node (`sudo systemctl reboot`) and test munge.

For the head node, create the following [systemd service](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/bramblehead.service) (named `/lib/systemd/system/bramblehead.service`):
```
~~~
{%- root_include /files/shared-storage/bramblehead.service -%}
~~~
```
Also create the following [daemon-reload script](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/bramble-head.sh):
```
{%- root_include /files/shared-storage/bramble-head.sh -%}
```
Then make it executable: `sudo chmod +x /scripts/bramble-head.sh`.
Then do `sudo systemctl daemon-reload`, and `sudo systemctl enable bramblehead.service`. 
Then reboot the node (`sudo systemctl reboot`) and test munge.


## Some Munge Tests:
The following munge tests should all work, once the systemd service is running and the PATH links are set up:
 - `munge -n`
 - `munge -n |unmunge`
 - `munge -n | ssh node02 unmunge` (try between every pair of nodes)
 - `ssh node02 munge -n | unmunge` (try between every pair of nodes)
 - `remunge`


<!--
`/clusterfs/usr/bin/munge -n -S /run/munge/munge.socket.2 |/clusterfs/usr/bin/unmunge -S /run/munge/munge.socket.2`
-->

## Appendix

Some interesting outputs from the `sudo make install` which may be useful at a later point:
```
Libraries have been installed in:
   /clusterfs/usr/lib

If you ever happen to want to link against installed libraries
in a given directory, LIBDIR, you must either use libtool, and
specify the full pathname of the library, or use the '-LLIBDIR'
flag during linking and do at least one of the following:
   - add LIBDIR to the 'LD_LIBRARY_PATH' environment variable
     during execution
   - add LIBDIR to the 'LD_RUN_PATH' environment variable
     during linking
   - use the '-Wl,-rpath -Wl,LIBDIR' linker flag
   - have your system administrator add LIBDIR to '/etc/ld.so.conf'
```
`PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbin" ldconfig -n /clusterfs/usr/lib`

<!--
Is this what's used in the tests to run?
/clusterfs/scratch/munge-0.5.16/src/etc/munge.systemd.service
Or maybe this?
MUNGED="${MUNGE_BUILD_DIR}/src/munged/munged"

/clusterfs/var/log/munge/munged.log
/clusterfs/run/munge/munge.socket.2

From munge.service:
ExecStart=/clusterfs/usr/sbin/munged --socket=/run/munge/munge.socket.2 $OPTIONS

`sudo systemctl unmask nfs-common.service`
-->
