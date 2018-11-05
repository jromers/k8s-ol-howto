# How-to: Using Ingress and Load balancer with Oracle Linux and Kubernetes

In this how-to guide I’ll describe the configuration steps to setup an Ingress controller and software load balancer for a Kubernetes cluster. This configuration can be used in Kubernetes demos or even in small proof of concept installations where you do not have a load balancer provided by a cloud service provider.

Ingress is a technology in Kubernetes to allow inbound network connections to reach application containers running in the pods in the cluster (which by default have IP addresses only routable in the cluster).

I use the following software:
* [Oracle Linux Vagrant Boxes to build VirtualBox VMs](https://github.com/oracle/vagrant-boxes) for a 3-node Kubernetes cluster
* Nginx Ingress controller to manage Ingress traffic to the containerized applications
* Haproxy and Keepalived as software load balancer on the Oracle Linux Kubernetes worker nodes
* The Cheeses application with three microservices (3 types of cheese) that is used to test the deployment

## Prerequisites

I run this deployment on a laptop using Vagrant and VirtualBox. I follow the standard installation as published on the Oracle Community website: [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800). 

This how-to will run on every developer platform (Windows, MacOS or Linux). But do not hesitate to use this how-to on any virtualization platform (Oracle Linux VMs based on KVM or VMware) or on bare-metal Oracle Linux servers in your datacenter network.

In this deployment I use the standard IP addresses from the Vagrantfile, I only add one IP-addresses to be used as Virtual IP for the load balancer with additional hostnames for the microservices. I add these addresses to my local hosts file on the laptop.
```
192.168.99.100  master.vagrant.vm
192.168.99.101  worker1.vagrant.vm
192.168.99.102  worker2.vagrant.vm
192.168.99.110  cheeses.vagrant.vm stilton.vagrant.vm cheddar.vagrant.vm wensleydale.vagrant.vm
```

## Ingress Controller and Load balancer
Ingress is a resource in the Kubernetes cluster for access to the services in the cluster, typically based on the HTTP protocol.  The functionality is controlled by an Ingress controller and there are several controller implementations. In this how-to I use the [nginx-ingress controller](https://kubernetes.github.io/ingress-nginx/).

Depending on the deployment type (AWS, GCE, OKE or bare-metal) there is communication between Ingress and load balancers. In this how-to I use the bare-metal deployment type and place haproxy and keepalived in front of the Ingress controller to forward all incoming traffic to the Ingress controller.

## Installation steps

I start with the configuration of the Ingress controller. When the Ingress service is exposed through a NodePort I’ll add the exposed ports to the haproxy configuration.

### Ingress controller

Login to master node (vagrant ssh master) and do:

```
# wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
# wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml
# more *.yaml
# kubectl apply -f mandatory.yaml
# kubectl apply -f service-nodeport.yaml
```
To verify the installation:
```
# kubectl get pods --all-namespaces -l app.kubernetes.io/name=ingress-nginx
```
Check the HTTP and HTTPS NodePorts of the Ingress controller, they will be used in the haproxy configuration:
```
# kubectl get services -n ingress-nginx
…….80:XXXXX/TCP,443:YYYYY/TCP……
```

### Haproxy 

Login on the worker nodes (vagrant ssh worker1 or vagrant ssh worker2) and install haproxy on each node. After installation, change the standard haproxy configuration file on each node. Remove the example configuration in the second part of the file (after the line that starts with “main frontend which proxys to the backends”) and replace with below configuration. Replace the XXXXX and YYYYY with the NodePort numbers found in the previous section.
```
# sudo yum -y install haproxy
# sudo vi /etc/haproxy/haproxy.cfg 

#<skipped first part of configuration file>

#---------------------------------------------------------------------
# main frontend which proxys to the backends
#---------------------------------------------------------------------
frontend http_front
    mode tcp
    bind *:80
    default_backend http_back
frontend https_front
    mode tcp
    bind *:443
    default_backend https_back
backend http_back
    mode tcp
    server worker1 192.168.99.101:XXXXX 
    server worker2 192.168.99.102:XXXXX
backend https_back
    mode tcp
    server worker1 192.168.99.101:YYYYY 
    server worker2 192.168.99.102:YYYYY

# sudo systemctl enable haproxy
# sudo systemctl start haproxy
```

### Keepalive configuration
As described earlier, we use the following IP addresses in our standard laptop deployment: 
```
Worker1: 	192.168.99.101
Worker2: 	192.168.99.102
Virtual IP: 	192.168.99.110
```
