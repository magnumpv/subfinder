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
    },
    languageMap = {

        fr = "FR_CA",
        pt = "BR_PT",
        sr = "SR_CYRL",
        zh = "ZH_BG"
    },
    regionMap = {

        fr_ca   = "canada",
        br_pt   = "brazilian",
        sr_cyrl = "cyrillic",
        zh_bg   = "bgcode"
    },
    limit = 30
})

function site:getPage(queryParams)

    local content
    local language = self:extendLanguage(queryParams.tags.language)
    local isSeries = self:isSeries(queryParams)

    --imdb id search

    if queryParams.imdbId then

        content = request:timeout(10):sendRequest(self.url.api.."/subtitles", {

            api_key        = config.api_subdl,
            imdb_id        = queryParams.imdbId,
            languages      = language,
            releases       = 1,
            season_number  = queryParams.tags.s,
            episode_number = queryParams.tags.e,
            subs_per_page  = 30,
            comment        = 1,
            page           = queryParams.tags.page
        })
    end

    --title search (with year)

    if not (content and content.subtitles and content.subtitles[1]) then

        content = request:timeout(10):sendRequest(self.url.api.."/subtitles", {

            api_key        = config.api_subdl,
            film_name      = queryParams.title,
            year           = queryParams.year,
            languages      = language,
            releases       = 1,
            season_number  = queryParams.tags.s,
            episode_number = queryParams.tags.e,
            subs_per_page  = self.limit,
            comment        = 1,
            type           = isSeries and "tv" or "movie",
            page           = queryParams.tags.page
        })
    end

    if not (content and content.subtitles and content.subtitles[1]) then return nil end

    return content.subtitles
end

function site:parse(content, queryParams)

    local isSeries = self:isSeries(queryParams)
    local rows     = {}

    for _, row in ipairs(content) do

        local passed = true

        if not self:filter(row, queryParams, isSeries) then

            msg.warn(string.format("[%s] Subtitle skipped. Reason: %s", self.name, "episode"))
            h.log(row)

            passed = false
        end

        if passed then

            table.insert(rows, subtitle:newLine({

                title        = row.release_name,
                pageLink     = row.subtitlePage,
                downloadLink = row.url,
                uploader     = row.author,
                bulk         = row.full_season,
                region       = self:getRegion(row.language),
                forced       = self:isForced(h.joinStrings(row.comment, row.release_name)),
                hi           = row.hi or self:isHi(h.joinStrings(row.comment, row.release_name)),
                releases     = row.releases
            }))
        end
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

    request:timeout(15):download(savePath):sendRequest(link, {api_key = config.api_subdl})
end

function site:filter(t, queryParams, isSeries)

    if isSeries and queryParams.tags and queryParams.tags.e and t.release_name and (t.full_season and t.full_season == false) then

        local episodeNumbers = subtitle:getEpisodeRange(t.release_name)

        if not episodeNumbers                                                                          then return true  end
        if not (queryParams.tags.e >= episodeNumbers.from and queryParams.tags.e <= episodeNumbers.to) then return false end
    end

    return true
end

return site