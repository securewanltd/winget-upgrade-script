@echo off
title Winget Paket Guncelleme
color 0A

echo ========================================
echo    WINDOWS WINGET GUNCELLEME ARACI
echo ========================================
echo.

echo Mevcut guncellemeler kontrol ediliyor...
echo.

:: Guncellemeleri listele
winget upgrade --all --include-unknown

echo.
set /p devam="Guncellemeleri yuklemek istiyor musunuz? (E/H): "

if /i "%devam%"=="E" (
    echo.
    echo Guncellemeler yukleniyor...
    echo ========================================
    
    :: Tum guncellemeleri yukle
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    
    if %errorlevel%==0 (
        echo.
        echo ✓ Tum guncellemeler basariyla tamamlandi!
    ) else (
        echo.
        echo ! Bazı guncellemelerde hata olustu.
    )
) else (
    echo.
    echo İslem iptal edildi.
)

echo.
echo ========================================
echo Programi kapamak icin bir tusa basin...
pause >nul
