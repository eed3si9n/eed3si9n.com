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

```bash
lsb_release -a
```

### Ubuntu release cycle

- https://www.ubuntu.com/about/release-cycle
- https://wiki.ubuntu.com/Releases

### upgrading Ubuntu distro

- https://help.ubuntu.com/lts/serverguide/installing-upgrading.html.en

> The recommended way to upgrade a Server Edition installation is to use the do-release-upgrade utility.

```bash
# for AWS
sudo ufw allow 1022/tcp
do-release-upgrade
sudo ufw delete allow 1022/tcp
```

### fix DNS issue on Ubuntu 18.04

Edit: /etc/systemd/resolved.conf

```bash
[Resolve]
DNS=8.8.8.8 2001:4860:4860::8888
FallbackDNS=8.8.4.4 2001:4860:4860::8844
```

```bash
sudo systemctl restart systemd-resolved.service
```


### disk usage

```bash
du -shx */ | sort -rh | head -10
```


### new disk

- https://askubuntu.com/questions/956470/add-additional-hdd-in-ubuntu-16-04

Assuming it's on `/dev/sdb`

```bash
sudo sudo fdisk -l
sudo mkfs.ext4 <device>
sudo mount <device> /data
sudo blkid
```

```bash
/dev/sdb: UUID="123456-*****" TYPE="ext4"
```

/dev/sdb: UUID="3c41630f-e414-47d0-9aea-e967c84934bd" TYPE="ext4"

### get all services

```bash
service --status-all
```

