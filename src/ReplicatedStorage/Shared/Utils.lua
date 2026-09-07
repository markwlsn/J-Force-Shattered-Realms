--!strict
--[[
    Utils.lua
    Anime Arena Fighter

    Shared utility functions for table operations, math helpers, formatting,
    GUID generation, and safe execution wrappers.
]]

local HttpService = game:GetService("HttpService")

local Utils = {}

--[[
    Generates a unique identifier string using HttpService:GenerateGUID(false).
    Safely wrapped in pcall with a fallback UUID generator if HttpService is unavailable.
]]
function Utils.GenerateGUID(): string
    local success, result = pcall(function()
        return HttpService:GenerateGUID(false)
    end)

    if success and typeof(result) == "string" and result ~= "" then
        return result
    end

    -- Fallback RFC-4122 v4 pseudorandom UUID generator
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local guid = string.gsub(template, "[xy]", function(c: string): string
        local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format("%x", v)
    end)
    return guid
end

--[[
    Recursively deep-copies a table, safely handling cyclic references.
    If original is a primitive value, it is returned directly.
]]
function Utils.DeepCopy(original: any): any
    local function copyRecursive(value: any, visited: { [any]: any }): any
        if typeof(value) ~= "table" then
            return value
        end

        if visited[value] then
            return visited[value]
        end

        local clone = {}
        visited[value] = clone

        for k, v in pairs(value) do
            local clonedKey = copyRecursive(k, visited)
            local clonedVal = copyRecursive(v, visited)
            clone[clonedKey] = clonedVal
        end

        return clone
    end

    return copyRecursive(original, {})
end

--[[
    Recursively merges source into target table in-place.
    Source values take precedence on conflict.
    Returns the target table.
]]
function Utils.DeepMerge(target: { [any]: any }, source: { [any]: any }): { [any]: any }
    if typeof(target) ~= "table" then
        target = {}
    end
    if typeof(source) ~= "table" then
        return target
    end

    for key, sourceVal in pairs(source) do
        local targetVal = target[key]
        if typeof(targetVal) == "table" and typeof(sourceVal) == "table" then
            Utils.DeepMerge(targetVal, sourceVal)
        else
            target[key] = Utils.DeepCopy(sourceVal)
        end
    end

    return target
end

--[[
    Checks if a table contains a given value.
    Returns true if found, false otherwise.
]]
function Utils.TableContains(tbl: { [any]: any }, value: any): boolean
    if typeof(tbl) ~= "table" then
        return false
    end

    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end

    return false
end

--[[
    Returns an array containing all keys present in the dictionary/table.
]]
function Utils.TableKeys(tbl: { [any]: any }): { any }
    if typeof(tbl) ~= "table" then
        return {}
    end

    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end

    return keys
end

--[[
    Counts the total number of key-value pairs in a dictionary or array.
]]
function Utils.TableCount(tbl: { [any]: any }): number
    if typeof(tbl) ~= "table" then
        return 0
    end

    local count = 0
    for _ in pairs(tbl) do
        count += 1
    end

    return count
end

--[[
    Clamps a numeric value between min and max boundaries.
]]
function Utils.Clamp(value: number, min: number, max: number): number
    if typeof(value) ~= "number" then
        return 0
    end
    if typeof(min) ~= "number" then
        min = 0
    end
    if typeof(max) ~= "number" then
        max = min
    end

    if min > max then
        min, max = max, min
    end

    return math.clamp(value, min, max)
end

--[[
    Linear interpolation between number a and number b by fraction t.
]]
function Utils.Lerp(a: number, b: number, t: number): number
    if typeof(a) ~= "number" then a = 0 end
    if typeof(b) ~= "number" then b = 0 end
    if typeof(t) ~= "number" then t = 0 end

    return a + (b - a) * t
end

--[[
    Rounds a numeric value to the specified number of decimal places.
    If decimals is omitted or 0, rounds to the nearest integer.
]]
function Utils.Round(value: number, decimals: number?): number
    if typeof(value) ~= "number" then
        return 0
    end

    local dec = decimals or 0
    if dec <= 0 then
        return math.round(value)
    end

    local factor = 10 ^ dec
    return math.round(value * factor) / factor
end

--[[
    Formats time in seconds to human-readable string:
    - Under an hour: "M:SS" (e.g. 125 -> "2:05", 5 -> "0:05")
    - One hour or more: "H:MM:SS" (e.g. 3665 -> "1:01:05")
]]
function Utils.FormatTime(seconds: number): string
    if typeof(seconds) ~= "number" or seconds < 0 then
        seconds = 0
    end

    local totalSeconds = math.floor(seconds)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local secs = totalSeconds % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%d:%02d", minutes, secs)
    end
end

--[[
    Formats a number with comma thousand separators (e.g. 12500 -> "12,500").
    Properly handles negative numbers and decimal fractions.
]]
function Utils.FormatNumber(n: number): string
    if typeof(n) ~= "number" then
        return tostring(n or 0)
    end

    local isNegative = n < 0
    local absNumber = math.abs(n)
    local numString = tostring(absNumber)

    -- Split integer and decimal components
    local dotIndex = string.find(numString, "%.")
    local intPart = numString
    local decPart = nil

    if dotIndex then
        intPart = string.sub(numString, 1, dotIndex - 1)
        decPart = string.sub(numString, dotIndex + 1)
    end

    -- Reverse string, append comma after every 3 digits, trim trailing comma, reverse back
    local reversed = string.reverse(intPart)
    local withCommas = string.gsub(reversed, "(%d%d%d)", "%1,")
    withCommas = string.gsub(withCommas, ",$", "")
    intPart = string.reverse(withCommas)

    local result = (if isNegative then "-" else "") .. intPart
    if decPart then
        result = result .. "." .. decPart
    end

    return result
end

--[[
    Safe function call wrapper using pcall.
    Logs descriptive error with callstack on failure.
    Returns (true, ...) on success, or (false, error) on failure.
]]
function Utils.SafeCall(func: (...any) -> ...any, ...: any): (boolean, any)
    if typeof(func) ~= "function" then
        local errMsg = string.format("[Utils.SafeCall] Argument is not a function (got %s)", typeof(func))
        warn(errMsg)
        return false, errMsg
    end

    local results = table.pack(pcall(func, ...))
    local success = results[1]

    if not success then
        local err = results[2]
        warn(string.format("[Utils.SafeCall] Execution failed: %s\nStack Trace:\n%s", tostring(err), debug.traceback()))
        return false, err
    end

    return true, table.unpack(results, 2, results.n)
end

return Utils
