local msg      = require "mp.msg"
local h        = require "lib/helper"
local base     = require "lib/base"
local subtitle = require "lib/subtitle"
local request  = require "lib/request"
local site     = base:new({

    name = "turkcealtyazi",
    url  = {

        site = "https://turkcealtyazi.org"
    },
    sameVersionAllKeyword = "genel"
})

function site:getCategory(content)

    if string.find(content, '<div class="altsonsez2') then

        return "movie"
    elseif string.find(content, '<div class="altsonsez1') then

        return "series"
    end

    return nil
end

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

        content = request:timeout(10):sendRequest(self.url.site.."/find.php", {cat = "sub", find = query.imdbId})
    end

    --title search (with year)

    if not (content and self:getCategory(content)) then

        self.searchMode = "title"

        content = request:timeout(10):sendRequest(self.url.site.."/filtre.php", {

            tur      = "",
            tur2     = "",
            yil      = query.year,
            yil2     = query.year,
            ulke     = "",
            dil      = "",
            sira     = "3",
            o        = "2",
            fragman  = "3",
            tip      = self:isSeries() and "2" or "1",
            taplimit = "0",
            taolimit = "0",
            plimit   = "0",
            olimit   = "0",
            find     = query.title
        })

        local firstResult

        if content then firstResult = content:match('href="(/mov/%d+/[^"]-)"') end

        if not firstResult then return nil end

        content = request:timeout(10):sendRequest(self.url.site..firstResult)

        if not (content and self:getCategory(content)) then return nil end
    end

    return content
end

function site:parse(content)

    local qualityMap = {

        ["rps c1"]  = "dvd",
        ["rps r2"]  = "dvd",
        ["cps c1"]  = "dvd",
        ["rps r2"]  = "dvd",
        ["rps r3"]  = "dvd",
        ["rps r6"]  = "web",
        ["rps r7"]  = "bd",
        ["rps r8"]  = "web",
        ["rps r12"] = "bd",
        ["rip1"]    = "dvd",
        ["rip3"]    = "web",
        ["rip4"]    = "bd",
        ["rip5"]    = "bd",
        ["rip9"]    = "web"
    }

    local languageMap = {

        tr = "flagtr",
        en = "flagen"
    }

    local rows        = {}
    local currentYear = os.date("!%Y", os.time() + 3 * 60 * 60)

    local dateConverter = function(str)

        if not str then return nil end

        local year = str:match("(%d+) yıl")

        if not year then return nil end

        return {d = "01", m = "01", y = tonumber(currentYear) - tonumber(year)}
    end

    local getSeason = function(str)

        if not str then return nil end

        return str:match("S0?(%d+)")
    end

    local getEpisode = function(str)

        if not str then return nil end

        if str:match("Paket") then return {text = "Paket"} end

        local episodeStart, episodeEnd = str:match("E0*(%d+)"), str:match("E0*%d+%-0*(%d+)")

        episodeEnd = episodeEnd or episodeStart

        if not (episodeStart and episodeEnd) then return nil end

        return {text = episodeStart == episodeEnd and episodeStart or episodeStart.."-"..episodeEnd, first = tonumber(episodeStart), last = tonumber(episodeEnd)}
    end

    local getBulk = function(str)

        return str:match("Paket") and true or nil
    end

    local findValues = function(row)

        if not row:match('class="'..languageMap[query.tags.language]..'"') then return nil end

        return subtitle:newLine({

            id           = row:match('href="/sub/(%d+)/[^"]*"'),
            title        = request:htmlUnescape(request:stripTags(row:match('<a itemprop="url"[^>]->(.-)</a>'))).." - "..request:htmlUnescape(request:stripTags(row:match('<div class="ripdiv">(.-)</div>'))),
            pageLink     = row:match('href="(/sub/[^"]*)"'),
            downloadLink = row:match('href="(/sub/[^"]*)"'),
            uploader     = request:stripTags(row:match('<div class="algonderen">(.-)</div>')),
            downloads    = row:match('<div class="alindirme">(.-)</div>'),
            date         = dateConverter(row:match('<div class="datediv">(.-)</div>')),
            quality      = qualityMap[row:match('<div class="ripdiv">%s*<span class="([^"]-)">')] or qualityMap[row:match('<div class="alcevirmen">%s*<span class="([^"]-)">')],
            hi           = row:match("/images/isitme.png"),
            season       = getSeason(request:stripTags(row:match('<div class="alcd">(.-)</div>'))),
            episode      = getEpisode(request:stripTags(row:match('<div class="alcd">(.-)</div>'))),
            bulk         = getBulk(request:stripTags(row:match('<div class="alcd">(.-)</div>'))),
            sameversion  = self:isSameVersion(request:stripTags(row:match('<div class="ripdiv">(.-)</div>')))
        })
    end

    if self:isSeries() then

        for row in content:gmatch('<div class="altsonsez1[^"]*sezon_'..query.tags.s..'[^"%d]*"[^>]*>(.-<div class="ta%-container">.-</div>%s*</div>)') do

            local values = findValues(row)

            if values and values.episode and (not query.tags.e or (values.episode.text == "Paket" or query.tags.e >= values.episode.first and query.tags.e <= values.episode.last)) then

                values.title = string.format("(S:%s-B:%s) %s", values.season, values.episode.text, values.title)

                table.insert(rows, values)
            end
        end
    else

        for row in content:gmatch('<div class="altsonsez2[^>]->(.-<div class="ta%-container">.-</div>%s*</div>)') do

            table.insert(rows, findValues(row))
        end
    end

    return rows
end

function site:download(link, savePath)

    if not link then msg.error("Link not found!") return end

    if string.find(link, "^/sub/%d+/[^%.]*.html$") then --from api

        link = self.url.site..link
    elseif string.find(link, "^https://turkcealtyazi%.org/sub/%d+/[^%.]*.html$") then --from link

        --nothing to do
    else

        msg.error("Invalid link!") return
    end

    local subtitlePageContent = request:timeout(10):sendRequest(link)

    if not subtitlePageContent then msg.error("Page not found!") return end

    local form = {}

    form.idid  = subtitlePageContent:match('<input type="hidden" name="idid" value="(%d+)"[^>]*>')
    form.altid = subtitlePageContent:match('<input type="hidden" name="altid" value="(%d+)"[^>]*>')
    form.sidid = subtitlePageContent:match('<input type="hidden" name="sidid" value="([^"]-)"[^>]*>')

    if not (form.idid and form.altid and form.sidid) then msg.error("Missing form value!") return end

    request:timeout(15):postData(form):download(savePath):sendRequest(self.url.site.."/ind")
end

function site:testQuery()

    query.tags          = {}
    query.tags.language = "tr"
    query.imdbId        = "tt0117500"
end

return site