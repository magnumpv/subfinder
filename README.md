# mpv-subfinder

An MPV plugin for downloading subtitles from multiple sources.

![Example for Subfinder](https://github.com/magnum357i/mpv-subfinder/blob/main/subfinder.jpg)

# 🧸Key Bindings

By default, no keys are assigned. You can create your own bindings in `input.conf`:

```
Ctrl+f script-binding subfinder
Ctrl+F script-binding subfinder_pastelink
```

# 🧲Dependencies

- **7-Zip**
- **cURL**
- **API KEYS**

# 🧰Installation

1. Install the plugin.

```
##### Manual

Place scripts and script-opts folders into your config directory.

| OS        | Location       |
|-----------|----------------|
| Windows   | %appdata%/mpv/ |
| GNU/Linux | ~/.config/mpv/ |

##### Automatic

To install or update via command line:

1. Windows 10 (CMD)

powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/magnum357i/mpv-subfinder/HEAD/installers/windows.ps1 | iex"

2. Linux

curl -fsSL https://raw.githubusercontent.com/magnum357i/mpv-subfinder/HEAD/installers/linux.sh | sh

##### 7-Zip (Windows Only)
1. Install 7-Zip.
2. Add the 7-Zip installation directory to your PATH.

Typical locations:
- C:\Program Files\7-Zip
- C:\Program Files (x86)\7-Zip
```

2. Set up the API keys.
3. Add the providers you want to use to `sites_to_search`.
4. Assign shortcuts.

# 🎮 Usage

1. Press `Ctrl+f` and you will see matching subtitles.
2. Click or press `Enter` to download the selected subtitle.

https://github.com/user-attachments/assets/ffb7a48a-d19d-4536-9d5c-76f5acdcbea5


| shortcut              | description         |
|-----------------------|---------------------|
| <kbd>Up</kbd>         | Previous row        |
| <kbd>Down</kbd>       | Next row            |
| <kbd>Click</kbd>      | Download            |
| <kbd>Enter</kbd>      | Download            |
| <kbd>Ctrl+Click</kbd> | Go to subtitle page |
| <kbd>Ctrl+Enter</kbd> | Go to subtitle page |
| <kbd>Esc</kbd>        | Exit                |

# Supported Themes

Controllers are disabled when the interface is opened in these themes:

- `uosc`
- default/vanilla

# 🎉Sources

| Source                | Subtitle Languages  | Requires API Key | Paste Link | Open Page |
|-----------------------|---------------------|------------------|------------|-----------|
| **subsource**         | all                 | ✔️               | ✔️        | ✔️       |
| **subdl**             | all                 | ✔️               | ❌        | ✔️       |
| **altyazidb**         | turkish, english    | ✔️               | ❌        | ❌       |
| **turkcealtyazi**     | turkish, english    | ❌               | ✔️        | ✔️       |

I don’t plan to add all subtitle sites, and I’m not sure what else to add. I can add popular sites, or you can add the sites you want.

> [!WARNING]
> Access to turkcealtyazi from outside Turkey is protected by Cloudflare.

> [!NOTE]
> I was planning to add OpenSubtitles, but its daily limit, even when logged in, is absurdly low.

# ⚙️Configuration

```ini
# Sites to enable (available values: subsource,subdl,altyazidb,turkcealtyazi)
sites_to_search=subsource,subdl

# Default search language on launch
preferred_language=en

# Prioritizes subtitle rows matching the video quality
smart_sorting=yes

# User Agent for cURL
useragent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36

# File Types
video_types=mkv,mp4,avi,ts,m2ts,ogm
subtitle_types=srt,ass,ssa,vtt,sub,sup,pgs
archive_types=zip,rar,7z

# API KEYS
api_subsource=
api_subdl=
api_altyazidb=

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
```

# 🔎Searching

1. Get **IMDb ID** from **TMDB**
2. Use title search if **IMDb ID** is not available or invalid.

### Tags
- **language**: Language filter (Currently available values: `fr`, `it`, `es`, `zh`, `de`, `ru`, `ja`, `tr`, `en`)
- **s**: Season filter
- **e**: Episode filter

# 🥏Saving
Saves subtitles in the same folder as the video using its filename for **Plex** and **Jellyfin** compatibility.

### Example
```text
Zootopia (2016) 1080P DSNP WEB-DL DDP5.1 Atmos H264.mkv
Zootopia (2016) 1080P DSNP WEB-DL DDP5.1 Atmos H264.en.srt
```

# 🔥Important Notes
- To ensure accurate subtitle matching, the video directory should only contain episodes from the same series.
- The year is treated as a tag even if it’s not in tag form (e.g., "avatar 2026") and is used when searching on added sites and **TMDB**. For more accurate results, try searching with the year.

# 🎯 Future Plans
- More languages
- **SubSource** episode filter
- Icons for some tags
- Inspect mode (=subtitle preview)