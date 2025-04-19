# ML Infrastructure - Technical Specifications
*Version 1.3 от 12.12.2024*

## Содержание
1. [Deep Learning и ML библиотеки](#deep-learning-и-ml-библиотеки)
2. [LangChain экосистема](#langchain-экосистема)
3. [Web сервисы и API](#web-сервисы-и-api)
4. [Системные компоненты](#системные-компоненты)
5. [GPU конфигурация](#gpu-конфигурация)
6. [Docker компоненты](#docker-компоненты)

## Deep Learning и ML библиотеки

### Deep Learning фреймворки
```python
tensorflow==2.18.0
torch==2.5.1
torchvision==0.20.1
torchaudio==2.5.1
keras==3.6.0

# CUDA компоненты
nvidia-cuda-nvrtc-cu12==12.1.105
nvidia-cuda-runtime-cu12==12.1.105
nvidia-cuda-cupti-cu12==12.1.105
nvidia-cudnn-cu12==8.9.2.26
nvidia-cublas-cu12==12.1.3.1
nvidia-cufft-cu12==11.0.2.54
nvidia-curand-cu12==10.3.2.106
nvidia-cusolver-cu12==11.4.5.107
nvidia-cusparse-cu12==12.1.0.106
nvidia-nccl-cu12==2.18.1
nvidia-nvtx-cu12==12.1.105
```

### ML библиотеки
```python
scikit-learn==1.3.1
scipy==1.11.3
numpy==1.26.4
pandas==2.1.1
```

### NLP и векторные операции
```python
transformers==4.46.2
sentence-transformers==3.2.1
huggingface-hub==0.26.2
nltk==3.8.1
pyspellchecker==0.7.2
stanza==1.5.1
spacy==3.7.2
thinc==8.2.1
sentencepiece==0.1.99
num2words==0.5.13
pymorphy2==0.9.1
```

### Языковые модели
```python
# Spacy модели
ru_core_news_sm @ https://github.com/explosion/spacy-models/releases/download/ru_core_news_sm-3.7.0/ru_core_news_sm-3.7.0.tar.gz

# Nemo
nemo_toolkit[all]==1.22.0
apex==0.1
```

## LangChain экосистема
```python
langchain-qdrant==0.2.0
langchain-core==0.3.15
langchain-experimental==0.0.43
qdrant-client==1.12.1
```

## Web сервисы и API

### Web фреймворки
```python
fastapi==0.104.1
uvicorn==0.24.0
flask==3.0.0
flask-cors==4.0.0
flask-socketio==5.3.6
```

### Очереди и кэширование
```python
celery==5.3.5
kombu==5.3.3
redis==5.0.1
```

### Мониторинг и метрики
```python
prometheus-client==0.17.1
GPUtil==1.4.0
psutil
```

### Визуализация
```python
matplotlib==3.8.0
seaborn==0.13.0
plotly==3.8.0
```

## Системные компоненты

### PostgreSQL
- Version: 15
- Extensions:
  ```sql
  psycopg2-binary==2.9.9
  sqlalchemy
  ```

### Qdrant
- Version: 1.12.3
- API Version: v1.12.0
- Storage Config:
  ```yaml
  storage:
    storage_path: /qdrant/storage
  service:
    http_port: 6333
    grpc_port: 6334
  ```

### Saiga LLM
- Model: NightForger/saiga_nemo_12b-GPTQ
- Framework: vLLM
- Requirements:
  ```python
  vllm
  transformers
  accelerate
  ```

## GPU конфигурация

### Характеристики
- Model: NVIDIA GeForce RTX 4090
- Memory: 24GB GDDR6X
- Architecture: Ada Lovelace
- CUDA Cores: 16384

### CUDA конфигурация
```bash
CUDA Version: 12.6
Driver Version: 560.35.03
NVIDIA-SMI: 560.35.03
```

### GPU топология
```
GPU0	 X 	0-27	0		N/A
Legend:
  X    = Self
  SYS  = Connection traversing PCIe as well as the SMP interconnect between NUMA nodes
  NODE = Connection traversing PCIe as well as the interconnect between PCIe Host Bridges
  PHB  = Connection traversing PCIe as well as a PCIe Host Bridge
  PXB  = Connection traversing multiple PCIe bridges
  PIX  = Connection traversing a single PCIe bridge
  NV#  = Connection traversing bonded NVLinks
```

## Docker компоненты

### Networks
```yaml
mlopsnew:
  driver: bridge
  ipam:
    config:
      - subnet: 172.22.0.0/16
        gateway: 172.22.0.1

agent_default:
  driver: bridge
  ipam:
    config:
      - subnet: 172.20.0.0/16
        gateway: 172.20.0.1
```

### Volumes
```yaml
volumes:
  grafana_data_new
  prometheus_data_new
  qdrant_storage_new
  postgres_data
```

### Logging
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "100m"
    max-file: "3"
```

## Требования к системе

### Минимальные требования
- CPU: 16+ ядер
- RAM: 64GB+
- GPU: NVIDIA с 16GB+ VRAM
- Storage: 500GB+ NVMe

### Рекомендуемые требования
- CPU: 32+ ядер
- RAM: 128GB+
- GPU: NVIDIA RTX 4090 (24GB)
- Storage: 1.5TB+ NVMe

### Сетевые требования
- 10Gbps внутренняя сеть
- Публичный IP для внешнего доступа
- Открытые порты:
  - your_port
  - your_port
  - your_port

## Дополнительная информация

### Зависимости окружения
- Ubuntu 22.04 LTS
- Docker 24.0+
- NVIDIA Container Toolkit
- Python 3.10+

### Мониторинг ресурсов
- Prometheus endpoints:
  - /metrics для каждого сервиса
  - node-exporter для системных метрик
  - dcgm-exporter для GPU метрик

### Рекомендации по обновлению
- Регулярное обновление CUDA драйверов
- Проверка совместимости библиотек
- Тестирование на staging среде
- Создание резервных копий перед обновлением