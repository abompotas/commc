#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

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
    email: $1
    privateKeySecretRef:
      name: letsencrypt-issuer
    solvers:
      - http01:
          ingress:
            class: nginx
EOF

microk8s kubectl apply -f ./letsencrypt-issuer.yaml