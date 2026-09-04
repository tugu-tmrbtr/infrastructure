# Incus Complete Guide

> **Incus 7.x / Arch Linux / VM + Container Lab Guide**
>
> Энэ guide нь Incus-ийг шинээр суулгахаас эхлээд container, virtual
> machine, network, DHCP, storage, profiles, snapshots, images,
> cloud-init, Terraform, troubleshooting хүртэл өдөр тутам хэрэглэхэд
> зориулж нэг дор цуглуулсан copy-paste reference юм.

------------------------------------------------------------------------

## 0. Incus гэж юу вэ?

Incus бол Linux дээр:

-   **System containers**
-   **Virtual machines**
-   Network
-   Storage
-   Images
-   Profiles
-   Snapshots / backups
-   Clustering
-   REST API

зэргийг удирддаг system container / VM manager юм.

Mental model:

``` text
                        INCUS
                          |
          +---------------+---------------+
          |               |               |
       NETWORK          STORAGE         PROFILES
          |               |               |
      incusbr0          default          default
          |               |               |
     DHCP / DNS       VM disks         devices/config
          |               |
      +---+---+       +---+---+
      |       |       |       |
     VM1     VM2     VM1     VM2
```

Docker-той харьцуулбал:

``` text
Docker                  Incus
------------------------------------------------
docker daemon           incusd
docker network          incus network
docker volume           storage volume
docker container        Incus container
docker run              incus launch
docker exec             incus exec
docker inspect           incus config show / incus info
docker stop             incus stop
docker start            incus start
docker restart          incus restart
docker rm               incus delete
docker images            incus image list
docker pull             incus image copy / launch
```

Incus нь Docker-оос илүү **full system environment** талдаа. VM ч
удирдана.

------------------------------------------------------------------------

# 1. Архитектур

Incus нь client/server architecture ашиглана:

``` text
Your shell
    |
    | incus CLI
    v
  incusd
    |
    +------------------+
    |                  |
    v                  v
 Containers           QEMU VMs
    |                  |
    +--------+---------+
             |
          Network
             |
          Storage
```

Гол процесс:

``` bash
ps aux | grep incusd
```

Service:

``` bash
systemctl status incus
```

------------------------------------------------------------------------

# 2. Arch Linux дээр Incus суулгах

Arch Linux дээр Incus package нь official repository-д байдаг.

``` bash
sudo pacman -Syu
sudo pacman -S incus
```

VM ашиглах бол host virtualization support-оо шалга:

``` bash
lscpu | grep -E 'Virtualization|vmx|svm'
```

AMD бол ихэвчлэн:

``` text
AMD-V / SVM
```

Intel бол:

``` text
VT-x / VMX
```

KVM:

``` bash
lsmod | grep kvm
```

AMD:

``` bash
lsmod | grep kvm_amd
```

Intel:

``` bash
lsmod | grep kvm_intel
```

------------------------------------------------------------------------

# 3. Incus service асаах

Arch дээр socket activation ашиглаж болно:

``` bash
sudo systemctl enable --now incus.socket
```

Эсвэл VM/container-уудаа host boot-той хамт автоматаар ажиллуулахыг
хүсвэл:

``` bash
sudo systemctl enable --now incus.service
```

Шалгах:

``` bash
systemctl status incus
```

``` bash
incus version
```

``` bash
incus info
```

------------------------------------------------------------------------

# 4. User-д Incus permission өгөх

Бүх command-ийг root-аар ажиллуулах шаардлагагүй.

### Full Incus administration

``` bash
sudo usermod -aG incus-admin $USER
```

Дараа нь logout/login хийх.

Эсвэл shell-ээ шинэ group-той болгох:

``` bash
newgrp incus-admin
```

Шалгах:

``` bash
groups
```

> `incus-admin` нь root-той дүйцэх өндөр эрхтэй. Production host дээр
> хэнд өгөхөө болгоомжтой сонго.

Basic per-user access хэрэгтэй бол:

``` bash
sudo usermod -aG incus $USER
```

------------------------------------------------------------------------

# 5. Incus initialize хийх

Анхны configuration:

``` bash
incus admin init
```

Энэ wizard:

-   clustering
-   storage
-   network
-   IPv4
-   IPv6
-   remote API

зэргийг тохируулна.

Lab machine дээр энгийн setup хийхэд:

``` text
Would you like to use clustering? no
Would you like to create a new storage pool? yes
Storage pool name: default
Storage backend: dir
Would you like to create a new local network bridge? yes
Network bridge name: incusbr0
IPv4 address: auto
IPv6 address: none
Would you like the server to be available over the network? no
```

Дараа нь:

``` bash
incus list
```

------------------------------------------------------------------------

# 6. Incus-ийн default objects шалгах

## Remotes

``` bash
incus remote list
```

## Networks

``` bash
incus network list
```

## Storage

``` bash
incus storage list
```

## Profiles

``` bash
incus profile list
```

## Instances

``` bash
incus list
```

## Images

``` bash
incus image list
```

------------------------------------------------------------------------

# 7. Default profile

Incus instance үүсгэхэд `default` profile автоматаар ашиглагддаг.

Харах:

``` bash
incus profile show default
```

Ихэнх setup дээр:

``` yaml
devices:
  eth0:
    name: eth0
    network: incusbr0
    type: nic

  root:
    path: /
    pool: default
    type: disk
```

гэсэн үндсэн devices байна.

Expanded config:

