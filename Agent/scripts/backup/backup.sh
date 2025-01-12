#!/bin/bash

# =====================================================
# КОНФИГУРАЦИЯ СКРИПТА
# =====================================================

# Основные настройки бэкапа
# !!! ИЗМЕНИТЕ СЛЕДУЮЩИЕ ЗНАЧЕНИЯ ПОД ВАШУ КОНФИГУРАЦИЮ !!!

# Корневая директория для бэкапов
BACKUP_ROOT="/backups"  # Корневая директория для хранения всех бэкапов

# Путь к файлу логов
LOG_FILE="/var/log/system-backup.log"  # Файл для записи логов выполнения скрипта

# Список сервисов для бэкапа
# Добавьте или удалите сервисы в соответствии с вашей инфраструктурой
SERVICES=(
    "mlopsnew"  # Сервис мониторинга и ML
    "agent"     # API сервис
    "webbot"    # Старый веб-интерфейс
    "webbot2"   # Новый веб-интерфейс
    "pgdb"      # PostgreSQL
)

# Пользователь и группа для файлов бэкапа
# !!! ОБЯЗАТЕЛЬНО ИЗМЕНИТЕ НА СВОЕГО ПОЛЬЗОВАТЕЛЯ И ГРУППУ !!!
BACKUP_USER="your_username"  # Пример: prohorov
BACKUP_GROUP="your_group"    # Пример: sudo

# Текущая дата для именования файлов
DATE=$(date +%Y%m%d_%H%M%S)

# =====================================================
# Функции логирования и очистки
# =====================================================

# Функция логирования - записывает сообщения в лог и выводит их на экран
log() {
   echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Функция очистки старых бэкапов
# $1 - директория с бэкапами
# $2 - количество сохраняемых версий
cleanup_old_backups() {
   local directory=$1
   local keep_count=$2

   if [ -d "$directory" ]; then
       log "Cleaning old backups in $directory, keeping $keep_count files"
       find "$directory" -maxdepth 1 -name "*.tar.gz" -o -name "*.sql" | \
           sort -r | tail -n +$((keep_count + 1)) | xargs -r rm
   fi
}

# =====================================================
# Функции бэкапа компонентов
# =====================================================

# Функция для бэкапа PostgreSQL
# !!! При необходимости измените имя контейнера и пользователя PostgreSQL !!!
backup_postgres() {
   local service_backup_dir="$BACKUP_ROOT/$1/$BACKUP_TYPE"
   local timestamp=$2
   log "Starting PostgreSQL backup"

   mkdir -p "$service_backup_dir/data"

   if docker exec ml_postgres pg_dumpall -U postgres > "$service_backup_dir/data/pgdump_${timestamp}.sql"; then
       log "PostgreSQL dump created successfully"
       chown $BACKUP_USER:$BACKUP_GROUP "$service_backup_dir/data/pgdump_${timestamp}.sql"
       chmod 2664 "$service_backup_dir/data/pgdump_${timestamp}.sql"
   else
       log "Error creating PostgreSQL dump"
       return 1
   fi
}

# Функция для бэкапа Docker volume
backup_volume() {
   local volume=$1
   local backup_path=$2

   # Пропускаем volumes, которые бэкапятся отдельно
   if [[ $volume == *"qdrant"* ]] && [[ $volume == *"mlopsnew"* ]]; then
       log "Skipping $volume - handled by large volumes backup"
       return
   fi

   local size_str=$(docker system df -v | grep "$volume" | awk '{print $3}')
   log "Volume $volume size: ${size_str}"

   # Особая обработка для Prometheus
   if [[ $volume == *"prometheus"* ]]; then
       log "Special handling for Prometheus data"
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

# Функция для бэкапа модели Saiga
# !!! ИЗМЕНИТЕ ПУТЬ К МОДЕЛИ, ЕСЛИ ОН ОТЛИЧАЕТСЯ !!!
backup_saiga_model() {
    local backup_dir="$BACKUP_ROOT/large_volumes"
    local model_dir="/home/prohorov/.cache/huggingface/hub/models--NightForger--saiga_nemo_12b-GPTQ"

    log "Starting Saiga model backup"
    mkdir -p "$backup_dir"

    tar czf "$backup_dir/saiga_model_${DATE}.tar.gz" \
        --warning=no-file-changed \
        "$model_dir/blobs" \
        "$model_dir/snapshots" \
        "$model_dir/refs" 2>/dev/null || true

    chown $BACKUP_USER:$BACKUP_GROUP "$backup_dir/saiga_model_${DATE}.tar.gz"
    chmod 2664 "$backup_dir/saiga_model_${DATE}.tar.gz"

    # Оставляем только последние 2 бэкапа
    find "$backup_dir" -name "saiga_model_*.tar.gz" | \
        sort -r | tail -n +3 | xargs -r rm

    log "Saiga model backup completed"
}

# Функция для бэкапа сервиса
backup_service() {
   local service=$1
   local service_backup_dir="$BACKUP_ROOT/$service/$BACKUP_TYPE"
   local keep_count=3  # По умолчанию храним 3 бэкапа для daily

   # Определяем количество хранимых бэкапов в зависимости от типа
   case $BACKUP_TYPE in
       "monthly")
           keep_count=2
           ;;
       "weekly")
           keep_count=2
           ;;
       "daily")
           keep_count=3
           ;;
   esac

   # Создаем директории с правильными правами
   mkdir -p "$service_backup_dir"/{configs,data,docker}
   chown -R $BACKUP_USER:$BACKUP_GROUP "$service_backup_dir"
   chmod -R 2775 "$service_backup_dir"

   log "Starting backup for $service"

   case $service in
       "mlopsnew")
           log "Backing up configs for mlopsnew"
           tar czf "$service_backup_dir/configs/configs_${DATE}.tar.gz" \
               /$service/docker-compose.*.yml \
               /$service/config \
               /$service/requirements \
               /$service/agent-exporter \
               /$service/saiga 2>/dev/null || true

           log "Backing up data for mlopsnew"
           tar czf "$service_backup_dir/data/data_${DATE}.tar.gz" \
               --exclude="*.pyc" \
               --exclude="__pycache__" \
               --exclude=".git" \
               --exclude="node_modules" \
               --exclude=".env" \
               -C /$service . 2>/dev/null || true
           ;;

       "pgdb")
           log "Backing up PostgreSQL config"
           tar czf "$service_backup_dir/configs/configs_${DATE}.tar.gz" \
               /pgdb/docker-compose.yml \
               /pgdb/configs \
               /pgdb/backups/backup.sh 2>/dev/null || true

           backup_postgres $service $DATE
           ;;

       *)
           log "Backing up service data for $service"
           tar czf "$service_backup_dir/data/data_${DATE}.tar.gz" \
               --exclude="*.pyc" \
               --exclude="__pycache__" \
               --exclude=".git" \
               --exclude="*.swp" \
               --exclude="*.swo" \
               --exclude="node_modules" \
               --exclude=".env" \
               -C /$service . 2>/dev/null || true
           ;;
   esac

   # Устанавливаем права на новые файлы
   find "$service_backup_dir" -type f -name "*.tar.gz" -exec chown $BACKUP_USER:$BACKUP_GROUP {} \;
   find "$service_backup_dir" -type f -name "*.tar.gz" -exec chmod 2664 {} \;

   # Бэкап Docker volumes
   # !!! ПРОВЕРЬТЕ И ИЗМЕНИТЕ ИМЕНА VOLUMES В СООТВЕТСТВИИ С ВАШЕЙ КОНФИГУРАЦИЕЙ !!!
   log "Backing up Docker volumes for $service"
   local volumes
   case $service in
       "mlopsnew")
           volumes=(
               "mlopsnew_grafana_data_new"
               "mlopsnew_prometheus_data_new"
           )
           ;;
       "agent")
           volumes=("agent_qdrant_storage")
           ;;
       "webbot")
           volumes=("webbot_data")
           ;;
       "webbot2")
           volumes=("webbot2_data")
           ;;
       *)
           volumes=()
           ;;
   esac

   for volume in "${volumes[@]}"; do
       if docker volume inspect "$volume" >/dev/null 2>&1; then
           log "Processing volume: $volume"
           backup_volume "$volume" "$service_backup_dir/docker"
       fi
   done

   # Очистка старых бэкапов
   cleanup_old_backups "$service_backup_dir/configs" $keep_count
   cleanup_old_backups "$service_backup_dir/data" $keep_count
   cleanup_old_backups "$service_backup_dir/docker" $keep_count
}

