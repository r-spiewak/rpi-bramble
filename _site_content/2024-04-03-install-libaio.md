---
title: "Libaio Installation"
date: 2024-04-03
order: 7
id: install-libaio
---

`libaio` can be installed through package managers or through a build from source.

## Through Package Managers

Run `sudo apt-get install libaio` or `sudo apt-get install libaio1` on each node (or maybe only on the head node?).

## Through Build from Source

On the head node, first get the most recent release (at this time, it seems to be 0.3.113):
```
sudo wget -P /clusterfs/scratch https://pagure.io/libaio/archive/libaio-0.3.113/libaio-0.3.113.tar.gz
```

Then `cd` into the scratch directory (`cd /clusterfs/scratch`), and run the following (changing the release version to match the latest release acquired above) to start the configuration:
```
sudo tar xf libaio-0.3.113.tar.gz --no-same-owner
cd libaio-0.3.113
sudo sed -i '/install.*libaio.a/s/^/#/' src/Makefile
```
Also edit the outer `Makefile` (`sudo nano Makefile`) and the inner `Makefile` (`sudo nano src/Makefile`) so that the line `prefix=/usr` near the top becomes `prefix=/clusterfs/usr`.
```
sudo make
sudo make partcheck
sudo make install
```
{% comment %}
<!-- If there are any errors, you're on your own... I just ignored some errors. -->
{% endcomment %}

{% comment %}
Link library to somewhere? Looks like it put it in `/clusterfs/usr/lib/`. So probably:
{% endcomment %} 
On every node, link the library files:
```
sudo ln -s /clusterfs/usr/lib/libaio.so.1.0.2 /usr/lib/libaio.so.1.0.2
sudo ln -s /clusterfs/usr/lib/libaio.so.1 /usr/lib/libaio.so.1
sudo ln -s /clusterfs/usr/lib/libaio.so /usr/lib/libaio.so
```

Note: It's entirely possible that this library only needs to be present on the node actually building other programs, and not actually on each node to run the other programs.