``` bash
incus profile show default
```

Instance ямар profile ашиглаж байгааг:

``` bash
incus config show <instance>
```

------------------------------------------------------------------------

# 8. Images

Image remote-ууд:

``` bash
incus remote list
```

`images:` remote-ийн image:

``` bash
incus image list images:
```

Жишээ:

``` bash
incus image list images: | grep -i alma
```

Specific image:

``` bash
incus image info images:almalinux/10
```

Debian:

``` bash
incus image info images:debian/12
```

Ubuntu:

``` bash
incus image info images:ubuntu/24.04
```

------------------------------------------------------------------------

# 9. Container үүсгэх

Жишээ Ubuntu container:

``` bash
incus launch images:ubuntu/24.04 ubuntu01
```

Шалгах:

``` bash
incus list
```

Output:

``` text
+----------+---------+----------------------+---------------------------------------------+-----------+-----------+
|   NAME   | STATE   |         IPV4         |                    IPV6                     |   TYPE    | SNAPSHOTS |
+----------+---------+----------------------+---------------------------------------------+-----------+-----------+
| ubuntu01 | RUNNING | 10.0.0.100 (eth0)    | ...                                         | CONTAINER | 0         |
+----------+---------+----------------------+---------------------------------------------+-----------+-----------+
```

------------------------------------------------------------------------

# 10. VM үүсгэх

VM үүсгэх үндсэн syntax:

``` bash
incus launch images:ubuntu/24.04 ubuntu-vm --vm
```

VM шалгах:

``` bash
incus list
```

VM-ийн мэдээлэл:

``` bash
incus info ubuntu-vm
```

------------------------------------------------------------------------

# 11. VM resource тохируулах

CPU:

``` bash
incus config set ubuntu-vm limits.cpu 2
```

RAM:

``` bash
incus config set ubuntu-vm limits.memory 8GiB
```

Шалгах:

``` bash
incus config show ubuntu-vm
```

Resource usage:

``` bash
incus info ubuntu-vm
```

------------------------------------------------------------------------

# 12. VM disk

Instance-ийн devices:

``` bash
incus config device list ubuntu-vm
```

Дэлгэрэнгүй:

``` bash
incus config device show ubuntu-vm
```

Root disk resize:

``` bash
incus config device set ubuntu-vm root size=48GiB
```

Дараа нь guest OS дотор partition/filesystem мөн expand хийх
шаардлагатай байж болно.

`size=48GiB` нь virtual disk-ийг томруулдаг болохоос guest partition-ийг
бүх image дээр автоматаар томруулна гэсэн үг биш.

Cloud-init enabled image ашиглавал filesystem auto-grow хийх боломжтой.

------------------------------------------------------------------------

# 13. VM/Container дотор орох

Shell:

``` bash
incus exec ubuntu01 -- bash
```

AlmaLinux:

``` bash
incus exec duskvale -- bash
```

Хэрэв bash байхгүй бол:

``` bash
incus exec ubuntu01 -- sh
```

Root shell:

``` bash
incus exec ubuntu01 -- bash
```

------------------------------------------------------------------------

# 14. VM console

Interactive console:

``` bash
incus console ubuntu-vm
```

Boot log:

``` bash
incus console ubuntu-vm --show-log
```

VM graphical VGA console:

``` bash
incus console ubuntu-vm --type vga
```

Start + console:

``` bash
incus start ubuntu-vm --console
```

------------------------------------------------------------------------

# 15. Instance lifecycle

Start:

``` bash
incus start ubuntu01
```

Stop:

``` bash
incus stop ubuntu01
```

Restart:

``` bash
incus restart ubuntu01
```

Force stop:

``` bash
incus stop ubuntu01 --force
```

Freeze container:

``` bash
incus pause ubuntu01
```

Unfreeze:

``` bash
incus resume ubuntu01
```

Delete:

``` bash
incus delete ubuntu01
```

Running instances:

``` bash
incus list
```

All instances:

``` bash
incus list --format yaml
```

JSON:

``` bash
incus list --format json
```

------------------------------------------------------------------------

# 16. Instance configuration

Basic:

``` bash
incus config show ubuntu01
```

Expanded:

``` bash
incus config show ubuntu01 --expanded
```

Config only:

``` bash
incus config show ubuntu01
```

Get one config:

``` bash
incus config get ubuntu01 limits.cpu
```

Set:

``` bash
incus config set ubuntu01 limits.cpu 4
```

``` bash
incus config set ubuntu01 limits.memory 8GiB
```

Unset:

``` bash
incus config unset ubuntu01 limits.cpu
```

------------------------------------------------------------------------

# 17. Network overview

All networks:

``` bash
incus network list
```

Specific network:

``` bash
incus network show incusbr0
```

IPv4:

``` bash
incus network get incusbr0 ipv4.address
```

DHCP:

``` bash
incus network get incusbr0 ipv4.dhcp
```

NAT:

``` bash
incus network get incusbr0 ipv4.nat
```

IPv6:

``` bash
incus network get incusbr0 ipv6.address
```

IPv6 DHCP:

``` bash
incus network get incusbr0 ipv6.dhcp
```

IPv6 NAT:

``` bash
incus network get incusbr0 ipv6.nat
```

------------------------------------------------------------------------

# 18. Default Incus bridge

Typical lab setup:

