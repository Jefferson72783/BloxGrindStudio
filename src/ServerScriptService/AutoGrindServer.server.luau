-- Luau | ServerScriptService | Roblox Studio | server-authoritative sample gameplay
-- Farm automation is for an experience you own. The server validates targets, ranges and rewards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.AutoGrindConfig)

local remote = ReplicatedStorage:FindFirstChild("AutoGrindRemote")
if remote and not remote:IsA("RemoteEvent") then
    error("ReplicatedStorage.AutoGrindRemote exists but is not a RemoteEvent")
end
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "AutoGrindRemote"
    remote.Parent = ReplicatedStorage
end

local states = {}
local lastRequestAt = {}

local function ensureIntValue(parent, name, defaultValue)
    local existing = parent:FindFirstChild(name)
    if existing then
        if existing:IsA("IntValue") then
            return existing
        end
        warn(("[AutoGrind] %s exists but is not an IntValue"):format(name))
        return nil
    end

    local value = Instance.new("IntValue")
    value.Name = name
    value.Value = defaultValue
    value.Parent = parent
    return value
end

local function getStats(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    return {
        Level = ensureIntValue(leaderstats, "Level", 1),
        Beli = ensureIntValue(leaderstats, "Beli", 0),
        XP = ensureIntValue(leaderstats, "XP", 0),
    }
end

local function getState(player)
    local state = states[player]
    if state then
        return state
    end

    state = {
        farmEnabled = false,
        autoQuest = false,
        targetMode = "Nearest",
        questId = nil,
        questKills = 0,
        status = "Pronto",
        loopRunning = false,
        currentTarget = nil,
        lastPathAt = 0,
        lastAttackAt = 0,
        lastStateAt = 0,
        credited = setmetatable({}, { __mode = "k" }),
        removed = false,
    }
    states[player] = state
    return state
end

local function getActiveQuest(state)
    if not state.questId then
        return nil
    end
    return Config.GetQuestById(state.questId)
end

local function ensureQuest(player, state)
    if not state.autoQuest or state.questId then
        return
    end

    local stats = getStats(player)
    local level = stats.Level and stats.Level.Value or 1
    local quest = Config.GetQuestForLevel(level)
    if quest then
        state.questId = quest.Id
        state.questKills = 0
        state.status = "Missão aceita: " .. quest.Name
    else
        state.status = "Nenhuma missão configurada para este nível"
    end
end

local function buildSnapshot(player, state)
    local stats = getStats(player)
    local quest = getActiveQuest(state)

    return {
        farmEnabled = state.farmEnabled,
        autoQuest = state.autoQuest,
        targetMode = state.targetMode,
        questName = quest and quest.Name or "Nenhuma",
        questProgress = state.questKills,
        questGoal = quest and quest.RequiredKills or 0,
        level = stats.Level and stats.Level.Value or 1,
        beli = stats.Beli and stats.Beli.Value or 0,
        xp = stats.XP and stats.XP.Value or 0,
        status = state.status,
    }
end

local function sendState(player)
    local state = states[player]
    if state and player.Parent then
        remote:FireClient(player, "State", buildSnapshot(player, state))
    end
end

local function addRewards(player, quest)
    local stats = getStats(player)
    if stats.Beli then
        stats.Beli.Value += quest.RewardBeli
    end

    if stats.XP and stats.Level then
        stats.XP.Value += quest.RewardXP
        while stats.Level.Value < 100 do
            local requiredXP = math.max(100, stats.Level.Value * 100)
            if stats.XP.Value < requiredXP then
                break
            end
            stats.XP.Value -= requiredXP
            stats.Level.Value += 1
        end
    end
end

local function registerKill(player, state, enemy)
    if not state.autoQuest then
        return
    end

    local quest = getActiveQuest(state)
    if not quest or enemy.Name ~= quest.EnemyName then
        return
    end

    state.questKills += 1
    if state.questKills >= quest.RequiredKills then
        addRewards(player, quest)
        state.status = ("Missão concluída: %s (+%d XP, +%d Beli)"):format(
            quest.Name,
            quest.RewardXP,
            quest.RewardBeli
        )
        state.questId = nil
        state.questKills = 0
    else
        state.status = ("Missão: %s (%d/%d)"):format(
            quest.Name,
            state.questKills,
            quest.RequiredKills
        )
    end
end

local function isFarmable(enemy)
    return enemy:GetAttribute("AutoFarmTarget") == true
        or CollectionService:HasTag(enemy, "FarmTarget")
end

local function isBoss(enemy)
    return enemy:GetAttribute("IsBoss") == true
        or CollectionService:HasTag(enemy, "FarmBoss")
end

local function findTarget(player, state, playerRoot)
    local enemiesFolder = Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then
        return nil
    end

    local quest = getActiveQuest(state)
    local bestTarget = nil
    local bestDistance = Config.TargetMaxDistance

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if not enemy:IsA("Model") or not isFarmable(enemy) then
            continue
        end

        local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
        if not enemyHumanoid or enemyHumanoid.Health <= 0 or not enemyRoot then
            continue
        end

        local eligible = true
        if state.autoQuest and quest then
            eligible = enemy.Name == quest.EnemyName
        elseif state.targetMode == "Boss" then
            eligible = isBoss(enemy)
        end

        if not eligible then
            continue
        end

        local distance = (enemyRoot.Position - playerRoot.Position).Magnitude
        if distance <= bestDistance then
            bestTarget = enemy
            bestDistance = distance
        end
    end

    return bestTarget
end

local function moveToward(humanoid, playerRoot, enemyRoot, state)
    local now = os.clock()
    if now - state.lastPathAt < Config.PathRecomputeInterval then
        return
    end
    state.lastPathAt = now

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 5,
    })

    local computed = pcall(function()
        path:ComputeAsync(playerRoot.Position, enemyRoot.Position)
    end)

    if computed and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local waypoint = waypoints[2] or waypoints[1]
        if waypoint then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid:MoveTo(waypoint.Position)
            return
        end
    end

    -- Fallback for simple/open arenas where pathfinding has no complete route.
    humanoid:MoveTo(enemyRoot.Position)
