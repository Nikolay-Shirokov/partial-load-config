<#
.SYNOPSIS
    Скрипт частичной загрузки конфигурации 1С из файлов по коммиту git

.DESCRIPTION
    Получает список измененных файлов из указанного git коммита,
    создает файл списка для частичной загрузки и выполняет команду
    LoadConfigFromFiles с параметром -partial

.PARAMETER CommitId
    Идентификатор коммита git (обязательный)

.PARAMETER InfoBasePath
    Путь к файловой информационной базе

.PARAMETER InfoBaseName
    Имя информационной базы из списка

.PARAMETER UserName
    Имя пользователя 1С

.PARAMETER Password
    Пароль пользователя 1С

.PARAMETER ConfigDir
    Каталог с выгруженной конфигурацией (по умолчанию: config)

.PARAMETER Format
    Формат конфигурации: Hierarchical или Plain (по умолчанию: Hierarchical)

.PARAMETER V8Path
    Путь к 1cv8.exe (если не указан, ищется в PATH)

.PARAMETER OutFile
    Файл для вывода служебных сообщений

.PARAMETER Debug
    Режим отладки с дополнительным выводом

.EXAMPLE
    .\partial-load-config.ps1 -CommitId "a3f5b21" -InfoBasePath "C:\Bases\MyBase" -UserName "Admin"

.EXAMPLE
    .\partial-load-config.ps1 -CommitId "HEAD~1" -InfoBaseName "MyBase" -ConfigDir ".\src"

.NOTES
    Требует: git, 1cv8.exe
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$CommitId,
    
    [Parameter(Mandatory=$false)]
    [string]$InfoBasePath,
    
    [Parameter(Mandatory=$false)]
    [string]$InfoBaseName,
    
    [Parameter(Mandatory=$false)]
    [string]$UserName,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigDir = "config",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Hierarchical", "Plain")]
    [string]$Format = "Hierarchical",
    
    [Parameter(Mandatory=$false)]
    [string]$V8Path = "1cv8.exe",
    
    [Parameter(Mandatory=$false)]
    [string]$OutFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$Debug
)

# Установка кодировки консоли
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Функция для вывода отладочной информации
function Write-DebugInfo {
    param([string]$Message)
    if ($Debug) {
        Write-Host "[DEBUG] $Message" -ForegroundColor Cyan
    }
}

# Функция для вывода ошибок
function Write-ErrorInfo {
    param([string]$Message)
    Write-Host "Ошибка: $Message" -ForegroundColor Red
}

# Проверка параметров
if (-not $InfoBasePath -and -not $InfoBaseName) {
    Write-ErrorInfo "Необходимо указать -InfoBasePath или -InfoBaseName"
    exit 1
}

if (-not (Test-Path $ConfigDir)) {
    Write-ErrorInfo "Каталог конфигурации не найден: $ConfigDir"
    exit 1
}

# Проверка наличия git
try {
    $null = git --version
    Write-DebugInfo "Git найден"
} catch {
    Write-ErrorInfo "git не найден в PATH"
    exit 1
}

# Создание временного каталога
$tempDir = Join-Path $env:TEMP "1c_partial_load_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-DebugInfo "Временный каталог: $tempDir"

$listFile = Join-Path $tempDir "load_list.txt"

try {
    # Получение списка измененных файлов из коммита
    Write-Host "Получение списка измененных файлов из коммита $CommitId..." -ForegroundColor Green
    
    $changedFiles = git show --pretty="" --name-only $CommitId 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorInfo "Ошибка при получении списка файлов из git"
        Write-Host $changedFiles
        exit 1
    }
    
    Write-DebugInfo "Всего измененных файлов: $($changedFiles.Count)"
    
    # Фильтрация и подготовка списка файлов для загрузки
    Write-Host "Подготовка списка файлов для загрузки..." -ForegroundColor Green
    
    $configFiles = @()
    $configDirNormalized = $ConfigDir.TrimEnd('\', '/')
    
    foreach ($file in $changedFiles) {
        $file = $file.Trim()
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        
        # Проверяем, что файл из каталога конфигурации
        if ($file -like "$configDirNormalized/*" -or $file -like "$configDirNormalized\*") {
            # Проверяем расширение (xml для конфигурации)
            if ($file -match '\.xml$') {
                # Получаем относительный путь
                $relativePath = $file -replace "^$configDirNormalized[\\/]", ""
                
                # Проверяем существование файла
                $fullPath = Join-Path $ConfigDir $relativePath
                if (Test-Path $fullPath) {
                    $configFiles += $relativePath
                    Write-DebugInfo "Добавлен: $relativePath"
                } else {
                    Write-DebugInfo "Файл не найден (возможно удален): $relativePath"
                }
            }
        }
    }
    
    if ($configFiles.Count -eq 0) {
        Write-Host "Не найдено ни одного файла конфигурации для загрузки в коммите $CommitId" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Найдено файлов для загрузки: $($configFiles.Count)" -ForegroundColor Green
    
    # Сохранение списка в файл
    $configFiles | Out-File -FilePath $listFile -Encoding UTF8
    
    if ($Debug) {
        Write-DebugInfo "Содержимое файла списка:"
        Get-Content $listFile | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    
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
    
    # Параметры загрузки
    $arguments += "/LoadConfigFromFiles", "`"$ConfigDir`""
    $arguments += "-listFile", "`"$listFile`""
    $arguments += "-Format", $Format
    $arguments += "-partial"
    $arguments += "-updateConfigDumpInfo"
    
    # Вывод служебных сообщений
    if (-not $OutFile) {
        $OutFile = Join-Path $tempDir "load_log.txt"
    }
    $arguments += "/Out", "`"$OutFile`""
    
    # Отключение диалогов
    $arguments += "/DisableStartupDialogs"
    
    # Выполнение команды
    Write-Host ""
    Write-Host "Выполнение загрузки конфигурации..." -ForegroundColor Green
    
    if ($Debug) {
        $cmdLine = "$V8Path $($arguments -join ' ')"
        Write-DebugInfo "Команда: $cmdLine"
    }
    
    $process = Start-Process -FilePath $V8Path `
                            -ArgumentList $arguments `
                            -NoNewWindow `
                            -Wait `
                            -PassThru
    
    $exitCode = $process.ExitCode
    
    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Host "Загрузка завершена успешно" -ForegroundColor Green
    } else {
        Write-Host "Ошибка при загрузке конфигурации (код: $exitCode)" -ForegroundColor Red
    }
    
    # Вывод лога
    if (Test-Path $OutFile) {
        Write-Host ""
        Write-Host "--- Лог выполнения ---" -ForegroundColor Yellow
        Get-Content $OutFile | Write-Host
        Write-Host "--- Конец лога ---" -ForegroundColor Yellow
    }
    
    exit $exitCode
    
} finally {
    # Очистка временных файлов
    if (-not $Debug) {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
            Write-DebugInfo "Временные файлы удалены"
        }
    } else {
        Write-DebugInfo "Временные файлы сохранены в: $tempDir"
    }
}