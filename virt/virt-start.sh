#!/bin/bash

if [ -z ${RHCOS_ISO+x} ]; then
        echo "Please set RHCOS_ISO"
        exit 1
fi

if [ -z ${VM_NAME+x} ]; then
        echo "Please set the VM_NAME"
        exit 1
fi

if [ -z ${NET_NAME+x} ]; then
        echo "Please set the NET_NAME"
        exit 1
fi

OS_VARIANT="rhel8.1"
RAM_MB="16384"
DISK_GB="20"
CPU_CORE="6"

nohup virt-install \
    --connect qemu:///system \
    -n "${VM_NAME}" \
    -r "${RAM_MB}" \
    --vcpus "${CPU_CORE}" \
    --os-variant="${OS_VARIANT}" \
    --import \
    --network=network:${NET_NAME},mac=52:54:00:ee:42:e6 \
    --graphics=none \
    --events on_reboot=restart \
    --cdrom "${RHCOS_ISO}" \
    --disk pool=default,size="${DISK_GB}" \
    --boot hd,cdrom \
    --noautoconsole \
    --wait=-1 &
