# Частичная загрузка конфигурации 1С из файлов по коммиту git

## Описание

Скрипты для автоматической частичной загрузки конфигурации 1С:Предприятие из файлов, измененных от указанного git коммита до текущего состояния.

### Возможности

- ✅ Получение всех измененных файлов от указанного коммита до текущего состояния (включая незафиксированные)
- ✅ Автоматическая фильтрация файлов конфигурации (XML)
- ✅ **Поддержка BSL файлов** - автоматическое добавление XML объектов при изменении модулей
- ✅ Создание файла списка для частичной загрузки
- ✅ Выполнение команды `/LoadConfigFromFiles` с параметром `-partial`
- ✅ **Автоматическое обновление конфигурации БД** - опциональное обновление после загрузки
- ✅ **Запуск в режиме 1С:Предприятие** - автоматический запуск после загрузки
- ✅ **Поддержка навигационных ссылок** - открытие конкретного объекта после старта
- ✅ **Запуск внешних обработок** - возможность запуска обработки после старта
- ✅ Поддержка обоих форматов выгрузки (Hierarchical/Plain)
- ✅ Подробное логирование процесса
- ✅ Режим отладки

## Файлы

1. **partial-load-config.cmd** - версия для Windows (cmd)
2. **partial-load-config.ps1** - версия для PowerShell

## Требования

- Git установлен и доступен в PATH
- Платформа 1С:Предприятие 8.3
- Конфигурация выгружена в файлы (с помощью `/DumpConfigToFiles`)
- Git репозиторий с историей изменений конфигурации

## Использование

### PowerShell (рекомендуется)

```powershell
# Базовый пример
.\partial-load-config.ps1 -CommitId "a3f5b21" -InfoBasePath "C:\Bases\MyBase"

# С аутентификацией
.\partial-load-config.ps1 -CommitId "HEAD~1" `
    -InfoBaseName "MyBase" `
    -UserName "Admin" `
    -Password "password"

# С нестандартным каталогом конфигурации (например, src вместо config)
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\edt\IB\Эксперименты" `
    -ConfigDir "src" `
    -Format "Hierarchical"

# С явным указанием пути к платформе 1С
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -V8Path "C:\Program Files\1cv8\8.3.27.1859\bin\1cv8.exe" `
    -DebugMode

# С автоматическим обновлением конфигурации БД
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\edt\IB\ERP_2.5.12.73" `
    -ConfigDir "src" `
    -UserName "Администратор" `
    -UpdateDB

# С запуском в режиме 1С:Предприятие
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -RunEnterprise

# С открытием конкретного объекта
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -RunEnterprise `
    -NavigationLink "e1cib/data/Catalog.Items"

# С запуском внешней обработки
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -RunEnterprise `
    -ExternalDataProcessor "C:\DataProcessors\MyProcessor.epf"
```

### CMD

```cmd
REM Базовый пример
partial-load-config.cmd a3f5b21 /ib "C:\Bases\MyBase"

REM С аутентификацией
partial-load-config.cmd HEAD~1 /ibname "MyBase" /n Admin /p password

REM С дополнительными параметрами
partial-load-config.cmd feature/new-report ^
    /ib "C:\Bases\Test" ^
    /configdir ".\src\conf" ^
    /format Hierarchical ^
    /debug
