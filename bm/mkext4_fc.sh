#!/bin/sh

dev=$1
MNT=$2
JOURNAL_DEV=$3
AGING=1

if [ "${dev}" = "ramdisk" ]
then
	echo ========ramdisk========
	umount ${MNT} > /dev/null

	dd if=/dev/zero of=./${dev}/ext4.image bs=1M count=204800 > /dev/null
	mkfs.ext4 -F -E lazy_journal_init=0,lazy_itable_init=0 ./${dev}/ext4.image
	mount -o loop ./${dev}/ext4.image ${MNT}
else
	umount ${dev} > /dev/null
	umount ${MNT} > /dev/null

	JOURNAL_DEV_FLAGS=""
	if [ "$JOURNAL_DEV" != "" ]; then
	        mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_DEV 262144
		JOURNAL_DEV_FLAGS="-J device=$JOURNAL_DEV"
	fi
	# Temp aging
	if [ "$AGING" == "1" ]; then
	    qemu-img convert -O raw /home/harshads/images/ext4_100g_80_fscked.qcow2 ${dev}
	    tune2fs -O fast_commit ${dev}
	else
            mkfs.ext4 -F -O fast_commit -E lazy_journal_init=0,lazy_itable_init=0 ${JOURNAL_DEV_FLAGS} -J fast_commit_size=256 ${dev} > /dev/null
	fi
	mount -t ext4 ${dev} ${MNT} > /dev/null
	sync
fi

