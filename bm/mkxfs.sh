#!/bin/sh

umount $1 > /dev/null
umount $2 > /dev/null
JOURNAL_DEV=$3

if [ "$JOURNAL_DEV" != "" ]; then
	JRNL_MKFS="-l logdev=$JOURNAL_DEV,size=1G"
	JRNL_MNT="-o logdev=$JOURNAL_DEV"
fi
mkfs.xfs -f $JRNL_MKFS -ssize=4k $1
mount $1 $2 $JRNL_MNT
