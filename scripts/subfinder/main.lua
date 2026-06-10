--[[

╔════════════════════════════════╗
║          MPV subfinder         ║
║              v1.1.2            ║
╚════════════════════════════════╝

https://github.com/magnum357i/mpv-subfinder

]]

local options         = require "mp.options"
local utils           = require "mp.utils"
local utf8            = require "lib/fastutf8"
local input           = require "lib/input"
local path            = require "lib/path"
local h               = require "lib/helper"
local subtitle        = require "lib/subtitle"
local gui             = require "lib/gui"
local request         = require "lib/base"
local msg             = require "mp.msg"
local labelText       = "Search for subtitles:"
local data            = {}
local opened          = false
local mouse           = {x = 0, y = 0}
local offset          = 1
local currentIndex    = 1
local message         = ""
local panel           = gui:new()
local providers       = {}
local currentLanguage = ""
local search          = {timer = nil, text = "", results = {}, processing = false}
local cachedPaths     = {}
local firstOpened     = true

query = {}

config = {

    sites_to_search           = "", --subsource,subdl,altyazidb,turkcealtyazi,opensubtitles
    preferred_language        = "en",
    smart_sorting             = false,
    useragent                 = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36",
    video_types               = "mkv,mp4,avi,ts,m2ts,ogm,wmv",
    subtitle_types            = "srt,ass,ssa,vtt,sub,sup,pgs,smi,idx",
    archive_types             = "zip,rar,7z",
    block_ai                  = false,
    extract_engine            = "7zip", --7zip, winrar

    --SECRETS
    api_subsource             = "",
    api_subdl                 = "",
    api_altyazidb             = "",
    credentials_opensubtitles = "", --username:password

    --GUI
    text_size                 = 24,
    sub_text_size             = 16,
    box_alpha                 = 70, -- 0-255
    box_color                 = "000000",
    cursor_color              = "white", -- white,black
    padding                   = 10,
    round                     = 8,
    pin_right_margin          = 35,
    icon_right_margin         = 25,
    date_format               = "<mm>-<dd>-<yyyy>",
    bar_width                 = 4,
    column_width              = 15,
    tag_padding               = 4,
    tag_right_margin          = 8
}

options.read_options(config)

titleProperties = {}

app = {

    name              = "mpvsubfinder",
    version           = "1.1.2",
    api_tmdb          = "108862d1305e0848f2a0874ca1bf5098",
    api_opensubtitles = "R3vsYHv28E3JIL288Fv3YSoqmablRACD"
}

colors = {

    text         = "FFFFFF",
    subtext      = "959595",
    hover        = "000000",
    sameversion  = "11C823",
    ai           = "1718FF",

    --quality
    bd           = "1F85CC",
    web          = "F8786C",
    dvd          = "7F7F7F",

    --tag
    hi           = "5551F9",
    batch        = "45AD18",
    foreign      = "CABF35",
    forced       = "CABF35",

    --region
    latinamerica = "DA50B2",
    spain        = "DA50B2",
    cantonese    = "DA50B2",
    simplified   = "DA50B2",
    traditional  = "DA50B2",
    cantonese    = "DA50B2",
    bgcode       = "DA50B2",
    bilingual    = "DA50B2",
    canada       = "DA50B2",
    france       = "DA50B2",
    brazilian    = "DA50B2",
    south        = "DA50B2",

    --imdb
    imdb         = "18C5F5"
}

