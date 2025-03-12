# Ответы на вопросы: Hive, YARN, HUE, Spark History, Airflow

## Что такое Hive?

**Hive** — это инструмент, который позволяет писать SQL-запросы для обработки больших данных в Hadoop. По сути, это надстройка над Hadoop, которая превращает сложные распределенные вычисления в привычные SQL-запросы.

**Ключевые моменты:**
- Позволяет аналитикам, не знающим Java, работать с данными в Hadoop
- Запросы на HiveQL (похож на SQL) преобразуются в задачи MapReduce, Tez или Spark
- Хранит метаданные (схемы таблиц) в специальной базе данных
- Подходит для аналитических запросов, но не для оперативной обработки транзакций

## В чем разница бакетирования и партицирования в Hive?

Это два способа организации данных, которые ускоряют запросы, но работают по-разному:

**Партиционирование:**
- Делит таблицу на части по значению определенного столбца
- Каждая партиция — отдельная папка на диске
- Хорошо для фильтрации по полям с небольшим количеством уникальных значений (дата, регион)
- Например: `/sales/year=2023/month=03/data.csv`

**Бакетирование:**
- Распределяет данные на фиксированное число "корзин" (бакетов) через хеш-функцию
- Все бакеты одного размера
- Хорошо для соединения таблиц и работы с полями, имеющими много уникальных значений (ID пользователя)
- Хранит каждый бакет в отдельном файле

**Отличия:**
- Партиции создают физически разные папки, бакеты — разные файлы в одной папке
- Партиций может быть много (тысячи), бакетов обычно немного (десятки)
- Партиции задаются вручную при загрузке данных, бакеты распределяются автоматически

## Что такое YARN?

**YARN** (Yet Another Resource Negotiator) — это система управления ресурсами в кластере Hadoop. Это как "диспетчер", который решает, кому и сколько ресурсов (CPU, память) выделить в кластере.

**Простыми словами:**
- Принимает заявки на выполнение задач от программ (Spark, MapReduce)
- Решает, на каких узлах кластера запустить задачи
- Следит за выполнением задач и распределением ресурсов
- Позволяет запускать разные типы приложений на одном кластере

**Основные компоненты:**
- **ResourceManager** — главный координатор (один на кластер)
- **NodeManager** — агент на каждом узле кластера
- **ApplicationMaster** — координатор для каждого приложения
- **Container** — выделенные ресурсы для выполнения задачи

## Какие параметры прописываются в Spark-сессию при использовании YARN?

При настройке Spark для работы с YARN указываются параметры, определяющие, как Spark будет использовать ресурсы кластера:

**Базовые параметры:**
- `master` — указывает использовать YARN (`"yarn"`)
- `deployMode` — режим запуска (`"cluster"` или `"client"`)

**Параметры ресурсов:**
- `executor.instances` — количество исполнителей (executors)
- `executor.memory` — память для каждого исполнителя
- `executor.cores` — количество ядер для каждого исполнителя
- `driver.memory` — память для драйвера
- `driver.cores` — ядра для драйвера

**Параметры YARN:**
- `yarn.queue` — очередь YARN для отправки задачи
- `dynamicAllocation.enabled` — разрешить динамически менять количество исполнителей
- `yarn.am.memory` — память для ApplicationMaster

**Пример простой настройки:**
```python
spark = SparkSession.builder \
    .appName("МоёПриложение") \
    .master("yarn") \
    .config("spark.executor.memory", "4g") \
    .config("spark.executor.instances", "5") \
    .config("spark.executor.cores", "2") \
    .config("spark.yarn.queue", "default") \
    .getOrCreate()
```

## Как можно выгружать логи в YARN и что они покажут?

**Способы получения логов:**
- **Через веб-интерфейс YARN** — обычно по адресу http://yarn-server:8088
- **Командная строка:** `yarn logs -applicationId application_id`
- **Агрегированные логи в HDFS** — если настроена агрегация логов

**Что показывают логи:**
- Информацию о запуске и работе приложения
- Сведения о выделенных ресурсах и контейнерах
- Стандартные выводы программы (stdout, stderr)
- Ошибки и исключения
- Метрики производительности

**Типичное использование:**
1. Найти ID приложения в веб-интерфейсе или через `yarn application -list`
2. Получить логи: `yarn logs -applicationId application_1234567890_0001`
3. Искать ошибки или проблемы в выводе

