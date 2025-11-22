<#
.SYNOPSIS
    Универсальный скрипт выгрузки конфигурации 1С в файлы

.DESCRIPTION
    Выполняет выгрузку конфигурации 1С в файлы в трех режимах:
    - Full: полная выгрузка всей конфигурации
    - Changes: выгрузка только измененных объектов
    - Partial: выгрузка конкретных объектов из списка

.PARAMETER Mode
    Режим выгрузки: Full, Changes, Partial (default: Changes)

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

.PARAMETER Objects
    Массив имен объектов метаданных для частичной выгрузки (для режима Partial).

.PARAMETER ChangesFile
    Файл для сохранения списка изменений (для режима Changes)

.PARAMETER CompareWith
    Путь к ConfigDumpInfo.xml для сравнения (для режима Changes)

.PARAMETER UpdateMode
    Режим обновления выгрузки (для режима Changes)

.PARAMETER Force
    Принудительная полная выгрузка при несоответствии версий (для режима Changes)

.PARAMETER Extension
    Имя расширения для выгрузки

.PARAMETER AllExtensions
    Выгрузить все расширения

.EXAMPLE
    .\dump-config.ps1 -Mode Full -OutputDir "src" -InfoBasePath "C:\Bases\MyBase"

.EXAMPLE
    .\dump-config.ps1 -Mode Changes -ChangesFile "changes.txt" -InfoBaseName "MyBase"

.EXAMPLE
    .\dump-config.ps1 -Mode Partial -Objects @("Справочник.Номенклатура", "Документ.РеализацияТоваровУслуг") -InfoBasePath "C:\Bases\MyBase"

.NOTES
    Требует: 1cv8.exe
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "Changes", "Partial")]
    [string]$Mode = "Changes",
    
    [Parameter(Mandatory=$false)]
    [Alias("ConfigDir")]
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
    [string]$Format = "Hierarchical",
    
    [Parameter(Mandatory=$false)]
    [string]$V8Path = "1cv8.exe",
    
    [Parameter(Mandatory=$false)]
    [string]$OutFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$DebugMode,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Objects,
    
    [Parameter(Mandatory=$false)]
    [string]$ChangesFile,
    
    [Parameter(Mandatory=$false)]
    [string]$CompareWith,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateMode,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string]$Extension,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllExtensions
)

# Устанавливаем кодировку для текущей сессии PowerShell
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# Функция для загрузки переменных окружения из .env файла
function Import-EnvFile {
    param([string]$EnvFilePath = ".env")
    
    if (Test-Path $EnvFilePath) {
        Get-Content $EnvFilePath -Encoding UTF8 | ForEach-Object {
            $line = $_.Trim()
            # Пропускаем пустые строки и комментарии
            if ($line -and -not $line.StartsWith('#')) {
                if ($line -match '^([^=]+)=(.*)$') {
                    $name = $matches[1].Trim()
                    $value = $matches[2].Trim()
                    # Удаляем кавычки если есть
                    $value = $value -replace '^["'']|["'']$', ''
                    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
                }
            }
        }
        return $true
    }
    return $false
}

# Загружаем переменные окружения из .env файла (если существует)
$envLoaded = Import-EnvFile
if ($envLoaded) {
    Write-Verbose "Environment variables loaded from .env file"
}

# Приоритет: Параметр командной строки → .env файл → Значение по умолчанию
if (-not $PSBoundParameters.ContainsKey('V8Path')) {
    $envV8Path = [Environment]::GetEnvironmentVariable('V8_PATH', 'Process')
    if ($envV8Path) { $V8Path = $envV8Path }
}

if (-not $PSBoundParameters.ContainsKey('OutputDir')) {
    $envOutputDir = [Environment]::GetEnvironmentVariable('DUMP_OUTPUT_DIR', 'Process')
    if ($envOutputDir) {
        $OutputDir = $envOutputDir
    } else {
        # Если DUMP_OUTPUT_DIR не задан, пробуем использовать CONFIG_DIR для единообразия
        $envConfigDir = [Environment]::GetEnvironmentVariable('CONFIG_DIR', 'Process')
        if ($envConfigDir) { $OutputDir = $envConfigDir }
    }
}

if (-not $PSBoundParameters.ContainsKey('Format')) {
    $envFormat = [Environment]::GetEnvironmentVariable('CONFIG_FORMAT', 'Process')
    if ($envFormat -and ($envFormat -eq 'Hierarchical' -or $envFormat -eq 'Plain')) {
        $Format = $envFormat
    }
}

