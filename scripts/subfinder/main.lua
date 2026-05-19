--[[

╔════════════════════════════════╗
║          MPV subfinder         ║
║              v1.0.3            ║
╚════════════════════════════════╝

]]

local options  = require "mp.options"
local utils    = require "mp.utils"
local utf8     = require "lib/fastutf8"
local input    = require "lib/input"
local path     = require "lib/path"
local h        = require "lib/helper"
local subtitle = require "lib/subtitle"
local gui      = require "lib/gui"
local request  = require "lib/base"
local msg      = require "mp.msg"
config         = {

    --settings
    preferred_language = "en",
    smart_sorting      = false,
    useragent          = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36",
    video_types        = "mkv,mp4,avi",
    subtitle_types     = "srt,ass",
    archive_types      = "zip,rar,7z",

    --gui
    text_size          = 24,
    sub_text_size      = 16,
    box_alpha          = 70, -- 0-255
    box_color          = "000000",
    cursor_color       = "white", -- white,black
    padding            = 10,
    round              = 8,
    pin_right_margin   = 35,
    icon_right_margin  = 25,
    date_format        = "<mm>-<dd>-<yyyy>",
    bar_width          = 4,
    column_width       = 15,
    tag_padding        = 4,
    tag_right_margin   = 8,


    --api keys
    sites_to_search    = "", --subsource,subdl,altyazidb,turkcealtyazi
    api_subsource      = "",
    api_subdl          = "",
    api_altyazidb      = ""
}

options.read_options(config, "subfinder")

local labelText       = "Search for subtitles:"
local data            = {}
local opened          = false
local mouse           = {x = 0, y = 0}
local offset          = 1
local currentIndex    = 1
local message         = ""
local titleProperties = {}
local panel           = gui:new()
local providers       = {}
local currentLanguage = ""
local search          = {timer = nil, text = "", results = {}, processing = false}
local cachedPaths     = {}
local firstOpened     = true
local query           = {}

colors = {

    text     = "FFFFFF",
    subtext  = "959595",
    hover    = "000000",
    delete   = "0000FF",
    bd       = "1F85CC",
    web      = "F8786C",
    dvd      = "7F7F7F",
    hi       = "5551F9",
    batch    = "45AD18",
    foreign  = "CABF35"
}

icons = {

    uploader = "m 16 15 l 16 15 19 14 21 10 19 6 16 5 l 16 5 12 7 11 10 12 14 16 15 m 16 17 b 9 17 5 21 5 23 l 5 26 l 27 26 l 27 23 b 27 21 22 17 16 17",
    date     = "m 8 30 l 24 30 l 24 30 28 26 28 25 l 28 9 l 28 9 25 6 l 23 6 l 23 4 l 23 4 20 4 l 20 6 l 12 6 l 12 4 l 12 4 9 4 l 9 6 l 6 6 l 6 6 4 9 l 4 25 l 4 25 7 29 8 30 m 6 17 l 6 17 7 16 l 25 16 l 25 16 25 17 l 25 25 l 25 25 24 27 l 8 27 l 8 27 6 25",
    download = "m 19 19 l 1 19 b 0 19 0 18 0 18 l 0 13 l 2 13 l 2 17 l 18 17 l 18 13 l 20 13 l 20 18 b 20 18 19 19 19 19 m 15 7 b 15 6 14 6 14 7 l 11 10 l 11 2 b 11 1 10 1 10 1 b 9 1 9 1 9 2 l 9 10 l 5 7 b 5 6 4 6 4 7 b 3 7 3 8 4 8 l 9 13 b 9 14 10 14 10 13 l 15 8 b 16 8 16 7 15 7"
}

