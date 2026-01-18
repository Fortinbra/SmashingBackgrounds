# SmashingBackgrounds

A PowerShell script to automatically download desktop wallpapers from Smashing Magazine's monthly wallpaper collections.

## Features

- Automatically downloads the largest 16:9 aspect ratio wallpapers from Smashing Magazine articles
- Creates an organized folder structure with month and year
- Prioritizes higher resolutions (4K > QHD > Full HD > etc.)
- Handles multiple wallpapers from a single article
- Provides detailed console output with download progress

## Requirements

- PowerShell 5.1 or later (Windows PowerShell or PowerShell Core)
- Internet connection
- Write access to the output directory

## Usage

### Basic Usage

```powershell
.\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/"
```

This will download all 16:9 wallpapers to a folder named with the month and year (e.g., `January_2026`) in the current directory.

### Custom Output Path

```powershell
.\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/" -OutputPath "C:\Wallpapers"
```

This will create the month/year folder inside `C:\Wallpapers`.

## How It Works

1. **Fetches the HTML** from the provided Smashing Magazine URL
2. **Parses the page** to find all wallpaper download links with resolution information
3. **Groups wallpapers** by detecting resolution patterns (e.g., "1920×1080", "2560x1440")
4. **Selects the best 16:9 image** from each wallpaper group:
   - Validates the aspect ratio is 16:9 (within a small tolerance)
   - Prioritizes larger resolutions (more total pixels)
5. **Downloads the images** to an organized folder with month/year naming
6. **Reports progress** with colored console output

## Supported 16:9 Resolutions

The script recognizes and prioritizes these common 16:9 resolutions (in order):

- 3840×2160 (4K UHD)
- 2560×1440 (QHD)
- 1920×1080 (Full HD)
- 1600×900
- 1366×768
- 1280×720 (HD)

## Examples

### Download January 2026 wallpapers

```powershell
.\Download-SmashingWallpapers.ps1 -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/"
```

### Download to a specific directory

```powershell
.\Download-SmashingWallpapers.ps1 `
    -Url "https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/" `
    -OutputPath "$env:USERPROFILE\Pictures\Wallpapers"
```

## Output Structure

```
OutputPath/
└── January_2026/
    ├── wallpaper_1_3840x2160.jpg
    ├── wallpaper_2_2560x1440.jpg
    └── ...
```

## Troubleshooting

### "No 16:9 wallpapers found"

This can occur if:
- The page structure has changed (Smashing Magazine updated their HTML)
- The article doesn't include 16:9 resolution wallpapers
- The parsing regex needs to be updated

### Download failures

If individual downloads fail:
- Check your internet connection
- Verify the URL is accessible
- Some images might be behind CDN restrictions

## Finding Smashing Magazine Wallpaper URLs

Smashing Magazine publishes monthly wallpaper collections. You can find them by:

1. Visiting [Smashing Magazine](https://www.smashingmagazine.com/)
2. Searching for "desktop wallpaper calendars"
3. Looking for articles titled like "Desktop Wallpaper Calendars: [Month] [Year]"

Recent examples:
- January 2026: `https://www.smashingmagazine.com/2025/12/desktop-wallpaper-calendars-january-2026/`
- December 2025: `https://www.smashingmagazine.com/2025/11/desktop-wallpaper-calendars-december-2025/`

## License

See the [LICENSE](LICENSE) file for details.