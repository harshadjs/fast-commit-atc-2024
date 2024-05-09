#!/bin/bash

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
