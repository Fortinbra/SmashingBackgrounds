<#
.SYNOPSIS
    Downloads desktop wallpapers from Smashing Magazine's monthly wallpaper collection.

.DESCRIPTION
    This script fetches wallpapers from a Smashing Magazine desktop wallpaper article,
    prioritizing the largest 16:9 aspect ratio images available. It creates a folder
    named with the month and year, and downloads all wallpapers to that folder.
    
    If no URL is provided, the script automatically builds the URL for the current month's
    wallpaper collection based on the predictable Smashing Magazine URL pattern.

.PARAMETER Url
    The URL of the Smashing Magazine wallpaper article. Optional - if not provided,
    the script will automatically generate the URL for the current month.

.PARAMETER OutputPath
    The base path where the wallpaper folder will be created. Defaults to current directory.

.EXAMPLE
    .\Download-SmashingWallpapers.ps1
    
    Downloads wallpapers for the current month automatically.

.EXAMPLE
    .\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/"

.EXAMPLE
    .\Download-SmashingWallpapers.ps1 -OutputPath "C:\Wallpapers"
    
    Downloads current month's wallpapers to the specified folder.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Url,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "."
)

# Function to build the Smashing Magazine wallpaper URL for a given month
function Get-SmashingWallpaperUrl {
    param(
        [DateTime]$Date = (Get-Date)
    )
    
    # Smashing Magazine publishes wallpapers the month before
    # e.g., January 2026 wallpapers are published in December 2025
    $publishDate = $Date.AddMonths(-1)
    $publishYear = $publishDate.Year
    $publishMonth = $publishDate.Month.ToString("00")
    
    $wallpaperMonth = $Date.ToString("MMMM").ToLower()
    $wallpaperYear = $Date.Year
    
    $url = "https://www.smashingmagazine.com/$publishYear/$publishMonth/desktop-wallpaper-calendars-$wallpaperMonth-$wallpaperYear/"
    
    return $url
}

# If no URL provided, build it automatically for the current month
if ([string]::IsNullOrWhiteSpace($Url)) {
    $Url = Get-SmashingWallpaperUrl -Date (Get-Date)
    Write-Host "No URL provided. Using current month's wallpaper URL:" -ForegroundColor Cyan
    Write-Host "  $Url" -ForegroundColor White
}

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

function Test-IsWidescreen {
    param([int]$Width, [int]$Height)
    
    if ($Height -eq 0) { return $false }
    # Widescreen = wider than 4:3 (ratio > 1.33)
    $ratio = $Width / $Height
    return $ratio -gt 1.33
}

