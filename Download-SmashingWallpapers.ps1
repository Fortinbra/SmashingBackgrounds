<#
.SYNOPSIS
    Downloads desktop wallpapers from Smashing Magazine's monthly wallpaper collection.

.DESCRIPTION
    This script fetches wallpapers from a Smashing Magazine desktop wallpaper article,
    prioritizing the largest 16:9 aspect ratio images available. It creates a folder
    named with the month and year, and downloads all wallpapers to that folder.

.PARAMETER Url
    The URL of the Smashing Magazine wallpaper article.

.PARAMETER OutputPath
    The base path where the wallpaper folder will be created. Defaults to current directory.

.EXAMPLE
    .\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/"

.EXAMPLE
    .\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/" -OutputPath "C:\Wallpapers"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "."
)

# Common 16:9 resolutions in order of preference (largest first)
$Preferred16x9Resolutions = @(
    @{Width=3840; Height=2160; Name="3840x2160"},  # 4K
    @{Width=2560; Height=1440; Name="2560x1440"},  # QHD
    @{Width=1920; Height=1080; Name="1920x1080"},  # Full HD
    @{Width=1600; Height=900; Name="1600x900"},
    @{Width=1366; Height=768; Name="1366x768"},
    @{Width=1280; Height=720; Name="1280x720"}     # HD
)

function Test-Is16x9 {
    param([int]$Width, [int]$Height)
    
    if ($Height -eq 0) { return $false }
    $ratio = [math]::Round($Width / $Height, 2)
    $target = [math]::Round(16.0 / 9.0, 2)
    # Allow small tolerance for rounding
    return [math]::Abs($ratio - $target) -lt 0.05
}

function Get-ResolutionFromText {
    param([string]$Text)
    
    # Try to match patterns like "1920×1080", "1920x1080", "1920 × 1080"
    # Updated to handle any number of digits for future-proofing
    if ($Text -match '(\d+)\s*[x×]\s*(\d+)') {
        return @{
            Width = [int]$matches[1]
            Height = [int]$matches[2]
            Name = "$($matches[1])x$($matches[2])"
        }
    }
    return $null
}

function Get-MonthYearFromUrl {
    param([string]$Url)
    
    # Try to extract month and year from various URL patterns:
    # .../2025/12/desktop-wallpaper-calendars-january-2026/
    # .../desktop-wallpaper-calendars-january-2026/
    # Try pattern with year/month in path and month-year at end
    if ($Url -match '/(\d{4})/(\d{2})/.*?-(\w+)-(\d{4})') {
        $month = $matches[3]
        $year = $matches[4]
        return "${month}_${year}"
    }
    
    # Try pattern with just month-year at end
    if ($Url -match '/.*?-(\w+)-(\d{4})/?') {
        $month = $matches[1]
        $year = $matches[2]
        return "${month}_${year}"
    }
    
    # Try to extract from title or other patterns
    if ($Url -match '(\w+)[\-_](\d{4})') {
        $month = $matches[1]
        $year = $matches[2]
        return "${month}_${year}"
    }
    
    # Fallback: use current month/year
    $date = Get-Date
    return $date.ToString("MMMM_yyyy")
}

function Select-Best16x9Image {
    param([array]$ImageLinks)
    
    $candidates = @()
    
    foreach ($link in $ImageLinks) {
        $resolution = Get-ResolutionFromText -Text $link.Text
        
        if ($resolution -and (Test-Is16x9 -Width $resolution.Width -Height $resolution.Height)) {
            $candidates += @{
                Url = $link.Href
                Width = $resolution.Width
                Height = $resolution.Height
                Name = $resolution.Name
                Text = $link.Text
            }
        }
    }
    
    # Sort by total pixels (width * height) descending
    $best = $candidates | Sort-Object { $_.Width * $_.Height } -Descending | Select-Object -First 1
    
    return $best
}

Write-Host "Fetching wallpaper page: $Url" -ForegroundColor Cyan