icons = {

    uploader = "m 16 15 l 16 15 19 14 21 10 19 6 16 5 l 16 5 12 7 11 10 12 14 16 15 m 16 17 b 9 17 5 21 5 23 l 5 26 l 27 26 l 27 23 b 27 21 22 17 16 17",
    date     = "m 8 30 l 24 30 l 24 30 28 26 28 25 l 28 9 l 28 9 25 6 l 23 6 l 23 4 l 23 4 20 4 l 20 6 l 12 6 l 12 4 l 12 4 9 4 l 9 6 l 6 6 l 6 6 4 9 l 4 25 l 4 25 7 29 8 30 m 6 17 l 6 17 7 16 l 25 16 l 25 16 25 17 l 25 25 l 25 25 24 27 l 8 27 l 8 27 6 25",
    download = "m 19 19 l 1 19 b 0 19 0 18 0 18 l 0 13 l 2 13 l 2 17 l 18 17 l 18 13 l 20 13 l 20 18 b 20 18 19 19 19 19 m 15 7 b 15 6 14 6 14 7 l 11 10 l 11 2 b 11 1 10 1 10 1 b 9 1 9 1 9 2 l 9 10 l 5 7 b 5 6 4 6 4 7 b 3 7 3 8 4 8 l 9 13 b 9 14 10 14 10 13 l 15 8 b 16 8 16 7 15 7"
}

flag = {}

languages = {

    ar = "Arabic",
    az = "Azerbaijani",
    bg = "Bulgarian",
    cs = "Czech",
    da = "Danish",
    de = "German",
    el = "Greek",
    en = "English",
    es = "Spanish",
    fa = "Farsi Persian",
    fi = "Finnish",
    fr = "French",
    he = "Hebrew",
    hi = "Hindi",
    hr = "Croatian",
    id = "Indonesian",
    it = "Italian",
    ja = "Japanese",
    ko = "Korean",
    nl = "Dutch",
    no = "Norwegian",
    pl = "Polish",
    pt = "Portuguese",
    ro = "Romanian",
    ru = "Russian",
    sq = "Albanian",
    sr = "Serbian",
    sv = "Swedish",
    th = "Thai",
    tr = "Turkish",
    uk = "Ukrainian",
    ur = "Urdu",
    uz = "Uzbek",
    vi = "Vietnamese",
    zh = "Chinese"
}

for _, p in pairs(h.splitString(config.sites_to_search)) do

    local ok, l = pcall(require, "providers/"..p)

    if ok then

        providers[p] = l
    else

        mp.osd_message("[subfinder] Unknown provider name: "..p, 10)
        msg.error(l)
    end
end

local function resizeIcons()

    for _, name in pairs({"uploader", "date", "download"}) do

        local iconWidth, iconHeight = h.getShapeSize(icons[name])
        local scale                 = (config.sub_text_size) / iconHeight
        icons[name]                 = h.scaleShape(icons[name], scale)
    end
end

resizeIcons()

local function getPath(key)

    if cachedPaths[key] then return cachedPaths[key] end

    local cacheFolder = "mpvsubfinder"

    if key == "video" then

        local fullPath      = mp.get_property("path")
        local dir, filename = utils.split_path(fullPath)
        dir                 = dir:gsub("[\\//]$", "")
        cachedPaths[key]    = dir

        return cachedPaths[key]
    elseif key == "flag" then

        cachedPaths[key] = path.join({"%scripts", "subfinder", "flags", "<lang>.json"})

        return cachedPaths[key]
    elseif key == "cache/resultsfile" then

        cachedPaths[key] = path.join({"%temp", cacheFolder, "results.json"})

        return cachedPaths[key]
    elseif key == "cache/searchedfile" then

        cachedPaths[key] = path.join({"%temp", cacheFolder, "searched.json"})

        return cachedPaths[key]
    elseif key == "cache/subtitles" then

        cachedPaths[key] = path.join({"%temp", cacheFolder, "subtitles"})

        return cachedPaths[key]
    elseif key == "cache" then

        cachedPaths[key] = path.join({"%temp", cacheFolder})

        return cachedPaths[key]
    end

    return nil
end

local function loadFlag(langCode)

    if not langCode then return end

    if flag.lang then

        if flag.lang == langCode then return end

        h.clearTable(flag.data)

        flag.lang = nil
        flag.data = nil
    end

    if langCode:len() == 2 then

        local content = path.readFile(getPath("flag"):gsub("<lang>", langCode))

        if not content then return end

        flag.lang = langCode
        flag.data = utils.parse_json(content)

        local maxIconHeight = 0

        for _, values in pairs(flag.data) do

            local iconWidth, iconHeight = h.getShapeSize(values.d)

            if iconHeight > maxIconHeight then maxIconHeight = iconHeight end
        end

        local scale = config.sub_text_size / maxIconHeight

        for _, values in pairs(flag.data) do

            values.d = h.scaleShape(values.d, scale)
        end
    end
