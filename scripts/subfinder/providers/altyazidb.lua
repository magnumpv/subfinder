local msg      = require "mp.msg"
local h        = require "lib/helper"
local subtitle = require "lib/subtitle"
local utils    = require "mp.utils"
local base     = require "lib/base"
local request  = require "lib/request"
local site     = base:new({

    name = "altyazidb",
    url  = {api = "https://altyazidb.com/api/v1", site = "https://altyazidb.com"}
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

        content = request:timeout(15):headers({["X-API-Key"] = config.api_altyazidb}):sendRequest(self.url.api.."/search", {imdb_id = queryParams.imdbId, lang = queryParams.tags.language, season = queryParams.tags.s, episode = queryParams.tags.e})
    end

    if not (content and content.data and content.data[1]) then

        return nil
    end

    return content.data
end

function site:parse(content, queryParams)

    local rows = {}

    for _, row in ipairs(content) do

        table.insert(rows, subtitle:new({

            id           = row.id,
            title        = (row.releases and row.releases[1]) and row.releases[1] or row.translator,
            downloadLink = row.id and self.url.api.."/download" or nil,
            uploader     = row.uploader,
            downloads    = row.downloads,
            hi           = row.hearing_impaired,
            releases     = row.translator_note,
            provider     = self
        }))
    end

    return rows
end

function site:download(subtitle, savePath)

    if self.name ~= subtitle.provider.name then

        msg.error("This subtitle belongs to a different provider!") return
    end

    if not subtitle.downloadLink then

        msg.error("Subtitle link not found!") return
    end

    request:timeout(30):headers({["X-API-Key"] = config.api_altyazidb}):download(savePath):sendRequest(subtitle.downloadLink, {sub_id = subtitle.id})
end

return site