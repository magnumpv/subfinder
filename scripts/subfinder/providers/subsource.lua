local msg      = require "mp.msg"
local utils    = require "mp.utils"
local h        = require "lib/helper"
local base     = require "lib/base"
local subtitle = require "lib/subtitle"
local request  = require "lib/request"
local path     = require "lib/path"
local site     = base:new({

    name = "subsource",
    url  = {

        api  = "https://api.subsource.net/api/v1",
        site = "https://subsource.net"
    }
})

function site:getPage(queryParams)

    local languageMap = {

        tr = "turkish",
        en = "english",
        fr = "french",
        it = "italian",
        es = "spanish",
        zh = "chinese",
        de = "german",
        ru = "russian",
        ja = "japanese"
    }

    if not languageMap[queryParams.tags.language] then return nil end

    local content

    --imdb id search

    if queryParams.imdbId then

        content = request:timeout(15):headers({["X-API-Key"] = config.api_subsource}):sendRequest(self.url.api.."/movies/search", {searchType = "imdb", imdb = queryParams.imdbId, season = queryParams.tags.s})
    end

    --title search (with year)

    if not (content and content.data and content.data[1] and content.data[1].movieId) then

        content = request:timeout(15):headers({["X-API-Key"] = config.api_subsource}):sendRequest(self.url.api.."/movies/search", {searchType = "text", q = queryParams.title, year = queryParams.year, season = queryParams.tags.s})
    end

    if not (content and content.data and content.data[1] and content.data[1].movieId) then

        return nil
    end

    content = request:timeout(15):headers({["X-API-Key"] = config.api_subsource}):sendRequest(self.url.api.."/subtitles", {movieId = content.data[1].movieId, language = languageMap[queryParams.tags.language], limit = 30})

    if not (content.data and content.data[1]) then return nil end

    return content.data
end

function site:parse(content, queryParams)

    local qualityMap    = {web = "web", bluray = "bd"}
    local rows          = {}
    local dateConverter = function(raw)

        local year, month, day = string.match(raw, "(%d+)%-(%d+)%-(%d+)")

        return year and {d = day, m = month, y = year} or nil
    end

    for _, row in ipairs(content) do

        table.insert(rows, subtitle:newLine({

            id           = row.subtitleId,
            title        = (row.releaseInfo and row.releaseInfo[1]) and row.releaseInfo[1] or nil,
            pageLink     = row.link,
            downloadLink = row.subtitleId and string.format("/subtitles/%s/download", row.subtitleId) or nil,
            uploader     = (row.contributors and row.contributors[1] and row.contributors[1].displayname) and row.contributors[1].displayname or nil,
            bulk         = (row.files and row.files > 1),
            downloads    = row.downloads,
            hi           = row.hearingImpaired,
            foreign      = row.foreignParts,
            quality      = qualityMap[row.releaseType],
            releases     = row.releaseInfo,
            date         = (row.createdAt) and dateConverter(row.createdAt) or nil
        }))
    end

    return rows
end

function site:download(link, savePath)

    if not link then msg.error("Link not found!") return end

    if string.find(link, "^/subtitles/%d+/download$") then --from api

        link = self.url.api..link
    elseif string.find(link, "^https://subsource%.net/subtitle/[^/]*/[^/]*/%d+$") then --from link

        local id = string.match(link, "(%d+)$")
        link     = self.url.api..string.format("/subtitles/%s/download", id)
    else

        msg.error("Invalid link!") return
    end

    request:timeout(30):headers({["X-API-Key"] = config.api_subsource}):download(savePath):sendRequest(link)
end

return site