end

local function getQueryParams()

    local searched = search.text

    local findTag = function (name)

        return searched:match("%s"..name..":(%S+)")
    end

    local getYear = function ()

        local y = tonumber(searched:match(".+(%d%d%d%d)"))

        return (y and y > 1900 and y < 2050) and y or nil
    end

    return {

        title = searched:gsub("%S+:%S+", ""):gsub("%d%d%d%d%s*$",""):gsub("%s+$", ""),
        year  = getYear(),
        tags  = {

            language = findTag("language"),
            s        = tonumber(findTag("s")),
            e        = tonumber(findTag("e")),
            page     = tonumber(findTag("page"))
        }
    }
end

local function getScaleFactor()

    local _, h = mp.get_osd_size()

    return h / 720
end

local function getScaledResolution()

    local w, h        = mp.get_osd_size()
    local scaleFactor = getScaleFactor()

    return w / scaleFactor, h / scaleFactor
end

local function cleanTitle()

    local title = h.removeExt(titleProperties.original)
    title       = title:gsub("%[[A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9][A-Za-z0-9]%]", "") --remove crc

    title =
       title:match("(.-)[Ss]%d+["..subtitle.spaces.."x]*[Ee]?%d+")
    or title:match("(.-)[%.%s_]%-[%.%s_]%d+")
    or title:match("(.-)19%d%d[^pix]")
    or title:match("(.-)20%d%d[^pix]")
    or title:match("(.-)[Ee]%d+")
    or title:match("(.-)#%d+")

    --last resort
    or title:match("(.-)OVA")
    or title:match("(.-)%d+[Pp]")
    or title:match("(.-)["..subtitle.spaces.."]%d%d+["..subtitle.spaces.."]")
    or title

    title = title:gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", "")
    title = title:gsub("[%(%[]", "")
    title = title:gsub("[%._]", " ")
    title = title:gsub("[%s%-]+$", "")
    title = title:gsub("[Ee]pisode%s*$", "")
    if titleProperties.year then title = title:gsub(titleProperties.year, "") end
    title = title:gsub("%s+", " ")
    title = title:gsub("^%s*(.-)%s*$", "%1")

    return title
end

local function fillData()

    data.resultCount                    = #search.results
    data.screenWidth, data.screenHeight = getScaledResolution()
    data.boxWidth, data.boxHeight       = data.screenWidth - config.padding * 2, data.screenHeight - config.padding * 2
    data.x, data.y                      = data.screenWidth / 2 - data.boxWidth / 2, config.padding
    data.contentArea                    = data.boxHeight - (config.padding * 3 + config.text_size)
    data.lineCount                      = math.floor(data.contentArea / (config.text_size + config.sub_text_size + config.padding / 4 + 5))
    data.lineHeight                     = data.contentArea / data.lineCount
    data.gap                            = data.lineHeight - (config.text_size + config.sub_text_size + config.padding / 4 + 5)
    data.lineCount                      = data.lineCount > data.resultCount and data.resultCount or data.lineCount
    data.maxOffset                      = data.resultCount - data.lineCount + 1
    data.barHeight                      = (data.lineCount * data.lineHeight) / (data.resultCount * data.lineHeight) * (data.lineCount * data.lineHeight)
    data.boxHeight                      = data.resultCount > 0 and config.text_size + config.padding * 2 + data.lineHeight * data.lineCount + config.padding or config.text_size + config.padding * 2

    panel:setResolution(data.screenWidth, data.screenHeight)
end

