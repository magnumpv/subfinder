local msg      = require "mp.msg"
local utils    = require "mp.utils"
local h        = require "lib/helper"
local base     = require "lib/base"
local subtitle = require "lib/subtitle"
local request  = require "lib/request"
local path     = require "lib/path"
local site     = base:new({

    name = "opensubtitles",
    url  = {

        api  = "https://api.opensubtitles.com/api/v1",
        site = "https://www.opensubtitles.com"
    },
    languageMap = {

        az = "az-az,az-zb",
        pt = "pt-pt,pt-br",
        zh = "zh-ca,zh-cn,zh-tw,ze",
        es = "sp,ea"
    },
    regionMap = {

        ["pt-br"] = "brazilian",
        ["az-zb"] = "south",
        ["zh-ca"] = "cantonese",
        ["zh-tw"] = "traditional",
        ["zh-cn"] = "simplified",
        ["ze"]    = "bilingual",
        ["ea"]    = "latinamerica",
        ["sp"]    = "spain"
    }
})

function site:getPage(queryParams)

    local content
    local language = self:extendLanguage(queryParams.tags.language)
    local isSeries = self:isSeries(queryParams)

    --imdb id search

    if queryParams.imdbId then

        content = request:timeout(10):userAgent(string.format("%s v%s", app.name, app.version)):headers({["Api-Key"] = app.api_opensubtitles, ["Accept"] = "application/json"}):sendRequest(self.url.api.."/subtitles", {

            season_number   = queryParams.tags.s,
            episode_number  = queryParams.tags.e,
            imdb_id         = isSeries and nil or queryParams.imdbId:gsub("tt0*", ""),
            parent_imdb_id  = isSeries and queryParams.imdbId:gsub("tt0*", "") or nil,
            languages       = language,
            ai_translated   = config.block_ai and "exclude" or nil,
            order_by        = "upload_date",
            order_direction = "desc"
        })
    end

    --title search (with year)

    if not (content and content.data and content.data[1]) then

        content = request:timeout(10):userAgent(string.format("%s v%s", app.name, app.version)):headers({["Api-Key"] = app.api_opensubtitles, ["Accept"] = "application/json"}):sendRequest(self.url.api.."/subtitles", {

            query           = queryParams.title:lower(),
            type            = isSeries and "episode" or "movie",
            season_number   = queryParams.tags.s,
            episode_number  = queryParams.tags.e,
            year            = queryParams.year,
            languages       = language,
            ai_translated   = config.block_ai and "exclude" or nil,
            order_by        = "upload_date",
            order_direction = "desc"
        })
    end

    if not (content and content.data and content.data[1]) then return nil end

    return content.data
end

function site:parse(content, queryParams)

    local isSeries      = self:isSeries(queryParams)
    local rows          = {}
    local dateConverter = function(raw)

        local year, month, day = string.match(raw, "(%d+)%-(%d+)%-(%d+)")

        return year and {d = day, m = month, y = year} or nil
    end

    for _, row in ipairs(content) do

        if row.attributes then

            table.insert(rows, subtitle:newLine({

                id           = row.id,
                title        = row.attributes.release,
                pageLink     = row.attributes.url and row.attributes.url:gsub("https://www.opensubtitles.com", "") or nil,
                downloadLink = (row.attributes.files and row.attributes.files[1]) and row.attributes.files[1].file_id or nil,
                uploader     = (row.attributes.uploader and row.attributes.uploader.name) and row.attributes.uploader.name or nil,
                downloads    = row.attributes.download_count,
                hi           = row.attributes.hearing_impaired,
                forced       = row.attributes.foreign_parts_only,
                region       = self:getRegion(row.attributes.language),
                ai           = row.attributes.machine_translated or row.attributes.ai_translated,
                date         = (row.attributes.upload_date) and dateConverter(row.attributes.upload_date) or nil
            }))
        end
    end

    return rows
end

function site:download(link, savePath)

    if not link then msg.error("Link not found!") return end

    if tonumber(link) then --from api

        link = self:getDownloadLink(link)
    else

        msg.error("Invalid link!") return
    end

    if not link then msg.error("Link not found or quota exceeded!") return end

    request:timeout(15):headers({["Api-Key"] = app.api_opensubtitles, ["Accept"] = "application/json"}):download(savePath):sendRequest(link)
end

function site:getUserToken()

    local content = request
    :timeout(10)
    :headers({

        ["Api-Key"]    = app.api_opensubtitles,
        ["Accept"]     = "application/json",
        ["User-Agent"] = string.format("%s v%s", app.name, app.version)
    })
    :postData({

        username = self:username(),
        password = self:password()
    })
    :sendRequest(self.url.api.."/login")

    if not (content and content.status and content.status == 200 and content.token) then return nil, (content and content.status) and content.status or 400 end

    return content.token, 200
end

function site:getDownloadLink(id)

    local content, token, status
    local file       = path.join({"%temp", "mpvsubfinder", "os_cache.json"})
    local refreshKey = self:username().."-"..self:password():len().."-"..os.date("!%Y%m%d")

    --load token

    if self:username() then

        if path.checkPath(file) then

            local cache = path.readFile(file)
            cache       = utils.parse_json(cache)
            token       = (cache.key == refreshKey) and cache.token or nil
        end

        if not token then

            token, status = self:getUserToken()

            if status ~= 200 then msg.error(string.format("[%s] Failed to retrieve auth token. Status code: %s", self.name, status)) return end

            path.createFile(file, utils.format_json({token = token, key = refreshKey}))
        end
    end

    content = request
    :timeout(10)
    :headers({

        ["Authorization"] = token and "Bearer "..token or nil,
        ["Api-Key"]       = app.api_opensubtitles,
        ["Accept"]        = "application/json"
    })
    :postData({

        file_id = id
    })
    :sendRequest(self.url.api.."/download")

    if not (content and content.link) then msg.error(string.format("%s API failed: %s", self.name, utils.format_json(content))) return end

    return content.link
end

function site:username()

    return config.credentials_opensubtitles:match("([^:]+):[^:]+")
end

function site:password()

    return config.credentials_opensubtitles:match("[^:]+:([^:]+)")
end

return site