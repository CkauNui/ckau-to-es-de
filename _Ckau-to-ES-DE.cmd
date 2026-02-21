@echo off
echo                  #####                  #####
echo                  #####                  #####
echo                  #####                  #####
echo                      #####          #####
echo                      #####          #####
echo                  ############################
echo                  ############################
echo              #########    ##########    #########
echo              #########    ##########    #########
echo          ############################################
echo          ############################################
echo          ############################################
echo          #####   ############################   #####
echo          #####   ############################   #####
echo          #####   #####                  #####   #####
echo          #####   #############  #############   #####
echo                      #########  #########
echo                      #########  #########
echo.
echo ==============================================================
echo            Добро пожаловать в инструмент конвертации
echo --------------------------------------------------------------
echo         Скрипт подготовит коллекции оформлений от Ckau
echo                    для использования в ES-DE
echo ==============================================================

ping -n 4 127.0.0.1 > nul
cls

for %%i in (%CD%) do set SystemFolderName=%%~ni
echo.
echo ==============================================================
echo                 Копирование медиа в новую папку               
echo                    Пожалуйста, подождите...                   
echo ==============================================================
REM Копируем только те папки, которые реально существуют
if exist media\boxart robocopy media\boxart ES-DE\downloaded_media\%SystemFolderName%\covers /E /XF *-0?.* /NJH /NJS /NFL
if exist media\fanart robocopy media\fanart ES-DE\downloaded_media\%SystemFolderName%\fanart /E /XF *-0?.* /NJH /NJS /NFL
if exist media\wheel robocopy media\wheel ES-DE\downloaded_media\%SystemFolderName%\marquees /E /XF *-0?.* /NJH /NJS /NFL
if exist media\art robocopy media\art ES-DE\downloaded_media\%SystemFolderName%\screenshots /E /XF *-0?.* /NJH /NJS /NFL
if exist media\cd robocopy media\cd ES-DE\downloaded_media\%SystemFolderName%\physicalmedia /E /XF *-0?.* /NJH /NJS /NFL
if exist media\cartridge robocopy media\cartridge ES-DE\downloaded_media\%SystemFolderName%\physicalmedia /E /XF *-0?.* /NJH /NJS /NFL
if exist media\video robocopy media\video ES-DE\downloaded_media\%SystemFolderName%\videos /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\boxart robocopy _media\boxart ES-DE\downloaded_media\%SystemFolderName%\covers /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\fanart robocopy _media\fanart ES-DE\downloaded_media\%SystemFolderName%\fanart /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\wheel robocopy _media\wheel ES-DE\downloaded_media\%SystemFolderName%\marquees /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\art robocopy _media\art ES-DE\downloaded_media\%SystemFolderName%\screenshots /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\cd robocopy _media\cd ES-DE\downloaded_media\%SystemFolderName%\physicalmedia /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\cartridge robocopy _media\cartridge ES-DE\downloaded_media\%SystemFolderName%\physicalmedia /E /XF *-0?.* /NJH /NJS /NFL
if exist _media\video robocopy _media\video ES-DE\downloaded_media\%SystemFolderName%\videos /E /XF *-0?.* /NJH /NJS /NFL
echo.
echo Копирование геймлиста...
mkdir ES-DE\gamelists 2>nul
mkdir ES-DE\gamelists\%SystemFolderName% 2>nul
if exist gamelist.xml copy gamelist.xml ES-DE\gamelists\%SystemFolderName%\gamelist.xml >nul

REM Конвертация fanart из PNG в JPG
echo Конвертация фанартов из PNG в JPG...
if exist ES-DE\downloaded_media\%SystemFolderName%\fanart (
    for /R "ES-DE\downloaded_media\%SystemFolderName%\fanart" %%i in (*.png) do (
        _ffmpeg -y -i "%%i" -preset ultrafast "%%~dpni.jpg" >nul 2>&1
    )
    ping -n 2 127.0.0.1 > nul
    del /S /Q "ES-DE\downloaded_media\%SystemFolderName%\fanart\*.png" >nul 2>&1
)

echo.
echo ==============================================================
echo             Копирование ROM-файлов в новую папку              
echo                    Пожалуйста, подождите...                   
echo ==============================================================
REM Создаем целевую папку
mkdir "ES-DE\roms\%SystemFolderName%" 2>nul
REM Копируем все ROM файлы
robocopy . "ES-DE\roms\%SystemFolderName%" /S /XD "media" "_media" "ES-DE" /NJH /NJS /NFL
echo.
REM Удаление служебных файлов
echo Очистка служебных файлов...
ping -n 2 127.0.0.1 > nul
del /S /Q "ES-DE\roms\%SystemFolderName%\_info.txt" >nul 2>&1
del /S /Q "ES-DE\roms\%SystemFolderName%\gamelist.xml" >nul 2>&1
del /S /Q "ES-DE\roms\%SystemFolderName%\_ffmpeg.exe" >nul 2>&1
del /S /Q "ES-DE\roms\%SystemFolderName%\_Ckau-to-ES-DE.cmd" >nul 2>&1
del /S /Q "ES-DE\roms\%SystemFolderName%\_Ckau-to-ES-DE-EN.cmd" >nul 2>&1
del /S /Q "ES-DE\roms\%SystemFolderName%\_MoveRenameMedia.ps1" >nul 2>&1

REM Удаляем пустые папки
echo Удаление пустых папок...
for /f "delims=" %%d in ('dir "ES-DE\roms\%SystemFolderName%" /ad /b /s ^| sort /r') do (
    rd "%%d" 2>nul
)

