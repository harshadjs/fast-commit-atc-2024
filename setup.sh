#!/bin/bash
# sudo dpkg -i mysql-apt-config_0.8.29-1_all.deb
# sudo apt-get update
apt-get install xfsprogs kexec-tools fsmark dbench fdisk libtool m4 automake make git bison flex sysstat python2 fio trace-cmd tmux nfs-kernel-server nfs-common postmark libelf-dev libssl-dev bc f2fs-tools # mysql-community-server sysbench
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
