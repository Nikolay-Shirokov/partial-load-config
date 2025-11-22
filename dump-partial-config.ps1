<#
.SYNOPSIS
    Частичная выгрузка конфигурации 1С в файлы

.DESCRIPTION
    Обертка над dump-config.ps1 для выгрузки конкретных объектов из файла.

.PARAMETER ConfigDir
    Каталог для выгрузки конфигурации. Переопределяет CONFIG_DIR из .env.

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
    Файл со списком имен объектов метаданных для выгрузки (обязательный).

.PARAMETER Extension
    Имя расширения для выгрузки

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectsListFile "dump_objects.txt" -InfoBasePath "C:\Bases\MyBase"

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectsListFile "dump_objects.txt" -InfoBaseName "MyBase" -DebugMode

.NOTES
    Требует: 1cv8.exe
    Параметры можно настроить в .env файле
    
    Формат файла: одна строка - одно имя объекта метаданных (например, "Справочник.Номенклатура").
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigDir,
    
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
if ($PSBoundParameters.ContainsKey('ConfigDir')) { $dumpConfigParams['OutputDir'] = $ConfigDir }
if ($PSBoundParameters.ContainsKey('InfoBasePath')) { $dumpConfigParams['InfoBasePath'] = $InfoBasePath }
if ($PSBoundParameters.ContainsKey('InfoBaseName')) { $dumpConfigParams['InfoBaseName'] = $InfoBaseName }
if ($PSBoundParameters.ContainsKey('UserName')) { $dumpConfigParams['UserName'] = $UserName }
if ($PSBoundParameters.ContainsKey('Password')) { $dumpConfigParams['Password'] = $Password }
if ($PSBoundParameters.ContainsKey('Format')) { $dumpConfigParams['Format'] = $Format }
if ($PSBoundParameters.ContainsKey('V8Path')) { $dumpConfigParams['V8Path'] = $V8Path }
if ($PSBoundParameters.ContainsKey('OutFile')) { $dumpConfigParams['OutFile'] = $OutFile }
if ($PSBoundParameters.ContainsKey('DebugMode')) { $dumpConfigParams['DebugMode'] = $true }
if ($PSBoundParameters.ContainsKey('ObjectsListFile')) { $dumpConfigParams['ObjectsListFile'] = $ObjectsListFile }
if ($PSBoundParameters.ContainsKey('Extension')) { $dumpConfigParams['Extension'] = $Extension }

# Вызываем основной скрипт
$scriptPath = Join-Path $PSScriptRoot "dump-config.ps1"
& $scriptPath @dumpConfigParams

exit $LASTEXITCODE