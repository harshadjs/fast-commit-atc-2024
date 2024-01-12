#!/bin/bash

ID=$RANDOM

rm -rf ~/results

./run_benchmark.sh configs/localssd/server/
mv ~/results/ ~/localssd-$ID

echo "Results are in ~/localssd-$ID"

./run_benchmark configs/nfs+localssd/server
mv ~/results ~/nfs+localssd-$ID

echo "Results are in ~/localssd-$ID and ~/nfs+localssd-$ID"
