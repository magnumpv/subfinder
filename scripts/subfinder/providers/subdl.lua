local msg      = require "mp.msg"
local h        = require "lib/helper"
local utils    = require "mp.utils"
local base     = require "lib/base"
local subtitle = require "lib/subtitle"
local request  = require "lib/request"
local site     = base:new({

    name = "subdl",
    url  = {

        api  = "https://api.subdl.com/api/v1",
        site = "https://subdl.com"
    }
})

function site:getPage(queryParams)

    local content

    --imdb id search

    if queryParams.imdbId then

        content = request:timeout(15):sendRequest(self.url.api.."/subtitles", {api_key = config.api_subdl, imdb_id = queryParams.imdbId, languages = queryParams.tags.language, releases = "1", season_number = queryParams.tags.s, episode_number = queryParams.tags.e, subs_per_page = 30})
    end

    --title search (with year)

    if not (content and content.subtitles and content.subtitles[1]) then

        content = request:timeout(15):sendRequest(self.url.api.."/subtitles", {api_key = config.api_subdl, film_name = queryParams.title, year = queryParams.year, languages = queryParams.tags.language, releases = "1", season_number = queryParams.tags.s, episode_number = queryParams.tags.e, subs_per_page = 30})
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

        table.insert(rows, subtitle:newLine({

            title        = row.release_name,
            pageLink     = row.subtitlePage,
            downloadLink = row.url,
            uploader     = row.author,
            bulk         = row.full_season,
            hi           = row.hi,
            releases     = row.releases
        }))
    end

    return rows
end

function site:download(link, savePath)

    if not link then msg.error("Link not found!") return end

    if string.find(link, "^/subtitle/%d+%-%d+%.zip$") then --from api

        link = self.url.site:gsub("//", "//dl.")..link
    elseif string.find(link, "^https://subdl%.com/s/info/[^/]*/[^/]*$") then --from link

        msg.error("This feature is not supported by the site.") return
    else

        msg.error("Invalid link!") return
    end

    request:timeout(30):download(savePath):sendRequest(link, {api_key = config.api_subdl})
end

return site