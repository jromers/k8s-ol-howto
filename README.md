# How-to: Using Ingress and Load balancer with Oracle Linux and Kubernetes

In this how-to guide I’ll describe the configuration steps to setup an Ingress controller and software load balancer for a Kubernetes cluster. This configuration can be used in Kubernetes demos or even in small proof of concept installations where you do not have a load balancer provided by a cloud service provider.

Ingress is a technology in Kubernetes to allow inbound network connections to reach application containers running in the pods in the cluster (which by default have IP addresses only routable in the cluster).

I use the following software:
* [Oracle Linux Vagrant Boxes to build VirtualBox VMs](https://github.com/oracle/vagrant-boxes) for a 3-node Kubernetes cluster
* Nginx Ingress controller to manage Ingress traffic to the containerized applications
* Haproxy and Keepalived as software load balancer on the Oracle Linux Kubernetes worker nodes
* The [Cheeses application](https://docs.traefik.io/user-guide/kubernetes/) with three microservices (3 types of cheese) that is used to test the deployment (I use nginx-ingress in stead of Traefik).

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
Login to worker1 (vagrant ssh worker1) and install keepalived and replace the configuration file with the one below:
```
# sudo yum install -y keepalived
# sudo vi /etc/keepalived/keepalived.conf

vrrp_script chk_haproxy {
        script "killall -0 haproxy"
        interval 2
        weight 2
}
  
vrrp_instance VI_1 {
        interface eth0
        state MASTER
        virtual_router_id 51
        priority 101              # 101 on master, 100 on backup
        virtual_ipaddress {
            192.168.99.110        # the virtual IP
        }
        track_script {
            chk_haproxy
        }
}

# sudo systemctl enable keepalived
# sudo systemctl start keepalived
```
Login to worker2 (vagrant ssh worker2) install keepalived and replace the configuration file with the one below:
```
# sudo yum install -y keepalived
# sudo vi /etc/keepalived/keepalived.conf

vrrp_script chk_haproxy {
        script "killall -0 haproxy"
        interval 2
        weight 2
}
  
vrrp_instance VI_1 {
        interface eth0
        state MASTER
        virtual_router_id 51
        priority 100                    # 101 on master, 100 on backup
        virtual_ipaddress {
	   192.168.99.110        # the virtual IP
        }
        track_script {
            chk_haproxy
        }
}

# sudo systemctl enable keepalived
# sudo systemctl start keepalived
```
## Cheeses Application
The Cheeses application is used in a [Traefik Kubernetes demos](https://docs.traefik.io/user-guide/kubernetes/) and it demonstrates some Ingress use-cases for a microservices type of application. Below yaml-files are adjusted to our Vagrant Kubernetes cluster, basically what is changed are the hostnames in the [cheese-ingress.yaml](https://github.com/jromers/poc-cheeses/blob/master/cheese-ingress.yaml) file. If you run the configuration in a different network, please change the hostnames/domain in this file.
Download the files, explore the code and apply them in the cluster:
```
# wget https://raw.githubusercontent.com/jromers/poc-cheeses/master/cheese-deployments.yaml
# wget https://raw.githubusercontent.com/jromers/poc-cheeses/master/cheese-services.yaml
# more *.yaml
# kubectl apply -f cheese-deployments.yaml
# kubectl apply -f cheese-services.yaml
```
### Routing based on host names (HTTP Host header)
The three microservices are represented by three domain names, they all point to a single Virtual IP address. The Ingress controller routes the incoming HTTP request based on the used domain name to the related microservice running in a pod.
```
# wget https://raw.githubusercontent.com/jromers/poc-cheeses/master/cheese-ingress.yaml
# more cheese-ingress.yaml
# kubectl apply -f cheese-ingress.yaml
```
Verify the installation:
```
# kubectl get pods
# kubectl get services
# kubectl get ingress
```
Test the Cheeses application with curl or point the browser to the URLs:
```
# curl -v -H 'Host: stilton.vagrant.vm' http://stilton.vagrant.vm/
# curl -v -H 'Host: cheddar.vagrant.vm' http://192.168.99.110/

http://stilton.vagrant.vm/
http://cheddar.vagrant.vm/
http://wensleydale.vagrant.vm/
```
### Routing based on url path
In this case the Ingress is reconfigured to host the three microservices under one domain and based on the URL path routed to the related microservice running in a pod. Note the annotation “ingress.kubernetes.io/rewrite-target: /“ in the yaml file, which takes care of rewrite the path from e.g. “/stilton” to “/“ before sending to the target backend (because that’s what it is expecting).
```
# wget https://raw.githubusercontent.com/jromers/poc-cheeses/master/cheeses-ingress.yaml
# more cheeses-ingress.yaml
# kubectl apply -f cheeses-ingress.yaml
# kubectl get ingress
```
Test the Cheeses application with curl or point the browser to the URLs:
```
# curl -v -H 'Host: cheeses.vagrant.vm' http://cheeses.vagrant.vm/stilton

http://cheeses.vagrant.vm/stilton/
http://cheeses.vagrant.vm/cheddar/
http://cheeses.vagrant.vm/wensleydale/
```
