<#
.SYNOPSIS
    Скрипт частичной загрузки конфигурации 1С из файлов по коммиту git

.DESCRIPTION
    Получает список измененных файлов из указанного git коммита,
    создает файл списка для частичной загрузки и выполняет команду
    LoadConfigFromFiles с параметром -partial

.PARAMETER CommitId
    Git commit identifier (required)

.PARAMETER InfoBasePath
    Path to file infobase

.PARAMETER InfoBaseName
    Infobase name from list

.PARAMETER UserName
    1C username

.PARAMETER Password
    User password

.PARAMETER ConfigDir
    Configuration directory (default: config)

.PARAMETER Format
    Format: Hierarchical or Plain (default: Hierarchical)

.PARAMETER V8Path
    Path to 1cv8.exe (if not specified, searched in PATH)

.PARAMETER OutFile
    Output file for service messages

.PARAMETER DebugMode
    Debug mode with additional output

.PARAMETER UpdateDB
    Update database configuration after loading

.PARAMETER RunEnterprise
    Run 1C:Enterprise in user mode after loading

.PARAMETER NavigationLink
    Navigation link to open in 1C:Enterprise (requires -RunEnterprise)

.PARAMETER ExternalDataProcessor
    Path to external data processor to run (requires -RunEnterprise)

.EXAMPLE
    .\partial-load-config.ps1 -CommitId "a3f5b21" -InfoBasePath "C:\Bases\MyBase" -UserName "Admin"

.EXAMPLE
    .\partial-load-config.ps1 -CommitId "HEAD~1" -InfoBaseName "MyBase" -ConfigDir ".\src"

.EXAMPLE
    .\partial-load-config.ps1 -CommitId "HEAD" -InfoBasePath "C:\Bases\MyBase" -UpdateDB

.EXAMPLE
    .\partial-load-config.ps1 -CommitId "HEAD" -InfoBasePath "C:\Bases\MyBase" -RunEnterprise -NavigationLink "e1cib/data/Catalog.Items"

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
    [switch]$DebugMode,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateDB,
    
    [Parameter(Mandatory=$false)]
    [switch]$RunEnterprise,
    
    [Parameter(Mandatory=$false)]
    [string]$NavigationLink,
    
    [Parameter(Mandatory=$false)]
    [string]$ExternalDataProcessor
)

# Установка кодировки консоли
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

function Get-ObjectXmlFromBsl {
    param([string]$BslPath, [string]$ConfigDir)
    
    $relativePath = $BslPath -replace "^$ConfigDir[\\/]", ""
    $parts = $relativePath -split '[\\/]'
    
    if ($parts.Count -ge 2) {
        $objectType = $parts[0]
        $objectName = $parts[1]
        $xmlPath = "$objectType/$objectName.xml"
        return $xmlPath
    }
    
    return $null
}

if (-not $InfoBasePath -and -not $InfoBaseName) {
    Write-ErrorInfo "InfoBasePath or InfoBaseName required"
    exit 1
}

if (-not (Test-Path $ConfigDir)) {
    Write-ErrorInfo "Config directory not found: $ConfigDir"
    exit 1
}

try {
    $null = git --version
    Write-DebugInfo "Git found"
} catch {
    Write-ErrorInfo "git not found in PATH"
    exit 1
}

# Создание временного каталога
$tempDir = Join-Path $env:TEMP "1c_partial_load_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Write-DebugInfo "Temp directory: $tempDir"

$listFile = Join-Path $tempDir "load_list.txt"

