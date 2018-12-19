# How-to guides: Using Oracle Linux and Kubernetes for on-premise deployments

In the How-to guides I describe the configuration steps to use cloud-native software in an Oracle Linux on-premise deployment. Most of the information is a result of work I did with customers or material I used for workshops or hands-on labs.

This will be a growing list with How-to guides organized in sub-projects, for now the following guides are available:
* [Install Ingress and Load balancer for on-premise Oracle Linux and Kubernetes](https://github.com/jromers/k8s-ol-howto/tree/master/ingress_loadbalancer)
* [Install Prometheus & Grafana with Helm and NFS store for on-premise Oracle Linux and Kubernetes](https://github.com/jromers/k8s-ol-howto/tree/master/prometheus-nfs)

The How-to guides are simple to use and designed to run on a laptop. This is a very conveniant setup and a nice way to explore or develop cloud native applications without spending cloud resources. Another advantage for this setup is that you build an infrastructure on your laptop that is similar to your production environment including clustered nodes.

You can use any developer platform (Windows, MacOS or Linux). But do not hesitate to use this How-to on any virtualization platform (Oracle Linux VMs based on KVM or VMware) or on bare-metal Oracle Linux servers in your datacenter network.

Fore reference, I use the following software in the How-to guides:
* [Using Oracle Linux Vagarant Boxes](http://public-yum.oracle.com/boxes)
* [Vagrant files and examples for Oracle products and projects](https://github.com/oracle/vagrant-boxes) 
* [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800)
* [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/)