## Для чего используют HUE?

**HUE** (Hadoop User Experience) — это веб-интерфейс для работы с экосистемой Hadoop, который делает работу с большими данными доступнее для обычных пользователей.

**Основные функции:**
- **SQL-редактор** — для запросов к Hive, Impala, SparkSQL
- **Файловый браузер** — просмотр и управление файлами в HDFS
- **Редактор данных** — работа с таблицами и метаданными
- **Планировщик** — создание и запуск рабочих процессов
- **Поиск и аналитика** — дашборды и визуализация данных

**Преимущества:**
- Работа с данными без знания командной строки
- Единый интерфейс для разных компонентов Hadoop
- Совместная работа и обмен запросами
- Визуализация результатов запросов

## Что можно увидеть в Spark History?

**Spark History Server** — это веб-интерфейс для просмотра информации о выполненных Spark-приложениях. Он помогает анализировать и отлаживать Spark-задачи.

**Основная информация в интерфейсе:**
- **Список приложений** — все запущенные Spark-задачи, их статус и продолжительность
- **Задания (Jobs)** — высокоуровневые операции в приложении
- **Стадии (Stages)** — части задания, которые выполняются параллельно
- **Задачи (Tasks)** — отдельные единицы работы в стадии
- **Хранилище (Storage)** — информация о кешированных данных
- **Среда (Environment)** — настройки Spark-приложения
- **Исполнители (Executors)** — рабочие процессы, выполняющие задачи

**Полезные визуализации:**
- График выполнения задач
- Визуализация DAG (направленного ациклического графа)
- Временная шкала выполнения
- Статистика использования ресурсов

## Что такое DAG?

**DAG** (Directed Acyclic Graph) — направленный ациклический граф, который показывает последовательность операций и зависимости между ними.

**В контексте Spark:**
- Представляет план выполнения программы
- Узлы — это операции (map, filter, join)
- Дуги показывают, как данные передаются между операциями
- Помогает Spark оптимизировать выполнение задачи

**В контексте Airflow:**
- Представляет рабочий процесс (workflow)
- Узлы — это задачи
- Дуги показывают зависимости между задачами
- Определяет порядок выполнения задач

**Свойства DAG:**
- **Направленный** — связи имеют направление (от одной операции к другой)
- **Ациклический** — нет циклов, операции не могут зависеть от своих результатов
- **Граф** — структура из узлов и связей

## Какие основные параметры прописываются в Airflow?

**Airflow** — это платформа для планирования и мониторинга рабочих процессов. Основные параметры:

**Параметры на уровне системы** (airflow.cfg):
- `dags_folder` — путь к директории с DAG-файлами
- `executor` — тип исполнителя (SequentialExecutor, LocalExecutor, CeleryExecutor)
- `parallelism` — максимальное количество одновременно выполняемых задач
- `default_timezone` — часовой пояс по умолчанию

**Параметры на уровне DAG:**
- `dag_id` — уникальный идентификатор DAG
- `schedule_interval` — расписание запуска (cron-выражение или предустановка, например: @daily)
- `start_date` — дата начала планирования
- `catchup` — выполнять ли пропущенные запуски
- `tags` — метки для фильтрации в интерфейсе

**Параметры для задач:**
- `owner` — владелец задачи
- `retries` — количество повторных попыток при ошибке
- `retry_delay` — задержка между повторами
- `depends_on_past` — зависимость от успешного выполнения прошлого запуска
- `execution_timeout` — максимальное время выполнения

**Пример простого DAG:**
```python
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'simple_example',
    default_args=default_args,
    schedule_interval='@daily',
    catchup=False,
)

task = BashOperator(
    task_id='print_date',
    bash_command='date',
    dag=dag,
)
```

## Что такое bash оператор в Airflow?

**BashOperator** — это тип задачи в Airflow, который выполняет команды оболочки Bash.

**Основные особенности:**
- Выполняет bash-команды или скрипты
- Возвращает результат выполнения (успех или ошибка)
- Может использовать шаблоны для динамического формирования команд

**Параметры:**
- `bash_command` — команда для выполнения
- `env` — переменные окружения
- `output_encoding` — кодировка для вывода

