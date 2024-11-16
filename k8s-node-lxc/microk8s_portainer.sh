#!/bin/bash

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $cwd

tee ./portainer-ingress.yaml > /dev/null <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portainer
  namespace: portainer
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-issuer
spec:
  ingressClassName: nginx
  rules:
  - host: $1
    http:
      paths:
      - backend:
          service:
            name: portainer
            port:
              number: 9000
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - $1
    secretName: letsencrypt-issuer
EOF

microk8s helm3 repo add portainer https://portainer.github.io/k8s/
microk8s helm3 repo update
microk8s helm3 upgrade --install --create-namespace -n portainer portainer portainer/portainer \
    --set service.type=ClusterIP \
    --set tls.force=false
#    --set tls.force=true \
#    --set ingress.enabled=true \
#    --set ingress.ingressClassName="nginx" \
#    --set ingress.annotations."nginx\.ingress\.kubernetes\.io/backend-protocol"=HTTPS \
#    --set ingress.hosts[0].host="portainer.imslab.gr" \
#    --set ingress.hosts[0].paths[0].path="/"

microk8s kubectl apply -f ./portainer-ingress.yaml