<#
.SYNOPSIS
    Обновляет файл состояния выгрузки (ConfigDumpInfo.xml) до текущей конфигурации ИБ.

.DESCRIPTION
    Обертка над dump-config.ps1 для вызова с ключом -configDumpInfoOnly.
    Это необходимо для "фиксации" состояния после инкрементальной выгрузки.

.PARAMETER ConfigDir
    Каталог, в котором находится ConfigDumpInfo.xml. Переопределяет CONFIG_DIR из .env.

.PARAMETER InfoBasePath
    Путь к файловой информационной базе.

.PARAMETER InfoBaseName
    Имя информационной базы из списка.

.EXAMPLE
    .\update-dump-info.ps1 -ConfigDir "src" -InfoBasePath "C:\Bases\MyBase"
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
    [string]$V8Path,
    
    [Parameter(Mandatory=$false)]
    [string]$OutFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$DebugMode
)

# Формируем параметры для вызова dump-config.ps1
$dumpConfigParams = @{
    Mode = "UpdateInfo"
}

# Передаем все остальные параметры, если они указаны
if ($PSBoundParameters.ContainsKey('ConfigDir')) { $dumpConfigParams['OutputDir'] = $ConfigDir }
if ($PSBoundParameters.ContainsKey('InfoBasePath')) { $dumpConfigParams['InfoBasePath'] = $InfoBasePath }
if ($PSBoundParameters.ContainsKey('InfoBaseName')) { $dumpConfigParams['InfoBaseName'] = $InfoBaseName }
if ($PSBoundParameters.ContainsKey('UserName')) { $dumpConfigParams['UserName'] = $UserName }
if ($PSBoundParameters.ContainsKey('Password')) { $dumpConfigParams['Password'] = $Password }
if ($PSBoundParameters.ContainsKey('V8Path')) { $dumpConfigParams['V8Path'] = $V8Path }
if ($PSBoundParameters.ContainsKey('OutFile')) { $dumpConfigParams['OutFile'] = $OutFile }
if ($PSBoundParameters.ContainsKey('DebugMode')) { $dumpConfigParams['DebugMode'] = $true }

# Вызываем основной скрипт
$scriptPath = Join-Path $PSScriptRoot "dump-config.ps1"
& $scriptPath @dumpConfigParams

exit $LASTEXITCODE