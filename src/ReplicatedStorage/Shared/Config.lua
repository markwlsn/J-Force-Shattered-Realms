--!strict
--[[
    Config.lua
    Anime Arena Fighter

    Master configuration module containing all tunable constants, combat parameters,
    match pacing, progression curves, ranking brackets, and economic values.
    No magic numbers should exist anywhere else in the codebase.
]]

local Config = {}

--------------------------------------------------------------------------------
-- COMBAT CONSTANTS
--------------------------------------------------------------------------------
Config.COMBAT = table.freeze({
    BASE_HP = 1000,
    BASE_WALK_SPEED = 20,
    BASE_JUMP_POWER = 55,
    BASE_CRIT_CHANCE = 0.10,
    CRIT_MULTIPLIER = 1.5,
    MAX_DEFENSE_REDUCTION = 0.50,
    MELEE_RANGE = 8, -- studs
})

-- Top-level aliases for direct access
Config.BASE_HP = Config.COMBAT.BASE_HP
Config.BASE_WALK_SPEED = Config.COMBAT.BASE_WALK_SPEED
Config.BASE_JUMP_POWER = Config.COMBAT.BASE_JUMP_POWER
Config.BASE_CRIT_CHANCE = Config.COMBAT.BASE_CRIT_CHANCE
Config.CRIT_MULTIPLIER = Config.COMBAT.CRIT_MULTIPLIER
Config.MAX_DEFENSE_REDUCTION = Config.COMBAT.MAX_DEFENSE_REDUCTION
Config.MELEE_RANGE = Config.COMBAT.MELEE_RANGE

--------------------------------------------------------------------------------
-- MATCH & MATCHMAKING
--------------------------------------------------------------------------------
Config.MATCH = table.freeze({
    COUNTDOWN_DURATION = 5,          -- seconds before match begins
    RESULTS_SCREEN_DURATION = 8,     -- seconds to display match outcome
    MATCHMAKING_TICK_INTERVAL = 2,   -- seconds between matchmaking poll cycles
    INITIAL_ELO_TOLERANCE = 200,     -- starting ELO range search window (+/-)
    ELO_TOLERANCE_EXPAND_RATE = 50,  -- expansion amount per 10s waiting in queue
    MAX_ELO_TOLERANCE = 500,         -- maximum search window before matching anyone
})

Config.COUNTDOWN_DURATION = Config.MATCH.COUNTDOWN_DURATION
Config.RESULTS_SCREEN_DURATION = Config.MATCH.RESULTS_SCREEN_DURATION
Config.MATCHMAKING_TICK_INTERVAL = Config.MATCH.MATCHMAKING_TICK_INTERVAL
Config.INITIAL_ELO_TOLERANCE = Config.MATCH.INITIAL_ELO_TOLERANCE
Config.ELO_TOLERANCE_EXPAND_RATE = Config.MATCH.ELO_TOLERANCE_EXPAND_RATE
Config.MAX_ELO_TOLERANCE = Config.MATCH.MAX_ELO_TOLERANCE

--------------------------------------------------------------------------------
-- RESPAWN & LIVES
--------------------------------------------------------------------------------
Config.RESPAWN = table.freeze({
    RESPAWN_TIME_2V2 = 5,         -- seconds before respawn in 2v2
    RESPAWN_TIME_FACTION_WAR = 8, -- seconds before respawn in Faction War
    RESPAWN_TIME_BOSS_RAID = 10,  -- seconds before respawn in Boss Raid
    BOSS_RAID_LIVES = 3,          -- max respawn lives per player in Boss Raid
})

Config.RESPAWN_TIME_2V2 = Config.RESPAWN.RESPAWN_TIME_2V2
Config.RESPAWN_TIME_FACTION_WAR = Config.RESPAWN.RESPAWN_TIME_FACTION_WAR
Config.RESPAWN_TIME_BOSS_RAID = Config.RESPAWN.RESPAWN_TIME_BOSS_RAID
Config.BOSS_RAID_LIVES = Config.RESPAWN.BOSS_RAID_LIVES

