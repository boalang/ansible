#!/bin/sh

pids=""

if test -b /dev/sdb && ! grep -q /dev/sdb /etc/fstab; then
    mke2fs -F -t ext4 /dev/sdb &
    pids="$pids $!"
fi

if test -b /dev/sda4 && ! grep -q /dev/sda4 /etc/fstab; then
    mke2fs -F -t ext4 /dev/sda4 &
    pids="$pids $!"
fi

for pid in $pids; do
    wait "$pid"
done

if test -b /dev/sdb && ! grep -q /dev/sdb /etc/fstab; then
    echo "/dev/sdb	/data1	ext4	defaults,noatime	0	0" >> /etc/fstab
    mkdir /data1
    mount /data1
    chmod 755 /data1
fi

if test -b /dev/sda4 && ! grep -q /dev/sda4 /etc/fstab; then
    echo "/dev/sda4	/data2	ext4	defaults,noatime	0	0" >> /etc/fstab
    mkdir /data2
    mount /data2
    chmod 755 /data2
fi

# On clouldlab the above statements will always execute and prepare the partitions for use,
# but when testing the above statements will not execute, so delete to directory
# contents to facilitate testing the full install script
if [ -d /data1 ]; then
	rm -rf /data1/*
fi

if [ -d /data2 ]; then
	rm -rf /data2/*
fi

#chmod 1755 /data1
#chmod 1755 /data2

