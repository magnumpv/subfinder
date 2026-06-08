local h       = require "lib/helper"
local assdraw = require "mp.assdraw"
local gui     = {}
gui.__index   = gui
gui.converter = {}

local overlay              = mp.create_osd_overlay("ass-events")
local textOverlay          = mp.create_osd_overlay("ass-events")
textOverlay.compute_bounds = true
textOverlay.hidden         = true

local screenWidth, screenHeight = 0, 0
local lastWidth                 = 0

gui.converter.opacity = function (val)

    return string.format("%x", val)
end

gui.converter.color = function (val, fade)

    if fade then

        local b = tonumber(val:sub(1,2), 16)
        local g = tonumber(val:sub(3,4), 16)
        local r = tonumber(val:sub(5,6), 16)

        r = math.floor(r * (1 - fade) + 0.5)
        g = math.floor(g * (1 - fade) + 0.5)
        b = math.floor(b * (1 - fade) + 0.5)

        return string.format("%02X%02X%02X", b, g, r)
    end

    return val
end

function gui:calculateTextWidth(text, fontSize)

    textOverlay.res_x, textOverlay.res_y = screenWidth, screenHeight
    textOverlay.data                     = "{\\bord0\\b0\\fs"..fontSize.."}"..text
    local res                            = textOverlay:update()

    return (res and res.x1) and (res.x1 - res.x0) or 0
end

function gui:new(sWidth, sHeight)

    screenWidth, screenHeight = sWidth, sHeight

    local o = {ass = assdraw.ass_new(), p = {}}

    return setmetatable(o, self)
end

function gui:setResolution(width, height)

    screenWidth, screenHeight = width, height
end

function gui:properties(newValues)

    h.clearTable(self.p)
    h.tableMerge2(self.p, newValues)

    return self
end

function gui:shape(width, height, round)

    local result = ""

    result = result.."\\an"..(self.p.align or 7)
    result = result.."\\pos("..self.p.x..","..self.p.y..")"
    result = result.."\\c&H"..self.p.color.."&"
    result = result.."\\bord"..(self.p.border or 0)
    if self.p.alpha then result = result.."\\alpha&H"..self.converter.opacity(self.p.alpha).."&" end

    self.ass:new_event()
    self.ass.text = self.ass.text.."{"..result.."}"

    self.ass:draw_start()
    self.ass:round_rect_cw(0, 0, width, height, round, round)
    self.ass:draw_stop()
end

function gui:text(str)

    str          = str or "unknown"
    local result = ""

    result = result.."\\an"..(self.p.align or 7)
    result = result.."\\pos("..self.p.x..","..self.p.y..")"
    result = result.."\\c&H"..(self.p.color or colors.text).."&"
    result = result.."\\bord0"
    result = result.."\\fs"..config.text_size
    if self.p.bold  then result = result.."\\b1"                                                 end
    if self.p.alpha then result = result.."\\alpha&H"..self.converter.opacity(self.p.alpha).."&" end
    if self.p.clip  then result = result.."\\clip("..self.p.clip..")" end

    self.ass:new_event()
    self.ass.text = self.ass.text.. "{"..result.."}"..str
end

function gui:icon(name, str)

    local result = ""

    result = result.."\\an"..(self.p.align or 7)
    result = result.."\\pos("..self.p.x..","..(self.p.y - config.sub_text_size / 4)..")"
    result = result.."\\c&H"..(colors[name] or self.p.color).."&"
    result = result.."\\bord0"
    result = result.."\\p1"
    if self.p.alpha then result = result.."\\alpha&H"..self.converter.opacity(self.p.alpha).."&" end

    self.ass:new_event()
    self.ass.text = self.ass.text.."{"..result.."}"..icons[name]

    if str then

        result = ""
        result = result.."\\an"..(self.p.align or 7)
        result = result.."\\pos("..(self.p.x + config.icon_right_margin)..","..self.p.y..")"
        result = result.."\\c&H"..self.p.color.."&"
        result = result.."\\bord0"
        result = result.."\\fs"..config.sub_text_size
        if self.p.alpha then result = result.."\\alpha&H"..self.converter.opacity(self.p.alpha).."&" end

        self.ass:new_event()
        self.ass.text = self.ass.text.."{"..result.."}"..str
    end
end

function gui:tag(str)

    local name  = str:upper()
    local width = self:calculateTextWidth(name, config.sub_text_size) + config.tag_padding * 2
    lastWidth   = width

    self.p.x     = self.p.x + width / 2
    local result = ""

    result = result.."\\an5"
    result = result.."\\pos("..self.p.x..","..self.p.y..")"
    result = result.."\\c&H"..colors[str].."&"
    result = result.."\\bord0"
    if self.p.alpha then result = result.."\\alpha&H"..self.converter.opacity(self.p.alpha).."&" end

    self.ass:new_event()
    self.ass.text = self.ass.text.."{"..result.."}"

    self.ass:draw_start()
    self.ass:round_rect_cw(0, 0, width, config.sub_text_size, config.round, config.round)
    self.ass:draw_stop()

    result = ""
    result = result.."\\an5"
    result = result.."\\pos("..(self.p.x)..","..self.p.y..")"
    result = result.."\\c&H"..colors.text.."&"
    result = result.."\\bord0"
    result = result.."\\b1"
    result = result.."\\fs"..config.sub_text_size
    if self.p.alpha then result = result.."\\alpha&H"..self.converter.opacity(self.p.alpha).."&" end

    self.ass:new_event()
    self.ass.text = self.ass.text.."{"..result.."}"..name
end

function gui:flag(lang)

    if flag.data then

        local result

        for _, flagpart in pairs(flag.data) do

            result = ""
            result = result.."\\an"..(self.p.align or "7")
            result = result.."\\pos("..self.p.x..","..self.p.y..")"
            result = result.."\\c&H"..(self.p.alpha and gui.converter.color(flagpart.c, self.p.alpha) or flagpart.c).."&"
            result = result.."\\bord0"
            result = result.."\\p1"

            self.ass:new_event()
            self.ass.text = self.ass.text.. "{"..result.."}"..flagpart.d
        end
    end
end

function gui:getLastWidth()

    return lastWidth
end

function gui:update()

    overlay.data  = self.ass.text
    overlay.res_x = (x and x > 0) and x or screenWidth
    overlay.res_y = (y and y > 0) and y or screenHeight
    overlay.z     = 2000

    overlay:update()

    self.ass.text = ""
end

function gui:remove()

    overlay:remove()

    screenWidth, screenHeight = 0, 0
    lastWidth                 = 0

    h.clearTable(self.p)
end

return gui