#!/bin/bash
ID=$RANDOM
rm -rf ~/results

./run_benchmark.sh configs/nfs+localssd+remote/client $1
mv ~/results ~/nfs+localssd+remote-$ID
echo "Results are in ~/nfs+localssd+remote-$ID"
