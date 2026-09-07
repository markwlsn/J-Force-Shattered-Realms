--[[
    PlayerDataManager
    The most critical server module — manages loading, caching, saving,
    and migrating player data using Roblox DataStoreService.

    Features:
    - Exponential-backoff retries on DataStore calls
    - In-memory cache with dirty tracking
    - Data migration pipeline
    - Auto-save loop driven by Config.AUTO_SAVE_INTERVAL
    - Studio mock DataStore support
]]

local Types = require(game.ReplicatedStorage.Shared.Types)
local Config = require(game.ReplicatedStorage.Shared.Config)
local Utils = require(game.ReplicatedStorage.Shared.Utils)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STORE_NAME = "JForceShatteredRealms_PlayerData_v1"
local CURRENT_DATA_VERSION = 1

-- When true, Studio sessions use an in-memory table instead of real DataStore
local USE_MOCK_IN_STUDIO = true

local isStudioMock = USE_MOCK_IN_STUDIO and RunService:IsStudio()

-------------------------------------------------------------------------------
-- DataStore / Mock DataStore
-------------------------------------------------------------------------------

local playerDataStore: DataStore -- real store (may be nil when mocking)
local mockStore = {} -- in-memory fallback for Studio

if isStudioMock then
    warn("[PlayerDataManager] Running in Studio with mock DataStore enabled")
else
    playerDataStore = DataStoreService:GetDataStore(STORE_NAME)
end

-------------------------------------------------------------------------------
-- Cache  { [userId] = { data: PlayerData, dirty: boolean, lastSave: number } }
-------------------------------------------------------------------------------

local cache: { [number]: { data: Types.PlayerData, dirty: boolean, lastSave: number } } = {}

-------------------------------------------------------------------------------
-- Migrations
-------------------------------------------------------------------------------

local Migrations = {
    -- [fromVersion] = function(data) -> data
    -- Example for future use:
    -- [1] = function(data)
    --     data.NewField = "default"
    --     data.DataVersion = 2
    --     return data
    -- end,
}

-------------------------------------------------------------------------------
-- Private helpers
-------------------------------------------------------------------------------

--- Run any pending migrations on the data table.
local function migrateData(data: Types.PlayerData): Types.PlayerData
    while data.DataVersion < CURRENT_DATA_VERSION do
        local migrator = Migrations[data.DataVersion]
        if migrator then
            data = migrator(data)
        else
            warn("[PlayerDataManager] Missing migration for version " .. data.DataVersion)
            break
        end
    end
    return data
end

--- Wraps a DataStore operation in pcall with exponential-backoff retry.
--- @param operation string -- "GetAsync" | "SetAsync" | etc.
--- @param key string -- the DataStore key
--- @return boolean success, any result
local function safeDataStoreCall(operation: string, key: string, ...: any): (boolean, any)
    local args = { ... }
    local maxRetries = Config.DATA_SAVE_RETRIES or 3

    for attempt = 0, maxRetries - 1 do
        local success, result

        if isStudioMock then
            -- Mock implementation — operates on an in-memory table
            success = true
            if operation == "GetAsync" then
                result = mockStore[key]
            elseif operation == "SetAsync" then
                mockStore[key] = args[1]
                result = nil
            else
                warn("[PlayerDataManager] Unsupported mock operation: " .. operation)
                return false, "Unsupported operation"
            end
        else
            success, result = pcall(function()
                return (playerDataStore :: any)[operation](playerDataStore, key, table.unpack(args))
            end)
        end

        if success then
            return true, result
        end

        warn(
            "[PlayerDataManager] DataStore "
                .. operation
                .. " failed (attempt "
                .. (attempt + 1)
                .. "/"
                .. maxRetries
                .. "): "
                .. tostring(result)
        )

        if attempt < maxRetries - 1 then
            -- Exponential backoff: 2^attempt seconds (1, 2, 4, …)
            task.wait(2 ^ attempt)
        end
    end

    warn("[PlayerDataManager] DataStore " .. operation .. " permanently failed for key: " .. key)
    return false, "Max retries exceeded"
end

-------------------------------------------------------------------------------
-- Module
-------------------------------------------------------------------------------

local PlayerDataManager = {}

--- Load (or create) a player's data, cache it, and return it.
function PlayerDataManager.LoadPlayer(player: Player): Types.PlayerData
    local key = tostring(player.UserId)

    -- 1. Attempt to read from DataStore
    local success, storedData = safeDataStoreCall("GetAsync", key)

    local data: Types.PlayerData

    if success and storedData ~= nil then
        -- 3. Existing data — migrate if necessary
        if storedData.DataVersion and storedData.DataVersion < CURRENT_DATA_VERSION then
            storedData = migrateData(storedData)
        end

        -- 4. Validate
        local valid, validationErr = Types.ValidatePlayerData(storedData)
        if valid then
            data = storedData :: Types.PlayerData
        else
            warn(
                "[PlayerDataManager] Validation failed for "
                    .. player.Name
                    .. ": "
                    .. tostring(validationErr)
                    .. " — creating fresh data"
            )
            data = Types.CreateDefaultPlayerData(player.UserId, player.DisplayName)
        end
    else
        -- 2. New player or failed load — create defaults
        data = Types.CreateDefaultPlayerData(player.UserId, player.DisplayName)
    end

    -- 5. Store in cache
    cache[player.UserId] = {
        data = data,
        dirty = false,
        lastSave = os.time(),
    }

    -- 6. Log
    print("[PlayerDataManager] Loaded data for " .. player.Name)

    -- 7. Return
    return data
