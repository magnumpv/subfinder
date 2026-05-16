local utf8  = require "lib/fastutf8"
local utils = require "mp.utils"
local this  = {}

function this.scaleShape(drawing, scale)

    local result = {}

    for token in drawing:gmatch("[^%s]+") do

        local num = tonumber(token)

        if num then

            table.insert(result, tostring(math.floor(num * scale + 0.5)))
        else

            table.insert(result, token)
        end
    end

    return table.concat(result, " ")
end

function this.getShapeSize(drawing)

    local minWidth, minHeight, maxWidth, maxHeight = 1000, 1000, 0, 0

    for x, y in drawing:gmatch("(%d+)%s+(%d+)") do

        x, y                = tonumber(x), tonumber(y)
        minWidth, minHeight = math.min(x, minWidth), math.min(y, minHeight)
        maxWidth, maxHeight = math.max(x, maxWidth), math.max(y, maxHeight)
    end

    return maxWidth, maxHeight
end

function this.runCommand(args)

    return mp.command_native({

        name           = 'subprocess',
        playback_only  = false,
        capture_stdout = true,
        capture_stderr = true,
        args           = args
    })
end

function this.splitString(str, splitter)

    splitter = splitter or ","

    local list = {}

    for val in str:gmatch("([^"..splitter.."]+)") do table.insert(list, val) end

    return list
end

function this.tableMerge(t1, t2)

    local t3 = {}

    for k, v in pairs(t1) do t3[k] = v end
    for k, v in pairs(t2) do t3[k] = v end

    return t3
end

function this.tableMerge2(t1, t2)

    if not t2 then return end

    for k, v in pairs(t2) do t1[k] = v end
end

function this.tableMerge3(t1, t2)

    if not t2 then return end

    for k, v in pairs(t2) do table.insert(t1, v) end
end

function this.truncate(str, limit)

    return (utf8.len(str) > limit) and string.gsub(utf8.sub(str, 1, limit), "%s+$", "").."..." or str
end

function this.assColor(rgbColor)

    local r, g, b = rgbColor:sub(1, 2), rgbColor:sub(3, 4), rgbColor:sub(5, 6)

    return b..g..r
end

function this.log(str)

    if type(str) == "table" then

        print(utils.format_json(str))
    else

        print(str)
    end
end

function this.log2(t, indent)

    indent    = indent or 0
    local tab = string.rep("  ", indent)

    for k, v in pairs(t) do

        if type(v) == "table" then

            print(tab..tostring(k)..":")

            this.log2(v, indent + 1)
        else

            print(tab..tostring(k).." = "..tostring(v))
        end
    end
end

function this.reindex(t, field)

    for i = 1, #t do t[i][field] = i end
end

function this.wait(seconds)

    os.execute("timeout "..seconds.." >nul")
end

function this.detectPlatform()

    local platform = mp.get_property_native("platform")

    if platform == "darwin" or platform == "windows" then

        return platform
    elseif os.getenv("WAYLAND_DISPLAY") or os.getenv("WAYLAND_SOCKET") then

        return "wayland"
    end

    return "x11"
end

function this.clearTable(t)

    for k in pairs(t) do t[k] = nil end
end

function this.listFiles(path, ext)

    local files = utils.readdir(path)

    if ext then

        local extList = {}

        for val in ext:gmatch("([^,]+)") do extList[val] = true end

        local filtered = {}

        for _, f in ipairs(files) do

            local e = string.match(f, "%.([^%.]-)$")

            if extList[e] then table.insert(filtered, f) end
        end

        return #filtered > 0 and filtered or nil
    end

    return files
end

function this.unpackArchive(source, target)

    local isWindows = package.config:sub(1,1) == "\\"

    if isWindows then

        this.runCommand({"powershell", "-NoProfile", "-Command", string.format('Expand-Archive -LiteralPath "%s" -DestinationPath "%s" -Force', source, target)})
    else

        this.runCommand({"unzip", "-o", source, "-d", target})
    end
end

function this.copyFile(source, target)

    local isWindows = package.config:sub(1,1) == "\\"

    if isWindows then

        this.runCommand({"powershell", "-NoProfile", "-Command", string.format('Copy-Item -LiteralPath "%s" -Destination "%s" -Force', source, target)})
    else

        this.runCommand({"cp", source, target})
    end
end

function this.getExt(filename)

    return filename:match("%.([^%.]-)$")
end

function this.renameFile(file,newname)

    local dir, oldname = utils.split_path(file)
    local ext          = this.getExt(oldname)

    os.rename(dir..oldname, dir..newname.."."..ext)
end

return this