``` text
Host
 |
 +-- incusbr0
       |
       +-- 10.0.0.1/24
       |
       +-- DHCP
       +-- DNS
       +-- NAT
       |
       +-- VM1 10.0.0.x
       +-- VM2 10.0.0.x
       +-- CT1 10.0.0.x
```

Incus managed bridge нь DHCP/DNS болон default NAT functionality өгч
чаддаг.

Шалгах:

``` bash
incus network show incusbr0
```

------------------------------------------------------------------------

# 19. DHCP lease

Маш хэрэгтэй command:

``` bash
incus network list-leases incusbr0
```

Жишээ:

``` text
+-----------+-------------------+-------------+-------+
| HOSTNAME  | MAC ADDRESS       | ADDRESS     | TYPE  |
+-----------+-------------------+-------------+-------+
| duskvale  | 00:16:3e:xx:xx:xx | 10.0.0.100  | DYNAMIC |
+-----------+-------------------+-------------+-------+
```

Тэгэхээр:

``` bash
incus network list-leases incusbr0
```

→ DHCP-ээр хэн ямар IP авсныг харна.

------------------------------------------------------------------------

# 20. Instance-ийн IP

``` bash
incus list
```

Specific:

``` bash
incus list duskvale
```

Guest дотор:

``` bash
incus exec duskvale -- ip addr
```

``` bash
incus exec duskvale -- ip route
```

``` bash
incus exec duskvale -- resolvectl status
```

------------------------------------------------------------------------

# 21. Network create

Managed bridge:

``` bash
incus network create labbr0 \
  ipv4.address=10.20.0.1/24 \
  ipv4.nat=true \
  ipv6.address=none
```

Шалгах:

``` bash
incus network show labbr0
```

DHCP lease:

``` bash
incus network list-leases labbr0
```

------------------------------------------------------------------------

# 22. Network config өөрчлөх

DHCP:

``` bash
incus network set labbr0 ipv4.dhcp true
```

NAT:

``` bash
incus network set labbr0 ipv4.nat true
```

IPv6 disable:

``` bash
incus network set labbr0 ipv6.address none
```

IPv4 address:

``` bash
incus network set labbr0 ipv4.address 10.20.0.1/24
```

Delete:

``` bash
incus network delete labbr0
```

------------------------------------------------------------------------

# 23. Instance-д network attach хийх

Existing network:

``` bash
incus config device add ubuntu01 eth0 nic \
  network=labbr0 \
  name=eth0
```

Шалгах:

``` bash
incus config device show ubuntu01
```

Remove:

``` bash
incus config device remove ubuntu01 eth0
```

------------------------------------------------------------------------

# 24. Static IP / DHCP reservation

DHCP reservation тохируулахын өмнө MAC:

``` bash
incus config device show ubuntu01
```

MAC тохируулах:

``` bash
incus config device set ubuntu01 eth0 hwaddr 00:16:3e:11:22:33
```

Network дээр static lease тохируулах:

``` bash
incus network set incusbr0 \
  ipv4.dhcp.ranges=10.0.0.100-10.0.0.200
```

Production static IP-ийг image/guest OS-ийн network config болон Incus
DHCP reservation strategy-тайгаа нэг мөр болгох нь зөв.

------------------------------------------------------------------------

# 25. Host network шалгах

``` bash
ip addr
```

``` bash
ip route
```

Bridge:

``` bash
ip addr show incusbr0
```

Bridge links:

``` bash
bridge link
```

Firewall:

``` bash
sudo nft list ruleset
```

------------------------------------------------------------------------

# 26. Storage overview

Storage pools:

``` bash
incus storage list
```

Specific pool:

``` bash
incus storage show default
```

Usage:

``` bash
incus storage info default
```

Storage driver:

``` bash
incus storage get default driver
```

Source:

``` bash
incus storage get default source
```

------------------------------------------------------------------------

# 27. Storage drivers

Incus supports several storage backends:

``` text
dir
btrfs
lvm
lvmcluster
zfs
ceph
```

Lab:

``` text
dir
```

нь хамгийн энгийн.

Production:

``` text
ZFS
Btrfs
Ceph
```

зэрэг нь workload болон operational requirement-ээс хамаарч илүү
тохиромжтой байж болно.

------------------------------------------------------------------------

# 28. Storage volume

All volumes:

``` bash
incus storage volume list default
```

Create:

``` bash
incus storage volume create default data01
```

Show:

``` bash
incus storage volume show default data01
```

Delete:

``` bash
incus storage volume delete default data01
```

------------------------------------------------------------------------

# 29. Custom storage volume instance-д mount хийх

Volume:

``` bash
incus storage volume create default data01
```

Instance:

``` bash
incus config device add ubuntu01 data disk \
  pool=default \
  source=data01 \
  path=/data
```

Дотор:

``` bash
incus exec ubuntu01 -- df -h
```

``` bash
incus exec ubuntu01 -- ls -la /data
```

Remove:

``` bash
incus config device remove ubuntu01 data
```

Volume өөрөө үлдэнэ.

------------------------------------------------------------------------

# 30. Host storage location

Incus data:

``` bash
sudo du -sh /var/lib/incus
```

Storage pool location:

``` bash
incus storage show default
```

`dir` pool ашиглаж байвал ихэвчлэн:

``` text
/var/lib/incus/storage-pools/default
```

орчимд байна.

Гэхдээ яг path-ийг `incus storage show`-оор шалга.

------------------------------------------------------------------------

# 31. Profiles

Profiles:

``` bash
incus profile list
```

Default:

