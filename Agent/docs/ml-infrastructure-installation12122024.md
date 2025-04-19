# ML Infrastructure - Installation Guide
*Version 1.0 от 16.12.2024*


## Содержание
1. [Предварительные требования](#предварительные-требования)
2. [Последовательность установки](#последовательность-установки)
3. [Настройка компонентов](#настройка-компонентов)
4. [Миграция данных](#миграция-данных)
5. [Проверка работоспособности](#проверка-работоспособности)


## Предварительные требования


### Аппаратные требования
- **CPU**: AMD Threadripper PRO 5975WX или аналогичный
  - Минимум: 16+ ядер
  - Рекомендуется: 32+ ядра
- **RAM**: 
  - Минимум: 64GB
  - Рекомендуется: 128GB
- **Storage**: 
  - Минимум: 500GB+ NVMe SSD
  - Рекомендуется: 1.5TB+ NVMe SSD
- **GPU**: NVIDIA с поддержкой CUDA
  - Минимум: 16GB+ VRAM
  - Рекомендуется: NVIDIA RTX 4090 (24GB VRAM)


### Системные требования
- **OS**: Ubuntu 22.04 LTS
- **Docker**: версия 24.0+
- **NVIDIA Driver**: версия 560.35.03+
- **CUDA**: версия 12.6
- **Python**: версия 3.10+
- **NVIDIA Container Toolkit**


### Сетевые требования
- Внутренняя сеть: 10Gbps
- Публичный IP адрес
- Открытые порты:
  - *****-*****: Базовые сервисы
  - *****-*****: Мониторинг
  - *****-*****: Web интерфейсы
- Настроенный DNS
- Доступ к внешним репозиториям:
  - Docker Hub
  - NVIDIA Container Registry
  - PyPI
  - Hugging Face
  
  
## Последовательность установки


### Подготовка системы

#### 1. Обновление системы
Перед началом установки необходимо обновить все системные пакеты до последних версий:
```bash
sudo apt update
sudo apt upgrade -y
```

#### 2. Установка базовых пакетов
Установка необходимых системных зависимостей для работы с репозиториями и SSL:
```bash
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common
```

#### 3. Установка NVIDIA драйверов
Добавление репозитория NVIDIA и установка драйверов. После установки требуется перезагрузка:
```bash
# Добавление репозитория NVIDIA
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update

# Установка драйверов
sudo apt install -y nvidia-driver-560

# Проверка установки
nvidia-smi  # Должно показать информацию о GPU и версии драйвера
```

#### 4. Установка CUDA
Установка CUDA toolkit для работы с GPU. Важно точно следовать версиям для совместимости:
```bash
# Скачивание и установка CUDA
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/cuda-repo-ubuntu2204-12-6-local_12.6.0-530.30.02-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-6-local_12.6.0-530.30.02-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/

# Установка CUDA и добавление в PATH
sudo apt update
sudo apt install -y cuda-12-6

# Настройка переменных окружения
echo 'export PATH=/usr/local/cuda-12.6/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc
source ~/.bashrc

# Проверка установки
nvcc --version  # Должна отображаться версия CUDA 12.6
```

#### 5. Установка Docker
Docker необходим для контейнеризации сервисов. Устанавливаем актуальную версию из официального репозитория:
```bash
# Добавление официального GPG ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Установка Docker и дополнительных компонентов
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавление текущего пользователя в группу docker для работы без sudo
sudo usermod -aG docker $USER
newgrp docker  # Применение изменений группы без перезагрузки

# Проверка установки
docker --version     # Должна отображаться версия Docker
docker compose version  # Должна отображаться версия Docker Compose
```

#### 6. Установка NVIDIA Container Toolkit
Этот компонент необходим для использования GPU внутри Docker контейнеров:
```bash
# Добавление репозитория NVIDIA
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Установка nvidia-docker2
sudo apt update
sudo apt install -y nvidia-docker2
sudo systemctl restart docker  # Перезапуск Docker для применения изменений

# Проверка работы GPU в контейнере
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi  # Должен показать информацию о GPU
```


### Установка сетевой инфраструктуры

#### 1. Создание Docker сетей
Создаем изолированные сети для разных компонентов системы:
```bash
# Создание сети для MLOps сервисов
docker network create --subnet=172.22.0.0/16 mlopsnew
# Ожидаемый вывод: ID сети в формате хеша

# Создание сети для агентских сервисов
docker network create --subnet=172.20.0.0/16 agent_default
# Ожидаемый вывод: ID сети в формате хеша

# Проверка созданных сетей
docker network ls  # Должны быть видны созданные сети
docker network inspect mlopsnew  # Подробная информация о сети mlopsnew
docker network inspect agent_default  # Подробная информация о сети agent_default
```


### Подготовка директорий

#### 1. Создание основных директорий
Создаем структуру директорий для хранения данных и конфигураций:
```bash
# Создание корневых директорий для сервисов
sudo mkdir -p /mlopsnew /agent /webbot2 /pgdb
sudo chown -R $USER:sudo /mlopsnew /agent /webbot2 /pgdb
sudo chmod -R 2775 /mlopsnew /agent /webbot2 /pgdb

# Создание поддиректорий для каждого сервиса
mkdir -p /mlopsnew/{config,data}  # Для MLOps системы
mkdir -p /agent/{config,data,logs}  # Для API сервиса
mkdir -p /webbot2/{static,templates,logs}  # Для веб-интерфейса
mkdir -p /pgdb/{configs,data,backups}  # Для PostgreSQL
```

#### 2. Создание директорий для логов
Настройка централизованного логирования:
```bash
# Создание основной директории для логов
sudo mkdir -p /var/log/ml-infrastructure
sudo chown -R $USER:sudo /var/log/ml-infrastructure
sudo chmod -R 2775 /var/log/ml-infrastructure
```

#### 3. Создание директорий для моделей
Подготовка директорий для хранения ML моделей:
```bash
# Создание директории для Hugging Face моделей
mkdir -p ~/.cache/huggingface
chmod 700 ~/.cache/huggingface  # Ограничение доступа для безопасности
```

#### 4. Создание директорий для бэкапов
Настройка системы резервного копирования:
```bash
# Создание структуры директорий для бэкапов
sudo mkdir -p /backups/{mlopsnew,agent,webbot2,pgdb,large_volumes}
sudo chown -R $USER:sudo /backups
sudo chmod -R 2775 /backups
```


### Установка PostgreSQL

#### 1. Подготовка конфигурации
Копируем конфигурационные файлы из резервной копии:
```bash
# Копирование файлов конфигурации
cp /agent_1t/config/pgdb/pg_hba.conf /pgdb/configs/  # Файл контроля доступа
cp /agent_1t/config/pgdb/postgresql.conf /pgdb/configs/  # Основной конфиг
cp /agent_1t/config/pgdb/docker-compose.yml /pgdb/  # Docker композиция
```

#### 2. Создание и запуск контейнера
Запускаем PostgreSQL в контейнере:
```bash
# Переход в директорию PostgreSQL
cd /pgdb

# Запуск контейнера
docker compose up -d  # Запуск в фоновом режиме

# Проверка запуска
docker ps | grep ml_postgres  # Должен показать запущенный контейнер
docker logs ml_postgres  # Проверка логов на наличие ошибок
```
#### 3. Проверка подключения к PostgreSQL
Выполняем базовые проверки работоспособности базы данных:
```bash
# Проверка доступности сервера PostgreSQL
docker exec -it ml_postgres pg_isready
# Ожидаемый вывод: /var/run/postgresql:5432 - accepting connections

# Проверка подключения и просмотр баз данных
docker exec -it ml_postgres psql -U postgres -c "\l"
# Должен показать список баз данных, включая ml_db
```


### Установка Qdrant

#### 1. Подготовка конфигурации
Копируем и настраиваем конфигурацию векторной базы данных:
```bash
# Копирование конфигураций из резервной копии
cp -r /agent_1t/config/mlopsnew/qdrant /mlopsnew/config/
# Убедитесь, что все файлы скопированы: должны быть config.yml и другие конфигурационные файлы
```

#### 2. Docker конфигурация
Создаем и настраиваем контейнер Qdrant. Этот сервис критически важен для векторного поиска:
```yaml
# docker-compose.yml для Qdrant - сохраните в /mlopsnew/config/qdrant/docker-compose.yml
services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant_new
    restart: unless-stopped
    ports:
      - "your_port:6333"  # HTTP API порт
      - "your_port:6334"  # GRPC порт
    volumes:
      - qdrant_storage_new:/qdrant/storage  # Постоянное хранилище данных
    environment:
      - QDRANT_ALLOW_RECOVERY=true  # Включение восстановления при сбоях
    networks:
      - mlopsnew

volumes:
  qdrant_storage_new:  # Определение volume для хранения данных

networks:
  mlopsnew:
    external: true  # Использование существующей сети
```

#### 3. Запуск Qdrant
Запускаем и проверяем работу векторной базы данных:
```bash
# Переход в директорию с конфигурацией
cd /mlopsnew

# Запуск сервиса
docker compose -f config/qdrant/docker-compose.yml up -d

# Проверка статуса контейнера
docker ps | grep qdrant_new
# Должен показать работающий контейнер с открытыми портами 17302 и 17303

# Проверка доступности API
curl http://localhost:_your_port/health
# Должен вернуть {"title":"Ok"} или похожий ответ о здоровье сервиса
```


### Установка Saiga LLM

#### 1. Подготовка конфигурации
Копируем конфигурацию и подготавливаем модель:
```bash
# Копирование конфигураций LLM сервиса
cp -r /agent_1t/src/mlopsnew/saiga /mlopsnew/
# Проверьте наличие всех необходимых файлов в директории
```

#### 2. Установка модели
Подготавливаем модель из резервной копии или загружаем новую:
```bash
# Создание директории для моделей Hugging Face
mkdir -p ~/.cache/huggingface/hub/models--NightForger--saiga_nemo_12b-GPTQ

# Восстановление модели из бэкапа (если есть)
# Замените YYYYMMDD_HHMMSS на актуальную дату бэкапа
tar xvf /backups/large_volumes/saiga_model_*.tar.gz -C ~/.cache/huggingface/hub/
# Должны быть распакованы файлы модели: конфигурация, веса и токенизатор
```

#### 3. Запуск LLM сервиса
Запускаем и проверяем работу языковой модели:
```bash
# Переход в директорию сервиса
cd /mlopsnew/saiga

# Запуск сервиса
docker compose up -d
# Запуск может занять несколько минут из-за загрузки модели в память

# Проверка статуса
docker ps | grep saiga
# Должен показать работающий контейнер

# Проверка API модели
curl http://localhost:_your_port/v1/models
# Должен вернуть информацию о доступной модели
```


### Установка Monitoring Stack

#### 1. Установка Prometheus
Настраиваем систему сбора метрик:
```bash
# Копирование конфигураций Prometheus
cp -r /agent_1t/config/mlopsnew/prometheus /mlopsnew/config/

# Запуск Prometheus
cd /mlopsnew
docker compose -f docker-compose.monitoring.yml up -d prometheus_new

# Проверка доступности
curl http://localhost:your_port/-/healthy
# Должен вернуть "Prometheus is Healthy" или похожий ответ
```

#### 2. Установка Grafana
Настраиваем систему визуализации метрик:
```bash
# Копирование конфигураций Grafana
cp -r /agent_1t/config/mlopsnew/grafana /mlopsnew/config/
# В директории должны появиться provisioning, dashboards и другие конфигурационные файлы

# Запуск Grafana
cd /mlopsnew
docker compose -f docker-compose.monitoring.yml up -d grafana_new

# Проверка доступности веб-интерфейса
curl http://localhost:your_port/api/health
# Должен вернуть {"commit":"","database":"ok","version":"10.x.x"}
```

#### 3. Установка экспортеров
Настраиваем сборщики метрик для различных компонентов системы:


##### Node Exporter
Для сбора системных метрик:
```bash
# Запуск Node Exporter
docker compose -f docker-compose.monitoring.yml up -d node-exporter_new

# Проверка метрик
curl http://localhost:9100/metrics | grep "node_cpu"
# Должны появиться метрики использования CPU
```


##### DCGM Exporter
Для сбора метрик GPU:
```bash
# Запуск DCGM Exporter
docker compose -f docker-compose.monitoring.yml up -d dcgm-exporter_new

# Проверка метрик GPU
curl http://localhost:9400/metrics | grep "DCGM_FI_DEV_GPU_UTIL"
# Должны появиться метрики использования GPU
```


##### Agent Exporter
Для сбора метрик приложения:
```bash
# Копирование конфигурации экспортера
cp -r /agent_1t/src/mlopsnew/agent-exporter /mlopsnew/

# Запуск Agent Exporter
docker compose -f docker-compose.monitoring.yml up -d agent_exporter_new

# Проверка пользовательских метрик
curl http://localhost:9402/metrics | grep "agent_"
# Должны появиться специфические метрики приложения
```

#### 4. Проверка сбора метрик
Проверяем, что все метрики собираются корректно:
```bash
# Проверка таргетов в Prometheus
curl http://localhost:your_port/api/v1/targets | jq .
# Все таргеты должны быть в состоянии "up"

# Проверка доступности метрик в Prometheus
curl http://localhost:your_port/api/v1/query?query=up | jq .
# Должен показать статус всех endpoint'ов
```


### Установка Project API

#### 1. Подготовка исходного кода
Копируем и настраиваем API сервис:
```bash
# Копирование файлов проекта
cp -r /agent_1t/src/agent/* /agent/
cp /agent_1t/config/agent/docker-compose.yml /agent/
# Проверьте наличие всех необходимых файлов и директорий
```

#### 2. Настройка зависимостей
Устанавливаем необходимые компоненты для работы API:
```bash
# Переход в директорию проекта
cd /agent

# Установка специфических зависимостей
./requirements/fix_pymorphy.sh  # Исправление проблем с pymorphy
./requirements/install_nlp_resources.sh  # Установка NLP ресурсов

# После установки проверьте наличие всех необходимых файлов
ls -la requirements/
```

#### 3. Запуск API сервиса
Запускаем и проверяем работу API:
```bash
# Запуск сервиса
docker compose up -d
# Дождитесь полного запуска всех контейнеров

# Проверка статуса
docker ps | grep project_api_service
# Контейнер должен быть в статусе "Up"

# Просмотр логов на наличие ошибок
docker logs project_api_service

# Проверка доступности API
curl -X GET http://localhost:17401/health
# Должен вернуть положительный статус

# Тестовый запрос к API
curl -X POST http://localhost:your_port/process_message \
  -H "Content-Type: application/json" \
  -d '{"message": "test", "user_name": "test", "course": "test"}'
# Должен вернуть корректный ответ от сервиса
```


### Установка WebBot2 (опционально)

#### 1. Подготовка файлов проекта
Копируем исходный код и конфигурации веб-интерфейса:
```bash
# Копирование исходного кода веб-интерфейса
cp -r /agent_1t/src/webbot2/* /webbot2/
cp /agent_1t/config/webbot2/docker-compose.yml /webbot2/
# Убедитесь в наличии всех необходимых файлов: app.py, static/, templates/
```

#### 2. Настройка прав доступа
Устанавливаем корректные права для работы приложения:
```bash
# Установка прав на исполнение для скриптов
chmod +x /webbot2/wait-for-api.sh  # Скрипт проверки доступности API

# Установка прав на статические файлы и шаблоны
chmod -R 755 /webbot2/static      # Доступ к статическим файлам
chmod -R 755 /webbot2/templates   # Доступ к шаблонам

# Проверка установленных прав
ls -la /webbot2/  # Должны быть корректные права на все файлы
```

#### 3. Проверка конфигурации
Проверяем настройки подключения к API:
```bash
# Проверка конфигурации API в app.py
cat /webbot2/app.py | grep API_CONFIG
# Убедитесь, что URL и порты соответствуют вашей конфигурации
```

#### 4. Запуск веб-интерфейса
Запускаем и проверяем работу WebBot2:
```bash
# Переход в директорию проекта
cd /webbot2

# Запуск сервиса
docker compose up -d
# Дождитесь полного запуска контейнера

# Проверка статуса
docker ps | grep webbot2
# Должен быть статус "Up"

# Проверка логов
docker logs webbot2
# Убедитесь в отсутствии ошибок

# Проверка доступности веб-интерфейса
curl http://localhost:your_port
# Должен вернуть HTML-страницу входа
```


### Настройка автозапуска

#### 1. Создание systemd сервиса
Настраиваем автоматический запуск всех компонентов:
```bash
# Создание systemd сервиса
sudo tee /etc/systemd/system/ml-infrastructure.service << 'EOL'
[Unit]
Description=ML Infrastructure Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/
ExecStart=/bin/bash -c '\
    cd /pgdb && docker compose up -d && \
    cd /mlopsnew && docker compose -f docker-compose.monitoring.yml up -d && \
    cd /agent && docker compose up -d && \
    cd /webbot2 && docker compose up -d'
ExecStop=/bin/bash -c '\
    cd /webbot2 && docker compose down && \
    cd /agent && docker compose down && \
    cd /mlopsnew && docker compose -f docker-compose.monitoring.yml down && \
    cd /pgdb && docker compose down'

[Install]
WantedBy=multi-user.target
EOL

# Проверка синтаксиса файла сервиса
cat /etc/systemd/system/ml-infrastructure.service
```

#### 2. Активация сервиса
Включаем и запускаем сервис:
```bash
# Перезагрузка конфигурации systemd
sudo systemctl daemon-reload

# Включение автозапуска
sudo systemctl enable ml-infrastructure
# Должно появиться сообщение о создании символической ссылки

# Запуск сервиса
sudo systemctl start ml-infrastructure

# Проверка статуса
sudo systemctl status ml-infrastructure
# Должен быть статус "active"
```


### Финальная проверка системы

#### 1. Проверка всех сервисов
Убеждаемся, что все компоненты работают корректно:
```bash
# Проверка статуса всех контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Проверка логов каждого сервиса
for container in ml_postgres qdrant_new saiga_saiga_1 project_api_service webbot2 grafana_new prometheus_new; do
    echo "=== Logs for $container ==="
    docker logs $container --tail 50
    echo
done
```

#### 2. Проверка сетевого взаимодействия
Тестируем связь между компонентами:
```bash
# Проверка сетевой связности
docker exec webbot2 ping -c 1 project_api_service
docker exec project_api_service ping -c 1 ml_postgres
docker exec project_api_service ping -c 1 qdrant_new

# Проверка доступности всех портов
netstat -tulpn | grep -E '172(22|29|30|31|40)'
```

#### 3. Тестовый запрос
Проверяем работу системы через веб-интерфейс:
```bash
# Тестовый запрос через curl
curl -X POST http://localhost:your_port/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Привет! Как дела?",
    "user_name": "test_user",
    "course": "test_course"
  }'
# Должен вернуть осмысленный ответ от бота
```


### Завершающие действия

#### 1. Очистка системы
Удаляем временные файлы и проверяем диск:
```bash
# Очистка временных файлов
rm -rf /tmp/restore_*

# Проверка использования диска
df -h /
du -sh /backups/*
```

#### 2. Создание тестового бэкапа
Проверяем работу системы резервного копирования:
```bash
# Запуск тестового бэкапа
/usr/local/bin/system-backup.sh

# Проверка результатов
ls -la /backups/*/daily/
# Должны появиться свежие файлы бэкапов
```

#### 3. Документация
Сохраняем все внесённые изменения в конфигурацию:
```bash
# Создание архива с конфигурациями
tar czf ~/ml-infrastructure-configs-$(date +%Y%m%d).tar.gz \
    /mlopsnew/config \
    /agent/config \
    /webbot2/config \
    /pgdb/configs

# Сохранение версий используемых образов
docker images > ~/ml-infrastructure-images-$(date +%Y%m%d).txt
```