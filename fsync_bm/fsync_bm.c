#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

int main(int argc, char *argv[])
{
	int fd, file_size, num_files, fsync_frequency, i = 0;
	int num_fsyncs = 0;
	char file_name[100];
	char *buf, *dir;
	clock_t begin, end;

	if (argc < 5) {
		printf("Usage: %s <dir> <num_files> <file_size> <fsync_frequency>\n",
			argv[0]);
		return 0;
	}

	dir = argv[1];
	num_files = strtol(argv[2], NULL, 10);
	file_size = strtol(argv[3], NULL, 10);
	fsync_frequency = strtol(argv[4], NULL, 10);

	buf = malloc(file_size);
	if (!buf) {
		printf("Error while malloc\n");
		return -1;
	}

	printf("Creating %d files of size %d each, fsync after %d files\n",
		num_files, file_size, fsync_frequency);

	begin = clock();
	for (i = 0; i < num_files; i++) {
		snprintf(file_name, 100, "%s/f_%d", dir, i);
		fd = open(file_name, O_APPEND |O_RDWR| O_CREAT | O_TRUNC);
		if (fd < 0) {
			printf("Error during open\n");
			return -1;
		}
		if (i % fsync_frequency == 0) {
			num_fsyncs++;
			if (fsync(fd) < 0) {
				printf("Error while fsync\n");
				return -1;
			}
		}
		if (write(fd, buf, file_size) < 0) {
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
		close(fd);
	}
	end = clock();
	printf("%d fsyncs issued, total time %lf seconds\n",
		num_fsyncs, (double)(end - begin) / CLOCKS_PER_SEC);

	return 0;
}