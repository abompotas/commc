#!/bin/bash

apt update
apt -y upgrade
apt -y install squashfuse curl gpg snapd nfs-common

systemctl daemon-reload
systemctl enable --now conf-kmsg

cat /opt/k8s-hosts >> /etc/hosts

snap install microk8s --classic

usermod -a -G microk8s $USER
chown -f -R $USER ~/.kube