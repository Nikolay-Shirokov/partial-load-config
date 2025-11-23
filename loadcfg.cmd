@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM loadcfg - Обертка для частичной загрузки конфигурации 1С
REM ============================================================================
REM 
REM Использование:
REM   loadcfg                           - загрузка незафиксированных изменений
REM   loadcfg HEAD                      - загрузка всех изменений с последнего коммита
REM   loadcfg HEAD~3                    - загрузка изменений за последние 3 коммита
REM   loadcfg -UpdateDB                 - загрузка с обновлением БД
REM   loadcfg HEAD -UpdateDB -DebugMode - загрузка с обновлением БД и отладкой
REM
REM Все параметры берутся из .env файла, но могут быть переопределены
REM ============================================================================

REM Определяем каталог скрипта
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Путь к основному PowerShell скрипту
set "PS_SCRIPT=%SCRIPT_DIR%\scripts\partial-load-config.ps1"

REM Проверяем существование скрипта
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Script not found: %PS_SCRIPT%
    exit /b 1
)

REM Проверка на -help или -h
if /i "%~1"=="-help" goto show_help
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="/?" goto show_help

REM Собираем все параметры
set "PARAMS="
:parse_args
if "%~1"=="" goto run_script
set "PARAMS=%PARAMS% %1"
shift
goto parse_args

:run_script
REM Запускаем PowerShell скрипт
powershell.exe -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %PARAMS%
goto end

:show_help
echo.
echo loadcfg - Загрузка конфигурации 1С из git
echo =========================================
echo.
echo Использование:
echo   loadcfg [CommitId] [параметры]
echo.
echo Примеры:
echo   loadcfg                           - загрузка незафиксированных изменений
echo   loadcfg HEAD                      - загрузка всех изменений с последнего коммита
echo   loadcfg HEAD~3                    - загрузка изменений за последние 3 коммита
echo   loadcfg -UpdateDB                 - загрузка с обновлением БД
echo   loadcfg HEAD -UpdateDB -RunEnterprise
echo.
echo Параметры:
echo   CommitId                          - Коммит git (HEAD, HEAD~N, хеш)
echo   -UpdateDB                         - Обновить конфигурацию БД после загрузки
echo   -RunEnterprise                    - Запустить 1С:Предприятие после загрузки
echo   -NavigationLink "url"             - Навигационная ссылка для открытия
echo   -ExternalDataProcessor "path"     - Путь к внешней обработке
echo   -DebugMode                        - Режим отладки
echo   -InfoBasePath "path"              - Путь к информационной базе
echo   -InfoBaseName "name"              - Имя базы из списка
echo   -UserName "name"                  - Имя пользователя
echo   -Password "pwd"                   - Пароль
echo   -ConfigDir "path"                 - Каталог конфигурации (default: src)
echo   -Format "fmt"                     - Формат: Hierarchical/Plain
echo   -V8Path "path"                    - Путь к 1cv8.exe
echo.
echo Все основные параметры берутся из .env файла
echo Параметры командной строки переопределяют значения из .env
echo.
echo Подробнее: см. README.md
echo.
exit /b 0

:end

REM Возвращаем код возврата из PowerShell
exit /b %ERRORLEVEL%