local function render()

    --background

    panel:properties({x = data.x, y = data.y, color = h.assColor(config.box_color), alpha = config.box_alpha}):shape(data.boxWidth, data.boxHeight, config.round)

    --label

    panel:properties({x = data.x + config.padding, y = data.y + config.padding}):text(labelText)

    --input

    local labelWidth           = gui:calculateTextWidth(labelText, config.text_size)
    local text, textWithCursor = input.texts()

    panel:properties({x = data.x + config.padding + labelWidth, y = data.y + config.padding}):text(text)

    --input

    panel:properties({x = data.x + config.padding + labelWidth, y = data.y + config.padding}):text(textWithCursor)

    --rows

    if data.resultCount > 0 then

        local lineX = data.x + config.padding
        local lineY = data.y + config.text_size + config.padding * 2
        m           = 1

        for k = offset, offset + data.lineCount - 1 do

            local posX, posY
            local selected = currentIndex == k
            local faded   = false
            --local faded   = (search.results[k].installed and not selected) and true or false

            --ai or sameversion

            if search.results[k].sameversion then

                panel:properties({x = data.x, y = lineY, color = colors.sameversion, alpha = 200}):shape(data.boxWidth, data.lineHeight, 0)
            elseif search.results[k].ai then

                panel:properties({x = data.x, y = lineY, color = colors.ai, alpha = 200}):shape(data.boxWidth, data.lineHeight, 0)
            end

            --selected or stripped

            if selected then

                panel:properties({x = data.x, y = lineY, color = colors.text}):shape(data.boxWidth, data.lineHeight, 0)
            elseif m % 2 == 0 then

                panel:properties({x = data.x, y = lineY, color = colors.text, alpha = 230}):shape(data.boxWidth, data.lineHeight, 0)
            end

            posX = lineX
            posY = lineY

            --flag

            posY = lineY + data.gap + config.text_size / 2

            panel:properties({x = posX, y = posY, align = 7, alpha = faded and 0.5 or 0}):flag(currentLanguage)

            posX = lineX + config.pin_right_margin
            posY = lineY + data.gap + config.text_size / 2

            --quality

            if search.results[k].quality then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag(search.results[k].quality)

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --hi

            if search.results[k].hi == true then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("hi")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --foreign

            if search.results[k].foreign == true then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("foreign")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --forced

            if search.results[k].forced == true then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("forced")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --bulk

            if search.results[k].bulk == true then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("batch")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --region

            if search.results[k].region then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag(search.results[k].region)

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --title

            panel:properties({x = posX, y = posY, align = 4, color = selected and colors.hover or colors.text, alpha = faded and 150 or 0, clip = string.format("%s,%s,%s,%s", lineX, lineY, lineX + (data.boxWidth / 100 * 80), lineY + data.lineHeight)}):text(search.results[k].title)


            posX = lineX + config.pin_right_margin
            posY = lineY + data.gap + config.text_size + 5 + config.sub_text_size / 2

            --uploader

            panel:properties({x = posX, y = posY, color = selected and colors.hover or colors.subtext, align = 4, alpha = faded and 150 or 0}):icon("uploader", search.results[k].uploader)

            --date

            if search.results[k].date then

                panel:properties({x = posX + (data.boxWidth / 100 * config.column_width), y = posY, color = selected and colors.hover or colors.subtext, align = 4, alpha = faded and 150 or 0}):icon("date", search.results[k].date)
            end

            --download

            if search.results[k].downloads then

                panel:properties({x = posX + (data.boxWidth / 100 * config.column_width * 2), y = posY, color = selected and colors.hover or colors.subtext, align = 4, alpha = faded and 150 or 0}):icon("download", search.results[k].downloads)
            end

            posX = data.boxWidth
            posY = lineY + data.lineHeight / 2

            --site name

            panel:properties({x = posX, y = posY, align = 6, color = search.results[k].searchMode == "imdb" and colors.imdb or (selected and colors.hover or colors.text), bold = true}):text(search.results[k].provider)

            lineY = lineY + data.lineHeight
            m     = m + 1
        end

        --scroll

        if not search.processing and data.resultCount > data.lineCount then

            lineY      = data.y + config.text_size + config.padding * 2
            local barX = data.x + data.boxWidth - config.bar_width
            local barY = (data.contentArea - data.barHeight) * ((offset - 1) / (data.maxOffset - 1))

            panel:properties({x = barX, y = lineY + barY, color = colors.text, border = 1.3}):shape(config.bar_width, data.barHeight, 0)
        end
    end

    --hint

    if message ~= "" then

        panel:properties({x = data.x + data.boxWidth - config.padding, y = data.y + config.padding, color = colors.subtext, align = 9}):text(message)
    elseif data.resultCount > 0 then

        panel:properties({x = data.x + data.boxWidth - config.padding, y = data.y + config.padding, align = 9}):text(string.format("%s/%s", currentIndex, data.resultCount))
    end

    --update

    panel:update()
