# mpv-subfinder

An MPV plugin for downloading subtitles from multiple sources.

![Example for Subfinder](https://github.com/magnum357i/mpv-subfinder/blob/main/subfinder.jpg)

# 🧸Key Bindings

By default, no keys are assigned. You can create your own bindings in `input.conf`:

```
Ctrl+f script-binding subfinder
Ctrl+F script-binding subfinder_pastelink
Ctrl+i script-binding subfinder_goto
```

# 🧲Requirements

- **7-Zip or WinRAR**
- **cURL**
- **API KEYS**

# 🧰Installation

1. Install the plugin.

```
### Manual

Place scripts and script-opts folders into your config directory.

| OS        | Location       |
|-----------|----------------|
| Windows   | %appdata%/mpv/ |
| GNU/Linux | ~/.config/mpv/ |

### Automatic

To install or update via command line:

1. Windows 10 (CMD)

powershell -ExecutionPolicy ByPass -c "irm https://raw.githubusercontent.com/magnum357i/mpv-subfinder/HEAD/installers/windows.ps1 | iex"

2. Linux

curl -fsSL https://raw.githubusercontent.com/magnum357i/mpv-subfinder/HEAD/installers/linux.sh | sh

##### 7-Zip/WinRAR (Windows Only)

### Manual

1. Install 7-Zip/WinRAR.
2. Add the 7-Zip/WinRAR installation directory to your PATH.

Typical locations:
- C:\Program Files\7-Zip
- C:\Program Files (x86)\7-Zip
- C:\Program Files\WinRAR
- C:\Program Files (x86)\WinRAR

### Automatic

winget install 7zip.7zip
winget install winrar
```

2. Set up the API keys.
3. Add the providers you want to use to `sites_to_search`.
4. Assign shortcuts.

# 🎮Usage

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

# 🖌️Supported Themes

Controllers are disabled when the interface is opened in these themes:

- `uosc`
- default/vanilla

# 🎉Sources

| Source                | Subtitle Languages  | Requires API Key             | Paste Link |
|-----------------------|---------------------|------------------------------|------------|
| **altyazidb**         | turkish, english    | ✔️                           | ❌        |
| **opensubtitles**     | all                 | to increase your daily quota | ❌        |
| **subsource**         | all                 | ✔️                           | ✔️        |
| **turkcealtyazi**     | turkish, english    | ❌                           | ✔️        |

I don't plan to add every subtitle site, but I can add these sites if anyone requests them:
- addic7ed
- tvsubtitles

> [!WARNING]
> Access to **turkcealtyazi** from outside Turkey is protected by **Cloudflare**.

> [!NOTE]
> Please note that **OpenSubtitles** allows 20 downloads for authenticated accounts and 5 downloads for anonymous users.

# ⚙️Configuration

```ini
# Sites to Enable (Available Values: subsource,subdl,altyazidb,turkcealtyazi,opensubtitles)
sites_to_search=subsource

# Default Search Language on Launch
preferred_language=en

# Sort Results (Available Values: quality, date)
sorting=

# User Agent for cURL
useragent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36

# File Types
video_types=mkv,mp4,avi,ts,m2ts,ogm,wmv
subtitle_types=srt,ass,ssa,vtt,sub,sup,pgs,smi,idx
archive_types=zip,rar,7z

# I don't want AI translations.
block_ai=no

# Choose a program to open the archive. (Available Values: 7zip, winrar)
extract_engine=7zip

# Appends the download source information to the subtitle file name. (<moviename><sitename><subtitleid><lang>)
# Note: Windows users may experience a half-second delay when opening the interface due to PowerShell startup overhead.
append_source_to_filename=no

# Go to URL (Available Tags: <imdbid>, <title>)
goto_url_formovies=https://www.imdb.com/title/<imdbid>/
goto_url_forseries=https://www.imdb.com/title/<imdbid>/

# SECRETS
# Credentials format is username:password.

api_subsource=
api_subdl=
api_altyazidb=
credentials_opensubtitles=

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

1. Get **IMDb ID** from **TMDB**.
2. Use title search if **IMDb ID** search fails.

### Tags
- **language**: Language filter (35 supported languages)
- **s**: Season filter
- **e**: Episode filter
- **page**: Page filter (default: 1)

# 🚀Go to URL
You can open the movie or show you are watching on your preferred site with a single key press. Add the following line to your `input.conf` file:

```
Ctrl+i script-binding subfinder_goto
```

And modify these lines in the `subfinder.conf` file if you'd rather go with a site other than IMDb:

```ini
goto_url_formovies=https://www.imdb.com/title/<imdbid>/
goto_url_forseries=https://www.imdb.com/title/<imdbid>/
```

Or you can use this: [IMDb Quick Search](https://greasyfork.org/en/scripts/427320-imdb-quick-search)

# 🥏Saving
Saves subtitles in the same folder as the video using its filename for **Plex** and **Jellyfin** compatibility.

### Example
```text
Zootopia (2016) 1080P DSNP WEB-DL DDP5.1 Atmos H264.mkv
Zootopia (2016) 1080P DSNP WEB-DL DDP5.1 Atmos H264.en.srt
```

# 🎈Color Meanings
- **red background:** ai
- **green background:** matched
- **yellow site color:** imdb search

# 🔥Important Notes
- To ensure accurate subtitle matching, the video directory should only contain episodes from the same series.
- The year is treated as a tag even if it’s not in tag form (e.g., "avatar 2026") and is used when searching on added sites and **TMDB**. For more accurate results, try searching with the year.
- If you use **the s tag (season filter)**, it will search for series. Otherwise, it will search for movies.