``` bash
incus profile show default
```

Create:

``` bash
incus profile create vm-profile
```

Show:

``` bash
incus profile show vm-profile
```

Set CPU:

``` bash
incus profile set vm-profile limits.cpu 2
```

Set RAM:

``` bash
incus profile set vm-profile limits.memory 4GiB
```

Add network:

``` bash
incus profile device add vm-profile eth0 nic \
  network=incusbr0 \
  name=eth0
```

Add root disk:

``` bash
incus profile device add vm-profile root disk \
  pool=default \
  path=/
```

------------------------------------------------------------------------

# 32. Profile ашиглаж VM үүсгэх

``` bash
incus launch images:ubuntu/24.04 vm01 \
  --vm \
  --profile vm-profile
```

Олон profile:

``` bash
incus launch images:ubuntu/24.04 vm01 \
  --vm \
  --profile default \
  --profile vm-profile
```

Сүүлийн profile-ийн утга давуу эрхтэй.

Instance-specific config нь profile-аас давуу.

------------------------------------------------------------------------

# 33. Snapshot

Create:

``` bash
incus snapshot create ubuntu01 before-change
```

List:

``` bash
incus snapshot list ubuntu01
```

Show:

``` bash
incus info ubuntu01
```

Restore:

``` bash
incus restore ubuntu01 before-change
```

Delete:

``` bash
incus snapshot delete ubuntu01 before-change
```

------------------------------------------------------------------------

# 34. Snapshot ашиглах workflow

Өөрчлөлт хийхээс өмнө:

``` bash
incus snapshot create duskvale before-upgrade
```

Өөрчлөлт:

``` bash
incus exec duskvale -- dnf update -y
```

Асуудал гарвал:

``` bash
incus restore duskvale before-upgrade
```

------------------------------------------------------------------------

# 35. Copy instance

Clone:

``` bash
incus copy ubuntu01 ubuntu02
```

Remote copy:

``` bash
incus copy ubuntu01 remote1:ubuntu02
```

------------------------------------------------------------------------

# 36. Move instance

Local rename:

``` bash
incus move ubuntu01 ubuntu-prod
```

Remote:

``` bash
incus move ubuntu01 remote1:ubuntu01
```

Cluster member рүү:

``` bash
incus move ubuntu01 --target server02
```

------------------------------------------------------------------------

# 37. Export / backup

Instance export:

``` bash
incus export ubuntu01 ubuntu01.tar.gz
```

Import:

``` bash
incus import ubuntu01.tar.gz
```

Backup strategy:

``` text
Instance
   |
   +-- snapshot
   |
   +-- export
   |
   +-- off-host backup
```

Snapshot-ийг дангаар нь backup гэж үзэхгүй байх нь зөв.

------------------------------------------------------------------------

# 38. Publish instance as image

Container/VM-ээс image:

``` bash
incus publish ubuntu01 --alias ubuntu-custom
```

Image list:

``` bash
incus image list
```

Image info:

``` bash
incus image info ubuntu-custom
```

Launch:

``` bash
incus launch ubuntu-custom new-instance
```

------------------------------------------------------------------------

# 39. Image delete

``` bash
incus image delete <fingerprint>
```

Alias list:

``` bash
incus image list
```

------------------------------------------------------------------------

# 40. File copy

Host → instance:

``` bash
incus file push ./config.yaml ubuntu01/etc/config.yaml
```

Instance → host:

``` bash
incus file pull ubuntu01/etc/config.yaml ./config.yaml
```

Directory:

``` bash
incus file push -r ./config ubuntu01/etc/
```

------------------------------------------------------------------------

# 41. Execute commands

Single command:

``` bash
incus exec ubuntu01 -- hostname
```

Multiple:

``` bash
incus exec ubuntu01 -- bash -c 'dnf update -y && systemctl restart nginx'
```

Environment:

``` bash
incus exec ubuntu01 --env FOO=bar -- bash
```

------------------------------------------------------------------------

# 42. Logs / troubleshooting

Instance info:

``` bash
incus info ubuntu01
```

Console:

``` bash
incus console ubuntu01
```

Boot log:

``` bash
incus console ubuntu01 --show-log
```

Daemon:

``` bash
journalctl -u incus
```

Follow:

``` bash
journalctl -fu incus
```

Kernel:

``` bash
dmesg -T | tail -100
```

------------------------------------------------------------------------

# 43. Incus daemon debug

Service status:

``` bash
systemctl status incus
```

Logs:

``` bash
journalctl -u incus --since "30 minutes ago"
```

Live:

``` bash
journalctl -fu incus
```

Incus info:

``` bash
incus info
```

------------------------------------------------------------------------

# 44. VM boot асуудал

VM ажиллахгүй бол:

``` bash
incus start vm01
```

Error:

``` bash
incus start vm01
```

дараа нь:

``` bash
incus console vm01 --show-log
```

Host virtualization:

``` bash
lscpu | grep Virtualization
```

KVM:

``` bash
lsmod | grep kvm
```

OVMF:

``` bash
pacman -Qs ovmf
```

Arch дээр Secure Boot firmware асуудал гарвал:

``` bash
incus config set vm01 security.secureboot false
```

дараа нь:

``` bash
incus restart vm01
```

------------------------------------------------------------------------

# 45. Network troubleshooting

Instance IP:

``` bash
incus list
```

Network:

``` bash
incus network show incusbr0
```

DHCP:

``` bash
incus network list-leases incusbr0
```

