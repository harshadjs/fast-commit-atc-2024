#!/bin/bash

dir=$1

function do_sum() {
	# cat iostat.dat |grep sdb | grep -v sdb1 | grep -v sdb2 > /tmp/out
	cat iostat.dat |grep sdb1  > /tmp/out
	sum=0
	while read line; do
		val=$(echo $line | xargs | cut -d " " -f$1 | cut -d "." -f1)
		sum=$((sum+val))
	done < /tmp/out
	echo "$2=$sum"
}

function get_max() {
	cat iostat.dat |grep sdb1  > /tmp/out
	sum=0
	echo "$2: "
	cat iostat.dat |grep sdb | grep -v sdb1 | grep -v sdb2 > /tmp/out; while read line; do val=$(echo $line | xargs | cut -d " " -f$1); echo $val; done < /tmp/out | sort -n | tail -2
}

for d in $(ls $dir); do
	clear
	echo $d

	cd $d
	cat config client-results.0/config | grep -v NFS | grep -v NUM

	echo "IOPS: "
	# cat iostat.dat |grep sdb | grep -v sdb1 | grep -v sdb2 > /tmp/out; while read line; do val=$(echo $line | xargs | cut -d " " -f8); echo $val; done < /tmp/out | sort -n | tail -2
	get_max 8 write
	get_max 2 read
	echo "BW: "
#	cat iostat.dat |grep sdb | grep -v sdb1 | grep -v sdb2 > /tmp/out; while read line; do val=$(echo $line | xargs | cut -d " " -f9); echo $val; done < /tmp/out | sort -n | tail -2
	get_max 9 write
	get_max 3 read

	read
	cat client-results.0/result.dat
	read
	cat info.dat
	cat fc_info.dat
	read
	cd ../
done
