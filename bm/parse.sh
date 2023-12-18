#!/bin/bash

THREADS=$1

source ./config

if [ "$NFS_CLIENT" == "1" ]; then
    exit
fi

function get_mb_written() {
    devname=${1:5}
    dev_kb_after=$(cat iostat_after_$THREADS.dat | grep $devname | xargs | cut -d " " -f7)
    dev_kb_before=$(cat iostat_before_$THREADS.dat | grep $devname | xargs | cut -d " " -f7)
    echo -n $(((dev_kb_after-dev_kb_before)/1024))
}
    
get_mb_written ${dev}
echo -n ","
if [ "$JOURNAL_DEV" != "" ]; then
    get_mb_written ${JOURNAL_DEV}
fi

if [ "$NFS_SERVER" == "1" ]; then
    cd client-results
    echo -n ",NFS"
    source ./config
else
    echo -n ",Local"
fi
echo -n ",$THREADS,$BENCHMARK"
if [[ "$BENCHMARK" == filebench* ]]; then
    runtime=$(cat result_$THREADS.dat | grep "Run took" | xargs | cut -d " " -f4)
else
    runtime=60
fi
echo -n ",$runtime"
sum=0
cat iostat_$THREADS.dat | grep ${dev:5} | sed -r 's/[[:blank:]]+/,/g' | cut -d "," -f8 > /tmp/wiops
while read wiops; do
    sum=$(python3 -c "print($sum+$wiops)")
done < /tmp/wiops

echo -n ",$sum,$runtime"
echo ""