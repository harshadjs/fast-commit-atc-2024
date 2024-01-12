#!/bin/bash

ID=$RANDOM
rm -rf ~/results

ifconfig
#./run_benchmark.sh configs/pd-perf/server/
#mv ~/results/ ~/pd-perf-$ID

./run_benchmark.sh configs/localssd-perf/server/
mv ~/results/ ~/localssd-perf-$ID

echo "All results are in ~/full-$ID"
echo "Results are in ~/localssd-perf-$ID"
