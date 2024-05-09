#!/bin/bash

# dev=/dev/nvme0n1
# domain=40
# JOURNAL_DEV=/dev/nvme0n3
# FAST_COMMIT=1
# NFS_SERVER=1
# NFS_CLIENT=0
# BENCHMARK=filebench-varmail
# NFS_CLIENT_OPS=-o async

PREFIX="configs/pd-perf"
CLIENT_DIR="${PREFIX}/client"
SERVER_DIR="${PREFIX}/server"
DATA_DEV="/dev/sdb1"
JOURNAL_DEV=("/dev/sdb2")
SERVER_IP="10.132.15.204"
NUM_WORKLOAD_THREADS=(40 0)

FILESYSTEMS=("F2FS" "XFS" "EXT4FC" "EXT4")
# WORKLOADS=("kernel-compile" "filebench-varmail" "filebench-varmail-split16" "filebench-webserver" "filebench-fileserver" "postmark")
WORKLOADS=("filebench-varmail" "postmark" "compilebench")

for workload in ${WORKLOADS[@]}; do
	echo $workload
done

# printf "%02d" 5
# echo ""
mkdir -p $CLIENT_DIR
mkdir -p $SERVER_DIR
rm -rf $CLIENT_DIR/*
rm -rf $SERVER_DIR/*

ID=500
NFS_ID=0

for workload in ${WORKLOADS[@]}; do
	for num_threads in ${NUM_WORKLOAD_THREADS[@]}; do
		if [ "$workload" == "postmark" -o "$workload" == "kernel-compile" ]; then
			if [ "$num_threads" != "0" ]; then
				continue
			fi
		else
			if [ "$num_threads" == "0" ]; then
				continue
			fi
		fi

		for journal in ${JOURNAL_DEV[@]}; do
			for fs in ${FILESYSTEMS[@]}; do
				# Generate common first
				LOCAL_FILENAME=$(printf "%03d" $ID)
				NFS_FILENAME=$(printf "%03d" $NFS_ID)
				echo "dev=$DATA_DEV" > $SERVER_DIR/$LOCAL_FILENAME
				echo "FS=$fs" >> $SERVER_DIR/$LOCAL_FILENAME
				if [ "$journal" == "none" ]; then
					echo "JOURNAL_DEV=" >> $SERVER_DIR/$LOCAL_FILENAME
				else
					echo "JOURNAL_DEV=$journal" >> $SERVER_DIR/$LOCAL_FILENAME
				fi
				cp $SERVER_DIR/$LOCAL_FILENAME $SERVER_DIR/$NFS_FILENAME
				# Local only
				echo "NFS_SERVER=0" >> $SERVER_DIR/$LOCAL_FILENAME
				echo "BENCHMARK=$workload" >> $SERVER_DIR/$LOCAL_FILENAME
				echo "NUM_THREADS=$num_threads" >> $SERVER_DIR/$LOCAL_FILENAME

				# NFS Server
				echo "NFS_SERVER=1" >> $SERVER_DIR/$NFS_FILENAME
				echo "NUM_CLIENTS=1" >> $SERVER_DIR/$NFS_FILENAME
				echo "NUM_THREADS=64" >> $SERVER_DIR/$NFS_FILENAME

				# NFS Client
				echo "dev=$SERVER_IP" > $CLIENT_DIR/$NFS_FILENAME
				echo "NFS_CLIENT=1" >> $CLIENT_DIR/$NFS_FILENAME
				echo "NFS_CLIENT_ID=0" >> $CLIENT_DIR/$NFS_FILENAME
				echo "BENCHMARK=$workload" >> $CLIENT_DIR/$NFS_FILENAME
				echo "NUM_THREADS=$num_threads" >> $CLIENT_DIR/$NFS_FILENAME
				ID=$((ID+1))
				NFS_ID=$((NFS_ID+1))
			done
		done
	done
done