```

## Параметры

### Обязательные

| Параметр | Описание |
|----------|----------|
| `CommitId` | Идентификатор коммита git - **точка отсчета** для получения изменений (хеш, ветка, HEAD~N и т.д.) |

### Параметры подключения к ИБ (один из двух обязателен)

| Параметр | Описание |
|----------|----------|
| `InfoBasePath` / `/ib` | Путь к файловой базе данных |
| `InfoBaseName` / `/ibname` | Имя базы из списка информационных баз |

### Дополнительные параметры

| Параметр | Значение по умолчанию | Описание |
|----------|----------------------|----------|
| `UserName` / `/n` | - | Имя пользователя 1С |
| `Password` / `/p` | - | Пароль пользователя |
| `ConfigDir` / `/configdir` | `config` | Каталог с выгруженной конфигурацией |
| `Format` / `/format` | `Hierarchical` | Формат: Hierarchical или Plain |
| `V8Path` / `/v8` | `1cv8.exe` | Путь к исполняемому файлу платформы (если не указан, ищется в PATH) |
| `OutFile` / `/out` | temp файл | Файл для вывода служебных сообщений |
| `DebugMode` / `/debug` | - | Включить режим отладки |
| `UpdateDB` | - | Автоматически обновить конфигурацию БД после загрузки |
| `RunEnterprise` | - | Запустить 1С:Предприятие после загрузки |
| `NavigationLink` | - | Навигационная ссылка для открытия объекта (требует `-RunEnterprise`) |
| `ExternalDataProcessor` | - | Путь к внешней обработке для запуска (требует `-RunEnterprise`) |

## Как это работает

1. **Получение списка файлов**
   
   Скрипт получает **все** измененные файлы от указанного коммита до текущего состояния:
   
   ```bash
   # Изменения от коммита до HEAD
   git diff --name-only <commit-id>..HEAD
   
   # Staged изменения (git add)
   git diff --cached --name-only
   
   # Unstaged изменения (рабочий каталог)
   git diff --name-only
   ```
   
   Все списки объединяются, дубликаты удаляются.

2. **Фильтрация файлов**
   - Проверяется, что файл находится в каталоге конфигурации
   - Для XML файлов - добавляются напрямую
   - **Для BSL файлов** - автоматически добавляется соответствующий XML объекта и все связанные файлы (модули, формы и т.д.)
   - Проверяется существование файла

3. **Создание файла списка**
   - Файлы записываются построчно
   - Пути указываются относительно каталога конфигурации

4. **Выполнение загрузки**
   ```cmd
   1cv8.exe DESIGNER /F "path\to\base" /LoadConfigFromFiles "config" 
            -listFile "load_list.txt" -Format Hierarchical -partial 
            -updateConfigDumpInfo /DisableStartupDialogs
   ```

## Примеры использования

### Загрузка всех изменений с последнего коммита (включая незафиксированные)

```powershell
# Загрузит все изменения в HEAD + staged + unstaged
.\partial-load-config.ps1 -CommitId "HEAD" -InfoBasePath "C:\Bases\Dev"
```

### Загрузка всех изменений за последние 5 коммитов

```powershell
# Загрузит изменения из последних 5 коммитов + текущие незафиксированные
.\partial-load-config.ps1 -CommitId "HEAD~5" -InfoBaseName "Production" -DebugMode
```

**Отладочный вывод покажет:**
```
[DEBUG] Getting changes from HEAD~5 to HEAD...
[DEBUG] Getting staged changes...
[DEBUG] Getting unstaged changes...
[DEBUG] Changes from HEAD~5 to HEAD: 15 files
[DEBUG] Staged changes: 3 files
[DEBUG] Unstaged changes: 2 files
[DEBUG] Total unique files: 18
```

### Загрузка изменений от конкретного коммита

```powershell
# Загрузит все изменения от коммита abc123 до текущего состояния
.\partial-load-config.ps1 -CommitId "abc123" -InfoBasePath "C:\Bases\Test"
```

### Загрузка изменений от другой ветки

```powershell
# Загрузит все файлы, которые изменились относительно feature/new-module
.\partial-load-config.ps1 -CommitId "feature/new-module" -InfoBasePath "C:\Bases\Test"
```

### Сценарий: разработка новой функциональности

```powershell
# 1. Создали ветку от master 5 коммитов назад
git checkout -b feature/new-report HEAD~5

# 2. Внесли изменения в 3 файла, но еще не зафиксировали
# 3. Хотим загрузить ВСЕ изменения с момента создания ветки

.\partial-load-config.ps1 -CommitId "HEAD~5" `
    -InfoBasePath "C:\Bases\Dev" `
    -UpdateDB `
    -RunEnterprise `
    -DebugMode