flags = {

    fr = {

        {c = "910000", d = "m 0 0 l 213 0 l 213 480 l 0 480"},
        {c = "FFFFFF", d = "m 213 0 l 426 0 l 426 480 l 213 480"},
        {c = "0F00E1", d = "m 426 0 l 640 0 l 640 480 l 426 480"}
    },
    it = {

        {c = "372BCE", d = "m 36 27 b 36 29 34 31 32 31 l 24 31 l 24 5 l 32 5 b 34 5 36 6 36 9 l 36 27"},
        {c = "469200", d = "m 4 5 b 1 5 0 6 0 9 l 0 27 b 0 29 1 31 4 31 l 12 31 l 12 5 l 4 5"},
        {c = "EEEEEE", d = "m 12 5 l 24 5 l 24 31 l 12 31"}
    },
    es = {

        {c = "1D0AC6", d = "m 36 27 b 36 29 34 31 32 31 l 4 31 b 1 31 0 29 0 27 l 0 9 b 0 6 1 5 4 5 l 32 5 b 34 5 36 6 36 9 l 36 27"},
        {c = "00C4FF", d = "m 0 12 l 36 12 l 36 24 l 0 24"},
        {c = "6E59EA", d = "m 9 17 l 9 20 b 9 21 10 23 12 23 b 13 23 15 21 15 20 l 15 17 l 9 17"},
        {c = "B2A2F4", d = "m 12 16 l 15 16 l 15 19 l 12 19"},
        {c = "442EDD", d = "m 9 16 l 12 16 l 12 19 l 9 19"},
        {c = "6E59EA", d = "m 12 13 b 13 13 15 13 15 14 b 15 15 13 16 12 16 b 10 16 9 15 9 14 b 9 13 10 13 12 13"},
        {c = "33ACFF", d = "m 12 13 b 13 13 15 13 15 13 b 15 14 13 14 12 14 b 10 14 9 14 9 13 b 9 13 10 13 12 13"},
        {c = "B5AA99", d = "m 7 16 l 8 16 l 8 23 l 7 23 m 16 16 l 17 16 l 17 23 l 16 23"},
        {c = "7F7566", d = "m 6 22 l 9 22 l 9 23 l 6 23 m 15 22 l 18 22 l 18 23 l 15 23 m 7 15 l 8 15 l 8 16 l 7 16 m 16 15 l 17 15 l 17 16 l 16 16"}
    },
    zh = {

        {c = "1029DE", d = "m 36 27 b 36 29 34 31 32 31 l 4 31 b 1 31 0 29 0 27 l 0 9 b 0 6 1 5 4 5 l 32 5 b 34 5 36 6 36 9 l 36 27"},
        {c = "02DEFF", d = "m 11 9 l 11 9 l 12 8 l 12 9 l 13 10 l 12 10 l 12 10 l 11 10 l 10 10 l 11 9 m 15 11 l 15 12 l 16 13 l 15 13 l 14 13 l 14 13 l 13 12 l 14 12 l 14 11 l 15 12 m 14 15 l 15 16 l 15 16 l 15 17 l 15 17 l 14 17 l 14 17 l 14 17 l 13 16 l 14 16 m 11 19 l 11 19 l 12 18 l 12 19 l 13 20 l 12 20 l 12 20 l 11 20 l 10 20 l 11 19 m 7 11 l 7 13 l 10 13 l 8 15 l 9 18 l 7 16 l 4 18 l 5 15 l 3 13 l 6 13"}
    },
    de = {

        {c = "05CDFF", d = "m 0 27 b 0 29 1 31 4 31 l 32 31 b 34 31 36 29 36 27 l 36 23 l 0 23 l 0 27"},
        {c = "241FED", d = "m 0 14 l 36 14 l 36 23 l 0 23"},
        {c = "141414", d = "m 32 5 l 4 5 b 1 5 0 6 0 9 l 0 14 l 36 14 l 36 9 b 36 6 34 5 32 5"}
    },
    ru = {

        {c = "2820CE", d = "m 36 27 b 36 29 34 31 32 31 l 4 31 b 1 31 0 29 0 27 l 0 23 l 36 23 l 36 27"},
        {c = "8C4022", d = "m 0 13 l 36 13 l 36 23 l 0 23"},
        {c = "EEEEEE", d = "m 32 5 l 4 5 b 1 5 0 6 0 9 l 0 13 l 36 13 l 36 9 b 36 6 34 5 32 5"}
    },
    ja = {

        {c = "EEEEEE", d = "m 36 27 b 36 29 34 31 32 31 l 4 31 b 1 31 0 29 0 27 l 0 9 b 0 6 1 5 4 5 l 32 5 b 34 5 36 6 36 9 l 36 27"},
        {c = "2F1BED", d = "m 18 11 b 21 11 25 14 25 18 b 25 21 21 25 18 25 b 14 25 11 21 11 18 b 11 14 14 11 18 11"}
    },
    tr = {

        {c = "170AE3", d = "m 0 0 l 640 0 l 640 480 l 0 480"},
        {c = "FFFFFF", d = "m 407 247 b 407 313 352 367 285 367 b 217 367 163 313 163 247 b 163 181 217 127 285 127 b 352 127 407 181 407 247"},
        {c = "170AE3", d = "m 413 247 b 413 300 369 343 315 343 b 261 343 217 300 217 247 b 217 194 261 151 315 151 b 369 151 413 194 413 247"},
        {c = "FFFFFF", d = "m 430 191 l 429 235 l 388 247 l 429 261 l 428 302 l 454 270 l 494 284 l 471 250 l 500 216 l 456 228 l 430 191"}
    },
    en = {

        {c = "692101", d = "m 0 0 l 640 0 l 640 480 l 0 480"},
        {c = "FFFFFF", d = "m 75 0 l 319 181 l 562 0 l 640 0 l 640 62 l 400 241 l 640 419 l 640 480 l 560 480 l 320 301 l 81 480 l 0 480 l 0 420 l 239 242 l 0 64 l 0 0"},
        {c = "2E10C8", d = "m 424 281 l 640 440 l 640 480 l 369 281 m 240 301 l 246 336 l 54 480 l 0 480 m 640 0 l 640 3 l 391 191 l 393 147 l 590 0 m 0 0 l 239 176 l 179 176 l 0 42"},
        {c = "FFFFFF", d = "m 241 0 l 241 480 l 401 480 l 401 0 m 0 160 l 0 320 l 640 320 l 640 160"},
        {c = "2E10C8", d = "m 0 193 l 0 289 l 640 289 l 640 193 m 273 0 l 273 480 l 369 480 l 369 0"}
    }
}

