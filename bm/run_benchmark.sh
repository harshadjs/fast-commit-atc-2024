#!/bin/bash


FILEBENCH_DIR=benchmark/filebench
FILEBENCH_PERTHREADDIR_DIR=benchmark/filebench-perthreaddir
FILEBENCH=filebench
FILEBENCH_PERTHREADDIR=${FILEBENCH_PERTHREADDIR_DIR}/filebench
SYSBENCH_DIR=benchmark/sysbench/src/
SYSBENCH=sysbench
DBENCH=benchmark/dbench/dbench
MDTEST=benchmark/ior/src/mdtest
MOBIBENCH_DIR=benchmark/mobibench/shell
MOBIBENCH=${MOBIBENCH_DIR}/mobibench
YCSB_DIR=benchmark/YCSB
YCSB=bin/ycsb
EXP_DIR=/home/harshads/cjfs/experiment
ROCKSDB_DIR=benchmark/rocksdb
DB_BENCH=${ROCKSDB_DIR}/db_bench
STOP_FILE=stop
START_FILE=start
OUTDIR=~/results

CONFIGS_DIR=$1

lockstat_on() {
	echo 1 > /proc/sys/kernel/lock_stat
}
lockstat_off() {
	echo 0 > /proc/sys/kernel/lock_stat
	cp /proc/lock_stat $1
	echo 0 > /proc/lock_stat
}

nfs_client_start() {
	echo "Waiting for NFS Server..."
	while [ ! -f ${MNT}/${START_FILE} ]; do
		umount $MNT
		sleep 1
		mount -t nfs ${NFS_CLIENT_OPS} ${dev}:/mnt $MNT
	done
	rm ${MNT}/${START_FILE}
	echo "Connected."
}

pre_run_workload() 
{
	UNIQ_OUTDIR=$1
	num_threads=$2

	# Format and Mount
	if [ "$NFS_SERVER" == "1" ]; then
		service nfs-kernel-server stop
		umount $MNT
	fi

	if [ "${NFS_CLIENT}" == "1" ]; then
		echo "This is a NFS Client, using $dev IP address"
		nfs_client_start
	elif [ "${XFS}" == "1" ]; then
		sudo bash mkxfs.sh $dev $MNT $JOURNAL_DEV
	elif [ ${FAST_COMMIT} == "1" ];then
		echo "Fast Commit is enabled!"
		sudo bash mkext4_fc.sh $dev $MNT $JOURNAL_DEV
	elif [ ${SPANFS} == "1" ]; then
		echo "SpanFS Mode!"
		sudo bash mkspanfs.sh $dev $MNT $domain
	elif [ ${NOBARRIER} == "1" ]; then
		echo "Asynchronous Commit with Checksum!"
		sudo bash mkext4_nobarrier.sh $dev $MNT
	else
		sudo bash mkext4.sh $dev $MNT $JOURNAL_DEV
	fi
	#sudo bash mkbtrfs.sh $dev $MNT

	echo "==== Format complete ===="
	if [ "$NFS_SERVER" == "1" ]; then
		echo "This is a NFS Sever, with $num_threads threads."
		service nfs-kernel-server restart
		exportfs -a
		ifconfig
		/usr/sbin/rpc.nfsd $num_threads
		touch $MNT/$START_FILE
		export BENCHMARK="noop"
	fi


	sync && sh -c 'echo 3 > /proc/sys/vm/drop_caches'
	dmesg -c > ${UNIQ_OUTDIR}/log.txt
	iostat > ${UNIQ_OUTDIR}/iostat_before.dat
	iostat -x -y 5 > ${UNIQ_OUTDIR}/iostat.dat&
	cp ~/fast-commit-override.sh ${UNIQ_OUTDIR}/config
	cp custom-workload.sh ${UNIQ_OUTDIR}
}


