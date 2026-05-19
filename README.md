# mpv-subfinder

An MPV plugin for downloading subtitles from multiple sources.

![Example for Subfinder](https://github.com/magnum357i/mpv-subfinder/blob/main/subfinder.jpg)

# 🧸Key Bindings

| shortcut          | description                               |
|-------------------|-------------------------------------------|
| <kbd>Ctrl+f</kbd> | toggle search panel                       |

# 🧲Dependencies

- **cURL**
- **API KEYS**

# 🧰Installation

1. Install the plugin.

### Manual

Place `scripts` and `script-opts` folders into your config directory.

| OS        | Location         |
|-----------|------------------|
| Windows   | `%appdata%/mpv/` |
| GNU/Linux | `~/.config/mpv/` |

### Automatic

To install or update via command line:

#### Windows 10 (CMD)

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/magnum357i/mpv-subfinder/HEAD/installers/windows.ps1 | iex"
```

#### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/magnum357i/mpv-subfinder/HEAD/installers/linux.sh | sh
```

2. Set up the API keys.
3. Add the providers you want to use to `sites_to_search`.

# 🎮 Usage

https://github.com/user-attachments/assets/ffb7a48a-d19d-4536-9d5c-76f5acdcbea5


1. Press `Ctrl+F` and you will see matching subtitles.
2. Click or press `Enter` to download the selected subtitle.

# 🎉Supported Sites
- **subsource** (all languages)
- **subdl** (all languages)
- **altyazidb** (turkish, english)
- **turkcealtyazi** (turkish, english)

I don’t plan to add all subtitle sites, and I’m not sure what else to add. I can add popular sites, or you can add the sites you want.

> [!NOTE]
> I was planning to add OpenSubtitles, but its daily limit, even when logged in, is absurdly low.

# ⚙️Configuration

```ini
# Default search language on launch
preferred_language=en

# Prioritizes subtitle rows matching the video quality
smart_sorting=yes

# User Agent for cURL
useragent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36

# GUI
text_size=24
sub_text_size=16
box_alpha=70
box_color=000000
cursor_color=white
padding=10
round=8
pin_right_margin=35
icon_right_margin=25
date_format=<mm>-<dd>-<yyyy>
bar_width=4
column_width=15
tag_padding=4
tag_right_margin=8

# API KEYS
# Sites to enable (available values: subsource,subdl,altyazidb,turkcealtyazi)
sites_to_search=subsource,subdl
api_subsource=
api_subdl=
api_altyazidb=
```

# 🔎Searching

1. Get **IMDb ID** from **TMDB**
2. Use title search if **IMDb ID** is not available or invalid.

### Tags
- **language**: Language filter (Currently available values: `fr`, `it`, `es`, `zh`, `de`, `ru`, `ja`, `tr`, `en`)
- **s**: Season filter
- **e**: Episode filter

> [!WARNING]
> The year is treated as a tag even if it’s not in tag form (e.g., "avatar 2026") and is used when searching on added sites and **TMDB**. For more accurate results, try searching with the year.

# 🥏Saving
Saves subtitles in the same folder as the video using its filename for **Plex** and **Jellyfin** compatibility.

### Example
```text
Media/
└── Movie (2024)/
    ├── Movie (2024).mkv
    └── Movie (2024).en.srt
```

# 🎯 Future Plans
- More languages
- **SubSource** episode filter
- Icons for some tags
- Inspect mode (=subtitle preview)