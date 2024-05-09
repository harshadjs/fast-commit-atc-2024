#!/bin/bash

function client() {
    ID=$RANDOM
    rm -rf ~/results

    echo "Running NFS+LocalSSD"
    ./run_benchmark.sh configs/nfs+localssd/client $1

    echo "Running NFS+LocalSSD"
    ./run_benchmark.sh configs/nfs+pd/client $1
}

function queue-depth() {
    QUEUE_DEPTHS=(4 8 16)

    for q in ${QUEUE_DEPTHS[@]}; do
	echo $q > /sys/block/sdb/queue/nr_requests 
	./run_benchmark.sh configs/pd-queue-depth/server
	mv ~/results ~/results-qd-$q
    done
}

function local() {
    ID=$RANDOM

    rm -rf ~/results

    ./run_benchmark.sh configs/localssd/server/
    mv ~/results/ ~/localssd-$ID

    echo "Results are in ~/localssd-$ID"

    ./run_benchmark configs/nfs+localssd/server
    mv ~/results ~/nfs+localssd-$ID

    echo "Results are in ~/localssd-$ID and ~/nfs+localssd-$ID"

}

function server() {
    ID=$RANDOM
    rm -rf ~/results
    mkdir ~/full-$ID

    ifconfig

    echo "Running NFS+LocalSSD" 
    ./run_benchmark.sh configs/nfs+localssd/server/
    mv ~/results/ ~/full-$ID/nfs+localssd

    echo "Running NFS+PD" 
    ./run_benchmark.sh configs/nfs+pd/server/
    mv ~/results/ ~/full-$ID/nfs+pd

    echo "Running LocalSSD" 
    ./run_benchmark.sh configs/localssd/server/
    mv ~/results/ ~/full-$ID/localssd

    echo "Running fsync_bm" 
    ./run_benchmark.sh configs/fsync_bm/server/
    mv ~/results/ ~/full-$ID/fsync_bm

    echo "Results are in ~/full-$ID"
}

if [ "$1" == "server" ]; then
    server
elif [ "$1" == "client" ]; then
    client $2
elif [ "$1" == "queue-depth" ]; then
    queue-depth
elif [ "$1" == "local" ]; then
    local
else
    echo "Usage: ./testsuite.sh [TESTSUITE] [ARGS]"
    echo "  TESTSUITE can be one of server, client, local, queue-depth"
fi