echo.
echo.
echo ==============================================================
echo              Хотите уменьшить размер изображений?
echo --------------------------------------------------------------
echo           Полезно при использовании ES-DE на Android
echo ==============================================================
echo.
echo                    Y = ДА            N = НЕТ
echo.
choice /C YN /N /T 60 /D Y /M "Ваш выбор [Y/N]: "
if %errorlevel%==1 goto optimize_images
if %errorlevel%==2 goto NEXT2

:optimize_images
echo.
echo Вы выбрали ДА, изображения будут оптимизированы
echo.

REM Оптимизация covers
if exist "ES-DE\downloaded_media\%SystemFolderName%\covers" (
    echo Оптимизация папки covers, пожалуйста, подождите...

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\covers\*.png") do (
        _ffmpeg -nostdin -i "%%i" -vf "scale=-2:680,format=rgba" -y "%%~dpni_optimized.png" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.png" "%%~nxi" 2>nul
    )

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\covers\*.jpg") do (
        _ffmpeg -nostdin -i "%%i" -vf "scale=-2:680" -y "%%~dpni_optimized.jpg" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.jpg" "%%~nxi" 2>nul
    )
)

REM Оптимизация screenshots
if exist "ES-DE\downloaded_media\%SystemFolderName%\screenshots" (
    echo Оптимизация папки screenshots, пожалуйста, подождите...

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\screenshots\*.png") do (
        _ffmpeg -nostdin -i "%%i" -vf "scale=-2:360,format=rgba" -y "%%~dpni_optimized.png" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.png" "%%~nxi" 2>nul
    )
    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\screenshots\*.jpg") do (
        _ffmpeg -nostdin -i "%%i" -vf scale=-2:360 -y "%%~dpni_optimized.jpg" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.jpg" "%%~nxi" 2>nul
    )
)

REM Оптимизация marquees
if exist "ES-DE\downloaded_media\%SystemFolderName%\marquees" (
    echo Оптимизация папки marquees, пожалуйста, подождите...

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\marquees\*.png") do (
        _ffmpeg -nostdin -i "%%i" -vf "scale=400:-2,format=rgba" -y "%%~dpni_optimized.png" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.png" "%%~nxi" 2>nul
    )

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\marquees\*.jpg") do (
        _ffmpeg -nostdin -i "%%i" -vf scale=400:-2 -y "%%~dpni_optimized.jpg" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.jpg" "%%~nxi" 2>nul
    )
)

REM Оптимизация fanart
if exist "ES-DE\downloaded_media\%SystemFolderName%\fanart" (
    echo Оптимизация папки fanart, пожалуйста, подождите...

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\fanart\*.png") do (
        _ffmpeg -nostdin -i "%%i" -vf "scale=960:-2,format=rgba" -y "%%~dpni_optimized.png" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.png" "%%~nxi" 2>nul
    )

    for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\fanart\*.jpg") do (
        _ffmpeg -nostdin -i "%%i" -vf scale=960:-2 -y "%%~dpni_optimized.jpg" >nul 2>&1
        del "%%i" 2>nul
        rename "%%~dpni_optimized.jpg" "%%~nxi" 2>nul
    )
)

echo.
goto NEXT2

:NEXT2
echo.
echo.
echo ==============================================================
echo           Хотите уменьшить разрешение и размер видео?
echo --------------------------------------------------------------
echo           Полезно при использовании ES-DE на Android
echo        (Видео обрезаются до 15 секунд, разрешение 240p)
echo ==============================================================
echo.
echo                    Y = ДА            N = НЕТ
echo.
choice /C YN /N /T 60 /D Y /M "Ваш выбор [Y/N]: "
if %errorlevel%==1 goto optimize_video
if %errorlevel%==2 goto NEXT3

:optimize_video
echo.
echo Вы выбрали ДА, видео будут оптимизированы
echo.
echo Оптимизация папки videos, пожалуйста, подождите...
echo.
REM Обрабатываем все видео в исходной папке (БЕЗ рекурсии)
for %%i in ("ES-DE\downloaded_media\%SystemFolderName%\videos\*.mp4" ^
            "ES-DE\downloaded_media\%SystemFolderName%\videos\*.avi" ^
            "ES-DE\downloaded_media\%SystemFolderName%\videos\*.mkv") do (

    echo Обработка: %%~nxi

    _ffmpeg -nostdin -i "%%i" -hide_banner -loglevel error ^
        -ss 00:00:00 -to 00:00:15 ^
        -vf "fade=t=in:st=0:d=2,fade=t=out:st=13:d=2,scale=-2:240,fps=30" ^
        -af "afade=t=in:st=0:d=2,afade=t=out:st=13:d=2" ^
        -c:v:0 h264 -b:v 350k -y "%%~dpni_optimized.mp4"

    REM Удаляет оригинал и переименовывает оптимизированный
    del "%%i" 2>nul
    rename "%%~dpni_optimized.mp4" "%%~nxi" 2>nul
)

echo.
goto NEXT3

:NEXT3
echo.
echo.
echo ==============================================================
echo         Перемещение и переименование медиа согласно ROM       
echo ==============================================================
echo.
REM Запускаем PowerShell скрипт для перемещения и переименования медиа
powershell -ExecutionPolicy Bypass -File "_MoveRenameMedia.ps1" -SystemFolderName "%SystemFolderName%"
echo.
echo ==============================================================
echo                             Готово!
echo                Нажмите любую клавишу для выхода
echo ==============================================================
pause > nul 2>&1