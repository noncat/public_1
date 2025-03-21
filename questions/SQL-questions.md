# Вопросы для технического собеседования: SQL

## Содержание
- [Какие виды join'ов вы знаете и в чем их различие?](#какие-виды-joinов-вы-знаете-и-в-чем-их-различие)
- [Что такое подзапросы?](#что-такое-подзапросы)
- [Что такое оконные функции?](#что-такое-оконные-функции)
- [В чем разница оконных функций с group by?](#в-чем-разница-оконных-функций-с-group-by)
- [В чем разница group by и order by?](#в-чем-разница-group-by-и-order-by)
- [Что такое distinct?](#что-такое-distinct)
- [В чем разница union и union all?](#в-чем-разница-union-и-union-all)
- [Конструкция having, конструкция where - в чем разница?](#конструкция-having-конструкция-where---в-чем-разница)
- [Что такое limit of set?](#что-такое-limit-of-set)
- [Что такое ранжирование?](#что-такое-ранжирование)
- [Что такое команда explain?](#что-такое-команда-explain)
- [Что такое команда explain analyze?](#что-такое-команда-explain-analyze)
- [Что такое индексирование?](#что-такое-индексирование)
- [Какие бывают индексы?](#какие-бывают-индексы)
- [Почему некоторые индексы работают быстрее, а некоторые медленнее?](#почему-некоторые-индексы-работают-быстрее-а-некоторые-медленнее)
- [Как оптимизировать индексы?](#как-оптимизировать-индексы)
- [Где хранятся индексы?](#где-хранятся-индексы)
- [Как посмотреть, что на таблицу наложены индексы?](#как-посмотреть-что-на-таблицу-наложены-индексы)
- [Какие есть методы оптимизации таблиц?](#какие-есть-методы-оптимизации-таблиц)
- [Как смотреть логи запросов в различных базах данных?](#как-смотреть-логи-запросов-в-различных-базах-данных)
- [Что такое OLAP и OLTP?](#что-такое-olap-и-oltp)
- [Что такое материализованное представление и обычное представление?](#что-такое-материализованное-представление-и-обычное-представление)
- [Что такое транзакции и какие команды к ним применимы?](#что-такое-транзакции-и-какие-команды-к-ним-применимы)
- [Назовите свойства ACID](#назовите-свойства-acid)
- [Назовите первые три нормальные формы](#назовите-первые-три-нормальные-формы)

## Какие виды join'ов вы знаете и в чем их различие?

В SQL существует несколько типов JOIN-операций:

- **INNER JOIN** — возвращает только совпадающие записи из обеих таблиц.
- **LEFT JOIN** — возвращает все записи из левой таблицы и совпадающие из правой; несовпадающие поля правой заполняются NULL.
- **RIGHT JOIN** — возвращает все записи из правой таблицы и совпадающие из левой; несовпадающие поля левой заполняются NULL.
- **FULL JOIN** — возвращает все записи из обеих таблиц, заполняя NULL-ами несовпадающие поля.
- **CROSS JOIN** — декартово произведение таблиц, каждая строка одной таблицы соединяется с каждой строкой другой.
- **SELF JOIN** — соединение таблицы с самой собой (используя алиасы).
- **NATURAL JOIN** — автоматически соединяет таблицы по столбцам с одинаковыми именами.

Пример SELF JOIN:
```sql
SELECT e1.employee_name as employee, e2.employee_name as manager
FROM employees e1
JOIN employees e2 ON e1.manager_id = e2.employee_id;
```

## Что такое подзапросы?

Подзапросы (subqueries) — это запросы SQL, вложенные внутрь другого SQL-запроса. Они могут возвращать одно значение, список значений или целую таблицу результатов.

Типы подзапросов:
1. Скалярные — возвращают одно значение
2. Табличные — возвращают таблицу
3. Коррелированные — ссылаются на внешний запрос

Применение: в секциях **SELECT, FROM, WHERE, HAVING** и с операторами **IN, EXISTS, ANY/ALL**.

Пример:
```sql
SELECT name FROM employees
WHERE department_id IN (SELECT id FROM departments WHERE location = 'New York');
```

## Что такое оконные функции?

Оконные функции в SQL позволяют выполнять вычисления по группе строк (окну), связанных с текущей строкой. Они дают возможность:

- Проводить агрегацию без группировки всех строк
- Получать доступ к нескольким строкам одновременно
- Вычислять скользящие агрегаты, ранги, процентили
- Сравнивать значения текущей строки с предыдущими/следующими

Ключевые компоненты: **OVER()**, **PARTITION BY** (разделение на группы), **ORDER BY** (сортировка внутри окна), оконные ограничения (**ROWS/RANGE**).

Популярные функции:
- **SUM(), AVG(), MIN(), MAX()** - агрегатные функции для подсчета суммы, среднего, минимума, максимума в окне
- **COUNT()** - подсчет строк в окне
- **ROW_NUMBER()** - присваивает уникальный номер каждой строке в окне
- **RANK()** - присваивает ранг с пропусками при совпадениях (1,2,2,4...)
- **DENSE_RANK()** - присваивает ранг без пропусков (1,2,2,3...)
- **NTILE(n)** - разделяет строки на n равных групп
- **LAG(expr, n)** - возвращает значение из предыдущей строки на n позиций назад
- **LEAD(expr, n)** - возвращает значение из следующей строки на n позиций вперед
- **FIRST_VALUE(), LAST_VALUE()** - первое/последнее значение в окне

## В чем разница оконных функций с group by?

**GROUP BY:**
- Группирует строки в единую строку результата для каждой группы
- Возвращает только одну строку для каждой группы
- Требует агрегации всех негруппированных столбцов
- Сокращает число строк в результирующем наборе

**Оконные функции:**
- Сохраняют все строки в результирующем наборе
- Выполняют вычисления по группам строк, но не объединяют их
- Позволяют иметь доступ к необработанным значениям всех строк
- Могут комбинировать агрегатные и неагрегатные значения в одном запросе

Пример GROUP BY:
```sql
SELECT department_id, AVG(salary) as avg_salary
FROM employees
GROUP BY department_id;
```

Пример оконных функций:
```sql
SELECT employee_name, department_id, salary,
       AVG(salary) OVER (PARTITION BY department_id) as avg_dept_salary
FROM employees;
```

## В чем разница group by и order by?

**GROUP BY:**
- Группирует строки с одинаковыми значениями в указанных столбцах
- Применяется для агрегации данных (с функциями SUM, AVG, COUNT и т.д.)
- Уменьшает количество строк в результирующем наборе
- Используется перед применением агрегатных функций

**ORDER BY:**
- Сортирует результирующий набор по указанным столбцам
- Не изменяет количество строк или содержимое результатов
- Влияет только на порядок вывода строк
- Применяется в последнюю очередь в логическом порядке выполнения запроса

Пример:
```sql
-- GROUP BY для агрегации
SELECT department_id, COUNT(*) as employee_count 
FROM employees 
GROUP BY department_id;

-- ORDER BY для сортировки
SELECT employee_name, salary 
FROM employees 
ORDER BY salary DESC;
```

## Что такое distinct?

**DISTINCT** — это ключевое слово SQL, которое:
- Удаляет дубликаты из результирующего набора
- Возвращает только уникальные значения или комбинации значений
- Применяется ко всем столбцам в списке SELECT
- Может значительно снизить производительность на больших наборах данных

Примеры:
```sql
-- Получить список уникальных отделов
SELECT DISTINCT department_id FROM employees;

-- Получить уникальные комбинации должностей и отделов
SELECT DISTINCT job_title, department_id FROM employees;

-- Альтернатива с GROUP BY
SELECT department_id FROM employees GROUP BY department_id;
```

## В чем разница union и union all?

**UNION:**
- Объединяет результаты двух или более SELECT-запросов
- Удаляет дублирующиеся строки из результата
- Требует сопоставления типов и количества столбцов между запросами
- Выполняет операцию сортировки для удаления дубликатов, что снижает производительность

**UNION ALL:**
- Также объединяет результаты запросов
- Сохраняет все дублирующиеся строки
- Не выполняет операцию сортировки и удаления дубликатов
- Работает быстрее, чем UNION
- Используется когда дубликаты допустимы или заведомо отсутствуют

Примеры:
```sql
-- UNION (убирает дубликаты)
SELECT employee_id FROM current_employees
UNION
SELECT employee_id FROM former_employees;

-- UNION ALL (сохраняет дубликаты)
SELECT employee_id FROM current_employees
UNION ALL
SELECT employee_id FROM former_employees;
```

## Конструкция having, конструкция where - в чем разница?

**WHERE:**
- Фильтрует строки до выполнения группировки и агрегации
- Применяется к отдельным строкам в таблице
- Не может использовать агрегатные функции (SUM, COUNT, AVG)
- Выполняется перед GROUP BY

**HAVING:**
- Фильтрует сгруппированные результаты после группировки
- Применяется к результатам агрегации
- Может использовать агрегатные функции
- Выполняется после GROUP BY

Порядок выполнения: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY

Пример:
```sql
SELECT department_id, AVG(salary) as avg_salary
FROM employees
WHERE hire_date > '2020-01-01'  -- фильтрует строки до группировки
GROUP BY department_id
HAVING AVG(salary) > 5000;  -- фильтрует группы после агрегации
```

## Что такое limit of set?

**LIMIT** — это оператор SQL, который:
- Ограничивает количество возвращаемых строк в результате запроса
- Полезен для пагинации результатов
- Часто используется совместно с ORDER BY для получения "топ-N" записей
- В разных СУБД имеет различный синтаксис:
  - MySQL, PostgreSQL, SQLite: `LIMIT количество [OFFSET смещение]`
  - Oracle: `FETCH FIRST количество ROWS ONLY`
  - SQL Server: `TOP количество` или `OFFSET смещение ROWS FETCH NEXT количество ROWS ONLY`

Примеры:
```sql
-- Получить первые 10 строк
SELECT * FROM employees LIMIT 10;

-- Пропустить первые 10 строк и получить следующие 10
SELECT * FROM employees LIMIT 10 OFFSET 10;

-- Получить 5 сотрудников с самой высокой зарплатой
SELECT * FROM employees ORDER BY salary DESC LIMIT 5;
```

## Что такое ранжирование?

Ранжирование в SQL — это присвоение порядковых номеров строкам в результирующем наборе на основе определенных условий сортировки. Реализуется с помощью оконных функций:

- **ROW_NUMBER()** — уникальные последовательные числа для каждой строки (1, 2, 3, 4...)
- **RANK()** — одинаковый ранг для строк с равными значениями, с пропусками в последовательности (1, 2, 2, 4...)
- **DENSE_RANK()** — одинаковый ранг для строк с равными значениями, без пропусков (1, 2, 2, 3...)
- **NTILE(n)** — разделяет строки на n приблизительно равных групп, нумеруя каждую группу

Пример:
```sql
SELECT 
    employee_name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as row_num,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dense_rank
FROM employees;
```

## Что такое команда explain?

**EXPLAIN** — это команда, которая:
- Показывает план выполнения запроса, выбранный оптимизатором СУБД
- Не выполняет сам запрос, а только отображает его план
- Помогает выявить неоптимальные запросы и потенциальные узкие места
- Показывает информацию о том, как база данных будет выполнять запрос:
  - Какие индексы будут использованы
  - Какие методы доступа к данным будут применены (полное сканирование, индексное сканирование)
  - Порядок соединения таблиц
  - Предполагаемое количество обрабатываемых строк

Пример:
```sql
EXPLAIN SELECT * FROM employees WHERE department_id = 5;
```

Результат в PostgreSQL может выглядеть так:
```
Index Scan using idx_employees_dept on employees
  Index Cond: (department_id = 5)
```

## Что такое команда explain analyze?

**EXPLAIN ANALYZE** — расширение команды EXPLAIN, которое:
- Фактически выполняет запрос (а не только показывает план)
- Собирает реальные метрики выполнения (время, количество строк)
- Сравнивает оценки оптимизатора с реальными показателями
- Даёт более точную информацию о производительности запроса
- Полезно для отладки сложных запросов и выявления расхождений между ожидаемой и реальной производительностью

Пример:
```sql
EXPLAIN ANALYZE SELECT e.employee_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE e.salary > 5000;
```

Результат содержит план запроса с фактическим временем выполнения каждого шага, количеством просканированных строк и другими деталями выполнения.

## Что такое индексирование?

Индексирование — это метод оптимизации базы данных, который:
- Ускоряет поиск, сортировку и выборку данных
- Создаёт отдельную структуру данных (индекс), содержащую отсортированные значения индексируемых столбцов и указатели на соответствующие строки
- Работает по принципу, аналогичному алфавитному указателю в книге
- Ускоряет операции SELECT, но замедляет INSERT, UPDATE, DELETE (из-за необходимости обновления индексов)
- Требует дополнительное дисковое пространство для хранения индексных структур

Индексы особенно эффективны для:
- Столбцов, часто используемых в предикатах WHERE
- Столбцов, используемых в JOIN-операциях
- Столбцов, часто применяемых в ORDER BY и GROUP BY

Создание индекса:
```sql
CREATE INDEX idx_employees_dept ON employees(department_id);
```

## Какие бывают индексы?

Основные типы индексов в СУБД:

1. **B-Tree (сбалансированное дерево)** — стандартный индекс, подходит для большинства случаев:
   - Поддерживает =, <, >, <=, >=, BETWEEN, LIKE (без начального %)
   - Эффективен для поиска диапазона и точных совпадений

2. **Hash (хеш)** — быстрый для точного соответствия, но не для диапазонов:
   - Поддерживает только операции равенства (=)
   - Быстрее B-Tree для точных совпадений
   - Не поддерживает сортировку и поиск по диапазону

3. **Bitmap** — эффективен для столбцов с небольшим количеством различных значений:
   - Хорошо работает для столбцов с низкой кардинальностью
   - Эффективен для операций над множествами (OR, AND)
   - Занимает меньше места, чем B-Tree

4. **GiST (Generalized Search Tree)** — для специализированных типов данных:
   - Используется для геопространственных данных, полнотекстового поиска
   - Поддерживает сложные операции (например, пересечение прямоугольников)

5. **Полнотекстовый индекс** — оптимизирован для поиска текста:
   - Поддерживает поиск по ключевым словам, фразам
   - Часто включает дополнительные возможности, как стемминг, ранжирование

По структуре индексы также делятся на:
- **Кластерные** — определяют физический порядок хранения данных
- **Некластерные** — не влияют на физический порядок данных
- **Составные** — включают несколько столбцов
- **Уникальные** — гарантируют уникальность значений
- **Частичные/фильтрованные** — индексируют только подмножество строк

## Почему некоторые индексы работают быстрее, а некоторые медленнее?

Эффективность индексов зависит от нескольких факторов:

1. **Тип индекса и сценарий использования**:
   - B-Tree эффективен для диапазонов, но может быть избыточен для точных совпадений
   - Hash быстр для точных совпадений, но бесполезен для диапазонов
   - Специализированные индексы (пространственные, полнотекстовые) оптимизированы для конкретных задач

2. **Селективность индекса**:
   - Высокоселективные индексы (много уникальных значений) работают быстрее
   - Низкоселективные индексы (мало уникальных значений) могут быть менее эффективны, чем полное сканирование таблицы

3. **Размер и структура данных**:
   - Меньшие индексы быстрее загружаются в память
   - Большие индексы могут не помещаться в кэш, вызывая чтение с диска

4. **Фрагментация индекса**:
   - Фрагментированные индексы медленнее из-за непоследовательного чтения
   - Требуют регулярной реорганизации/перестроения

5. **Порядок столбцов в составных индексах**:
   - Оптимальный порядок: сначала столбцы для точного соответствия, затем для диапазонов
   - Неоптимальный порядок может привести к неиспользованию части индекса

6. **Конкуренция за ресурсы**:
   - Частые изменения в таблице снижают производительность из-за обновления индексов
   - Излишнее индексирование замедляет операции изменения данных

7. **Статистика оптимизатора**:
   - Устаревшая статистика может привести к неоптимальному использованию индексов
   - Требуется регулярное обновление статистики

## Как оптимизировать индексы?

Основные стратегии оптимизации индексов:

1. **Выбор правильных столбцов для индексации**:
   - Индексировать столбцы, часто используемые в условиях WHERE, JOIN, ORDER BY, GROUP BY
   - Избегать индексирования редко используемых столбцов
   - Учитывать селективность (уникальность) значений в столбце

2. **Оптимизация составных индексов**:
   - Учитывать порядок столбцов (наиболее селективные или часто используемые в условиях равенства — в начале)
   - Создавать покрывающие индексы (включающие все столбцы запроса)
   - Соблюдать принцип "левого префикса" — начальные столбцы должны использоваться самостоятельно

3. **Регулярное обслуживание**:
   - Перестроение фрагментированных индексов
   - Обновление статистики для оптимизатора
   - Мониторинг использования индексов

4. **Удаление неиспользуемых индексов**:
   - Выявление и удаление неиспользуемых или дублирующих индексов
   - Мониторинг соотношения выгоды от индекса к затратам на его поддержание

5. **Использование частичных/фильтрованных индексов**:
   - Индексирование только подмножества данных, которые часто используются в запросах
   - Применение для таблиц с неравномерным распределением запросов

6. **Учет специфики запросов**:
   - Создание специализированных индексов под конкретные сложные запросы
   - Использование специальных типов индексов для конкретных типов данных

7. **Балансирование количества индексов**:
   - Избегать избыточного индексирования (увеличивает затраты на операции INSERT/UPDATE/DELETE)
   - Оптимизировать существующие индексы перед добавлением новых

Инструменты для оптимизации:
- Анализ планов выполнения (EXPLAIN/EXPLAIN ANALYZE)
- Мониторинг использования индексов
- Тестирование производительности до и после изменений

## Где хранятся индексы?

Индексы хранятся в базе данных следующим образом:

1. **Физическое хранение**:
   - В отдельных файлах или областях хранения, отличных от таблиц данных
   - В современных СУБД часто в отдельных табличных пространствах (tablespaces)
   - Могут располагаться на отдельных физических устройствах для оптимизации производительности

2. **Структура хранения** зависит от типа индекса:
   - B-Tree: многоуровневая древовидная структура с корневым узлом, промежуточными узлами и листовыми узлами
   - Hash: хеш-таблица с корзинами
   - Bitmap: битовые карты для каждого уникального значения
   - Специализированные индексы: собственные форматы хранения

3. **Системные каталоги**:
   - Метаданные об индексах (имя, тип, связанная таблица, столбцы) хранятся в системных таблицах
   - В PostgreSQL: pg_index, pg_class
   - В MySQL: INFORMATION_SCHEMA.STATISTICS или системные таблицы в схеме mysql
   - В Oracle: ALL_INDEXES, ALL_IND_COLUMNS

4. **Оперативная память**:
   - Часто используемые части индексов кэшируются в буферном пуле/кэше СУБД
   - Специальные настройки могут определять процент памяти, выделяемый для кэширования индексов

Важно отметить, что:
- Кластерные индексы в некоторых СУБД (например, MS SQL Server) определяют физический порядок хранения данных в таблице
- Некластерные индексы содержат указатели на физическое расположение данных
- Индексы занимают дополнительное пространство, которое нужно учитывать при планировании хранилища

## Как посмотреть, что на таблицу наложены индексы?

Способы просмотра индексов для таблицы зависят от СУБД:

**PostgreSQL**:
```sql
-- Через информационную схему
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'имя_таблицы';

-- Через системные таблицы
SELECT
    i.relname AS index_name,
    a.attname AS column_name
FROM
    pg_class t,
    pg_class i,
    pg_index ix,
    pg_attribute a
WHERE
    t.oid = ix.indrelid
    AND i.oid = ix.indexrelid
    AND a.attrelid = t.oid
    AND a.attnum = ANY(ix.indkey)
    AND t.relkind = 'r'
    AND t.relname = 'имя_таблицы'
ORDER BY
    i.relname, a.attnum;
```

**MySQL**:
```sql
-- Через информационную схему
SELECT index_name, column_name, non_unique
FROM information_schema.statistics
WHERE table_schema = 'имя_базы' AND table_name = 'имя_таблицы'
ORDER BY index_name, seq_in_index;

-- Или более просто
SHOW INDEX FROM имя_таблицы;
```

**Oracle**:
```sql
SELECT index_name, column_name, column_position
FROM all_ind_columns
WHERE table_name = 'ИМЯ_ТАБЛИЦЫ' AND table_owner = 'ВЛАДЕЛЕЦ'
ORDER BY index_name, column_position;
```

**SQL Server**:
```sql
-- Базовая информация
SELECT i.name AS index_name, COL_NAME(ic.object_id, ic.column_id) AS column_name
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic 
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('имя_таблицы');

-- Детальная информация
EXEC sp_helpindex 'имя_таблицы';
```

**SQLite**:
```sql
PRAGMA index_list('имя_таблицы');
```

Графические инструменты:
- PostgreSQL: pgAdmin, DBeaver
- MySQL: MySQL Workbench, HeidiSQL
- Oracle: SQL Developer, TOAD
- SQL Server: SQL Server Management Studio

## Какие есть методы оптимизации таблиц?

Основные методы оптимизации таблиц в СУБД:

1. **Оптимизация схемы**:
   - Нормализация/денормализация в зависимости от сценария использования
   - Выбор оптимальных типов данных (минимально необходимый размер)
   - Использование ограничений (CHECK, FOREIGN KEY, NOT NULL) для обеспечения целостности данных
   - Вертикальное/горизонтальное разделение больших таблиц

2. **Управление индексами**:
   - Создание необходимых индексов на основе анализа запросов
   - Удаление неиспользуемых и дублирующих индексов
   - Регулярное перестроение фрагментированных индексов
   - Использование покрывающих индексов для высоконагруженных запросов

3. **Партиционирование**:
   - Разделение больших таблиц на логические секции по определенному критерию (дата, регион и т.д.)
   - Ускоряет запросы, работающие только с частью данных
   - Упрощает обслуживание (обновление статистики, архивирование)

4. **Статистика и планировщик запросов**:
   - Регулярное обновление статистики таблиц для оптимизатора запросов
   - Настройка параметров оптимизатора под конкретные нагрузки
   - Анализ планов выполнения и настройка критических запросов

5. **Физическая оптимизация**:
   - Регулярная дефрагментация и перестроение таблиц (REINDEX, VACUUM, REBUILD)
   - Настройка параметров хранения (размер страниц, факторы заполнения)
   - Размещение часто используемых таблиц и индексов на быстрых носителях

6. **Материализованные представления**:
   - Создание для часто выполняемых сложных запросов
   - Настройка регулярного обновления для поддержания актуальности данных

7. **Кэширование**:
   - Настройка параметров кэширования данных и запросов
   - Использование внешних систем кэширования для часто запрашиваемых данных

## Как смотреть логи запросов в различных базах данных?

Способы просмотра логов запросов в разных СУБД:

**PostgreSQL**:
- Настройка логирования в файле postgresql.conf:
  ```
  log_statement = 'all'  # none, ddl, mod, all
  log_min_duration_statement = 0  # логировать все запросы длиннее указанного времени (мс)
  ```
- Просмотр логов:
  ```sql
  -- Для просмотра текущей активности
  SELECT * FROM pg_stat_activity;
  
  -- Для анализа медленных запросов (если установлено расширение)
  SELECT * FROM pg_stat_statements ORDER BY total_time DESC;
  ```

**MySQL**:
- Включение логирования в my.cnf:
  ```
  general_log = 1
  general_log_file = /var/log/mysql/mysql.log
  slow_query_log = 1
  slow_query_log_file = /var/log/mysql/mysql-slow.log
  long_query_time = 2
  ```
- Просмотр логов:
  ```sql
  -- Просмотр медленных запросов в таблице
  SELECT * FROM mysql.slow_log;
  
  -- Общий лог, если он настроен для записи в таблицу
  SELECT * FROM mysql.general_log;
  ```

**Oracle**:
- Настройка логирования:
  ```sql
  -- Включение трассировки SQL
  ALTER SESSION SET SQL_TRACE = TRUE;
  
  -- Настройка уровня логирования
  ALTER SYSTEM SET TIMED_STATISTICS = TRUE;
  ```
- Просмотр логов:
  ```sql
  -- Активные сессии и запросы
  SELECT * FROM v$session;
  
  -- История запросов
  SELECT * FROM v$sql ORDER BY elapsed_time DESC;
  ```

**SQL Server**:
- Настройка логирования:
  ```sql
  -- Включение расширенных событий для отслеживания запросов
  CREATE EVENT SESSION [QueryMonitoring] ON SERVER 
  ADD EVENT sqlserver.sql_statement_completed
  ADD TARGET package0.event_file(SET filename=N'C:\Logs\QueryMonitoring.xel')
  WITH (MAX_MEMORY=4096 KB, MAX_DISPATCH_LATENCY=30 SECONDS)
  GO
  
  ALTER EVENT SESSION [QueryMonitoring] ON SERVER STATE = START;
  ```
- Просмотр логов:
  ```sql
  -- Текущие запросы
  SELECT * FROM sys.dm_exec_requests r
  CROSS APPLY sys.dm_exec_sql_text(r.sql_handle);
  
  -- Анализ кэша планов для часто выполняемых запросов
  SELECT * FROM sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle)
  ORDER BY qs.total_elapsed_time DESC;
  ```

## Что такое OLAP и OLTP?

**OLTP (Online Transaction Processing)**:
- Обрабатывает большое количество коротких транзакций
- Ориентирован на операции вставки, обновления, удаления данных
- Характеризуется высокой скоростью и большим количеством параллельных пользователей
- Работает с текущими данными, обеспечивает их целостность
- Оптимизирован для операционных систем (CRM, ERP, банковские системы)
- Нормализованная схема для минимизации избыточности данных
- Обычно содержит детализированные данные
- Запросы простые и стандартизированные
- Размер базы данных: относительно небольшой (гигабайты)

**OLAP (Online Analytical Processing)**:
- Обрабатывает сложные запросы для анализа данных
- Ориентирован преимущественно на операции чтения
- Используется для бизнес-аналитики, поддержки принятия решений
- Работает с историческими (архивными) данными
- Оптимизирован для многомерного анализа (кубы данных, иерархии)
- Часто денормализованная схема (звезда, снежинка) для ускорения запросов
- Содержит агрегированные данные для разных уровней детализации
- Запросы сложные, часто нерегламентированные
- Размер базы данных: большой (терабайты и петабайты)

Основные различия:
- OLTP: быстрые транзакции, много записи, работа с текущими данными
- OLAP: сложная аналитика, преимущественно чтение, работа с историческими данными

## Что такое материализованное представление и обычное представление?

**Обычное представление (View)**:
- Виртуальная таблица, основанная на результате SQL-запроса
- Не хранит данные физически, выполняет запрос каждый раз при обращении
- Всегда отражает текущее состояние базовых таблиц
- Занимает минимум места (только определение запроса)
- Может быть обновляемым (при соблюдении определенных условий)
- Создание:
  ```sql
  CREATE VIEW view_name AS
  SELECT column1, column2, ...
  FROM table_name
  WHERE condition;
  ```

**Материализованное представление (Materialized View)**:
- Физически хранит результаты запроса как таблицу
- Данные сохраняются и не пересчитываются при каждом обращении
- Требует явного обновления для отражения изменений в базовых таблицах
- Занимает дополнительное место для хранения данных
- Обычно не обновляемое (только через пересоздание)
- Значительно ускоряет сложные запросы, особенно с агрегацией
- Создание (PostgreSQL):
  ```sql
  CREATE MATERIALIZED VIEW matview_name AS
  SELECT column1, column2, ...
  FROM table_name
  WHERE condition;
  ```
- Обновление:
  ```sql
  REFRESH MATERIALIZED VIEW matview_name;
  ```

Когда использовать:
- **Обычное представление**: для инкапсуляции логики, упрощения сложных запросов, обеспечения безопасности данных
- **Материализованное представление**: для кэширования результатов дорогостоящих запросов, повышения производительности аналитики, снижения нагрузки на сервер

## Что такое транзакции и какие команды к ним применимы?

**Транзакция** — это группа последовательных операций с базой данных, которая рассматривается как единая логическая единица работы. Транзакция либо выполняется полностью, либо не выполняется вовсе.

**Основные команды транзакций**:

1. **BEGIN** (или START TRANSACTION) — начинает новую транзакцию:
   ```sql
   BEGIN;
   -- или
   START TRANSACTION;
   ```

2. **COMMIT** — подтверждает все изменения, внесенные в рамках текущей транзакции:
   ```sql
   COMMIT;
   ```

3. **ROLLBACK** — отменяет все изменения, внесенные в рамках текущей транзакции:
   ```sql
   ROLLBACK;
   ```

4. **SAVEPOINT** — создает точку сохранения внутри транзакции, к которой можно вернуться:
   ```sql
   SAVEPOINT savepoint_name;
   ```

5. **ROLLBACK TO SAVEPOINT** — откатывает транзакцию до определенной точки сохранения:
   ```sql
   ROLLBACK TO SAVEPOINT savepoint_name;
   ```

6. **RELEASE SAVEPOINT** — удаляет точку сохранения:
   ```sql
   RELEASE SAVEPOINT savepoint_name;
   ```

7. **SET TRANSACTION** — устанавливает характеристики транзакции:
   ```sql
   SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
   ```

**Управление уровнями изоляции транзакций**:
- READ UNCOMMITTED — транзакция может видеть незафиксированные изменения других транзакций
- READ COMMITTED — транзакция видит только зафиксированные изменения других транзакций
- REPEATABLE READ — гарантирует, что если транзакция повторно читает данные, они не изменятся
- SERIALIZABLE — транзакции полностью изолированы друг от друга

Пример использования транзакции:
```sql
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE user_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE user_id = 2;
    
    -- Проверка условия
    IF (SELECT balance FROM accounts WHERE user_id = 1) < 0 THEN
        ROLLBACK;  -- Отмена транзакции при недостатке средств
    ELSE
        COMMIT;    -- Подтверждение транзакции
    END IF;
```

## Назовите свойства ACID

**ACID** — аббревиатура, описывающая ключевые гарантии транзакций в СУБД:

1. **Atomicity (Атомарность)**:
   - Транзакция выполняется как единое целое — либо полностью, либо никак
   - Если часть транзакции не выполнилась, все предыдущие операции отменяются
   - Обеспечивает, что система всегда переходит из одного целостного состояния в другое
   - Реализуется через механизмы журналирования и откатов (rollback)

2. **Consistency (Согласованность)**:
   - Транзакция переводит базу данных из одного согласованного состояния в другое
   - Все ограничения целостности (constraints) должны выполняться до и после транзакции
   - Поддерживает инвариантность бизнес-правил и структурную целостность
   - Реализуется через проверки ограничений и триггеры

3. **Isolation (Изолированность)**:
   - Конкурентные транзакции не влияют друг на друга
   - Результат параллельного выполнения транзакций эквивалентен их последовательному выполнению
   - Предотвращает аномалии конкурентного доступа (грязное чтение, неповторяемое чтение, фантомное чтение)
   - Реализуется через механизмы блокировок или многоверсионного контроля конкурентного доступа (MVCC)

4. **Durability (Долговечность)**:
   - После подтверждения (commit) транзакции изменения сохраняются в системе постоянно
   - Данные не должны быть потеряны даже при сбое системы (отключении питания и т.д.)
   - Гарантирует, что подтвержденные транзакции выживут при любых отказах
   - Реализуется через журналирование операций и синхронизацию с диском

Вместе эти свойства обеспечивают надежность и предсказуемость работы СУБД в многопользовательской среде и при возникновении ошибок.

## Назовите первые три нормальные формы

**Первые три нормальные формы** — это основные правила нормализации базы данных, которые устраняют избыточность данных и обеспечивают целостность:

### Первая нормальная форма (1NF)

**Определение**: Таблица находится в первой нормальной форме, если:
- Все атрибуты содержат только атомарные (неделимые) значения
- В таблице нет повторяющихся групп или массивов
- У каждой таблицы есть первичный ключ

**Пример нарушения 1NF**:
Таблица `Клиенты`:

| ИД_клиента | Имя     | Телефоны                   | 
|------------|---------|----------------------------|
| 1          | Иван    | 123-456-7890, 098-765-4321 |
| 2          | Мария   | 555-123-4567               |

*Проблема*: Столбец "Телефоны" содержит несколько значений в одной ячейке.

**Приведение к 1NF**:
Таблица `Клиенты`:

| ИД_клиента | Имя     |
|------------|---------|
| 1          | Иван    |
| 2          | Мария   |

Таблица `Телефоны`:

| ИД_телефона | ИД_клиента | Телефон      |
|-------------|------------|--------------|
| 1           | 1          | 123-456-7890 |
| 2           | 1          | 098-765-4321 |
| 3           | 2          | 555-123-4567 |

### Вторая нормальная форма (2NF)

**Определение**: Таблица находится во второй нормальной форме, если она:
- Уже находится в первой нормальной форме (1NF)
- Все неключевые атрибуты полностью функционально зависят от всего первичного ключа, а не от его части

**Пример нарушения 2NF**:
Таблица `Заказы_продукты`:

| ИД_заказа | ИД_продукта | Количество | Название_продукта | Цена_продукта |
|-----------|-------------|------------|-------------------|---------------|
| 1         | 101         | 2          | Ноутбук           | 50000         |
| 1         | 102         | 1          | Мышь              | 1000          |
| 2         | 101         | 1          | Ноутбук           | 50000         |

*Проблема*: Составной первичный ключ (ИД_заказа, ИД_продукта), но Название_продукта и Цена_продукта зависят только от части ключа - ИД_продукта.

**Приведение к 2NF**:
Таблица `Заказы_продукты`:

| ИД_заказа | ИД_продукта | Количество |
|-----------|-------------|------------|
| 1         | 101         | 2          |
| 1         | 102         | 1          |
| 2         | 101         | 1          |

Таблица `Продукты`:

| ИД_продукта | Название_продукта | Цена_продукта |
|-------------|-------------------|---------------|
| 101         | Ноутбук           | 50000         |
| 102         | Мышь              | 1000          |

### Третья нормальная форма (3NF)

**Определение**: Таблица находится в третьей нормальной форме, если она:
- Уже находится во второй нормальной форме (2NF)
- Нет транзитивных зависимостей — неключевые атрибуты не зависят от других неключевых атрибутов

**Пример нарушения 3NF**:
Таблица `Сотрудники`:

| ИД_сотрудника | Имя     | Отдел_ID | Название_отдела |
|---------------|---------|----------|-----------------|
| 1             | Иван    | 10       | Маркетинг       |
| 2             | Мария   | 20       | Разработка      |
| 3             | Алексей | 10       | Маркетинг       |

*Проблема*: Неключевой атрибут Название_отдела зависит от другого неключевого атрибута Отдел_ID, а не напрямую от первичного ключа ИД_сотрудника.

**Приведение к 3NF**:
Таблица `Сотрудники`:

| ИД_сотрудника | Имя     | Отдел_ID |
|---------------|---------|----------|
| 1             | Иван    | 10       |
| 2             | Мария   | 20       |
| 3             | Алексей | 10       |

Таблица `Отделы`:

| Отдел_ID | Название_отдела |
|----------|-----------------|
| 10       | Маркетинг       |
| 20       | Разработка      |

### Практическое значение нормализации

Нормализация базы данных до третьей нормальной формы обеспечивает несколько важных преимуществ:

1. **Уменьшение избыточности данных**:
   - Данные хранятся только в одном месте
   - Экономия дискового пространства
   - Упрощение обновлений данных

2. **Предотвращение аномалий**:
   - **Аномалии вставки**: невозможность добавить данные из-за отсутствия других данных
   - **Аномалии обновления**: необходимость обновлять одни и те же данные в нескольких местах
   - **Аномалии удаления**: непреднамеренная потеря данных при удалении

3. **Улучшение целостности данных**:
   - Более точное представление реальных сущностей и отношений
   - Лучшая защита от несогласованности данных
   - Более ясная структура базы данных

4. **Гибкость базы данных**:
   - Возможность расширения без нарушения существующей структуры
   - Упрощение обслуживания и изменения

### Когда нужна денормализация

Хотя нормализация имеет множество преимуществ, иногда осознанная денормализация может быть необходима:

- **Производительность**: для часто запрашиваемых данных, чтобы уменьшить количество соединений
- **OLAP-системы**: для аналитических баз данных, где важнее скорость чтения, чем обновления
- **Хранение исторических данных**: для сохранения неизменного снимка данных на определенный момент времени

### Мнемоническое правило для запоминания

Первые три нормальные формы часто помогает запоминать правило:
- **1NF**: "Каждый атрибут содержит только одно значение"
- **2NF**: "Все поля зависят от всего ключа"
- **3NF**: "Ничто не зависит от не-ключа"

Или более кратко:
- **1NF**: Атомарность
- **2NF**: Полная зависимость от ключа
- **3NF**: Нет транзитивных зависимостей