debug()
{

	UNIQ_OUTDIR=$1
	num_threads=$2
	dev=$3
	# Debug Page Conflict
	# sort by block number	# cat /proc/fs/jbd2/${dev:5}-8/pcl \
	#	> ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;
	iostat > ${UNIQ_OUTDIR}/iostat_after.dat;
	killall iostat
	if [ "$JOURNAL_DEV" == "" ]; then
		cat /proc/fs/jbd2/${dev:5}-8/info > ${UNIQ_OUTDIR}/info.dat;
	else
		cat /proc/fs/jbd2/${JOURNAL_DEV:5}/info > ${UNIQ_OUTDIR}/info.dat;
	fi
	if [ "${FAST_COMMIT}" == "1" ];then
		cat /proc/fs/ext4/${dev:5}/fc_info \
			> ${UNIQ_OUTDIR}/fc_info.dat;
	elif [ "${SPANFS}" == 1 ]; then
		mkdir -p ${UNIQ_OUTDIR}/${num_threads}d
		for ((i=1; i<=${domain}; i++)); do
			cat /proc/fs/jbd2/${dev:5}-${i}-8/info \
				> ${UNIQ_OUTDIR}/${num_threads}d/info_${num_threads}_${i}.dat;
		done
	fi

	#touch ${UNIQ_OUTDIR}/conflict_counts_${num_threads}.dat
	#while [ "`tail -n 1 ${UNIQ_OUTDIR}/conflict_counts_${num_threads}.dat`" != "NULL" ]
	#do
	#	cat /proc/fs/jbd2/${dev:5}-8/conflict_counts \
	#		>> ${UNIQ_OUTDIR}/conflict_counts_${num_threads}.dat
	#done


	# Lock statistic
	#lockstat_off ${OUTPUTDIR_DEV_PSP_ITER}/lock_stat_${num_threads}.dat;

	# disk anatomy
	#fsstat -i raw -f ext ${dev} \
	#	> ${UNIQ_OUTDIR}/disk_${num_threads};
	#python3 block_identity.py \
	#	--disk-info ${OUTPUTDIR_DEV_PSP_ITER}/disk_${num_threads} \
	#	--pcl-info ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat \
	#	--out-file ${OUTPUTDIR_DEV_PSP_ITER}/pcl_${num_threads}.dat;

	dmesg -c > ${UNIQ_OUTDIR}/log_${num_threads}.txt

	sudo bash ./avg.sh
	if [ "${DEBUG_TX_INTERVAL}" == 1 ]; then
		if [ "${SPANFS}" == 1 ];then
			sudo bash ./spanfs_op.sh ${UNIQ_OUTDIR} ${num_threads} ${dev} 
		else 
			sudo bash ./op.sh ${UNIQ_OUTDIR} ${num_threads} ${dev}
		fi
	fi
	if [ "${DEBUG_FSYNC_LATENCY}" == 1 ]; then
		sudo bash ./parse_fsync_latency.sh ${UNIQ_OUTDIR} ${num_threads} ${dev}
	fi

}

save_summary()
{
	INFO=$1
	DAT=$2
	num_threads=$3
	
	TX=`grep -E "transactions" ${INFO} | awk '{print $1}'`
	HPT=`grep -E "handles per transaction" ${INFO} | awk '{print $1}'`
	BPT=`grep -E "blocks per transaction" ${INFO} | awk '{print $1}'`
	case ${BENCHMARK} in
		"filebench-varmail"|"filebench-fileserver"|"filebench-varmail-perthreaddir")
		RET2=`grep -E " ops/s" $DAT | awk '{print $6}'`
		;;
		"sysbench-update")
		RET2=`grep -E "events/s" $DAT | awk '{print $3}'`
		;;
		"sysbench-insert")
		RET2=`grep -E " events/s" $DAT | awk '{print $3}'`
		;;
		"dbench-client")
		RET2=`cat $DAT | head -n 97 | tail -n 16 | awk '{sum+=$2} END {print sum/60}'`
		;;
		"mobibench")
		RET2=`grep -E "TIME" $DAT | awk '{print $10}'`
		;;
		"mdtest")
		RET2=`grep -E "File creation" $DAT | awk '{print $3}'`
		;;
		"db_bench")
		RET2=`grep -E "ops/sec" $DAT | awk '{print $5}'`
		;;
		"ycsb-load"|"ycsb-a"|"ycsb-b"|"ycsb-c"|"ycsb-d"|"ycsb-e"|"ycsb-f")
		RET2=`grep -E "Throughput" $DAT | awk '{print $3}'`
		;;
	esac
	echo ${num_threads} ${TX} ${HPT} ${BPT} ${RET2}

}

