@echo off

:: Yonetici izni kontrolu
NET FILE >nul 2>&1
if %errorlevel% neq 0 (
    echo Bu islemi gerceklestirmek icin yonetici izni gerekiyor.
    echo Script yonetici olarak yeniden baslatiliyor...
    
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

color 0A
echo ========================================
echo    WINGET GUNCELLEME (Yonetici Modu)
echo ========================================
echo.

echo 1. Mevcut guncellemeler listeleniyor...
winget upgrade --all

echo.
echo 2. Guncellemeler yukleniyor...
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

echo.
if %errorlevel%==0 (
    echo ✓ Guncelleme islemi tamamlandi!
) else (
    echo ! Guncelleme sirasinda hata olustu!
)

echo.
echo 3. Winget temizligi yapiliyor...
winget upgrade --all --disable-interactivity

echo.
echo ========================================
echo Islem tamamlandi. Pencereyi kapatabilirsiniz.
timeout /t 5 >nul
