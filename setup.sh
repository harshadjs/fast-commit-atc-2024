#!/bin/bash

echo "Installing necessary software"

sudo apt-get install xfsprogs kexec-tools fsmark dbench fdisk libtool m4 automake make git bison flex sysstat python3 fio trace-cmd tmux nfs-kernel-server nfs-common postmark libelf-dev libssl-dev bc f2fs-tools

echo "Setting up NFS export"
echo '/mnt *(rw,sync,no_subtree_check,no_root_squash)' > /etc/exports
