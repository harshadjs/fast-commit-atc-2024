#!/bin/bash

ID=$RANDOM

./run_benchmark.sh configs/localssd-perf/server/
mv ~/results/ ~/localssd-perf-$ID

echo "Results are in ~/localssd-perf-$ID"

