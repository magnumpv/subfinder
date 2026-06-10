local h       = require "lib/helper"
local path    = require "lib/path"
local utils   = require "mp.utils"
local request = require "lib/request"
local msg     = require "mp.msg"
local this    = {name = "unknown", url = "", languageMap = {}, regionMap = {}, sameVersionAllKeyword = nil, searchMode = ""}
this.__index  = this

function this:new(conf)

    setmetatable(conf, self)

    return conf
end

function this:findSubtitles()

    local content = self:getPage()

    if not content then

        msg.error(string.format("[%s] Page not found!", self.name))

        return nil
    end

    local result = self:parse(content)

    msg.info(string.format("[%s] Found %s subtitle(s)", self.name, #result))

    return result, self.searchMode
end

function this:findImdbId()

    local isSeries = this:isSeries()
    local content

    content = request:timeout(10):sendRequest("https://api.themoviedb.org/3/search/"..(isSeries and "tv" or "movie"), {api_key = app.api_tmdb, query = query.title, primary_release_year = query.year})

    if not (content and content.results and content.results[1]) then msg.warn("[findimdbid] TMDB page not found.") return nil end

    local k            = 1
    local getDateValue = function(row) return row.release_date or row.first_air_date end

    for i = 1, #content.results do

        if query.year then

            if getDateValue(content.results[i]) and getDateValue(content.results[i]):match("%d%d%d%d") == tostring(query.year) then

                k = i break
            end
        else

            k = i break
        end
    end

    content = request:timeout(10):sendRequest(string.format("https://api.themoviedb.org/3/%s/%s", (isSeries and "tv" or "movie"), content.results[k].id), {api_key = app.api_tmdb, append_to_response = "external_ids"})

    if not (content and content.external_ids and content.external_ids.imdb_id) then msg.warn("[findimdbid] TMDB page does not contain an IMDb ID.") return nil end

    msg.info(string.format("IMDb page found: https://www.imdb.com/title/%s", content.external_ids.imdb_id))

    return content.external_ids.imdb_id
end

function this:extendLanguage(language)

    language = h.slugify(language)

    return self.languageMap[language] and h.slugify(language..","..self.languageMap[language]) or language
end

function this:getRegion(language)

    language = h.slugify(language)

    return self.regionMap[language]
end

function this:isForced(str)

    if not str then return nil end

    str = str:lower()

    return str:find("forced") and true or nil
end

function this:isHi(str)

    if not str then return nil end

    str = " "..str:lower().." "

    for _, w in pairs({"non?[%s%-]*hearing", "non?[%s%-]*hi", "non?[%s%-]*sdh", "hi removed", "sdh removed", "removed hearing"}) do

        if str:find("[^a-z]"..w.."[^a-z]") then return false end
    end

    for _, w in pairs({"sdh", "hi", "hearing", "cc"}) do

        if str:find("[^a-z]"..w.."[^a-z]") then return true end
    end

    return false
end

function this:isSameVersion(releases)

    if not (releases and titleProperties.version) then return nil end

    if type(releases) == "table" then

        for _, release in ipairs(releases) do

            if type(release) == "string" and string.find(release:lower(), titleProperties.version) then return true end
        end

        return nil
    end

    releases = releases:lower()

    if string.find(releases, titleProperties.version) or (self.sameVersionAllKeyword and string.find(releases, self.sameVersionAllKeyword)) then return true end

    return nil
end

function this:isSeries()

    return query.tags and query.tags.s
end

return this