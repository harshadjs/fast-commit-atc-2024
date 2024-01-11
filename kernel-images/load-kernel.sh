#!/bin/bash

image=$1
if [ "$image" == "" ]; then
	echo "Usage: ./load-kernel.sh <image>"
	exit
fi

kexec -l $image --command-line="root=/dev/sda1 console=tty0 console=ttyS0,115200 earlyprintk=ttyS0,115200 consoleblank=0 intel_iommu=off" -f -x