Host bridge:

``` bash
ip addr show incusbr0
```

Guest:

``` bash
incus exec ubuntu01 -- ip addr
```

Route:

``` bash
incus exec ubuntu01 -- ip route
```

DNS:

``` bash
incus exec ubuntu01 -- cat /etc/resolv.conf
```

Connectivity:

``` bash
incus exec ubuntu01 -- ping -c 3 10.0.0.1
```

Internet:

``` bash
incus exec ubuntu01 -- ping -c 3 1.1.1.1
```

DNS:

``` bash
incus exec ubuntu01 -- ping -c 3 google.com
```

------------------------------------------------------------------------

# 46. Firewalld / nftables

Incus managed bridge нь nftables/netfilter ашигладаг.

Host:

``` bash
sudo nft list ruleset
```

Хэрэв host дээр firewall ажиллаж байвал:

``` bash
systemctl status firewalld
```

``` bash
sudo firewall-cmd --list-all
```

VPN, Docker, firewalld, NetworkManager зэрэг нь Incus bridge
networking-тэй conflict үүсгэж болно.

------------------------------------------------------------------------

# 47. Docker + Incus

Docker болон Incus нэг host дээр байж болно.

Гэхдээ Docker-ийн firewall/nftables rules Incus networking-тэй conflict
хийх боломжтой.

Шалгах:

``` bash
docker network ls
```

``` bash
incus network list
```

``` bash
sudo nft list ruleset
```

Incus:

``` bash
ip addr show incusbr0
```

------------------------------------------------------------------------

# 48. NetworkManager

Incus managed bridge-ийг NetworkManager өөрөө удирдах шаардлагагүй.

Шалгах:

``` bash
nmcli device status
```

Incus bridge харагдаж байгаа эсэх:

``` bash
nmcli device status | grep incus
```

NetworkManager Incus interface-д interference хийж байвал тухайн
interface-ийг ignore хийх шаардлага гарч болно.

------------------------------------------------------------------------

# 49. Cloud-init

Cloud-init нь VM/container first boot provisioning хийхэд маш хэрэгтэй.

Жишээ:

``` yaml
#cloud-config

package_update: true

packages:
  - nginx
  - curl

users:
  - name: devops
    groups: sudo
    shell: /bin/bash

runcmd:
  - systemctl enable --now nginx
```

Cloud-init нь **first boot дээр нэг удаа** ажилладаг.

------------------------------------------------------------------------

# 50. Cloud image ба normal image

Энэ distinction маш чухал.

``` text
images:ubuntu/24.04
```

ба

``` text
images:ubuntu/24.04/cloud
```

хоёр өөр image variant байж болно.

Cloud-init ашиглах бол cloud-init enabled image ашиглах нь хамгийн зөв.

Жишээ:

``` bash
incus launch images:ubuntu/24.04/cloud ubuntu-cloud
```

VM:

``` bash
incus launch images:ubuntu/24.04/cloud ubuntu-vm \
  --vm
```

------------------------------------------------------------------------

# 51. Cloud-init-ээр root filesystem auto-grow

VM disk:

``` text
48GiB
```

image root partition:

``` text
4GiB
```

байвал cloud-init enabled image-ийн grow functionality ашигласнаар first
boot үед root filesystem-ийг disk-ийн хэмжээнд тааруулах боломжтой.

Шалгах:

``` bash
incus exec ubuntu-vm -- lsblk
```

``` bash
incus exec ubuntu-vm -- df -h
```

------------------------------------------------------------------------

# 52. Cloud-init debug

Guest:

``` bash
incus exec ubuntu-vm -- cloud-init status
```

``` bash
incus exec ubuntu-vm -- cloud-init status --long
```

Log:

``` bash
incus exec ubuntu-vm -- cat /var/log/cloud-init.log
```

Output:

``` bash
incus exec ubuntu-vm -- cat /var/log/cloud-init-output.log
```

------------------------------------------------------------------------

# 53. VM автомат startup

Instance config:

``` bash
incus config set vm01 boot.autostart true
```

Delay:

``` bash
incus config set vm01 boot.autostart.delay 10
```

Order:

``` bash
incus config set vm01 boot.autostart.priority 10
```

Шалгах:

``` bash
incus config get vm01 boot.autostart
```

------------------------------------------------------------------------

# 54. Container vs VM

## Container

``` bash
incus launch images:ubuntu/24.04 ct01
```

Host kernel-ийг share хийнэ.

Давуу:

-   маш хурдан
-   RAM бага
-   disk бага
-   startup хурдан

## VM

``` bash
incus launch images:ubuntu/24.04 vm01 --vm
```

Өөр kernel-тэй.

Давуу:

-   OS isolation өндөр
-   өөр kernel
-   Windows/Linux VM
-   Kubernetes lab node
-   systemd/full OS behavior

------------------------------------------------------------------------

# 55. Incus VM ашиглах practical example

``` bash
incus launch images:almalinux/10 alma01 \
  --vm \
  --config limits.cpu=2 \
  --config limits.memory=8GiB
```

Disk:

``` bash
incus config device set alma01 root size=48GiB
```

Network:

``` bash
incus list alma01
```

Console:

``` bash
incus console alma01
```

Shell:

``` bash
incus exec alma01 -- bash
```

------------------------------------------------------------------------

# 56. VM resource inspect

``` bash
incus info alma01
```

Guest:

``` bash
incus exec alma01 -- nproc
```

