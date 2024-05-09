#!/bin/bash

# Library functions to create file systems

function make_ext4() {
    dev=$1
    MNT=$2
    JOURNAL_DEV=$3
    AGING=0

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
	if [ "$AGING" == "1" ]; then
	    qemu-img convert -O raw /home/harshads/images/ext4_100g_80_fscked.qcow2 ${dev}
	else
	    mkfs.ext4 $JOURNAL_DEV_FLAGS -F -E lazy_journal_init=0,lazy_itable_init=0 ${dev} > /dev/null
	fi
	mount -t ext4 ${dev} ${MNT} > /dev/null
	sync
    fi

}

function make_ext4_fc() {
    dev=$1
    MNT=$2
    JOURNAL_DEV=$3
    AGING=0

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

}

function make_ext4_async() {
    dev=$1
    MNT=$2
    JOURNAL_DEV=$3
    AGING=0

    if [ "${dev}" = "ramdisk" ]
    then
	echo ========ramdisk========
	umount ${MNT} > /dev/null

	dd if=/dev/zero of=./${dev}/ext4.image bs=1M count=204800 > /dev/null
	mkfs.ext4 -O journal_async_commit -F -E lazy_journal_init=0,lazy_itable_init=0 ./${dev}/ext4.image
	mount -o loop ./${dev}/ext4.image ${MNT}
    else
	umount ${dev} > /dev/null
	umount ${MNT} > /dev/null

	JOURNAL_DEV_FLAGS=""
	if [ "$JOURNAL_DEV" != "" ]; then
	    mkfs.ext4 -F -O journal_dev -b 4096 $JOURNAL_DEV 262144
	    JOURNAL_DEV_FLAGS="-J device=$JOURNAL_DEV"
	fi
	if [ "$AGING" == "1" ]; then
	    qemu-img convert -O raw /home/harshads/images/ext4_100g_80_fscked.qcow2 ${dev}
	else
	    mkfs.ext4 $JOURNAL_DEV_FLAGS -F -E lazy_journal_init=0,lazy_itable_init=0 ${dev} > /dev/null
	fi
	mount -O journal_async_commit -t ext4 ${dev} ${MNT} > /dev/null
	sync
    fi

}    

function make_xfs() {
    umount $1 > /dev/null
    umount $2 > /dev/null
    JOURNAL_DEV=$3
    AGING=0

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
}

function make_f2fs() {
    umount $1 > /dev/null
    umount $2 > /dev/null
    mkfs.f2fs -f $1
    mount $1 $2
}    


STOP_FILE=stop
NFS_SERVER_DONE=server_done
START_FILE=start
OUTDIR=~/results

CONFIGS_DIR=$1
NFS_SERVER_IP_ADDRESS=$2
LOCAL_SERVER_MNT="/server"
MEMORY_FOOTPRINT=0
CPU_USAGE=0

if [ "$LOCAL_NFS_SERVER" == "1" ]; then
    mkdir -p $LOCAL_SERVER_MNT
fi


nfs_client_start() {
    echo "Waiting for NFS Server..."
    while [ ! -f ${MNT}/${START_FILE}$NFS_CLIENT_ID ]; do
	umount $MNT
	sleep 1
	mount -t nfs ${NFS_CLIENT_OPS} ${NFS_SERVER_IP_ADDRESS}:/mnt $MNT
    done
    rm ${MNT}/${START_FILE}$NFS_CLIENT_ID
    echo "Connected."
}

