# Скрипты работы с конфигурацией 1С

## Описание

Набор скриптов для автоматической работы с конфигурацией 1С:Предприятие:
- **Частичная загрузка** - загрузка измененных файлов из git в информационную базу
- **Выгрузка конфигурации** - выгрузка конфигурации из информационной базы в файлы (полная, инкрементальная, частичная)

### Возможности загрузки

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

### Возможности выгрузки

- ✅ **Полная выгрузка** - выгрузка всей конфигурации в файлы
- ✅ **Инкрементальная выгрузка** - выгрузка только измененных объектов
- ✅ **Частичная выгрузка** - выгрузка конкретных объектов из списка
- ✅ Поддержка обоих форматов (Hierarchical/Plain)
- ✅ Сохранение списка изменений
- ✅ Сравнение с другой выгрузкой
- ✅ Поддержка расширений конфигурации
- ✅ Режим отладки

## Файлы

### Загрузка конфигурации
1. **partial-load-config.ps1** - частичная загрузка из git (PowerShell)
2. **partial-load-config.cmd** - частичная загрузка (CMD)

### Выгрузка конфигурации
1. **dump-config.ps1** - универсальный скрипт выгрузки (три режима)
2. **dump-full-config.ps1** - обертка для полной выгрузки
3. **dump-changes-config.ps1** - обертка для инкрементальной выгрузки
4. **dump-partial-config.ps1** - обертка для частичной выгрузки

## Требования

- Git установлен и доступен в PATH
- Платформа 1С:Предприятие 8.3
- Конфигурация выгружена в файлы (с помощью `/DumpConfigToFiles`)
- Git репозиторий с историей изменений конфигурации

## Конфигурация через .env файл

Для удобства работы с параметрами можно создать файл `.env` в корне проекта. Скопируйте `.env.example` и настройте под свою среду:

```bash
cp .env.example .env
```

### Приоритет параметров

Параметры применяются в следующем порядке приоритета:
1. **Параметры командной строки** (самый высокий приоритет)
2. **Переменные из .env файла**
3. **Значения по умолчанию** (самый низкий приоритет)

Это позволяет настроить базовые параметры в `.env`, но при необходимости переопределить их через командную строку.

### Пример .env файла

```ini
# Путь к платформе 1С:Предприятие
V8_PATH=C:\\Program Files\\1cv8\\8.3.24.1467\\bin\\1cv8.exe

# Каталог конфигурации
CONFIG_DIR=src

# Формат выгрузки
CONFIG_FORMAT=Hierarchical

# Путь к информационной базе
INFOBASE_PATH=C:\\edt\\IB\\MyBase

# Имя пользователя 1С
USERNAME_1C=Администратор

# Дополнительные параметры
DEBUG_MODE=false
UPDATE_DB=false
RUN_ENTERPRISE=false
```

### Безопасность

⚠️ **Не храните пароли в .env файле!** Файл `.env` добавлен в `.gitignore`, но для дополнительной безопасности рекомендуется передавать пароль через параметр командной строки:

```powershell
.\partial-load-config.ps1 -CommitId "HEAD" -Password "your_password"
```

### Использование с .env

После настройки `.env` можно запускать скрипт без указания базовых параметров:

```powershell
# Параметры подключения берутся из .env
.\partial-load-config.ps1 -CommitId "HEAD"

# Переопределение параметров из .env
.\partial-load-config.ps1 -CommitId "HEAD" -ConfigDir "config" -UpdateDB
```

## Использование

### PowerShell (рекомендуется)

