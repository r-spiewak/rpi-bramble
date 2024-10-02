---
title: "MySQL Installation"
date: 2024-04-03
order: 9
id: install-mysql
---

These instructions largely follow [the official MySQL installation instructions](https://dev.mysql.com/doc/refman/8.0/en/binary-installation.html).

## Initial Setup

### Dependencies

MySQL depends on `libaio`, so make sure to build/install that first (check for it with `ldconfig -p |grep libaio`; if there's no output, it's not currently installed).

To install `libaio` shared, follow instructions in [this post](2024-04-03-install-mysql.md).

MySQL also depends on `libncurses.so.6`. Follow the instructions in [this post](2024-04-04-install-ncurses.md) to install it.

### User and Group

First, we need to set up on each node the mysql user and group, with the home directory on the shared drive.

We must create the home directory on the shared drive (this only must be done once, from one node, and can be skipped if this was done already in [the previous steps to install munge](2024-03-29-install-munge.md)):
```
sudo mkdir -p -m777 /clusterfs/var/lib
```

Then, on each node create the group and user:
```
export MYSQLUSER=1003
sudo groupadd -g $MYSQLUSER mysql
sudo useradd -m -r -c "MySQL" -d /clusterfs/var/lib/mysql -u $MYSQLUSER -g mysql -s /bin/false mysql
```
(I ignored the warning `useradd warning: mysql's uid 1003 is greater than SYS_UID_MAX 999`. Also ignore the warnings on all nodes after the first that the directory already exists and that it won't copy any file from skel directory into it. Also one can remove the "/clusterfs" from the last command if installing mysql through package managers on each individual node.)

The number on the first line should be the same for all nodes (according to a warning on the SLURM installation site), so if a group already exists with that GID or a user already exists with that UID then remove the newly-created ones (with `sudo groupdel mysql` and `sudo userdel mysql`) and re-create them with a new number. To avoid this, one can also do `grep $MYSQLUSER /etc/group` and `grep $MYSQLUSER /etc/passwd` (both after the `export` command in the first block) on each node and ensure there is no output.

## Installation

### Through Package Managers

`apt`

### Through Build from Source

#### Download Build

First, figure out what CPU architecture is in use. On the ehad node, run 
`dpkg --print-architecture` (the output on mine was
`arm64`, so I have amd architecture).

Then go to the [MySQL downloads website](https://dev.mysql.com/downloads/mysql/) and find the most recent version for the above CPU architecture (mine was "Linux - Generic (glibc 2.28) (ARM, 64-bit), Compressed TAR Archive") and copy the download url.

On the head node, download that file:
```
cd /clusterfs/scratch
sudo wget https://dev.mysql.com/get/Downloads/MySQL-8.3/mysql-8.3.0-linux-glibc2.28-aarch64.tar.xz
```
{% comment %}
```
wget -O out/file/name http...
```
{% endcomment %}

#### Extract and Link

Run the following (changing the release version to match the latest release acquired above) to start the configuration:
```
sudo tar xJf mysql-8.3.0-linux-glibc2.28-aarch64.tar.xz --no-same-owner
cd mysql-8.3.0-linux-glibc2.28-aarch64
```

Now make a symlink to the mysql version as `mysql` (to make upgrades easier and such):
```
ln -s full-path-to-mysql-VERSION-OS mysql
```

#### Add to PATH

On each node, add the following to the `/etc/profile` file, just after the line added in [the earlier munge installation post](2024-03-29-install-munge.md) and before the `export PATH` command:
```
PATH="$PATH:/clusterfs/scratch/mysql/bin"
```

As [before](2024-03-29-install-munge.md), we must also enable `PermitUserEnvironment` (uncomment it and set it to `yes` instead of `no`) in `/etc/ssh/sshd_config` (edit with `sudo`), and also add `PATH=/clusterfs/usr/bin:/clusterfs/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games:/clusterfs/scratch/mysql/bin` to a file `~/.ssh/environment`. 

#### Create Data Directory

On the head node, change into the mysql directory, make the data directory, and assign permissions:
```
cd mysql
sudo mkdir mysql-files
sudo chown mysql:mysql mysql-files
sudo chmod 750 mysql-files
sudo mkdir data
sudo chown mysql:mysql data
sudo chmod 750 data
```

#### Initialize Data Directory

```
sudo bin/mysqld --initialize --user=mysql
```
Make note of the temporary password generated for the 
`root@localhost` user. It will need to be used to login, and then immediately changed. The line with that information will look like 
```
2024-04-04T12:36:41.979580Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: bWWJdQrxj2#>
```
and on mine was the second to last line of output.


#### Setup Secure Connections

Run the follwoing (note that it is likely deprecated, so it may be necessary to replace it with a new command; see [documentation](https://dev.mysql.com/doc/refman/8.0/en/mysql-ssl-rsa-setup.html)):
```
sudo bin/mysql_ssl_rsa_setup --datadir=data
```

#### Setup Service File and Automatic Start At Boot

(Presumably, this must only be done on the head node?)

Make a `systemd` service file (following [documentation](https://dev.mysql.com/doc/mysql-secure-deployment-guide/8.0/en/secure-deployment-post-install.html#secure-deployment-systemd-startup)) in `/clusterfs/scratch/mysql/mysql.service`:
{% highlight bash %}
{%- root_include_lines /files/shared-storage/mysql.service 0 37 -%}
{% endhighlight %}

Also create a configuration file `/clusterfs/etc/mysql.conf`:
{% highlight bash %}
{%- root_include_lines /files/shared-storage/mysql.conf 0 8 -%}
{% endhighlight %}

Link systemd to the service file:
```
sudo ln -s /clusterfs/scratch/mysql/mysql.service /lib/systemd/system/mysql.service
```

Now add
`sudo systemctl start mysql`
to the end of the [head node's file](2024-03-29-install-munge.md) [bramble-head.sh](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/bramble-head.sh) and the [compute node's file](2024-03-28-shared-storage.md) [mount-shared.sh](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/mount-shared.sh). 

{% comment %}
```
# Next command is optional
cp support-files/mysql.server /etc/init.d/mysql.server
```
{% endcomment %}

#### Change Root Password

Start the server manually with `sudo systemctl start mysql`.

Change the root password by starting the server and entering the following command:
```
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root-password';
```

#### Test the Server

Start the server manually with `sudo systemctl start mysql`.
{% comment %}
```
sudo bin/mysqld_safe --user=mysql &
```
{% endcomment %}

Test the database using the following:
```
mysqlshow -u root -p
```
If successful, the output should look like the following:
```
+--------------------+
|     Databases      |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```

Also try the following:
```
mysqladmin -u root -p version
```
Successful results should resemble the following:
```
mysqladmin  Ver 8.3.0 for Linux on aarch64 (MySQL Community Server - GPL)
Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Server version		8.3.0
Protocol version	10
Connection		Localhost via UNIX socket
UNIX socket		/tmp/mysql.sock
Uptime:			27 min 17 sec

Threads: 2  Questions: 10  Slow queries: 0  Opens: 133  Flush tables: 3  Open tables: 49  Queries per second avg: 0.006
```

There are [additional tests](https://dev.mysql.com/doc/refman/8.0/en/testing-server.html) that can be performed as well, but these are likely sufficient.