pre_run_workload() 
{
    UNIQ_OUTDIR=$1
    num_threads=$2

    # Format and Mount
    service nfs-kernel-server stop
    umount $MNT
    umonut $LOCAL_SERVER_MNT
    mntpt=$MNT
    if [ "$LOCAL_NFS_SERVER" == "1" ]; then
	mntpt=$LOCAL_SERVER_MNT
    fi
    if [ "${NFS_CLIENT}" == "1" ]; then
	echo "This is a NFS Client, using $NFS_SERVER_IP_ADDRESS IP address"
	nfs_client_start
    elif [ "${FS}" == "XFS" ]; then
	make_xfs $dev $mntpt $JOURNAL_DEV
    elif [ "${FS}" == "EXT4FC" ]; then
	make_ext4_fc $dev $mntpt $JOURNAL_DEV
    elif [ "${FS}" == "EXT4ASYNC" ]; then
	make_ext4_async $dev $mntpt $JOURNAL_DEV
    elif [ "${FS}" == "F2FS" ];then
	make_f2fs $dev $mntpt $JOURNAL_DEV
    else
	make_ext4 $dev $mntpt $JOURNAL_DEV
    fi

    echo "==== Format complete ===="
    if [ "$NFS_SERVER" == "1" ]; then
	echo "This is a NFS Sever, with $num_threads threads."
	service nfs-kernel-server restart
	exportfs -a
	ifconfig
	/usr/sbin/rpc.nfsd $num_threads
	export BENCHMARK="noop"
    elif [ "$LOCAL_NFS_SERVER" == "1" ]; then
	echo "This is a LOCAL NFS Sever."
	service nfs-kernel-server restart
	exportfs -a
	echo "Mounting localhost:$LOCAL_SERVER_MNT on $MNT"
	mount localhost:$LOCAL_SERVER_MNT -t nfs $MNT
    fi


    sync && sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    dmesg -c > ${UNIQ_OUTDIR}/log.txt
    iostat > ${UNIQ_OUTDIR}/iostat_before.dat
    iostat -x -y -p 1 > ${UNIQ_OUTDIR}/iostat.dat&
    cp ~/fast-commit-override.sh ${UNIQ_OUTDIR}/config
    if [ "$NFS_SERVER" == "1" ]; then
	iter=0
	if [ "$NUM_CLIENTS" != "" ]; then
	    while [ $iter -lt $NUM_CLIENTS ]; do
		touch $MNT/$START_FILE$iter
		iter=$((iter+1))
	    done
	else
	    touch $MNT/$START_FILE
	fi
    fi
}


debug()
{

    UNIQ_OUTDIR=$1
    num_threads=$2
    dev=$3
    iostat > ${UNIQ_OUTDIR}/iostat_after.dat;
    killall iostat
    if [ "$JOURNAL_DEV" == "" ]; then
	cat /proc/fs/jbd2/${dev:5}-8/info > ${UNIQ_OUTDIR}/info.dat;
    else
	cat /proc/fs/jbd2/${JOURNAL_DEV:5}/info > ${UNIQ_OUTDIR}/info.dat;
    fi
    cat /proc/fs/ext4/${dev:5}/fc_info > ${UNIQ_OUTDIR}/fc_info.dat
    dmesg -c > ${UNIQ_OUTDIR}/log_${num_threads}.txt
}

