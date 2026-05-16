local h       = require "lib/helper"
local path    = require "lib/path"
local utils   = require "mp.utils"
local request = require "lib/request"
local msg     = require "mp.msg"
local this    = {name = "unknown", url = "", hash = nil}
this.__index  = this

local tmdpApiKey = "108862d1305e0848f2a0874ca1bf5098"

function this:new(conf)

    setmetatable(conf, self)

    return conf
end

function this:findSubtitles(queryParams)

    local content = self:getPage(queryParams)

    if not content then

        msg.error(string.format("[%s] Page not found!", self.name))

        return nil
    end

    local result = self:parse(content, queryParams)

    msg.info(string.format("[%s] Found %s subtitle(s)", self.name, #result))

    return result
end

function this:findImdbId(queryParams)

    local content

    content = request:timeout(15):sendRequest("https://api.themoviedb.org/3/search/multi", {api_key = tmdpApiKey, query = queryParams.title, primary_release_year = queryParams.year})

    if not (content and content.results and content.results[1]) then return nil end

    --filter (tt0412142)

    local isSeries      = (queryParams.tags and queryParams.tags.s and queryParams.tags.e)
    local k             = 1
    local findDateField = function(row)

        return row.release_date or row.first_air_date
    end

    for i = 1, #content.results do

        local passed = false

        if isSeries then

            if content.results[i].media_type == "tv" then

                passed = true
            end
        else

            passed = true
        end

        if passed then

            if queryParams.year and findDateField(content.results[i]) and findDateField(content.results[i]):match("%d%d%d%d") == tostring(queryParams.year) then

                passed = true
            else

                passed = false
            end
        end

        if passed then k = i break end
    end

    if not (content.results[k].media_type and content.results[k].media_type == "tv" or content.results[k].media_type == "movie") then return nil end

    content = request:timeout(15):sendRequest(string.format("https://api.themoviedb.org/3/%s/%s", content.results[k].media_type, content.results[k].id), {api_key = tmdpApiKey, append_to_response = "external_ids"})

    if not (content and content.external_ids and content.external_ids.imdb_id) then return nil end

    msg.info(string.format("IMDb ID found: %s", content.external_ids.imdb_id))

    return content.external_ids.imdb_id
end

return this