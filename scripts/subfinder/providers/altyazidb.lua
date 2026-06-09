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

function site:getPage(queryParams)

    local languageMap = {

        tr = true,
        en = true
    }

    if not languageMap[queryParams.tags.language] then return nil end

    local content

    --imdb id search

    if queryParams.imdbId then

        content = request:timeout(10):headers({["X-API-Key"] = config.api_altyazidb}):sendRequest(self.url.api.."/search", {

            imdb_id = queryParams.imdbId,
            lang    = queryParams.tags.language,
            season  = queryParams.tags.s,
            episode = queryParams.tags.e,
            page    = queryParams.page
        })
    end

    --title search

    if not (content and content.data and content.data[1]) then

        content = request:timeout(10):headers({["X-API-Key"] = config.api_altyazidb}):sendRequest(self.url.api.."/search", {

            title   = queryParams.title,
            year    = queryParams.year,
            lang    = queryParams.tags.language,
            season  = queryParams.tags.s,
            episode = queryParams.tags.e,
            page    = queryParams.page
        })
    end

    if not (content and content.data and content.data[1]) then return nil end

    return content.data
end

function site:parse(content, queryParams)

    local rows = {}

    for _, row in ipairs(content) do

        local passed = true

        if config.block_ai and row.ai_ceviri and row.ai_ceviri == 1 then

            msg.warn(string.format("[%s] Subtitle skipped. Reason: %s", self.name, "ai translate"))
            h.log(row)

            passed = false
        end

        if passed then

            h.log2(row)

            table.insert(rows, subtitle:newLine({

                id           = row.id,
                title        = (row.releases and row.releases[1]) and row.releases[1] or row.translator,
                downloadLink = row.download_url and row.download_url:gsub(".+(/download)", "%1") or nil,
                uploader     = row.uploader,
                downloads    = row.downloads,
                forced       = row.forced and row.forced == 1,
                foreign      = row.foreign_parts and row.foreign_parts == 1,
                hi           = row.hearing_impaired and row.hearing_impaired == 1,
                sameversion  = self:isSameVersion(row.releases)
            }))
        end
    end

    return rows
end

function site:download(link, savePath)

    if not link then msg.error("Link not found!") return end

    if string.find(link, "^/download%?sub_id=%d+$") then --from api

        link = self.url.api..link
    else

        msg.error("Invalid link!") return
    end

    request:timeout(15):headers({["X-API-Key"] = config.api_altyazidb}):download(savePath):sendRequest(link)
end

return site