if (-not $PSBoundParameters.ContainsKey('Mode')) {
    $envMode = [Environment]::GetEnvironmentVariable('DUMP_MODE', 'Process')
    if ($envMode -and ($envMode -eq 'Full' -or $envMode -eq 'Changes' -or $envMode -eq 'Partial')) {
        $Mode = $envMode
    }
}

if (-not $PSBoundParameters.ContainsKey('InfoBasePath')) {
    $envInfoBasePath = [Environment]::GetEnvironmentVariable('INFOBASE_PATH', 'Process')
    if ($envInfoBasePath) { $InfoBasePath = $envInfoBasePath }
}

if (-not $PSBoundParameters.ContainsKey('InfoBaseName')) {
    $envInfoBaseName = [Environment]::GetEnvironmentVariable('INFOBASE_NAME', 'Process')
    if ($envInfoBaseName) { $InfoBaseName = $envInfoBaseName }
}

if (-not $PSBoundParameters.ContainsKey('UserName')) {
    $envUserName = [Environment]::GetEnvironmentVariable('USERNAME_1C', 'Process')
    if ($envUserName) { $UserName = $envUserName }
}

if (-not $PSBoundParameters.ContainsKey('Password')) {
    $envPassword = [Environment]::GetEnvironmentVariable('PASSWORD_1C', 'Process')
    if ($envPassword) { $Password = $envPassword }
}

if (-not $PSBoundParameters.ContainsKey('OutFile')) {
    $envOutFile = [Environment]::GetEnvironmentVariable('OUT_FILE', 'Process')
    if ($envOutFile) { $OutFile = $envOutFile }
}

if (-not $PSBoundParameters.ContainsKey('DebugMode')) {
    $envDebugMode = [Environment]::GetEnvironmentVariable('DEBUG_MODE', 'Process')
    if ($envDebugMode -eq 'true') { $DebugMode = $true }
}

if (-not $PSBoundParameters.ContainsKey('Objects')) {
    # .env для этого параметра больше не поддерживается
}

if (-not $PSBoundParameters.ContainsKey('ChangesFile')) {
    $envChangesFile = [Environment]::GetEnvironmentVariable('DUMP_CHANGES_FILE', 'Process')
    if ($envChangesFile) { $ChangesFile = $envChangesFile }
}

if (-not $PSBoundParameters.ContainsKey('CompareWith')) {
    $envCompareWith = [Environment]::GetEnvironmentVariable('DUMP_COMPARE_WITH', 'Process')
    if ($envCompareWith) { $CompareWith = $envCompareWith }
}

# Функция для вывода отладочной информации
function Write-DebugInfo {
    param([string]$Message)
    if ($DebugMode) {
        Write-Host "[DEBUG] $Message" -ForegroundColor Cyan
    }
}

function Write-ErrorInfo {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
}

# Проверка обязательных параметров
if (-not $InfoBasePath -and -not $InfoBaseName) {
    Write-ErrorInfo "InfoBasePath or InfoBaseName required"
    exit 1
}

# Проверка параметров для режима Partial
if ($Mode -eq "Partial" -and (-not $Objects -or $Objects.Count -eq 0)) {
    Write-ErrorInfo "At least one object required for Partial mode"
    Write-Host "Please specify objects using -Objects parameter" -ForegroundColor Yellow
    exit 1
}

