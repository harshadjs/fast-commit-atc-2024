#!/bin/bash
ID=$RANDOM
rm -rf ~/results

echo "Running NFS+LocalSSD"
./run_benchmark.sh configs/nfs+localssd/client $1

echo "Running NFS+LocalSSD"
./run_benchmark.sh configs/nfs+pd/client $1

