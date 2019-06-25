# SablinIgor_microservices
SablinIgor microservices repository

# Выполнено ДЗ №12

 - [x] Основное ДЗ
 - [x] Задание со *

## В процессе сделано:
 - Настроена интеграция с Трависом
 - Изучены команды докера для работы с образами и контейнерами
 - Исследованы различия между образом и контейнером докера

# Выполнено ДЗ №13

 - [x] Основное ДЗ
 - [x] Задание со *

 ## В процессе сделано:
 - Новый проект в GCP (docker)
 - Docker machine использует проект docker для создания вируталки docker-host для работы с образами докера
 - Докер образ с установленными mongodb, ruby и тестовым приложением (reddit-app): docker-monolith/Dockerfile
 - Образ выложен на докер хаб: https://cloud.docker.com/u/soaron/repository/docker/soaron/otus-reddit


 ## В процессе сделано (*):
 - Шаблон терраформа для создания виртуалки для инсталляции приложения (кол-во инстансов регулируется переменной)
 - Плейбук для установки докера (используется роль geerlingguy.docker)
 - Плейбук для развертывания докер-образа приложения (используется модуль docker-container)
 - Шаблон пакера для создания образа с установленным докером (используется плейбук с ролью geerlingguy.docker)
 - Для работы с динамическим инвентори ансибла используется плагин gcp_compute


## Использованные источники 
 - http://matthieure.me/2018/12/31/ansible_inventory_plugin.html

# Выполнено ДЗ №14

 - [x] Основное ДЗ
 - [x] Задание со *

 ## В процессе сделано:

 - Запуск докера на удаленном хосте
 ~~~~
 export GOOGLE_PROJECT=docker-239119
 docker-machine create --driver google \
                --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
                --google-machine-type n1-standard-1 \
                --google-zone europe-west1-b \
                docker-host 
eval $(docker-machine env docker-host)
~~~~

- Тестовое приложение разделено по микросервисам
  - post-py
  - comment
  - ui

- Сборка образов
~~~~
docker build -t soaron/post:1.1 ./post-py
docker build -t soaron/comment:1.1 ./comment
docker build -t soaron/ui:1.9 ./ui
~~~~

- Оптимизация размера докер-образов. Использованы основные образы на базе alpine. Необходимые пакеты доустановлены при помощи менеджера пакетов apk.

- Тестовое приложение запущено на удаленном хосте
~~~~
docker network create reddit

docker run -d --network=reddit --network-alias=my_post_db \
--network-alias=my_comment_db -v reddit_db:/data/db mongo:latest

docker run -d --network=reddit \
--network-alias=my_post -e POST_DATABASE_HOST=my_post_db soaron/post:1.1

docker run -d --network=reddit \
--network-alias=my_comment -e COMMENT_DATABASE_HOST=my_comment_db soaron/comment:1.1

docker run -d --network=reddit \
-p 9292:9292 -e POST_SERVICE_HOST=my_post -e COMMENT_SERVICE_HOST=my_comment soaron/ui:1.9
~~~~

- Сетевые алиасы передаются микросервисам при запуске контейнеров с помощью параметра  -e

- Для хранения данных (патерн Statefull) используется механизм томов докера
~~~~
docker volume create reddit_db
~~~~

## Использованные источники 
 Ошибка с "OSError: [Errno 8] Exec format error": https://github.com/pallets/werkzeug/issues/1482

# Выполнено ДЗ №15

 - [x] Основное ДЗ
 - [] Задание со *

 ## В процессе сделано:

- Исследован запуск контейнеров в различных типах сетей

- При запуске одного контейнера несколько раз в режиме хост, в работоспособном состоянии остается только первый запущенный контейнер
~~~~
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
49ca11dba3fb        nginx               "nginx -g 'daemon of…"   17 seconds ago      Up 13 seconds                           laughing_beaver
~~~~

- Остальные контейнеры завершаются с ошибкой, так как необходимый адрес/порт уже занят
~~~~
 2019/05/15 16:58:02 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
~~~~

- Default naming rule
~~~~
The default naming scheme for containers created by Compose in this version has changed from <project>_<service>_<index> to <project>_<service>_<index>_<slug>, where <slug> is a randomly-generated hexadecimal string.
~~~~

- При необходимости можно самостоятельно определить имя для контейнера
~~~~
  ui:
    build: ./ui
    container_name: my-ui-container
~~~~

## Использованные источники 

https://docs.docker.com/compose/extends/

# Выполнено ДЗ №16

 - [x] Основное ДЗ
 - [x] Задание со *
 
 ## В процессе сделано:

 - Установлен Gitlab CE из докер-образа
 - Установлен gitlab-runner из докер-образа
 - Настроена интеграция Gitlab и Slack (https://devops-team-otus.slack.com/messages/CH08W3XRT)
 - Проект тестового приложения залит на Gitlab
 ~~~~
 > git checkout -b gitlab-ci-1
 > git remote add gitlab http://<your-vm-ip>/homework/example.git
 > git push gitlab gitlab-ci-1
 ~~~~
 - Настроен пайплан в файле .gitlab-ci.yml 
 - Для запуска шагов Stage и Production указано требование к наличию тэга:
     ~~~~
     only:
       - /^\d+\.\d+\.\d+/
     ~~~~
 - Настроено поднятие динамического окружения для шага review
   - При сборке образ приложения помечается тэгом равным коммиту
   - Образ заливается на DockerHub
   - Для окружения формируется доменное имя вида: 
     ~~~~
     url: http://$CI_COMMIT_SHORT_SHA.sablin.de
     ~~~~
   - Дальшейнее создания окружения происходит на сервисах AWS (script.sh)
     - Создается target group
     - Поднимается Load balancer
     - Для Load balancer добавляется listener для обращения по порту 80
     - В Task definition указывается тэг образа тестового приложения
     - В Cluster создается Service для запуска приложения из образа
     - В Route53 (DNS records) создается Record set для связи доменного имени окружения с Load Balanсer DNS name

   - При остановке окружения происходит обратный процесс (stop.sh)
     - Удаляется запись Resord set в Route53
     - Удаляется Load balancer
     - Удаляется Target group
     - Удаляется Service

   - Создание необходимого числа Gitlab runners реализовано при помощи терраформа: /gitlab-ci/terraform/

# Выполнено ДЗ №17

 - [x] Основное ДЗ
 - [] Задание со *
 
 ## В процессе сделано:

 - Рефактор каталого проекта - сборка образов отделена от docker-compose
 - Дополнительно к контейнерам приложения запускается контейнер с Прометеусом для отслеживания метрик приложения
   ~~~~
    prometheus:
      image: ${USERNAME}/prometheus
      ports:
        - '9090:9090'
      volumes:
        - prometheus_data:/prometheus
      command:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--storage.tsdb.retention=1d'
      volumes:
        prometheus_data: 
   ~~~~
 - Добавлен node-exporter для отслеживания метрик самого хоста
    ~~~~
     node-exporter:
       image: prom/node-exporter:v0.15.2
       user: root
       volumes:
         - /proc:/host/proc:ro
         - /sys:/host/sys:ro
         - /:/rootfs:ro
       command:
         - '--path.procfs=/host/proc'
         - '--path.sysfs=/host/sys'
         - '--collector.filesystem.ignored-mount-points="^/(sys|proc|dev|host|etc)($$|/)"' 
    ~~~~ 
  - Созданные образы выгружены на DockerHub
    - https://cloud.docker.com/u/soaron/repository/docker/soaron/prometheus
    - https://cloud.docker.com/u/soaron/repository/docker/soaron/post
    - https://cloud.docker.com/u/soaron/repository/docker/soaron/comment
    - https://cloud.docker.com/u/soaron/repository/docker/soaron/ui
    
# Выполнено ДЗ №18

 - [x] Основное ДЗ
 - [] Задание со *
 
 ## В процессе сделано:

 - Настроены dashboards для Grafana
   - Бизнес-метрики: monitoring/grafana/dashboards/Business_Logic_Monitoring.json
   - Мониторинг докера: monitoring/grafana/dashboards/DockerMonitoring.json
   - Мониторинг микросервисов: monitoring/grafana/dashboards/UI_Service_Monitoring.json  

 - Настроен алертинг-сервис - уведомления уходят в канал Slack

 - Список образов на DockerHub
   - soaron/alertmanager:latest
   - soaron/prometheus:latest
   - soaron/comment:logging
   - soaron/post:logging
   - soaron/ui:logging

# Выполнено ДЗ №19

 - [x] Основное ДЗ
 - [] Задание со *

 ## В процессе сделано:

- Сборка образов приложения
  ~~~~
  for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
  ~~~~

- Поднят elasticsearch
- Поднята kibana
- Преобразование неструктурированных логов осуществляется при помощи Fluentd
- Для распределенного трейсинга используется Zipkin

# Выполнено ДЗ №20

 - [x] Основное ДЗ
 - [] Задание со *

## В процессе сделано:

- Подготовлены манифест-файлы для запуска тестового приложения: /Users/admin/SablinIgor_microservices/kubernetes/reddit
  
  Деплой в миникуб показал работоспособность приложения (посты создаются, комменты тоже)

  ~~~~
  minikube start
  kubectl apply -f mongo-deployment.yml
  kubectl apply -f mongo-service.yaml
  kubectl apply -f post-deployment.yml
  kubectl apply -f post-service.yaml
  kubectl apply -f comment-deployment.yml
  kubectl apply -f comment-service.yaml
  kubectl apply -f ui-deployment.yml
  kubectl apply -f ui-service.yaml
  minikube service ui --url
  ~~~~

- Настройка кубернетес по мануалу https://github.com/kelseyhightower/kubernetes-the-hard-way (OSX)
- Prerequisites
  - gcloud config set compute/region europe-west1
- Installing the Client Tools
  - brew install cfssl
  - curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/darwin/amd64/kubectl
  - chmod +x kubectl
  - sudo mv kubectl /usr/local/bin/
- Provisioning Compute Resources
  - gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
  - gcloud compute networks subnets create kubernetes --network kubernetes-the-hard-way --range 10.240.0.0/24
  - gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal --allow tcp,udp,icmp --network kubernetes-the-hard-way --source-ranges 10.240.0.0/24,10.200.0.0/16
  - gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external --allow tcp:22,tcp:6443,icmp --network kubernetes-the-hard-way --source-ranges 0.0.0.0/0
  - gcloud compute addresses create kubernetes-the-hard-way --region $(gcloud config get-value compute/region)
  - Create three compute instances for control plane
    ~~~~ 
    for i in 0 1 2; do
      gcloud compute instances create controller-${i} \
        --async \
        --boot-disk-size 200GB \
        --can-ip-forward \
        --image-family ubuntu-1804-lts \
        --image-project ubuntu-os-cloud \
        --machine-type n1-standard-1 \
        --private-network-ip 10.240.0.1${i} \
        --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
        --subnet kubernetes \
        --tags kubernetes-the-hard-way,controller
    done
    ~~~~ 
  - Create three compute instances for worker nodes 
    ~~~~ 
    for i in 0 1 2; do
      gcloud compute instances create worker-${i} \
        --async \
        --boot-disk-size 200GB \
        --can-ip-forward \
        --image-family ubuntu-1804-lts \
        --image-project ubuntu-os-cloud \
        --machine-type n1-standard-1 \
        --metadata pod-cidr=10.200.${i}.0/24 \
        --private-network-ip 10.240.0.2${i} \
        --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
        --subnet kubernetes \
        --tags kubernetes-the-hard-way,worker
    done
    ~~~~ 
  - gcloud compute ssh ubuntu@controller-0 (test connection, use !!!existing!!! name)
  - **Provisioning a CA and Generating TLS Certificates**
    - Certificate Authority
    ~~~~ 
    {

    cat > ca-config.json <<EOF
    {
      "signing": {
        "default": {
          "expiry": "8760h"
        },
        "profiles": {
          "kubernetes": {
            "usages": ["signing", "key encipherment", "server auth", "client auth"],
            "expiry": "8760h"
          }
        }
      }
    }
    EOF

    cat > ca-csr.json <<EOF
    {
      "CN": "Kubernetes",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "US",
          "L": "Portland",
          "O": "Kubernetes",
          "OU": "CA",
          "ST": "Oregon"
        }
      ]
    }
    EOF

    cfssl gencert -initca ca-csr.json | cfssljson -bare ca

    }
    ~~~~ 

  - Client and Server Certificates
    ~~~~ 
    {

    cat > admin-csr.json <<EOF
    {
      "CN": "admin",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "US",
          "L": "Portland",
          "O": "system:masters",
          "OU": "Kubernetes The Hard Way",
          "ST": "Oregon"
        }
      ]
    }
    EOF

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      admin-csr.json | cfssljson -bare admin

    }
    ~~~~ 

  - The Kubelet Client Certificates
    ~~~~
    for instance in worker-0 worker-1 worker-2; do
    cat > ${instance}-csr.json <<EOF
    {
      "CN": "system:node:${instance}",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "US",
          "L": "Portland",
          "O": "system:nodes",
          "OU": "Kubernetes The Hard Way",
          "ST": "Oregon"
        }
      ]
    }
    EOF

    EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
      --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

    INTERNAL_IP=$(gcloud compute instances describe ${instance} \
      --format 'value(networkInterfaces[0].networkIP)')

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
      -profile=kubernetes \
      ${instance}-csr.json | cfssljson -bare ${instance}
    done
    ~~~~  

  - The Controller Manager Client Certificate
    ~~~~  
    {

    cat > kube-controller-manager-csr.json <<EOF
    {
      "CN": "system:kube-controller-manager",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "US",
          "L": "Portland",
          "O": "system:kube-controller-manager",
          "OU": "Kubernetes The Hard Way",
          "ST": "Oregon"
        }
      ]
    }
    EOF

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

    }
    ~~~~  

    - The Kube Proxy Client Certificate
    ~~~~  
    {

    cat > kube-proxy-csr.json <<EOF
    {
      "CN": "system:kube-proxy",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "US",
          "L": "Portland",
          "O": "system:node-proxier",
          "OU": "Kubernetes The Hard Way",
          "ST": "Oregon"
        }
      ]
    }
    EOF

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      kube-proxy-csr.json | cfssljson -bare kube-proxy

    }
    ~~~~  

  - The Scheduler Client Certificate
    ~~~~
    {

    cat > kube-scheduler-csr.json <<EOF
    {
      "CN": "system:kube-scheduler",
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "US",
          "L": "Portland",
          "O": "system:kube-scheduler",
          "OU": "Kubernetes The Hard Way",
          "ST": "Oregon"
        }
      ]
    }
    EOF

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -profile=kubernetes \
      kube-scheduler-csr.json | cfssljson -bare kube-scheduler

    }
    ~~~~

  - The Kubernetes API Server Certificate
  ~~~~
  {

  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  cat > kubernetes-csr.json <<EOF
  {
    "CN": "kubernetes",
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "US",
        "L": "Portland",
        "O": "Kubernetes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
      }
    ]
  }
  EOF

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes

  }
  ~~~~

- The Service Account Key Pair
  ~~~~
  {

  cat > service-account-csr.json <<EOF
  {
    "CN": "service-accounts",
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names": [
      {
        "C": "US",
        "L": "Portland",
        "O": "Kubernetes",
        "OU": "Kubernetes The Hard Way",
        "ST": "Oregon"
      }
    ]
  }
  EOF

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    service-account-csr.json | cfssljson -bare service-account

  }
  ~~~~

- Distribute the Client and Server Certificates
  ~~~~
  for instance in worker-0 worker-1 worker-2; do
    gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ubuntu@${instance}:~/
  done
  ~~~~

  ~~~~
  for instance in controller-0 controller-1 controller-2; do
    gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ubuntu@${instance}:~/
  done
  ~~~~

- **Generating Kubernetes Configuration Files for Authentication**
- KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way --region $(gcloud config get-value compute/region) --format 'value(address)')
- The kubelet Kubernetes Configuration File
  ~~~~
  for instance in worker-0 worker-1 worker-2; do
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-credentials system:node:${instance} \
      --client-certificate=${instance}.pem \
      --client-key=${instance}-key.pem \
      --embed-certs=true \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:node:${instance} \
      --kubeconfig=${instance}.kubeconfig

    kubectl config use-context default --kubeconfig=${instance}.kubeconfig
  done
  ~~~~

- The kube-proxy Kubernetes Configuration File
  ~~~~
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-credentials system:kube-proxy \
      --client-certificate=kube-proxy.pem \
      --client-key=kube-proxy-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:kube-proxy \
      --kubeconfig=kube-proxy.kubeconfig

    kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
  }
  ~~~~

- The kube-controller-manager Kubernetes Configuration File
  ~~~~
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-credentials system:kube-controller-manager \
      --client-certificate=kube-controller-manager.pem \
      --client-key=kube-controller-manager-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:kube-controller-manager \
      --kubeconfig=kube-controller-manager.kubeconfig

    kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
  }
  ~~~~

- The kube-scheduler Kubernetes Configuration File
  ~~~~
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-credentials system:kube-scheduler \
      --client-certificate=kube-scheduler.pem \
      --client-key=kube-scheduler-key.pem \
      --embed-certs=true \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:kube-scheduler \
      --kubeconfig=kube-scheduler.kubeconfig

    kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
  }
  ~~~~

- The admin Kubernetes Configuration File
  ~~~~
  {
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://127.0.0.1:6443 \
      --kubeconfig=admin.kubeconfig

    kubectl config set-credentials admin \
      --client-certificate=admin.pem \
      --client-key=admin-key.pem \
      --embed-certs=true \
      --kubeconfig=admin.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=admin \
      --kubeconfig=admin.kubeconfig

    kubectl config use-context default --kubeconfig=admin.kubeconfig
  }
  ~~~~

- Distribute the Kubernetes Configuration Files
  ~~~~
  for instance in worker-0 worker-1 worker-2; do
    gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ubuntu@${instance}:~/
  done
  ~~~~

  ~~~~
  for instance in controller-0 controller-1 controller-2; do
    gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ubuntu@${instance}:~/
  done
  ~~~~

- **Generating the Data Encryption Config and Key**

- ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

- The Encryption Config File
  ~~~~
  cat > encryption-config.yaml <<EOF
  kind: EncryptionConfig
  apiVersion: v1
  resources:
    - resources:
        - secrets
      providers:
        - aescbc:
            keys:
              - name: key1
                secret: ${ENCRYPTION_KEY}
        - identity: {}
  EOF
  ~~~~

  ~~~~
  for instance in controller-0 controller-1 controller-2; do
    gcloud compute scp encryption-config.yaml ubuntu@${instance}:~/
  done
  ~~~~

- **Bootstrapping the etcd Cluster** (via ssh on controllers)

- Bootstrapping an etcd Cluster Member
  ~~~~
  wget -q --show-progress --https-only --timestamping \
    "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"
  ~~~~

  ~~~~
  {
    tar -xvf etcd-v3.3.9-linux-amd64.tar.gz
    sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/
  }
  ~~~~

  ~~~~
  {
    sudo mkdir -p /etc/etcd /var/lib/etcd
    sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
  }
  ~~~~

  ~~~~
  INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
  ~~~~

  ~~~~
  ETCD_NAME=$(hostname -s)
  ~~~~

  ~~~~
  cat <<EOF | sudo tee /etc/systemd/system/etcd.service
  [Unit]
  Description=etcd
  Documentation=https://github.com/coreos

  [Service]
  ExecStart=/usr/local/bin/etcd \\
    --name ${ETCD_NAME} \\
    --cert-file=/etc/etcd/kubernetes.pem \\
    --key-file=/etc/etcd/kubernetes-key.pem \\
    --peer-cert-file=/etc/etcd/kubernetes.pem \\
    --peer-key-file=/etc/etcd/kubernetes-key.pem \\
    --trusted-ca-file=/etc/etcd/ca.pem \\
    --peer-trusted-ca-file=/etc/etcd/ca.pem \\
    --peer-client-cert-auth \\
    --client-cert-auth \\
    --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
    --listen-peer-urls https://${INTERNAL_IP}:2380 \\
    --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
    --advertise-client-urls https://${INTERNAL_IP}:2379 \\
    --initial-cluster-token etcd-cluster-0 \\
    --initial-cluster controller-0=https://10.240.0.10:2380,controller-1=https://10.240.0.11:2380,controller-2=https://10.240.0.12:2380 \\
    --initial-cluster-state new \\
    --data-dir=/var/lib/etcd
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
  ~~~~

  ~~~~
  {
    sudo systemctl daemon-reload
    sudo systemctl enable etcd
    sudo systemctl start etcd
  }
  ~~~~

- **Bootstrapping the Kubernetes Control Plane**

- sudo mkdir -p /etc/kubernetes/config

  ~~~~
  wget -q --show-progress --https-only --timestamping \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler" \
    "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl"
  ~~~~

  {
    chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
    sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
  }

  {
    sudo mkdir -p /var/lib/kubernetes/

    sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
      service-account-key.pem service-account.pem \
      encryption-config.yaml /var/lib/kubernetes/
  }

  INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

  cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
  [Unit]
  Description=Kubernetes API Server
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-apiserver \\
    --advertise-address=${INTERNAL_IP} \\
    --allow-privileged=true \\
    --apiserver-count=3 \\
    --audit-log-maxage=30 \\
    --audit-log-maxbackup=3 \\
    --audit-log-maxsize=100 \\
    --audit-log-path=/var/log/audit.log \\
    --authorization-mode=Node,RBAC \\
    --bind-address=0.0.0.0 \\
    --client-ca-file=/var/lib/kubernetes/ca.pem \\
    --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
    --enable-swagger-ui=true \\
    --etcd-cafile=/var/lib/kubernetes/ca.pem \\
    --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
    --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
    --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
    --event-ttl=1h \\
    --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
    --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
    --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
    --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
    --kubelet-https=true \\
    --runtime-config=api/all \\
    --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
    --service-cluster-ip-range=10.32.0.0/24 \\
    --service-node-port-range=30000-32767 \\
    --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
    --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF

  sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

  cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
  [Unit]
  Description=Kubernetes Controller Manager
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-controller-manager \\
    --address=0.0.0.0 \\
    --cluster-cidr=10.200.0.0/16 \\
    --cluster-name=kubernetes \\
    --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
    --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
    --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
    --leader-elect=true \\
    --root-ca-file=/var/lib/kubernetes/ca.pem \\
    --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
    --service-cluster-ip-range=10.32.0.0/24 \\
    --use-service-account-credentials=true \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF

  sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/

  cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
  apiVersion: componentconfig/v1alpha1
  kind: KubeSchedulerConfiguration
  clientConnection:
    kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
  leaderElection:
    leaderElect: true
  EOF

  cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
  [Unit]
  Description=Kubernetes Scheduler
  Documentation=https://github.com/kubernetes/kubernetes

  [Service]
  ExecStart=/usr/local/bin/kube-scheduler \\
    --config=/etc/kubernetes/config/kube-scheduler.yaml \\
    --v=2
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
EOF

... а дальше я заебался конспектировать...


# Выполнено ДЗ №21

 - [x] Основное ДЗ
 - [] Задание со *
 
## В процессе сделано:
  - В дополнение к предыдущему ДЗ, где уже были созданы манифесты для деплоя работоспособного приложения (с преферансом и сервисами) поднят кластер кубернетеса в GKE. Адрес приложения: http://34.77.124.212:31247/

# Выполнено ДЗ №22

 - [x] Основное ДЗ
 - [x] Задание со *
 
## В процессе сделано:
 - развернут кластер AWS EKS
 - настроен ингресс-контроллер
   ~~~~
   kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.0.0/docs/examples/rbac-role.yaml
   curl -sS "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.0.0/docs/examples/alb-ingress-controller.yaml" > alb-ingress-controller.yaml
   kubectl apply -f alb-ingress-controller.yaml
   ~~~~
 - трафик перенаправляется на https
 - для проверки ssl используется сертификат в хранилище ACM
 - (*) так как использовалось хранилище сертификатов (честно подписанным), то секрет в кластер не передавался, но если бы было нужно, то можно поступить так (перекодировать тело и ключ сертификата в base26):
  ~~~~
  apiVersion: v1
  data:
    tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURKakNDQWc2Z0F3SUJBZ0lKQUw2Y3R2bk9zMzlUTUEwR0NTcUdTSWIzRFFFQkJRVUFNQll4RkRBU0JnTlYKQkFNVEMyWnZieTVpWVhJdVkyOXRNQjRYRFRFNE1USXhOREUxTWpJeU1Gb1hEVEU1TVRJeE5ERTFNakl5TUZvdwpGakVVTUJJR0ExVUVBeE1MWm05dkxtSmhjaTVqYjIwd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3CmdnRUtBb0lCQVFDbWVsQTNqVy9NZ2REejJNazMwbXZ4K2VOSHJkQlIwMEJ4ZUR1VjBjYWVFUGNFa2RmSnk5V28KaTFpSXV1V04vZGV6UEhyTWMxenBPNGtzbWU5NThRZVFCWjNmVThWeGpRYktmb1JzNnhQUlNKZVVSckVCcWE4SQpUSXpEVVdaUTAwQ2xsa1dOejE4dDYvVjJycWxJd1VvaTVZWHloOVJsaWR4MjZRaXJBcFFFaXZDY2QzdUExc3AwCkUxRXdIVGxVdzFqSE9Eb3BLZGxaRndmcWhFSHNmYjZvLzJFb1A1MXMwY2JuTld6MHNsUjhhejdzOExVYnhBWnkKQkNQdDY1Z2VhT3hYWWUxaWhLYzN4SE4wYSsxMXpBYUdDMnpTemdOcEVWeFFJQ3lZdVZld3dNb0FrcHNkdGEybwpnMnFTaDZQZzRHeFFabzRwejIwN0c2SkFUaFIyNENiTEFnTUJBQUdqZHpCMU1CMEdBMVVkRGdRV0JCU3NBcUZoCkpPS0xZaXNHTkNVRGU4N1VWRkp0UERCR0JnTlZIU01FUHpBOWdCU3NBcUZoSk9LTFlpc0dOQ1VEZTg3VVZGSnQKUEtFYXBCZ3dGakVVTUJJR0ExVUVBeE1MWm05dkxtSmhjaTVqYjIyQ0NRQytuTGI1enJOL1V6QU1CZ05WSFJNRQpCVEFEQVFIL01BMEdDU3FHU0liM0RRRUJCUVVBQTRJQkFRQU1wcDRLSEtPM2k1NzR3dzZ3eU1pTExHanpKYXI4Cm8xbHBBa3BJR3FMOHVnQWg5d2ZNQWhsYnhJcWZJRHlqNWQ3QlZIQlc1UHZweHpKV3pWbmhPOXMrdzdWRTlNVHUKWlJHSXVRMjdEeExueS9DVjVQdmJUSTBrcjcwYU9FcGlvTWYyUVUvaTBiN1B2ajJoeEJEMVZTVkd0bHFTSVpqUAo0VXZQYk1yTWZUWmJka1pIbG1SUjJmbW4zK3NTVndrZTRhWXlENVVHNnpBVitjd3BBbkZWS25VR0d3TkpVMjA4CmQrd3J2UUZ5bi9kcVBKTEdlNTkvODY4WjFCcFIxRmJYMitUVW4yWTExZ0dkL0J4VmlzeGJ0b29GQkhlVDFLbnIKTTZCVUhEeFNvWVF0VnJWSDRJMWh5UGRkdmhPczgwQkQ2K01Dd203OXE2UExaclVKOURGbFl2VTAKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBcG5wUU40MXZ6SUhRODlqSk45SnI4Zm5qUjYzUVVkTkFjWGc3bGRIR25oRDNCSkhYCnljdlZxSXRZaUxybGpmM1hzeng2ekhOYzZUdUpMSm52ZWZFSGtBV2QzMVBGY1kwR3luNkViT3NUMFVpWGxFYXgKQWFtdkNFeU13MUZtVU5OQXBaWkZqYzlmTGV2MWRxNnBTTUZLSXVXRjhvZlVaWW5jZHVrSXF3S1VCSXJ3bkhkNwpnTmJLZEJOUk1CMDVWTU5ZeHpnNktTblpXUmNINm9SQjdIMitxUDloS0QrZGJOSEc1elZzOUxKVWZHcys3UEMxCkc4UUdjZ1FqN2V1WUhtanNWMkh0WW9Tbk44UnpkR3Z0ZGN3R2hndHMwczREYVJGY1VDQXNtTGxYc01ES0FKS2IKSGJXdHFJTnFrb2VqNE9Cc1VHYU9LYzl0T3h1aVFFNFVkdUFteXdJREFRQUJBb0lCQUMvSitzOEhwZWxCOXJhWgpLNkgvb0ljVTRiNkkwYjA3ZEV0ZVpWUnJwS1ZwWDArTGdqTm1kUTN0K2xzOXMzbmdQWlF4TDFzVFhyK0JISzZWCi9kMjJhQ0pheW1mNmh6cENib21nYWVsT1RpRU13cDZJOEhUMnZjMFhGRzFaSjVMYUlidW0rSTV0MGZlL3ZYWDEKUzVrY0Mya2JGQ2w3L21lcmZJTVNBQy8vREhpRTUyV1QydEIrQk01U2FMV3p4cDhFa3NwNkxWN3ZwYmR4dGtrTwpkZ1A4QjkwWlByck5SdUN5ekRwRUkvMnhBY24yVzNidlBqRGpoTjBXdlhTbTErVk9DcXNqOEkrRkxoUzZJemVuCm1MUkFZNnpWVGpZV05TU2J3dTRkbnNmNElIOEdiQkZJajcrdlN5YVNVTEZiVGJzY3ZzQ3I1MUszbWt2bEVMVjgKaWsvMlJoa0NnWUVBMFpmV2xUTjR2alh2T0FjU1RUU3MwMFhIRWh6QXFjOFpUTEw2S1d4YkxQVFJNaXBEYklEbQp6b3BiMGNTemxlTCtNMVJCY3dqMk5HcUNodXcyczBaNTQyQVhSZXdteG1EcWJaWkFQY0UzbERQNW5wNGRpTFRCClZaMFY4UExSYjMrd2tUdE83VThJZlY1alNNdmRDTWtnekI4dU1yQ1VMYnhxMXlVUGtLdGpJdThDZ1lFQXkxYWMKWjEyZC9HWWFpQjJDcWpuN0NXZE5YdGhFS2dOYUFob21nNlFMZmlKakVLajk3SExKalFabFZ0b3kra1RrdTJjZAp0Wm1zUi9IU042YmZLbEpxckpUWWkzY2E1TGY4a3NxR0Z5Y0x1MXo3cmN6K1lUaEVWSFIyOVkrVHVWYXRDTnkzCklCOGNUQW1ORWlVMlVHR2VKeUllME44Z1VZRXRCYzFaMEg2QWllVUNnWUFETDIrUGJPelUxelQvZ1B3Q09GNjQKQjBOelB3U2VrQXN1WXpueUR6ZURnMlQ2Z2pIc0lEbGh3akNMQzVZL0hPZ0lGNnUyOTlmbURBaFh6SmM0T2tYMwo4cW5uNGlMa3VPeFhKZ1ZyNnRmUlpNalNaRXpHbXhpbEdISVE2MS9MZGdGVTg3WExYWHdmaTZPdW80cUVhNm9YCjhCRmZxOWRVcXB4bEVLY2Y1N3JsK1FLQmdGbjVSaFc2NS9oU0diVlhFWVZQU0pSOW9FK3lkRjcrd3FvaGRoOVQKekQ0UTZ6THBCQXJITkFYeDZZK0gxM3pFVlUzVEwrTTJUM1E2UGFHZ2Rpa2M5TlRPdkE3aU1nVTRvRXMzMENPWQpoR2x3bUhEc1B6YzNsWXlsU0NvYVVPeDJ2UFFwN2VJSndoU25PVVBwTVdKWi80Z2pZZTFjZmNseTFrQTJBR0x3ClJ1STlBb0dCQU14aGFJSUdwTGdmcHk0K24rai9BSWhJUUhLZFRCNVBqaGx0WWhqZittK011UURwK21OeTVMbzEKT0FRc0Q0enZ1b3VxeHlmQlFQZlllYThvcm4vTDE3WlJyc3lSNHlhS1M3cDVQYmJKQlNlcTc5Z0g5ZUNIQkxMbQo0aThCUFh0K0NmWktMQzg3NTNHSHVpOG91V25scUZ0NGxMQUlWaGJZQmtUbURZSWo4Q0NaCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
  kind: Secret
  metadata:
    name: test-tls
    namespace: default
  type: kubernetes.io/tls
  ~~~~
- для разграничения сетевых потоков применен Calico policy engine
  ~~~~
  kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.4/calico.yaml
  ~~~~
- для хранения данных использованы технологии
  - emptyDir
  - gcePersistentDisk
  - PersistentVolume
  - StorageClass Fast 

## Использованные источники 
  - https://aws.amazon.com/ru/blogs/opensource/kubernetes-ingress-aws-alb-ingress-controller/
  - https://kubernetes-sigs.github.io/aws-alb-ingress-controller/guide/tasks/ssl_redirect/

# Выполнено ДЗ №23

 - [x] Основное ДЗ
 - [] Задание со *

 ## В процессе сделано:
  - установлен helm
  - созданы charts для сервисов приложения
  - для mongodb используется chart из центрального репозитория
  - в chatrs используются шаблоны (templates)
  - в шаблонах используются функции helpers
  - подготовлен единый chart приложения с зависимостями на charts сервисов и базы
  - рассмотрен пайплайн установки приложения через hellm на gitlab-е

 ## Использованные источники 
  - https://www.bible.com/ru/bible/400/GEN.1.SYNO
  - https://kubernetes.io/docs/tasks/debug-application-cluster/debug-service/
  - https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/#known-issues
  - https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#getting-a-shell-to-a-container

# Выполнено ДЗ №24

 - [x] Основное ДЗ
 - [] Задание со *

 ## В процессе сделано:
  - снова поднят кластер
  - установлен тиллер 
    - kubectl apply -f tiller.yml
    - helm init --service-account tiller
  - установлен ингресс
    - helm install stable/nginx-ingress --name nginx
  - установка прометеуса
    - helm fetch --untar stable/prometheus
    - helm upgrade prom . -f custom_values.yml --install
  - устоновка приложения
    - helm install reddit --name reddit-test
    - helm install reddit --name production  --namespace production
    - helm install reddit --name staging  --namespace staging
  - блоки endpoint-ов разделены на три части: test, staging и production
  - установка grafana
  
  35.205.141.242 reddit reddit-prometheus reddit-grafana reddit-non-prod production reddit-kibana staging prod
