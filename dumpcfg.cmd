@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM dumpcfg - Обертка для выгрузки конфигурации 1С
REM ============================================================================
REM 
REM Использование:
REM   dumpcfg                           - выгрузка по умолчанию (Changes из .env)
REM   dumpcfg Full                      - полная выгрузка
REM   dumpcfg Changes                   - инкрементальная выгрузка
REM   dumpcfg Partial                   - частичная выгрузка (список из .env)
REM   dumpcfg -mode Full                - явное указание режима
REM   dumpcfg -mode Partial -objects "Справочник.Номенклатура,Документ.Заказ"
REM   dumpcfg -DebugMode                - выгрузка с отладкой
REM
REM Все параметры берутся из .env файла, но могут быть переопределены
REM ============================================================================

REM Определяем каталог скрипта
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Проверка на -help или -h
if /i "%~1"=="-help" goto show_help
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="/?" goto show_help

REM Обработка параметров - ищем режим и -objects
set "MODE="
set "USE_PARTIAL_SCRIPT=0"
set "PARAMS="
set "FIRST_PARAM=%~1"

REM Проверяем первый параметр на режим
if not "%FIRST_PARAM%"=="" (
    if /i "%FIRST_PARAM%"=="Full" (
        set "MODE=Full"
        shift
    ) else if /i "%FIRST_PARAM%"=="Changes" (
        set "MODE=Changes"
        shift
    ) else if /i "%FIRST_PARAM%"=="Partial" (
        set "MODE=Partial"
        set "USE_PARTIAL_SCRIPT=1"
        shift
    )
)

REM Собираем остальные параметры и проверяем наличие -objects или -mode Partial
:parse_params
if "%~1"=="" goto determine_script

if /i "%~1"=="-mode" (
    set "nextparam=%~2"
    if /i "!nextparam!"=="Partial" (
        set "USE_PARTIAL_SCRIPT=1"
        set "MODE=Partial"
    ) else (
        set "MODE=!nextparam!"
    )
    shift
    shift
    goto parse_params
)

if /i "%~1"=="-objects" (
    REM Для -objects используем dump-partial-config.ps1
    set "USE_PARTIAL_SCRIPT=1"
    set "PARAMS=!PARAMS! -ObjectNames %2"
    shift
    shift
    goto parse_params
)

REM Все остальные параметры передаем как есть
set "PARAMS=!PARAMS! %1"
shift
goto parse_params

:determine_script
REM Определяем какой скрипт использовать
if "!USE_PARTIAL_SCRIPT!"=="1" (
    set "PS_SCRIPT=%SCRIPT_DIR%\scripts\dump-partial-config.ps1"
) else (
    set "PS_SCRIPT=%SCRIPT_DIR%\scripts\dump-config.ps1"
    if not "!MODE!"=="" set "PARAMS=-Mode !MODE! !PARAMS!"
)

REM Проверяем существование скрипта
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Script not found: %PS_SCRIPT%
    exit /b 1
)

:run_script
REM Запускаем PowerShell скрипт
powershell.exe -ExecutionPolicy Bypass -File "%PS_SCRIPT%" !PARAMS!

REM Возвращаем код возврата из PowerShell
exit /b %ERRORLEVEL%

:show_help
echo.
echo dumpcfg - Выгрузка конфигурации 1С в файлы
echo ==========================================
echo.
echo Использование:
echo   dumpcfg [режим] [параметры]
echo.
echo Примеры:
echo   dumpcfg                           - выгрузка по умолчанию (Changes из .env)
echo   dumpcfg Full                      - полная выгрузка
echo   dumpcfg Changes                   - инкрементальная выгрузка
echo   dumpcfg Partial                   - частичная выгрузка (список из .env)
echo   dumpcfg -mode Full                - явное указание режима
echo   dumpcfg -mode Partial -objects "Справочник.Номенклатура,Документ.Заказ"
echo   dumpcfg -DebugMode                - выгрузка с отладкой
echo.
echo Режимы:
echo   Full                              - Полная выгрузка всей конфигурации
echo   Changes                           - Инкрементальная (только изменения)
echo   Partial                           - Частичная (конкретные объекты)
echo.
echo Параметры:
echo   -mode [режим]                     - Явное указание режима
echo   -objects "obj1,obj2,..."          - Список объектов (режим Partial)
echo   -ObjectsListFile "file"           - Файл со списком объектов
echo   -ChangesFile "file"               - Файл для списка изменений
echo   -CompareWith "file"               - ConfigDumpInfo.xml для сравнения
echo   -Force                            - Принудительная полная выгрузка
echo   -DebugMode                        - Режим отладки
echo   -InfoBasePath "path"              - Путь к информационной базе
echo   -InfoBaseName "name"              - Имя базы из списка
echo   -UserName "name"                  - Имя пользователя
echo   -Password "pwd"                   - Пароль
echo   -ConfigDir "path"                 - Каталог для выгрузки (default: src)
echo   -Format "fmt"                     - Формат: Hierarchical/Plain
echo   -V8Path "path"                    - Путь к 1cv8.exe
echo   -Extension "name"                 - Имя расширения для выгрузки
echo   -AllExtensions                    - Выгрузить все расширения
echo.
echo Все основные параметры берутся из .env файла
echo Параметры командной строки переопределяют значения из .env
echo.
echo Подробнее: см. README.md
echo.
exit /b 0