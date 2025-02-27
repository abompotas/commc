#!/bin/bash

cd ~/k8s-node

hostnamectl hostname k8s-$1

apt update
apt -y upgrade
apt -y install squashfuse curl gpg snapd nfs-common

cat ./k8s-hosts >> /etc/hosts

snap install microk8s --classic

usermod -a -G microk8s imslab
chown -f -R imslab ~/.kube
su - imslab

cd ~/k8s-node

node_ip=`expr 200 + $1`
rm /etc/netplan/*
tee /etc/netplan/01-network-manager-all.yaml > /dev/null <<EOF
network:
  ethernets:
    ens18:
      addresses:
      - 192.168.7.7/24
      nameservers:
        addresses:
        - 8.8.8.8
        - 8.8.4.4
        search: []
      routes:
      - to: default
        via: 192.168.7.1
    ens19:
      addresses:
      - 192.168.0.${node_ip}/24
  version: 2
EOF
netplan generate
netplan apply

microk8s disable hostpath-storage
microk8s enable helm
microk8s enable ha-cluster
microk8s enable ingress
microk8s enable dns
microk8s enable cert-manager
microk8s enable rbac
microk8s enable community

tee ./letsencrypt-issuer.yaml > /dev/null <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $2
    privateKeySecretRef:
      name: letsencrypt-issuer
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

microk8s kubectl apply -f ./letsencrypt-issuer.yaml

if [ "$3" = true ]
then
  apt update
  apt install nfs-kernel-server -y
  mkdir -p $5
  chown nobody:nogroup $5
  chmod 0777 $5
  mv /etc/exports /etc/exports.bak
  echo "$5 $4/24(rw,sync,no_subtree_check)" | tee /etc/exports
  systemctl restart nfs-kernel-server

  microk8s helm3 repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
  microk8s helm3 repo update
  microk8s helm3 install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
      --namespace kube-system \
      --set kubeletDir=/var/snap/microk8s/common/var/lib/kubelet
  microk8s kubectl wait pod --selector app.kubernetes.io/name=csi-driver-nfs --for condition=ready --namespace kube-system
fi

if [ "$6" = true ]
then
  tee ./sc-nfs.yaml > /dev/null <<EOF
# sc-nfs.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: $4
  share: $5
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - hard
  - nfsvers=4.1
EOF

  microk8s kubectl apply -f ./sc-nfs.yaml
  microk8s kubectl patch storageclass nfs-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi
