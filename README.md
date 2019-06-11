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
