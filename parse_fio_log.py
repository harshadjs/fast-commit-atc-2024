import sys

with open(sys.argv[1]) as f:
	current_second = 0
	current_samples = 0
	current_read_bw = 0
	current_write_bw = 0
	for line in f.readlines():
		parts = line.split(",")
		this_second = int(int(parts[0])/1000)
		if this_second != current_second:
			if current_samples == 0:
				print("%d,0,0" % (current_second))
			else:
				print("%d,%d,%d" % (current_second, current_read_bw / current_samples, current_write_bw / current_samples))
			current_second = this_second
			current_samples = 0
			current_read_bw = 0
			current_write_bw = 0

		bw = int(parts[1])
		if int(parts[2]) == 1:
			current_read_bw = current_read_bw + bw
		else:
			current_write_bw = current_write_bw + bw
		current_samples = current_samples + 1
	if current_samples == 0:
		print("%d,0,0" % (current_second))
	else:
		print("%d,%d,%d" % (current_second, current_read_bw / current_samples, current_write_bw / current_samples))

