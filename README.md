# Fast Commit ATC 2024 Benchmarking

This repository contains benchmarking scripts that were used to evaluate fast commit
performance for ATC 2024 paper. I have merged majority of the fast commit kernel code into
the upstream Linux kernel. Kernel versions >= 5.10 support Fast Commits natively. Some
kernel patches are being [actively reviewed](link) upstream, and I expect them to be merged
soon as well. These unmerged patches can be found
[here](https://github.com/harshadjs/fc-perf-v2).

NOTE:  ATC 2024 Artifact Evaluation can be found [here](https://github.com/harshadjs/fast-commit-atc-2024/blob/main/docs/artifact_eval.md).

## Benchmarking Setup

While we used Google Cloud Compute Engine (GCE) for all our benchmarking, these scripts can
be used for benchmarking Fast Commits on any machine with Linux kernel >= 5.10.

1. Please follow steps in [GCE
   docs](https://cloud.google.com/compute/docs/instances/create-start-instance) to setup GCE
   account and create a GCE VM. Similar instructions for AWS [AWS
   instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html) or
   [Azure
   instance](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu). Alternatively,
   you can use any Debian / Ubuntu based machine.
   
2. Log into the machine.

3. Install git

```sh
sudo apt-get install git
```

4. Clone this repository

```sh
git clone https://github.com/harshadjs/fast-commit-atc-2024.git
```

5. Perform one time setup

This step installs all the necessary software.

```sh
cd fast-commit-atc-2024
./setup.sh
```

## Running Benchmarks

The benchmark is designed to run many tests at once. It also supports running tests across
NFS client / server. The test

### Defining one test

A single test is defined by designing a configuration file consisting of following
configuration variables:
- `dev`: Device under test (e.g. /dev/sdb)
- `FS`:	File system to use for testing. Possible options: `EXT4`, `EXT4FC`, `EXT4ASYNC`,
  `F2FS`, `XFS`
- `NFS_SERVER`: Set to `1` if the machine running this test is acting as NFS server. In that
  case, there should be an equivalent client test.
- `BENCHMARK`: The actual benchmark to run.
- `NUM_THREADS`: Number of threads to use.

Define these configurations by placing them in a file. Here is an example configuration
file:

```sh
dev=/dev/nvme0n1p1
FS=EXT4
JOURNAL_DEV=
NFS_SERVER=0
BENCHMARK=filebench-varmail-10m
NUM_THREADS=1
```

### Creating tests directory

As seen in the previous section, each configuration file defines one unique test. Create a
directory with multiple files where each file defines a unique test.

### Running all the tests

To run all the tests in the directory, run the following command:

```
./bm.sh my-configs-dir/
```

This command will run all the tests defined in folder `configs`.

### Simplifying test generations

To simplify generating test configurations, I have provided script
`configs/generate-configs.sh`. You can tweak that script to generate all the different
combinations. I have generated different configurations which are ready to use. Please find
these configurations under `configs/` directory.

### Test suites

## TODO
- Add instructions in https://github.com/harshadjs/fc-perf-v2.
- Send patches for upstream review and fix link above.