```powershell
# Загрузка незафиксированных изменений (без указания коммита)
.\partial-load-config.ps1

# Загрузка изменений от конкретного коммита
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

### Основные

| Параметр | Обязательный | Описание |
|----------|--------------|----------|
| `CommitId` | Нет | Идентификатор коммита git - **точка отсчета** для получения изменений (хеш, ветка, HEAD~N и т.д.). **Если не указан, загружаются только незафиксированные изменения** (staged + unstaged + untracked) |

### Параметры подключения к ИБ (один из двух обязателен)

| Параметр | Описание |
|---|---|
| `InfoBasePath` / `/ib` | **Путь к каталогу файловой базы данных.** Указывается каталог, содержащий файл `1Cv8.1CD`. <br> *Пример: `C:\Bases\MyFileBase`* |
| `InfoBaseName` / `/ibname` | **Имя клиент-серверной базы из списка баз 1С.** <br> *Пример: `MyServerBase`* |

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
   
   # Unstaged изменения (измененные файлы)
   git diff --name-only
   
   # Untracked файлы (новые файлы, не добавленные в git)
   git ls-files --others --exclude-standard
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

### Загрузка незафиксированных изменений (быстрый режим)

```powershell
# Загрузит только незафиксированные изменения (staged + unstaged + untracked)
# Параметры подключения берутся из .env файла
.\partial-load-config.ps1

# С явным указанием базы
.\partial-load-config.ps1 -InfoBasePath "C:\Bases\Dev"

# С обновлением БД и запуском
.\partial-load-config.ps1 -UpdateDB -RunEnterprise
```

### Загрузка всех изменений с последнего коммита (включая незафиксированные)

```powershell
# Загрузит все изменения в HEAD + staged + unstaged + untracked
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
### Скрипт открывается в Блокноте вместо выполнения
Если при запуске `.ps1` файла он открывается в текстовом редакторе, это означает, что в вашей системе для этого типа файлов не настроено действие "Выполнить".

Для принудительного выполнения используйте `powershell.exe`:

```powershell
# Пример для полной выгрузки
powershell.exe -ExecutionPolicy Bypass -File .\dump-full-config.ps1

# Пример для частичной загрузки
powershell.exe -ExecutionPolicy Bypass -File .\partial-load-config.ps1 -CommitId "HEAD"
```


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

# Выгрузка конфигурации в файлы

## Описание

Скрипты для выгрузки конфигурации 1С:Предприятие из информационной базы в файлы в трех режимах.

## Режимы выгрузки

### 1. Полная выгрузка (Full)

Выгружает всю конфигурацию целиком.

```powershell
# Используя обертку
.\dump-full-config.ps1 -ConfigDir "src" -InfoBasePath "C:\Bases\MyBase"

# Используя универсальный скрипт
.\dump-config.ps1 -Mode Full -ConfigDir "src" -InfoBasePath "C:\Bases\MyBase"
```

**Использование:**
- Первичная выгрузка конфигурации
- Создание базовой копии для версионирования
- Экспорт для анализа

### 2. Инкрементальная выгрузка (Changes)

Выгружает только измененные объекты относительно предыдущей выгрузки.

```powershell
# Используя обертку
.\dump-changes-config.ps1 -ConfigDir "src" -InfoBasePath "C:\Bases\MyBase"

# С сохранением списка изменений
.\dump-changes-config.ps1 -ConfigDir "src" `
    -InfoBasePath "C:\Bases\MyBase" `
    -ChangesFile "changes.txt"

# Сравнение с другой выгрузкой
.\dump-changes-config.ps1 -ConfigDir "src" `
    -InfoBasePath "C:\Bases\MyBase" `
    -CompareWith "old_dump\ConfigDumpInfo.xml" `
    -Force
```

**Использование:**
- Регулярная выгрузка изменений для версионирования
- Отслеживание модификаций конфигурации
- Экспорт для анализа изменений с AI-ассистентами

**Важно:** Требует файл `ConfigDumpInfo.xml` от предыдущей выгрузки.

### 3. Частичная выгрузка (Partial)

Выгружает только конкретные объекты, указанные либо в файле, либо напрямую в командной строке.

**Способ 1: Указание объектов в файле**
```powershell
# Используя обертку с файлом
.\dump-partial-config.ps1 -ObjectsListFile "dump_objects.txt" `
    -ConfigDir "src" `
    -InfoBasePath "C:\Bases\MyBase"
