@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================================================
REM Скрипт частичной загрузки конфигурации 1С из файлов по коммиту git
REM ============================================================================
REM
REM Использование:
REM   partial-load-config.cmd <commit-id> [options]
REM
REM Параметры:
REM   <commit-id>     - Идентификатор коммита git
REM   /ib <path>      - Путь к информационной базе (файловая) или строка подключения
REM   /ibname <name>  - Имя информационной базы из списка
REM   /n <user>       - Имя пользователя
REM   /p <password>   - Пароль пользователя
REM   /configdir <dir>- Каталог с выгруженной конфигурацией (по умолчанию: ./config)
REM   /format <fmt>   - Формат конфигурации: Hierarchical или Plain (по умолчанию: Hierarchical)
REM   /v8 <path>      - Путь к 1cv8.exe (по умолчанию: ищется в PATH)
REM   /out <file>     - Файл для вывода служебных сообщений
REM   /debug          - Режим отладки (вывод дополнительной информации)
REM
REM ============================================================================

REM Параметры по умолчанию
set "COMMIT_ID="
set "IB_PATH="
set "IB_NAME="
set "USER_NAME="
set "USER_PWD="
set "CONFIG_DIR=config"
set "CONFIG_FORMAT=Hierarchical"
set "V8_PATH=1cv8.exe"
set "OUT_FILE="
set "DEBUG_MODE=0"
set "TEMP_DIR=%TEMP%\1c_partial_load_%RANDOM%"
set "LIST_FILE=%TEMP_DIR%\load_list.txt"

