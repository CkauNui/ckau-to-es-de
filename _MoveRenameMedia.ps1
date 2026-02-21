param(
    [string]$SystemFolderName
)

# Проверяем что имя системы передано
if (-not $SystemFolderName) {
    $SystemFolderName = (Get-Location).Path | Split-Path -Leaf
}

$romsPath = "ES-DE\roms\$SystemFolderName"
$mediaBasePath = "ES-DE\downloaded_media\$SystemFolderName"

# Создаем лог-файл
$logFile = "_skipped_files_$SystemFolderName.txt"
"=== PROCESSING LOG ===" | Out-File -FilePath $logFile
"Generated: $(Get-Date)" | Out-File -FilePath $logFile -Append
"" | Out-File -FilePath $logFile -Append

# Проверяем существование папок
if (-not (Test-Path -LiteralPath $romsPath)) {
    Write-Host "ERROR: ROMs folder not found!" -ForegroundColor Red
    exit
}

if (-not (Test-Path -LiteralPath $mediaBasePath)) {
    Write-Host "ERROR: Media folder not found!" -ForegroundColor Red
    exit
}

# ==============================================
# ЧАСТЬ 1: ПЕРЕИМЕНОВАНИЕ МЕДИА
# ==============================================
Write-Host "Step 1: Renaming media files to match ROM names..." -ForegroundColor Cyan

# Получаем все ROM файлы для переименования
$romFiles = Get-ChildItem -LiteralPath $romsPath -File -Recurse

# Создаем словари для поиска
$romExact = @{}
$romClean = @{}

foreach ($rom in $romFiles) {
    $romExact[$rom.BaseName] = $rom.BaseName
    $cleanName = $rom.BaseName -replace '\s*\[.*?\]','' -replace '\s*\(.*?\)$',''
    $romClean[$cleanName] = $rom.BaseName
}

$mediaTypes = @("covers", "fanart", "marquees", "screenshots", "physicalmedia", "videos")
$totalRenamed = 0
$totalSuffixRemoved = 0

foreach ($mediaType in $mediaTypes) {
    $typePath = Join-Path $mediaBasePath $mediaType
    if (Test-Path $typePath) {
        # Получаем все медиафайлы (включая подпапки)
        $mediaFiles = Get-ChildItem $typePath -File -Recurse
        $renamedInType = 0
        $suffixInType = 0
        
        foreach ($file in $mediaFiles) {
            # Пропускаем файлы с !relpath! в имени
            if ($file.Name -like "*!relpath!*") {
                continue
            }
            
            # Убираем суффикс
            $baseName = $file.BaseName -replace '-boxart|-fanart|-wheel|-cartridge|-cd|-screenshot|-video',''
            
            # Очищаем от тегов для поиска
            $cleanName = $baseName -replace '\s*\[.*?\]','' -replace '\s*\(.*?\)$',''
            
            # Ищем соответствующий ROM
            $romName = $null
            if ($romExact.ContainsKey($baseName)) {
                $romName = $romExact[$baseName]
            }
            elseif ($romClean.ContainsKey($cleanName)) {
                $romName = $romClean[$cleanName]
            }
            
            if ($romName) {
                # Переименовываем в имя ROM
                $newName = $romName + $file.Extension
                if ($file.Name -ne $newName) {
                    try {
                        Rename-Item -LiteralPath $file.FullName -NewName $newName -Force
                        $renamedInType++
                    }
                    catch {
                        # Ошибка "файл уже существует" - пропускаем
                    }
                }
            }
            else {
                # Если ROM не найден, просто убираем суффикс
                $newName = $baseName + $file.Extension
                if ($file.Name -ne $newName) {
                    try {
                        Rename-Item -LiteralPath $file.FullName -NewName $newName -Force
                        $suffixInType++
                    }
                    catch {}
                }
            }
        }
        
        $totalRenamed += $renamedInType
        $totalSuffixRemoved += $suffixInType
    }
}

