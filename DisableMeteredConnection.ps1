<#
.SYNOPSIS
    Ethernet adaptörlerindeki tarifeli bağlantı (Metered Connection) ayarını kapatır ve log tutar.
.DESCRIPTION
    Bu script, Windows 10/11 bilgisayarlardaki Ethernet adaptörlerinin tarifeli bağlantı özelliğini devre dışı bırakır.
    Tüm işlemleri C:\ProgramData\MeteredConnectionFix\Logs klasörüne kaydeder.
.NOTES
    Author: Yardımcı Asistan
    Version: 1.0
#>

# --- ADMIN CHECK & ELEVATE ---
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host "Elevating script to run as Administrator..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Log klasörünü oluştur
$LogPath = "C:\Temp"
if (-not (Test-Path -Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# Log dosya adını oluştur (BilgisayarAdı_YYYYMMDD_HHMMSS.log formatında)
$ComputerName = $env:COMPUTERNAME
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "$LogPath\${ComputerName}_${Timestamp}.log"

# Log yazma fonksiyonu
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    
    # Konsola yaz (renkli)
    switch ($Level) {
        "INFO"    { Write-Host $LogEntry -ForegroundColor Green }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $LogEntry -ForegroundColor Red }
        "ACTION"  { Write-Host $LogEntry -ForegroundColor Cyan }
        default   { Write-Host $LogEntry }
    }
    
    # Dosyaya yaz
    $LogEntry | Out-File -FilePath $LogFile -Append
}

# Script başlangıcı
Write-Log "=========================================="
Write-Log "TARIFELI BAGLANTI KAPATMA SCRIP'I BASLADI"
Write-Log "=========================================="
Write-Log "Bilgisayar: $ComputerName"
Write-Log "Kullanici: $env:USERNAME"
Write-Log "Isletim Sistemi: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)"

$Change = $false
$AdaptorCount = 0
$FixedCount = 0

try {
    # Tüm Ethernet adaptörlerini bul
    Write-Log "Ethernet adaptorleri taraniyor..."
    $Eths = Get-NetAdapter | Where-Object {$_.Name -like "*Ethernet*" -or $_.InterfaceDescription -like "*Ethernet*"}
    
    if ($Eths.Count -eq 0) {
        Write-Log "Ethernet adaptoru bulunamadi!" "WARNING"
    } else {
        Write-Log "Toplam $($Eths.Count) ethernet adaptoru bulundu."
        
        foreach ($E in $Eths) {
            $AdaptorCount++
            Write-Log "[$AdaptorCount/$($Eths.Count)] Adaptor inceleniyor: $($E.Name) (Durum: $($E.Status))" "INFO"
            
            $NIC_Guid = $E.InterfaceGuid
            $EthRegPath = "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$NIC_Guid\*"
            
            if (Test-Path -Path $EthRegPath) {
                try {
                    # Mevcut UserCost değerini oku (0: tarifesiz, 2: tarifeli)
                    $UserCost = (Get-ItemProperty -Path $EthRegPath -Name UserCost -ErrorAction SilentlyContinue).UserCost
                    
                    Write-Log "Mevcut UserCost degeri: $UserCost (0: Tarifesiz, 2: Tarifeli)" "INFO"
                    
                    # Eğer tarifeli (2) ise, tarifesiz (0) yap
                    if ($UserCost -eq 2) {
                        Write-Log "TARIFELI BAGLANTI BULUNDU: $($E.Name)" "ACTION"
                        Set-ItemProperty -Path $EthRegPath -Name UserCost -Value 0 | Out-Null
                        Write-Log "Basariyla tarifesiz olarak degistirildi." "ACTION"
                        $Change = $true
                        $FixedCount++
                    } else {
                        Write-Log "Zaten tarifesiz olarak ayarlanmis, islem yapilmadi." "INFO"
                    }
                }
                catch {
                    Write-Log "HATA: $($E.Name) adaptoru islenirken hata olustu: $($_.Exception.Message)" "ERROR"
                }
            }
            else {
                Write-Log "UYARI: $($E.Name) icin kayit defteri yolu bulunamadi!" "WARNING"
            }
        }
    }
    
    # Wi-Fi adaptörlerini de kontrol etmek ister misiniz? (İsteğe bağlı)
    $CheckWiFi = $false  # True yaparsanız WiFi'ları da kontrol eder
    if ($CheckWiFi) {
        Write-Log "Wi-Fi adaptorleri taranıyor..."
        $Wifis = Get-NetAdapter | Where-Object {$_.Name -like "*Wi-Fi*" -or $_.InterfaceDescription -like "*Wireless*"}
        
        foreach ($W in $Wifis) {
            $NIC_Guid = $W.InterfaceGuid
            $WifiRegPath = "HKLM:\SOFTWARE\Microsoft\DusmSvc\Profiles\$NIC_Guid\*"
            
            if (Test-Path -Path $WifiRegPath) {
                $UserCost = (Get-ItemProperty -Path $WifiRegPath -Name UserCost -ErrorAction SilentlyContinue).UserCost
                if ($UserCost -eq 2) {
                    Write-Log "Wi-Fi TARIFELI BULUNDU: $($W.Name)" "ACTION"
                    Set-ItemProperty -Path $WifiRegPath -Name UserCost -Value 0 | Out-Null
                    $Change = $true
                    $FixedCount++
                }
            }
        }
    }
    
    # Eğer bir değişiklik yapıldıysa, ilgili servisi yeniden başlat
    if ($Change -eq $true) {
        Write-Log "Toplam $FixedCount adaptorde degisiklik yapildi. DusmSvc servisi yeniden baslatiliyor..." "ACTION"
        try {
            Restart-Service -Name DusmSvc -Force
            Write-Log "DusmSvc servisi basariyla yeniden baslatildi." "INFO"
        }
        catch {
            Write-Log "Servis yeniden baslatilirken hata: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "Hicbir adaptorde degisiklik yapilmadi." "INFO"
    }
}
catch {
    Write-Log "BEKLENMEYEN HATA: $($_.Exception.Message)" "ERROR"
    Write-Log "Hata detayi: $($_.ScriptStackTrace)" "ERROR"
}

# Script bitişi
Write-Log "=========================================="
Write-Log "SCRIPT TAMAMLANDI"
Write-Log "Islem Ozeti: $FixedCount / $AdaptorCount adaptorde duzeltme yapildi."
Write-Log "Log dosyasi: $LogFile"
Write-Log "=========================================="

# Log dosyasının konumunu göster
Write-Host "Log dosyasi surada: $LogFile" -ForegroundColor Yellow

# --- WAIT BEFORE EXIT ---
Write-Host "Press any key to exit..."
[System.Console]::ReadKey() | Out-Null
Exit 0