REM Разбор параметров командной строки
:parse_args
if "%~1"=="" goto check_params
if "%~1"=="/ib" (
    set "IB_PATH=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/ibname" (
    set "IB_NAME=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/n" (
    set "USER_NAME=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/p" (
    set "USER_PWD=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/configdir" (
    set "CONFIG_DIR=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/format" (
    set "CONFIG_FORMAT=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/v8" (
    set "V8_PATH=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/out" (
    set "OUT_FILE=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/debug" (
    set "DEBUG_MODE=1"
    shift
    goto parse_args
)
if "!COMMIT_ID!"=="" (
    set "COMMIT_ID=%~1"
    shift
    goto parse_args
)
echo Неизвестный параметр: %~1
goto usage

:check_params
if "!COMMIT_ID!"=="" (
    echo Ошибка: Не указан идентификатор коммита
    goto usage
)

if "!IB_PATH!"=="" if "!IB_NAME!"=="" (
    echo Ошибка: Необходимо указать /ib или /ibname
    goto usage
)

if not exist "!CONFIG_DIR!" (
    echo Ошибка: Каталог конфигурации не найден: !CONFIG_DIR!
    exit /b 1
)

REM Проверка наличия git
where git >nul 2>&1
if errorlevel 1 (
    echo Ошибка: git не найден в PATH
    exit /b 1
)

REM Создание временного каталога
if not exist "!TEMP_DIR!" mkdir "!TEMP_DIR!"

if "!DEBUG_MODE!"=="1" (
    echo [DEBUG] Commit ID: !COMMIT_ID!
    echo [DEBUG] Config dir: !CONFIG_DIR!
    echo [DEBUG] Format: !CONFIG_FORMAT!
    echo [DEBUG] Temp dir: !TEMP_DIR!
    echo [DEBUG] List file: !LIST_FILE!
)

REM Получение списка измененных файлов из коммита
echo Получение списка измененных файлов из коммита !COMMIT_ID!...
git show --pretty="" --name-only !COMMIT_ID! > "!TEMP_DIR!\changed_files.txt" 2>&1
if errorlevel 1 (
    echo Ошибка при получении списка файлов из git
    type "!TEMP_DIR!\changed_files.txt"
    goto cleanup
)

REM Фильтрация файлов конфигурации и создание списка для загрузки
echo Подготовка списка файлов для загрузки...
set "FILE_COUNT=0"
(
    for /f "usebackq delims=" %%f in ("!TEMP_DIR!\changed_files.txt") do (
        set "FILE_PATH=%%f"
        
        REM Проверяем, что файл относится к каталогу конфигурации
        echo !FILE_PATH! | findstr /b "!CONFIG_DIR!" >nul
        if !errorlevel! equ 0 (
            REM Проверяем расширение файла (xml для конфигурации)
            echo !FILE_PATH! | findstr /i "\.xml$" >nul
            if !errorlevel! equ 0 (
                REM Убираем префикс каталога конфигурации
                set "REL_PATH=!FILE_PATH:*%CONFIG_DIR%\=!"
                
                REM Проверяем существование файла
                if exist "!CONFIG_DIR!\!REL_PATH!" (
                    echo !REL_PATH!
                    set /a FILE_COUNT+=1
                    
                    if "!DEBUG_MODE!"=="1" echo [DEBUG] Добавлен: !REL_PATH!
                )
            )
        )
    )
) > "!LIST_FILE!"

if "!FILE_COUNT!"=="0" (
    echo Не найдено ни одного файла конфигурации для загрузки в коммите !COMMIT_ID!
    goto cleanup
)

echo Найдено файлов для загрузки: !FILE_COUNT!

if "!DEBUG_MODE!"=="1" (
    echo [DEBUG] Содержимое файла списка:
    type "!LIST_FILE!"
)

REM Формирование командной строки для 1cv8
set "CMD_LINE="!V8_PATH!" DESIGNER"

REM Параметры подключения к ИБ
if not "!IB_NAME!"=="" (
    set "CMD_LINE=!CMD_LINE! /IBName "!IB_NAME!""
) else (
    set "CMD_LINE=!CMD_LINE! /F "!IB_PATH!""
)

REM Учетные данные
if not "!USER_NAME!"=="" set "CMD_LINE=!CMD_LINE! /N "!USER_NAME!""
if not "!USER_PWD!"=="" set "CMD_LINE=!CMD_LINE! /P "!USER_PWD!""

REM Параметры загрузки
set "CMD_LINE=!CMD_LINE! /LoadConfigFromFiles "!CONFIG_DIR!""
set "CMD_LINE=!CMD_LINE! -listFile "!LIST_FILE!""
set "CMD_LINE=!CMD_LINE! -Format !CONFIG_FORMAT!"
set "CMD_LINE=!CMD_LINE! -partial"
set "CMD_LINE=!CMD_LINE! -updateConfigDumpInfo"

REM Вывод служебных сообщений
if not "!OUT_FILE!"=="" (
    set "CMD_LINE=!CMD_LINE! /Out "!OUT_FILE!""
) else (
    set "CMD_LINE=!CMD_LINE! /Out "!TEMP_DIR!\load_log.txt""
    set "OUT_FILE=!TEMP_DIR!\load_log.txt"
)

REM Отключение диалогов
set "CMD_LINE=!CMD_LINE! /DisableStartupDialogs"

echo.
echo Выполнение загрузки конфигурации...
if "!DEBUG_MODE!"=="1" (
    echo [DEBUG] Команда: !CMD_LINE!
)

REM Выполнение команды
!CMD_LINE!
set "EXIT_CODE=!errorlevel!"

echo.
if "!EXIT_CODE!"=="0" (
    echo Загрузка завершена успешно
) else (
    echo Ошибка при загрузке конфигурации ^(код: !EXIT_CODE!^)
)

REM Вывод лога
if exist "!OUT_FILE!" (
    echo.
    echo --- Лог выполнения ---
    type "!OUT_FILE!"
    echo --- Конец лога ---
)

:cleanup
REM Очистка временных файлов
if "!DEBUG_MODE!"=="0" (
    if exist "!TEMP_DIR!" rd /s /q "!TEMP_DIR!"
) else (
    echo [DEBUG] Временные файлы сохранены в: !TEMP_DIR!
)

exit /b !EXIT_CODE!

:usage
echo.
echo Использование:
echo   %~nx0 ^<commit-id^> [options]
echo.
echo Параметры:
echo   ^<commit-id^>     - Идентификатор коммита git
echo   /ib ^<path^>      - Путь к информационной базе или строка подключения
echo   /ibname ^<name^>  - Имя информационной базы из списка
echo   /n ^<user^>       - Имя пользователя
echo   /p ^<password^>   - Пароль пользователя
echo   /configdir ^<dir^>- Каталог с выгруженной конфигурацией (по умолчанию: ./config)
echo   /format ^<fmt^>   - Формат: Hierarchical или Plain (по умолчанию: Hierarchical)
echo   /v8 ^<path^>      - Путь к 1cv8.exe
echo   /out ^<file^>     - Файл для вывода служебных сообщений
echo   /debug          - Режим отладки
echo.
echo Примеры:
echo   %~nx0 a3f5b21 /ib "C:\Bases\MyBase" /n Admin
echo   %~nx0 HEAD~1 /ibname "MyBase" /configdir ".\src"
echo.
exit /b 1