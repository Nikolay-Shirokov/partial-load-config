<#
.SYNOPSIS
    Выгрузка изменений конфигурации 1С в файлы

.DESCRIPTION
    Обертка над dump-config.ps1 для инкрементальной выгрузки только измененных объектов.
    Выполняет команду /DumpConfigToFiles с параметром -update.

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

.PARAMETER ChangesFile
    Файл для сохранения списка изменений

.PARAMETER CompareWith
    Путь к ConfigDumpInfo.xml для сравнения

.PARAMETER Force
    Принудительная полная выгрузка при несоответствии версий

.PARAMETER Extension
    Имя расширения для выгрузки

.PARAMETER AllExtensions
    Выгрузить все расширения

.EXAMPLE
    .\dump-changes-config.ps1 -OutputDir "src" -InfoBasePath "C:\Bases\MyBase"

.EXAMPLE
    .\dump-changes-config.ps1 -InfoBaseName "MyBase" -ChangesFile "changes.txt" -DebugMode

.EXAMPLE
    .\dump-changes-config.ps1 -InfoBasePath "C:\Bases\MyBase" -CompareWith "old\ConfigDumpInfo.xml" -Force

.NOTES
    Требует: 1cv8.exe
    Параметры можно настроить в .env файле
    Для работы необходим файл ConfigDumpInfo.xml от предыдущей выгрузки
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
    [string]$ChangesFile,
    
    [Parameter(Mandatory=$false)]
    [string]$CompareWith,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string]$Extension,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllExtensions
)

# Формируем параметры для вызова dump-config.ps1
$dumpConfigParams = @{
    Mode = "Changes"
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
if ($ChangesFile) { $dumpConfigParams['ChangesFile'] = $ChangesFile }
if ($CompareWith) { $dumpConfigParams['CompareWith'] = $CompareWith }
if ($Force) { $dumpConfigParams['Force'] = $true }
if ($Extension) { $dumpConfigParams['Extension'] = $Extension }
if ($AllExtensions) { $dumpConfigParams['AllExtensions'] = $true }

# Вызываем основной скрипт
$scriptPath = Join-Path $PSScriptRoot "dump-config.ps1"
& $scriptPath @dumpConfigParams

exit $LASTEXITCODE