try {
    # Fetch the HTML content
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing
    $html = $response.Content
    
    Write-Host "Page fetched successfully" -ForegroundColor Green
    
    # Extract month/year for folder name
    $folderName = Get-MonthYearFromUrl -Url $Url
    $outputFolder = Join-Path -Path $OutputPath -ChildPath $folderName
    
    # Create output folder if it doesn't exist
    if (-not (Test-Path -Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
        Write-Host "Created folder: $outputFolder" -ForegroundColor Green
    }
    else {
        Write-Host "Using existing folder: $outputFolder" -ForegroundColor Yellow
    }
    
    # Parse HTML to find wallpaper sections
    # Use PowerShell's HTML parsing for more robust link extraction
    
    # Find all links from the parsed HTML
    $allLinks = @()
    
    # Try to use parsed links if available
    if ($response.Links) {
        foreach ($link in $response.Links) {
            if ($link.href -and $link.innerText) {
                $allLinks += @{
                    Href = $link.href
                    Text = $link.innerText.Trim()
                }
            }
        }
    }
    
    # Fallback to regex if parsed links aren't available
    if ($allLinks.Count -eq 0) {
        Write-Host "Using fallback regex parsing..." -ForegroundColor Yellow
        $linkMatches = [regex]::Matches($html, '<a[^>]+href=["'']([^"'']+)["''][^>]*>([^<]+)</a>')
        foreach ($match in $linkMatches) {
            $allLinks += @{
                Href = $match.Groups[1].Value
                Text = $match.Groups[2].Value.Trim()
            }
        }
    }
    
    # Group links by wallpaper (they typically come in groups with different resolutions)
    $wallpaperGroups = @{}
    $currentGroup = @()
    $groupIndex = 0
    
    foreach ($link in $allLinks) {
        $href = $link.Href
        $text = $link.Text
        
        # Check if this is a resolution link
        $resolution = Get-ResolutionFromText -Text $text
        
        if ($resolution) {
            $currentGroup += @{
                Href = $href
                Text = $text
                Resolution = $resolution
            }
        }
        else {
            # If we have accumulated links and hit a non-resolution link, save the group
            if ($currentGroup.Count -gt 0) {
                $wallpaperGroups["Group_$groupIndex"] = $currentGroup
                $currentGroup = @()
                $groupIndex++
            }
        }
    }
    
    # Don't forget the last group
    if ($currentGroup.Count -gt 0) {
        $wallpaperGroups["Group_$groupIndex"] = $currentGroup
    }
    
    Write-Host "Found $($wallpaperGroups.Count) wallpaper groups" -ForegroundColor Cyan
    
    $downloadCount = 0
    
    foreach ($groupName in $wallpaperGroups.Keys | Sort-Object) {
        $group = $wallpaperGroups[$groupName]
        
        # Select the best 16:9 image from this group
        $bestImage = Select-Best16x9Image -ImageLinks $group
        
        if ($bestImage) {
            $downloadCount++
            
            # Extract filename from URL
            $uri = [System.Uri]$bestImage.Url
            $filename = [System.IO.Path]::GetFileName($uri.LocalPath)
            
            # Detect file extension from the URL or use a default
            $extension = ".jpg"
            if ($filename -match '\.(\w+)$') {
                $extension = $matches[0]
            }
            
            # If filename is not descriptive, create one
            if ([string]::IsNullOrWhiteSpace($filename) -or $filename -notmatch '\.(jpg|jpeg|png|webp|bmp|gif)$') {
                $filename = "wallpaper_${downloadCount}_$($bestImage.Name)${extension}"
            }
            
            $outputFile = Join-Path -Path $outputFolder -ChildPath $filename
            
            Write-Host "[$downloadCount] Downloading: $filename ($($bestImage.Name))" -ForegroundColor Yellow
            Write-Host "    URL: $($bestImage.Url)" -ForegroundColor Gray
            
            try {
                Invoke-WebRequest -Uri $bestImage.Url -OutFile $outputFile -UseBasicParsing
                Write-Host "    ✓ Downloaded successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "    ✗ Failed to download: $_" -ForegroundColor Red
            }
        }
    }
    
    if ($downloadCount -eq 0) {
        Write-Host "No 16:9 wallpapers found. This might indicate:" -ForegroundColor Yellow
        Write-Host "  - The page structure has changed" -ForegroundColor Yellow
        Write-Host "  - No 16:9 resolution wallpapers are available" -ForegroundColor Yellow
        Write-Host "  - The parsing logic needs to be updated" -ForegroundColor Yellow
    }
    else {
        Write-Host "`nSuccessfully downloaded $downloadCount wallpapers to: $outputFolder" -ForegroundColor Green
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
