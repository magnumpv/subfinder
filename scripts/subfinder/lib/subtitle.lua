local h        = require "lib/helper"
local subtitle = {}

function subtitle:getEpisodeNumber(title)

    return
       string.match(title, "s0*%d+[%s%.%-]*e0*(%d+)")
    or string.match(title, "%-[%s_]0*(%d+)")
    or string.match(title, "0*%d+%s*x%s*0*(%d+)")
    or string.match(title:gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", ""), "[%.%s]0*(%d+)$")
end

function subtitle:properties(title)

    local platformMap = {

        netflix = "nf",
        disney  = "dsnp",
        amazon  = "amzn",
        blutv   = "blutv",
        apple   = "atvp,atv,it"
    }
    local spaces      = "[%.%s%-_%[%]%(%)]"
    local t           = {}
    title             = title:lower()

    --quality

    if
       string.find(title, "blu[%s%-_]*ray")
    or string.find(title, "b[dr][%s%-_]*rip")
    or string.find(title, "remaster")
    or string.find(title, "extended")
    or string.find(title.." ", spaces.."bd"..spaces)
    then

        t.quality = "bd"
    elseif string.find(title, "web[%s%-_]*dl") or string.find(title, "web[%s%-_]*rip") or string.find(title, spaces.."web"..spaces) then

        t.quality = "web"
    elseif string.find(title, "dvd") then

        t.quality = "dvd"
    end

    --season

    t.season = string.match(title, "s0*(%d+)[%s%.%-]*e") or string.match(title, "0*(%d+)%s*x%s*0?%d+")

    --episode

    t.episode = self:getEpisodeNumber(title)

    --version

    t.version = string.match(title, "%-([a-zA-Z0-9]-)$") or string.match(title, "^%[([^%]]-)%]") or string.match(title, "%[([^%]]-)%]$")

    if t.version and (tonumber(t.version) or string.len(t.version) > 25) then t.version = nil end

    --platform

    for platform, value in pairs(platformMap) do

        value = h.splitString(value)

        for _, variant in pairs(value) do

            if string.find(title.." ", spaces..variant..spaces) then t.platform = platform break end
        end
    end

    --year

    local yearList = {}

    for y in string.gmatch(title:gsub("%d%d%d%d%s*[pix]", ""), "(%d%d%d%d)") do  --progressive, interlaced, 1920x1080

        y = tonumber(y)

        if y > 1900 and y < 2100 then table.insert(yearList, y) end
    end

    t.year = yearList[2] or yearList[1]

    return t
end

function subtitle:formatK(number)

    if not number then return nil end

    number = tostring(number)
    number = string.gsub(number, "[^%d]+", "")
    number = tonumber(number)

    if not number then return nil end

    return number >= 1000 and math.floor(number / 1000).."K" or number
end

function subtitle:newLine(t)

    local info = {}

    for k, v in pairs(t) do info[k] = v end

    info.downloads = self:formatK(t.downloads)

    if info.date then

        if info.date.d and info.date.m and info.date.y then

            info.date = config.date_format:gsub("<mm>", info.date.m):gsub("<dd>", info.date.d):gsub("<yyyy>", info.date.y)
        else

            info.date = info.date
        end
    end

    local p = self:properties(info.title)

    for k, v in pairs(p) do info[k] = info[k] or v end

    return info
end

return subtitle