for _, p in pairs(h.splitString(config.sites_to_search)) do

    local ok, l = pcall(require, "providers/"..p)

    if ok then

        providers[p] = l
    else

        mp.osd_message("[subfinder] Unknown provider name: "..p, 10)
    end
end

local function resizeShapes()

    for _, name in pairs({"uploader", "date", "download"}) do

        local iconWidth, iconHeight = h.getShapeSize(icons[name])
        local scale                 = (config.sub_text_size) / iconHeight
        icons[name]                 = h.scaleShape(icons[name], scale)
    end

    for _, flag in pairs(flags) do

        local maxIconHeight = 0

        for _, values in pairs(flag) do

            local iconWidth, iconHeight = h.getShapeSize(values.d)

            if iconHeight > maxIconHeight then maxIconHeight = iconHeight end
        end

        local scale = config.sub_text_size / maxIconHeight

        for _, values in pairs(flag) do

            values.d = h.scaleShape(values.d, scale)
        end
    end
end

resizeShapes()

local function getQueryParams()

    local searched = search.text

    local findTag = function (name)

        return searched:match(name..":(%S+)")
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
            e        = tonumber(findTag("e"))
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

    local title = h.removeExt(titleProperties.name)

    title = title:gsub("%d%d%d%d[%s_]+x[%s_]+%d%d%d", "")

    title =
       title:match("^(.-)S%d+[%s%.%-]*E?%d+")
    or title:match("(.-)[%s_]%-[%s_]%d+")
    or title:match("^(.-)19%d%d[^pix]")
    or title:match("^(.-)20%d%d[^pix]")
    or title:match("^(.-)%d+p")
    or title

    title = title:gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", "")
    title = title:gsub("[%(%[]", "")
    title = title:gsub("[%._]", " ")
    title = title:gsub("[%s%-]+$", "")
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
            local hovered = currentIndex == k
            local faded   = (search.results[k].installed and not hovered) and true or false

            --hover or stripped

            if hovered then

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

            if search.results[k].hi then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("hi")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --foreign

            if search.results[k].foreign then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("foreign")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --bulk

            if search.results[k].bulk then

                panel:properties({x = posX, y = posY, alpha = faded and 150 or 0}):tag("batch")

                posX = posX + panel:getLastWidth() + config.tag_right_margin
            end

            --title

            panel:properties({x = posX, y = posY, align = 4, color = hovered and colors.hover or colors.text, alpha = faded and 150 or 0, clip = string.format("%s,%s,%s,%s", lineX, lineY, lineX + (data.boxWidth / 100 * 80), lineY + data.lineHeight)}):text(search.results[k].title)


            posX = lineX + config.pin_right_margin
            posY = lineY + data.gap + config.text_size + 5 + config.sub_text_size / 2

            --uploader

            panel:properties({x = posX, y = posY, color = hovered and colors.hover or colors.subtext, align = 4, alpha = faded and 150 or 0}):icon("uploader", search.results[k].uploader)

            --date

            if search.results[k].date then

                panel:properties({x = posX + (data.boxWidth / 100 * config.column_width), y = posY, color = hovered and colors.hover or colors.subtext, align = 4, alpha = faded and 150 or 0}):icon("date", search.results[k].date)
            end

            --download

            if search.results[k].downloads then

                panel:properties({x = posX + (data.boxWidth / 100 * config.column_width * 2), y = posY, color = hovered and colors.hover or colors.subtext, align = 4, alpha = faded and 150 or 0}):icon("download", search.results[k].downloads)
            end

            posX = data.boxWidth
            posY = lineY + data.lineHeight / 2

            --site name or download/delete button

            if hovered then

                if search.results[k].installed then

                    panel:properties({x = posX, y = posY, color = colors.delete, align = 6, bold = true}):text("Delete")
                else

                    panel:properties({x = posX, y = posY, color = colors.hover, align = 6, bold = true}):text("Download")
                end
            else

                panel:properties({x = posX, y = posY, color = colors.subtext, align = 6, bold = true}):text(search.results[k].provider.name)
            end

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

    mouse.x, mouse.y = 0, 0
    offset           = 1
    currentIndex     = 1
    currentLanguage  = ""
