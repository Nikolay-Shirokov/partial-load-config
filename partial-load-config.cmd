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
REM   /updatedb       - Обновить конфигурацию БД после загрузки
REM   /run            - Запустить 1С:Предприятие после загрузки
REM   /navlink <url>  - Навигационная ссылка для запуска
REM   /runep <path>   - Путь к внешней обработке для запуска
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
set "UPDATE_DB=0"
set "RUN_ENTERPRISE=0"
set "NAVIGATION_LINK="
set "EXTERNAL_DATA_PROCESSOR="
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
if "%~1"=="/updatedb" (
    set "UPDATE_DB=1"
    shift
    goto parse_args
)
if "%~1"=="/run" (
    set "RUN_ENTERPRISE=1"
    shift
    goto parse_args
)
if "%~1"=="/navlink" (
    set "NAVIGATION_LINK=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="/runep" (
    set "EXTERNAL_DATA_PROCESSOR=%~2"
    shift
    shift
    goto parse_args
)
if "!COMMIT_ID!"=="" (
    set "COMMIT_ID=%~1"
    shift
    goto parse_args
)
echo Unknown parameter: %~1
goto usage

:check_params
if "!COMMIT_ID!"=="" (
    echo Error: Commit ID not specified
    goto usage
)

if "!IB_PATH!"=="" if "!IB_NAME!"=="" (
    echo Error: InfoBasePath or InfoBaseName required
    goto usage
)

if not exist "!CONFIG_DIR!" (
    echo Error: Config directory not found: !CONFIG_DIR!
    exit /b 1
)

where git >nul 2>&1
if errorlevel 1 (
    echo Error: git not found in PATH
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

REM Получение списка измененных файлов от коммита до текущего состояния
echo Getting changed files from commit !COMMIT_ID! to current state...

REM Получаем изменения от коммита до HEAD
if "!DEBUG_MODE!"=="1" echo [DEBUG] Getting changes from !COMMIT_ID! to HEAD...
git diff --name-only "!COMMIT_ID!..HEAD" > "!TEMP_DIR!\commit_to_head.txt" 2>&1
if errorlevel 1 (
    echo Error getting changes from commit to HEAD
    type "!TEMP_DIR!\commit_to_head.txt"
    goto cleanup
)

REM Получаем staged изменения
if "!DEBUG_MODE!"=="1" echo [DEBUG] Getting staged changes...
git diff --cached --name-only > "!TEMP_DIR!\staged.txt" 2>&1
if errorlevel 1 (
    echo Error getting staged changes
    type "!TEMP_DIR!\staged.txt"
    goto cleanup
)

REM Получаем unstaged изменения
if "!DEBUG_MODE!"=="1" echo [DEBUG] Getting unstaged changes...
git diff --name-only > "!TEMP_DIR!\unstaged.txt" 2>&1
if errorlevel 1 (
    echo Error getting unstaged changes
    type "!TEMP_DIR!\unstaged.txt"
    goto cleanup
)

REM Объединяем все файлы
type "!TEMP_DIR!\commit_to_head.txt" "!TEMP_DIR!\staged.txt" "!TEMP_DIR!\unstaged.txt" > "!TEMP_DIR!\all_changes.txt" 2>nul

REM Подсчет статистики для отладки
if "!DEBUG_MODE!"=="1" (
    for /f %%i in ('type "!TEMP_DIR!\commit_to_head.txt" ^| find /c /v ""') do echo [DEBUG] Changes from !COMMIT_ID! to HEAD: %%i files
    for /f %%i in ('type "!TEMP_DIR!\staged.txt" ^| find /c /v ""') do echo [DEBUG] Staged changes: %%i files
    for /f %%i in ('type "!TEMP_DIR!\unstaged.txt" ^| find /c /v ""') do echo [DEBUG] Unstaged changes: %%i files
)

REM Убираем дубликаты и пустые строки
(for /f "usebackq delims=" %%f in ("!TEMP_DIR!\all_changes.txt") do echo %%f) | sort | uniq > "!TEMP_DIR!\changed_files.txt"

if "!DEBUG_MODE!"=="1" (
    for /f %%i in ('type "!TEMP_DIR!\changed_files.txt" ^| find /c /v ""') do echo [DEBUG] Total unique files: %%i
)

REM Фильтрация файлов конфигурации и создание списка для загрузки
echo Preparing file list for loading...
set "FILE_COUNT=0"
set "TEMP_LIST=!TEMP_DIR!\temp_list.txt"
if exist "!TEMP_LIST!" del "!TEMP_LIST!"

for /f "usebackq delims=" %%f in ("!TEMP_DIR!\changed_files.txt") do (
    set "FILE_PATH=%%f"
    
    REM Проверяем, что файл относится к каталогу конфигурации
    echo !FILE_PATH! | findstr /b "!CONFIG_DIR!" >nul
    if !errorlevel! equ 0 (
        REM Убираем префикс каталога конфигурации
        set "REL_PATH=!FILE_PATH:*%CONFIG_DIR%\=!"
        
        REM Проверяем расширение файла
        echo !FILE_PATH! | findstr /i "\.xml$" >nul
        if !errorlevel! equ 0 (
            REM XML файл - добавляем напрямую
            if exist "!CONFIG_DIR!\!REL_PATH!" (
                echo !REL_PATH!>> "!TEMP_LIST!"
                set /a FILE_COUNT+=1
                if "!DEBUG_MODE!"=="1" echo [DEBUG] Added XML: !REL_PATH!
            )
        ) else (
            REM Проверяем BSL файлы
            echo !FILE_PATH! | findstr /i "\.bsl$" >nul
            if !errorlevel! equ 0 (
                if "!DEBUG_MODE!"=="1" echo [DEBUG] Found BSL file: !REL_PATH!
                
                REM Извлекаем тип и имя объекта из пути
                REM Пример: Catalogs\Справочник1\Ext\ObjectModule.bsl
                for /f "tokens=1,2 delims=\" %%a in ("!REL_PATH!") do (
                    set "OBJ_TYPE=%%a"
                    set "OBJ_NAME=%%b"
                    
                    REM Формируем путь к XML объекта
                    set "OBJ_XML=%%a\%%b.xml"
                    
                    if exist "!CONFIG_DIR!\!OBJ_XML!" (
                        REM Добавляем XML объекта
                        echo !OBJ_XML!>> "!TEMP_LIST!"
                        set /a FILE_COUNT+=1
                        if "!DEBUG_MODE!"=="1" echo [DEBUG] Added object XML for BSL: !OBJ_XML!
                        
                        REM Добавляем BSL файл
                        echo !REL_PATH!>> "!TEMP_LIST!"
                        set /a FILE_COUNT+=1
                        if "!DEBUG_MODE!"=="1" echo [DEBUG] Added BSL: !REL_PATH!
                        
                        REM Добавляем все файлы из подкаталога Ext
                        if exist "!CONFIG_DIR!\%%a\%%b\Ext\" (
                            for /r "!CONFIG_DIR!\%%a\%%b\Ext" %%e in (*) do (
                                set "EXT_FILE=%%e"
                                set "EXT_REL=!EXT_FILE:*%CONFIG_DIR%\=!"
                                echo !EXT_REL!>> "!TEMP_LIST!"
                                set /a FILE_COUNT+=1
                                if "!DEBUG_MODE!"=="1" echo [DEBUG] Added additional file: !EXT_REL!
                            )
                        )
                    )
                )
            )
        )
    )
)