**Пример использования:**
```python
from airflow.operators.bash import BashOperator

# Простая команда
task = BashOperator(
    task_id='print_date',
    bash_command='date',
    dag=dag,
)

# С переменными окружения
task_with_env = BashOperator(
    task_id='echo_path',
    bash_command='echo $MY_PATH',
    env={'MY_PATH': '/usr/local/bin'},
    dag=dag,
)

# С шаблоном (переменной)
task_with_template = BashOperator(
    task_id='print_execution_date',
    bash_command='echo "Дата запуска: {{ ds }}"',
    dag=dag,
)
```

## Что такое файл requirements.txt и как его в Airflow подкладывать?

**requirements.txt** — это файл, который содержит список Python-пакетов, необходимых для работы проекта.

**Структура файла:**
```
pandas==1.3.5
numpy>=1.20.0
scikit-learn
requests
```

**Как использовать в Airflow:**

1. **Общая установка** — установить пакеты в окружение Airflow:
   ```bash
   pip install -r requirements.txt
   ```

2. **Для PythonVirtualenvOperator** — создает временное окружение для задачи:
   ```python
   from airflow.operators.python import PythonVirtualenvOperator
   
   task = PythonVirtualenvOperator(
       task_id='task_in_venv',
       python_callable=my_function,
       requirements='path/to/requirements.txt',
       dag=dag,
   )
   ```

3. **Для Docker** — использовать requirements.txt в образе Docker:
   ```python
   from airflow.providers.docker.operators.docker import DockerOperator
   
   task = DockerOperator(
       task_id='docker_task',
       image='python:3.9',
       command='pip install -r /requirements.txt && python /script.py',
       volumes=['/path/to/requirements.txt:/requirements.txt'],
       dag=dag,
   )
   ```

## Какие зависимости в Airflow можно протягивать?

В Airflow "зависимости" — это способы указать, в каком порядке должны выполняться задачи.

**Основные типы зависимостей:**

1. **Простые зависимости** — одна задача после другой:
   ```python
   task1 >> task2  # task2 запустится только после успешного выполнения task1
   
   # Или альтернативная запись:
   task1.set_downstream(task2)
   task2.set_upstream(task1)
   ```

2. **Множественные зависимости:**
   ```python
   # Задача зависит от нескольких предыдущих
   [task1, task2] >> task3
   
   # Несколько задач зависят от одной
   task1 >> [task2, task3]
   
   # Более сложные схемы
   task1 >> [task2, task3]
   task3 >> task4
   ```

3. **Триггерные правила** — условия запуска задачи:
   - `all_success` (по умолчанию) — все предыдущие задачи успешны
   - `all_failed` — все предыдущие задачи завершились с ошибкой
   - `one_success` — хотя бы одна предыдущая задача успешна
   - `one_failed` — хотя бы одна предыдущая задача с ошибкой
   - `all_done` — все предыдущие задачи завершены (с ошибкой или успехом)

4. **Условное ветвление** — выбор пути на основе результатов:
   ```python
   def choose_path(**context):
       if condition:
           return 'task_a'
       else:
           return 'task_b'
   
   branch_task = BranchPythonOperator(
       task_id='branch',
       python_callable=choose_path,
       dag=dag,
   )
   
   task_a = BashOperator(...)
   task_b = BashOperator(...)
   
   branch_task >> [task_a, task_b]
   ```

## Какое время в Airflow выстраивается?

Airflow имеет особую систему времени для планирования задач:

**Основные концепции:**

1. **Execution Date (Дата выполнения)** — это логическое время, к которому относится запуск:
   - Не фактическое время запуска, а период, за который обрабатываются данные
   - В шаблонах доступна как `{{ ds }}` или `{{ execution_date }}`
   - В Airflow 2.0+ переименована в logical_date

2. **Schedule Interval (Интервал планирования)** — как часто запускать DAG:
   - Cron-выражение: '0 0 * * *' (ежедневно в полночь)
   - Предустановки: @daily, @weekly, @monthly
   - Объект timedelta: timedelta(days=1)

3. **Время запуска DAG:**
   - DAG запускается ПОСЛЕ окончания интервала
   - Например, DAG с расписанием @daily и start_date='2023-01-01' первый раз запустится '2023-01-02'
   - Этот запуск будет обрабатывать данные за '2023-01-01'

