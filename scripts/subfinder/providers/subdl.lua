local h        = require "lib/helper"
local utils    = require "mp.utils"
local base     = require "lib/base"
local subtitle = require "lib/subtitle"
local request  = require "lib/request"
local site     = base:new({

    name = "SubdL",
    url  = {"https://api.subdl.com/api/v1", "https://dl.subdl.com"},
})

function site:getPage(queryParams)

    local content

    --imdb id search

    if queryParams.imdbId then

        content = request:timeout(15):sendRequest(self.url[1].."/subtitles", {api_key = config.api_subdl, imdb_id = queryParams.imdbId, languages = queryParams.tags.language, releases = "1", season_number = queryParams.tags.s, episode_number = queryParams.tags.e})
    end

    --title search (with year)

    if not (content and content.subtitles and content.subtitles[1]) then

        content = request:timeout(15):sendRequest(self.url[1].."/subtitles", {api_key = config.api_subdl, film_name = queryParams.title, year = queryParams.year, languages = queryParams.tags.language, releases = "1", season_number = queryParams.tags.s, episode_number = queryParams.tags.e})
    end

    if not (content and content.subtitles and content.subtitles[1]) then

        return nil
    end

    return content.subtitles
end

function site:parse(content, queryParams)

    local rows          = {}
    local dateConverter = function(raw)

        local year, month, day = string.match(raw, "(%d+)%-(%d+)%-(%d+)")

        return year and {d = day, m = month, y = year} or nil
    end

    for _, row in ipairs(content) do

        table.insert(rows, subtitle:new({

            title    = row.release_name,
            link     = row.url,
            uploader = row.author,
            bulk     = row.full_season,
            hi       = row.hi,
            releases = row.releases,
            provider  = self
        }))
    end

    return rows
end

function site:download(subtitle, savePath)

    if self.name ~= subtitle.provider.name then

        msg.error("This subtitle belongs to a different provider!") return
    end

    if not subtitle.link then

        msg.error("Subtitle link not found!") return
    end

    request:timeout(30):download(savePath):sendRequest(self.url[2]..subtitle.link)
end

return site