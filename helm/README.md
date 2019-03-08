# How-to: Install Helm package manager for on-premise Oracle Linux and Kubernetes

In this how-to guide I’ll describe the configuration steps to install Helm from the Oracle Linux distribution. For generic information on Helm go to the [Helm Documentation](https://helm.sh/docs/) website.

Helm is a package-manager for Kubernetes, like yum is package-manager for Oracle Linux. Helm charts are packages of pre-configured Kubernetes resources and it makes deploying applications in Kubernetes 
very easy. Helm has additional features such as versioning, delete, upgrade or rollback deployments.

The Helm client is a program that you run as a developer or ops person. But there is also a second part to Helm and that is Tiller, this is the server side component of Helm and it runs in the Kubernetes cluster and handles the Helm packages.

## Install Helm package
The version of Helm that is used at the moment of writing is 
available in the ol7_developer channel of Oracle Linux.
First step is to install the Helm program in Oracle Linux:
```
# sudo yum-config-manager --enable ol7_developer
# sudo yum install helm
```

## Create Kubernetes secret and service-account
We use the Oracle Linux version of Helm/Tiller and the Tiller component is hosted as container image on the Oracle Container Registry. Before installing Tiller make sure you have accepted Oracle Standard Terms and Restrictions in [Container Services (Developer)](https://container-registry.oracle.com) section on the [Oracle Container Registry](https://container-registry.oracle.com).

A worker node in the Kubernetes cluster needs to authenticate against the registry with your Oracle SSO credentials to pull the Tiller image from the registry. You can do this by storing your Oracle SSO credentials in a Kubernetes secret object and use that secret when you deploy the container image:
```
# kubectl create secret docker-registry ora-registry --namespace kube-system \
    --docker-server=container-registry.oracle.com \
    --docker-username="joe.random@oracle.com" \
    --docker-password="joe_sso_passwd" \
    --docker-email="joe.random@oracle.com"
```
A Kubernetes service-account is created to provide an identity to running processes in the cluster. A tiller service account is created added with the corresponding *ora-registry* secret for the Oracle Container Registry:
```
# kubectl create -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
imagePullSecrets:
  - name: ora-registry
EOF
```
Tiller needs to manage resources in all namespaces of the cluster, so we need to create a kind of super-user access for the *tiller* service-account. This is done by creating a ClusterRoleBinding:
```
# kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller
```

## Initialize Helm and install Tiller
Now it's time to initialize Helm in the local CLI and deploy the Tiller container image into the Kubernetes cluster. This could be done in a single step:
```
# helm init --service-account tiller \
    --tiller-image \
    container-registry.oracle.com/kubernetes_developer/tiller:v2.9.1 
```
To test if the installation works, you can do this quick test:
```
# helm version
# helm repo update
# helm search mysql
```
## Automated install script
The instructions in this How-to guide were provided by [AmedeeBulle](https://github.com/AmedeeBulle) and he was so kind to provide the [helm-oracle.sh shell-script](https://github.com/jromers/k8s-ol-howto/tree/master/helm/helm-oracle.sh) to automate the installation steps. Running this script (replace Oracle SSO username in the script with yours before running the script) is even more secure than providing CLI commands beacuse it hides your password from the command-line history.