end

local function showMessage(str)

    message = str or ""

    render()
end

local function getPath(key)

    if cachedPaths[key] then return cachedPaths[key] end

    if key == "video" then

        local fullPath      = mp.get_property("path")
        local dir, filename = utils.split_path(fullPath)
        dir                 = dir:gsub("[\\//]$", "")
        cachedPaths[key]    = dir

        return cachedPaths[key]
    elseif key == "cache" then

        cachedPaths[key] = path.join({"%temp", "mpvsubfinder"})

        return cachedPaths[key]
    end

    return nil
end

local function openInBrowser()

    if not search.results[currentIndex]          then msg.warn("Row not found!")  return end
    if not search.results[currentIndex].pageLink then msg.warn("Link not found!") return end

    h.visitTo(search.results[currentIndex].pageLink)
end

local function downloadFile()

    if not search.results[currentIndex] then return end

    path.removeDir(getPath("cache"))
    path.createDir(getPath("cache"))

    search.results[currentIndex].provider:download(search.results[currentIndex], getPath("cache"))

    local archiveFiles = h.listFiles(getPath("cache"), config.archive_types)

    if not (archiveFiles and archiveFiles[1]) then

        mp.osd_message("Zip file not found.", 3) return
    end

    h.unpackArchive(path.join({getPath("cache"), archiveFiles[1]}), getPath("cache"))

    local subFiles = h.listFiles(getPath("cache"), "ass,srt")

    if not (subFiles and subFiles[1]) then

        mp.osd_message("Subtitle file not found.", 3) return
    end

    local attachSubtitle = function(subtitleFile, videoFile)

        local attachedSubtitleFile = path.join({getPath("video"), table.concat({h.removeExt(videoFile), currentLanguage, h.getExt(subtitleFile)}, ".")})

        if path.checkPath(attachedSubtitleFile) then path.removeFile(attachedSubtitleFile) end

        h.copyFile(path.join({getPath("cache"), subtitleFile}), attachedSubtitleFile)
    end

    local videos        = h.listFiles(getPath("video"), config.video_types)
    local subtitles     = h.listFiles(getPath("cache"), config.subtitle_types)
    local videoCount    = videos    and #videos    or 0
    local subtitleCount = subtitles and #subtitles or 0

    if subtitleCount == 0 then mp.osd_message("Subtitle file not found.", 3) return end

    local subtitleOfThisVideo   = ""
    local attachedSubtitleCount = 0

    if not (query.tags and query.tags.s or query.tags.e) then

        attachSubtitle(subtitles[1], titleProperties.name)

        subtitleOfThisVideo   = subtitles[1]
        attachedSubtitleCount = attachedSubtitleCount + 1
    else

        local episodes = {}

        for _, s in pairs(subtitles) do

            local eNumber = subtitle:getEpisodeNumber(s:lower())

            if eNumber then

                if not episodes[eNumber]           then episodes[eNumber]           = {} end
                if not episodes[eNumber].subtitles then episodes[eNumber].subtitles = {} end

                table.insert(episodes[eNumber].subtitles, s)
            else

                msg.warn("[subtitle matching] Episode number not found: "..s)
            end
        end

        for _, v in pairs(videos) do

            local eNumber = subtitle:getEpisodeNumber(v:lower())

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

                        if v == titleProperties.name then subtitleOfThisVideo = bestSubtitle end

                        attachSubtitle(bestSubtitle, v)

                        attachedSubtitleCount = attachedSubtitleCount + 1
                    end
                end
            end
        end
    end

    if subtitleOfThisVideo ~= "" then

        subtitleOfThisVideo = path.join({getPath("video"), table.concat({h.removeExt(titleProperties.name), currentLanguage, h.getExt(subtitleOfThisVideo)}, ".")})

        if path.checkPath(subtitleOfThisVideo) then mp.commandv("sub-add", subtitleOfThisVideo, "select") end
    end

    if attachedSubtitleCount > 0 then

        mp.osd_message("Download completed!", 3)
    else

        mp.osd_message("Download failed!", 3)
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

    if not flags[query.tags.language] then

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

        h.tableMerge3(results, providers[p]:findSubtitles(query))

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

        mp.commandv("script-message-to", "uosc", "disable-elements", mp.get_script_name(), "timeline,controls,volume,top_bar,speed")
    else

        mp.commandv("script-message-to", "uosc", "disable-elements", mp.get_script_name(), "")
    end
