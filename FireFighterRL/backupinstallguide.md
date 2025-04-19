- [Описание проекта FireFighterRL](README.md)
- [Описание архитектуры проекта FireFighter](https://github.com/FireTech-team41/FireFighterRL/tree/architecture_project41)
- [Руководство по развертыванию FireFighter ML-инфраструктуры](firetechinstallguide.md)

# Руководство по системе бэкапа проекта FireFighter

<br>
<div align="center">
  <a href="/screenshots/example_of_script_execution.png">
    <img src="/screenshots/example_of_script_execution.png" alt="Пример выполнения скрипта резервного копирования" width="600" style="max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; margin: 20px 0;">
  </a>
  <p><em>Пример выполнения скрипта резервного копирования</em></p>
</div>
<br>

## Компоненты бэкапа

Скрипт backup-script.sh создает резервные копии:
- Конфигурационных файлов из каталогов Jupiter, Mongo и Monitoring/configs
- Docker volumes JupyterHub и системы мониторинга
- Дампа базы данных MongoDB (если запущен соответствующий контейнер)

Бэкапы шифруются паролем и отправляются на удаленный ресурс, а также сохраняются локально на сервере.

## Установка и настройка

### 1. Подготовка окружения

В структуре проекта уже созданы необходимые директории:
```
/project41/backup/
├── archives/       # Для хранения локальных копий бэкапов
├── logs/           # Для хранения журналов
├── backup-script.sh
└── restore-script.sh
```

### 2. Установка зависимостей

```bash
sudo apt update
sudo apt install -y rclone p7zip-full
```

### 3. Настройка rclone для удаленного ресурса

```bash
rclone config
```

При настройке:
- Выберите "n" для создания нового подключения
- Введите имя: `например GoogleDrive`
- Выберите тип хранилища: `drive` (обычно это номер 20)
- Для client_id и client_secret нажмите Enter (оставьте пустыми)
- Для advanced config выберите "y"
- Для всех дополнительных настроек нажимайте Enter
- При вопросе о auto config выберите "n"
- Запустите на локальном компьютере: `rclone authorize "drive"`
- Скопируйте полученный токен на сервер

### 4. Настройка скриптов

В обоих скриптах измените пароль шифрования:
```bash
nano /project41/backup/backup-script.sh
```
Найдите строку:
```
PASSWORD="changeThisPassword"
```
Замените на надежный пароль.

То же самое сделайте в скрипте восстановления:
```bash
nano /project41/backup/restore-script.sh
```
**В обоих скриптах замените название профиля авторизации в rclone на свой.**
```
# remote name (configured in rclone)
REMOTE_NAME="GoogleDrive"
REMOTE_PATH="Test"
```

### 5. Настройка автозапуска

Добавьте задание в crontab:
```bash
crontab -e
```

Добавьте строку для запуска в 2 часа ночи:
```
0 2 * * * /project41/backup/backup-script.sh /project41/backup/logs/backup.log
```

## Использование

### Ручной запуск бэкапа

```bash
/project41/backup/backup-script.sh /project41/backup/logs/manual_backup.log
```

### Просмотр доступных бэкапов

Локальные бэкапы:
```bash
/project41/backup/restore-script.sh
```
<br>
<div align="center">
  <a href="/screenshots/local_backup.png">
    <img src="/screenshots/local_backup.png" alt="Пример бэкапа сохраненного локально" width="600" style="max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; margin: 20px 0;">
  </a>
  <p><em>Пример бэкапа сохраненного локально</em></p>
</div>
<br>

Бэкапы на удаленном ресурсе:
```
Зайти на ресурс и проверить вручную
```

<br>
<div align="center">
  <a href="/screenshots/backup_on_a_remote_resource.png">
    <img src="/screenshots/backup_on_a_remote_resource.png" alt="Пример бэкапа сохраненного на удаленном ресурсе" width="600" style="max-width: 100%; height: auto; border: 1px solid #ddd; border-radius: 4px; margin: 20px 0;">
  </a>
  <p><em>Пример бэкапа сохраненного на удаленном ресурсе</em></p>
</div>
<br>

### Восстановление из бэкапа

С локального хранилища:
```bash
/project41/backup/restore-script.sh имя_файла_бэкапа.tar.gz
```

С удаленного ресурса:
```bash
/project41/backup/restore-script.sh имя_файла_бэкапа.tar.gz "" yandex
```

При восстановлении скрипт попросит подтверждения перед:
1. Заменой конфигурационных файлов
2. Восстановлением Docker volumes (эта операция требует остановки соответствующих контейнеров)

## Принцип работы скриптов

### Как работает скрипт бэкапа (backup-script.sh)

Скрипт выполняет следующие операции:

1. **Подготовительный этап**
   - Создает уникальную временную директорию для сборки данных (`/tmp/proj41_backup_TIMESTAMP`)
   - Проверяет наличие необходимых каталогов и инструментов

2. **Сбор конфигурационных файлов**
   - Копирует файлы из Jupiter, Mongo и Monitoring/configs
   - Сохраняет структуру директорий для правильного восстановления

3. **Бэкап Docker volumes**
   - Для каждого Docker volume создается временный контейнер Ubuntu
   - Контейнер монтирует volume как `/data` и директорию для бэкапа как `/backup`
   - Создается tar-архив содержимого volume
   - Это "горячий бэкап" - не требует остановки основных контейнеров

4. **Бэкап MongoDB** (если запущен MongoDB)
   - Запускает mongodump внутри контейнера MongoDB
   - Копирует созданный дамп во временную директорию
   - Удаляет временные файлы из контейнера

5. **Создание архива**
   - Создает зашифрованный 7z-архив из всех собранных данных
   - Защищает архив паролем, включая шифрование имен файлов

6. **Сохранение и отправка**
   - Копирует архив в локальное хранилище (`/project41/backup/archives/`)
   - Загружает архив на удаленный ресурс через rclone

7. **Очистка и ротация**
   - Удаляет временные файлы
   - Выполняет ротацию старых бэкапов

### Как работает скрипт восстановления (restore-script.sh)

1. **Подготовка**
   - Создает временную директорию для работы
   - Определяет источник данных (локальный или удаленный ресурс)

2. **Получение архива**
   - При восстановлении с удаленного ресурса: скачивает архив через rclone
   - При локальном восстановлении: копирует архив во временную директорию

3. **Распаковка**
   - Распаковывает архив с помощью 7z, используя заданный пароль
   - Проверяет успешность распаковки

4. **Восстановление конфигураций**
   - По запросу пользователя восстанавливает конфигурационные файлы
   - Копирует файлы в соответствующие директории проекта

5. **Восстановление Docker volumes**
   - Требует отдельного подтверждения пользователя
   - Для каждого volume:
     - Останавливает связанные контейнеры
     - Создает volume, если он не существует
     - Восстанавливает данные через временный контейнер
     - Перезапускает контейнеры

6. **Восстановление MongoDB**
   - При наличии дампа в бэкапе, копирует его в контейнер MongoDB
   - Запускает mongorestore для восстановления базы

7. **Завершение**
   - Удаляет временные файлы
   - Выводит сообщение об успешном восстановлении

## Настройка ротации бэкапов

По умолчанию система хранит только 2 последние резервные копии как на локальном сервере, так и на удаленном ресурсе. Вы можете изменить это количество изменив его в скрипте.

### Изменение количества хранимых бэкапов

1. Откройте скрипт бэкапа:
```bash
nano /project41/backup/backup-script.sh
```

2. Найдите строку:
```bash
MAX_BACKUPS=2
```

3. Измените значение на нужное (например, 5 копий):
```bash
MAX_BACKUPS=5
```

4. Сохраните файл (Ctrl+O, затем Enter) и закройте редактор (Ctrl+X)

### Отключение ротации

Если вы хотите хранить все бэкапы без ротации:

1. Откройте скрипт бэкапа:
```bash
nano /project41/backup/backup-script.sh
```

2. Найдите и закомментируйте блоки кода, отвечающие за ротацию:

```bash
# Закомментируйте этот блок для отключения локальной ротации
# if [ "$LOCAL_BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
#     # Get the oldest backup and delete it
#     OLDEST_LOCAL_BACKUP=$(ls -1t "$LOCAL_BACKUP_DIR"/${BACKUP_NAME}_*.tar.gz | tail -n +$((MAX_BACKUPS + 1)))
#     for backup in $OLDEST_LOCAL_BACKUP; do
#         log "Deleting old local backup: $backup"
#         rm "$backup"
#     done
# fi
```

И аналогичный блок для ротации на удаленном ресурсе.

### Раздельные настройки для локальных и облачных бэкапов

Если вы хотите хранить разное количество бэкапов локально и в облаке:

1. Откройте скрипт бэкапа:
```bash
nano /project41/backup/backup-script.sh
```

2. Добавьте дополнительную переменную:
```bash
# Number of backups to keep locally
LOCAL_MAX_BACKUPS=2

# Number of backups to keep on Yandex Disk
REMOTE_MAX_BACKUPS=5
```

3. Измените соответствующие блоки кода, заменив `MAX_BACKUPS` на `LOCAL_MAX_BACKUPS` для локальной ротации и на `REMOTE_MAX_BACKUPS` для ротации на удаленном ресурсе.

### Настройка разной частоты бэкапов

Если вы хотите делать бэкапы чаще или реже, измените запись в crontab:

```bash
# Ежедневно в 2:00
0 2 * * * /project41/backup/backup-script.sh /project41/backup/logs/backup.log

# Раз в неделю (каждое воскресенье) в 3:00
0 3 * * 0 /project41/backup/backup-script.sh /project41/backup/logs/backup.log

# Два раза в день (в 2:00 и 14:00)
0 2,14 * * * /project41/backup/backup-script.sh /project41/backup/logs/backup.log
```

## Мониторинг и проверка

### Проверка журналов

```bash
cat /project41/backup/logs/backup.log
```

### Проверка локальных бэкапов

```bash
ls -la /project41/backup/archives/
```

<div align="top">
  <a href="#top">↑ Наверх</a>
</div>