``` bash
incus exec alma01 -- free -h
```

``` bash
incus exec alma01 -- lsblk
```

``` bash
incus exec alma01 -- df -h
```

------------------------------------------------------------------------

# 57. Instance profiles практик

Recommended:

``` text
default
   |
   +-- network
   +-- root disk

vm-small
   |
   +-- 2 CPU
   +-- 4 GiB

vm-medium
   |
   +-- 4 CPU
   +-- 8 GiB

k3s-node
   |
   +-- 4 CPU
   +-- 8 GiB
   +-- network
```

Create:

``` bash
incus profile create k3s-node
```

Set:

``` bash
incus profile set k3s-node limits.cpu 4
incus profile set k3s-node limits.memory 8GiB
```

Network:

``` bash
incus profile device add k3s-node eth0 nic \
  network=incusbr0 \
  name=eth0
```

------------------------------------------------------------------------

# 58. K3s lab VM example

``` bash
incus launch images:almalinux/10 k3s-01 \
  --vm
```

``` bash
incus config set k3s-01 limits.cpu 4
```

``` bash
incus config set k3s-01 limits.memory 8GiB
```

``` bash
incus config device set k3s-01 root size=32GiB
```

Check:

``` bash
incus list
```

------------------------------------------------------------------------

# 59. Incus as a mini virtualization platform

Typical homelab:

``` text
                    Incus Host
                        |
          +-------------+-------------+
          |             |             |
       k3s-01        k3s-02        k3s-03
       4 CPU          4 CPU          4 CPU
       8 GB           8 GB           8 GB
       32 GB          32 GB          32 GB
          |             |             |
          +-------------+-------------+
                        |
                    incusbr0
                        |
                  DHCP / DNS / NAT
```

Additional:

``` text
db01
monitoring01
gitlab01
ansible01
```

------------------------------------------------------------------------

# 60. Terraform + Incus

Terraform provider:

``` hcl
terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "1.2.0"
    }
  }
}

provider "incus" {}
```

Instance:

``` hcl
resource "incus_instance" "vm" {
  name  = "vm01"
  type  = "virtual-machine"
  image = "images:ubuntu/24.04"

  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "4GiB"
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      pool = "default"
      path = "/"
      size = "32GiB"
    }
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      network = "incusbr0"
    }
  }

  device {
    name = "agent"
    type = "disk"

    properties = {
      source = "agent:config"
      path   = "/dev/incus"
    }
  }
}
```

------------------------------------------------------------------------

# 61. Terraform workflow

``` bash
terraform init
```

``` bash
terraform fmt
```

``` bash
terraform validate
```

``` bash
terraform plan
```

``` bash
terraform apply
```

Destroy:

``` bash
terraform destroy
```

------------------------------------------------------------------------

# 62. Terraform recommended project structure

``` text
provisioning/
├── providers.tf
├── variables.tf
├── network.tf
├── storage.tf
├── instances.tf
├── outputs.tf
├── terraform.tfvars
└── cloud-init/
    ├── common.yaml
    ├── alma.yaml
    └── ubuntu.yaml
```

Environment:

``` text
provisioning/
├── dev/
├── staging/
└── prod/
```

------------------------------------------------------------------------

# 63. Terraform + cloud-init

Recommended flow:

``` text
Terraform
   |
   v
Incus instance
   |
   v
Cloud-init
   |
   +-- users
   +-- packages
   +-- SSH
   +-- filesystem grow
   +-- systemd
   +-- basic OS config
   |
   v
Ansible
   |
   +-- application config
   +-- hardening
   +-- monitoring
```

Terraform нь infrastructure lifecycle.

Ansible нь configuration management.

------------------------------------------------------------------------

# 64. Incus API

Incus нь REST API-тай.

API endpoint:

``` bash
incus query /1.0
```

Instances:

``` bash
incus query /1.0/instances
```

Networks:

``` bash
incus query /1.0/networks
```

Storage:

``` bash
incus query /1.0/storage-pools
```

Operations:

``` bash
incus operation list
```

------------------------------------------------------------------------

# 65. Remotes

Remotes:

``` bash
incus remote list
```

Add remote:

``` bash
incus remote add myserver https://10.0.0.10:8443
```

Use remote:

``` bash
incus list myserver:
```

Launch:

``` bash
incus launch images:ubuntu/24.04 vm01
```

Remote instance:

``` bash
incus launch images:ubuntu/24.04 myserver:vm01
```

------------------------------------------------------------------------

# 66. Projects

List:

``` bash
incus project list
```

Show:

``` bash
incus project show default
```

Create:

``` bash
incus project create dev
```

Switch:

``` bash
incus project switch dev
```

List instances in current project:

``` bash
incus list
```

Projects нь multi-tenant separation хийхэд ашиглагдана.

------------------------------------------------------------------------

# 67. Cluster

Cluster initialize:

``` bash
incus admin init
```

Cluster members:

``` bash
incus cluster list
```

Member info:

``` bash
incus cluster show <member>
```

Instance location:

``` bash
incus list
```

Target member:

``` bash
incus launch images:ubuntu/24.04 vm01 \
  --target server02
```

Move:

``` bash
incus stop vm01
incus move vm01 --target server02
incus start vm01
```

Cluster production design:

``` text
              Incus Cluster
       +----------+----------+
       |          |          |
    node01      node02     node03
       |          |          |
      VM         VM         VM
```