end

local function runFarmLoop(player, state)
    if state.loopRunning then
        return
    end
    state.loopRunning = true

    task.spawn(function()
        while player.Parent and states[player] == state and state.farmEnabled do
            if state.autoQuest then
                ensureQuest(player, state)
            end

            local character = player.Character
            local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
            local playerRoot = character and character:FindFirstChild("HumanoidRootPart")

            if not playerHumanoid or playerHumanoid.Health <= 0 or not playerRoot then
                state.status = "Aguardando personagem"
                state.currentTarget = nil
            else
                local target = findTarget(player, state, playerRoot)
                if not target then
                    state.status = "Nenhum alvo próximo elegível"
                    state.currentTarget = nil
                else
                    local enemyHumanoid = target:FindFirstChildOfClass("Humanoid")
                    local enemyRoot = target:FindFirstChild("HumanoidRootPart")

                    if not enemyHumanoid or enemyHumanoid.Health <= 0 or not enemyRoot then
                        state.currentTarget = nil
                    else
                        local distance = (enemyRoot.Position - playerRoot.Position).Magnitude
                        if distance > Config.AttackRange then
                            state.status = "Indo até " .. target.Name
                            if state.currentTarget ~= target then
                                state.lastPathAt = 0
                                state.currentTarget = target
                            end
                            moveToward(playerHumanoid, playerRoot, enemyRoot, state)
                        else
                            state.currentTarget = target
                            if os.clock() - state.lastAttackAt >= Config.AttackCooldown then
                                state.lastAttackAt = os.clock()
                                state.status = "Atacando " .. target.Name

                                local oldHealth = enemyHumanoid.Health
                                enemyHumanoid:TakeDamage(Config.AttackDamage)

                                if oldHealth > 0
                                    and enemyHumanoid.Health <= 0
                                    and not state.credited[target]
                                then
                                    state.credited[target] = true
                                    registerKill(player, state, target)
                                end
                            end
                        end
                    end
                end
            end

            if os.clock() - state.lastStateAt >= Config.StateUpdateInterval then
                state.lastStateAt = os.clock()
                sendState(player)
            end

            task.wait(Config.LoopInterval)
        end

        state.loopRunning = false
        if player.Parent and states[player] == state then
            if not state.farmEnabled then
                state.status = "Farm pausado"
            end
            sendState(player)
        end
    end)
end

local function teleportPlayer(player, destinationKey)
    if type(destinationKey) ~= "string" then
        return false
    end

    local destinationName = Config.Destinations[destinationKey]
    if not destinationName then
        return false
    end

    local destinations = Workspace:FindFirstChild("FarmDestinations")
    local destination = destinations and destinations:FindFirstChild(destinationName)
    if not destination or not destination:IsA("BasePart") then
        local state = getState(player)
        state.status = "Destino não configurado: " .. destinationName
        sendState(player)
        return false
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    root.CFrame = destination.CFrame + Vector3.new(0, 4, 0)
    local state = getState(player)
    state.status = "Chegou a " .. destinationKey
    sendState(player)
    return true
end

local function onRemote(player, action, value)
    local now = os.clock()
    local last = lastRequestAt[player] or 0
    if now - last < Config.RequestRateLimit then
        return
    end
    lastRequestAt[player] = now

    if type(action) ~= "string" then
        return
    end

    local state = getState(player)

    if action == "GetState" then
        sendState(player)
        return
    end

    if action == "SetFarm" then
        if type(value) ~= "boolean" then
            return
        end
        state.farmEnabled = value
        if value then
            runFarmLoop(player, state)
        else
            state.status = "Farm pausado"
        end
        sendState(player)
        return
    end

    if action == "SetQuest" then
        if type(value) ~= "boolean" then
            return
        end
        state.autoQuest = value
        if value then
            ensureQuest(player, state)
        else
            state.questId = nil
            state.questKills = 0
            state.status = "Auto Quest desativado"
        end
        sendState(player)
        return
    end

    if action == "SetTarget" then
        if value ~= "Nearest" and value ~= "Boss" then
            return
        end
        state.targetMode = value
        state.currentTarget = nil
        state.lastPathAt = 0
        state.status = "Alvo: " .. value
        sendState(player)
        return
    end

    if action == "Teleport" then
        teleportPlayer(player, value)
        return
    end

    if action == "StopAll" then
        state.farmEnabled = false
        state.autoQuest = false
        state.questId = nil
        state.questKills = 0
        state.currentTarget = nil
        state.status = "Todos os módulos pausados"
        sendState(player)
    end
end

remote.OnServerEvent:Connect(onRemote)

local function onPlayerAdded(player)
    getStats(player)
    local state = getState(player)
    player.CharacterAdded:Connect(function()
        task.delay(1, function()
            if player.Parent then
                sendState(player)
                if state.farmEnabled then
                    runFarmLoop(player, state)
                end
            end
        end)
    end)
    task.delay(1, function()
        if player.Parent then
            sendState(player)
        end
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local state = states[player]
    if state then
        state.removed = true
        state.farmEnabled = false
    end
    states[player] = nil
    lastRequestAt[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

print("[BloxGrindStudio] Server ready.")
