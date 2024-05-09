# Fast Commit ATC 2024 Benchmarking

This repository contains benchmarking scripts that were used to evaluate fast commit
performance for ATC 2024 paper. We have merged majority of the fast commit kernel code into
the upstream Linux kernel. Kernel versions >= 5.10 support Fast Commits natively. Some
kernel patches are being [actively reviewed](link) upstream, and we expect them to be merged
soon as well. These unmerged patches can be found
[here](https://github.com/harshadjs/fc-perf-v2).

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



## TODO
- Add instructions in https://github.com/harshadjs/fc-perf-v2.
- Send patches for upstream review and fix link above.
