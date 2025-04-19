- [Описание проекта FireFighterRL](README.md)
- [Описание архитектуры проекта FireFighter](infrastructure.md)
- [Руководство по системе резервного копирования](backupinstallguide.md)


# Руководство по развертыванию FireFighter ML-инфраструктуры


## Рекомендуемые требования к системе

- Ubuntu 22.04 Server
- AMD Ryzen Threadripper PRO 3995WX (64 ядра)
- 64-128 ГБ оперативной памяти
- 1-1,5 ТБ дискового пространства
- NVIDIA RTX 4090
- Сетевое подключение 10 Гбит/с

## Обзор компонентов системы

FireFighter состоит из следующих основных компонентов:

1. **JupyterHub**: среда разработки с поддержкой GPU
2. **MongoDB**: база данных для хранения метрик и результатов экспериментов
3. **Система мониторинга**: Prometheus, Grafana, экспортеры
4. **Система резервного копирования**: локальные и удаленные бэкапы

## Структура проекта

```
FireFighterRL/
├── backup/                   # Система резервного копирования
│   ├── backup-script.sh      # Скрипт создания резервных копий
│   └── restore-script.sh     # Скрипт восстановления из резервных копий
│
│
├── Jupiter/                  # Компонент JupyterHub
│   ├── docker-compose.yaml   # Конфигурация Docker Compose для JupyterHub
│   ├── Dockerfile            # Образ JupyterHub
│   ├── Dockerfile.notebook   # Образ Jupyter Notebook с ML-библиотеками
│   ├── jupyterhub_config.py  # Конфигурационный файл JupyterHub
│   ├── requirements.notebook.txt  # Зависимости для образа Notebook
│   └── requirements.txt      # Зависимости для образа JupyterHub
│
├── Mongo/                    # Компонент MongoDB
│   ├── docker-compose.yml    # Конфигурация Docker Compose для MongoDB
│   └── database              # База с сохраненными результатами экспериментов
│
├── Monitoring/               # Компонент мониторинга
│   ├── configs/              # Конфигурационные файлы для системы мониторинга
│   │   ├── alertmanager.yml  # Конфигурация AlertManager
│   │   ├── alert.rules.yml   # Правила оповещений Prometheus
│   │   ├── Dockerfile.exporter  # Образ для кастомных экспортеров
│   │   ├── gpu_monitor.sh    # Скрипт мониторинга GPU
│   │   ├── grafana/          # Конфигурация Grafana
│   │   │   └── provisioning/
│   │   │       ├── dashboards/  # Предустановленные дашборды
│   │   │       │   ├── GPU Monitoring.json
│   │   │       │   ├── JupyterHub users stat.json
│   │   │       │   ├── MongoDB.json
│   │   │       │   ├── Server Metrics.json
│   │   │       │   └── Server load by users.json
│   │   │       └── datasources/  # Источники данных
│   │   ├── grafana.ini       # Основная конфигурация Grafana
│   │   ├── loki.yaml         # Конфигурация Loki для сбора логов
│   │   ├── notebook_exporter.py  # Скрипт экспорта метрик JupyterHub
│   │   ├── prometheus.yml    # Конфигурация Prometheus
│   │   └── promtail.yaml     # Конфигурация Promtail для отправки логов
│   ├── docker-compose.yml    # Конфигурация Docker Compose для мониторинга
│   └── metrics/              # Директория для хранения метрик
│       └── gpu.prom          # Файл с метриками GPU
│
│
└── screenshots/              # Скриншоты для документации
```

## Подготовка сервера

### 1. Установка Docker и Docker Compose

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common git

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo apt install -y docker-compose-plugin
```

### 2. Установка драйверов NVIDIA

> **Примечание**: На целевом сервере уже установлены драйверы NVIDIA версии 560.35.03 с CUDA 12.6 для RTX 4090. Если драйверы уже установлены, этот шаг можно пропустить.

```bash
# Проверка наличия драйверов
nvidia-smi

# Если не установлены, выполните:
sudo apt install -y nvidia-driver-560  # Используйте версию 560 или новее

# Установка NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Настройка Docker для работы с NVIDIA
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Клонирование репозитория

```bash
# Клонирование репозитория с указанием нужной ветки
git clone -b architecture_project41 https://github.com/FireTech-team41/FireFighterRL.git

# Переход в директорию проекта
cd FireFighterRL
```

## Настройка конфигурационных файлов

Перед развертыванием необходимо заменить placeholder-значения и настроить IP-адреса в конфигурационных файлах:

### 1. JupyterHub (Jupiter/jupyterhub_config.py)

```bash
# Отредактируйте файл конфигурации
nano Jupiter/jupyterhub_config.py

# Замените следующие значения:
# c.JupyterHub.public_url = 'IP_сервера : ПОРТ' -> фактический IP и порт (например, '192.168.1.10 : 8080')
```

