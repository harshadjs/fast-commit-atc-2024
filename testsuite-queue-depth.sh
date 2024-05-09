#!/bin/bash

QUEUE_DEPTHS=(4 8 16)

for q in ${QUEUE_DEPTHS[@]}; do
  echo $q > /sys/block/sdb/queue/nr_requests 
  ./run_benchmark.sh configs/pd-queue-depth/server
  mv ~/results ~/results-qd-$q
done