# ==============================================
# ЧАСТЬ 2: ПЕРЕМЕЩЕНИЕ МЕДИА В ПОДПАПКИ
# ==============================================
Write-Host "Step 2: Moving media files to ROM folders..." -ForegroundColor Cyan

# Получаем все ROM файлы (обновляем, если были изменения)
$romFiles = Get-ChildItem -LiteralPath $romsPath -File -Recurse

# Создаем lookup dictionary - теперь ищем по точному имени!
$romLookup = @{}
foreach ($rom in $romFiles) {
    $romLookup[$rom.BaseName] = $rom.Directory.FullName.Replace((Get-Location).Path + "\$romsPath", "").TrimStart('\')
}

# Словари для хранения статистики по пропущенным файлам
$skippedStats = @{}
foreach ($mediaType in $mediaTypes) {
    $skippedStats[$mediaType] = 0
}

$totalMoved = 0
$totalSkipped = 0

foreach ($mediaType in $mediaTypes) {
    $mediaPath = Join-Path $mediaBasePath $mediaType
    if (Test-Path -LiteralPath $mediaPath) {
        # Получаем все медиафайлы ТОЛЬКО В КОРНЕ
        $mediaFiles = Get-ChildItem -LiteralPath $mediaPath -File
        $movedInType = 0
        $skippedInType = 0
        
        # Временный список для этого типа медиа
        $skippedFiles = @()
        
        foreach ($mediaFile in $mediaFiles) {
            # Пропускаем файлы с !relpath! в имени
            if ($mediaFile.Name -like "*!relpath!*") {
                continue
            }
            
            # Получаем имя без расширения
            $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($mediaFile.Name)
            
            # Проверяем есть ли соответствующий ROM
            if ($romLookup.ContainsKey($nameWithoutExt)) {
                $romFolder = $romLookup[$nameWithoutExt]
                
                # Создаем целевую папку
                $targetDir = Join-Path $mediaPath $romFolder
                
                if (-not (Test-Path -LiteralPath $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                
                # Перемещаем файл
                $targetFile = Join-Path $targetDir $mediaFile.Name
                $sourceFile = $mediaFile.FullName
                
                try {
                    Move-Item -LiteralPath $sourceFile -Destination $targetFile -Force
                    $movedInType++
                }
                catch {
                    # Если Move не работает, пробуем Copy+Remove
                    try {
                        Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
                        if (Test-Path -LiteralPath $targetFile) {
                            Remove-Item -LiteralPath $sourceFile -Force
                            $movedInType++
                        } else {
                            $skippedInType++
                            $skippedFiles += $mediaFile.Name
                        }
                    }
                    catch {
                        $skippedInType++
                        $skippedFiles += $mediaFile.Name
                    }
                }
            } else {
                $skippedInType++
                $skippedFiles += $mediaFile.Name
            }
        }
        
        # Записываем пропущенные файлы в лог
        if ($skippedFiles.Count -gt 0) {
            "$mediaType ($skippedInType files):" | Out-File -FilePath $logFile -Append
            foreach ($file in $skippedFiles) {
                "  $file" | Out-File -FilePath $logFile -Append
            }
            "" | Out-File -FilePath $logFile -Append
        }
        
        $skippedStats[$mediaType] = $skippedInType
        $totalMoved += $movedInType
        $totalSkipped += $skippedInType
    }
}

# Финальный подсчет файлов
Write-Host "`nFINAL FILE COUNT" -ForegroundColor Cyan

$totalFilesAfter = 0
foreach ($mediaType in $mediaTypes) {
    $typePath = Join-Path $mediaBasePath $mediaType
    if (Test-Path $typePath) {
        $fileCount = (Get-ChildItem $typePath -File -Recurse).Count
        Write-Host "$mediaType : $fileCount files, skipped $($skippedStats[$mediaType])" -ForegroundColor Yellow
        $totalFilesAfter += $fileCount
    }
}
Write-Host "`nTOTAL: $totalFilesAfter files, skipped $totalSkipped" -ForegroundColor Green

# Показываем путь к логу
Write-Host "`nSkipped files list: $logFile" -ForegroundColor Cyan