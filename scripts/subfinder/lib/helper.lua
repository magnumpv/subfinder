local utf8  = require "lib/fastutf8"
local utils = require "mp.utils"
local msg   = require "mp.msg"
local this  = {}

function this.findBestSubtitle(videoFile, subtitleFiles)

    local lastScore = 0
    local bestSubtitle

    for _, s in pairs(subtitleFiles) do

        local score = this.similarityScore(videoFile, s)

        if score > 0 and score > lastScore then bestSubtitle = s end

        lastScore = score
    end

    return bestSubtitle
end

function this.tokenize(str)

    str = str:lower():gsub("%.[^%.]-$", ""):gsub("%[[^%]]*%]", ""):gsub("%([^%)]*%)", ""):gsub("[^a-z0-9 ]", " ")

    local list = {}

    for val in str:gmatch("(%S+)") do list[val] = true end

    return list
end

function this.similarityScore(a, b)

    a                  = this.tokenize(a)
    b                  = this.tokenize(b)
    local intersection = 0
    local union        = 0
    local seen         = {}
    local categories   = {ova = true, sp = true, special = true}
    local aCategory    = ""
    local bCategory    = ""

    for k in pairs(a) do

        seen[k] = true
        union   = union + 1

        if b[k] then intersection = intersection + 1 end

        if categories[k] then aCategory = k end
    end

    for k in pairs(b) do

        if not seen[k] then

            union = union + 1
        end

        if categories[k] then bCategory = k end
    end

    if (aCategory ~= "" or bCategory ~= "") and aCategory ~= bCategory then return 0 end

    return intersection / union
end

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

    local res = mp.command_native({

        name           = 'subprocess',
        playback_only  = false,
        capture_stdout = true,
        capture_stderr = true,
        args           = args
    })

    if res.status ~= 0 then

        local tab     = string.rep(" ", 4)
        local command = ""

        for _, v in pairs(args) do command = command..v.." " end

        msg.error("Command failed: "..command)
        msg.error("[RESULT]")

        for k, v in pairs(res) do msg.error(tab..tostring(k).."="..tostring(v)) end
    end

    return res
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

            print(tab..tostring(k).."="..tostring(v))
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

    if not files then return nil end

    if ext then

        local extList = {}

        for val in ext:gmatch("([^,]+)") do extList[val] = true end

        local filtered = {}

        for _, f in ipairs(files) do

            local e = this.getExt(f)

            if e and extList[e] then table.insert(filtered, f) end
        end

        return #filtered > 0 and filtered or nil
    end

    return files
end

function this.visitTo(link)

    local isWindows = package.config:sub(1,1) == "\\"

    if isWindows then

        link = link:gsub("@", "")

        return this.runCommand({"powershell", "-NoProfile", "-Command", "Start-Process @'\n"..link.."\n'@"})
    else

        link = link:gsub("EOF", "")

        return this.runCommand({"sh", "-c", "xdg-open <<'EOF'\n"..link.."\nEOF"})
    end
end

function this.unpackArchive(source, target)

    if config.extract_engine == "winrar" then

        this.runCommand({"winrar", "x", "-o+", "-ibck", "-inul", source, target})
    else

        this.runCommand({"7z", "x", source, "-o"..target, "-y"})
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

function this.removeExt(filename)

    return filename:gsub("%.[^%.]-$", "")
end

function this.renameFile(file,newname)

    local dir, oldname = utils.split_path(file)
    local ext          = this.getExt(oldname)

    os.rename(dir..oldname, dir..newname.."."..ext)
end

function this.commandCheck(cmd)

    local isWindows = package.config:sub(1,1) == "\\"
    local res       = isWindows and this.runCommand({"where", cmd}) or this.runCommand({"which", cmd})

    return res.status == 0
end

function this.slugify(str)

    return str:lower():gsub("%s", "_")
end

function this.joinStrings(...)

    local t = {}

    for _, v in ipairs({...}) do table.insert(t, tostring(v)) end

    return table.concat(t, " ")
end

function this.hasValue(items, value)

    for _, item in ipairs(items) do if item == value then return true end end

    return false
end

return this