end

--- Save a player's data to the DataStore.
--- @return boolean -- true on success
function PlayerDataManager.SavePlayer(player: Player): boolean
    local entry = cache[player.UserId]
    if not entry then
        warn("[PlayerDataManager] SavePlayer called for uncached player: " .. player.Name)
        return false
    end

    -- Update save timestamp
    entry.data.LastSaveTime = os.time()

    local key = tostring(player.UserId)
    local success, err = safeDataStoreCall("SetAsync", key, entry.data)

    if success then
        entry.dirty = false
        entry.lastSave = os.time()
        return true
    else
        warn("[PlayerDataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
        return false
    end
end

--- Return cached PlayerData for a userId, or nil if not loaded.
function PlayerDataManager.GetData(userId: number): Types.PlayerData?
    local entry = cache[userId]
    if entry then
        return entry.data
    end
    return nil
end

--- Update a single top-level key on a player's cached data.
function PlayerDataManager.UpdateData(userId: number, key: string, value: any)
    local entry = cache[userId]
    if not entry then
        warn("[PlayerDataManager] UpdateData called for uncached userId: " .. tostring(userId))
        return
    end

    (entry.data :: any)[key] = value
    entry.dirty = true
end

--- Update a nested field using a dot-separated path (e.g. "Stats.WinStreak").
function PlayerDataManager.SetNestedData(userId: number, path: string, value: any)
    local entry = cache[userId]
    if not entry then
        warn("[PlayerDataManager] SetNestedData called for uncached userId: " .. tostring(userId))
        return
    end

    local keys = string.split(path, ".")
    if #keys == 0 then
        warn("[PlayerDataManager] SetNestedData received empty path")
        return
    end

    -- Traverse to the parent table of the final key
    local current: any = entry.data
    for i = 1, #keys - 1 do
        local k = keys[i]
        if type(current[k]) ~= "table" then
            warn("[PlayerDataManager] SetNestedData: intermediate key '" .. k .. "' is not a table in path '" .. path .. "'")
            return
        end
        current = current[k]
    end

    current[keys[#keys]] = value
    entry.dirty = true
end

--- Infinite auto-save loop. Should be started once via task.spawn from Main.server.lua.
function PlayerDataManager.AutoSaveLoop()
    while true do
        task.wait(Config.AUTO_SAVE_INTERVAL)

        for userId, entry in pairs(cache) do
            if entry.dirty then
                -- Resolve the Player object so we can reuse SavePlayer
                local player = Players:GetPlayerByUserId(userId)
                if player then
                    local ok = PlayerDataManager.SavePlayer(player)
                    if ok then
                        print("[PlayerDataManager] Auto-saved data for " .. player.Name)
                    end
                else
                    -- Player object gone but cache entry lingers — save with a synthetic key
                    entry.data.LastSaveTime = os.time()
                    local key = tostring(userId)
                    local success, err = safeDataStoreCall("SetAsync", key, entry.data)
                    if success then
                        entry.dirty = false
                        entry.lastSave = os.time()
                    else
                        warn("[PlayerDataManager] Auto-save failed for userId " .. tostring(userId) .. ": " .. tostring(err))
                    end
                end
            end
        end
    end
end

--- Final save when a player leaves. Always saves (ignores dirty flag).
function PlayerDataManager.OnPlayerRemoving(player: Player)
    -- 1. Force-save regardless of dirty flag
    PlayerDataManager.SavePlayer(player)

    -- 2. Remove from cache
    cache[player.UserId] = nil

    -- 3. Log
    print("[PlayerDataManager] Saved and unloaded data for " .. player.Name)
end

--- Save every cached player. Called from game:BindToClose to parallelise
--- within the 30-second shutdown window.
function PlayerDataManager.SaveAllPlayers()
    local threads: { thread } = {}

    for userId, _entry in pairs(cache) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            table.insert(threads, task.spawn(function()
                PlayerDataManager.SavePlayer(player)
            end))
        else
            -- Player already left but cache not yet cleaned — save directly
            table.insert(threads, task.spawn(function()
                _entry.data.LastSaveTime = os.time()
                local key = tostring(userId)
                local success, err = safeDataStoreCall("SetAsync", key, _entry.data)
                if success then
                    _entry.dirty = false
                else
                    warn("[PlayerDataManager] SaveAllPlayers failed for userId " .. tostring(userId) .. ": " .. tostring(err))
                end
            end))
        end
    end
end

return PlayerDataManager
