#!/bin/bash

./run_benchmark.sh configs/localssd-perf/server/
mv ~/results/ ~/localssd-perf
./run_benchmark.sh configs/scaling/server/
mv ~/results/ ~/scaling
