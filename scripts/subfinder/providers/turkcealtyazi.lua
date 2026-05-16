local h        = require "lib/helper"
local base     = require "lib/base"
local subtitle = require "lib/subtitle"
local request  = require "lib/request"
local site     = base:new({

    name = "Türkçe Altyazı",
    url  = "https://turkcealtyazi.org"
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

        content = request:timeout(15):sendRequest(self.url.."/find.php", {cat = "sub", find = queryParams.imdbId})
    end

    --title search (with year)

    if not content or not (string.find(content, "\"altsonsez2") or string.find(content, "\"altsonsez1")) then

        content = request:timeout(15):sendRequest(self.url.."/filtre.php", {

            tur      = "",
            tur2     = "",
            yil      = queryParams.year,
            yil2     = queryParams.year,
            ulke     = "",
            dil      = "",
            sira     = "3",
            o        = "2",
            fragman  = "3",
            tip      = "3",
            taplimit = "0",
            taolimit = "0",
            plimit   = "0",
            olimit   = "0",
            find     = queryParams.title
        })

        local firstResult

        if content then firstResult = content:match('href="/(mov/%d+/[^"]-)"') end

        if firstResult then

            content = request:timeout(15):sendRequest(self.url.."/"..firstResult)
        end
    end

    if not content or not (string.find(content, "\"altsonsez2") or string.find(content, "\"altsonsez1")) then return nil end

    return content
end

function site:parse(content, queryParams)

    local qualityMap    = {

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
    local languageMap       = {

        tr = "flagtr",
        en = "flagen"
    }
    local isSeries      = string.find(content, '<div class="altsonsez1')
    local rows          = {}
    local dateConverter = function(raw)

        local year, month, day = string.match(raw, "(%d+)%-(%d+)%-(%d+)")

        return year and {d = day, m = month, y = year} or nil
    end

    if not languageMap[queryParams.tags.language] then return {} end

    local getSeason = function(str)

        if not str then return nil end

        return str:match("S0?(%d+)")
    end

    local getEpisode = function(str)

        if not str then return nil end

        return str:match("E0?(%d+)") or str:match("Paket")
    end

    local findValues = function(row)

        if not row:match('class="'..languageMap[queryParams.tags.language]..'"') then return nil end

        return subtitle:new({

            title     = request:stripTags(row:match('<a itemprop="url"[^>]->(.-)</a>')).." - "..request:stripTags(row:match('<div class="ripdiv">(.-)</div>')),
            link      = row:match('href="(/sub/[^"]*)"'),
            uploader  = request:stripTags(row:match('<div class="algonderen">(.-)</div>')),
            downloads = row:match('<div class="alindirme">(.-)</div>'),
            date      = row:match('<div class="datediv">(.-)</div>'),
            quality   = qualityMap[row:match('<div class="ripdiv">%s*<span class="([^"]-)">')] or qualityMap[row:match('<div class="alcevirmen">%s*<span class="([^"]-)">')],
            hi        = row:match("/images/isitme.png") and true or false,
            season    = getSeason(request:stripTags(row:match('<div class="alcd">(.-)</div>'))),
            episode   = getEpisode(request:stripTags(row:match('<div class="alcd">(.-)</div>'))),
            provider  = self
        })
    end

    if isSeries then

        for row in content:gmatch('<div class="altsonsez1[^"]*sezon_'..queryParams.tags.s..'[^"]*"[^>]->(.-<div class="ta%-container">.-</div>%s*</div>)') do

            local values = findValues(row)

            if values and queryParams.tags.e and values.episode and (tostring(queryParams.tags.e) == tostring(values.episode) or tostring(values.episode) == "Paket") then

                values.title = string.format("(S:%s-B:%s) %s", values.season, values.episode, values.title)

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

function site:download(subtitle, savePath)

    if self.name ~= subtitle.provider.name then

        msg.error("This subtitle belongs to a different provider!") return
    end

    if not subtitle.link then

        msg.error("Subtitle link not found!") return
    end

    local subtitlePageContent = request:timeout(15):sendRequest(self.url..subtitle.link)

    if not subtitlePageContent then return end

    local form = {}

    form.idid  = subtitlePageContent:match('<input type="hidden" name="idid" value="(%d+)"[^>]*>')
    form.altid = subtitlePageContent:match('<input type="hidden" name="altid" value="(%d+)"[^>]*>')
    form.sidid = subtitlePageContent:match('<input type="hidden" name="sidid" value="([^"]-)"[^>]*>')

    if not (form.idid and form.altid and form.sidid) then return end

    request:timeout(30):postData(form):download(savePath):sendRequest(self.url.."/ind")
end

return site