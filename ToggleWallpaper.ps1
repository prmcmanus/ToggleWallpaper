# Wallpaper Selector for Windows 11
# Version: 20260916
#
# Shortcut Address (change file path)
# C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\ToggleWallpaper.ps1"

$themesPath = Join-Path $env:APPDATA "Microsoft\Windows\Themes"
$targetFile = Join-Path $themesPath "TranscodedWallpaper"

$files = @(
    Get-ChildItem -Path $themesPath -File |
        Where-Object { $_.Name -ne "TranscodedWallpaper" } |
        Sort-Object Name
)

Write-Host ""
Write-Host "Wallpaper Selector"
Write-Host "=================="
Write-Host "v20260916"
Write-Host ""

if ($files.Count -gt 0) {
    for ($i = 0; $i -lt $files.Count; $i++) {
        Write-Host "$($i + 1). $($files[$i].Name)"
    }
}
else {
    Write-Host "No wallpaper files were found." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "O. Open wallpaper directory in File Explorer"
Write-Host "Q. Quit"
Write-Host ""

$choice = Read-Host "Select a wallpaper number or option"

if ($choice -match '^[Oo]$') {
    Start-Process -FilePath "explorer.exe" -ArgumentList "`"$themesPath`""
    exit
}

if ($choice -match '^[Qq]$') {
    exit
}

if ($files.Count -eq 0) {
    Write-Host ""
    Write-Host "There are no wallpaper files to select." -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit
}

if ($choice -notmatch '^\d+$') {
    Write-Host ""
    Write-Host "Invalid selection. Enter a wallpaper number, O, or Q." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit
}

$choiceNumber = [int]$choice

if ($choiceNumber -lt 1 -or $choiceNumber -gt $files.Count) {
    Write-Host ""
    Write-Host "Invalid selection. Enter a number from 1 to $($files.Count)." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit
}

$selectedFile = $files[$choiceNumber - 1]

try {
    Copy-Item -LiteralPath $selectedFile.FullName -Destination $targetFile -Force -ErrorAction Stop

    if (-not ("WallpaperSettings" -as [type])) {
        Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;

public static class WallpaperSettings
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(
        int action,
        int parameter,
        string wallpaper,
        int updateFlags
    );
}
"@
    }

    $result = [WallpaperSettings]::SystemParametersInfo(20, 0, $targetFile, 3)

    Write-Host ""

    if ($result) {
        Write-Host "Wallpaper changed to: $($selectedFile.Name)" -ForegroundColor Green
    }
    else {
        $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

        Write-Host "The file was copied, but Windows did not refresh the wallpaper." -ForegroundColor Yellow
        Write-Host "Windows error code: $errorCode"
    }
}
catch {
    Write-Host ""
    Write-Host "The wallpaper could not be changed:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host ""
Read-Host "Press Enter to close"