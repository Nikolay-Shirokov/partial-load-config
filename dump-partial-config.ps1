<#
.SYNOPSIS
    Частичная выгрузка конфигурации 1С в файлы

.DESCRIPTION
    Обертка над dump-config.ps1 для выгрузки конкретных объектов из списка.
    Выполняет команду /DumpConfigToFiles с параметром -listFile.

.PARAMETER OutputDir
    Каталог для выгрузки конфигурации (default: config_dump)

.PARAMETER InfoBasePath
    Путь к файловой информационной базе

.PARAMETER InfoBaseName
    Имя информационной базы из списка

.PARAMETER UserName
    Имя пользователя 1С

.PARAMETER Password
    Пароль пользователя

.PARAMETER Format
    Формат выгрузки: Hierarchical или Plain (default: Hierarchical)

.PARAMETER V8Path
    Путь к 1cv8.exe (если не указан, ищется в PATH)

.PARAMETER OutFile
    Файл для вывода служебных сообщений

.PARAMETER DebugMode
    Режим отладки с дополнительным выводом

.PARAMETER ObjectsListFile
    Файл со списком объектов для выгрузки (обязательный)

.PARAMETER Extension
    Имя расширения для выгрузки

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectsListFile "objects.txt" -InfoBasePath "C:\Bases\MyBase"

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectsListFile "objects.txt" -InfoBaseName "MyBase" -DebugMode

.NOTES
    Требует: 1cv8.exe
    Параметры можно настроить в .env файле
    
    Формат файла списка объектов (objects.txt):
    Catalogs/Справочник1.xml
    Documents/Документ1.xml
    Configuration.Help
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputDir,
    
    [Parameter(Mandatory=$false)]
    [string]$InfoBasePath,
    
    [Parameter(Mandatory=$false)]
    [string]$InfoBaseName,
    
    [Parameter(Mandatory=$false)]
    [string]$UserName,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Hierarchical", "Plain")]
    [string]$Format,
    
    [Parameter(Mandatory=$false)]
    [string]$V8Path,
    
    [Parameter(Mandatory=$false)]
    [string]$OutFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$DebugMode,
    
    [Parameter(Mandatory=$false)]
    [string]$ObjectsListFile,
    
    [Parameter(Mandatory=$false)]
    [string]$Extension
)

# Формируем параметры для вызова dump-config.ps1
$dumpConfigParams = @{
    Mode = "Partial"
}

# Передаем все остальные параметры, если они указаны
if ($OutputDir) { $dumpConfigParams['OutputDir'] = $OutputDir }
if ($InfoBasePath) { $dumpConfigParams['InfoBasePath'] = $InfoBasePath }
if ($InfoBaseName) { $dumpConfigParams['InfoBaseName'] = $InfoBaseName }
if ($UserName) { $dumpConfigParams['UserName'] = $UserName }
if ($Password) { $dumpConfigParams['Password'] = $Password }
if ($Format) { $dumpConfigParams['Format'] = $Format }
if ($V8Path) { $dumpConfigParams['V8Path'] = $V8Path }
if ($OutFile) { $dumpConfigParams['OutFile'] = $OutFile }
if ($DebugMode) { $dumpConfigParams['DebugMode'] = $true }
if ($ObjectsListFile) { $dumpConfigParams['ObjectsListFile'] = $ObjectsListFile }
if ($Extension) { $dumpConfigParams['Extension'] = $Extension }

# Вызываем основной скрипт
$scriptPath = Join-Path $PSScriptRoot "dump-config.ps1"
& $scriptPath @dumpConfigParams

exit $LASTEXITCODE