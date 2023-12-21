#!/bin/sh

umount $1 > /dev/null
umount $2 > /dev/null
mkfs.f2fs -f $1
mount $1 $2
