#!/bin/bash

ID=$RANDOM
rm -rf ~/results

ifconfig

./run_benchmark.sh configs/nfs+localssd+remote/server/
mv ~/results/ ~/nfs+localssd+remote-$ID

echo "Results are in ~/nfs+localssd+remote-$ID"