**Часовые пояса:**
- По умолчанию Airflow использует UTC
- Можно настроить другой часовой пояс в конфигурации
- Все даты выполнения хранятся в UTC, но отображаются в настроенном часовом поясе

**Пример планирования:**
- DAG с start_date='2023-01-01' и schedule='@daily'
- Первый запуск: 2023-01-02, обрабатывает данные за 2023-01-01
- Второй запуск: 2023-01-03, обрабатывает данные за 2023-01-02

## Что такое XCOM?

**XCom** (Cross-Communication) — это механизм в Airflow для передачи небольших объемов данных между задачами.

**Основные характеристики:**
- Хранит данные в базе данных Airflow
- Предназначен для небольших объемов информации (не более нескольких МБ)
- Позволяет одной задаче использовать результаты другой задачи

**Как использовать:**

1. **Отправка данных (push):**
   ```python
   def push_data(**context):
       # Явная отправка значения в XCom
       context['task_instance'].xcom_push(key='sample_key', value='sample_value')
   
   # Или автоматически через возвращаемое значение
   def return_value(**context):
       return {"status": "success", "count": 42}  # Автоматически сохранится в XCom
   ```

2. **Получение данных (pull):**
   ```python
   def use_data(**context):
       # Получение значения по ключу и ID задачи
       value = context['task_instance'].xcom_pull(
           task_ids='push_task', 
           key='sample_key'
       )
       print(f"Полученное значение: {value}")
   ```

**Практический пример:**
```python
# Задача 1: генерирует данные
def generate_data(**context):
    data = {"count": 100, "status": "ok"}
    return data  # Автоматически сохраняется в XCom

# Задача 2: использует данные
def process_data(**context):
    # Получаем данные из первой задачи
    data = context['task_instance'].xcom_pull(task_ids='generate')
    count = data["count"]
    print(f"Обработка {count} записей")

# Создание задач
generate = PythonOperator(
    task_id='generate',
    python_callable=generate_data,
    provide_context=True,
    dag=dag,
)

process = PythonOperator(
    task_id='process',
    python_callable=process_data,
    provide_context=True,
    dag=dag,
)

# Зависимость
generate >> process
```

## Что такое Connections?

**Connections** в Airflow — это способ хранения информации о подключении к внешним системам (базам данных, API, облачным сервисам).

**Преимущества:**
- Централизованное хранение учетных данных
- Безопасное хранение паролей (зашифрованы в базе данных)
- Многократное использование в разных DAG-ах

**Структура Connection:**
- `conn_id` — уникальный идентификатор подключения
- `conn_type` — тип подключения (postgres, mysql, http, aws)
- `host` — хост или URL сервера
- `schema` — схема базы данных или дополнительная информация
- `login` — имя пользователя
- `password` — пароль
- `port` — порт для подключения
- `extra` — дополнительные параметры в формате JSON

**Способы создания Connection:**

1. **Через веб-интерфейс:**
   - Admin → Connections → Create
   - Заполнить необходимые поля

2. **Через командную строку:**
   ```bash
   airflow connections add \
       --conn-id 'my_postgres' \
       --conn-type 'postgres' \
       --conn-host 'localhost' \
       --conn-login 'user' \
       --conn-password 'pass' \
       --conn-schema 'mydb' \
       --conn-port '5432'
   ```

3. **Через переменные окружения:**
   ```bash
   export AIRFLOW_CONN_MY_POSTGRES='postgres://user:pass@localhost:5432/mydb'
   ```

**Использование в задачах:**
```python
# Через Hook (рекомендуемый способ)
from airflow.hooks.postgres_hook import PostgresHook

def query_data(**context):
    pg_hook = PostgresHook(postgres_conn_id='my_postgres')
    records = pg_hook.get_records("SELECT * FROM users LIMIT 10")
    return records

task = PythonOperator(
    task_id='query_postgres',
    python_callable=query_data,
    dag=dag,
)
```

# Что такое сенсоры в Airflow?

Сенсоры в Airflow — это специальные операторы, которые ждут выполнения определенного условия перед продолжением выполнения DAG.

## Принцип работы сенсоров