try {
    Write-Host "Getting changed files from commit $CommitId to current state..." -ForegroundColor Green
    
    # Получаем изменения от указанного коммита до HEAD
    Write-DebugInfo "Getting changes from $CommitId to HEAD..."
    $commitToHead = git diff --name-only "$CommitId..HEAD" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorInfo "Error getting changes from commit to HEAD"
        Write-Host $commitToHead
        exit 1
    }
    
    # Получаем staged изменения
    Write-DebugInfo "Getting staged changes..."
    $stagedFiles = git diff --cached --name-only 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorInfo "Error getting staged changes"
        Write-Host $stagedFiles
        exit 1
    }
    
    # Получаем unstaged изменения (измененные файлы)
    Write-DebugInfo "Getting unstaged changes..."
    $unstagedFiles = git diff --name-only 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorInfo "Error getting unstaged changes"
        Write-Host $unstagedFiles
        exit 1
    }
    
    # Получаем untracked файлы (новые файлы, не добавленные в git)
    Write-DebugInfo "Getting untracked files..."
    $untrackedFiles = git ls-files --others --exclude-standard 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ErrorInfo "Error getting untracked files"
        Write-Host $untrackedFiles
        exit 1
    }
    
    # Объединяем все изменения и убираем дубликаты
    $changedFiles = @()
    $changedFiles += $commitToHead
    $changedFiles += $stagedFiles
    $changedFiles += $unstagedFiles
    $changedFiles += $untrackedFiles
    $changedFiles = $changedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    
    Write-DebugInfo "Changes from $CommitId to HEAD: $(($commitToHead | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count) files"
    Write-DebugInfo "Staged changes: $(($stagedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count) files"
    Write-DebugInfo "Unstaged changes: $(($unstagedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count) files"
    Write-DebugInfo "Untracked files: $(($untrackedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count) files"
    Write-DebugInfo "Total unique files: $($changedFiles.Count)"
    Write-Host "Preparing file list for loading..." -ForegroundColor Green
    
    $configFiles = @()
    $configDirNormalized = $ConfigDir.TrimEnd('\', '/')
    
    foreach ($file in $changedFiles) {
        $file = $file.Trim()
        if ([string]::IsNullOrWhiteSpace($file)) { continue }
        
        if ($file -like "$configDirNormalized/*" -or $file -like "$configDirNormalized\*") {
            $relativePath = $file -replace "^$configDirNormalized[\\/]", ""
            
            # Пропускаем служебные файлы
            if ($relativePath -eq "ConfigDumpInfo.xml") {
                Write-DebugInfo "Skipped service file: $relativePath"
                continue
            }
            
            if ($file -match '\.xml$') {
                $fullPath = Join-Path $ConfigDir $relativePath
                if (Test-Path $fullPath) {
                    if ($configFiles -notcontains $relativePath) {
                        $configFiles += $relativePath
                        Write-DebugInfo "Added XML: $relativePath"
                    }
                }
            }
            elseif ($file -match '\.bsl$') {
                Write-DebugInfo "Found BSL file: $relativePath"
                
                $objectXml = Get-ObjectXmlFromBsl -BslPath $file -ConfigDir $configDirNormalized
                if ($objectXml) {
                    $fullXmlPath = Join-Path $ConfigDir $objectXml
                    if (Test-Path $fullXmlPath) {
                        if ($configFiles -notcontains $objectXml) {
                            $configFiles += $objectXml
                            Write-DebugInfo "Added object XML for BSL: $objectXml"
                        }
                        
                        if ($configFiles -notcontains $relativePath) {
                            $configFiles += $relativePath
                            Write-DebugInfo "Added BSL: $relativePath"
                        }
                        
                        $objectDir = Split-Path $fullXmlPath -Parent
                        if (Test-Path $objectDir) {
                            $extDir = Join-Path $objectDir "Ext"
                            if (Test-Path $extDir) {
                                Get-ChildItem -Path $extDir -Recurse -File | ForEach-Object {
                                    $extRelPath = $_.FullName.Replace($ConfigDir + '\', '').Replace('\', '/')
                                    if ($configFiles -notcontains $extRelPath) {
                                        $configFiles += $extRelPath
                                        Write-DebugInfo "Added additional file: $extRelPath"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    if ($configFiles.Count -eq 0) {
        Write-Host "No configuration files found for loading in commit $CommitId" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Files found for loading: $($configFiles.Count)" -ForegroundColor Green
    
    $configFiles | Out-File -FilePath $listFile -Encoding UTF8
    
    if ($DebugMode) {
        Write-DebugInfo "List file content:"
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
    Write-Host "Executing configuration load..." -ForegroundColor Green
    
    if ($DebugMode) {
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
        Write-Host "Load completed successfully" -ForegroundColor Green
    } else {
        Write-Host "Error loading configuration (code: $exitCode)" -ForegroundColor Red
    }
    
    if (Test-Path $OutFile) {
        Write-Host ""
        Write-Host "--- Execution log ---" -ForegroundColor Yellow
        Get-Content $OutFile | Write-Host
        Write-Host "--- End of log ---" -ForegroundColor Yellow
    }
    
    # Обновление конфигурации БД если запрошено
    if ($UpdateDB -and $exitCode -eq 0) {
        Write-Host ""
        Write-Host "Updating database configuration..." -ForegroundColor Green
        
        $updateArguments = @("DESIGNER")
        
        # Параметры подключения к ИБ
        if ($InfoBaseName) {
            $updateArguments += "/IBName", "`"$InfoBaseName`""
        } else {
            $updateArguments += "/F", "`"$InfoBasePath`""
        }
        
        # Учетные данные
        if ($UserName) { $updateArguments += "/N", "`"$UserName`"" }
        if ($Password) { $updateArguments += "/P", "`"$Password`"" }
        
        # Команда обновления
        $updateArguments += "/UpdateDBCfg"
        $updateArguments += "/DisableStartupDialogs"
        
        # Файл вывода
        $updateOutFile = Join-Path $tempDir "update_log.txt"
        $updateArguments += "/Out", "`"$updateOutFile`""
        
        if ($DebugMode) {
            $updateCmdLine = "$V8Path $($updateArguments -join ' ')"
            Write-DebugInfo "Update command: $updateCmdLine"
        }
        
        $updateProcess = Start-Process -FilePath $V8Path `
                                      -ArgumentList $updateArguments `
                                      -NoNewWindow `
                                      -Wait `
                                      -PassThru
        
        $updateExitCode = $updateProcess.ExitCode
        
        Write-Host ""
        if ($updateExitCode -eq 0) {
            Write-Host "Database configuration updated successfully" -ForegroundColor Green
        } else {
            Write-Host "Error updating database configuration (code: $updateExitCode)" -ForegroundColor Red
            $exitCode = $updateExitCode
        }
        
        if (Test-Path $updateOutFile) {
            Write-Host ""
            Write-Host "--- Update log ---" -ForegroundColor Yellow
            Get-Content $updateOutFile | Write-Host
            Write-Host "--- End of update log ---" -ForegroundColor Yellow
        }
    }
    
    # Запуск в режиме 1С:Предприятие если запрошено
    if ($RunEnterprise -and $exitCode -eq 0) {
        Write-Host ""
        Write-Host "Starting 1C:Enterprise..." -ForegroundColor Green
        
        $enterpriseArguments = @("ENTERPRISE")
        
        # Параметры подключения к ИБ
        if ($InfoBaseName) {
            $enterpriseArguments += "/IBName", "`"$InfoBaseName`""
        } else {
            $enterpriseArguments += "/F", "`"$InfoBasePath`""
        }
        
        # Учетные данные
        if ($UserName) { $enterpriseArguments += "/N", "`"$UserName`"" }
        if ($Password) { $enterpriseArguments += "/P", "`"$Password`"" }
        
        # Навигационная ссылка
        if ($NavigationLink) {
            $enterpriseArguments += "/URL", "`"$NavigationLink`""
        }
        
        # Внешняя обработка
        if ($ExternalDataProcessor) {
            if (Test-Path $ExternalDataProcessor) {
                $enterpriseArguments += "/Execute", "`"$ExternalDataProcessor`""
            } else {
                Write-Host "Warning: External data processor not found: $ExternalDataProcessor" -ForegroundColor Yellow
            }
        }
        
        if ($DebugMode) {
            $enterpriseCmdLine = "$V8Path $($enterpriseArguments -join ' ')"
            Write-DebugInfo "Enterprise command: $enterpriseCmdLine"
        }
        
        # Запуск в обычном режиме (неблокирующий)
        Start-Process -FilePath $V8Path -ArgumentList $enterpriseArguments
        
        Write-Host "1C:Enterprise started" -ForegroundColor Green
    }
    
    exit $exitCode
    
} finally {
    if (-not $DebugMode) {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
            Write-DebugInfo "Temporary files deleted"
        }
    } else {
        Write-DebugInfo "Temporary files saved in: $tempDir"
    }
}