--------------------------------------------------------------------------------
-- ECONOMY & REWARDS
--------------------------------------------------------------------------------
Config.ECONOMY = table.freeze({
    GOLD_WIN = 100,
    GOLD_LOSS = 50,
    GOLD_PER_KILL = 10,
    GOLD_PER_1000_DAMAGE = 5,
    XP_WIN = 60,
    XP_LOSS = 30,
    XP_PER_KILL = 5,
    XP_PER_1000_DAMAGE = 3,
    WIN_STREAK_BONUS_PER_WIN = 0.20, -- 20% bonus per win in current streak
    WIN_STREAK_BONUS_CAP = 1.00,     -- 100% max streak bonus multiplier
    SKILL_RESET_COST = 500,          -- gold cost to reset unlocked skill nodes
})

Config.GOLD_WIN = Config.ECONOMY.GOLD_WIN
Config.GOLD_LOSS = Config.ECONOMY.GOLD_LOSS
Config.GOLD_PER_KILL = Config.ECONOMY.GOLD_PER_KILL
Config.GOLD_PER_1000_DAMAGE = Config.ECONOMY.GOLD_PER_1000_DAMAGE
Config.XP_WIN = Config.ECONOMY.XP_WIN
Config.XP_LOSS = Config.ECONOMY.XP_LOSS
Config.XP_PER_KILL = Config.ECONOMY.XP_PER_KILL
Config.XP_PER_1000_DAMAGE = Config.ECONOMY.XP_PER_1000_DAMAGE
Config.WIN_STREAK_BONUS_PER_WIN = Config.ECONOMY.WIN_STREAK_BONUS_PER_WIN
Config.WIN_STREAK_BONUS_CAP = Config.ECONOMY.WIN_STREAK_BONUS_CAP
Config.SKILL_RESET_COST = Config.ECONOMY.SKILL_RESET_COST

--------------------------------------------------------------------------------
-- PROGRESSION FORMULA
--------------------------------------------------------------------------------
Config.PROGRESSION = table.freeze({
    XP_FORMULA_BASE = 100,
    XP_FORMULA_EXPONENT = 1.5,
})

Config.XP_FORMULA_BASE = Config.PROGRESSION.XP_FORMULA_BASE
Config.XP_FORMULA_EXPONENT = Config.PROGRESSION.XP_FORMULA_EXPONENT

--------------------------------------------------------------------------------
-- ELO RATING
--------------------------------------------------------------------------------
Config.ELO = table.freeze({
    STARTING_ELO = 1000,
    ELO_K_FACTOR = 32,
    MINIMUM_ELO = 100,
})

Config.STARTING_ELO = Config.ELO.STARTING_ELO
Config.ELO_K_FACTOR = Config.ELO.ELO_K_FACTOR
Config.MINIMUM_ELO = Config.ELO.MINIMUM_ELO

--------------------------------------------------------------------------------
-- PERSISTENCE & TIMING
--------------------------------------------------------------------------------
Config.TIMING = table.freeze({
    AUTO_SAVE_INTERVAL = 120,    -- seconds between auto-saves
    DATA_SAVE_RETRIES = 3,       -- attempts before giving up on failed save
    BIND_TO_CLOSE_TIMEOUT = 30,  -- seconds server waits during shutdown
})

Config.AUTO_SAVE_INTERVAL = Config.TIMING.AUTO_SAVE_INTERVAL
Config.DATA_SAVE_RETRIES = Config.TIMING.DATA_SAVE_RETRIES
Config.BIND_TO_CLOSE_TIMEOUT = Config.TIMING.BIND_TO_CLOSE_TIMEOUT

--------------------------------------------------------------------------------
-- ANTI-CHEAT VALIDATION
--------------------------------------------------------------------------------
Config.ANTI_CHEAT = table.freeze({
    MAX_SKILL_FIRES_PER_SECOND = 5,
    MAX_MOVEMENT_SPEED = 60,     -- studs/sec (accounts for dashes/teleports)
    POSITION_CHECK_INTERVAL = 1, -- seconds between speed checks
})

Config.MAX_SKILL_FIRES_PER_SECOND = Config.ANTI_CHEAT.MAX_SKILL_FIRES_PER_SECOND
Config.MAX_MOVEMENT_SPEED = Config.ANTI_CHEAT.MAX_MOVEMENT_SPEED
Config.POSITION_CHECK_INTERVAL = Config.ANTI_CHEAT.POSITION_CHECK_INTERVAL