function Select-BestWallpaper {
    param([array]$ImageLinks)
    
    $candidates16x9 = @()
    $candidatesWidescreen = @()
    
    foreach ($link in $ImageLinks) {
        $resolution = Get-ResolutionFromText -Text $link.Text
        
        if ($resolution) {
            $candidate = @{
                Url = $link.Href
                Width = $resolution.Width
                Height = $resolution.Height
                Name = $resolution.Name
                Text = $link.Text
            }
            
            if (Test-Is16x9 -Width $resolution.Width -Height $resolution.Height) {
                $candidates16x9 += $candidate
            }
            elseif (Test-IsWidescreen -Width $resolution.Width -Height $resolution.Height) {
                $candidatesWidescreen += $candidate
            }
        }
    }
    
    # Prefer 16:9, sorted by total pixels (width * height) descending
    if ($candidates16x9.Count -gt 0) {
        $best = $candidates16x9 | Sort-Object { $_.Width * $_.Height } -Descending | Select-Object -First 1
        return @{ Image = $best; Type = "16:9" }
    }
    
    # Fallback to largest widescreen image
    if ($candidatesWidescreen.Count -gt 0) {
        $best = $candidatesWidescreen | Sort-Object { $_.Width * $_.Height } -Descending | Select-Object -First 1
        return @{ Image = $best; Type = "widescreen" }
    }
    
    return $null
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
    
    # Fallback to regex if parsed links aren't available or insufficient
    if ($allLinks.Count -eq 0) {
        Write-Host "Using fallback regex parsing..." -ForegroundColor Yellow
    }
    
    # Always use regex to find wallpaper resolution links since UseBasicParsing may not populate Links properly
    # Pattern handles both quoted and unquoted href attributes:
    # <a href="...url...">1920x1080</a> OR <a href=...url... title="...">1920×1080</a>
    $linkMatches = [regex]::Matches($html, '<a\s+href="?([^"\s>]+)"?\s*[^>]*>(\d+[x×]\d+)</a>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    Write-Host "Found $($linkMatches.Count) resolution links via regex" -ForegroundColor Cyan
    
    foreach ($match in $linkMatches) {
        $allLinks += @{
            Href = $match.Groups[1].Value
            Text = $match.Groups[2].Value.Trim()
        }
    }
    
    # Group links by wallpaper name extracted from URL
    # URL pattern: .../wallpapers/jan-26/WALLPAPER-NAME/cal/...
    # or: .../wallpapers/jan-26/WALLPAPER-NAME/nocal/...
    $wallpaperGroups = @{}
    
    foreach ($link in $allLinks) {
        $href = $link.Href
        $text = $link.Text
        
        # Check if this is a resolution link
        $resolution = Get-ResolutionFromText -Text $text
        
        if ($resolution) {
            # Extract wallpaper name from URL path
            # Pattern: /wallpapers/xxx/WALLPAPER-NAME/(cal|nocal)/
            $wallpaperName = "unknown"
            if ($href -match '/wallpapers/[^/]+/([^/]+)/(cal|nocal)/') {
                $wallpaperName = $matches[1]
            }
            elseif ($href -match '/([^/]+)-nocal-\d+x\d+\.\w+$') {
                $wallpaperName = $matches[1]
            }
            elseif ($href -match '/([^/]+)-cal-\d+x\d+\.\w+$') {
                $wallpaperName = $matches[1]
            }
            
            if (-not $wallpaperGroups.ContainsKey($wallpaperName)) {
                $wallpaperGroups[$wallpaperName] = @()
            }
            
            $wallpaperGroups[$wallpaperName] += @{
                Href = $href
                Text = $text
                Resolution = $resolution
            }
        }
    }
    
    Write-Host "Found $($wallpaperGroups.Count) wallpaper groups" -ForegroundColor Cyan
    
    $downloadCount = 0
    $skippedCount = 0
    $count16x9 = 0
    $countWidescreen = 0
    
    foreach ($groupName in $wallpaperGroups.Keys | Sort-Object) {
        $group = $wallpaperGroups[$groupName]
        
        # Select the best wallpaper from this group (prefers 16:9, falls back to widescreen)
        $result = Select-BestWallpaper -ImageLinks $group
        
        if ($result) {
            $bestImage = $result.Image
            $imageType = $result.Type
            
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
                $filename = "wallpaper_${groupName}_$($bestImage.Name)${extension}"
            }
            
            $outputFile = Join-Path -Path $outputFolder -ChildPath $filename
            
            # Skip if file already exists (idempotent)
            if (Test-Path -Path $outputFile) {
                $skippedCount++
                Write-Host "[SKIP] $filename already exists" -ForegroundColor DarkGray
                continue
            }
            
            # Count by type only for files we actually download
            if ($imageType -eq "16:9") { $count16x9++ } else { $countWidescreen++ }
            $downloadCount++
            
            $typeLabel = if ($imageType -eq "16:9") { "" } else { " [widescreen]" }
            Write-Host "[$downloadCount] Downloading: $filename ($($bestImage.Name))$typeLabel" -ForegroundColor Yellow
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
    
    if ($downloadCount -eq 0 -and $skippedCount -eq 0) {
        Write-Host "No wallpapers found. This might indicate:" -ForegroundColor Yellow
        Write-Host "  - The page structure has changed" -ForegroundColor Yellow
        Write-Host "  - No widescreen resolution wallpapers are available" -ForegroundColor Yellow
        Write-Host "  - The parsing logic needs to be updated" -ForegroundColor Yellow
    }
    else {
        Write-Host "`n=== Summary ===" -ForegroundColor Cyan
        Write-Host "Output folder: $outputFolder" -ForegroundColor White
        Write-Host "  - Downloaded: $downloadCount (16:9: $count16x9, widescreen: $countWidescreen)" -ForegroundColor Green
        Write-Host "  - Skipped (already exist): $skippedCount" -ForegroundColor DarkGray
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