select_workload() 
{

	UNIQ_OUTDIR=$1
	num_threads=$2
	echo 0 > /proc/sys/kernel/randomize_va_space

	case $BENCHMARK in
		"filebench-varmail")
			${FILEBENCH} -f workloads/varmail_${num_threads}.f \
				> ${UNIQ_OUTDIR}/result.dat;
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"filebench-varmail-split16")
			${FILEBENCH} -f workloads/varmail_split16_${num_threads}.f \
				> ${UNIQ_OUTDIR}/result.dat;

			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}

			;;
		"filebench-varmail-perthreaddir")
			${FILEBENCH_PERTHREADDIR} -f \
				${FILEBENCH_PERTHREADDIR_DIR}/workloads/varmail_${num_threads}.f \
				> ${UNIQ_OUTDIR}/result.dat;

			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}

			;;
		"filebench-fileserver")
			;;
		"mobibench")
			./${MOBIBENCH} -p $MNT -f 10000000 -r 4 -y 2 -a 0 \
			> ${OUTPUTDIR_DEV_PSP_ITER}/result.dat
			;;
		"sysbench-insert")
			filesize=128G
			CURDIR=$(pwd)
			#lua=oltp_update_index.lua
			lua=oltp_insert.lua
			#cd $MNT

			systemctl stop mysqld
			systemctl stop mysqld
			chown -R mysql:mysql /mnt
			cp -rp /var/lib/mysql/ /mnt/mysql-data/
			chown -R mysql:mysql /mnt/mysql-data/
			chmod 777 /mnt/mysql-data/
			systemctl start mysqld
			
			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --threads=${num_threads} --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} cleanup
			
			#mysql_pid=$(ps -ef | grep mysqld | head -n 1 | awk '{print $2}')
			#echo "MySQL PID : ${mysql_pid}"
			#ps -ef | grep mysqld | head -n 1
			#sudo strace -fp ${mysql_pid} -e trace=creat,unlink,rename,write,read,fsync \
			#	-o ${UNIQ_OUTDIR}/trace.log &

			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} prepare

			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --warmup-time=60 --threads=${num_threads} --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} run > ${UNIQ_OUTDIR}/result_${num_threads}.dat

				
			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --threads=${num_threads} --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} cleanup

			cd $CURDIR
			systemctl stop mysqld

			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"sysbench-update")
			filesize=128G
			CURDIR=$(pwd)
			lua=oltp_update_index.lua
			#lua=oltp_insert.lua
			#cd $MNT

			systemctl stop mysqld
			systemctl stop mysqld
			mkdir -p /mnt/mysql-data
			cp -rp /var/lib/mysql/ /mnt/mysql-data/
			chown -R mysql:mysql /mnt/mysql-data/
			systemctl start mysqld

			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --threads=${num_threads} --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} cleanup

			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} prepare

			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --warmup-time=60 --threads=${num_threads} --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} run > ${UNIQ_OUTDIR}/result_${num_threads}.dat

				
			${SYSBENCH} --mysql-host=localhost --mysql-port=3306 --mysql-user=root \
			--mysql-password=oslab0810 --mysql-db=sysbench --threads=${num_threads} --table-size=444444 --tables=5 \
			${SYSBENCH_DIR}lua/${lua} cleanup

			cd $CURDIR
			systemctl stop mysqld

			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"dbench-client")
			num_process=${num_threads}
			DURATION=60
			WORKLOAD=benchmark/dbench/loadfiles/client.txt
			echo "./${DBENCH} ${num_process} -t ${DURATION} -c ${WORKLOAD} -D ${MNT} --sync-dir \
				> ${UNIQ_OUTDIR}/result_${num_process}.dat;"
			./${DBENCH} ${num_process} -t ${DURATION} -c ${WORKLOAD} -D ${MNT} --sync-dir \
				> ${UNIQ_OUTDIR}/result_${num_process}.dat;
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-load")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			echo "${UNIQ_OUTDIR}"
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloada -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-a")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloada -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/load_${num_threads}.dat;
			echo "===== Run Workload A ====="
			./${YCSB} run rocksdb -threads ${num_threads} -s -P ./workloads/workloada -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-b")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloadb -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/load_${num_threads}.dat;
			echo "===== Run Workload B ====="
			./${YCSB} run rocksdb -threads ${num_threads} -s -P ./workloads/workloadb -p rocksdb.dir=${MNT}  \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-c")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloadc -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/load_${num_threads}.dat;
			echo "===== Run Workload C ====="
			./${YCSB} run rocksdb -threads ${num_threads} -s -P ./workloads/workloadc -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-d")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloadd -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/load_${num_threads}.dat;
			echo "===== Run Workload D ====="
			./${YCSB} run rocksdb -threads ${num_threads} -s -P ./workloads/workloadd -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-e")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloade -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/load_${num_threads}.dat;
			echo "===== Run Workload E ====="
			./${YCSB} run rocksdb -threads ${num_threads} -s -P ./workloads/workloade -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"ycsb-f")
			CURDIR=$(pwd)
			cd ${YCSB_DIR}
			num_record=100000000
			echo "===== Load Workload ====="
			./${YCSB} load rocksdb -threads ${num_threads} -s -P ./workloads/workloadf -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/load_${num_threads}.dat;
			echo "===== Run Workload F ====="
			./${YCSB} run rocksdb -threads ${num_threads} -s -P ./workloads/workloadf -p rocksdb.dir=${MNT} \
			&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			cd ${CURDIR}
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"db_bench")
			DB_DIR=/mnt
			WAL_DIR=/mnt/wal
			NUM_KEYS=5000
			KEY_SIZE=16
			VALUE_SIZE=1024
			mkdir -p ${WAL_DIR}
			sudo touch ${EXP_DIR}/${UNIQ_OUTDIR}/benchmark_fillsync.wal_enabled.log
			sudo touch ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat
			sudo ./${DB_BENCH} \
				--benchmarks=fillsync \
        			--db=${DB_DIR} --wal_dir={WAL_DIR} \
        			--num=${NUM_KEYS} \
        			--key_size=${KEY_SIZE} \
        			--value_size=${VALUE_SIZE} \
        			--compression_type=zstd \
        			--write_buffer_size=4194304 \
        			--sync=1 \
        			--threads=${num_threads} \
        			--disable_wal=0 \
        			--report_file=${UNIQ_OUTDIR}/benchmark_fillsync.wal_enabled.log \
				&> ${EXP_DIR}/${UNIQ_OUTDIR}/result_${num_threads}.dat;
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"exim")
			;;
		"dd")
			dd if=/dev/zero of=${MNT}/test bs=4K count=2621440 oflag=dsync
			;;
		"mailbench-p")
			;;
		"mdtest")  
			num_process=${num_threads}
			num_make=300
			num_iteration=1
			num_depth=3
			num_branch=5
			write_bytes=4096

			/usr/lib64/openmpi3/bin/mpirun -np ${num_process} --allow-run-as-root ${MDTEST} -z ${num_depth} -b ${num_branch} \
				-I ${num_make} -i ${num_iteration} -y -w ${write_bytes} -d ${MNT} -F -C \
				> ${UNIQ_OUTDIR}/result_${num_process}.dat
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"noop")
			while [ ! -f ${MNT}/${STOP_FILE} ]; do
				sleep 1
			done
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev}
			;;
		"custom")
			bash custom-workload.sh $MNT
			debug ${UNIQ_OUTDIR} ${num_threads} ${dev} > ${UNIQ_OUTDIR}/result
			;;

	esac
	if [ "$NFS_CLIENT" == "1" ]; then
		touch ${MNT}/${STOP_FILE}
		cp -r ${UNIQ_OUTDIR} ${MNT}/results.tmp
		mv ${MNT}/results.tmp ${MNT}/results
		umount /mnt
	fi
	if [ "$NFS_SERVER" == "1" ]; then
		while [ ! -d ${MNT}/results ]; do
			sleep 1
		done
		cp -r ${MNT}/results ${UNIQ_OUTDIR}/client-results
	fi
	CURDIR=$(pwd)
	cp parse.sh ${UNIQ_OUTDIR}
	cd ${UNIQ_OUTDIR}
	./parse.sh $UNIQUE_ID >> ~/global-summary
	cd ${CURDIR}
}