```

**Способ 2: Указание объектов в параметре**
```powershell
# Выгрузка одного объекта
.\dump-partial-config.ps1 -ObjectNames "Справочник.Номенклатура" -InfoBaseName "MyBase"

# Выгрузка нескольких объектов (важно: в двойных кавычках, без пробелов у запятой)
.\dump-partial-config.ps1 -ObjectNames "Справочник.Номенклатура,Документ.РеализацияТоваровУслуг" `
    -InfoBasePath "C:\Bases\MyBase" `
    -DebugMode
```

**Формат файла списка объектов (`dump_objects.txt`):**
```
# Каждая строка - имя объекта метаданных
Справочник.Номенклатура
Документ.РеализацияТоваровУслуг
Отчет.АнализПродаж
```

**Использование:**
- **Через параметр `-ObjectNames`**: идеально для быстрой выгрузки 1-2 объектов.
- **Через файл `-ObjectsListFile`**: удобно для выгрузки большого или часто используемого списка объектов.
- Экспорт отдельных модулей для анализа или передачи коллегам.

## Параметры выгрузки

### Основные параметры

| Параметр | Обязательный | Описание |
|----------|--------------|----------|
| `Mode` | Нет | Режим выгрузки: Full, Changes, Partial (default: Changes) |
| `ConfigDir` | Нет | Каталог для выгрузки. Переопределяет `CONFIG_DIR` из `.env`. (default: `config`) |
| `InfoBasePath` | Да* | Путь к файловой базе данных |
| `InfoBaseName` | Да* | Имя базы из списка (альтернатива InfoBasePath) |

*Один из двух параметров обязателен

### Параметры для режима Changes

| Параметр | Описание |
|----------|----------|
| `ChangesFile` | Файл для сохранения списка изменений |
| `CompareWith` | Путь к ConfigDumpInfo.xml для сравнения |
| `Force` | Принудительная полная выгрузка при несоответствии версий |

### Параметры для режима Partial

| Параметр | Описание |
|----------|----------|
| `ObjectsListFile` | **(Обязательный, если не указан `ObjectNames`)**<br>Файл со списком имен объектов для выгрузки. |
| `ObjectNames` | **(Обязательный, если не указан `ObjectsListFile`)**<br>Массив строк с именами объектов для выгрузки. |

### Дополнительные параметры

| Параметр | Значение по умолчанию | Описание |
|----------|----------------------|----------|
| `UserName` | - | Имя пользователя 1С |
| `Password` | - | Пароль пользователя |
| `Format` | `Hierarchical` | Формат: Hierarchical или Plain |
| `V8Path` | `1cv8.exe` | Путь к исполняемому файлу платформы |
| `OutFile` | temp файл | Файл для вывода служебных сообщений |
| `DebugMode` | - | Режим отладки |
| `Extension` | - | Имя расширения для выгрузки |
| `AllExtensions` | - | Выгрузить все расширения |

## Использование с .env

Параметры выгрузки можно настроить в файле `.env`:

```ini
# Выгрузка конфигурации
DUMP_MODE=Changes
DUMP_OBJECTS_LIST=objects.txt
DUMP_CHANGES_FILE=config_changes.txt
```

После настройки `.env` запуск упрощается:

```powershell
# Параметры берутся из .env
.\dump-changes-config.ps1

# Переопределение параметров из .env
.\dump-full-config.ps1 -OutputDir "config_backup"
```

## Примеры использования

### Сценарий 1: Регулярная выгрузка изменений

```powershell
# Первая выгрузка (полная)
.\dump-full-config.ps1 -ConfigDir "src" -InfoBasePath "C:\Bases\Dev"

# Работа в 1С...

# Последующие выгрузки (только изменения)
.\dump-changes-config.ps1 -ConfigDir "src" `
    -InfoBasePath "C:\Bases\Dev" `
    -ChangesFile "changes.txt"

