#!/bin/bash
# Install HELM from Oracle repos

# Please replace with your own Orace SSO username.
User="joe.random@oracle.com"

if [ $# -gt 0 ]
then
  User="$1"
fi

echo -n "Password for ${User}: "
read -s Pass
echo

# Install package
sudo yum --enablerepo ol7_developer -y install helm

# Create secret
kubectl create secret docker-registry ora-registry --namespace kube-system \
  --docker-server=container-registry-fra.oracle.com \
  --docker-username="${User}" \
  --docker-password="${Pass}" \
  --docker-email="${User}"

# Create service account, together with the secret
kubectl create -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
imagePullSecrets:
  - name: ora-registry
EOF

# Alternative way to create service account
# kubectl create serviceaccount --namespace kube-system tiller
# kubectl patch serviceaccount tiller --namespace kube-system \
#   -p '{"imagePullSecrets": [{"name": "ora-registry"}]}'

kubectl create clusterrolebinding tiller-cluster-rule \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller

# Initialize
helm init --service-account tiller --tiller-image container-registry-fra.oracle.com/kubernetes_developer/tiller:v2.9.1 --wait

# Quick test
helm version
helm search mysql