--------------------------------------------------------------------------------
-- ARENA SIZES (studs)
--------------------------------------------------------------------------------
Config.ARENA_SIZES = table.freeze({
    ["Arena_1v1_A"]      = Vector3.new(80, 50, 80),
    ["Arena_1v1_B"]      = Vector3.new(100, 50, 100),
    ["Arena_2v2"]        = Vector3.new(120, 50, 120),
    ["Arena_FFA"]        = Vector3.new(150, 50, 150),
    ["Arena_FactionWar"] = Vector3.new(200, 50, 200),
})

--------------------------------------------------------------------------------
-- MATCH TIME LIMITS (seconds)
--------------------------------------------------------------------------------
Config.MATCH_TIME_LIMITS = table.freeze({
    ["1v1"]        = 180,
    ["2v2"]        = 240,
    ["FFA"]        = 180,
    ["FactionWar"] = 300,
    ["BossRaid"]   = 600,
})

--------------------------------------------------------------------------------
-- MATCH ROUNDS (best of N)
--------------------------------------------------------------------------------
Config.MATCH_ROUNDS = table.freeze({
    ["1v1"]        = 3, -- best of 3
    ["2v2"]        = 1,
    ["FFA"]        = 1,
    ["FactionWar"] = 1,
    ["BossRaid"]   = 1,
})

--------------------------------------------------------------------------------
-- RANK BRACKETS
--------------------------------------------------------------------------------
Config.RANK_BRACKETS = table.freeze({
    Bronze   = table.freeze({ Min = 0,    Max = 799 }),
    Silver   = table.freeze({ Min = 800,  Max = 1099 }),
    Gold     = table.freeze({ Min = 1100, Max = 1399 }),
    Platinum = table.freeze({ Min = 1400, Max = 1699 }),
    Diamond  = table.freeze({ Min = 1700, Max = 1999 }),
    Master   = table.freeze({ Min = 2000, Max = 2299 }),
    Legend   = table.freeze({ Min = 2300, Max = math.huge }),
})

--------------------------------------------------------------------------------
-- COSMETIC PRICES (in gems)
--------------------------------------------------------------------------------
Config.COSMETIC_PRICES = table.freeze({
    CharacterSkin = 500,
    AuraEffect    = 300,
    VictoryEmote  = 200,
    Title         = 100,
})

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

--[[
    Calculates total XP required to advance from the specified level to the next.
    Formula: floor(XP_FORMULA_BASE * level^XP_FORMULA_EXPONENT)
    
    @param level: The current level of the player (must be >= 1)
    @return: XP required to complete this level
]]
function Config.XPForLevel(level: number): number
    local safeLevel = if typeof(level) == "number" and level > 0 then level else 1
    return math.floor(Config.XP_FORMULA_BASE * (safeLevel ^ Config.XP_FORMULA_EXPONENT))
end

--[[
    Determines the player's competitive rank based on their ELO rating.
    Evaluates against Config.RANK_BRACKETS thresholds.
    
    @param elo: Current competitive ELO rating
    @return: Name of the rank ("Bronze", "Silver", "Gold", "Platinum", "Diamond", "Master", "Legend")
]]
function Config.GetRank(elo: number): string
    local safeElo = if typeof(elo) == "number" then elo else Config.STARTING_ELO

    if safeElo >= Config.RANK_BRACKETS.Legend.Min then
        return "Legend"
    elseif safeElo >= Config.RANK_BRACKETS.Master.Min then
        return "Master"
    elseif safeElo >= Config.RANK_BRACKETS.Diamond.Min then
        return "Diamond"
    elseif safeElo >= Config.RANK_BRACKETS.Platinum.Min then
        return "Platinum"
    elseif safeElo >= Config.RANK_BRACKETS.Gold.Min then
        return "Gold"
    elseif safeElo >= Config.RANK_BRACKETS.Silver.Min then
        return "Silver"
    else
        return "Bronze"
    end
end

return table.freeze(Config)