end

local function reset()

    h.clearTable(data)
    h.clearTable(search.results)
    h.clearTable(titleProperties)
    h.clearTable(cachedPaths)
    h.clearTable(query)

    currentLanguage  = ""
    search.text      = ""
    mouse.x, mouse.y = 0, 0
end

local function showMessage(str)

    message = str or ""

    render()
end

local function loadTitleProperties()

    if not titleProperties.original then

        local filename           = mp.get_property("filename")
        titleProperties          = subtitle:properties(h.removeExt(filename))
        titleProperties.original = filename
    end
end

local function startDownload(link, provider)

    mp.osd_message("Please wait...", 30)

    path.removeDir(getPath("cache/subtitles"))
    path.createDir(getPath("cache/subtitles"))

    provider:download(link, getPath("cache/subtitles"))

    local archiveFiles = h.listFiles(getPath("cache/subtitles"), config.archive_types)

    if archiveFiles then h.unpackArchive(path.join({getPath("cache/subtitles"), archiveFiles[1]}), getPath("cache/subtitles")) end

    local subFiles = h.listFiles(getPath("cache/subtitles"), "ass,srt")

    if not (subFiles and subFiles[1]) then mp.osd_message("Subtitle file not found.", 3) return end

    local attachSubtitle = function(subtitleFile, videoFile)

        local attachedSubtitleFile = path.join({getPath("video"), table.concat({h.removeExt(videoFile), currentLanguage, h.getExt(subtitleFile)}, ".")})

        if path.checkPath(attachedSubtitleFile) then path.removeFile(attachedSubtitleFile) end

        h.copyFile(path.join({getPath("cache/subtitles"), subtitleFile}), attachedSubtitleFile)
    end

    local videos        = h.listFiles(getPath("video"), config.video_types)
    local subtitles     = h.listFiles(getPath("cache/subtitles"), config.subtitle_types)
    local videoCount    = videos    and #videos    or 0
    local subtitleCount = subtitles and #subtitles or 0

    if subtitleCount == 0 then mp.osd_message("Subtitle file not found.", 3) return end

    local subtitleOfThisVideo   = ""
    local attachedSubtitleCount = 0

    if not (query.tags and query.tags.s) then

        attachSubtitle(subtitles[1], titleProperties.original)

        subtitleOfThisVideo   = subtitles[1]
        attachedSubtitleCount = attachedSubtitleCount + 1
    else

        local episodes = {}

        for _, s in pairs(subtitles) do

            local eNumber = subtitle:getEpisodeNumber(s)

            if eNumber then

                if not episodes[eNumber]           then episodes[eNumber]           = {} end
                if not episodes[eNumber].subtitles then episodes[eNumber].subtitles = {} end

                table.insert(episodes[eNumber].subtitles, s)
            else

                msg.warn("[subtitle matching] Episode number not found: "..s)
            end
        end

        for _, v in pairs(videos) do

            local eNumber = subtitle:getEpisodeNumber(v)

            if eNumber then

                if episodes[eNumber] then

                    if not episodes[eNumber].videos then episodes[eNumber].videos = {} end

                    table.insert(episodes[eNumber].videos, v)
                else

                    msg.warn("[video matching] No subtitles found for this video: "..v)
                end
            else

                msg.warn("[video matching] Episode number not found:"..v)
            end
        end

        for eIndex, e in pairs(episodes) do

            if e.videos then

                for vIndex, v in pairs(e.videos) do

                    local bestSubtitle = e.subtitles and #e.subtitles > 1 and h.findBestSubtitle(v, e.subtitles) or e.subtitles[1]

                    if bestSubtitle then

                        if v == titleProperties.original then subtitleOfThisVideo = bestSubtitle end

                        attachSubtitle(bestSubtitle, v)

                        attachedSubtitleCount = attachedSubtitleCount + 1
                    end
                end
            end
        end
    end

    if subtitleOfThisVideo ~= "" then

        subtitleOfThisVideo = path.join({getPath("video"), table.concat({h.removeExt(titleProperties.original), currentLanguage, h.getExt(subtitleOfThisVideo)}, ".")})

        if path.checkPath(subtitleOfThisVideo) then mp.commandv("sub-add", subtitleOfThisVideo, "select") end
    end

    if attachedSubtitleCount > 0 then

        mp.osd_message("Completed!", 3)
    else

        mp.osd_message("Failed!", 3)
    end
