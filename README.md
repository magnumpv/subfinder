# mpv-subfinder

An MPV plugin that finds and lets you download subtitles for the current video from multiple sources.

![Example for Subfinder](https://github.com/magnum357i/mpv-subfinder/blob/main/subfinder.jpg)

# Key Bindings

| shortcut          | description                               |
|-------------------|-------------------------------------------|
| <kbd>Ctrl+f</kbd> | toggle search panel                       |

# Dependencies

- `cURL`

# Installation
- Place the plugin files in the installation directory.
- Set up the API keys.
- Add the providers you want to search in `sites_to_search`.

# Usage
1. Open the interface by pressing `Ctrl+f`.
2. Press `Enter` to search.
3. Click the subtitle you want to download.

# Supported Sites
- **SubSource** (all languages)
- **SubDL** (all languages)
- **altyazıdb** (turkish, english)
- **Türkçe Altyazı** (turkish, english)

I don’t plan to add all subtitle sites, and I’m not sure what else to add. I may add popular sites, or you can add them yourself.

# Configuration

```ini
preferred_language=en
smart_sorting=no
useragent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36

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

sites_to_search=subsource,subdl
api_subsource=
api_subdl=
api_altyazidb=
```

# Search Tags
- **language**: Language filter (Currently available values: `fr`, `it`, `es`, `zh`, `de`, `ru`, `ja`, `tr`, `en`)
- **s**: Season filter
- **e**: Episode filter

> [!NOTE]
> The year is treated as a tag even if it’s not in tag form (e.g., "avatar 2026"), and is used in the search fields of the added sites and TMDB. For more accurate results, try searching with the year.

# Searching

1. Get **IMDb ID** from **TMDB**
2. Use title search if the IMDb ID is unavailable or no matching page is found.

# Downloading
Saves subtitles in the video folder using the video filename for compatibility with Plex and Jellyfin.

### Example
```text
Media/
└── Movie (2024)/
    ├── Movie (2024).mkv
    └── Movie (2024).en.srt
```

# Future Plans
- More languages
- **SubSource** episode filter
- Icons for some tags
- Inspect mode (=subtitle preview)