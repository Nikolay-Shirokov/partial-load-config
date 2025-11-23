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

REM Путь к основному PowerShell скрипту
set "PS_SCRIPT=%SCRIPT_DIR%\scripts\dump-config.ps1"

REM Проверяем существование скрипта
if not exist "%PS_SCRIPT%" (
    echo [ERROR] Script not found: %PS_SCRIPT%
    exit /b 1
)

REM Обработка первого параметра как режима (если это не флаг)
set "PARAMS="
set "FIRST_PARAM=%~1"
if not "%FIRST_PARAM%"=="" (
    REM Проверяем, является ли первый параметр режимом (Full/Changes/Partial)
    if /i "%FIRST_PARAM%"=="Full" (
        set "PARAMS=-Mode Full"
        shift
        goto parse_remaining
    )
    if /i "%FIRST_PARAM%"=="Changes" (
        set "PARAMS=-Mode Changes"
        shift
        goto parse_remaining
    )
    if /i "%FIRST_PARAM%"=="Partial" (
        set "PARAMS=-Mode Partial"
        shift
        goto parse_remaining
    )
)

REM Передаем остальные параметры командной строки
:parse_remaining
if "%~1"=="" goto run_script
set "PARAMS=%PARAMS% %1"
shift
goto parse_remaining

:run_script
REM Запускаем PowerShell скрипт
powershell.exe -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %PARAMS%

REM Возвращаем код возврата из PowerShell
exit /b %ERRORLEVEL%