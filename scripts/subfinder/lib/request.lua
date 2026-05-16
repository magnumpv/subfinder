local h      = require "lib/helper"
local utils  = require "mp.utils"
local msg    = require "mp.msg"
local this   = {data = {}}
this.__index = this

function this:buildUrl(link, params)

    if not params or next(params) == nil then return link end

    local query = {}

    for k, v in pairs(params) do

        table.insert(query, string.format("%s=%s", k, self:urlEncode(v)))
    end

    return link.."?"..table.concat(query, "&")
end

--source: https://help.interfaceware.com/code/details/urlcode-lua
function this:urlEncode(str)

    str = tostring(str)
    str = string.gsub(str, "([^0-9a-zA-Z !'()*._~-])", function (c) return string.format("%%%02X", string.byte(c)) end)
    str = str:gsub(" ", "+")

    return str
end

function this:stripTags(str)

    if not str then return nil end

    return str:gsub("<[^>]*>", ""):gsub("%s(.-)%s", "%1"):gsub("\t", "")
end

function this:timeout(val)

    self.data.timeout = tostring(val)

    return self
end

function this:postData(val)

    self.data.postData = val

    return self
end

function this:headers(val)

    self.data.headers = val

    return self
end

function this:download(dir)

    self.data.savePath = dir

    return self
end

function this:sendRequest(link, params)

    local url  = self:buildUrl(link, params)
    local args = {}

    table.insert(args, "curl")
    table.insert(args, "-L")
    table.insert(args, "-s")
    table.insert(args, "-A")
    table.insert(args, config.useragent)

    if self.data.timeout then

        table.insert(args, "-m")
        table.insert(args, self.data.timeout)
    end

    if self.data.savePath then

        table.insert(args, "-OJ")
        table.insert(args, "--output-dir")
        table.insert(args, self.data.savePath)
    end

    if self.data.headers then

        for k, v in pairs(self.data.headers) do

            table.insert(args, "-H")
            table.insert(args, k..": "..v)
        end
    end

    if self.data.postData then

        table.insert(args, "-X")
        table.insert(args, "POST")

        for k, v in pairs(self.data.postData) do

            table.insert(args, "-d")
            table.insert(args, k.."="..v)
        end
    end

    table.insert(args, url)

    self:reset()

    msg.info(string.format("Sending request: %s", url))

    local res = mp.command_native({

        name           = 'subprocess',
        playback_only  = false,
        capture_stdout = true,
        capture_stderr = true,
        args           = args
    })

    if res.status ~= 0 then

        msg.error(string.format("Request failed: %s", utils.format_json(res)))

        return nil
    end

    return utils.parse_json(res.stdout) or res.stdout
end

function this:reset()

    for k, v in pairs(self.data) do

        if type(v) == "table" then

            for kk in pairs(v) do

                self.data[k][kk] = nil
            end

            self.data[k] = nil
        else

            self.data[k] = nil
        end
    end
end

--[[
function this:sendRequestWithFlareSolverr(url)

    local args = {

        "curl", "-s", "-X", "POST", string.format("http://localhost:%s/v1", config.flaresolverr_port),
        "-H", "Content-Type: application/json",
        "-d", utils.format_json({cmd = "request.get", url = url, maxTimeout = 60000, followRedirects = true})
    }

    res = utils.subprocess({args = args})

    if res.status ~= 0 then return nil end

    local data = utils.parse_json(res.stdout)

    if not (data and data.status == "ok") then return nil end

    return data.solution.response
end
]]

return this