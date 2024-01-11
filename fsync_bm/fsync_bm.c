#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

int main(int argc, char *argv[])
{
	int fd, file_size = 0, final_size, write_size, fsync_frequency, i = 0;
	int num_fsyncs = 0;
	char *file_name;
	char *buf;
	clock_t begin, end;

	if (argc < 5) {
		printf("Usage: %s <file_path> <file_size_mb> <write_size> <fsync_frequency>\n",
			argv[0]);
		return 0;
	}

	file_name = argv[1];
	final_size = strtol(argv[2], NULL, 10) * 1024 * 1024;
	write_size = strtol(argv[3], NULL, 10);
	fsync_frequency = strtol(argv[4], NULL, 10);

	buf = malloc(write_size);
	if (!buf) {
		printf("Error while malloc\n");
		return -1;
	}

	printf("filename = %s\n", file_name);
	fd = open(file_name, O_APPEND |O_RDWR| O_CREAT | O_TRUNC);
	if (fd < 0) {
		printf("Error during creat\n");
		return -1;
	}

	begin = clock();	
	while (file_size < final_size) {
		file_size += write_size;
		if (write(fd, buf, write_size) < 0) {
			printf("Error while write: %s\n", strerror(errno));
			return -1;
		}
		if (i % fsync_frequency == 0) {
			num_fsyncs++;
			if (fsync(fd) < 0) {
				printf("Error while fsync\n");
				return -1;
			}
		}
		i++;
	}
	close(fd);
	end = clock();
	printf("%d fsyncs issued, total time %lf seconds\n",
		num_fsyncs, (double)(end - begin) / CLOCKS_PER_SEC);

	return 0;
}