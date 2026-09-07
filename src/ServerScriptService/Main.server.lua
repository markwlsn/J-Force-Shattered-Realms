--!strict
--[[
    Main.server.lua
    Anime Arena Fighter - Server Entry Point
    
    Initializes all server-side managers, ensures remote declarations are loaded,
    handles player lifecycle (joining, loading data, creating leaderstats, leaving),
    initiates the auto-save loop, and binds to server shutdown for graceful data persistence.
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1. Print startup banner
print("========================================")
print("  J Force: Shattered Realms - Server Starting")
print("========================================")

-- 2. Require all manager modules (from ServerScriptService.Managers)
local PlayerDataManager = require(script.Parent.Managers.PlayerDataManager)

-- TODO: The following managers will be added in later phases:
-- local MatchManager = require(script.Parent.Managers.MatchManager)
-- local CombatManager = require(script.Parent.Managers.CombatManager)
-- local SkillTreeManager = require(script.Parent.Managers.SkillTreeManager)
-- local EconomyManager = require(script.Parent.Managers.EconomyManager)
-- local LoadoutManager = require(script.Parent.Managers.LoadoutManager)
-- local LeaderboardManager = require(script.Parent.Managers.LeaderboardManager)

-- 3. Require RemoteDefinitions to ensure all remotes are created
local Remotes = require(ReplicatedStorage.Remotes.RemoteDefinitions)

-- 4. PlayerAdded logic
local function onPlayerAdded(player: Player): ()
    print("[Main] Player joined: " .. player.Name)
    
    -- Load player data from DataStore
    local data = PlayerDataManager.LoadPlayer(player)
    if not data then
        warn("[Main] Failed to load data for " .. player.Name)
        return
    end
    
    -- Guard against player disconnecting while async data load was yielding
    if not player:IsDescendantOf(Players) then
        return
    end
    
    -- If player hasn't chosen a faction, they'll see FactionSelectScreen
    -- (handled client-side by checking data.Faction == nil)
    
    -- Set up leaderstats for display
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    local levelStat = Instance.new("IntValue")
    levelStat.Name = "Level"
    levelStat.Value = data.Level
    levelStat.Parent = leaderstats
    
    local goldStat = Instance.new("IntValue")
    goldStat.Name = "Gold"
    goldStat.Value = data.Gold
    goldStat.Parent = leaderstats
    
    local rankStat = Instance.new("StringValue")
    rankStat.Name = "Rank"
    rankStat.Value = data.Rank or "Bronze"
    rankStat.Parent = leaderstats
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- 5. Set up Players.PlayerRemoving connection
local function onPlayerRemoving(player: Player): ()
    print("[Main] Player leaving: " .. player.Name)
    PlayerDataManager.OnPlayerRemoving(player)
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

-- 6. Handle any players already in the server (in case script loads late)
for _, player in Players:GetPlayers() do
    task.spawn(function()
        onPlayerAdded(player)
    end)
end

-- 7. Start auto-save loop
task.spawn(function()
    PlayerDataManager.AutoSaveLoop()
end)

-- 8. Bind to close for graceful shutdown
game:BindToClose(function()
    print("[Main] Server shutting down, saving all player data...")
    PlayerDataManager.SaveAllPlayers()
    print("[Main] All data saved. Goodbye!")
end)

-- 9. Print ready message
print("[Main] Server initialized successfully!")
print("[Main] Loaded managers: PlayerDataManager")
print("[Main] Waiting for players...")
