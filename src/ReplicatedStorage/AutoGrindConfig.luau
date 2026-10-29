-- Luau | Shared configuration for the BloxGrindStudio sample game.
-- This is intended for a Roblox experience you own and control.

local Config = {}

Config.LoopInterval = 0.2
Config.StateUpdateInterval = 0.75
Config.AttackDamage = 12
Config.AttackRange = 9
Config.AttackCooldown = 0.8
Config.TargetMaxDistance = 220
Config.PathRecomputeInterval = 1.2
Config.RequestRateLimit = 0.08

-- Teleport destinations are names of BaseParts under Workspace.FarmDestinations.
-- Only these keys are accepted by the server.
Config.Destinations = {
    Spawn = "SpawnPoint",
    QuestBoard = "QuestBoard",
    BossArena = "BossArena",
}

-- Add matching NPC models under Workspace.Enemies.
-- Each model must have a Humanoid, HumanoidRootPart and AutoFarmTarget=true.
Config.Quests = {
    {
        Id = "bandit_patrol",
        Name = "Patrulha Bandit",
        EnemyName = "Bandit",
        MinLevel = 1,
        RequiredKills = 5,
        RewardXP = 100,
        RewardBeli = 125,
    },
    {
        Id = "desert_patrol",
        Name = "Patrulha do Deserto",
        EnemyName = "Desert Bandit",
        MinLevel = 10,
        RequiredKills = 7,
        RewardXP = 240,
        RewardBeli = 300,
    },
    {
        Id = "ice_patrol",
        Name = "Guarda do Gelo",
        EnemyName = "Ice Guard",
        MinLevel = 25,
        RequiredKills = 8,
        RewardXP = 500,
        RewardBeli = 650,
    },
}

function Config.GetQuestById(id)
    for _, quest in ipairs(Config.Quests) do
        if quest.Id == id then
            return quest
        end
    end

    return nil
end

function Config.GetQuestForLevel(level)
    local selected = nil

    for _, quest in ipairs(Config.Quests) do
        if level >= quest.MinLevel then
            selected = quest
        end
    end

    return selected
end

return Config
