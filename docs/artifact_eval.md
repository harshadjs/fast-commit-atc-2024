# Artifact Evaluation

This page describes how artifacts mentioned in the paper can be reproduced. Please ensure
that you have the access to virtual machine (credentials provided over private
channel). Following table describes how experiments mentioned in the paper can be
reproduced.


| Figure       | Key  | NFS   |
|:-------------|:-----|:------|
| 13/14/15 (a) | 13-a | False |
| 13/14/15 (b) | 13-b | True  |
| 13/14/15 (c) | 13-c | True  |
| 16           | 16   | False |
| 17           | 17   | True  |
| 18/19        | 13-c | True  |


## How to reproduce an experiment from the paper?

1. Note down the figure number from the paper.
2. Look up the corresponding key from the table above.
3. If the `NFS` flag is `False` for the test you are interested in, perform following steps:
   - Login to `SERVER` VM.
   - Run following commands:
   ```sh
   cd /root/fast-commit-atc-2024
   ./run_benchmark.sh configs/eval/<key>
   ```
4. If the `NFS` flag is `False` for the test you are interested in, perform following steps:
   - Login to `SERVER` VM.
   - Run following commands:
   ```sh
   cd /root/fast-commit-atc-2024
   ./run_benchmark.sh configs/eval/<key>/server
   ```
   - Login to `CLIENT` VM.
   - Run following commands:
   ```sh
   cd /root/fast-commit-atc-2024
   ./run_benchmark.sh configs/eval/<key>/client
   ```
   
### Example: Reproducing Fig 13 A

1. Figure number is `13 A`.
2. Key noted from the table is `13-a`.
3. `NFS` flag is False, so run following commands on the server VM:
   ```sh
   cd /root/fast-commit-atc-2024
   ./run_benchmark.sh configs/eval/13-a
   ```

### Example: Reproducing Fig 13 B

1. Figure number is `13 B`
2. Key noted from the table is `13-b`.
3. `NFS` flag is True, so run following commands on the server VM:
   ```sh
   cd /root/fast-commit-atc-2024
   ./run_benchmark.sh configs/eval/13-b/server
   ```
4. Run following commands on the client VM:
   ```sh
   cd /root/fast-commit-atc-2024
   ./run_benchmark.sh configs/eval/13-b/client
   ```