end

local function getProviderFromLink(link)

    link = link or ""

    return string.match(link, "//([^%.]*)")
end

local function openInBrowser()

    if not (search.results[currentIndex] and search.results[currentIndex].pageLink) then msg.warn("Link not found!") return end

    local provider = providers[search.results[currentIndex].provider]

    h.visitTo(search.results[currentIndex].pageLink and provider.url.site..search.results[currentIndex].pageLink or nil)
end

local function downloadFile()

    if not (search.results[currentIndex] and search.results[currentIndex].downloadLink) then mp.osd_message("Link not found!", 5) return end

    local provider = providers[search.results[currentIndex].provider]

    startDownload(search.results[currentIndex].downloadLink, provider)
end

local function pasteLink()

    loadTitleProperties()

    currentLanguage = "xx"
    local clipboard = mp.get_property("clipboard/text", "")
    local provider  = getProviderFromLink(clipboard)

    if not (provider and providers[provider]) then mp.osd_message(string.format("Provider (%s) not found!", clipboard:sub(1,50)), 5) return end

    startDownload(clipboard, providers[provider])
    reset()
end

local function writeResultsToCache()

    local ok = path.createFile(getPath("cache/resultsfile"), utils.format_json(search.results))

    if not ok then mp.osd_message("Results not saved!", 3) return end

    path.createFile(getPath("cache/searchedfile"), utils.format_json({filename = titleProperties.original, searched = search.text}))
end

local function readResultsFromCache()

    local searchedFile = path.readFile(getPath("cache/searchedfile"))

    if searchedFile then

        searchedFile = utils.parse_json(searchedFile)

        if searchedFile.filename == titleProperties.original then

            local resultsFile = path.readFile(getPath("cache/resultsfile"))

            if resultsFile then

                resultsFile     = utils.parse_json(resultsFile)
                search.text     = searchedFile.searched
                query           = getQueryParams()
                currentLanguage = query.tags.language
                search.results  = resultsFile

                fillData()
                loadFlag(currentLanguage)
            end
        end
    end
end

