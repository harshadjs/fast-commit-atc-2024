#!/bin/bash

# dev=/dev/nvme0n1
# domain=40
# JOURNAL_DEV=/dev/nvme0n3
# FAST_COMMIT=1
# NFS_SERVER=1
# NFS_CLIENT=0
# BENCHMARK=filebench-varmail
# NFS_CLIENT_OPS=-o async

CLIENT_DIR="client-configs"
SERVER_DIR="server-configs"
DATA_DEV="/dev/nvme0n1"
JOURNAL_DEV=("none" "/dev/nvme0n3")
NUM_THREADS=(10 20 40 80)
SERVER_IP="10.132.0.21"

FILESYSTEMS=("XFS" "FC" "EXT4")
WORKLOADS=("filebench-varmail" "filebench-varmail-split16")

for workload in ${WORKLOADS[@]}; do
	echo $workload
done

# printf "%02d" 5
# echo ""

rm -rf $CLIENT_DIR/*
rm -rf $SERVER_DIR/*

ID=100
NFS_ID=0
for journal in ${JOURNAL_DEV[@]}; do
	for fs in ${FILESYSTEMS[@]}; do
		for workload in ${WORKLOADS[@]}; do
			# Generate Local Workload First
			LOCAL_FILENAME=$(printf "%03d" $ID)
			NFS_FILENAME=$(printf "%03d" $NFS_ID)
			echo $LOCAL_FILENAME:$NFS_FILENAME
			echo "dev=$DATA_DEV" > $SERVER_DIR/$LOCAL_FILENAME
			if [ "$fs" == "XFS" ]; then
				echo "XFS=1" >> $SERVER_DIR/$LOCAL_FILENAME
			elif [ "$fs" == "FC" ]; then
				echo "FAST_COMMIT=1" >> $SERVER_DIR/$LOCAL_FILENAME
			elif [ "$fs" == "EXT4" ]; then
				echo "FAST_COMMIT=0" >> $SERVER_DIR/$LOCAL_FILENAME
			else
				echo "Unsupported filesystem $fs"
			fi
			if [ "$journal" == "none" ]; then
				echo "JOURNAL_DEV=" >> $SERVER_DIR/$LOCAL_FILENAME
			else
				echo "JOURNAL_DEV=$journal" >> $SERVER_DIR/$LOCAL_FILENAME
			fi
			cp $SERVER_DIR/$LOCAL_FILENAME $SERVER_DIR/$NFS_FILENAME
			echo "NFS_SERVER=1" >> $SERVER_DIR/$NFS_FILENAME
			echo "BENCHMARK=$workload" >> $SERVER_DIR/$LOCAL_FILENAME
			echo "NUM_THREADS=(10 20 40 80)" >> $SERVER_DIR/$LOCAL_FILENAME
			echo "NUM_THREADS=(64)" >> $SERVER_DIR/$NFS_FILENAME

			echo "dev=$SERVER_IP" > $CLIENT_DIR/$NFS_FILENAME
			echo "NFS_CLIENT=1" >> $CLIENT_DIR/$NFS_FILENAME
			echo "BENCHMARK=$workload" >> $CLIENT_DIR/$NFS_FILENAME
			echo "NUM_THREADS=(10 20 40 80)" >> $CLIENT_DIR/$NFS_FILENAME
			ID=$((ID+1))
			NFS_ID=$((NFS_ID+1))
		done
	done
done