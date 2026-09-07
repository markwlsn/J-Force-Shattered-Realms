--!strict
--[[
    RemoteDefinitions.lua
    Single source of truth for all networking in Anime Arena Fighter.
    
    This module creates and returns all RemoteEvents and RemoteFunctions used
    across the client and server.
    
    Behavior:
    - Server: Creates the "Remotes" folder in ReplicatedStorage and instantiates
      all RemoteEvents and RemoteFunctions within it.
    - Client: Locates the "Remotes" folder and retrieves the replicated remotes
      using WaitForChild.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local REMOTES_FOLDER_NAME: string = "Remotes"
local CLIENT_WAIT_TIMEOUT: number = 10 -- Seconds to wait for replication on client

-------------------------------------------------------------------------------
-- Type Definitions
-------------------------------------------------------------------------------

export type RemoteDefinitions = {
    -- Combat (Client → Server)
    ActivateSkill: RemoteEvent,
    CancelSkill: RemoteEvent,

    -- Combat (Server → Client broadcast)
    SkillActivated: RemoteEvent,
    DamageDealt: RemoteEvent,
    PlayerDied: RemoteEvent,
    StatusEffectApplied: RemoteEvent,
    HPUpdated: RemoteEvent,

    -- Match
    RequestQueue: RemoteEvent,
    LeaveQueue: RemoteEvent,
    MatchFound: RemoteEvent,
    MatchCountdown: RemoteEvent,
    MatchStarted: RemoteEvent,
    MatchEnded: RemoteEvent,
    RoundEnded: RemoteEvent,
    TimerUpdate: RemoteEvent,

    -- Skill Tree (RemoteFunctions)
    UnlockSkill: RemoteFunction,
    GetSkillTree: RemoteFunction,

    -- Loadout (RemoteFunctions)
    EquipLoadout: RemoteFunction,
    GetLoadout: RemoteFunction,

    -- Economy (RemoteFunctions)
    GetPlayerData: RemoteFunction,
    PurchaseCosmetic: RemoteFunction,

    -- Faction (RemoteFunctions)
    SelectFaction: RemoteFunction,
}

-------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------

--- Retrieves an existing instance by name under parent, creates it if running
--- on the server, or yields with WaitForChild when running on the client.
--- @param parent Instance The parent instance to search or create within
--- @param className string The Roblox class name (Folder, RemoteEvent, RemoteFunction)
--- @param name string The name of the child instance
--- @return Instance The existing, created, or replicated Instance
local function getOrCreate(parent: Instance, className: string, name: string): Instance
    local existing = parent:FindFirstChild(name)
    if existing then
        return existing
    end

    if RunService:IsServer() then
        local remote = Instance.new(className)
        remote.Name = name
        remote.Parent = parent
        return remote
    else
        local remote = parent:WaitForChild(name, CLIENT_WAIT_TIMEOUT)
        if not remote then
            error(string.format("[RemoteDefinitions] Timed out waiting for %s '%s' under %s", className, name, parent:GetFullName()))
        end
        return remote
    end
end

-------------------------------------------------------------------------------
-- Initialization: Remotes Folder
-------------------------------------------------------------------------------

local remotesFolder: Folder = getOrCreate(ReplicatedStorage, "Folder", REMOTES_FOLDER_NAME) :: Folder
if not remotesFolder then
    error("[RemoteDefinitions] Failed to locate or create 'Remotes' folder in ReplicatedStorage")
end

-------------------------------------------------------------------------------
-- Remotes Definitions & Documentation
-------------------------------------------------------------------------------

--[[
    ═══════════════════════════════════════════════════════════════════════════
    1. COMBAT REMOTES (RemoteEvents — Fire-and-Forget)
    ═══════════════════════════════════════════════════════════════════════════

    ActivateSkill (Client → Server)
        Requests activation of a skill slot.
        Payload:
            skillId: string           -- Identifier of skill (e.g. "Fireball", "FlashStep")
            targetPosition: Vector3?  -- Aim or target ground point (for skillshots/AoE)
            targetUserId: number?     -- Targeted player's UserId (for targeted skills)
        Server validation:
            - Verifies player is alive and not crowd-controlled (stun/silence)
            - Verifies skill is equipped in player's active/ultimate slots
            - Verifies skill is off cooldown
            - Validates range and line of sight

    CancelSkill (Client → Server)
        Cancels an active channeled or charging skill early.
        Payload:
            skillId: string           -- Identifier of skill to cancel

    SkillActivated (Server → Client Broadcast)
        Notifies all players in the match to play animations, VFX, and audio.
        Payload:
            casterUserId: number      -- UserId of the character casting the skill
            skillId: string           -- Identifier of the skill cast
            position: Vector3         -- Cast origin position
            direction: Vector3        -- Direction vector of the skill

    DamageDealt (Server → Client Broadcast)
        Notifies clients of damage inflicted for floating damage numbers and SFX.
        Payload:
            targetUserId: number      -- UserId of the damaged character
            damage: number            -- Amount of damage dealt
            isCritical: boolean       -- Whether the attack was a critical strike
            sourceSkillId: string     -- Identifier of the skill dealing damage

    PlayerDied (Server → Client Broadcast)
        Notifies clients of a player knockout for kill feed and death state.
        Payload:
            userId: number            -- UserId of the player who died
            killerUserId: number      -- UserId of the killer (or self if environmental)

    StatusEffectApplied (Server → Client Broadcast)
        Notifies clients when a status effect is applied (stun, burn, slow, etc.).
        Payload:
            targetUserId: number      -- UserId of the character affected
            effectType: string        -- "Stun" | "Burn" | "Slow" | "Knockback" | "Silence" | "Fear" | "Sleep"
            duration: number          -- Duration of effect in seconds

    HPUpdated (Server → Client Broadcast)
        Authoritative HP synchronization from server to client HUD and overhead bars.
        Payload:
            userId: number            -- UserId of player
            currentHP: number         -- Current health value
            maxHP: number             -- Max health value
]]

--[[
    ═══════════════════════════════════════════════════════════════════════════
    2. MATCH REMOTES (RemoteEvents)
    ═══════════════════════════════════════════════════════════════════════════

    RequestQueue (Client → Server)
        Requests to join matchmaking queue for a specified mode.
        Payload:
            mode: string              -- "1v1" | "2v2" | "FFA" | "FactionWar"

    LeaveQueue (Client → Server)
        Requests removal from the matchmaking queue.
        Payload:
            (none)

    MatchFound (Server → Client)
        Notifies clients that an arena match has been formed.
        Payload:
            matchData: {
                MatchId: string,          -- Unique match GUID
                Mode: string,             -- "1v1" | "2v2" | "FFA" | "FactionWar"
                ArenaName: string,        -- e.g. "Arena_1v1_A"
                Players: { any }          -- Table of player info in the match
            }

    MatchCountdown (Server → Client)
        Periodic countdown tick before match officially begins.
        Payload:
            secondsRemaining: number  -- Seconds remaining (e.g. 5, 4, 3, 2, 1)

    MatchStarted (Server → Client)
        Signals that countdown is complete and combat is enabled.
        Payload:
            matchId: string           -- Unique match GUID

    MatchEnded (Server → Client)
        Broadcasts match completion with winner, stats, and rewards.
        Payload:
            matchData: {
                MatchId: string,          -- Unique match GUID
                Results: any              -- Winner, MVP, rewards (Gold/XP), and match stats
            }

    RoundEnded (Server → Client)
        Signals completion of a round in multi-round modes (e.g. best of 3).
        Payload:
            roundData: {
                Round: number,            -- Current round index (1, 2, 3)
                WinnerTeam: number?,      -- Winning team index (if team mode)
                WinnerUserId: number?     -- Winning player's UserId (for 1v1)
            }

    TimerUpdate (Server → Client)
        Broadcast every second with authoritative match time remaining.
        Payload:
            timeRemaining: number     -- Seconds remaining in current round/match
]]

--[[
    ═══════════════════════════════════════════════════════════════════════════
    3. SKILL TREE REMOTES (RemoteFunctions — Request / Response)
    ═══════════════════════════════════════════════════════════════════════════

    UnlockSkill (Client → Server → Client)
        Attempts to unlock a skill node in the player's faction skill tree.
        Request:
            skillId: string           -- Identifier of skill to unlock
        Response:
            {
                Success: boolean,         -- Whether unlock succeeded
                Error: string?            -- Error message if failed
            }
        Server validation:
            - Player level meets LevelRequired
            - Player has sufficient Gold
            - All prerequisite skills are unlocked
            - Skill belongs to player's faction

    GetSkillTree (Client → Server → Client)
        Retrieves the skill tree definition and unlock state for player's faction.
        Request:
            (none — determined by player's chosen faction)
        Response:
            {
                Tree: any,                -- SkillTreeDefinition
                Unlocked: { [string]: boolean } -- Set of unlocked skillIds
            }
]]

--[[
    ═══════════════════════════════════════════════════════════════════════════
    4. LOADOUT REMOTES (RemoteFunctions — Request / Response)
    ═══════════════════════════════════════════════════════════════════════════

    EquipLoadout (Client → Server → Client)
        Attempts to equip new skill selections into the active/passive/ultimate slots.
        Request:
            loadoutData: {
                ActiveSkills: { string }, -- Array of 4 active skill IDs
                PassiveSkills: { string },-- Array of 2 passive skill IDs
                Ultimate: string          -- 1 ultimate skill ID
            }
        Response:
            {
                Success: boolean,         -- Whether loadout was saved
                Error: string?            -- Error message if failed
            }
        Server validation:
            - All skills are unlocked by the player
            - Skills match required slot types (Active/Passive/Ultimate)
            - No duplicate active or passive skills
            - Player is not currently in a match

    GetLoadout (Client → Server → Client)
        Retrieves player's currently equipped loadout.
        Request:
            (none)
        Response:
            {
                Loadout: any              -- Current Loadout structure
            }
]]

--[[
    ═══════════════════════════════════════════════════════════════════════════
    5. ECONOMY REMOTES (RemoteFunctions — Request / Response)
    ═══════════════════════════════════════════════════════════════════════════

    GetPlayerData (Client → Server → Client)
        Retrieves sanitized player profile data for lobby and UI menus.
        Request:
            (none)
        Response:
            {
                PlayerData: any           -- Sanitized profile (Level, Gold, XP, Stats, etc.)
            }

    PurchaseCosmetic (Client → Server → Client)
        Purchases a cosmetic item from the shop using Gold or Gems.
        Request:
            cosmeticId: string        -- Identifier of cosmetic item
        Response:
            {
                Success: boolean,         -- Whether purchase succeeded
                Error: string?            -- Error message if failed
            }
        Server validation:
            - Item exists in catalog
            - Player does not already own the item
            - Player has sufficient currency
]]

--[[
    ═══════════════════════════════════════════════════════════════════════════
    6. FACTION REMOTES (RemoteFunctions — Request / Response)
    ═══════════════════════════════════════════════════════════════════════════

    SelectFaction (Client → Server → Client)
        Permanent initial faction selection for a new player.
        Request:
            faction: string           -- "Pirate" | "Shinigami" | "Ninja"
        Response:
            {
                Success: boolean,         -- Whether faction was set
                Error: string?            -- Error message if failed
            }
        Server validation:
            - Player has not already chosen a faction (PlayerData.Faction == nil)
            - Faction string is valid
        On success:
            - Grants default starter skills
            - Permanently binds faction
]]

local RemoteDefinitions: RemoteDefinitions = {
    -- Combat (Client → Server)
    ActivateSkill = getOrCreate(remotesFolder, "RemoteEvent", "ActivateSkill") :: RemoteEvent,
    CancelSkill = getOrCreate(remotesFolder, "RemoteEvent", "CancelSkill") :: RemoteEvent,

    -- Combat (Server → Client broadcast)
    SkillActivated = getOrCreate(remotesFolder, "RemoteEvent", "SkillActivated") :: RemoteEvent,
    DamageDealt = getOrCreate(remotesFolder, "RemoteEvent", "DamageDealt") :: RemoteEvent,
    PlayerDied = getOrCreate(remotesFolder, "RemoteEvent", "PlayerDied") :: RemoteEvent,
    StatusEffectApplied = getOrCreate(remotesFolder, "RemoteEvent", "StatusEffectApplied") :: RemoteEvent,
    HPUpdated = getOrCreate(remotesFolder, "RemoteEvent", "HPUpdated") :: RemoteEvent,

    -- Match (Client → Server & Server → Client)
    RequestQueue = getOrCreate(remotesFolder, "RemoteEvent", "RequestQueue") :: RemoteEvent,
    LeaveQueue = getOrCreate(remotesFolder, "RemoteEvent", "LeaveQueue") :: RemoteEvent,
    MatchFound = getOrCreate(remotesFolder, "RemoteEvent", "MatchFound") :: RemoteEvent,
    MatchCountdown = getOrCreate(remotesFolder, "RemoteEvent", "MatchCountdown") :: RemoteEvent,
    MatchStarted = getOrCreate(remotesFolder, "RemoteEvent", "MatchStarted") :: RemoteEvent,
    MatchEnded = getOrCreate(remotesFolder, "RemoteEvent", "MatchEnded") :: RemoteEvent,
    RoundEnded = getOrCreate(remotesFolder, "RemoteEvent", "RoundEnded") :: RemoteEvent,
    TimerUpdate = getOrCreate(remotesFolder, "RemoteEvent", "TimerUpdate") :: RemoteEvent,

    -- Skill Tree (RemoteFunctions)
    UnlockSkill = getOrCreate(remotesFolder, "RemoteFunction", "UnlockSkill") :: RemoteFunction,
    GetSkillTree = getOrCreate(remotesFolder, "RemoteFunction", "GetSkillTree") :: RemoteFunction,

    -- Loadout (RemoteFunctions)
    EquipLoadout = getOrCreate(remotesFolder, "RemoteFunction", "EquipLoadout") :: RemoteFunction,
    GetLoadout = getOrCreate(remotesFolder, "RemoteFunction", "GetLoadout") :: RemoteFunction,

    -- Economy (RemoteFunctions)
    GetPlayerData = getOrCreate(remotesFolder, "RemoteFunction", "GetPlayerData") :: RemoteFunction,
    PurchaseCosmetic = getOrCreate(remotesFolder, "RemoteFunction", "PurchaseCosmetic") :: RemoteFunction,

    -- Faction (RemoteFunctions)
    SelectFaction = getOrCreate(remotesFolder, "RemoteFunction", "SelectFaction") :: RemoteFunction,
}

return RemoteDefinitions
