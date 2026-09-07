--!strict
--[[
    Types.lua
    Anime Arena Fighter

    Defines all shared data structures, Luau type definitions, factory functions,
    and schema validation logic for player progression, combat loadouts, matches,
    and queues.

    Single source of truth for runtime data models across Client and Server.
]]

local Types = {}

-- Safe reference to Config module to avoid magic numbers
local Config = nil
local configOk, loadedConfig = pcall(function()
    return require(script.Parent.Config)
end)
if configOk and type(loadedConfig) == "table" then
    Config = loadedConfig
else
    -- Fallback constants if Config module is not yet initialized
    Config = {
        BASE_HP = 1000,
        STARTING_ELO = 1000,
        MATCH_TIME_LIMITS = {
            ["1v1"] = 180,
            ["2v2"] = 240,
            ["FFA"] = 180,
            ["FactionWar"] = 300,
            ["BossRaid"] = 600,
        },
        MATCH_ROUNDS = {
            ["1v1"] = 3,
        },
    }
end

--------------------------------------------------------------------------------
-- LUAU EXPORTED TYPES
--------------------------------------------------------------------------------

-- Skill Loadout configuration
export type Loadout = {
    ActiveSkills: { string },   -- Exactly 4 skill IDs (or "" if empty)
    PassiveSkills: { string },  -- Exactly 2 skill IDs (or "" if empty)
    Ultimate: string,           -- Exactly 1 skill ID (or "" if empty)
}

-- Lifetime player statistics
export type PlayerStats = {
    MatchesPlayed: number,
    MatchesWon: number,
    TotalKills: number,
    TotalDeaths: number,
    TotalDamageDealt: number,
    WinStreak: number,
    BestWinStreak: number,
}

-- Equipped cosmetics selection
export type EquippedCosmetics = {
    CharacterSkin: string?,
    AuraEffect: string?,
    VictoryEmote: string?,
    Title: string?,
}

-- Player user settings
export type PlayerSettings = {
    MusicVolume: number,
    SFXVolume: number,
    ShowDamageNumbers: boolean,
    AutoQueue: boolean,
}

-- Root persisted player data model (DataStore schema)
export type PlayerData = {
    UserId: number,
    DisplayName: string,
    CreatedAt: number,
    Faction: string?,
    Level: number,
    CurrentXP: number,
    TotalXPEarned: number,
    Gold: number,
    TotalGoldEarned: number,
    PremiumGems: number,
    UnlockedSkills: { [string]: boolean },
    Loadout: Loadout,
    Stats: PlayerStats,
    ELO: number,
    Rank: string,
    OwnedCosmetics: { [string]: boolean },
    EquippedCosmetics: EquippedCosmetics,
    Settings: PlayerSettings,
    DataVersion: number,
    LastSaveTime: number,
}

-- Temporary active status effect on a player
export type StatusEffect = {
    Type: string,
    Duration: number,
    Value: number?,
}

-- Active player combat state within an arena match
export type MatchPlayerState = {
    UserId: number,
    Faction: string,
    Team: number?,
    Loadout: Loadout,
    HP: number,
    MaxHP: number,
    Alive: boolean,
    Kills: number,
    Deaths: number,
    DamageDealt: number,
    Cooldowns: { [string]: number },
    ActiveStatusEffects: { StatusEffect },
    Position: Vector3,
}

-- Match end reward structure
export type MatchPlayerReward = {
    Gold: number,
    XP: number,
}

-- Match outcome results
export type MatchResults = {
    Winner: number?,
    MVP: number?,
    Rewards: { [number]: MatchPlayerReward }?,
}

-- Server-side active match state
export type MatchState = {
    MatchId: string,
    Mode: string,
    ArenaName: string,
    State: string,
    StartTime: number,
    TimeLimit: number,
    TimeRemaining: number,
    Players: { [number]: MatchPlayerState },
    CurrentRound: number,
    MaxRounds: number,
    RoundWins: { [number]: number },
    Results: MatchResults?,
}

-- Matchmaking queue entry
export type QueueEntry = {
    UserId: number,
    Faction: string,
    ELO: number,
    Mode: string,
    QueuedAt: number,
    PartyMembers: { number }?,
}

--------------------------------------------------------------------------------
-- DEFAULT CONSTANTS
--------------------------------------------------------------------------------

local DEFAULT_DATA_VERSION = 1
local DEFAULT_LEVEL = 1
local DEFAULT_XP = 0
local DEFAULT_GOLD = 0
local DEFAULT_PREMIUM_GEMS = 0
local DEFAULT_RANK = "Bronze"

local DEFAULT_SETTINGS = {
    MusicVolume = 0.5,
    SFXVolume = 0.8,
    ShowDamageNumbers = true,
    AutoQueue = false,
}

local DEFAULT_TIME_LIMIT_FALLBACK = 180
local DEFAULT_MAX_ROUNDS_FALLBACK = 1

