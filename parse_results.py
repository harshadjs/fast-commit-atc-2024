#!/bin/python3
import os
import sys
import numpy as np

debug = False

def log(str):
	if debug:
		print(str)

def get_main_dev(partition):
	if partition == "/dev/sdb1":
		return "/dev/sdb"
	if partition == "/dev/nvme0n1p1":
		return "/dev/nvme0n1"
	return ""

def parse_results(dir):


def parse(dir, config_dict):
	# print(config_dict)
	iostat = dir + "/iostat.dat"
	iops_array = []
	j_iops_array = []
	bw_array = []
	j_bw_array = []
	f_array = []
	f_await_array = []
	with open(iostat) as iostat_f:
		lines = iostat_f.readlines()
		dev = get_main_dev(config_dict["dev"])
		# print(dev)
		num_seconds = 0 
		for line in lines:
			num_seconds = num_seconds + 1
			if not line.startswith(dev[5:]):
				continue
			iostat_stats =line.split()
			iops_array.append(float(iostat_stats[7]))
			bw_array.append(float(iostat_stats[8]))
			f_array.append(float(iostat_stats[19]))
			f_await_array.append(float(iostat_stats[20]))
			# print(iostat_stats)
		j_dev = config_dict["JOURNAL_DEV"]
		if j_dev != "":
			for line in lines:
				if not line.startswith(j_dev[5:]):
					continue
				iostat_stats =line.split()
				j_iops_array.append(float(iostat_stats[7]))
				j_bw_array.append(float(iostat_stats[8]))
	
	(app_tput, time, )
	print("%s,%s,%s,%s,%f,%f,%f,%f,%f,%f,%f,%f," %
		(config_dict["ID"].split("/")[-1], config_dict["FS"], config_dict["BENCHMARK"], config_dict["NUM_THREADS"],
		sum(iops_array), sum(j_iops_array), sum(bw_array),  sum(j_bw_array),
		sum(f_array), sum(f_await_array), np.percentile(iops_array, 95), np.percentile(bw_array, 95)))

def should_filter_out(config_dict, filter):
	if config_dict["BENCHMARK"] == "compilebench":
		return True
	if config_dict["BENCHMARK"] == "kernel-compile":
		return True
	if filter == "all":
		return False
	if filter == config_dict["FS"]:
		return False
	return True

def parse_dir(dir, filter):
	config_dict = {}
	config_file = dir + "/config"
	config_dict["ID"] = dir
	if not os.path.exists(config_file):
		if debug:
			print("Skipping non-results dir " + dir)
		return
	with open(config_file) as config:
		lines = config.readlines()
		for line in lines:
			config_var = line.strip().split("=")
			if len(config_var) == 0:
				continue
			val = None
			if len(config_var) == 2:
				val = config_var[1]
			config_dict[config_var[0]] = val
	if config_dict["NFS_SERVER"] == "1":
		# Parse client config
		client_config_file = dir + "/client-results.0/config"

		if not os.path.exists(config_file):
			if debug:
				print("Invalid client config " + dir)
			return
		with open(client_config_file) as config:
			lines = config.readlines()
			for line in lines:
				config_var = line.strip().split("=")
				if len(config_var) == 0:
					continue
				val = None
				if len(config_var) == 2:
					val = config_var[1]
				if config_var[0] == "BENCHMARK":
					config_dict[config_var[0]] = val
				if config_var[0] == "NUM_THREADS":
					config_dict[config_var[0]] = val
	if should_filter_out(config_dict, filter):
		return
	parse(dir + "/iostat.dat", config_dict)


print(sys.argv[1])
filter = "all"
if len(sys.argv) == 3:
	filter = sys.argv[2]
print("ID,FS,Benchmark,Threads,IOs,Journal IOs,KB,Journal KB,Flushes,Flush_wait,IOPS,BW")
for path in os.listdir(sys.argv[1]):
	full_path = os.getcwd() + "/" + sys.argv[1] + "/" + path
	if not os.path.isdir(full_path):
		continue
	parse_dir(full_path, filter)