# Загрузится:
# - Все изменения из 5 коммитов
# - Ваши незафиксированные изменения в 3 файлах
```

### Загрузка изменений с начала недели

```powershell
# Загрузит все изменения за неделю + незафиксированные
.\partial-load-config.ps1 -CommitId "HEAD@{1.week.ago}" `
    -InfoBasePath "C:\Bases\MyBase" `
    -OutFile "C:\Logs\load_log.txt" `
    -UpdateDB
```

### Комплексный сценарий: от фиксации до запуска

```powershell
# 1. Сделали 3 коммита с новой функциональностью
# 2. Есть незафиксированные изменения для тестирования
# 3. Хотим загрузить все, обновить БД и сразу открыть нужную форму

.\partial-load-config.ps1 -CommitId "HEAD~3" `
    -InfoBasePath "C:\edt\IB\ERP" `
    -ConfigDir "src" `
    -UserName "Администратор" `
    -UpdateDB `
    -RunEnterprise `
    -NavigationLink "e1cib/data/Document.SalesOrder" `
    -DebugMode

# Что произойдет:
# 1. Получит все файлы из 3 коммитов + незафиксированные
# 2. Загрузит их в конфигурацию
# 3. Обновит конфигурацию БД
# 4. Запустит 1С с открытой формой документа
```

## Структура каталогов

Рекомендуемая структура проекта:

```
project/
├── config/                 # Выгруженная конфигурация
│   ├── Catalogs/
│   ├── Documents/
│   ├── Reports/
│   └── ...
├── partial-load-config.ps1
├── partial-load-config.cmd
└── README_partial_load.md
```

## Коды возврата

| Код | Описание |
|-----|----------|
| 0 | Успешное выполнение |
| 1 | Ошибка (неверные параметры, git ошибка, ошибка загрузки) |

## Отладка

При возникновении проблем используйте параметр `-DebugMode`:

```powershell
.\partial-load-config.ps1 -CommitId "HEAD" -InfoBasePath "C:\Bases\Test" -DebugMode
```

Это выведет:
- Параметры запуска
- Список найденных файлов
- Содержимое файла списка загрузки
- Полную командную строку 1cv8.exe
- Путь к временным файлам (не удаляются)

## Как работает поддержка BSL

Когда скрипт обнаруживает изменение в BSL файле (например, `src/Catalogs/Справочник1/Ext/ObjectModule.bsl`), он автоматически:

1. Определяет тип объекта (`Catalogs`) и его имя (`Справочник1`)
2. Добавляет в список загрузки XML объекта (`Catalogs/Справочник1.xml`)
3. Добавляет сам BSL файл
4. Рекурсивно добавляет все файлы из подкаталога `Ext` (включая формы, предопределенные данные и т.д.)

Это гарантирует корректную загрузку изменений в модулях объектов.

## Логика работы с коммитами

### Точка отсчета

Указанный параметр `CommitId` является **точкой отсчета** для получения изменений:

```
CommitId ────────> HEAD ────────> Current State
   ▲                 ▲                  ▲
   │                 │                  │
   └─────────────────┴──────────────────┘
         Все эти изменения загружаются
```

**Примеры:**

- `HEAD~5` - загрузит все изменения за последние 5 коммитов + незафиксированные
- `abc123` - загрузит все изменения от коммита abc123 до текущего состояния
- `feature/branch` - загрузит все изменения от указанной ветки до текущего HEAD

### Что включается в загрузку

1. **Зафиксированные изменения**: все коммиты от указанного до HEAD
2. **Staged изменения**: файлы после `git add`
3. **Unstaged изменения**: измененные файлы в рабочем каталоге

### Важно

⚠️ Загрузка **всегда** происходит из текущего состояния файлов, не из коммита!
✅ Указанный коммит определяет **какие объекты** загружать, но не **откуда** их брать.

## Ограничения

1. Работает только с файлами формата XML/BSL (не с `.cf`, `.cfu`)
2. Требует предварительную выгрузку конфигурации в файлы
3. Не поддерживает расширения конфигурации
4. Загружает измененные файлы из текущего состояния (не переключается на указанный коммит)

## Расширение функциональности

### Загрузка изменений из диапазона коммитов

Можно модифицировать скрипт для загрузки всех изменений между двумя коммитами:

```bash
git diff --name-only <commit1>..<commit2>
```

### Поддержка расширений

Добавить параметр `-Extension`:

```powershell
$arguments += "-Extension", "`"MyExtension`""
```

