# Kubernetes Autoscaling Demo with sample application

## Horizontal Pod Autoscaling (HPA)

HPA allows us to scale pods when their resource utilisation goes over a threshold <br/>

## Requirements

### Code checkout
Clone the repository for demo [codeCheckout](git@github.com:sameer1701/spring-boot-hello-world-example.git)

### A Cluster 

* For both autoscaling guides, we'll need a cluster. <br/>
* For `Cluster Autoscaler` You need a cloud based cluster that supports the cluster autoscaler <br/>
* For this demo we are using EKS cluster.

### Cluster Autoscaling - Creating EKS Cluster

You can provision one using [Terraform](https://github.com/sameer1701/terraform-mgmt/tree/master/EKS) script.

### Metric Server
[Metric Server](https://github.com/kubernetes-sigs/metrics-server) provides container resource metrics for use in autoscaling <br/>
To install metric server follow below steps<br/>
<b>Important Note</b> : For Demo clusters , you will need to disable TLS <br/>
You can disable TLS by adding the following to the metrics-server container args <br/>
<b>For production, make sure you remove the following :</b> <br/>
```
- --kubelet-insecure-tls
- --kubelet-preferred-address-types="InternalIP"
```

Deployment: <br/>
Run below manifest to deploy metric server

```
 - cd  k8s/metric-server-ingress
 - kubectl apply -f metric-server.yaml
 #test 
 - kubectl -n kube-system get pods
 #note: wait for metrics to populate!
 - kubectl top nodes
 
```
### Deployment of Example application
For all autoscaling guides, we'll need a simple app, that generates some CPU load <br/>
Below steps need to follow 
* Run deployment to Kubernetes
* Ensure metrics are visible for the app

This will deploy sample application, service , ingress-resource and traffic generator pod

```
cd k8s/application
- kubectl create ns ingress-nginx
- kubectl apply -f .
- kubectl -n ingress-nginx get all 
```

I have added below resource requirement in manifest, make sure you have it

```
# resource requirements
resources:
  requests:
    memory: "50Mi"
    cpu: "500m"
  limits:
    memory: "500Mi"
    cpu: "2000m"
```

### Deploy Horizontal Pod Autoscaling

Run below command to deploy HPA

```
 - cd k8s/HPA
 - kubectl apply -f deployment-hpa.yaml
 - kubectl -n ingress-nginx get hpa spring-boot
 ## run below to check resource utilization of pods
 - kubectl -n ingress-nginx top pod
```


## Generate some traffic

Let's generate traffic using traffic-generator pod

```

# get a terminal to the traffic-generator
kubectl exec -it traffic-generator sh

# install wrk
apk add --no-cache wrk

# simulate some load
wrk -c 5 -t 5 -d 99999 -H "Connection: Close" http://spring-boot.inginx-ingress.svc.cluster.local:8080

```

I have set "targetCPUUtilizationPercentage" to 75%.<br/>
If CPU utilized more than 75% then HPA will trigger and scal our pods automatically
```
    # metrics
   - kubectl -n ingress-nginx top pods
   - kubectl -n ingress-nginx get hpa spring-boot
   - kubectl -n ingress-nginx get pod

```

## Vertical Pod Autoscaling

The vertical pod autoscaler allows us to automatically set request values on our pods <br/>
based on recommendations.
This helps us tune the request values based on actual CPU and Memory usage.<br/>

VPA docs [here]("https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#install-command") <br/>
Let's install the VPA from a container that can access our cluster

```

git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/

./hack/vpa-up.sh

# after few seconds, we can see the VPA components in:

kubectl -n kube-system get pods
```
# Deploy an example VPA

```
 - cd k8s/VPA
 - kubectl apply -f vpa.yaml
 - kubectl describe vpa spring-boot-vpa

```

Let's generate the traffic using above method

```
 - kubectl -n ingress-nginx get pod
 - kubectl -n ingress-nginx top pod
 - kubectl -n ingress-nginx describe vpa spring-boot-vpa

```
In describe vpa command you will see recommendations from VPA for CPU and RAM

updateMode is set to "Auto", VPA will adjust resource requirement in running POD using "AdmissionController".
You can set it to "off" as well.

## Cluster Autoscaler

For cluster autoscaling, you should be able to scale the pods manually and watch the cluster scale. </br>


## Deploy an autoscaler
For Cluster autoscaler use documentation provided by [AWS]("https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html")
```
cd k8s/cluster_autoscalar

## create IAM policy:

aws iam create-policy \
    --policy-name AmazonEKSClusterAutoscalerPolicy \
    --policy-document file://cluster-autoscaler-policy.json

## tag your EC2:
k8s.io/cluster-autoscaler/my-cluster    : owned
k8s.io/cluster-autoscaler/enabled       : true

## Create service account:
eksctl create iamserviceaccount \
  --cluster=task \
  --namespace=kube-system \
  --name=cluster-autoscaler \
  --attach-policy-arn=arn:aws:iam::<IAM_USER>:policy/AmazonEKSClusterAutoscalerPolicy \
  --override-existing-serviceaccounts \
  --approve

## annotated cluster:
  kubectl annotate serviceaccount cluster-autoscaler \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::<Account_ID>:role/AmazonEKSClusterAutoscalerRole

## deploy cluster-autoscaler-autodiscover
 - kubectl apply -f cluster-autoscaler-autodiscover.yaml 
##Create Auto scalar group with scaling plan

```