select_workload() 
{

    UNIQ_OUTDIR=$1
    num_threads=$2
    echo 0 > /proc/sys/kernel/randomize_va_space

    case $BENCHMARK in
	"filebench-varmail")
	    bin/filebench -f workloads/varmail_${num_threads}.f \
			  > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-varmail-1m")
	    bin/filebench_1m -f workloads/varmail_${num_threads}_long.f \
			     > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-varmail-10m")
	    bin/filebench_10m -f workloads/varmail_${num_threads}_long.f \
			      > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-fileserver")
	    bin/filebench -f workloads/fileserver_${num_threads}.f \
			  > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-fileserver-1m")
	    bin/filebench_1m -f workloads/fileserver_${num_threads}_long.f \
			     > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-fileserver-10m")
	    bin/filebench_10m -f workloads/fileserver_${num_threads}_long.f \
			      > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-webserver")
	    filebench -f workloads/webserver_${num_threads}.f \
		      > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"filebench-networkfs")
	    filebench -f workloads/networkfs_${num_threads}.f \
		      > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"postmark")
	    postmark workloads/postmark > ${UNIQ_OUTDIR}/result.dat
	    ;;
	"dbench")
	    dbench -c /usr/share/dbench/client.txt -D $MNT -t 60 $num_threads
	    ;;
	"fsmark2")
	    fs_mark -t 5 -n 100000 -s 8192 -w 4096 -d $MNT > ${UNIQ_OUTDIR}/result.dat
	    ;;
	"fsmark")
	    fs_mark -t ${num_threads} -n 10000 -s 16384 -w 8192 -d $MNT > ${UNIQ_OUTDIR}/result.dat
	    ;;
	"write-interference")
	    fio --name=write_bandwidth_test --filename=/$MNT/fio --filesize=5G --loops=5 --ramp_time=5s --ioengine=libaio --direct=1 --verify=0 --randrepeat=0  --bs=1M --iodepth=1 --rw=write --numjobs=1 --write_bw_log=${UNIQ_OUTDIR}/fio-bw&
	    sleep 10s
	    fs_mark -t 5 -n 100000 -s 8192 -w 4096 -d $MNT > ${UNIQ_OUTDIR}/fsmark.out
	    # bin/filebench -f workloads/varmail_10.f > ${UNIQ_OUTDIR}/varmail.out
	    sleep 80s
	    ;;
	"read-interference")
	    fio --name=write_bandwidth_test --filename=/$MNT/fio --filesize=5G --time_based=1 --ramp_time=10s --runtime=120s --ioengine=libaio --direct=1 --verify=0 --randrepeat=0  --bs=1M --iodepth=1 --rw=read --numjobs=1 --write_bw_log=${UNIQ_OUTDIR}/fio-bw&
	    sleep 30s
	    bin/filebench -f workloads/varmail_10.f > ${UNIQ_OUTDIR}/varmail.out
	    sleep 80s
	    ;;
	"rw-interference")
	    fio --name=write_bandwidth_test --filename=/$MNT/fio --filesize=5G --time_based=1 --ramp_time=10s --runtime=120s --ioengine=libaio --direct=1 --verify=0 --randrepeat=0  --bs=1M --iodepth=1 --rw=rw --numjobs=1 --write_bw_log=${UNIQ_OUTDIR}/fio-bw&
	    sleep 30s
	    bin/filebench -f workloads/varmail_10.f > ${UNIQ_OUTDIR}/varmail.out
	    sleep 80s
	    ;;
	"dd")
	    dd if=/dev/zero of=${MNT}/test bs=4K count=2621440 oflag=dsync
	    ;;
	"noop")
	    iter=0
	    while [ $iter -lt $NUM_CLIENTS ]; do
		while [ ! -f ${MNT}/${STOP_FILE}.$iter ]; do
		    sleep 1
		done
		iter=$((iter+1))
	    done
	    ;;
	"fio-write")
	    fio --name=write_bandwidth_test  --filename=/mnt/fio --filesize=100M  \
		--time_based=1 --ramp_time=5s --runtime=50s  --ioengine=libaio \
		--direct=1 --verify=0 --randrepeat=0  --bs=1M --iodepth=4 --rw=write \
		--numjobs=1 > ${UNIQ_OUTDIR}/result.dat;
	    ;;
	"kernel-compile")
	    bash workloads/kernel-compile/run.sh $MNT
	    ;;
	"compilebench")
            cd ../compilebench-0.6
	    python2 ./compilebench -D $MNT > ${UNIQ_OUTDIR}/result.dat
            cd -
	    ;;
	"fsyncbm")
	    sleep 5
	    bin/fsync_bm $MNT 1024 4096 $NUM_THREADS > ${UNIQ_OUTDIR}/result.dat
	    sleep 5
	    fsfreeze -f $MNT
	    fsfreeze -u $MNT
	    sleep 5
	    ;;
	"create-empty")
	    touch $MNT/file
	    sync $MNT/file
	    ;;
	"create-empty-and-append")
	    echo "t" > $MNT/file
	    sync $MNT/file
	    ;;
    esac
    debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
    if [ "$NFS_CLIENT" == "1" ]; then
	touch ${MNT}/${STOP_FILE}.${NFS_CLIENT_ID}
	while [ ! -f ${MNT}/${NFS_SERVER_DONE} ]; do
	    sleep 1
	done
	cp -r ${UNIQ_OUTDIR} ${MNT}/results.tmp
	mv ${MNT}/results.tmp ${MNT}/results.$NFS_CLIENT_ID
	umount $MNT
    fi
    if [ "$NFS_SERVER" == "1" ]; then
	touch ${MNT}/${NFS_SERVER_DONE}
	iter=0
	while [ $iter -lt $NUM_CLIENTS ]; do
	    while [ ! -d ${MNT}/results.$iter ]; do
		sleep 1
	    done
	    cp -r ${MNT}/results.$iter ${UNIQ_OUTDIR}/client-results.$iter
	    iter=$((iter+1))
	done
    fi
    CURDIR=$(pwd)
    cd ${UNIQ_OUTDIR}
    cd ${CURDIR}
}