local function submit()

    h.clearTable(query)
    h.clearTable(search.results)

    data.resultCount = 0
    data.lineCount   = 0
    currentIndex     = 1
    offset           = 1

    fillData()

    query = getQueryParams()

    if not query.tags.language then

        showMessage("Language tag (language:en) required")

        return
    end

    loadFlag(query.tags.language)

    if not flag.data then

        showMessage("Language not found")

        return
    end

    currentLanguage   = query.tags.language
    local sites       = h.splitString(config.sites_to_search)
    local results     = {}
    local steps       = 1
    search.processing = true

    --search

    steps = steps + #sites

    showMessage(string.format("(%s) IMDb ID searching...", steps))

    query.imdbId = request:findImdbId(query)
    steps        = steps - 1

    for i, p in pairs(sites) do

        showMessage(string.format("(%s) Getting subtitles from %s...", steps, p))

        local rows, searchMode = providers[p]:findSubtitles(query)

        if rows then

            for k, v in pairs(rows) do

                v.provider   = p
                v.searchMode = searchMode

                table.insert(search.results, v)
            end
        end

        steps = steps - 1
    end

    --sorting

    if config.smart_sorting then

        if titleProperties.quality then

            h.reindex(results, "order")

            local qualityOrder

            if     titleProperties.quality == "bd"  then qualityOrder = {bd  = 3, web = 2, dvd = 1}
            elseif titleProperties.quality == "web" then qualityOrder = {web = 3, bd  = 2, dvd = 1}
            elseif titleProperties.quality == "dvd" then qualityOrder = {dvd = 3, web = 2, bd  = 1} end

            table.sort(results, function(a, b)

                local aQuality = qualityOrder[a.quality] or 0
                local bQuality = qualityOrder[b.quality] or 0

                return aQuality == bQuality and a.order < b.order or aQuality > bQuality
            end)
        end
    end

    for i, v in pairs(results) do

        table.insert(search.results, v)
    end

    search.processing = false

    if #search.results > 0 then

        showMessage()
    else

        showMessage("No results found")
    end

    fillData()
    render()
end

local function togglePlayerControllers()

    if not opened then

        mp.commandv("script-message", "osc-visibility", "never", "no-osd")
        mp.commandv("script-message-to", "uosc", "disable-elements", mp.get_script_name(), "timeline,controls,volume,top_bar,speed")
    else

        mp.commandv("script-message", "osc-visibility", "auto", "no-osd")
        mp.commandv("script-message-to", "uosc", "disable-elements", mp.get_script_name(), "")
    end
end

local function toggle()

    togglePlayerControllers()

    if not opened then

        if firstOpened then

            --site check

            if config.sites_to_search:gsub("%s", "") == "" then

                mp.osd_message("Please select at least one provider", 5) return
            end

            --secrets check

            for _, p in pairs(h.splitString(config.sites_to_search)) do

                if config["api_"..p] and config["api_"..p]:gsub("%s", "") == "" then

                    mp.osd_message(string.format("API key required for %s", p), 5) return
                end
            end

            --[[

            for _, p in pairs(h.splitString(config.sites_to_search)) do

                if config["credentials_"..p] and not config["credentials_"..p]:find("[^:]+:[^:]+") then

                    mp.osd_message(string.format("Username and password required for %s", p), 5) return
                end
            end

            ]]

            --dependencies check

            local dependencies = {}

            table.insert(dependencies, "curl")

            if config.extract_engine == "winrar" then

                table.insert(dependencies, "winrar")
            elseif config.extract_engine == "7zip" then

                table.insert(dependencies, "7z")
            else

                mp.osd_message(string.format("Unknown extract engine: %s (Use 7zip or winrar)", config.extract_engine), 5) return
            end

            for _, d in pairs(dependencies) do

                if not h.commandCheck(d) then

                    mp.osd_message(string.format("Command not exists: %s", d), 5) return
                end
            end

            firstOpened = false
        end

        input.init()
        loadTitleProperties()
        readResultsFromCache()

        if search.text == "" then

            local searched = cleanTitle()

            if titleProperties.episode and not titleProperties.season then titleProperties.season = 1                                   end
            if titleProperties.year                                   then searched = searched.." "..titleProperties.year               end
            if titleProperties.season                                 then searched = searched.." s:"..titleProperties.season           end
            if titleProperties.episode                                then searched = searched.." e:"..titleProperties.episode          end
            if config.preferred_language ~= ""                        then searched = searched.." language:"..config.preferred_language end

            search.text = searched
        end

        input.font_size    = config.text_size
        input.cursor_theme = config.cursor_color

        input.default(search.text)

        if next(search.results) == nil then submit() end
        --fillData()
        render()
        setBindings()
    else

        unsetBindings()
        panel:remove()

        input.reset()
        collectgarbage()
    end

    opened = not opened
end

