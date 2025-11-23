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

REM Возвращаем код возврата из PowerShell
exit /b %ERRORLEVEL%