end

local function toggle()

    if not opened then

        if firstOpened then

            --site check

            if config.sites_to_search:gsub("%s", "") == "" then

                mp.osd_message("Please select at least one provider", 5) return
            end

            --APIs check

            for _, p in pairs(h.splitString(config.sites_to_search)) do

                if providers[p].url and providers[p].url.api and config["api_"..p]:gsub("%s", "") == "" then

                    mp.osd_message(string.format("An API key is required for %s", p), 5) return
                end
            end

            --dependencies check

            local dependencies = {"7z", "curl"}

            for _, d in pairs(dependencies) do

                if not h.commandCheck(d) then

                    mp.osd_message(string.format("Command not exists: %s", d), 5) return
                end
            end

            firstOpened = false
        end

        input.init()

        local filename       = mp.get_property("filename")
        titleProperties      = subtitle:properties(h.removeExt(filename))
        titleProperties.name = filename

        if search.text == "" then

            local searched = cleanTitle()

            if titleProperties.episode and not titleProperties.season then titleProperties.season = 1 end

            if titleProperties.year            then searched = searched.." "..titleProperties.year               end
            if titleProperties.season          then searched = searched.." s:"..titleProperties.season           end
            if titleProperties.episode         then searched = searched.." e:"..titleProperties.episode          end
            if config.preferred_language ~= "" then searched = searched.." language:"..config.preferred_language end

            search.text = searched
        end

        input.font_size    = config.text_size
        input.cursor_theme = config.cursor_color

        input.default(search.text)

        submit()
        --fillData()
        render()
        setBindings()

    else

        unsetBindings()
        panel:remove()

        input.reset()
        reset()
        collectgarbage()
    end

    togglePlayerControllers()

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
            end,
            opts = nil
        },

        confirm = {

            key  = "enter",
            func = function ()

                if data.resultCount > 0 then

                    downloadFile()
                    toggle()
                end
            end,
            opts = nil
        },

        download = {

            key  = "mbtn_left",
            func = function ()

                local isMouseOverRow = setCurrentIndex()

                if isMouseOverRow then downloadFile() end

                toggle()
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

mp.register_event("file-loaded", function()

    search.text = ""
end)

mp.add_key_binding("Ctrl+f", "subfinder", toggle)