run_bench()
{
	UNIQ_OUTDIR=${OUTDIR}/$UNIQUE_ID

	mkdir -p ${UNIQ_OUTDIR}
	echo `uname -r` >> ${UNIQ_OUTDIR}/summary
	echo "# thr tx h/tx blk/tx" >> ${UNIQ_OUTDIR}/summary;

	num_threads=$NUM_THREADS
	echo $'\n'
	echo "==== Start experiment of ${BENCHMARK} with $num_threads ===="


	echo "==== Format $dev on $MNT ===="
	pre_run_workload ${UNIQ_OUTDIR} ${num_threads}

	# Run
	#blktrace -d $dev -o ./blk_result &
	#blktrace_PID=$!
	echo "==== Run workload ===="
	
	if [ "$MEMORY_FOOTPRINT" == "1" ]; then
		echo "==== Measure Memory Footprint ===="
		dstat -m \
		--output=./${UNIQ_OUTDIR}/mem.csv \
			&> /dev/null &
		DSTAT_PID=$!
	fi
	
	if [ "$CPU_USAGE" == "1" ]; then
		echo "==== Measure CPU Usage Start ===="
		cp /proc/stat ${UNIQ_OUTDIR}/cpu_start.dat
	fi
	
	select_workload ${UNIQ_OUTDIR} ${num_threads}
	sleep 5
	#kill $blktrace_PID
	#blkparse -i blk_result -o ${UNIQ_OUTDIR}/blk_result_${num_threads}.p
	#rm -rf blk_result.blktrace*
	echo "==== Workload complete ===="
	
	if [ "$MEMORY_FOOTPRINT" == "1" ]; then
		echo "==== Kill Memory Footprint Measurement Facility ===="
		kill $DSTAT_PID
	fi

	if [ "$CPU_USAGE" == "1" ]; then
		echo "==== Measure CPU Usage End ===="
		cp /proc/stat ${UNIQ_OUTDIR}/cpu_end_${num_threads}.dat
	fi

	save_summary ${UNIQ_OUTDIR}/info.dat ${UNIQ_OUTDIR}/result.dat \
		${num_threads}>>${UNIQ_OUTDIR}/summary;
	cat ${UNIQ_OUTDIR}/summary | tail -1 \
		>> ${OUTDIR}/summary_total
	echo "==== End the experiment ===="
	echo $'\n'

	echo "# thr tx h/tx blk/tx" >> ${OUTDIR}/summary_avg
	awk '
	{
	c[$1]++; 
	for (i=2;i<=NF;i++) {
		s[$1"."i]+=$i};
	} 
	END {
		for (k in c) {
			printf "%s ", k; 
			for(i=2;i<NF;i++) printf "%.1f ", s[k"."i]/c[k]; 
			printf "%.1f\n", s[k"."NF]/c[k];
		}
	}' ${OUTDIR}/summary_total >> ${OUTDIR}/summary_avg
	echo "Find results in: ${OUTDIR}/$UNIQUE_ID"
}

for file in $(ls $CONFIGS_DIR); do
	cp ${CONFIGS_DIR}/$file ~/fast-commit-override.sh
	source parameter.sh
	UNIQUE_ID=$(date +%s)
	echo "RUNNING TEST $file"
	run_bench
	echo "TEST $file FINISHED"
done