---
title: "Shared Storage Setup"
date: 2024-03-28
order: 4
id: shared-storage
---
Steps in these instructions have been adapted from [this post](https://glmdev.medium.com/building-a-raspberry-pi-cluster-784f0df9afbd).

## Setup the SSD on the Head Node

`ssh` into the 2GB Pi (the "head" node), and, unless directed otherwise, perform the steps from that terminal.

Plug in the SSD into one of the USB ports on the 2GB Pi. Find the drive identifier with `lsblk`. The output should resemble the following:
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    0 931.5G  0 disk 
`-sda1        8:1    0 931.5G  0 part 
mmcblk0     179:0    0  29.1G  0 disk 
|-mmcblk0p1 179:1    0   512M  0 part /boot/firmware
`-mmcblk0p2 179:2    0  28.6G  0 part /
```
From the above, we see that the desired partition on this drive is at `/dev/sda1`.

Now get the UUID of the drive with `sudo blkid`. The output should resemble the following:
```
/dev/mmcblk0p1: LABEL_FATBOOT="bootfs" LABEL="bootfs" UUID="44FC-6CF2" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="d83f7158-01"
/dev/mmcblk0p2: LABEL="rootfs" UUID="93c89e92-8f2e-4522-ad32-68faed883d2f" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="d83f7158-02"
/dev/sda1: LABEL="My Passport" UUID="68AA-3B9B" BLOCK_SIZE="512" TYPE="exfat" PARTLABEL="My Passport" PARTUUID="776bc48e-6882-4c6a-a7b0-3b2e1fd3074d"
```
The part we require is `UUID="68AA-3B9B"`.

Now create the mount point (this step will need to be performed on all nodes):
```
sudo mkdir /clusterfs
sudo chown nobody:nogroup -R /clusterfs
sudo chmod 777 -R /clusterfs
```

Get the drive's format type. To do this, we need to mount the drive first. Run `sudo mount /dev/sda1 /clusterfs` to mount the drive, then run `sudo df -Th` to get the drive format type. Sample output:
```
Filesystem     Type      Size  Used Avail Use% Mounted on
udev           devtmpfs  660M     0  660M   0% /dev
tmpfs          tmpfs     185M  1.2M  184M   1% /run
/dev/mmcblk0p2 ext4       29G  1.8G   25G   7% /
tmpfs          tmpfs     924M     0  924M   0% /dev/shm
tmpfs          tmpfs     5.0M   16K  5.0M   1% /run/lock
/dev/mmcblk0p1 vfat      510M   63M  448M  13% /boot/firmware
tmpfs          tmpfs     185M     0  185M   0% /run/user/1000
/dev/sda1      exfat     932G  331M  932G   1% /clusterfs
```
The last line there has what we require: `/dev/sda1` has Type `exfat`. Now unmount the drive with `sudo umount /clusterfs`, so we can remount it again automatically.

Setup automatic mounting of the drive by including an entry in the `fstab` file. Add the entry `UUID=68AA-3B9B /clusterfs exfat defaults 0 2` to the file `/etc/fstab` using you favorite cli text editor (`nano` and `vi` are two popular choices). Remember to use `sudo` to be able to write out the file. Now reload the `fstab` file into the system with `sudo systemctl daemon-reload` and test the mounting with `sudo mount -a`. If it mounted successfully, the command `ls -a /clusterfs` should return results that are on the drive, for example:
```
 .    .Spotlight-V100  'Install Western Digital Software for Mac.dmg'
 ..   .Trashes         'Install Western Digital Software for Windows.exe'
```

## Setup Share via NFS

### Setup the Head Node to Share the SSD

First, install the NFS server with `sudo apt install nfs-kernel-server`.

Add the drive mount point to the `/etc/exports` list (replace the first three segments of the IP address with the scheme from your router; note that the subnet mask /24 is given such that anyone on the network can access the drive): `/clusterfs    10.0.0.0/24(auto,_netdev,rw,sync,no_root_squash,no_subtree_check)`. 
The options are: `auto,_netdev` makes the filesystem wait for a network connection, `rw` gives read/write permissions, `sync` forces changes to be written immediately, `no_root_squash` allows root users to write files with root permissions, and `no_subtree_check` prevents errors caused by files being changed while another process/device is using it. To be more restrictive, one can create separate entries (on separate lines) with the exact reserved IP addresses of each node (and use the mask /32 instead of /24), so that only those IP addresses can access the drive.
Remember to edit the file with `sudo`.

Now actually export the drive: `sudo exportfs -a`.

However, if, like me, your drive is fromatted as `exfat`, NFS will not work to share it. In this case, you must either reformat the drive, or use a different sharing protocol (such as SMB or `sshfs`).

### Setup the Other Nodes to Access the Shared SSD

Do this on each of the other nodes.

Install the NFS client with `sudo apt install nfs-common` (if it's not already installed).

Create the mount point:
```
sudo mkdir /clusterfs
sudo chown nobody:nogroup -R /clusterfs
sudo chmod 777 -R /clusterfs
```

Setup automatic mounting of the drive by including an entry in the `fstab` file. Add the entry `10.0.0.1:/clusterfs /clusterfs nfs defaults 0 0` (replacing the IP address with the IP address of the Head node) to the file `/etc/fstab` using you favorite cli text editor (`nano` and `vi` are two popular choices). Remember to use `sudo` to be able to write out the file. Now reload the `fstab` file into the system with `sudo systemctl daemon-reload` and test the mounting with `sudo mount -a`. If it mounted successfully, the command `ls -a /clusterfs` should return results that are on the drive, for example:
```
 .    .Spotlight-V100  'Install Western Digital Software for Mac.dmg'
 ..   .Trashes         'Install Western Digital Software for Windows.exe'
```

## Setup Share via SSHFS

Since the `ssh` connections between nodes was already established, all that is required is to install `sshfs` on the client nodes and add the entry to the `fstab` file.

Install `sshfs` with `sudo apt install sshfs`.

Initialize the `fuse` module: `sudo modprobe fuse`.

Check if there is a group for fuse: `getent group fuse` (if not, add it with `sudo groupadd fuse`). Then add the user to the fuse group: ` sudo adduser $USER fuse`.

Uncomment the `user_allow_other` line in the file `/etc/fuse.conf` (using the chosen editor, and remember to open it with `sudo`).

First connect to the share manually: `sshfs pi01:/clusterfs /clusterfs -o auto,_netdev,reconnect,rw,sync,allow_other`. Check (with `ls`) that it mounted correctly, then unmount with `fusermount -u /clusterfs`. Or just skip this step and temporarily include the `sshfs_debug` flag in the next step to allow the host properly. 

Add the following entry to `/etc/fstab` (remember to use `sudo` when opening the editor): `pi01@pi01:/clusterfs /clusterfs fuse.sshfs defaults,auto,delay_connect,_netdev,reconnect,rw,sync,follow_symlinks,allow_other,default_permissions,IdentitiFile=/home/pi02/.ssh/id_rsa 0 0`. Now reload the `fstab` file into the system with `sudo systemctl daemon-reload` and test the mounting with `sudo mount -a`. If it mounted successfully, the command `ls -a /clusterfs` should return results that are on the drive, for example:
```
 .    .Spotlight-V100  'Install Western Digital Software for Mac.dmg'
 ..   .Trashes         'Install Western Digital Software for Windows.exe'
```
(If there are issues in the `fstab` file and and debugging is necessary, add the flag `sshfs_debug` to the list of flags, and then when mounting it, after the sshfs version appears, try to access the mounted directory from another terminal and watch for error messages in the first terminal.)