--------------------------------------------------------------------------------
-- FACTORY FUNCTIONS
--------------------------------------------------------------------------------

--[[
    Creates a new empty Loadout table with standard slot dimensions:
    - 4 Active skills
    - 2 Passive skills
    - 1 Ultimate skill
]]
function Types.CreateDefaultLoadout(): Loadout
    return {
        ActiveSkills = { "", "", "", "" },
        PassiveSkills = { "", "" },
        Ultimate = "",
    }
end

--[[
    Creates a fresh PlayerData table populated with all default fields.
    Validates that userId is a valid number and displayName is a string.
]]
function Types.CreateDefaultPlayerData(userId: number, displayName: string): PlayerData
    local validUserId = if typeof(userId) == "number" then userId else 0
    local validDisplayName = if typeof(displayName) == "string" then displayName else "Fighter"
    local now = os.time()
    local startingElo = if Config and Config.STARTING_ELO then Config.STARTING_ELO else 1000

    local defaultData: PlayerData = {
        UserId = validUserId,
        DisplayName = validDisplayName,
        CreatedAt = now,

        -- Faction selection (nil until selected by player)
        Faction = nil,

        -- Progression
        Level = DEFAULT_LEVEL,
        CurrentXP = DEFAULT_XP,
        TotalXPEarned = DEFAULT_XP,

        -- Economy
        Gold = DEFAULT_GOLD,
        TotalGoldEarned = DEFAULT_GOLD,
        PremiumGems = DEFAULT_PREMIUM_GEMS,

        -- Skills & Loadout
        UnlockedSkills = {},
        Loadout = Types.CreateDefaultLoadout(),

        -- Stats
        Stats = {
            MatchesPlayed = 0,
            MatchesWon = 0,
            TotalKills = 0,
            TotalDeaths = 0,
            TotalDamageDealt = 0,
            WinStreak = 0,
            BestWinStreak = 0,
        },

        -- Ranking
        ELO = startingElo,
        Rank = DEFAULT_RANK,

        -- Cosmetics
        OwnedCosmetics = {},
        EquippedCosmetics = {
            CharacterSkin = nil,
            AuraEffect = nil,
            VictoryEmote = nil,
            Title = nil,
        },

        -- Settings
        Settings = {
            MusicVolume = DEFAULT_SETTINGS.MusicVolume,
            SFXVolume = DEFAULT_SETTINGS.SFXVolume,
            ShowDamageNumbers = DEFAULT_SETTINGS.ShowDamageNumbers,
            AutoQueue = DEFAULT_SETTINGS.AutoQueue,
        },

        -- Metadata
        DataVersion = DEFAULT_DATA_VERSION,
        LastSaveTime = now,
    }

    return defaultData
end

--[[
    Creates an active combat state representation for a player inside a match.
    HP defaults to Config.BASE_HP (or 1000).
]]
function Types.CreateMatchPlayerState(
    userId: number,
    faction: string,
    loadout: Loadout?,
    team: number?
): MatchPlayerState
    local baseHp = if Config and Config.BASE_HP then Config.BASE_HP else 1000
    local resolvedLoadout = loadout or Types.CreateDefaultLoadout()

    local playerState: MatchPlayerState = {
        UserId = userId,
        Faction = faction,
        Team = team,
        Loadout = resolvedLoadout,
        HP = baseHp,
        MaxHP = baseHp,
        Alive = true,
        Kills = 0,
        Deaths = 0,
        DamageDealt = 0,
        Cooldowns = {},
        ActiveStatusEffects = {},
        Position = Vector3.zero,
    }

    return playerState
end

--[[
    Creates a new server-side MatchState container for an arena encounter.
    Time limit and max rounds are retrieved from Config when available.
]]
function Types.CreateMatchState(matchId: string, mode: string, arenaName: string): MatchState
    local timeLimit = DEFAULT_TIME_LIMIT_FALLBACK
    if Config and Config.MATCH_TIME_LIMITS and Config.MATCH_TIME_LIMITS[mode] then
        timeLimit = Config.MATCH_TIME_LIMITS[mode]
    end

    local maxRounds = DEFAULT_MAX_ROUNDS_FALLBACK
    if Config and Config.MATCH_ROUNDS and Config.MATCH_ROUNDS[mode] then
        maxRounds = Config.MATCH_ROUNDS[mode]
    end

    local matchState: MatchState = {
        MatchId = matchId,
        Mode = mode,
        ArenaName = arenaName,
        State = "Countdown",
        StartTime = os.time(),
        TimeLimit = timeLimit,
        TimeRemaining = timeLimit,
        Players = {},
        CurrentRound = 1,
        MaxRounds = maxRounds,
        RoundWins = {},
        Results = nil,
    }

    return matchState
end

