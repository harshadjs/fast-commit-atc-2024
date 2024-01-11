#!/bin/bash
SERVER=$1
NFS_SERVER_IP=$2

ID=$RANDOM
if [ "$SERVER" == "1" ]; then
  ifconfig
  ./run_benchmark.sh configs/pd-perf/server/
  mv ~/results/ ~/pd-perf-$ID
else
  ./run_benchmark.sh configs/pd-perf/client/ $NFS_SERVER_IP
fi

echo "All results are in ~/pd-perf-$ID"