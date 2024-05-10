# Artifact Evaluation for USENIX ATC 2024

This page describes how artifacts mentioned in the paper can be reproduced. Please ensure
that you have the access to virtual machine (credentials provided over artifact submission
website).

## Getting Started

For the purpose of the evaluation, please use provided `NFS_SERVER_IP` and `NFS_CLIENT_IP`
in the evaluation submission.

- Login to the server VM. The password is provided in the submission instructions.

```sh
ssh eval@$NFS_SERVER_IP
```

- Login to the client VM. The password is provided in the submission instructions.

```sh
ssh eval@$NFS_SERVER_IP
```

- Switch to `root` user and cd to `/root/fast-commit-atc-2024` on both the VMs.

```sh
# Running on NFS SERVER VM.
$ sudo su
$ cd /root/fast-commit-atc-2024
```

```sh
# Running on NFS CLIENT VM.
$ sudo su
$ cd /root/fast-commit-atc-2024
```

- Run sample evaluation on the server VM.

```sh
# Running on NFS SERVER VM.
$ ./bm.sh eval/quick/local
```

- Run sample evaluation over NFS.

```sh
# Running on NFS SERVER VM.
$ ./bm.sh eval/quick/server
```

```sh
# Running on NFS CLIENT VM.
$ ./bm.sh eval/quick/client
```

## Detailed Evaluation

Following table describes the commands that should be run to reproduce the results
from a given experiment in the paper.

| Figure       | Server                   | Client                                 |
|:-------------|:-------------------------|:---------------------------------------|
| 13/14/15 (a) | ./bm.sh eval/13-a        | N/A                                    |
| 13/14/15 (b) | ./bm.sh eval/13-b/server | ./bm.sh eval/13-b/client 10.128.15.220 |
| 13/14/15 (c) | ./bm.sh eval/13-c/server | ./bm.sh eval/13-c/client 10.128.15.220 |
| 16           | ./bm.sh eval/16          | N/A                                    |
| 17           | ./bm.sh eval/17/server   | ./bm.sh eval/17/client 10.128.15.220   |
| 18/19        | ./bm.sh eval/13-c/server | ./bm.sh eval/13-c/client 10.128.15.220 |


- Look up the the figure number from the paper.
- Run respective commands on the server and optionally on the client VMs.
- Each run reproduce all the test in a given figure and the results will be available under
  /root/results directory.

