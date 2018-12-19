# How-to: Install Prometheus & Grafana with Helm and NFS store for on-premise Oracle Linux and Kubernetes

In this how-to guide I’ll describe the configuration steps to setup Prometheus and Grafana on an Oracle Linux on-premise Kubernetes cluster. I use this configuration in Kubernetes demos, workshops or even in small proof of concept installations where you want to have a quick installation experience.

I use the following software:
* [Oracle Linux Vagrant Boxes](https://github.com/oracle/vagrant-boxes) to build 3-node Kubernetes cluster
* [Helm](https://docs.helm.sh/) to install Kubernetes applications
* [NFS Client Provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) using an external NFS server
* [Prometheus Operator](https://github.com/coreos/prometheus-operator) for Kubernetes

## Prerequisites

I run this deployment on a laptop using Vagrant and VirtualBox. I follow the standard installation as published on the Oracle Community website: [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800). 

## Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources. In this How-to guide I use the [Helm Charts](https://github.com/helm/charts/tree/master/stable) for the NFS Client Provisioner and the Prometheus Operator.

Install Helm on MacOSX with the [Homebrew](https://brew.sh/) package manager:
```
# brew install kubernetes-helm
```
For other platforms check the [releases, download and install](https://github.com/helm/helm/releases) (see below for Linux):
```
# wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.0-linux-amd64.tar.gz
# tar xvfx helm-v2.12.0-linux-amd64.tar.gz
# cp linux-amd64/helm /usr/local/bin/helm
```

Install Tiller (this is the server part of Helm) on your cluster, it includes the required service-account:
```
# kubectl -n kube-system create sa tiller
# kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# helm init --service-account tiller
```


## Install NFS Client Provisioner

The NFS Client Provisioner is a Kubernetes application to dynamically create persistent volumes for your applications. The NFS share is provided by an already configured NFS server outside your Kubernetes deployment.

First, on each Oracle Linux worker node, install the NFS packages:
```
# yum install -y nfs-utils
```
The [Helm NFS Provisioner chart](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) requires some configuration settings so that your Kubernetes server knows how to find your external NFS server and mountpath. For this I use a customized [values.yaml](https://github.com/jromers/k8s-ol-howto/blob/master/prometheus-nfs/values-nfs-client.yaml) file to overwrite the default settings. 
```
# wget https://raw.githubusercontent.com/jromers/k8s-ol-howto/master/prometheus-nfs/values-nfs-client.yaml
# more values-nfs-client.yaml 
replicaCount: 2

nfs:
  server: XXX.XXX.XXX.XXX
  path: /path/to/shared/dir
  mountOptions:

storageClass:
  archiveOnDelete: false
```
Change the server and path settings in the values-nfs-client.yaml file to the NFS server and mountpath you use in your infrastructure.

Install the provisioner:
```
# helm install --name ext -f values-nfs-client.yaml stable/nfs-client-provisioner
# kubectl k get pods
NAME                                          READY     STATUS    RESTARTS   AGE
ext-nfs-client-provisioner-769f9fcdd7-cpq4h   1/1       Running   0          1d
ext-nfs-client-provisioner-769f9fcdd7-lpdhb   1/1       Running   0          1d
```
For the sake of simplicity, I did not pay much attention to the NFS permissions. In real production environments you should set proper UID and GID mappings between containers and NFS share. On my NFS server (with /export/kubernetes/devtest)  I have the following directory permissions:
```
# ls -l /export/kubernetes/
total 4
drwxr-xr-x 4 nfsnobody nfsnobody 4096 Dec 18 22:17 devtest
```
### Troubleshooting

tbd

## Install Prometheus and Grafana

Add Prometheus repo:
```
# helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
```

Install Prometheus and Grafana, this prometheus operator does include the nice dashboard used by Grafana.
```
# helm install --namespace monitoring --name prometheus-operator coreos/prometheus-operator
# helm install coreos/kube-prometheus --name kube-prometheus --namespace monitoring --values values-nfs-prometheus.yaml
```

By default the Prometheus GUI and the Grafana GUI endpoints are exposed as ClusterIP and not reachable for outside access. To access the dashboard from outside the cluster change from  ClusterIP to NodePort.
```
# kubectl edit svc kube-prometheus -n monitoring
  change "type: ClusterIP" to "type: NodePort"
# kubectl edit svc kube-prometheus-grafana -n monitoring
  change "type: ClusterIP" to "type: NodePort"
# kubectl get services -n monitoring
  this will provide you the port nrs to access the GUI
```
