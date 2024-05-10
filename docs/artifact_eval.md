# Artifact Evaluation

This page describes how artifacts mentioned in the paper can be reproduced. Please ensure
that you have the access to virtual machine (credentials provided over private
channel). Following table describes the commands that should be run to reproduce the results
from a given experiment in the paper.


| Figure       | Server                   | Client                                 |
|:-------------|:-------------------------|:---------------------------------------|
| 13/14/15 (a) | ./bm.sh eval/13-a        | N/A                                    |
| 13/14/15 (b) | ./bm.sh eval/13-b/server | ./bm.sh eval/13-b/client 10.128.15.220 |
| 13/14/15 (c) | ./bm.sh eval/13-c/server | ./bm.sh eval/13-c/client 10.128.15.220 |
| 16           | ./bm.sh eval/16          | N/A                                    |
| 17           | ./bm.sh eval/17/server   | ./bm.sh eval/16/client 10.128.15.220   |
| 18/19        | ./bm.sh eval/13-c/server | ./bm.sh eval/13-c/client 10.128.15.220 |


- Look up the the figure number from the paper.
- Run respective commands on the server and optionally on the client VMs.
- Each run reproduce all the test in a given figure and the results will be available under
  /root/results directory.

