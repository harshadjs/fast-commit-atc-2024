1#!/bin/sh

umount $1 > /dev/null
umount $2 > /dev/null
JOURNAL_DEV=$3
AGING=1

if [ "$JOURNAL_DEV" != "" ]; then
	JRNL_MKFS="-l logdev=$JOURNAL_DEV,size=1G"
	JRNL_MNT="-o logdev=$JOURNAL_DEV"
fi
if [ "$AGING" == "1" ]; then
    xfs_mdrestore -i /home/harshads/images/xfs_100G_80.img $1
else
    mkfs.xfs -f $JRNL_MKFS -ssize=4k $1
fi
mount $1 $2 $JRNL_MNT
