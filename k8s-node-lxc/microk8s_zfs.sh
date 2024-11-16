#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

microk8s stop
find /var/snap/microk8s/common/var/lib/containerd -mindepth 1 -maxdepth 1 ! -name "*zfs" -exec rm -r "{}" \;
sed -i 's/"${SNAPSHOTTER}"/"zfs"/' /var/snap/microk8s/current/args/containerd-template.toml
microk8s start