--!strict
--[[
    Enums.lua
    Anime Arena Fighter

    Game enumerations as frozen, immutable tables.
    Provides canonical identifiers for Factions, Skill Paths, Skill Tiers,
    Slot Types, Match Modes, Match States, Hitboxes, Status Effects,
    Ranks, and Cosmetics.
]]

local Enums = {}

--------------------------------------------------------------------------------
-- EXPORTED LUAU TYPES
--------------------------------------------------------------------------------
export type Faction = "Pirate" | "Shinigami" | "Ninja"

export type SkillPath =
    | "Swordsman"
    | "DevilFruit"
    | "Haki"
    | "Tactician"
    | "Zanpakuto"
    | "Kido"
    | "Hollow"
    | "Healer"
    | "Ninjutsu"
    | "Taijutsu"
    | "Genjutsu"
    | "Sage"

export type SkillTier = number

export type SlotType = "Active" | "Passive" | "Ultimate"

export type MatchMode = "1v1" | "2v2" | "FFA" | "FactionWar" | "BossRaid"

export type MatchState = "Countdown" | "InProgress" | "Ending" | "Cleanup"

export type HitboxShape = "Sphere" | "Box" | "Cone" | "Line"

export type StatusEffectType =
    | "Stun"
    | "Silence"
    | "Slow"
    | "Burn"
    | "Knockback"
    | "Fear"
    | "Sleep"

export type Rank =
    | "Bronze"
    | "Silver"
    | "Gold"
    | "Platinum"
    | "Diamond"
    | "Master"
    | "Legend"

export type CosmeticType = "CharacterSkin" | "AuraEffect" | "VictoryEmote" | "Title"

--------------------------------------------------------------------------------
-- ENUM TABLES (Frozen for immutability)
--------------------------------------------------------------------------------

-- Anime factions playable in the game
Enums.Faction = table.freeze({
    Pirate = "Pirate",
    Shinigami = "Shinigami",
    Ninja = "Ninja",
})

-- All 12 skill tree paths across Pirate, Shinigami, and Ninja factions
Enums.SkillPath = table.freeze({
    -- Pirate Paths
    Swordsman = "Swordsman",
    DevilFruit = "DevilFruit",
    Haki = "Haki",
    Tactician = "Tactician",

    -- Shinigami Paths
    Zanpakuto = "Zanpakuto",
    Kido = "Kido",
    Hollow = "Hollow",
    Healer = "Healer",

    -- Ninja Paths
    Ninjutsu = "Ninjutsu",
    Taijutsu = "Taijutsu",
    Genjutsu = "Genjutsu",
    Sage = "Sage",
})

-- Progression tier for skills in a tree
Enums.SkillTier = table.freeze({
    Starter = 0,
    Tier1 = 1,
    Tier2 = 2,
    Tier3 = 3,
})

-- Combat loadout equip slot classification
Enums.SlotType = table.freeze({
    Active = "Active",
    Passive = "Passive",
    Ultimate = "Ultimate",
})

-- Arena game modes supported by the match system
Enums.MatchMode = table.freeze({
    Solo1v1 = "1v1",
    Team2v2 = "2v2",
    FFA = "FFA",
    FactionWar = "FactionWar",
    BossRaid = "BossRaid",
})

-- State machine phases for match lifecycle
Enums.MatchState = table.freeze({
    Countdown = "Countdown",
    InProgress = "InProgress",
    Ending = "Ending",
    Cleanup = "Cleanup",
})

-- Spatial collision geometry shapes for combat hitboxes
Enums.HitboxShape = table.freeze({
    Sphere = "Sphere",
    Box = "Box",
    Cone = "Cone",
    Line = "Line",
})

-- Crowd-control and damage-over-time status effects
Enums.StatusEffectType = table.freeze({
    Stun = "Stun",
    Silence = "Silence",
    Slow = "Slow",
    Burn = "Burn",
    Knockback = "Knockback",
    Fear = "Fear",
    Sleep = "Sleep",
})

-- Competitive ELO ranking tiers
Enums.Rank = table.freeze({
    Bronze = "Bronze",
    Silver = "Silver",
    Gold = "Gold",
    Platinum = "Platinum",
    Diamond = "Diamond",
    Master = "Master",
    Legend = "Legend",
})

-- Cosmetic categorization for customization and shop items
Enums.CosmeticType = table.freeze({
    CharacterSkin = "CharacterSkin",
    AuraEffect = "AuraEffect",
    VictoryEmote = "VictoryEmote",
    Title = "Title",
})

return table.freeze(Enums)
