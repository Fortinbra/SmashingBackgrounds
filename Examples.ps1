# Example usage script for Download-SmashingWallpapers.ps1
# This demonstrates how to use the wallpaper downloader

Write-Host "Smashing Magazine Wallpaper Downloader - Example Usage" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Example 1: Download January 2026 wallpapers to current directory
Write-Host "Example 1: Download to current directory" -ForegroundColor Yellow
Write-Host "Command:" -ForegroundColor Gray
Write-Host '  .\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/"' -ForegroundColor White
Write-Host ""

# Example 2: Download to a specific directory
Write-Host "Example 2: Download to specific directory" -ForegroundColor Yellow
Write-Host "Command:" -ForegroundColor Gray
Write-Host '  .\Download-SmashingWallpapers.ps1 `' -ForegroundColor White
Write-Host '      -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/" `' -ForegroundColor White
Write-Host '      -OutputPath "C:\Users\YourName\Pictures\Wallpapers"' -ForegroundColor White
Write-Host ""

# Example 3: Download different month
Write-Host "Example 3: Download December 2025 wallpapers" -ForegroundColor Yellow
Write-Host "Command:" -ForegroundColor Gray
Write-Host '  .\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/11/desktop-wallpaper-calendars-december-2025/"' -ForegroundColor White
Write-Host ""

Write-Host "To run any of these examples, copy the command and execute it in PowerShell" -ForegroundColor Green
Write-Host ""
Write-Host "For more information, run:" -ForegroundColor Cyan
Write-Host "  Get-Help .\Download-SmashingWallpapers.ps1 -Full" -ForegroundColor White
