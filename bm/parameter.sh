#!/bin/bash

# Device
# - /dev/sdb: SAMSUNG 860PRO 512GB
# - /dev/nvme0n1: SAMSUNG 970PRO 512GB
VERSION="$(uname -r| awk -F '-' '{print $1}')"
EXTRA_VERSION="$(uname -r| awk -F '-' '{print $2}')"
DEBUG="$(uname -r | awk -F '-' '{print $3}')"
NOBARRIER=0
SPANFS=0
MEMORY_FOOTPRINT=0
CPU_USAGE=0
DEBUG_TX_INTERVAL=0
DEBUG_FSYNC_LATENCY=0


#BENCHMARK="mobibench"
BENCHMARKS=(filebench-varmail)
#BENCHMARKS=(filebench-varmail-perthreaddir dbench-client)
#BENCHMARKS=(sysbench-insert)
#BENCHMARKS=(filebench-varmail-perthreaddir)
#BENCHMARKS=(sysbench-update sysbench-insert) 
#BENCHMARKS=(sysbench-insert) 



#FTRACE_PATH=/sys/kernel/debug/tracing

#NUM_THREADS=(10 20 30 40)
NUM_THREADS=(40)
#NUM_THREADS=(1)
#NUM_THREADS=(1 2 5 10 20 30 40)
ITER=1
MNT=/mnt

## Configurables
BENCHMARK=filebench-varmail
dev=/dev/nvme0n1
domain=40
JOURNAL_DEV=/dev/nvme0n3
FAST_COMMIT=1
NFS_SERVER=0
NFS_CLIENT=0

VERSION_PATH="raw_data"
if [ "$EXTRA_VERSION" == "CJFS" ] || [ "$EXTRA_VERSION" == "CJFS+" ]; then
	#VERSION_PATH=${VERSION_PATH}"/CJFS-nobarrier"
	VERSION_PATH=${VERSION_PATH}"/CJFS"
elif [ "$EXTRA_VERSION" == "barrier" ] || [ "$EXTRA_VERSION" == "barrier+" ]; then
	VERSION_PATH=${VERSION_PATH}"/bfs"
elif [ "$EXTRA_VERSION" == "SpanFS" ] || [ "$EXTRA_VERSION" == "SpanFS+" ]; then
	VERSION_PATH=${VERSION_PATH}"/spanfs"
else
	if [ "${FAST_COMMIT}" == 1 ]; then
		VERSION_PATH=${VERSION_PATH}"/ext4-fc"
	else
		VERSION_PATH=${VERSION_PATH}"/ext"
	fi
	DEBUG="$EXTRA_VERSION"
fi

echo "$VERSION_PATH"

source ~/fast-commit-override.sh