### 2. Docker Compose для JupyterHub

```bash
# Отредактируйте файл docker-compose
nano Jupiter/docker-compose.yaml

# Замените заглушки на фактические значения:
# - "внешний_ПОРТ:8000" -> укажите фактический внешний порт (например, "8080:8000")
```

### 3. Grafana (Monitoring/configs/grafana.ini)

```bash
# Отредактируйте файл конфигурации
nano Monitoring/configs/grafana.ini

# Замените email-настройки:
# host = smtp.почтовый_сервис:465 -> smtp-сервер (например, smtp.gmail.com:465)
# user = email -> email для уведомлений
# password = пароль_email -> пароль
# from_address = email -> адрес отправки
```

### 4. AlertManager (Monitoring/configs/alertmanager.yml)

```bash
# Отредактируйте файл конфигурации
nano Monitoring/configs/alertmanager.yml

# Замените настройки SMTP:
# smtp_smarthost: 'smtp.почтовый_сервис:465' -> фактический SMTP-сервер
# smtp_from: 'email' -> адрес отправителя
# smtp_auth_username: 'email' -> логин почты
# smtp_auth_password: 'пароль_email' -> пароль
# to: 'email' -> адрес получателя уведомлений
```

### 5. Monitoring Docker Compose

```bash
# Отредактируйте файл docker-compose
nano Monitoring/docker-compose.yml

# Замените заглушки на фактические значения:
# - внешний_ПОРТ:9090 -> для Prometheus (например, "9090:9090")
# - "внешний_ПОРТ:внешний_ПОРТ" -> для jupyterhub-exporter (например, "4104:4104")
```

### 6. JupyterHub Exporter (Monitoring/configs/notebook_exporter.py)

```bash
# Отредактируйте файл экспортера
nano Monitoring/configs/notebook_exporter.py

# Замените заглушки в методе main:
# start_http_server(ваш_ПОРТ) -> фактический порт (например, 4104)
# logging.info("Prometheus exporter запущен на порту ваш_ПОРТ") -> тот же порт
```

### 7. Prometheus (Monitoring/configs/prometheus.yml)

```bash
# Отредактируйте файл конфигурации
nano Monitoring/configs/prometheus.yml

# Замените заглушки для экспортера:
# - targets: ['jupyterhub-exporter:ваш_ПОРТ'] -> фактический порт (например, 'jupyterhub-exporter:4104')
```

## Развертывание компонентов

Каждый компонент запускается отдельно в своей директории.

### 1. Запуск JupyterHub

```bash
cd /project41/Jupiter

# Сборка образа JupyterHub
docker build -t jupyterhub:firetech .

# Сборка образа Jupyter Notebook
docker build -f Dockerfile.notebook -t my-custom-jupyter-notebook:latest .

# Запуск JupyterHub
docker compose up -d
```

### 2. Запуск MongoDB

```bash
cd /project41/Mongo

# Запуск MongoDB
docker compose up -d
```

### 3. Запуск системы мониторинга

```bash
cd /project41/Monitoring

# Создание каталога для метрик
mkdir -p metrics

# Запуск системы мониторинга
docker compose up -d
```

## Проверка работоспособности

После запуска всех компонентов проверьте их доступность:

- **JupyterHub**: IP_сервера : ПОРТ
- **Grafana**: IP_сервера : ПОРТ (логин/пароль: admin/admin)
- **Prometheus**: IP_сервера : ПОРТ

### Проверка доступности GPU

Убедитесь, что GPU доступна для контейнеров:

```bash
# Проверка статуса GPU
nvidia-smi

# Ожидаемый вывод должен показать NVIDIA GeForce RTX 4090 с доступной памятью
# и, возможно, запущенные процессы Python, использующие GPU
```

## Начальная настройка

### 1. Создание администратора JupyterHub

- Перейдите на IP_сервера : ПОРТ/hub/signup
- Создайте учетную запись с именем "admin" (как указано в конфигурации)
- Войдите в систему и проверьте доступ к интерфейсу администратора

### 2. Настройка Grafana

- Перейдите на IP_сервера : ПОРТ (порт Grafana)
- Используйте логин: admin, пароль: admin при первом входе
- После входа вам будет предложено изменить пароль
- Проверьте доступность подключенных источников данных в разделе Configuration > Data sources
- Импортированные дашборды доступны в разделе Dashboards

### 3. Проверка Prometheus

- Перейдите на IP_сервера : ПОРТ (порт Prometheus) 
- В интерфейсе Prometheus выберите раздел Status > Targets для проверки статуса всех целей мониторинга
- Убедитесь, что все экспортеры (node-exporter, cadvisor, nvidia-smi-exporter, jupyterhub-exporter) имеют статус UP

<div align="top">
  <a href="#top">↑ Наверх</a>
</div>