# Создание выходного каталога если не существует
if (-not (Test-Path $OutputDir)) {
    Write-Host "Creating output directory: $OutputDir" -ForegroundColor Green
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Проверка существования 1cv8.exe
$v8Exists = $false
if ([System.IO.Path]::IsPathRooted($V8Path)) {
    $v8Exists = Test-Path $V8Path
} else {
    try {
        $null = Get-Command $V8Path -ErrorAction Stop
        $v8Exists = $true
    } catch {
        $v8Exists = $false
    }
}

if (-not $v8Exists) {
    Write-Host ""
    Write-ErrorInfo "1C:Enterprise platform (1cv8.exe) not found"
    Write-Host ""
    Write-Host "Checked path: $V8Path" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Cyan
    Write-Host "  1. 1C:Enterprise is installed" -ForegroundColor Gray
    Write-Host "  2. Correct path specified in V8_PATH parameter or .env file" -ForegroundColor Gray
    Write-Host "  3. 1cv8.exe is in system PATH (if using relative path)" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

Write-DebugInfo "Using 1C platform: $V8Path"
Write-DebugInfo "Dump mode: $Mode"
Write-DebugInfo "Output directory: $OutputDir"
Write-DebugInfo "Format: $Format"

# Создание временного каталога
$tempDir = Join-Path $env:TEMP "1c_dump_config_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-DebugInfo "Temp directory: $tempDir"

try {
    # Формирование командной строки для 1cv8
    $arguments = @("DESIGNER")
    
    # Параметры подключения к ИБ
    if ($InfoBaseName) {
        $arguments += "/IBName", "`"$InfoBaseName`""
    } else {
        $arguments += "/F", "`"$InfoBasePath`""
    }
    
    # Учетные данные
    if ($UserName) { $arguments += "/N", "`"$UserName`"" }
    if ($Password) { $arguments += "/P", "`"$Password`"" }
    
    # Команда выгрузки
    $arguments += "/DumpConfigToFiles", "`"$OutputDir`""
    
    # Формат выгрузки
    $arguments += "-Format", $Format
    
    # Параметры в зависимости от режима
    switch ($Mode) {
        "Full" {
            Write-Host "Executing full configuration dump..." -ForegroundColor Green
            # Для полной выгрузки дополнительных параметров не нужно
        }
        
        "Changes" {
            Write-Host "Executing incremental configuration dump..." -ForegroundColor Green
            $arguments += "-update"
            
            if ($ChangesFile) {
                $arguments += "-getChanges", "`"$ChangesFile`""
                Write-DebugInfo "Changes will be saved to: $ChangesFile"
            }
            
            if ($CompareWith) {
                if (Test-Path $CompareWith) {
                    $arguments += "-configDumpInfoForChanges", "`"$CompareWith`""
                    Write-DebugInfo "Comparing with: $CompareWith"
                } else {
                    Write-Host "Warning: ConfigDumpInfo file not found: $CompareWith" -ForegroundColor Yellow
                }
            }
            
            if ($Force) {
                $arguments += "-force"
                Write-DebugInfo "Force mode enabled"
            }
        }
        
        "Partial" {
            Write-Host "Executing partial configuration dump..." -ForegroundColor Green
            
            # Создаем временный файл в КОРНЕ ПРОЕКТА, чтобы избежать проблем с путями.
            $tempListFile = Join-Path $PSScriptRoot "partial_dump_list.txt"
            $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
            [System.IO.File]::WriteAllLines($tempListFile, $Objects, $utf8WithBom)

            $arguments += "-listFile", "`"$tempListFile`""
            Write-DebugInfo "Using temp list file with correct encoding: $tempListFile"
            
            if ($DebugMode) {
                Write-DebugInfo "Objects list content:"
                $Objects | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
            }
        }
    }
    
    # Расширения
    if ($Extension) {
        $arguments += "-Extension", "`"$Extension`""
        Write-DebugInfo "Dumping extension: $Extension"
    } elseif ($AllExtensions) {
        $arguments += "-AllExtensions"
        Write-DebugInfo "Dumping all extensions"
    }
    
    # Вывод служебных сообщений
    if (-not $OutFile) {
        $OutFile = Join-Path $tempDir "dump_log.txt"
    }
    $arguments += "/Out", "`"$OutFile`""
    
    # Отключение диалогов
    $arguments += "/DisableStartupDialogs"
    
    # Выполнение команды
    Write-Host ""
    if ($DebugMode) {
        $cmdLine = "$V8Path $($arguments -join ' ')"
        Write-DebugInfo "Command: $cmdLine"
    }
    
    $process = Start-Process -FilePath $V8Path `
                            -ArgumentList $arguments `
                            -NoNewWindow `
                            -Wait `
                            -PassThru
    
    $exitCode = $process.ExitCode
    
    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Host "Dump completed successfully" -ForegroundColor Green
        Write-Host "Configuration dumped to: $OutputDir" -ForegroundColor Green
        
        # Выводим информацию об изменениях для режима Changes
        if ($Mode -eq "Changes" -and $ChangesFile -and (Test-Path $ChangesFile)) {
            Write-Host ""
            Write-Host "--- Changes detected ---" -ForegroundColor Yellow
            Get-Content $ChangesFile | Write-Host
            Write-Host "--- End of changes ---" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Error dumping configuration (code: $exitCode)" -ForegroundColor Red
    }
    
    if (Test-Path $OutFile) {
        Write-Host ""
        Write-Host "--- Execution log ---" -ForegroundColor Yellow
        Get-Content $OutFile | Write-Host
        Write-Host "--- End of log ---" -ForegroundColor Yellow
    }
    
    exit $exitCode
    
} finally {
    # Удаляем временный файл списка, если он был создан
    if (Test-Path $tempListFile) {
        Remove-Item -Path $tempListFile -Force
        Write-DebugInfo "Temporary list file deleted"
    }

    if (-not $DebugMode) {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
            Write-DebugInfo "Temporary files deleted"
        }
    } else {
        Write-DebugInfo "Temporary files saved in: $tempDir"
    }
}