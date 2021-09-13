---
title:       "Linux memo"
type:        story
date:        2018-12-03
draft:       true
sticky:      false
url:         /linux-memo
tags:        [ "bash" ]
---

### show distro version

<code>
lsb_release -a
</code>

### Ubuntu release cycle

- https://www.ubuntu.com/about/release-cycle
- https://wiki.ubuntu.com/Releases

### upgrading Ubuntu distro

- https://help.ubuntu.com/lts/serverguide/installing-upgrading.html.en

> The recommended way to upgrade a Server Edition installation is to use the do-release-upgrade utility.

<code>
# for AWS
sudo ufw allow 1022/tcp
do-release-upgrade
sudo ufw delete allow 1022/tcp
</code>

### fix DNS issue on Ubuntu 18.04

Edit: /etc/systemd/resolved.conf

<code>
[Resolve]
DNS=8.8.8.8 2001:4860:4860::8888
FallbackDNS=8.8.4.4 2001:4860:4860::8844
</code>

<code>
sudo systemctl restart systemd-resolved.service
</code>


### disk usage

<code>
du -shx */ | sort -rh | head -10
</code>


### new disk

- https://askubuntu.com/questions/956470/add-additional-hdd-in-ubuntu-16-04

Assuming it's on `/dev/sdb`

<code>
sudo sudo fdisk -l
sudo mkfs.ext4 <device>
sudo mount <device> /data
sudo blkid
</code>

<code>
/dev/sdb: UUID="123456-*****" TYPE="ext4"
</code>

/dev/sdb: UUID="3c41630f-e414-47d0-9aea-e967c84934bd" TYPE="ext4"

### get all services

<code>
service --status-all
</code>