REM Убираем дубликаты и создаем финальный список
if exist "!TEMP_LIST!" (
    (for /f "usebackq delims=" %%i in ("!TEMP_LIST!") do echo %%i) | sort | uniq > "!LIST_FILE!"
    del "!TEMP_LIST!"
)

set "FILE_COUNT=0"
for /f %%i in ('type "!LIST_FILE!" ^| find /c /v ""') do set "FILE_COUNT=%%i"

if "!FILE_COUNT!"=="0" (
    echo No configuration files found for loading in commit !COMMIT_ID!
    goto cleanup
)

echo Files found for loading: !FILE_COUNT!

if "!DEBUG_MODE!"=="1" (
    echo [DEBUG] List file content:
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
echo Executing configuration load...
if "!DEBUG_MODE!"=="1" (
    echo [DEBUG] Command: !CMD_LINE!
)

REM Выполнение команды
!CMD_LINE!
set "EXIT_CODE=!errorlevel!"

echo.
if "!EXIT_CODE!"=="0" (
    echo Load completed successfully
) else (
    echo Error loading configuration ^(code: !EXIT_CODE!^)
)

if exist "!OUT_FILE!" (
    echo.
    echo --- Execution log ---
    type "!OUT_FILE!"
    echo --- End of log ---
)

if "!EXIT_CODE!" NEQ "0" goto cleanup

REM Обновление конфигурации БД
if "!UPDATE_DB!"=="1" (
    echo.
    echo Updating database configuration...
    
    set "UPDATE_CMD="!V8_PATH!" DESIGNER"
    if not "!IB_NAME!"=="" (
        set "UPDATE_CMD=!UPDATE_CMD! /IBName "!IB_NAME!""
    ) else (
        set "UPDATE_CMD=!UPDATE_CMD! /F "!IB_PATH!""
    )
    if not "!USER_NAME!"=="" set "UPDATE_CMD=!UPDATE_CMD! /N "!USER_NAME!""
    if not "!USER_PWD!"=="" set "UPDATE_CMD=!UPDATE_CMD! /P "!USER_PWD!""
    
    set "UPDATE_CMD=!UPDATE_CMD! /UpdateDBCfg"
    set "UPDATE_CMD=!UPDATE_CMD! /DisableStartupDialogs"
    
    set "UPDATE_OUT=!TEMP_DIR!\update_log.txt"
    set "UPDATE_CMD=!UPDATE_CMD! /Out "!UPDATE_OUT!""
    
    if "!DEBUG_MODE!"=="1" (
        echo [DEBUG] Update command: !UPDATE_CMD!
    )
    
    !UPDATE_CMD!
    set "UPDATE_EXIT_CODE=!errorlevel!"
    
    echo.
    if "!UPDATE_EXIT_CODE!"=="0" (
        echo Database configuration updated successfully
    ) else (
        echo Error updating database configuration ^(code: !UPDATE_EXIT_CODE!^)
        set "EXIT_CODE=!UPDATE_EXIT_CODE!"
    )
    
    if exist "!UPDATE_OUT!" (
        echo.
        echo --- Update log ---
        type "!UPDATE_OUT!"
        echo --- End of update log ---
    )
    
    if "!EXIT_CODE!" NEQ "0" goto cleanup
)

REM Запуск 1С:Предприятие
if "!RUN_ENTERPRISE!"=="1" (
    echo.
    echo Starting 1C:Enterprise...
    
    set "ENTERPRISE_CMD="!V8_PATH!" ENTERPRISE"
    if not "!IB_NAME!"=="" (
        set "ENTERPRISE_CMD=!ENTERPRISE_CMD! /IBName "!IB_NAME!""
    ) else (
        set "ENTERPRISE_CMD=!ENTERPRISE_CMD! /F "!IB_PATH!""
    )
    if not "!USER_NAME!"=="" set "ENTERPRISE_CMD=!ENTERPRISE_CMD! /N "!USER_NAME!""
    if not "!USER_PWD!"=="" set "ENTERPRISE_CMD=!ENTERPRISE_CMD! /P "!USER_PWD!""
    
    if not "!NAVIGATION_LINK!"=="" (
        set "ENTERPRISE_CMD=!ENTERPRISE_CMD! /URL "!NAVIGATION_LINK!""
    )
    
    if not "!EXTERNAL_DATA_PROCESSOR!"=="" (
        if exist "!EXTERNAL_DATA_PROCESSOR!" (
            set "ENTERPRISE_CMD=!ENTERPRISE_CMD! /Execute "!EXTERNAL_DATA_PROCESSOR!""
        ) else (
            echo Warning: External data processor not found: !EXTERNAL_DATA_PROCESSOR!
        )
    )
    
    if "!DEBUG_MODE!"=="1" (
        echo [DEBUG] Enterprise command: !ENTERPRISE_CMD!
    )
    
    start "" !ENTERPRISE_CMD!
    echo 1C:Enterprise started
)

:cleanup
REM Очистка временных файлов
if "!DEBUG_MODE!"=="0" (
    if exist "!TEMP_DIR!" rd /s /q "!TEMP_DIR!"
) else (
    echo [DEBUG] Temporary files saved in: !TEMP_DIR!
)

exit /b !EXIT_CODE!

:usage
echo.
echo Usage:
echo   %~nx0 ^<commit-id^> [options]
echo.
echo Parameters:
echo   ^<commit-id^>     - Git commit identifier
echo   /ib ^<path^>      - Path to infobase or connection string
echo   /ibname ^<name^>  - Infobase name from list
echo   /n ^<user^>       - Username
echo   /p ^<password^>   - Password
echo   /configdir ^<dir^>- Configuration directory (default: ./config)
echo   /format ^<fmt^>   - Format: Hierarchical or Plain (default: Hierarchical)
echo   /v8 ^<path^>      - Path to 1cv8.exe
echo   /out ^<file^>     - Output file for service messages
echo   /debug          - Debug mode
echo   /updatedb       - Update database configuration after loading
echo   /run            - Run 1C:Enterprise after loading
echo   /navlink ^<url^>  - Navigation link to open in 1C:Enterprise
echo   /runep ^<path^>   - Path to external data processor to run
echo.
echo Examples:
echo   %~nx0 a3f5b21 /ib "C:\Bases\MyBase" /n Admin
echo   %~nx0 HEAD~1 /ibname "MyBase" /configdir ".\src"
echo   %~nx0 HEAD /ib "C:\Bases\MyBase" /updatedb
echo   %~nx0 HEAD /ib "C:\Bases\MyBase" /run /navlink "e1cib/data/Catalog.Items"
echo.
exit /b 1