### Автоматическое обновление БД

**Реализовано!** Используйте параметр `-UpdateDB`:

```powershell
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -UpdateDB
```

### Запуск в режиме 1С:Предприятие

**Реализовано!** Используйте параметр `-RunEnterprise`:

```powershell
# Простой запуск
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -RunEnterprise

# С открытием конкретного объекта
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -RunEnterprise `
    -NavigationLink "e1cib/data/Catalog.Items"

# С запуском внешней обработки
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\Bases\MyBase" `
    -RunEnterprise `
    -ExternalDataProcessor "C:\Tools\MyProcessor.epf"
```

### Комплексный сценарий

Загрузка, обновление БД и запуск с открытием объекта:

```powershell
.\partial-load-config.ps1 -CommitId "HEAD" `
    -InfoBasePath "C:\edt\IB\ERP_2.5.12.73" `
    -ConfigDir "src" `
    -UserName "Администратор" `
    -UpdateDB `
    -RunEnterprise `
    -NavigationLink "e1cib/data/Document.SalesOrder"
```

## Устранение неполадок

### Ошибка: "git не найден"
Установите git и добавьте его в PATH

### Ошибка: "Каталог конфигурации не найден"
Проверьте параметр `-ConfigDir` и наличие каталога

### Ошибка: "No configuration files found for loading"
- Проверьте идентификатор коммита
- Убедитесь, что в коммите есть изменения XML или BSL файлов
- Проверьте путь к каталогу конфигурации (параметр `-ConfigDir`)

### Ошибка: "The system cannot find the file specified" при запуске 1cv8.exe
- Укажите полный путь к платформе через параметр `-V8Path`
- Пример: `-V8Path "C:\Program Files\1cv8\8.3.27.1859\bin\1cv8.exe"`

### Код возврата 1 от 1cv8.exe
Проверьте файл лога (`-OutFile` или временный файл)

## См. также

- [Документация 1С: Командная строка](https://its.1c.ru/)
- [Git документация](https://git-scm.com/doc)
- Параметр `/LoadConfigFromFiles` (строка 1070 в документации)

## История изменений

### Версия 4.0 (ноябрь 2024)
- ✅ **Изменена логика получения файлов**: указанный коммит теперь точка отсчета
- ✅ **Загрузка всех изменений**: от коммита до HEAD + незафиксированные
- ✅ **Улучшенная отладка**: детальная статистика по источникам изменений
- ✅ Обновлена документация с подробным описанием логики

### Версия 3.0 (ноябрь 2024)
- ✅ **Автоматическое обновление конфигурации БД** (`-UpdateDB`)
- ✅ **Запуск в режиме 1С:Предприятие** (`-RunEnterprise`)
- ✅ **Поддержка навигационных ссылок** (`-NavigationLink`)
- ✅ **Запуск внешних обработок** (`-ExternalDataProcessor`)
- ✅ Комплексные сценарии: загрузка + обновление + запуск

### Версия 2.0 (ноябрь 2024)
- ✅ Добавлена поддержка BSL файлов
- ✅ Автоматическое добавление XML объектов при изменении модулей
- ✅ Улучшенная обработка связанных файлов объектов
- ✅ Исправлен конфликт параметра `-Debug` с встроенным PowerShell параметром (переименован в `-DebugMode`)
- ✅ Интернационализация сообщений (English)

### Версия 1.0
- ✅ Базовая функциональность частичной загрузки
- ✅ Поддержка XML файлов конфигурации
- ✅ Режим отладки

## Автор

Скрипт создан для автоматизации процесса разработки конфигураций 1С с использованием git.

## Лицензия

Свободное использование