cleanup()
{
    if [ "$NFS_SERVER" == "1" ]; then
	service nfs-kernel-server stop
    fi
    umount -f $MNT
    if [ "$LOCAL_NFS_SERVER" == "1" ]; then
	service nfs-kernel-server stop
	umount -f $LOCAL_SERVER_MNT
    fi
}

run_bench()
{
    UNIQ_OUTDIR=${OUTDIR}/$UNIQUE_ID

    num_threads=$NUM_THREADS
    echo $'\n'
    echo "==== Start experiment of ${BENCHMARK} with $num_threads ===="


    echo "==== Format $dev on $MNT ===="
    pre_run_workload ${UNIQ_OUTDIR} ${num_threads}

    # Run
    echo "==== Run workload ===="
    
    if [ "$MEMORY_FOOTPRINT" == "1" ]; then
	echo "==== Measure Memory Footprint ===="
	dstat -m \
	      --output=./${UNIQ_OUTDIR}/mem.csv \
	    &> /dev/null &
	DSTAT_PID=$!
    fi
    
    if [ "$CPU_USAGE" == "1" ]; then
	echo "==== Measure CPU Usage Start ===="
	cp /proc/stat ${UNIQ_OUTDIR}/cpu_start.dat
    fi
    
    select_workload ${UNIQ_OUTDIR} ${num_threads}
    sleep 5

    echo "==== Workload complete ===="
    
    if [ "$MEMORY_FOOTPRINT" == "1" ]; then
	echo "==== Kill Memory Footprint Measurement Facility ===="
	kill $DSTAT_PID
    fi

    if [ "$CPU_USAGE" == "1" ]; then
	echo "==== Measure CPU Usage End ===="
	cp /proc/stat ${UNIQ_OUTDIR}/cpu_end_${num_threads}.dat
    fi

    echo "==== End the experiment ===="
    echo $'\n'

    echo "Find results in: ${OUTDIR}/$UNIQUE_ID"
    cleanup
}


for file in $(ls $CONFIGS_DIR); do
    cp ${CONFIGS_DIR}/$file ~/fast-commit-override.sh
    MNT=/mnt
    source ~/fast-commit-override.sh
    UNIQUE_ID=$(echo "$FS-$NFS_SERVER-$BENCHMARK-$(date +%s)")
    echo "[$file]: Results sent to ${OUTDIR}/$UNIQUE_ID/log"
    mkdir -p ${OUTDIR}/$UNIQUE_ID
    echo -n "[$file]: Running Test..."
    run_bench > ${OUTDIR}/$UNIQUE_ID/log 2>&1
    echo "\tFinished."
done
