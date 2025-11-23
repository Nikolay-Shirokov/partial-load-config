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
    Файл со списком имен объектов метаданных для выгрузки.

.PARAMETER ObjectNames
    Один или несколько объектов для выгрузки, переданные как параметр.

.PARAMETER Extension
    Имя расширения для выгрузки

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectsListFile "dump_objects.txt" -InfoBasePath "C:\Bases\MyBase"

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectNames "Справочник.Номенклатура", "Документ.РеализацияТоваровУслуг"

.EXAMPLE
    .\dump-partial-config.ps1 -ObjectNames "Справочник.Валюты" -InfoBaseName "MyBase" -DebugMode

.NOTES
    Требует: 1cv8.exe.
    Нужно указать либо -ObjectsListFile, либо -ObjectNames.
    Параметры можно настроить в .env файле.
    
    Формат файла: одна строка - одно имя объекта метаданных (например, "Справочник.Номенклатура").
#>

[CmdletBinding(DefaultParameterSetName = 'FromFile')]
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
    
    [Parameter(ParameterSetName = 'FromFile', Mandatory=$true)]
    [string]$ObjectsListFile,

    [Parameter(ParameterSetName = 'FromNames', Mandatory=$true)]
    [string[]]$ObjectNames,
    
    [Parameter(Mandatory=$false)]
    [string]$Extension
)

# Проверка, что указан либо файл, либо имена объектов, но не оба сразу
if ($PSBoundParameters.ContainsKey('ObjectsListFile') -and $PSBoundParameters.ContainsKey('ObjectNames')) {
    Write-Host "Ошибка: Нельзя одновременно использовать параметры -ObjectsListFile и -ObjectNames." -ForegroundColor Red
    exit 1
}

# Если не указан ни один из обязательных параметров (на случай запуска без параметров)
if (-not $PSBoundParameters.ContainsKey('ObjectsListFile') -and -not $PSBoundParameters.ContainsKey('ObjectNames')) {
    Write-Host "Ошибка: Необходимо указать либо -ObjectsListFile, либо -ObjectNames для частичной выгрузки." -ForegroundColor Red
    exit 1
}

$objectsToDump = @()
if ($PSBoundParameters.ContainsKey('ObjectsListFile')) {
    if (-not (Test-Path $ObjectsListFile)) {
        Write-Host "Ошибка: Файл со списком объектов не найден: $ObjectsListFile" -ForegroundColor Red
        exit 1
    }
    # Читаем содержимое файла в массив, пропуская пустые строки
    $objectsToDump = Get-Content -Path $ObjectsListFile -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
}
else {
    # Если из внешней оболочки пришел один элемент с запятыми, его нужно разделить
    if ($ObjectNames.Count -eq 1 -and $ObjectNames[0].Contains(',')) {
        $objectsToDump = $ObjectNames[0].Split(',') | ForEach-Object { $_.Trim() }
    }
    else {
        # Иначе, используем массив как есть (например, при вызове из PowerShell)
        $objectsToDump = $ObjectNames
    }
}

if ($objectsToDump.Count -eq 0) {
    Write-Host "Ошибка: Список объектов для выгрузки пуст." -ForegroundColor Red
    exit 1
}

# Формируем параметры для вызова dump-config.ps1
$dumpConfigParams = @{
    Mode = "Partial"
}

# Передаем прочитанный массив объектов
$dumpConfigParams['Objects'] = $objectsToDump

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
if ($PSBoundParameters.ContainsKey('Extension')) { $dumpConfigParams['Extension'] = $Extension }

# Вызываем основной скрипт
$scriptPath = Join-Path $PSScriptRoot "dump-config.ps1"
& $scriptPath @dumpConfigParams

exit $LASTEXITCODE