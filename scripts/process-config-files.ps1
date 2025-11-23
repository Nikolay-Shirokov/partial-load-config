param(
    [string]$ChangedFilesPath,
    [string]$ConfigDir,
    [string]$TempList,
    [string]$DebugMode
)

# Получаем абсолютный путь к каталогу конфигурации
$configDirAbs = (Resolve-Path $ConfigDir).Path
$changedFiles = Get-Content -Path $ChangedFilesPath -Encoding UTF8 -ErrorAction SilentlyContinue

# Создаем файл без BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

foreach ($filePath in $changedFiles) {
    $filePath = $filePath.Trim()
    if ([string]::IsNullOrWhiteSpace($filePath)) { continue }
    
    $filePathNorm = $filePath.Replace('/', '\')
    
    if (-not $filePathNorm.StartsWith("$ConfigDir\")) { continue }
    
    $relPath = $filePathNorm.Substring($ConfigDir.Length + 1)
    
    # Пропускаем служебный файл
    if ($relPath -eq 'ConfigDumpInfo.xml') {
        if ($DebugMode -eq '1') {
            Write-Host "[DEBUG] Skipped service file: $relPath"
        }
        continue
    }
    
    # XML файлы
    if ($filePath -match '\.xml$') {
        if (Test-Path "$ConfigDir\$relPath") {
            [System.IO.File]::AppendAllText($TempList, "$relPath`r`n", $utf8NoBom)
            if ($DebugMode -eq '1') {
                Write-Host "[DEBUG] Added XML: $relPath"
            }
        }
    }
    # BSL файлы
    elseif ($filePath -match '\.bsl$') {
        if ($DebugMode -eq '1') {
            Write-Host "[DEBUG] Found BSL file: $relPath"
        }
        
        $parts = $relPath -split '\\'
        if ($parts.Count -ge 2) {
            $objType = $parts[0]
            $objName = $parts[1]
            $objXml = "$objType\$objName.xml"
            
            if (Test-Path "$ConfigDir\$objXml") {
                # Добавляем XML объекта
                [System.IO.File]::AppendAllText($TempList, "$objXml`r`n", $utf8NoBom)
                if ($DebugMode -eq '1') {
                    Write-Host "[DEBUG] Added object XML for BSL: $objXml"
                }
                
                # Добавляем BSL файл
                [System.IO.File]::AppendAllText($TempList, "$relPath`r`n", $utf8NoBom)
                if ($DebugMode -eq '1') {
                    Write-Host "[DEBUG] Added BSL: $relPath"
                }
                
                # Добавляем все файлы из Ext
                $extDir = Join-Path $configDirAbs "$objType\$objName\Ext"
                if (Test-Path $extDir) {
                    Get-ChildItem -Path $extDir -Recurse -File | ForEach-Object {
                        $extRelPath = $_.FullName.Substring($configDirAbs.Length + 1)
                        [System.IO.File]::AppendAllText($TempList, "$extRelPath`r`n", $utf8NoBom)
                        if ($DebugMode -eq '1') {
                            Write-Host "[DEBUG] Added additional file: $extRelPath"
                        }
                    }
                }
            }
        }
    }
}