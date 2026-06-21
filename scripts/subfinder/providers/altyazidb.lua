local msg      = require "mp.msg"
local h        = require "lib/helper"
local subtitle = require "lib/subtitle"
local utils    = require "mp.utils"
local base     = require "lib/base"
local request  = require "lib/request"
local site     = base:new({

    name = "altyazidb",
    url  = {

        api = "https://altyazidb.com/api/v1",
        site = "https://altyazidb.com"
    },
    limit = 100
})

function site:getPage()

    local languageMap = {

        tr = true,
        en = true
    }

    if not languageMap[query.tags.language] then return nil end

    local content

    --imdb id search

    if query.imdbId then

        self.searchMode = "imdb"

        content = request:timeout(10):headers({["X-API-Key"] = config.api_altyazidb}):sendRequest(self.url.api.."/search", {

            imdb_id = query.imdbId,
            lang    = query.tags.language,
            season  = query.tags.s,
            episode = query.tags.e,
            page    = query.page
        })
    end

    --title search

    if not (content and content.data and content.data[1]) then

        self.searchMode = "title"

        content = request:timeout(10):headers({["X-API-Key"] = config.api_altyazidb}):sendRequest(self.url.api.."/search", {

            title        = query.title,
            year         = query.year,
            lang         = query.tags.language,
            season       = query.tags.s,
            episode      = query.tags.e,
            content_type = self:isSeries() and "series" or "movie",
            page         = query.page
        })
    end

    if not (content and content.data and content.data[1]) then return nil end

    return content.data
end

function site:parse(content)

    local rows = {}

    local dateConverter = function(raw)

        local year, month, day = string.match(raw, "(%d+)%-(%d+)%-(%d+)")

        return year and {d = day, m = month, y = year} or nil
    end

    local getTitle = function(row)

        return (row.releases and row.releases[1]) and row.releases[1] or row.translator
    end

    for _, row in ipairs(content) do

        local passed = true

        if config.block_ai and row.ai_ceviri and row.ai_ceviri == 1 then

            msg.warn(string.format("[%s] Subtitle skipped. Reason: %s", self.name, "ai translate"))
            h.log(row)

            passed = false
        end

        if passed then

            table.insert(rows, subtitle:newLine({

                id           = row.id,
                title        = self:isSeries() and string.format("(S:%s-B:%s) %s", row.season, row.episode, getTitle(row)) or getTitle(row),
                pageLink     = query.imdbId and string.format("/onizleme.php?type=imdb&id=%s", query.imdbId) or nil,
                downloadLink = row.download_url and row.download_url:gsub("https://altyazidb%.com/api/v1", "") or nil,
                uploader     = row.uploader,
                downloads    = row.downloads,
                bulk         = (row.episode == "PAKET"),
                forced       = row.forced and row.forced == 1,
                foreign      = row.foreign_parts and row.foreign_parts == 1,
                hi           = row.hearing_impaired and row.hearing_impaired == 1,
                date         = row.date and dateConverter(row.date) or nil,
                sameversion  = self:isSameVersion(row.releases)
            }))
        end
    end

    return rows
end

function site:download(link, savePath)

    if not link then msg.error("Link not found!") return end

    if string.find(link, "^/subtitle%?sub_id=%d+$") then --from api

        link = self.url.api..link
    else

        msg.error("Invalid link!") return
    end

    request:timeout(15):headers({["X-API-Key"] = config.api_altyazidb}):download(savePath):sendRequest(link)
end

function site:testQuery()

    query.tags          = {}
    query.tags.language = "tr"
    query.imdbId        = "tt0117500"
end

return site