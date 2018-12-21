# How-to: Install Prometheus & Grafana with Helm for on-premise Oracle Linux and Kubernetes deployments

In this How-to guide I’ll describe the configuration steps to setup Prometheus and Grafana on an Oracle Linux on-premise Kubernetes cluster. The following software packages are used in this deployment:
* [Oracle Linux Vagrant Boxes](https://github.com/oracle/vagrant-boxes) to build a 3-node Kubernetes cluster
* [Helm](https://docs.helm.sh/) to install Kubernetes applications
* [NFS Client Provisioner](https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner) using an external NFS server (optional)
* [Prometheus Operator](https://github.com/coreos/prometheus-operator) for Kubernetes

I use this configuration in Kubernetes demos, workshops or even in small proof of concept installations where you want to have a quick installation experience. But do not hesitate to use this How-to guide for bare-metal or other virtual deployments.

## Prerequisites

I run this deployment on a laptop using Vagrant and VirtualBox. I follow the standard installation as published on the Oracle Community website: [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800). 

The Prometheus Operator uses by default non-persistent storage which means that when the pod restarts, the historical monitoring data is lost. This is OK for a quick demo, but for a workshop, PoC or production deployment you like to have persistent volumes. In this guide I use an example with a NFS share based on the configuration that is explained in my NFS Client Provisioner How-to guide.

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

## Install Prometheus and Grafana

Prometheus is used to monitor Oracle Linux nodes in the cluster, the health and status of the Kubernetes resources and it dynamically adds installed resources to the monitoring system. Grafana is graphical interface with several dashboards to visualize the collected Prometheus metrics.

First, start with adding the repo with the Prometheus Operator charts:
```
# helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
```

The Helm chart installs out-of-the-box, but I use a yaml file with customized settings. Change the default password in the yaml file to your own, preferred admin password and install Prometheus and Grafana, based on the fully autoconfigured Prometheus Operator. For the non-persistent storage volumes deployment use:
```
# wget values-prometheus.yaml
# vi values-prometheus.yaml
  change default password
# helm install --namespace monitoring --name prometheus-operator coreos/prometheus-operator
# helm install coreos/kube-prometheus --name kube-prometheus --namespace monitoring --values values-prometheus.yaml
```

For the persistent storage volumes with the NFS Client Provisioner I use a yaml file with customized settings. Like before, change the admin password. By default the StorageClass is *nfs-client* (if you use the NFS Client Provisioner) but for your deployment this may be different. Also the amount of claimed space is something you might change (8Gi in my deployment):
```
# wget values-nfs-prometheus.yaml
# vi values-nfs-prometheus.yaml
  change default password
# helm install --namespace monitoring --name prometheus-operator coreos/prometheus-operator
# helm install coreos/kube-prometheus --name kube-prometheus --namespace monitoring --values values-nfs-prometheus.yaml
```

The Prometheus GUI and the Grafana GUI endpoints are exposed as ClusterIP and not reachable for outside access. To access the dashboard from outside the cluster change from  ClusterIP to NodePort.
```
# kubectl edit svc kube-prometheus -n monitoring
  change "type: ClusterIP" to "type: NodePort"
# kubectl edit svc kube-prometheus-grafana -n monitoring
  change "type: ClusterIP" to "type: NodePort"
# kubectl get services -n monitoring
  this will provide you the port nrs to access the GUI
```

Connect to the Prometheus GUI or the Grafana Dashboards with the URL to one of the worker nodes in the cluster and the provide NodePort numbers (in your case the NodePort number are different):
```
# kubectl get services -n monitoring |grep NodePort
kube-prometheus                       NodePort    10.102.21.69     <none>        9090:31287/TCP      2m
kube-prometheus-grafana               NodePort    10.99.2.105      <none>        80:32216/TCP        2m

http://worker1.vagrant.vm:31287/
http://worker1.vagrant.vm:32216/
```

## Troubleshooting
### Problem 1: kubelet metrics down 

If you point your browser to the Prometheus Targets (in my server example this is *http://worker1.vagrant.vm:31287/targets*) you will see a page with all the scrape targets currently configured for this Prometheus server. Check the status of the kubelet processes running on each node in the Kubernetes cluster. 

If the state is down with the error message *server returned HTTP status 403 Forbidden*, than change the kubelet startup command in the systemd files and restart the process. On each node of the cluster do:

```
# sudo vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf 
Environment="KUBELET_EXTRA_ARGS=--authentication-token-webhook"
# sudo systemctl daemon-reload
# sudo systemctl stop kubelet
# sudo systemctl start kubelet
```

If you use the Vagrant Kubernetes installation with a local Container Registry you need to change another systemd file:
```
# sudo vi /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf 
add to KUBELET_EXTRA_ARGS "--authentication-token-webhook"
# sudo systemctl daemon-reload
# sudo systemctl stop kubelet
# sudo systemctl start kubelet
```

### Problem 2: node-exporter metrics down 

On the same Prometheus Target page, if you see the state of the node-exporter is down than most likely it can't connect to the node-exporter process running on port 9100 on the Oracle Linux nodes in the Kubernetes cluster. Change the firewall settings:
```
# firewall-cmd --zone=public --add-port=9100/tcp
# firewall-cmd --zone=public --permanent --add-port=9100/tcp
# firewall-cmd --reload
```