local function setCurrentIndex()

    local lineY = data.y + config.text_size + config.padding * 2

    for k = offset, offset + data.lineCount - 1 do

        if mouse.y and mouse.y > lineY and mouse.y < lineY + data.lineHeight and mouse.x > config.padding and mouse.x < config.padding + data.boxWidth then

            currentIndex = k

            return true
        end

        lineY = lineY + data.lineHeight
    end

    return false
end

local function bindingList()

    local inputBindings = input.bindings({

        after_changes = function()

            local searched = input.get_text()

            if searched ~= search.text then

                message     = "Please wait..."
                search.text = searched

                if search.timer then search.timer:kill() end

                search.timer = mp.add_timeout(3, submit)
            end

            render()
        end
    })

    local defaultBindings = {

        scrollup = {

            key  = "wheel_up",
            func = function ()

                if offset > 1 then offset = offset - 1 end

                setCurrentIndex()
                render()
            end,
            opts = nil
        },

        scrolldown = {

            key  = "wheel_down",
            func = function ()

                if data.maxOffset and offset < data.maxOffset then offset = offset + 1 end

                setCurrentIndex()
                render()
            end,
            opts = nil
        },

        up = {

            key  = "up",
            func = function ()

                if currentIndex > 1                                                           then currentIndex = currentIndex - 1 end
                if data.resultCount > data.lineCount and currentIndex < offset and offset > 1 then offset = offset - 1             end

                render()
            end,
            opts = {repeatable = true}
        },

        down = {

            key  = "down",
            func = function ()

                if currentIndex < data.resultCount                                                 then currentIndex = currentIndex + 1 end
                if data.resultCount > data.lineCount and currentIndex == (offset + data.lineCount) then offset = offset + 1             end

                render()
            end,
            opts = {repeatable = true}
        },

        close = {

            key  = "esc",
            func = function ()

                toggle()
                writeResultsToCache()
                reset()
            end,
            opts = nil
        },

        confirm = {

            key  = "enter",
            func = function ()

                if data.resultCount > 0 then

                    toggle()
                    writeResultsToCache()
                    downloadFile()
                    reset()
                end
            end,
            opts = nil
        },

        download = {

            key  = "mbtn_left",
            func = function ()

                toggle()
                writeResultsToCache()

                local isMouseOverRow = setCurrentIndex()

                if isMouseOverRow then downloadFile() end

                reset()
            end,
            opts = nil
        },

        visit1 = {

            key  = "ctrl+enter",
            func = function ()

                openInBrowser()
            end,
            opts = nil
        },

        visit2 = {

            key  = "ctrl+mbtn_left",
            func = function ()

                openInBrowser()
            end,
            opts = nil
        }
    }

    return h.tableMerge(defaultBindings, inputBindings)
end

function setBindings()

    for name, binding in pairs(bindingList()) do mp.add_forced_key_binding(binding.key, "subfinder_"..name, binding.func, binding.opts) end
end

function unsetBindings()

    for name in pairs(bindingList()) do mp.remove_key_binding("subfinder_"..name) end
end

function titleMetadataTest()

    local testTitle = "[anti-raws]K-ON!! ep.15[BDRemux]"

    print(string.format("Parsing result for %s", testTitle))
    h.log2(subtitle:properties(testTitle))
end

mp.observe_property("mouse-pos", "native", function()

    if opened then

        local x, y        = mp.get_mouse_pos()
        local scaleFactor = getScaleFactor()
        mouse.x, mouse.y  = math.floor(x / scaleFactor), math.floor(y / scaleFactor)

        setCurrentIndex()
        render()
    end
end)

mp.observe_property("osd-dimensions", "native", function (_, value)

    if opened then fillData() render() end
end)

mp.observe_property("display-hidpi-scale", "native", function (name, value)

    if opened then fillData() render() end
end)

mp.add_forced_key_binding(nil, "subfinder", function()

    if not opened then

        toggle()
    else

        toggle()
        writeResultsToCache()
        reset()
    end
end)
mp.add_forced_key_binding(nil, "subfinder_pastelink", function ()

    if opened then

        toggle()
        writeResultsToCache()
        reset()
    end

    pasteLink()
end)