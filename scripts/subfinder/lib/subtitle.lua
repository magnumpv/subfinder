local h        = require "lib/helper"
local subtitle = {

    spaces         = "%s%.%-_",
    brackets       = "%[%]%(%)",
    rangeSeparator = "%-%~"
}

function subtitle:prepareTitle(title)

    title = title:lower()
    title = title:gsub("%d%d%d%dx%d+p?", "") --1920x1080, 1280x720
    title = title:gsub("%d%d%d%d["..self.spaces.."]x["..self.spaces.."]%d+p?", "") --1920 x 1080, 1280 x 720
    title = title:gsub("["..self.spaces.."]x%d%d%d", "") --x264, x265
    title = title:gsub("[257]%.[01]", "")

    return title
end

function subtitle:getEpisodeNumber(title)

    title = self:prepareTitle(title)
    title = title:gsub("19%d%d", ""):gsub("20%d%d", "")
    title = title:gsub("season %d+", "")

    return tonumber(
       string.match(title, "s0*%d+["..self.spaces.."]*e0*(%d+)") --> s1e3
    or string.match(title, "%-["..self.spaces.."]0*(%d+)") --> - 03
    or string.match(title, "0*%d+["..self.spaces.."]*x["..self.spaces.."]*0*(%d+)") --> 1x3
    or string.match(title, "["..self.spaces.."]ep?["..self.spaces.."]*0*(%d+)") --> ep3 | e3
    or string.match(title, "episode["..self.spaces.."]0*(%d+)") --> episode 3
    or string.match(title, "["..self.brackets.."]0*(%d+)["..self.brackets.."]") --> [3]
    or string.match(title, "["..self.spaces.."]*ova["..self.spaces.."]*0*(%d+)") --> ova3
    or string.match(title, "#0*(%d+)") --> #3

    --last resort
    or string.match(" "..title, "["..self.spaces.."]0*(%d+)["..self.spaces.."]%-["..self.spaces.."]") --> 03 -
    or string.match(title:gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", ""), "["..self.spaces.."]%d(%d+)%s*$")) --> 3$
end

function subtitle:getEpisodeRange(title)

    local episodes = {title:match("0*(%d+)["..self.spaces.."]*["..self.rangeSeparator.."]["..self.spaces.."]*[eE]?0*(%d+)")}

    if #episodes > 0 then return {from = tonumber(episodes[1]), to = tonumber(episodes[2])} end

    local episode = self:getEpisodeNumber(title)

    if episode then return {from = episode, to = episode} end

    return nil
end

function subtitle:getSeasonNumber(title)

    title = self:prepareTitle(title)

    return
       string.match(title, "["..self.spaces.."]s0*(%d+)")
    or string.match(title, "0*(%d+)["..self.spaces.."]*x["..self.spaces.."]*0*%d+")
    or string.match(title, "season["..self.spaces.."]0*(%d+)")
end

function subtitle:properties(title)

    local platformMap = {

        netflix = "nf",
        disney  = "dsnp",
        amazon  = "amzn",
        blutv   = "blutv",
        apple   = "atvp,atv,it"
    }
    local t = {}
    title   = self:prepareTitle(title)

    --quality

    if
       string.find(title, "blu["..self.spaces.."]*ray")
    or string.find(title, "b[dr]["..self.spaces.."]*rip")
    or string.find(title, "remaster")
    or string.find(title, "extended")
    or string.find(title.." ", "["..self.spaces..self.brackets.."]".."bd".."["..self.spaces..self.brackets.."]")
    then

        t.quality = "bd"
    elseif string.find(title, "web["..self.spaces.."]*dl") or string.find(title, "web["..self.spaces.."]*rip") or string.find(title, "["..self.spaces..self.brackets.."]".."web".."["..self.spaces..self.brackets.."]") then

        t.quality = "web"
    elseif string.find(title, "dvd") then

        t.quality = "dvd"
    end

    --season

    t.season = self:getSeasonNumber(title)

    --episode

    t.episode = self:getEpisodeNumber(title)

    --version

    t.version = string.match(title, "%-([a-z0-9]-)$") or string.match(title, "^%[([^%]]-)%]") or string.match(title, "%[([^%]]-)%]$")

    if t.version and (tonumber(t.version) or string.len(t.version) > 25) then t.version = nil end

    --platform

    for platform, value in pairs(platformMap) do

        value = h.splitString(value)

        for _, variant in pairs(value) do

            if string.find(title.." ", "["..self.spaces..self.brackets.."]"..variant.."["..self.spaces..self.brackets.."]") then t.platform = platform break end
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

    local p = (info.title and info.title ~= "") and self:properties(info.title) or {}

    for k, v in pairs(p) do info[k] = info[k] or v end

    return info
end

return subtitle