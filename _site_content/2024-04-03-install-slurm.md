---
title: "Slurm Installation"
date: 2024-04-03
order: 10
id: install-slurm
---

## Initial Setup

First, we need to set up on each node the slurm user and group, with the home directory on the shared drive.

We must create the home directory on the shared drive (this only must be done once, from one node, and can be skipped if this was done already in [the previous steps to install munge](2024-03-29-install-munge.md)):
```
sudo mkdir -p -m777 /clusterfs/var/lib
```

Then, on each node create the group and user:
```
export SLURMUSER=1004
sudo groupadd -g $SLURMUSER slurm
sudo useradd -m -c "SLURM" -d /clusterfs/var/lib/slurm -u $SLURMUSER -g slurm -s /sbin/nologin slurm
```
(Ignore the warnings on all nodes after the first that the directory already exists and that it won't copy any file from skel directory into it. Also one can remove the "/clusterfs" from the last command if installing slurm through package managers on each individual node.)

The number on the first line should be the same for all nodes (according to a warning on the SLURM installation site), so if a group already exists with that GID or a user already exists with that UID then remove the newly-created ones (with `sudo groupdel slurm` and `sudo userdel slurm`) and re-create them with a new number. To avoid this, one can also do `grep $SLURMUSER /etc/group` and `grep $SLURMUSER /etc/passwd` (both after the `export` command in the first block) on each node and ensure there is no output.


## Install from Source

Install some additional build depencencies if not already installed (check with `dpkg -l <package-name>`, and install with `sudo apt-get install <package-name>`):
* `libdbus-1-dev`
* `linux-headers-$(uname -r)`


Locate the download url for the most recent slurm version from `https://www.schedmd.com/download-slurm/`.

On the head node, enter the scratch directory, download, and extract the slurm installer file:
```
cd /clusterfs/scratch
wget https://download.schedmd.com/slurm/slurm-23.11.6.tar.bz2
tar xjf slurm-23.11.6.tar.bz2
```

### Configure and install:
```
./configure --prefix=/clusterfs/usr/local/slurm --with-munge=/clusterfs/usr --enable-load-env-no-login --with-systemdsystemunitdir=/clusterfs/usr/lib/systemd/system 
make -j$(nproc)
sudo make install
```

### Edit service files:

In `/clusterfs/usr/lib/systemd/system/slurmd.service`, uncomment the line near the top for `ConditionPathExists`.


### Edit configuration files:

Some examples of necessary configuration files can be found [here](http://wiki.sc3.uis.edu.co/index.php/Slurm_Installation_from_sources).

Create the directory to hold them:
```
sudo mkdir -m777 /clusterfs/usr/local/slurm/etc
```

Create `/clusterfs/usr/local/slurm/etc/slurm.conf` (visit [this url](https://slurm.schedmd.com/configurator.html) in a web browser to generate the configuration file):
{% highlight bash %}
{%- root_include /files/shared-storage/slurm.conf -%}
{% endhighlight %}


### Setup database for slurm:

First, we need to enter the mysql shell in order to create the database user:
```
mysql -u root -p
```
Enter the password to access the mysql shell.

Then we can create the user (replace the password with something):
```
CREATE USER 'slurm'@'localhost' IDENTIFIED BY 'password';
```

Now grant privaleges:
```
GRANT ALL PRIVILEGES ON slurm_acct_db.* TO 'slurm'@'localhost' WITH GRANT OPTION;
```

Now create the database:
```
create database slurm_acct_db;
```

Exit the shell with `exit;`.


### Slurmdbd configuration file:

Create `/clusterfs/usr/local/slurm/etc/slurmdbd.conf` (change the database username and password accordingly):
{% highlight bash %}
{%- root_include /files/shared-storage/slurm.conf -%}
{% endhighlight %}
Change the file permissions of this file to 600 and the ownership to the `slurm` user:
```
sudo chmod 600 /clusterfs/usr/local/slurm/etc/slurmdbd.conf
sudo chown slurm /clusterfs/usr/local/slurm/etc/slurmdbd.conf
```

### Link to Service files

Link to service files (on the nodes other than the head node, it is sufficient to link only the first of the service files below):
```
sudo ln -s /clusterfs/usr/lib/systemd/system/slurmd.service /lib/systemd/system/slurmd.service
sudo ln -s /clusterfs/usr/lib/systemd/system/slurmdbd.service /lib/systemd/system/slurmdbd.service
sudo ln -s /clusterfs/usr/lib/systemd/system/slurmctld.service /lib/systemd/system/slurmctld.service
sudo ln -s /clusterfs/usr/lib/systemd/system/sackd.service /lib/systemd/system/sackd.service
```

### Add to PATH

Add `/clusterfs/usr/local/slurm/bin/` to PATH (in `/etc/profile` file, as we did for munge), or add links to all those files into `/clusterfs/usr/bin/`:
```
for file in $(ls /clusterfs/usr/local/slurm/bin/); do
    sudo ln -s /clusterfs/usr/local/slurm/bin/${file} /clusterfs/usr/bin/${file}
done
```

## Test

Start the slurm daemons on all nodes (head node needs `slurmd`, `slurmctl`, and `slurmdbd`, all other nodes just need `slurmd`) with `sudo systemctl start <daemon>`.

Check that the nodes all appear in the slurm control:
`sinfo -N -r -l` (the `-r` shows only nodes responsive to slurm, so omit it to also include nodes that are down; omit the `-l` flag to see only the short description table instead of the long one; ommitting the `-N` flag allows it to group the responses instead of outputting one line for each node).

If the nodes are all up, the command `srun -N4 /bin/hostname` should print out each node's hostname. Run it as a shared user though (like `sudo su - $NEWUSERNAME -c "srun -N4 /bin/hostname"`), or it will be looking for the home directory of the regular user on the login node (which won't exist on other nodes). See next section for creating a shared user.

## Create Shared Users

Create one or more users on each login node with shared home directories (i.e., on `/clusterfs/home/<user>`) to be able to run slurm commands:
```
export NEWUSER=1111
export NEWUSERNAME=newuser
sudo useradd -m -c "Shared user $NEWUSERNAME" -U -d /clusterfs/home/$NEWUSERNAME -u $NEWUSER -s /bin/bash $NEWUSERNAME
sudo passwd $NEWUSERNAME
```
(Again, ignore warnings on all nodes other than the first about the home directory already existing and not copying files into it.)

{% comment %}
If all nodes are up, [this script]() can be used to easily create users with the command `sbatch <script> add <usrename>`.  
{% endcomment %}

## Add Services to Startup Script Files

Add the start service command to the scripts files:
In [systemd service](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/bramblehead.service) (named `/lib/systemd/system/bramblehead.service`), add:
{% highlight bash %}
{%- root_include_lines /files/shared-storage/bramblehead.service 6 9 -%}
{% endhighlight %}
In [daemon-reload script](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/bramble-head.sh), add:
{% highlight bash %}
{%- root_include_lines /files/shared-storage/bramble-head.sh 11 12 -%}
{% endhighlight %}

## Additional Notes

To see details about a particular node (including a reason why it may be in a down state), run the following:
```
scontrol show node <node's hostname>
```

If you ever have to reboot a node without doing it through slurm, run the following to tell slurm to bring the node back from the "down" state:
```
sudo /clusterfs/usr/bin/scontrol update state=resume NodeName=<node's hostname>
```
The proper way to reboot a node is with `scontrol reboot_nodes <node's hostname>` (or `ALL`, or a list `<NodeList>`, and assuming the `RebootProgram` is set in the `slurm.conf`).

## Appendix

Some interesting outputs from `sudo make install`:
```
libtool: finish: PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbin" ldconfig -n /clusterfs/usr/local/slurm/lib
----------------------------------------------------------------------
Libraries have been installed in:
   /clusterfs/usr/local/slurm/lib

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

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
```

```
libtool: finish: PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sbin" ldconfig -n /clusterfs/usr/local/slurm/lib/slurm
----------------------------------------------------------------------
Libraries have been installed in:
   /clusterfs/usr/local/slurm/lib/slurm

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

See any operating system documentation about shared libraries for
more information, such as the ld(1) and ld.so(8) manual pages.
```
