#!/bin/bash

apt-get install kexec-tools fsmark libtool m4 automake make git bison flex sysstat fio trace-cmd tmux nfs-kernel-server nfs-common
cd filebench
libtoolize
aclocal
autoheader
automake --add-missing
autoconf
./configure
make
make install