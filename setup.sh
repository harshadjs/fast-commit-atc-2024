#!/bin/bash

apt-get install kexec-tools fsmark libtool m4 automake make git bison flex sysstat fio trace-cmd tmux nfs-kernel-server nfs-common
echo '/mnt *(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports
cd filebench
libtoolize
aclocal
autoheader
automake --add-missing
autoconf
./configure
make
make install