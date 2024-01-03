#!/bin/bash
SERVER=$1

if [ "$SERVER" == "1" ]; then
  ./run_benchmark.sh configs/pd-perf/server/
  mv ~/results/ ~/pd-perf
  ./run_benchmark.sh configs/localssd-perf/server/
  mv ~/results/ ~/localssd-perf
  ./run_benchmark.sh configs/scaling/server/
  mv ~/results/ ~/scaling
else
  ./run_benchmark.sh configs/pd-perf/client/
fi