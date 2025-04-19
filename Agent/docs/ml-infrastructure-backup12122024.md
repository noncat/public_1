# ML Infrastructure - Backup & Recovery Guide
*Version 1.3 от 12.12.2024*

## Содержание
1. [Общая информация](#общая-информация)
2. [Структура бэкапов](#структура-бэкапов)
3. [Процедуры резервного копирования](#процедуры-резервного-копирования)
4. [Процедуры восстановления](#процедуры-восстановления)
5. [Автоматизация и мониторинг](#автоматизация-и-мониторинг)
6. [Проверка и тестирование](#проверка-и-тестирование)

## Общая информация

### Расписание бэкапов
- **Ежедневно** (01:00):
  - Хранятся последние 3 версии
  - Полный бэкап всех сервисов

- **Еженедельно** (воскресенье 01:00):
  - Хранятся последние 2 версии
  - Полный бэкап всех сервисов

- **Ежемесячно** (1-е число месяца 01:00):
  - Хранятся последние 2 версии
  - Полный бэкап всех сервисов

### Компоненты системы бэкапа
```bash
# Основной скрипт
/usr/local/bin/system-backup.sh

# Логи бэкапа
/var/log/system-backup.log

# Директория бэкапов
/backups/
```

### Объем данных
- PostgreSQL: ~20-30 GB
- Qdrant: ~50-100 GB
- Saiga Model: ~7-8 GB
- Конфигурации: <1 GB

## Структура бэкапов

### Файловая система
```
/backups/
├── mlopsnew/                  # ML мониторинг
│   ├── daily/
│   │   ├── configs/         # Конфигурации
│   │   ├── data/           # Данные
│   │   └── docker/         # Docker volumes
│   ├── weekly/
│   └── monthly/
├── large_volumes/            # Большие данные
│   ├── mlopsnew_qdrant_storage_new_*.tar.gz
│   └── saiga_model_*.tar.gz
├── agent/                    # API сервис
├── webbot/                   # Старый интерфейс
├── webbot2/                  # Новый интерфейс
└── pgdb/                     # PostgreSQL
```

### Содержимое по сервисам

#### mlopsnew
```yaml
configs:
  - docker-compose.*.yml
  - config/grafana/
  - config/prometheus/
  - config/qdrant/
  - agent-exporter/
  - requirements/
  - saiga/
data:
  - Все файлы директории
docker:
  - grafana_data_new
  - prometheus_data_new
```

#### agent
```yaml
data:
  - Все файлы директории
docker:
  - agent_qdrant_storage
```

#### webbot/webbot2
```yaml
data:
  - Все файлы директории
docker:
  - webbot_data
  - webbot2_data
```

#### pgdb
```yaml
configs:
  - docker-compose.yml
  - pg_hba.conf
  - postgresql.conf
  - backup.sh
data:
  - SQL dumps
```

## Процедуры резервного копирования

### Основной скрипт бэкапа
```bash
#!/bin/bash

# Настройки
BACKUP_ROOT="/backups"
LOG_FILE="/var/log/system-backup.log"
SERVICES=("mlopsnew" "agent" "webbot" "webbot2" "pgdb")
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_USER="prohorov"
BACKUP_GROUP="sudo"

# Функция логирования
log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Очистка старых бэкапов
cleanup_old_backups() {
   local directory=$1
   local keep_count=$2

   if [ -d "$directory" ]; then
       find "$directory" -maxdepth 1 -name "*.tar.gz" -o -name "*.sql" | \
           sort -r | tail -n +$((keep_count + 1)) | xargs -r rm
   fi
}
```

### Бэкап PostgreSQL
```bash
backup_postgres() {
   local service_backup_dir="$BACKUP_ROOT/$1/$BACKUP_TYPE"
   local timestamp=$2

   mkdir -p "$service_backup_dir/data"

   if docker exec ml_postgres pg_dumpall -U postgres > \
       "$service_backup_dir/data/pgdump_${timestamp}.sql"; then
       log "PostgreSQL dump created successfully"
       chown $BACKUP_USER:$BACKUP_GROUP \
           "$service_backup_dir/data/pgdump_${timestamp}.sql"
       chmod 2664 "$service_backup_dir/data/pgdump_${timestamp}.sql"
   else
       log "Error creating PostgreSQL dump"
       return 1
   fi
}
```

### Бэкап Docker volumes
```bash
backup_volume() {
   local volume=$1
   local backup_path=$2

   # Получаем размер
   local size_str=$(docker system df -v | grep "$volume" | awk '{print $3}')
   log "Volume $volume size: ${size_str}"

   # Особая обработка для Prometheus
   if [[ $volume == *"prometheus"* ]]; then
       docker run --rm -v "$volume":/data -v "$backup_path":/backup \
           ubuntu tar czf "/backup/${volume}_${DATE}.tar.gz" \
           --warning=no-file-changed /data
   else
       docker run --rm -v "$volume":/data -v "$backup_path":/backup \
           ubuntu tar czf "/backup/${volume}_${DATE}.tar.gz" /data
   fi

   chown $BACKUP_USER:$BACKUP_GROUP "$backup_path/${volume}_${DATE}.tar.gz"
   chmod 2664 "$backup_path/${volume}_${DATE}.tar.gz"
}
```

### Бэкап модели Saiga
```bash
backup_saiga_model() {
    local backup_dir="$BACKUP_ROOT/large_volumes"
    local model_dir="/home/prohorov/.cache/huggingface/hub/models--NightForger--saiga_nemo_12b-GPTQ"
    
    log "Starting Saiga model backup"
    mkdir -p "$backup_dir"
    
    tar czf "$backup_dir/saiga_model_${DATE}.tar.gz" \
        --warning=no-file-changed \
        "$model_dir/blobs" \
        "$model_dir/snapshots" \
        "$model_dir/refs"
    
    chown $BACKUP_USER:$BACKUP_GROUP "$backup_dir/saiga_model_${DATE}.tar.gz"
    chmod 2664 "$backup_dir/saiga_model_${DATE}.tar.gz"
    
    # Оставляем только последние 2 бэкапа
    find "$backup_dir" -name "saiga_model_*.tar.gz" | \
        sort -r | tail -n +3 | xargs -r rm
}
```

## Процедуры восстановления

### Порядок восстановления
1. PostgreSQL (база данных)
2. Mlopsnew (мониторинг)
3. Agent (API сервис)
4. Webbot/Webbot2 (интерфейсы)

### Восстановление mlopsnew

#### Конфигурации
```bash
# 1. Выбор бэкапа
ls -l /backups/mlopsnew/daily/configs/

# 2. Распаковка
sudo mkdir -p /tmp/restore_mlopsnew
sudo tar xvf /backups/mlopsnew/daily/configs/configs_YYYYMMDD_HHMMSS.tar.gz \
    -C /tmp/restore_mlopsnew

# 3. Восстановление
sudo cp -r /tmp/restore_mlopsnew/mlopsnew/config/* /mlopsnew/config/
sudo cp /tmp/restore_mlopsnew/mlopsnew/docker-compose.*.yml /mlopsnew/
sudo cp -r /tmp/restore_mlopsnew/mlopsnew/requirements /mlopsnew/
sudo cp -r /tmp/restore_mlopsnew/mlopsnew/agent-exporter /mlopsnew/
sudo cp -r /tmp/restore_mlopsnew/mlopsnew/saiga /mlopsnew/

# 4. Права
sudo chown -R USER:sudo /mlopsnew
sudo chmod -R 2775 /mlopsnew
```

#### Docker volumes
```bash
# Grafana
docker volume rm mlopsnew_grafana_data_new
docker volume create mlopsnew_grafana_data_new
docker run --rm -v mlopsnew_grafana_data_new:/data \
    -v /backups/mlopsnew/daily/docker:/backup \
    ubuntu bash -c "cd /data && tar xf /backup/mlopsnew_grafana_data_new_YYYYMMDD_HHMMSS.tar.gz --strip 1"

# Prometheus
docker volume rm mlopsnew_prometheus_data_new
docker volume create mlopsnew_prometheus_data_new
docker run --rm -v mlopsnew_prometheus_data_new:/data \
    -v /backups/mlopsnew/daily/docker:/backup \
    ubuntu bash -c "cd /data && tar xf /backup/mlopsnew_prometheus_data_new_YYYYMMDD_HHMMSS.tar.gz --strip 1"

# Qdrant
docker volume rm mlopsnew_qdrant_storage_new
docker volume create mlopsnew_qdrant_storage_new
docker run --rm -v mlopsnew_qdrant_storage_new:/data \
    -v /backups/large_volumes:/backup \
    ubuntu bash -c "cd /data && tar xf /backup/mlopsnew_qdrant_storage_new_YYYYMMDD_HHMMSS.tar.gz --strip 1"
```

### Восстановление PostgreSQL

#### Конфигурации
```bash
# 1. Выбор бэкапа
ls -l /backups/pgdb/daily/configs/

# 2. Распаковка
sudo mkdir -p /tmp/restore_pgdb
sudo tar xvf /backups/pgdb/daily/configs/configs_YYYYMMDD_HHMMSS.tar.gz \
    -C /tmp/restore_pgdb

# 3. Восстановление
sudo cp -r /tmp/restore_pgdb/pgdb/configs/* /pgdb/configs/
sudo cp /tmp/restore_pgdb/pgdb/docker-compose.yml /pgdb/
```

#### Данные
```bash
# 1. Остановка контейнера
docker stop ml_postgres

# 2. Очистка данных
sudo rm -rf /pgdb/data/*

# 3. Запуск контейнера
docker-compose -f /pgdb/docker-compose.yml up -d

# 4. Восстановление
cat /backups/pgdb/daily/data/pgdump_YYYYMMDD_HHMMSS.sql | \
    docker exec -i ml_postgres psql -U postgres
```

### Восстановление Saiga
```bash
# 1. Выбор бэкапа
ls -l /backups/large_volumes/saiga_model_*.tar.gz

# 2. Распаковка
sudo mkdir -p /tmp/restore_saiga
sudo tar xvf /backups/large_volumes/saiga_model_YYYYMMDD_HHMMSS.tar.gz \
    -C /tmp/restore_saiga

# 3. Восстановление
sudo mkdir -p /home/prohorov/.cache/huggingface/hub/
sudo cp -r /tmp/restore_saiga/home/prohorov/.cache/huggingface/hub/* \
    /home/prohorov/.cache/huggingface/hub/

# 4. Права
sudo chown -R USER:sudo /home/USER/.cache/huggingface
sudo chmod -R 2775 /home/USER/.cache/huggingface
```

## Автоматизация и мониторинг

### Crontab конфигурация
```bash
# Ежедневное резервное копирование
0 1 * * * /usr/local/bin/system-backup.sh

# Проверка статуса бэкапов
30 1 * * * /usr/local/bin/check-backups.sh
```

### Мониторинг бэкапов
```bash
# Проверка логов
sudo tail -f /var/log/system-backup.log

# Проверка размеров
du -sh /backups/*

# Проверка последних бэкапов
ls -lth /backups/*/daily/data/
ls -lth /backups/large_volumes/saiga_model_*
```

### Уведомления
```python
def send_backup_notification(status, message):
    """Отправка уведомлений о статусе бэкапа"""
    import requests
    
    webhook_url = "YOUR_WEBHOOK_URL"
    payload = {
        "status": status,
        "message": message,
        "timestamp": datetime.now().isoformat()
    }
    
    requests.post(webhook_url, json=payload)
```

## Проверка и тестирование

### Проверка целостности
```bash
# PostgreSQL
pg_restore --list backup.sql

# Tar архивы
tar tvf backup.tar.gz

# Docker volumes
docker volume inspect volume_name
```

### Тестовое восстановление
```bash
# 1. Создание тестовой среды
docker-compose -f docker-compose.test.yml up -d

# 2. Восстановление в тестовую среду
./restore-test.sh backup_file

# 3. Проверка
./verify-restore.sh
```

### Мониторинг процесса
```bash
# Проверка статуса
docker ps
docker logs

# Проверка ресурсов
docker stats

# Проверка сети
netstat -tulpn
```

