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

