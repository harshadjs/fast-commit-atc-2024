#!/bin/sh

umount $1 > /dev/null
umount $2 > /dev/null
JOURNAL_DEV=$3

if [ "$JOURNAL_DEV" != "" ]; then
	JRNL_MKFS="-l logdev=$JOURNAL_DEV"
	JRNL_MNT="-o logdev=$JOURNAL_DEV"
fi
mkfs.xfs -f -d agsize=419614818304,sunit=256,swidth=1792 $JRNL_MKFS-l sunit=256 $1

#mount $1 $2 -o nodev,noatime,attr2,inode64,sunit=256,swidth=1792,noquota
mount $1 $2 -o nodev,noatime,attr2,inode64,sunit=256,swidth=1792,noquota,nobarrier $JRNL_MNT
