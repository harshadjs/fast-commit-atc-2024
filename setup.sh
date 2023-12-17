#!/bin/bash

apt-get install xfsprogs kexec-tools fsmark libtool m4 automake make git bison flex sysstat fio trace-cmd tmux nfs-kernel-server nfs-common

echo '/mnt *(rw,sync,no_subtree_check,no_root_squash)' > /etc/exports
echo """dev=/dev/nvme0n1
domain=40
JOURNAL_DEV=/dev/nvme0n3
FAST_COMMIT=1
NFS_SERVER=0
NFS_CLIENT=0
BENCHMARK=filebench-varmail
NFS_CLIENT_OPS="-o async"
""" > ~/fast-commit-override.sh
cd filebench
libtoolize
aclocal
autoheader
automake --add-missing
autoconf
./configure
make
make install