# =====================================================
# ОСНОВНОЙ ПРОЦЕСС
# =====================================================

# Определение типа бэкапа
DOW=$(date +%u)    # день недели (1-7)
DOM=$(date +%d)    # день месяца (1-31)

if [ "$DOM" = "01" ]; then
   BACKUP_TYPE="monthly"
elif [ "$DOW" = "7" ]; then
   BACKUP_TYPE="weekly"
else
   BACKUP_TYPE="daily"
fi

# Основной процесс
log "Starting system backup (Type: $BACKUP_TYPE)"
log "Available space: $(df -h $BACKUP_ROOT | awk 'NR==2 {print $4}')"

# Бэкап каждого сервиса
for service in "${SERVICES[@]}"; do
   backup_service "$service"
done

# Бэкап большого Qdrant
# !!! ИЗМЕНИТЕ ИМЯ VOLUME ЕСЛИ ОТЛИЧАЕТСЯ !!!
if docker volume inspect "mlopsnew_qdrant_storage_new" >/dev/null 2>&1; then
   log "Backing up mlopsnew qdrant storage"
   docker run --rm -v mlopsnew_qdrant_storage_new:/data -v $BACKUP_ROOT/large_volumes:/backup \
       ubuntu tar czf "/backup/mlopsnew_qdrant_storage_new_${DATE}.tar.gz" /data

   chown $BACKUP_USER:$BACKUP_GROUP "$BACKUP_ROOT/large_volumes/mlopsnew_qdrant_storage_new_${DATE}.tar.gz"
   chmod 2664 "$BACKUP_ROOT/large_volumes/mlopsnew_qdrant_storage_new_${DATE}.tar.gz"

   # Оставляем только последние 2 бэкапа
   find "$BACKUP_ROOT/large_volumes" -name "mlopsnew_qdrant_storage_new_*.tar.gz" | \
       sort -r | tail -n +3 | xargs -r rm
fi

# Бэкап модели Saiga
backup_saiga_model

# Проверка результатов
log "Backup completed. Results:"
for service in "${SERVICES[@]}"; do
   log "$(du -sh $BACKUP_ROOT/$service 2>/dev/null)"
done

log "Large volumes backup size: $(du -sh $BACKUP_ROOT/large_volumes 2>/dev/null)"
log "Remaining space: $(df -h $BACKUP_ROOT | awk 'NR==2 {print $4}')"
log "Backup finished"
log "-------------------"