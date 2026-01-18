# GitHub Copilot Instructions for SmashingBackgrounds

## Project Overview

This is a PowerShell-based tool that automates downloading monthly desktop calendar wallpapers from Smashing Magazine. The wallpapers are published monthly at URLs like:
- `https://www.smashingmagazine.com/YYYY/MM/desktop-wallpaper-calendars-month-year/`

## Primary Goals

1. **Download the largest resolution images available** - Always prioritize higher pixel counts
2. **Prefer 16:9 aspect ratio wallpapers** - These are standard widescreen monitor dimensions
3. **Organize downloads by month/year** - Create folder structures like `January_2026/`

## Technical Guidelines

### PowerShell Best Practices

- Target **PowerShell 5.1+** compatibility (works on both Windows PowerShell and PowerShell Core)
- Use `[CmdletBinding()]` and proper parameter blocks with validation
- Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- Use approved PowerShell verbs (Get-, Set-, New-, Remove-, etc.)
- Prefer `Write-Host` with `-ForegroundColor` for user-friendly console output
- Use `Invoke-WebRequest` for HTTP requests

### Resolution Priorities

When selecting wallpapers, prefer resolutions in this order:
1. 3840×2160 (4K UHD)
2. 2560×1440 (QHD/2K)
3. 1920×1080 (Full HD)
4. 1600×900
5. 1366×768
6. 1280×720 (HD)

### 16:9 Aspect Ratio Detection

- Calculate ratio as `Width / Height`
- Target ratio is approximately 1.78 (16/9 = 1.777...)
- Allow small tolerance (~0.05) for rounding in resolution names

### URL Parsing

Smashing Magazine URLs follow patterns like:
- `/YYYY/MM/desktop-wallpaper-calendars-month-year/`
- Extract the calendar month/year from the URL slug, not the publication date

### HTML Parsing

- Wallpaper links contain resolution info in text (e.g., "1920×1080" or "1920x1080")
- Links are typically anchor tags within the article content
- Handle both `×` (multiplication sign) and `x` (letter) as dimension separators

## Code Style

- Use PascalCase for function names and parameters
- Use descriptive variable names
- Group related functionality into helper functions
- Provide meaningful error messages and progress feedback
- Use color-coded console output (Green for success, Yellow for warnings, Red for errors)

## Error Handling

- Validate URLs before processing
- Handle network failures gracefully
- Skip invalid or inaccessible images without stopping the entire process
- Report summary statistics at the end (downloaded, skipped, failed)