--[[
    Creates a new queue entry when a player queues for matchmaking.
]]
function Types.CreateQueueEntry(
    userId: number,
    faction: string,
    elo: number,
    mode: string
): QueueEntry
    local queueEntry: QueueEntry = {
        UserId = userId,
        Faction = faction,
        ELO = elo,
        Mode = mode,
        QueuedAt = os.time(),
        PartyMembers = nil,
    }

    return queueEntry
end

--------------------------------------------------------------------------------
-- VALIDATOR FUNCTIONS
--------------------------------------------------------------------------------

--[[
    Validates that a PlayerData candidate table meets the required schema.
    Returns (true, nil) if valid, or (false, errorMessage) if invalid.
]]
function Types.ValidatePlayerData(data: any): (boolean, string?)
    if typeof(data) ~= "table" then
        return false, string.format("PlayerData must be a table, got %s", typeof(data))
    end

    -- Required scalar fields
    local requiredTypes = {
        UserId = "number",
        DisplayName = "string",
        CreatedAt = "number",
        Level = "number",
        CurrentXP = "number",
        TotalXPEarned = "number",
        Gold = "number",
        TotalGoldEarned = "number",
        PremiumGems = "number",
        UnlockedSkills = "table",
        Loadout = "table",
        Stats = "table",
        ELO = "number",
        Rank = "string",
        OwnedCosmetics = "table",
        EquippedCosmetics = "table",
        Settings = "table",
        DataVersion = "number",
        LastSaveTime = "number",
    }

    for field, expectedType in pairs(requiredTypes) do
        local val = data[field]
        if typeof(val) ~= expectedType then
            return false, string.format("Field '%s' is missing or invalid (expected %s, got %s)", field, expectedType, typeof(val))
        end
    end

    -- Optional / Nullable field: Faction (must be string or nil)
    if data.Faction ~= nil and typeof(data.Faction) ~= "string" then
        return false, string.format("Field 'Faction' must be string or nil, got %s", typeof(data.Faction))
    end

    -- Validate Loadout structure
    local loadout = data.Loadout
    if typeof(loadout.ActiveSkills) ~= "table" then
        return false, "Loadout.ActiveSkills must be a table"
    end
    if #loadout.ActiveSkills ~= 4 then
        return false, string.format("Loadout.ActiveSkills must contain exactly 4 entries, got %d", #loadout.ActiveSkills)
    end
    for i = 1, 4 do
        if typeof(loadout.ActiveSkills[i]) ~= "string" then
            return false, string.format("Loadout.ActiveSkills[%d] must be a string, got %s", i, typeof(loadout.ActiveSkills[i]))
        end
    end

    if typeof(loadout.PassiveSkills) ~= "table" then
        return false, "Loadout.PassiveSkills must be a table"
    end
    if #loadout.PassiveSkills ~= 2 then
        return false, string.format("Loadout.PassiveSkills must contain exactly 2 entries, got %d", #loadout.PassiveSkills)
    end
    for i = 1, 2 do
        if typeof(loadout.PassiveSkills[i]) ~= "string" then
            return false, string.format("Loadout.PassiveSkills[%d] must be a string, got %s", i, typeof(loadout.PassiveSkills[i]))
        end
    end

    if typeof(loadout.Ultimate) ~= "string" then
        return false, string.format("Loadout.Ultimate must be a string, got %s", typeof(loadout.Ultimate))
    end

    -- Validate Stats table
    local requiredStats = {
        MatchesPlayed = "number",
        MatchesWon = "number",
        TotalKills = "number",
        TotalDeaths = "number",
        TotalDamageDealt = "number",
        WinStreak = "number",
        BestWinStreak = "number",
    }
    for statField, statType in pairs(requiredStats) do
        if typeof(data.Stats[statField]) ~= statType then
            return false, string.format("Stats.%s must be %s, got %s", statField, statType, typeof(data.Stats[statField]))
        end
    end

    -- Validate EquippedCosmetics table (nullable strings)
    local cosmeticSlots = { "CharacterSkin", "AuraEffect", "VictoryEmote", "Title" }
    for _, slot in ipairs(cosmeticSlots) do
        local val = data.EquippedCosmetics[slot]
        if val ~= nil and typeof(val) ~= "string" then
            return false, string.format("EquippedCosmetics.%s must be string or nil, got %s", slot, typeof(val))
        end
    end

    -- Validate Settings table
    local requiredSettings = {
        MusicVolume = "number",
        SFXVolume = "number",
        ShowDamageNumbers = "boolean",
        AutoQueue = "boolean",
    }
    for settingKey, settingType in pairs(requiredSettings) do
        if typeof(data.Settings[settingKey]) ~= settingType then
            return false, string.format("Settings.%s must be %s, got %s", settingKey, settingType, typeof(data.Settings[settingKey]))
        end
    end

    return true, nil
end

return Types
