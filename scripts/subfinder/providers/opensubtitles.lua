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
    },
    hash = nil
})

function site:getPage()

    self.hash = self:moviehash()

    local content
    local language = self:extendLanguage(query.tags.language)
    local isSeries = self:isSeries()

    --imdb id search

    if query.imdbId then

        self.searchMode = "imdb"

        content = request:timeout(10):userAgent(string.format("%s v%s", app.name, app.version)):headers({["Api-Key"] = app.api_opensubtitles, ["Accept"] = "application/json"}):sendRequest(self.url.api.."/subtitles", {

            season_number   = query.tags.s,
            episode_number  = query.tags.e,
            imdb_id         = isSeries and nil or query.imdbId:gsub("tt0*", ""),
            parent_imdb_id  = isSeries and query.imdbId:gsub("tt0*", "") or nil,
            languages       = language,
            ai_translated   = config.block_ai and "exclude" or nil,
            order_by        = "upload_date",
            order_direction = "desc",
            moviehash       = self.hash
        })
    end

    --title search (with year)

    if not (content and content.data and content.data[1]) then

        self.searchMode = "title"

        content = request:timeout(10):userAgent(string.format("%s v%s", app.name, app.version)):headers({["Api-Key"] = app.api_opensubtitles, ["Accept"] = "application/json"}):sendRequest(self.url.api.."/subtitles", {

            query           = query.title:lower(),
            type            = isSeries and "episode" or "movie",
            season_number   = query.tags.s,
            episode_number  = query.tags.e,
            year            = query.year,
            languages       = language,
            ai_translated   = config.block_ai and "exclude" or nil,
            order_by        = "upload_date",
            order_direction = "desc",
            moviehash       = self.hash
        })
    end

    if not (content and content.data and content.data[1]) then return nil end

    return content.data
end

function site:parse(content)

    local isSeries      = self:isSeries()
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
                date         = (row.attributes.upload_date) and dateConverter(row.attributes.upload_date) or nil,
                sameversion  = row.attributes.moviehash_match or self:isSameVersion(row.attributes.release)
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

--https://github.com/opensubtitles/vlsub-opensubtitles-com/blob/main/vlsubcom.lua
function site:moviehash()

    local size
    local dataStart = ""
    local dataEnd   = ""
    local chunkSize = 65536
    local file      = io.open(mp.get_property("path"), "rb")

    if not file then return nil end

    size      = chunkSize
    dataStart = file:read(chunkSize)

    if not dataStart then file:close() return nil end

    size = file:seek("end", -chunkSize)

    if not size then file:close() return nil end

    size    = size + chunkSize
    dataEnd = file:read(chunkSize)

    if not dataEnd then file:close() return nil end

    file:close()

    if not dataStart or not dataEnd or #dataStart == 0 or #dataEnd == 0 then return nil end

    local overflow
    local o , a, b, c, d, e, f, g, h
    local lo       = size
    local hi       = 0
    local hashData = dataStart..dataEnd
    local maxSize  = 4294967296

    for i = 1, #hashData, 8 do

        a, b, c, d, e, f, g, h = hashData:byte(i, i + 7)

        if not a then break end

        b = b or 0
        c = c or 0
        d = d or 0
        e = e or 0
        f = f or 0
        g = g or 0
        h = h or 0

        lo = lo + a + b * 256 + c * 65536 + d * 16777216
        hi = hi + e + f * 256 + g * 65536 + h * 16777216

        if lo > maxSize then

            overflow = math.floor(lo / maxSize)
            lo       = lo - (overflow * maxSize)
            hi       = hi + overflow
        end

        if hi > maxSize then

            overflow = math.floor(hi / maxSize)
            hi       = hi - (overflow * maxSize)
        end
    end

    return string.format("%08x%08x", hi, lo)
end

return site