# Фиксация в git
git add src
git commit -m "Добавлен новый справочник"
```

### Сценарий 2: Выгрузка для анализа с AI

```powershell
# Выгружаем только измененные объекты
.\dump-changes-config.ps1 -ConfigDir "export_for_ai" `
    -InfoBasePath "C:\Bases\MyBase" `
    -ChangesFile "what_changed.txt" `
    -DebugMode

# Читаем что изменилось
Get-Content what_changed.txt

# Анализируем выгруженные файлы с помощью AI-ассистента
```

### Сценарий 3: Выгрузка конкретных объектов

```powershell
# Способ А: Создаем список объектов в файле
@"
Справочник.Номенклатура
Документ.РеализацияТоваровУслуг
Отчет.АнализПродаж
"@ | Out-File dump_objects.txt -Encoding UTF8

# Выгружаем только эти объекты из файла
.\dump-partial-config.ps1 -ObjectsListFile "dump_objects.txt" `
    -ConfigDir "selected_objects" `
    -InfoBasePath "C:\Bases\MyBase"

# Способ Б: Передаем объекты напрямую
.\dump-partial-config.ps1 -ObjectNames "Справочник.Номенклатура", "Отчет.АнализПродаж" `
    -ConfigDir "selected_objects" `
    -InfoBasePath "C:\Bases\MyBase"
```

### Сценарий 4: Выгрузка расширений

```powershell
# Выгрузка конкретного расширения
.\dump-full-config.ps1 -ConfigDir "extensions\MyExtension" `
    -InfoBasePath "C:\Bases\MyBase" `
    -Extension "MyExtension"

# Выгрузка всех расширений
.\dump-full-config.ps1 -ConfigDir "all_extensions" `
    -InfoBasePath "C:\Bases\MyBase" `
    -AllExtensions
```

## Интеграция с загрузкой

Скрипты выгрузки и загрузки дополняют друг друга:

```powershell
# 1. Выгружаем конфигурацию из базы в файлы
.\dump-changes-config.ps1 -ConfigDir "src" -InfoBasePath "C:\Bases\Prod"

# 2. Фиксируем в git
git add src
git commit -m "Обновление конфигурации"

# 3. В другой базе загружаем изменения
.\partial-load-config.ps1 -CommitId "HEAD" `
    -ConfigDir "src" `
    -InfoBasePath "C:\Bases\Dev" `
    -UpdateDB
```

## Отладка

При возникновении проблем используйте параметр `-DebugMode`:

```powershell
.\dump-changes-config.ps1 -ConfigDir "src" `
    -InfoBasePath "C:\Bases\MyBase" `
    -DebugMode
```

Это выведет:
- Параметры запуска
- Режим выгрузки
- Полную командную строку 1cv8.exe
- Список изменений (для режима Changes)
- Путь к временным файлам (не удаляются)

## История изменений

### Версия 5.0 (ноябрь 2025)
- ✅ **Добавлена выгрузка конфигурации** - три режима (Full, Changes, Partial)
- ✅ **Универсальный скрипт dump-config.ps1** с поддержкой .env
- ✅ **Три обертки** для удобного запуска каждого режима
- ✅ Поддержка расширений конфигурации
- ✅ Интеграция с существующей системой загрузки

### Версия 4.0 (ноябрь 2025)
- ✅ **Изменена логика получения файлов**: указанный коммит теперь точка отсчета
- ✅ **Загрузка всех изменений**: от коммита до HEAD + незафиксированные
- ✅ **Улучшенная отладка**: детальная статистика по источникам изменений
- ✅ Обновлена документация с подробным описанием логики

### Версия 3.0 (ноябрь 2025)
- ✅ **Автоматическое обновление конфигурации БД** (`-UpdateDB`)
- ✅ **Запуск в режиме 1С:Предприятие** (`-RunEnterprise`)
- ✅ **Поддержка навигационных ссылок** (`-NavigationLink`)
- ✅ **Запуск внешних обработок** (`-ExternalDataProcessor`)
- ✅ Комплексные сценарии: загрузка + обновление + запуск

### Версия 2.0 (ноябрь 2025)
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