1. **Периодическая проверка** — сенсор проверяет условие через заданные интервалы времени (например, каждую минуту)
2. **Ожидание** — сенсор ждет, пока условие не будет выполнено или не истечет таймаут
3. **Продолжение** — когда условие выполнено, сенсор успешно завершается, и DAG может продолжить выполнение

## Режимы работы сенсоров

1. **Режим poke** (по умолчанию):
   - Сенсор занимает слот воркера на всё время ожидания
   - Подходит для коротких ожиданий
   - Использует меньше ресурсов базы данных

2. **Режим reschedule**:
   - Освобождает слот воркера между проверками
   - Экономит ресурсы кластера при длительном ожидании
   - Рекомендуется для большинства сценариев

## Основные типы сенсоров

### 1. FileSensor
Ожидает появления файла в файловой системе:
```python
from airflow.sensors.filesystem import FileSensor

wait_for_file = FileSensor(
    task_id='wait_for_file',
    filepath='/path/to/file.csv',
    poke_interval=60,  # проверка каждую минуту
    timeout=60*60*5,   # таймаут 5 часов
    mode='reschedule',
    dag=dag,
)
```

### 2. ExternalTaskSensor
Ожидает завершения задачи в другом DAG:
```python
from airflow.sensors.external_task import ExternalTaskSensor

wait_for_other_dag = ExternalTaskSensor(
    task_id='wait_for_other_dag',
    external_dag_id='another_dag',
    external_task_id='final_task',
    allowed_states=['success'],
    mode='reschedule',
    dag=dag,
)
```

### 3. HttpSensor
Проверяет ответ от HTTP-эндпоинта:
```python
from airflow.providers.http.sensors.http import HttpSensor

check_api = HttpSensor(
    task_id='check_api',
    http_conn_id='api_conn',
    endpoint='/status',
    response_check=lambda response: response.status_code == 200,
    dag=dag,
)
```

### 4. SqlSensor
Ждет результата SQL-запроса:
```python
from airflow.providers.common.sql.sensors.sql import SqlSensor

check_data = SqlSensor(
    task_id='check_data',
    conn_id='postgres_conn',
    sql="SELECT COUNT(*) FROM orders WHERE date='{{ ds }}'",
    success=lambda cnt: cnt[0][0] > 0,  # успех если найдены записи
    dag=dag,
)
```

### 5. S3KeySensor
Проверяет наличие файла в Amazon S3:
```python
from airflow.providers.amazon.aws.sensors.s3 import S3KeySensor

wait_for_s3_file = S3KeySensor(
    task_id='wait_for_s3_file',
    bucket_name='my-bucket',
    bucket_key='data/{{ ds }}/file.csv',
    aws_conn_id='aws_default',
    dag=dag,
)
```

## Ключевые параметры всех сенсоров

- **task_id** — уникальный идентификатор задачи
- **poke_interval** — интервал между проверками (в секундах)
- **timeout** — максимальное время ожидания (в секундах)
- **mode** — режим работы ('poke' или 'reschedule')
- **soft_fail** — если True, сенсор будет помечен как skipped вместо failed при таймауте

## Практические применения сенсоров

### 1. Ожидание поступления данных
Сенсор ждет появления файла с данными, прежде чем начать обработку:
```python
wait_for_data = FileSensor(...)
process_data = PythonOperator(...)

wait_for_data >> process_data
```

### 2. Интеграция между системами
Ожидание завершения задач в других DAG перед запуском текущей задачи:
```python
wait_for_upstream = ExternalTaskSensor(...)
generate_reports = PythonOperator(...)

wait_for_upstream >> generate_reports
```

### 3. Проверка готовности API
Убедиться, что API работает перед отправкой запросов:
```python
check_api_health = HttpSensor(...)
send_requests = PythonOperator(...)

check_api_health >> send_requests
```

## Советы по работе с сенсорами

1. **Всегда устанавливайте таймаут** — чтобы избежать бесконечного ожидания
2. **Используйте режим reschedule** — для длительных ожиданий, чтобы экономить ресурсы
3. **Создайте отдельный пул** — для сенсоров, чтобы они не занимали все слоты в основном пуле
4. **Не злоупотребляйте** — используйте сенсоры только когда действительно нужно ожидание
5. **Рассмотрите soft_fail=True** — для несущественных проверок, чтобы DAG мог продолжиться