Storage architecture-ийг cluster design-тэй тусад нь төлөвлөнө.

------------------------------------------------------------------------

# 68. Storage production guideline

Lab:

``` text
dir
```

Production:

``` text
ZFS
Btrfs
Ceph
```

Incus documentation нь production-д loop-backed storage-аас зайлсхийж,
dedicated disk/partition зэрэг ашиглахыг зөвлөдөг.

Жишээ:

``` text
/dev/nvme1
     |
     v
    ZFS
     |
     +-- Incus pool
           |
           +-- VM01
           +-- VM02
           +-- VM03
```

------------------------------------------------------------------------

# 69. Useful one-liners

All instances:

``` bash
incus list
```

All networks:

``` bash
incus network list
```

All storage:

``` bash
incus storage list
```

All profiles:

``` bash
incus profile list
```

All images:

``` bash
incus image list
```

DHCP:

``` bash
incus network list-leases incusbr0
```

VM config:

``` bash
incus config show vm01 --expanded
```

VM resources:

``` bash
incus info vm01
```

VM shell:

``` bash
incus exec vm01 -- bash
```

VM console:

``` bash
incus console vm01
```

------------------------------------------------------------------------

# 70. Daily operations cheat sheet

## Create

``` bash
incus launch images:ubuntu/24.04 vm01 --vm
```

## List

``` bash
incus list
```

## Start

``` bash
incus start vm01
```

## Stop

``` bash
incus stop vm01
```

## Restart

``` bash
incus restart vm01
```

## Shell

``` bash
incus exec vm01 -- bash
```

## Config

``` bash
incus config show vm01 --expanded
```

## Resources

``` bash
incus info vm01
```

## Snapshot

``` bash
incus snapshot create vm01 before-change
```

## Restore

``` bash
incus restore vm01 before-change
```

## Delete

``` bash
incus delete vm01
```

## Force delete

``` bash
incus delete vm01 --force
```

------------------------------------------------------------------------

# 71. Full environment inspection

Энэ хэсгийг copy-paste diagnostic script шиг ашиглаж болно:

``` bash
echo "===== INCUS VERSION ====="
incus version

echo
echo "===== SERVER INFO ====="
incus info

echo
echo "===== REMOTES ====="
incus remote list

echo
echo "===== PROJECTS ====="
incus project list

echo
echo "===== PROFILES ====="
incus profile list

echo
echo "===== NETWORKS ====="
incus network list

echo
echo "===== STORAGE ====="
incus storage list

echo
echo "===== INSTANCES ====="
incus list

echo
echo "===== IMAGES ====="
incus image list
```

------------------------------------------------------------------------

# 72. Default environment inspection

``` bash
incus profile show default
```

``` bash
incus network show incusbr0
```

``` bash
incus storage show default
```

``` bash
incus storage info default
```

------------------------------------------------------------------------

# 73. VM complete inspection

``` bash
incus config show duskvale --expanded
```

``` bash
incus info duskvale
```

``` bash
incus config device show duskvale
```

``` bash
incus network list-leases incusbr0
```

Guest:

``` bash
incus exec duskvale -- lsblk
```

``` bash
incus exec duskvale -- df -h
```

``` bash
incus exec duskvale -- ip addr
```

``` bash
incus exec duskvale -- ip route
```

------------------------------------------------------------------------

# 74. Recommended Incus workflow

Шинэ VM:

``` text
1. Choose image
       |
2. Choose profile
       |
3. Choose CPU/RAM
       |
4. Choose storage
       |
5. Choose network
       |
6. Launch
       |
7. cloud-init
       |
8. Verify IP
       |
9. Verify disk
       |
10. Ansible provisioning
```

Commands:

``` bash
incus launch images:almalinux/10/cloud duskvale \
  --vm \
  --config limits.cpu=2 \
  --config limits.memory=8GiB
```

``` bash
incus config device set duskvale root size=48GiB
```

``` bash
incus list
```

``` bash
incus network list-leases incusbr0
```

``` bash
incus exec duskvale -- lsblk
```

``` bash
incus exec duskvale -- df -h
```

------------------------------------------------------------------------

# 75. Recommended IaC architecture

Чиний SRE/DevOps lab-д:

``` text
                    Git
                     |
                     v
                 Terraform
                     |
                     v
                   Incus
        +------------+------------+
        |            |            |
       VM           VM           VM
        |            |            |
    AlmaLinux    AlmaLinux    AlmaLinux
        |            |            |
        +------------+------------+
                     |
                  Ansible
                     |
          +----------+----------+
          |          |          |
        k3s       monitoring    DB
```

Responsibilities:

``` text
Terraform
  └── VM/Container
  └── CPU/RAM/Disk
  └── Network
  └── Storage
  └── Profiles

Cloud-init
  └── First boot
  └── User
  └── SSH
  └── Packages
  └── Disk grow

Ansible
  └── OS configuration
  └── Security hardening
  └── Services
  └── Applications

Kubernetes
  └── Container orchestration
```

------------------------------------------------------------------------

# 76. Important distinction: Incus vs Docker vs Kubernetes

``` text
Physical host
     |
     v
   Incus
     |
     +--------------------------+
     |                          |
     v                          v
    VM                     Container
     |
     v
   Linux OS
     |
     v
    k3s
     |
     v
 Kubernetes Pods
```

Өөрөөр:

``` text
Incus       = machine / VM / system container layer
Docker      = application container layer
Kubernetes  = container orchestration layer
Ansible     = configuration management layer
Terraform   = infrastructure provisioning layer
```

