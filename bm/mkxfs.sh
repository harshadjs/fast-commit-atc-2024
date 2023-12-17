#!/bin/sh

umount $1 > /dev/null
umount $2 > /dev/null
JOURNAL_DEV=$3

if [ "$JOURNAL_DEV" != "" ]; then
	JRNL_MKFS="-l logdev=$JOURNAL_DEV"
	JRNL_MNT="-o logdev=$JOURNAL_DEV"
fi
mkfs.xfs -f $JRNL_MKFS -ssize=4k $1
mount $1 $2 -o nodev,noatime,attr2,inode64,sunit=256,swidth=1792,noquota,nobarrier $JRNL_MNT
