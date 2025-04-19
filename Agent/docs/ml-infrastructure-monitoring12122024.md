# ML Infrastructure - Monitoring & Resources
*Version 1.3 от 12.12.2024*

## Содержание
1. [Общий мониторинг системы](#общий-мониторинг-системы)
2. [GPU мониторинг и управление](#gpu-мониторинг-и-управление)
3. [Мониторинг сервисов](#мониторинг-сервисов)
4. [Grafana дашборды](#grafana-дашборды)
5. [Prometheus метрики](#prometheus-метрики)
6. [Логирование](#логирование)
7. [Оптимизация производительности](#оптимизация-производительности)

## Общий мониторинг системы

### Системные ресурсы
```python
def monitor_system_resources():
    """Комплексный мониторинг системных ресурсов"""
    import psutil
    import subprocess
    
    # CPU Usage
    cpu_percent = psutil.cpu_percent(interval=1, percpu=True)
    print("CPU Usage per core:", cpu_percent)
    
    # Memory Usage
    memory = psutil.virtual_memory()
    print(f"\nMemory Usage: {memory.percent}%")
    print(f"Available Memory: {memory.available/1024/1024/1024:.2f} GB")
    
    # GPU Usage
    gpu_info = subprocess.run(
        ['nvidia-smi', '--query-gpu=utilization.gpu,memory.used,temperature.gpu',
         '--format=csv,noheader,nounits'],
        stdout=subprocess.PIPE,
        text=True
    )
    gpu_util, gpu_mem, gpu_temp = map(float, gpu_info.stdout.split(','))
    print(f"\nGPU Utilization: {gpu_util}%")
    print(f"GPU Memory Used: {gpu_mem} MB")
    print(f"GPU Temperature: {gpu_temp}°C")
```

### Командная строка
```bash
# Базовая информация о системе
top
htop
free -h
df -h

# Сетевые подключения
netstat -tulpn
ss -tunlp

# Docker контейнеры
docker stats
docker ps -a
```

### Мониторинг процессов
```python
def check_processes():
    """Проверка процессов и их ресурсов"""
    import psutil
    
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info']):
        try:
            print(f"Process: {proc.info['name']}")
            print(f"CPU: {proc.info['cpu_percent']}%")
            print(f"Memory: {proc.info['memory_info'].rss / 1024 / 1024:.2f} MB")
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
```

## GPU мониторинг и управление

### Мониторинг GPU
```python
def monitor_gpu_usage():
    """Мониторинг использования GPU из Python"""
    try:
        import subprocess
        # Базовая информация
        result = subprocess.run(['nvidia-smi'], stdout=subprocess.PIPE, text=True)
        print("GPU Status:")
        print(result.stdout)
        
        # Информация о процессах
        result = subprocess.run(
            ['nvidia-smi', 'pmon', '-i', '0'], 
            stdout=subprocess.PIPE, 
            text=True
        )
        print("\nProcess Monitor:")
        print(result.stdout)
    except Exception as e:
        print(f"Error monitoring GPU: {e}")
```

### Живой мониторинг
```python
def live_monitor(interval=5, duration=60):
    """
    Живой мониторинг GPU
    interval: интервал обновления в секундах
    duration: общее время мониторинга в секундах
    """
    from IPython.display import clear_output
    import time
    
    start_time = time.time()
    while time.time() - start_time < duration:
        clear_output(wait=True)
        monitor_gpu_usage()
        time.sleep(interval)
```

### Управление памятью GPU
```python
def clear_gpu_memory():
    """Полная очистка памяти GPU"""
    import gc
    
    # TensorFlow
    try:
        import tensorflow as tf
        tf.keras.backend.clear_session()
    except ImportError:
        pass
    
    # PyTorch
    try:
        import torch
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
            torch.cuda.synchronize()
    except ImportError:
        pass
    
    # Общая очистка
    gc.collect()
    
    # Проверка результата
    monitor_gpu_usage()
```

### Оптимальные размеры батчей
- CNN: 32-256
- Transformer модели: 8-32
- RNN: 16-128
- Saiga LLM: max 8-16

## Мониторинг сервисов

### Docker контейнеры
```bash
# Статус контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Использование ресурсов
docker stats --no-stream

# Логи контейнера
docker logs -f [container_name]
```

### Проверка здоровья сервисов
```bash
# PostgreSQL
docker exec -it ml_postgres pg_isready

# Grafana
curl http://localhost:your_port/api/health

# Prometheus
curl http://localhost:your_port/-/healthy

# Qdrant
curl http://localhost:your_port/health
```

### API мониторинг
```python
def check_api_health():
    """Проверка здоровья API сервисов"""
    import requests
    import json
    
    endpoints = {
        'saiga': 'http://localhost:your_port/v1/models',
        'qdrant': 'http://localhost:your_port/collections',
        'project_api': 'http://localhost:your_port/health'
    }
    
    for name, url in endpoints.items():
        try:
            response = requests.get(url)
            print(f"{name}: {response.status_code}")
        except Exception as e:
            print(f"{name}: Error - {e}")
```

## Grafana дашборды

### System Overview Dashboard
```javascript
// Панели дашборда
{
  "panels": [
    {
      "title": "CPU Usage",
      "type": "graph",
      "datasource": "Prometheus",
      "targets": [
        {
          "expr": "rate(node_cpu_seconds_total{mode='user'}[1m])"
        }
      ]
    },
    {
      "title": "Memory Usage",
      "type": "graph",
      "targets": [
        {
          "expr": "node_memory_MemTotal_bytes - node_memory_MemFree_bytes"
        }
      ]
    },
    {
      "title": "GPU Metrics",
      "type": "graph",
      "targets": [
        {
          "expr": "DCGM_FI_DEV_GPU_UTIL"
        }
      ]
    }
  ]
}
```

### Saiga Dashboard
```javascript
{
  "panels": [
    {
      "title": "Request Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(saiga_requests_total[5m])"
        }
      ]
    },
    {
      "title": "Response Time",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(saiga_response_time_seconds_sum[5m])/rate(saiga_response_time_seconds_count[5m])"
        }
      ]
    },
    {
      "title": "GPU Memory",
      "type": "graph",
      "targets": [
        {
          "expr": "saiga_gpu_memory_usage_bytes"
        }
      ]
    }
  ]
}
```

### Qdrant Dashboard
```javascript
{
  "panels": [
    {
      "title": "Query Performance",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(qdrant_requests_total[5m])"
        }
      ]
    },
    {
      "title": "Collection Stats",
      "type": "stat",
      "targets": [
        {
          "expr": "qdrant_collections_total"
        }
      ]
    }
  ]
}
```

## Prometheus метрики

### Node Metrics
```yaml
# node-exporter метрики
- node_cpu_seconds_total
- node_memory_MemTotal_bytes
- node_memory_MemFree_bytes
- node_filesystem_size_bytes
- node_network_receive_bytes_total
```

### GPU Metrics
```yaml
# DCGM метрики
- DCGM_FI_DEV_GPU_UTIL
- DCGM_FI_DEV_MEM_COPY_UTIL
- DCGM_FI_DEV_MEMORY_TEMP
- DCGM_FI_DEV_POWER_USAGE
```

### Application Metrics
```yaml
# Saiga метрики
- saiga_requests_total
- saiga_response_time_seconds
- saiga_tokens_total
- saiga_gpu_memory_usage_bytes

# Qdrant метрики
- qdrant_requests_total
- qdrant_collections_total
- qdrant_points_total
```

## Логирование

### Системные логи
```bash
# Системные журналы
journalctl -u docker.service
journalctl -u prometheus-node-exporter.service

# Docker логи
docker logs [container] --since 1h
```

### Настройка логирования
```yaml
# Docker logging
logging:
  driver: "json-file"
  options:
    max-size: "100m"
    max-file: "3"
```

### Python логирование
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
```

## Оптимизация производительности

### GPU оптимизация
1. Регулярная очистка памяти
2. Использование контекстных менеджеров
3. Оптимальные размеры батчей
4. Мониторинг температуры

### Database оптимизация
1. PostgreSQL настройки:
```ini
shared_buffers = 256MB
work_mem = 16MB
maintenance_work_mem = 128MB
effective_cache_size = 768MB
```

2. Qdrant оптимизация:
```yaml
storage:
  optimize_storage_on_create: true
  performance:
    memmap_threshold: 10000
```

