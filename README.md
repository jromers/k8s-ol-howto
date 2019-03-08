# How-to guides: Using Oracle Linux and Kubernetes for on-premise deployments

In the How-to guides I describe the configuration steps to use cloud-native software in an Oracle Linux on-premise deployment. Most of the information is a result of work I did with customers or material I used for workshops or hands-on labs.

All the How-to guides are tested on my demo-infrastructure, they are simple to use and designed to run on a laptop. This is a very convenient setup and a nice way to explore or develop cloud native applications without spending cloud resources. Use the following Oracle Community document to build this infrastructure:
* [Use Vagrant and VirtualBox to setup Oracle Container Services for use with Kubernetes](https://community.oracle.com/docs/DOC-1022800)

This will be a growing list with How-to guides organized in sub-projects, for now the following guides are available:
* [Install Helm package manager for on-premise Oracle Linux and Kubernetes](https://github.com/jromers/k8s-ol-howto/tree/master/helm)
* [Install NFS Client Provisioner as persistent storage for on-premise Oracle Linux and Kubernetes deployments](https://github.com/jromers/k8s-ol-howto/tree/master/nfs-client)
* [Install Prometheus & Grafana with Helm and NFS store for on-premise Oracle Linux and Kubernetes](https://github.com/jromers/k8s-ol-howto/tree/master/prometheus-nfs)
* [Install Ingress and Load balancer for on-premise Oracle Linux and Kubernetes](https://github.com/jromers/k8s-ol-howto/tree/master/ingress_loadbalancer)

You can use any developer platform (Windows, MacOS or Linux). But do not hesitate to use the How-tos on any virtualization platform (Oracle Linux VMs based on KVM or VMware) or on bare-metal Oracle Linux servers in your datacenter network.

Fore reference, more information on the software used in the How-to guides:
* [Using Oracle Linux Vagarant Boxes](http://public-yum.oracle.com/boxes)
* [Vagrant files and examples for Oracle products and projects](https://github.com/oracle/vagrant-boxes) 
* [Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/)
* [Useful tips for getting ready for the cloud](https://cloudinfrastructuresoftware.blogspot.com/)

