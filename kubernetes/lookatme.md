Презентация
https://1drv.ms/p/s!Aq1-1swCEI99gZsEiHLiw9BjBls_kg

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
1. Миникуб
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# Старт кластера
minikube start

# Просмотр нод
kubectl get nodes

# Установка приложения

spec:
  type: NodePort 
  ports:
  - port: 9292
    protocol: TCP
    targetPort: 9292
    
## Вариант 1
kubectl apply -f [имя файла]

## Вариант 2
kubectl apply -f kubernetes/reddit/

kubectl get pods

kubectl get svc
minikube service list
minikube service ui
minikube service frontend --url


# Удаление кластера
minikube delete

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
2. kops (настройка над kubeadm)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# aws credentials

aws configure

#kops credentials
#"AccessKeyId": "AKIAWDVP7RJZOKK5VZFF"
#"SecretAccessKey": "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", 

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

export NAME=myfirstcluster.sablin.de
export KOPS_STATE_STORE=s3://prefix-sablin-de-state-store


aws s3api create-bucket \
    --bucket prefix-sablin-de-state-store \
    --region eu-west-3 \
    --create-bucket-configuration LocationConstraint=eu-west-3 

    "Location": "http://prefix-sablin-de-state-store.s3.amazonaws.com/"


# config cluster
kops create cluster \
--zones eu-west-3a \
--master-size="t2.micro" --node-size="t2.micro" \
${NAME}

# возможные ошибки
error assigning default machine type for masters
   use --master-size="t2.micro" --node-size="t2.micro" 

SSH public key must be specified when running with AWS
   ssh-keygen
   kops create secret --name myfirstcluster.sablin.de sshpublickey admin -i ~/.ssh/id_rsa.pub

# real start
kops update cluster --name myfirstcluster.sablin.de --yes

# проверка (4-5 минут)
kops validate cluster

#The dns-controller Kubernetes deployment has not updated the Kubernetes cluster's API DNS entry to the correct IP address.  The API DNS IP address is the placeholder address that kops creates: 203.0.113.123.  Please wait about 5-10 minutes for a master to start, dns-controller to launch, and DNS to propagate.  The protokube container and dns-controller deployment logs may contain more diagnostic information.  Etcd and the API DNS entries must be updated for a kops Kubernetes cluster to start.


# Установка приложения
spec:
  type: LoadBalancer 
  ports:
  - port: 80
    protocol: TCP
    targetPort: 9292

kubectl apply -f kubernetes/reddit/


# смотрим куда стучаться
kubectl get svc

# смотрим в консоли AWS состояние балансера (все ли инстансы в статусе InService)

# удаление кластера
kops delete cluster --name ${NAME} --yes


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
2. EKS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# ПОМЕНЯТЬ Креды на админа
aws configure

#kops credentials
#"AccessKeyId": "AKIAWDVP7RJZFB3SAGLO"
#"SecretAccessKey": "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", 

export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)


# запуск кластера (12-47)
eksctl create cluster \
--name otus-kuber \
--version 1.12 \
--nodegroup-name standard-workers \
--node-type t2.small \
--nodes 3 \
--nodes-min 1 \
--nodes-max 4 \
--node-ami auto

kubectl get nodes

# Установка приложения
kubectl apply -f kubernetes/reddit/

kubectl get svc

# удаление кластера
eksctl delete cluster \
--name otus-kuber
