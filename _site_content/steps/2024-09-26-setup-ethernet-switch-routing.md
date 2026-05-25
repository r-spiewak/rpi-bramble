---
title: "Setup Ethernet Port Switch and Routing"
date: 2024-09-26
order: 4
id: setup-port-switch
---

On [the previous page](2024-03-26-OS-setup.md), the pis were connected via their built-in wifi to the router. For a more stable connection, we want a wired connection between them. To that end, we include an unmanaged ethernet port switch, which we connect here.

Since the switch is unmanaged, it will not do any routing. We will have to configure the routing ourselves, by creating a dhcp server on one of the pis and either by using static IP addresses or by configuring dynamic routing. 

## DHCP Server Setup

We will do the following on the head node, where we will be setting up the dhcp server.

Before plugging anything in, first check the status of the current network configuration: `ip addr show`. The entry for `wlan0` should have a number of lines, whereas the entry `eth0` (which probably appears before `wlan0`) should pretty much just have a line with a MAC address. 

After plugging in (and turning on) the port switch, a new entry should appear in the `eth0` section. However, it does not have an IPv4 address, only an IPv6 address.

Next, install the dhcpd server saemon: `sudo apt-get install kea` (see [this page](https://www.isc.org/dhcp_migration/) for why we choose `kea` over `isc-dhcp-server`). With this package, we can set up routing, as well as statically assign IP addresses from the routing head node (we could also set up each pi to request a static IP address in their `/etc/dhcp/dhclient.conf` file, but here we will use this method as it will allow us to configure everything all in one place). 

Start by opening the file `/etc/kea/kea-dhcp4.conf` for editing: `sudo nano /etc/kea/kea-dhcp4.conf`. A [sample configuration file](https://r-spiewak.github.io/rpi-bramble/files/shared-storage/kea-dhcp4.conf) follows:
{% highlight bash %}
{%- root_include /files/shared-storage/kea-dhcp4.conf -%}
{% endhighlight %}

Next, the `kea-ctrl-agent` service, which controls the server, must be configured and started. The default configuration file `/etc/kea/kea-ctrl-agent.conf` is likely sufficient and can be left alone, but the `kea-ctrl-agent` service does require a password or else it won't start. The password should be put in `/etc/kea/kea-api-password`, with ownership `root:_kea` and permissions `0640`. So first enter a password into the file with `sudo nano /etc/kea/kea-api-password`, then do `sudo chown root:_kea /etc/kea/kea-api-password` and `sudo chmod 640 /etc/kea/kea-api-password`.

Now the DHCP server is ready to be started. First, enable and start the service:
```
sudo systemctl enable kea-ctrl-agent
sudo systemctl start kea-ctrl-agent
```
Check that is is running successfully with `sudo systemctl status kea-ctrl-agent`.

If the configuration files need to be subsequently changed, the service can reload the configuration while running by using the command `sudo kea-shell --host 127.0.0.1 --port 8000 --auth-user kea-api --auth-password $(sudo cat /etc/kea/kea-api-password) --service dhcp4 config-reload` and then pressing the `ctrl-d` keyboard combination. If the response is `[ { "result": 0, "text": "Configuration successful." } ]`, then the configuration was successfully reloaded. Or just restart the server: `sudo systemctl restart kea-dhcp4-server`.

The leases can be viewed in the file `/var/lib/kea/kea-leases4.csv`.

It may (or may not) be necessary to manually add an IP address for this pi. To do so, `sudo ip addr add 10.0.0.1/24 dev eth0` will manually add an IP address. 
{% comment %}
But it will go away (and the same issue of "WARN  DHCPSRV_OPEN_SOCKET_FAIL failed to open socket: the interface eth0 has no usable IPv4 addresses configured" will appear in the messages like in `sudo journalctl -u kea-dhcp4-server` and `sudo systemctl status kea-dhcp4-server`) upon restart? Or maybe only with the suffix /32 it'll go away?
{% endcomment %}

## Connect Other Nodes

Now, just plug in the other pis to the port switch, and the server should automatically assign them the correct IP addresses.

Finally, add/modify the entries in each pis `~/.ssh/config` file to refer to the ethernet IP address of each pi (the ones fixed in the `/etc/kea/kea-dhcp4.conf` file), instead of their WiFi IP address. (If these steps have been followed out of order, also modify the entry on the head node's `/etc/exports`, the entry in each pi's `fstab` file to load the shared drive from the ethernet IP address, and the entry in each pi's `/scripts/mount-shared.sh` to look for it on the ethernet IP address as well.)

"option-data": [
    {
        "name": "domain-name",
        "data": "bramble.local"
    },
    {
        "name": "domain-search",
        "data": "*.bramble.local, bramble.local"
    }
]