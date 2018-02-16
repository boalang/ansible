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
    mkdir -p /data1
    mount /data1
    chmod 755 /data1
fi

if test -b /dev/sda4 && ! grep -q /dev/sda4 /etc/fstab; then
    echo "/dev/sda4	/data2	ext4	defaults,noatime	0	0" >> /etc/fstab
    mkdir -p /data2
    mount /data2
    chmod 755 /data2
fi


mkdir -p /data1
chmod 1755 /data1

mkdir -p /data2
chmod 1755 /data2

