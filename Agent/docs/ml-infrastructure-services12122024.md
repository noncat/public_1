# ML Infrastructure - Services Guide
*Version 1.3 от 12.12.2024*

## Содержание
1. [Saiga LLM Service](#saiga-llm-service)
2. [Qdrant Vector Database](#qdrant-vector-database)
3. [PostgreSQL Database](#postgresql-database)
4. [Project API Service](#project-api-service)
5. [WebBot2 Interface](#webbot2-interface)
6. [Monitoring Services](#monitoring-services)

## Saiga LLM Service

### Общая информация
- **Порт**: your_port (API), your_port (метрики)
- **Модель**: NightForger/saiga_nemo_12b-GPTQ
- **Контейнер**: saiga_saiga_1

### Docker конфигурация
```yaml
services:
  saiga:
    image: vllm/vllm-openai:latest
    runtime: nvidia
    restart: always
    environment:
      - HUGGING_FACE_HUB_TOKEN=<token>
    volumes:
      - ~/.cache/huggingface:/root/.cache/huggingface
      - ./config.py:/app/config.py
    entrypoint: []
    command: >
      python3 -m vllm.entrypoints.openai.api_server 
      --host 0.0.0.0 
      --model NightForger/saiga_nemo_12b-GPTQ 
      --max-model-len 20000 
      --port 8010 
      --trust-remote-code 
      --gpu-memory-utilization 0.95
    ports:
      - "your_port:8010"
```

### API Endpoints

#### Модель
```bash
# Информация о модели
GET /v1/models

# Пример ответа:
{
  "object": "list",
  "data": [{
    "id": "NightForger/saiga_nemo_12b-GPTQ",
    "object": "model",
    "created": 1734024720,
    "owned_by": "vllm"
  }]
}
```

#### Генерация
```bash
# Генерация текста
POST /v1/completions

# Параметры:
{
  "max_model_len": 20000,
  "temperature": 0.7,
  "top_p": 0.9,
  "presence_penalty": 0.0,
  "frequency_penalty": 0.0,
  "max_tokens": 1024
}
```

### Системный промпт
```python
SYSTEM_PROMPT = """Ты - русскоязычный автоматический ассистент. 
Твоя задача - отвечать кратко и по делу, сохраняя вежливость 
и профессионализм. Для технических тем используй точные термины. 
При работе с кодом объясняй критически важные моменты."""
```

## Qdrant Vector Database

### Основная конфигурация
- **Порты**: your_port (API), your_port (внутренний)
- **Volumes**: qdrant_storage_new
- **Контейнер**: qdrant_new

### Docker Setup
```yaml
services:
  qdrant:
    image: qdrant/qdrant:latest
    container_name: qdrant_new
    restart: unless-stopped
    ports:
      - "your_port:6333"
      - "your_port:6334"
    volumes:
      - qdrant_storage_new:/qdrant/storage
    environment:
      - QDRANT_ALLOW_RECOVERY=true
```

### Коллекции
1. **BD_curs_data**
   - База знаний курсов
   - Векторные представления учебных материалов
   - Используется для поиска релевантного контекста

2. **BD_chat_question**
   - База вопросов и ответов
   - История взаимодействий
   - Часто задаваемые вопросы

3. **BD_organization_question**
   - Организационная информация
   - Административные вопросы
   - Системные инструкции

### Пример работы с Qdrant
```python
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_qdrant import QdrantVectorStore
from contextlib import contextmanager
import gc

@contextmanager
def vector_store_session():
    """Контекстный менеджер для работы с Qdrant"""
    embeddings = HuggingFaceEmbeddings(
        model_name="deepvk/USER-bge-m3"
    )
    store = QdrantVectorStore(
        collection_name="DS_local_new2",
        embeddings=embeddings,
        url="http://qdrant:6333"
    )
    try:
        yield store
    finally:
        del store
        del embeddings
        gc.collect()

# Пример поиска
def safe_semantic_search(query, k=3, threshold=0.7):
    with vector_store_session() as vs:
        results = vs.similarity_search_with_relevance_scores(
            query=query,
            k=k
        )
        return [
            (doc.page_content, score) 
            for doc, score in results 
            if score > threshold
        ]
```

## PostgreSQL Database

### Основные параметры
- **Порт**: your_port
- **База**: ml_db
- **Пользователь**: postgres
- **Контейнер**: ml_postgres

### Docker конфигурация
```yaml
services:
  postgres:
    container_name: ml_postgres
    image: postgres:15
    ports:
      - "your_port:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: your_password
      POSTGRES_DB: ml_db
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ./data:/var/lib/postgresql/data
      - ./configs:/etc/postgresql/conf.d
      - ./backups:/backups
```

### Настройки производительности
```ini
# Основные параметры
max_connections = 100
shared_buffers = 256MB
work_mem = 16MB
maintenance_work_mem = 128MB

# WAL конфигурация
wal_buffers = 16MB
min_wal_size = 1GB
max_wal_size = 4GB
```

### Настройки доступа (pg_hba.conf)
```
# TYPE  DATABASE  USER  ADDRESS      METHOD
local   all       all                trust
host    all       all   127.0.0.1/32 md5
host    all       all   0.0.0.0/0    md5
```

### Примеры подключения
```python
# SQLAlchemy подключение
DATABASE_URL = "postgresql://postgres:your_password@ml_postgres:5432/ml_db"

# Из Docker контейнера
DATABASE_URL = "postgresql://postgres:your_password@ml_postgres:5432/ml_db"

# Внешнее подключение
DATABASE_URL = "postgresql://postgres:your_password@95.64.227.126:your_port/ml_db"
```

## Project API Service

### Основная информация
- **Порт**: your_port
- **Framework**: FastAPI
- **Контейнер**: project_api_service

### Docker конфигурация
```yaml
services:
  api_service:
    build: .
    container_name: project_api_service
    command: uvicorn api.api:app --host 0.0.0.0 --port your_port --reload
    environment:
      - CUDA_VISIBLE_DEVICES=0
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "your_port:your_port"
    volumes:
      - .:/app
```

### API структура
```python
# Основной роутинг
@app.post("/process_message")
async def process_message(message: Message, request: Request):
    data = message.model_dump()
    return await process_message_logic(data, request)

# Модель данных
class Message(BaseModel):
    message: str
    user_name: str
    course: str
```

### Процесс обработки сообщений
```python
async def process_message_logic(data, request):
    # 1. Извлечение данных
    input_text = data["message"]
    user_name = data["user_name"]
    course = data["course"]
    
    # 2. Генерация ответа
    async def response_generator():
        response_chunks = []
        data_for_history = {}
        
        try:
            # RAG System обработка
            generator = pipeline.process_message(
                client_ip, 
                input_text, 
                model_function
            )
            
            # Потоковая генерация ответа
            async for chunk in generator:
                str_chunk = str(chunk)
                response_chunks.append(str_chunk)
                yield str_chunk
                
        finally:
            # Сохранение в историю
            full_response = "".join(response_chunks)
            pipeline.add_to_history(...)
    
    # 3. Возврат потокового ответа
    return StreamingResponse(
        response_generator(), 
        media_type="text/plain"
    )
```

## WebBot2 Interface

### Основная информация
- **Порт**: your_port
- **Framework**: Flask
- **Контейнер**: webbot2

### Структура проекта
```
/webbot2/
├── app.py                 # Flask приложение
├── Dockerfile            # Docker конфигурация
├── docker-compose.yml    # Docker Compose
├── requirements.txt      # Зависимости
├── wait-for-api.sh       # Проверка API
├── static/              # Статические файлы
└── templates/           # HTML шаблоны
```

### Конфигурация WebSocket
```javascript
SOCKET_EVENTS = {
    "from_client": {
        "send_message": "Отправка сообщения"
    },
    "from_server": {
        "bot_typing": "Индикация набора",
        "bot_chunk": "Частичный ответ",
        "bot_finished": "Завершение"
    }
}
```

### API Integration
```python
API_CONFIG = {
    "base_url": "http://project_api_service:your_port",
    "endpoints": {
        "process_message": "/process_message"
    },
    "methods": ["POST"],
    "headers": {
        "Content-Type": "application/json"
    }
}
```

## Monitoring Services

### Grafana
- **Порт**: your_port
- **URL**: http://your_IP_adres:your_port
- **Доступ**: admin/admin

#### Docker конфигурация
```yaml
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana_new
    ports:
      - "your_port:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data_new:/var/lib/grafana
      - ./config/grafana/provisioning:/etc/grafana/provisioning
      - ./config/grafana/dashboards:/etc/grafana/dashboards
```

#### Основные дашборды
1. System Overview
   - CPU, Memory, Disk usage
   - Network stats
   - System load
   - GPU metrics

2. Saiga Dashboard
   - API latency
   - Request rate
   - Token usage
   - GPU utilization
   - Error rate

3. Qdrant Metrics
   - Collection stats
   - Query performance
   - Resource usage

### Prometheus
- **Порт**: your_port
- **URL**: http://your_IP_adres:your_port

#### Docker конфигурация
```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus_new
    ports:
      - "your_port:9090"
    volumes:
      - ./config/prometheus:/etc/prometheus
      - prometheus_data_new:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=7d'
```

#### Jobs конфигурация
```yaml
scrape_configs:
  - job_name: 'agent_metrics'
    metrics_path: '/metrics'
    scrape_interval: 15s
    static_configs:
      - targets: ['agent-exporter:9090']

  - job_name: 'qdrant'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['qdrant_new:6333']

  - job_name: 'saiga'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['saiga_saiga_1:8010']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter_new:9100']
```

### Экспортеры

#### Node Exporter
- **Порт**: 9101
- Системные метрики
- Resource utilization

#### DCGM Exporter
- **Порт**: 9401
- GPU метрики
- CUDA мониторинг

#### Agent Exporter
- **Порт**: 9402
- Метрики приложения
- Business logic мониторинг