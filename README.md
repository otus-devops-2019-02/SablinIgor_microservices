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
