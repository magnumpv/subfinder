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
    },
    languageMap = {

        spanish    = "Spanish Latin America,Spanish Spain",
        french     = "French Canada,French France",
        portuguese = "Brazilian Portuguese",
        chinese    = "Chinese Cantonese,Chinese Simplified,Chinese Traditional,Chinese BG Code,Chinese Bilingual"
    },
    regionMap = {

        spanish_latin_america = "latinamerica",
        spanish_spain         = "spain",
        chinese_cantonese     = "cantonese",
        chinese_simplified    = "simplified",
        chinese_traditional   = "traditional",
        chinese_bg_code       = "bgcode",
        chinese_bilingual     = "bilingual",
        french_canada         = "canada",
        french_france         = "france",
        brazilian_portuguese  = "brazilian"
    },
    limit = 100
})

function site:getPage()

    local content
    local language = self:extendLanguage(languages[query.tags.language])
    local isSeries = self:isSeries()

    --imdb id search

    if query.imdbId then

        self.searchMode = "imdb"

        content = request:timeout(10):headers({["X-API-Key"] = config.api_subsource}):sendRequest(self.url.api.."/movies/search", {

            searchType = "imdb",
            imdb       = query.imdbId,
            season     = query.tags.s
        })
    end

    --title search (with year)

    if not (content and content.data and content.data[1] and content.data[1].movieId) then

        self.searchMode = "title"

        content = request:timeout(10):headers({["X-API-Key"] = config.api_subsource}):sendRequest(self.url.api.."/movies/search", {

            searchType = "text",
            q          = query.title,
            year       = query.year,
            season     = query.tags.s,
            type       = isSeries and "series" or "movie"
        })

        if not (content and content.data and content.data[1] and content.data[1].movieId and content.data) then return nil end
    end

    content = request:timeout(10):headers({["X-API-Key"] = config.api_subsource}):sendRequest(self.url.api.."/subtitles", {

        movieId  = content.data[1].movieId,
        language = language,
        limit    = self.limit,
        page     = query.tags.page
    })

    if not (content.data and content.data[1]) then return nil end

    return content.data
end

function site:parse(content)

    local isSeries      = self:isSeries()
    local qualityMap    = {web = "web", bluray = "bd"}
    local rows          = {}
    local dateConverter = function(raw)

        local year, month, day = string.match(raw, "(%d+)%-(%d+)%-(%d+)")

        return year and {d = day, m = month, y = year} or nil
    end

    for _, row in ipairs(content) do

        local passed = true

        if config.block_ai and row.productionType and row.productionType == "machine" then

            msg.warn(string.format("[%s] Subtitle skipped. Reason: %s", self.name, "ai translate"))
            h.log(row)

            passed = false
        end

        if passed and not self:filter(row, isSeries) then

            msg.warn(string.format("[%s] Subtitle skipped. Reason: %s", self.name, "episode"))
            h.log(row)

            passed = false
        end

        if passed then

            table.insert(rows, subtitle:newLine({

                id           = row.subtitleId,
                title        = (row.releaseInfo and row.releaseInfo[1]) and row.releaseInfo[1] or nil,
                pageLink     = row.link,
                downloadLink = row.subtitleId and string.format("/subtitles/%s/download", row.subtitleId) or nil,
                uploader     = self:getUploaderName(row),
                bulk         = (row.files and row.files > 1),
                downloads    = row.downloads,
                hi           = row.hearingImpaired or self:isHi(row.commentary),
                foreign      = row.foreignParts,
                region       = self:getRegion(row.language),
                forced       = self:isForced(h.joinStrings(row.commentary, (row.releaseInfo and row.releaseInfo[1]) and table.concat(row.releaseInfo, " ") or nil)),
                quality      = qualityMap[row.releaseType],
                sameversion  = self:isSameVersion(row.releaseInfo),
                date         = (row.createdAt) and dateConverter(row.createdAt) or nil,
                ai           = row.productionType and row.productionType == "machine"
            }))
        end
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

    request:timeout(15):headers({["X-API-Key"] = config.api_subsource}):download(savePath):sendRequest(link)
end

function site:getUploaderName(t)

    if not (t.contributors and t.contributors[1]) then return nil end

    for _, c in pairs(t.contributors) do if c.id == t.uploaderId then return c.displayname end end

    return nil
end

function site:filter(t, isSeries)

    if isSeries and query.tags.e and t.releaseInfo and t.releaseInfo[1] then

        local episodeNumbers = subtitle:getEpisodeRange(t.releaseInfo[1])

        if not episodeNumbers                                                                          then return true  end
        if not (query.tags.e >= episodeNumbers.from and query.tags.e <= episodeNumbers.to) then return false end
    end

    return true
end

return site