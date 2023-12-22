#!/bin/bash

DIR=$1
RUN_ID=$1

if [ "$NFS_CLIENT" == "1" ]; then
    exit
fi 

function get_mb_written() {
	# echo dev=$dev
	if [ "$1" == "" ]; then
		echo -n "0"
		return
	fi
	devname=${1:5}
	dev_kb_after=$(cat iostat_after.dat | grep $devname | xargs | cut -d " " -f7)
	dev_kb_before=$(cat iostat_before.dat | grep $devname | xargs | cut -d " " -f7)
	echo -n $(((dev_kb_after-dev_kb_before)/1024))
}

function get_wiops_sum() {
	if [ "$1" == "" ]; then
		echo -n "0"
		return
	fi
	devname=${1:5}
	sum=0
	cat iostat.dat | grep ${devname} | sed -r 's/[[:blank:]]+/,/g' | cut -d "," -f8 > /tmp/wiops
	while read wiops; do
    		sum=$(python3 -c "print($sum+$wiops)")
	done < /tmp/wiops
	echo $sum
}

function parse_run() {
	RUN_ID=$1
	echo -n "$1,"
	source ./config

	if [ "$JOURNAL_DEV" == "" ]; then
		jrnl="combined"
	else
		jrnl="split"
	fi
	
	echo -n "$(get_mb_written ${dev}),$(get_mb_written ${JOURNAL_DEV}),$(get_wiops_sum $dev),$(get_wiops_sum $JOURNAL_DEV),"
	if [ "$NFS_SERVER" == "1" ]; then
		cd client-results
		echo -n "NFS=1"
		source ./config
	else
		echo -n "NFS=0"
	fi
		echo -n ",$FS,JOURNAL=$jrnl,$NUM_THREADS,$BENCHMARK,"
	if [[ "$BENCHMARK" == filebench* ]]; then
		runtime=$(cat result.dat | grep "Run took" | xargs | cut -d " " -f4)
		throughput=$(cat result.dat  | grep "IO Summary" | cut -d " " -f6)
	elif [ "$BENCHMARK" == "postmark" ]; then
		echo ""
	else
		runtime=60
		throughput=unknown
	fi
	echo "$throughput,$runtime"
}

cd $1
top_dir=$(pwd)
for dir in $(find . -maxdepth 1 -type d -name "1*"); do
	cd $dir
	run=$(echo $dir | cut -d "/" -f2)
	parse_run $run
	cd $top_dir
done
