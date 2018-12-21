# How-to: Install NFS Client Provisioner and use NFS as persistent storage for on-premise Oracle Linux and Kubernetes deployments

In this How-to guide I’ll describe the configuration steps to setup the NFS Client Provisioner on an Oracle Linux on-premise Kubernetes cluster. The provisioner automatically creates persistent volumes in Kubernetes for an external, already configured NFS server.  The following software packages are used in this deployment:

* [Oracle Linux Vagrant Boxes](https://github.com/oracle/vagrant-boxes) to build 3-node Kubernetes cluster
* [Helm](https://docs.helm.sh/) to install Kubernetes applications
* [NFS Client Provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) using an external NFS server

I use this configuration in Kubernetes demos, workshops or even in small proof of concept installations where you want to have a quick installation experience. But do not hesitate to use this How-to guide for bare-metal or other virtual deployments.

## Prerequisites

I run this deployment on a laptop using Vagrant and VirtualBox. I follow the standard installation as published on the Oracle Community website: [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800). Here's my Kubernetes cluster:
```
# kubectl get nodes
NAME                 STATUS    ROLES     AGE       VERSION
master.vagrant.vm    Ready     master    6m        v1.9.11+2.1.1.el7
worker1.vagrant.vm   Ready     <none>    3m        v1.9.11+2.1.1.el7
worker2.vagrant.vm   Ready     <none>    43s       v1.9.11+2.1.1.el7
```

You must have an already configured NFS server in your network and you should know the IP_address of the server and the exported mountpath for the NFS share. In this How-to guide I use:
```
Server: 	10.10.10.10
Mountpath: 	/export/kubernetes/devtest
```
If you do not have an external NFS server, try to [setup NFS services](https://docs.oracle.com/cd/E52668_01/E54669/html/ol7-cfgsvr-nfs.html) on your Kubernetes master node in this little 3-node cluster (for test and demo purposes only).

## Install Helm

Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources. In this How-to guide I use the [Helm Charts](https://github.com/helm/charts/tree/master/stable) for the NFS Client Provisioner and the Prometheus Operator.

Install Helm on MacOSX with the [Homebrew](https://brew.sh/) package manager:
```
# brew install kubernetes-helm
```
For other platforms check the [releases, download and install](https://github.com/helm/helm/releases) the Helm binary (see below for Linux):
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

The NFS Client Provisioner is a Kubernetes application to dynamically create persistent volumes for your applications. The NFS share is provided by an already existing NFS server outside your Kubernetes deployment.

First, on each Oracle Linux worker node, install the NFS packages:
```
# yum install -y nfs-utils
```
The [Helm NFS Provisioner chart](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) requires some configuration settings so that your Kubernetes server knows how to find your external NFS server and mountpath. For this I use a customized yaml file to overwrite the default settings. 
```
# wget https://raw.githubusercontent.com/jromers/k8s-ol-howto/master/nfs-client/values-nfs-client.yaml
# more values-nfs-client.yaml 
replicaCount: 2

nfs:
  server: 10.10.10.10
  path: /export/kubernetes/devtest
  mountOptions:

storageClass:
  archiveOnDelete: false
```
Change the **server** and **path** settings in the values-nfs-client.yaml file to the NFS server and mountpath you use in your infrastructure. This configuration uses two Replicas and when an applications is deleted with Helm it also removes the files from the NFS store. If you want to keep the data after the application is removed set archiveOnDelete to true.

Install the provisioner:
```
# helm install --name ext -f values-nfs-client.yaml stable/nfs-client-provisioner
# kubectl get storageclass
NAME         PROVISIONER                                AGE
nfs-client   cluster.local/ext-nfs-client-provisioner   3m
# kubectl get pods
NAME                                          READY     STATUS    RESTARTS   AGE
ext-nfs-client-provisioner-6fcf996c79-5svck   1/1       Running   0          4m
ext-nfs-client-provisioner-6fcf996c79-wcp57   1/1       Running   0          4m
```
For the sake of simplicity, I did not pay much attention to the NFS permissions.
In real production environments you should set proper UID and GID mappings between containers and NFS share. 

On my NFS server (with /export/kubernetes/devtest) I have the following directory permissions:
```
# ls -l /export/kubernetes/
total 4
drwxr-xr-x 4 nfsnobody nfsnobody 4096 Dec 18 22:17 devtest
```

### NFS Client Provisioner Troubleshooting