Эдгээрийг нэгнийгээ шууд орлох зүйл гэж ойлгохгүй.

------------------------------------------------------------------------

# 77. Production checklist

## Host

``` bash
lscpu
free -h
lsblk
ip addr
```

## Incus

``` bash
incus version
incus info
```

## Storage

``` bash
incus storage list
incus storage info default
```

## Network

``` bash
incus network list
incus network show incusbr0
incus network list-leases incusbr0
```

## Profiles

``` bash
incus profile list
incus profile show default
```

## Instances

``` bash
incus list
```

## Backup

``` bash
incus snapshot list <instance>
```

## Logs

``` bash
journalctl -fu incus
```

------------------------------------------------------------------------

# 78. Most useful commands table

  Task               Command
  ------------------ ----------------------------------------------
  Incus version      `incus version`
  Server info        `incus info`
  List instances     `incus list`
  Launch container   `incus launch images:ubuntu/24.04 ct01`
  Launch VM          `incus launch images:ubuntu/24.04 vm01 --vm`
  Start              `incus start vm01`
  Stop               `incus stop vm01`
  Restart            `incus restart vm01`
  Shell              `incus exec vm01 -- bash`
  Console            `incus console vm01`
  Config             `incus config show vm01 --expanded`
  Resource info      `incus info vm01`
  Networks           `incus network list`
  Network config     `incus network show incusbr0`
  DHCP leases        `incus network list-leases incusbr0`
  Storage            `incus storage list`
  Storage info       `incus storage info default`
  Profiles           `incus profile list`
  Profile config     `incus profile show default`
  Images             `incus image list`
  Snapshot           `incus snapshot create vm01 snap1`
  Snapshot list      `incus snapshot list vm01`
  Restore            `incus restore vm01 snap1`
  Copy               `incus copy vm01 vm02`
  Move               `incus move vm01 vm02`
  Delete             `incus delete vm01`
  File push          `incus file push file vm01/path`
  File pull          `incus file pull vm01/path file`
  Daemon logs        `journalctl -fu incus`

------------------------------------------------------------------------

# 79. Quick reference

``` bash
# SYSTEM
incus version
incus info

# INSTANCES
incus list
incus launch images:ubuntu/24.04 vm01 --vm
incus start vm01
incus stop vm01
incus restart vm01
incus delete vm01

# ACCESS
incus exec vm01 -- bash
incus console vm01

# CONFIG
incus config show vm01 --expanded
incus info vm01
incus config device show vm01

# NETWORK
incus network list
incus network show incusbr0
incus network list-leases incusbr0

# STORAGE
incus storage list
incus storage show default
incus storage info default
incus storage volume list default

# PROFILE
incus profile list
incus profile show default

# IMAGE
incus image list
incus image info images:ubuntu/24.04

# SNAPSHOT
incus snapshot create vm01 before-change
incus snapshot list vm01
incus restore vm01 before-change

# FILE
incus file push ./file vm01/tmp/file
incus file pull vm01/tmp/file ./file

# LOG
journalctl -fu incus
```

------------------------------------------------------------------------

# 80. Final mental model

Incus-ийг дараах байдлаар ойлговол хамгийн амар:

``` text
                         INCUS
                           |
          +----------------+----------------+
          |                |                |
       PROJECT          PROFILE          REMOTE
          |                |
          |          +-----+------+
          |          |            |
          |        NETWORK      STORAGE
          |          |            |
          +----------+------------+
                     |
                 INSTANCE
              +------+------+
              |             |
           CONTAINER        VM
              |             |
              |          QEMU/KVM
              |             |
              +------+------+
                     |
                  SNAPSHOT
                     |
                   IMAGE
```

Instance:

``` text
instance
  |
  +-- config
  |
  +-- devices
  |     |
  |     +-- eth0 -> network
  |     +-- root -> storage
  |     +-- data -> custom volume
  |
  +-- profiles
  |
  +-- snapshots
  |
  +-- image
```

Ингэж mental model-оо суулгачихвал Incus CLI-ийн ихэнх command-ийг
нэрнээс нь шууд тааж чадна.

------------------------------------------------------------------------

## Official references

-   Incus installation:
    https://linuxcontainers.org/incus/docs/main/installing/
-   Initialization:
    https://linuxcontainers.org/incus/docs/main/howto/initialize/
-   First steps:
    https://linuxcontainers.org/incus/docs/main/tutorial/first_steps/
-   Instance creation:
    https://linuxcontainers.org/incus/docs/main/howto/instances_create/
-   Instance management:
    https://linuxcontainers.org/incus/docs/main/howto/instances_manage/
-   Networking:
    https://linuxcontainers.org/incus/docs/main/explanation/networks/
-   Bridge networking:
    https://linuxcontainers.org/incus/docs/main/reference/network_bridge/
-   Storage:
    https://linuxcontainers.org/incus/docs/main/explanation/storage/
-   Profiles: https://linuxcontainers.org/incus/docs/main/profiles/
-   Cloud-init: https://linuxcontainers.org/incus/docs/main/cloud-init/

> **Note:** Incus-ийн CLI болон configuration options хувилбараас
> хамаарч бага зэрэг өөрчлөгдөж болно. Тухайн host дээр хамгийн үнэн зөв
> reference нь `incus <command> --help`,
> `incus <command> <subcommand> --help` юм.
