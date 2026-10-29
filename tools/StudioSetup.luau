-- Luau | Roblox Studio Command Bar | creates demo content for BloxGrindStudio
-- Paste into View > Command Bar in a place you own. Existing objects are preserved.

local Workspace = game:GetService("Workspace")

local function getOrCreateFolder(parent, name)
    local found = parent:FindFirstChild(name)
    if found and found:IsA("Folder") then
        return found
    end
    if found then
        error(("%s exists but is not a Folder"):format(found:GetFullName()))
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

local function makePoint(folder, name, position, color)
    local found = folder:FindFirstChild(name)
    if found and found:IsA("BasePart") then
        return found
    elseif found then
        warn(("[BloxGrindStudio] Keeping existing object %s"):format(found:GetFullName()))
        return nil
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(8, 1, 8)
    part.Position = position
    part.Anchored = true
    part.CanCollide = true
    part.Material = Enum.Material.Neon
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Label"
    billboard.Size = UDim2.fromOffset(150, 28)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.35
    label.TextScaled = true
    label.Parent = billboard

    return part
end

local function makeDummyPart(parent, name, size, cframe, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = true
    part.Material = Enum.Material.SmoothPlastic
    part.Color = color
    part.Transparency = transparency or 0
    part.Parent = parent
    return part
end

local function attachRespawn(model, enemiesFolder)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local template = model:Clone()
    template.Parent = nil

    humanoid.Died:Connect(function()
        task.delay(5, function()
            if not enemiesFolder.Parent then
                template:Destroy()
                return
            end

            local replacement = template:Clone()
            replacement.Parent = enemiesFolder
            attachRespawn(replacement, enemiesFolder)
        end)
    end)
end

local function createDemoNpc(enemiesFolder, name, position, color, isBoss)
    local existing = enemiesFolder:FindFirstChild(name)
    if existing then
        return
    end

    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("AutoFarmTarget", true)
    model:SetAttribute("IsBoss", isBoss == true)

    local root = makeDummyPart(
        model, "HumanoidRootPart", Vector3.new(2, 2, 1),
        CFrame.new(position + Vector3.new(0, 3, 0)),
        Color3.new(1, 1, 1), 1
    )
    local torso = makeDummyPart(
        model, "Torso", Vector3.new(2, 2, 1),
        root.CFrame, color
    )
    local head = makeDummyPart(
        model, "Head", Vector3.new(1.4, 1.4, 1.4),
        root.CFrame * CFrame.new(0, 1.7, 0),
        Color3.fromRGB(238, 198, 154)
    )
    local leftArm = makeDummyPart(
        model, "Left Arm", Vector3.new(0.8, 2, 0.8),
        root.CFrame * CFrame.new(-1.4, 0, 0), color
    )
    local rightArm = makeDummyPart(
        model, "Right Arm", Vector3.new(0.8, 2, 0.8),
        root.CFrame * CFrame.new(1.4, 0, 0), color
    )
    local leftLeg = makeDummyPart(
        model, "Left Leg", Vector3.new(0.9, 2, 0.9),
        root.CFrame * CFrame.new(-0.5, -1.8, 0), color
    )
    local rightLeg = makeDummyPart(
        model, "Right Leg", Vector3.new(0.9, 2, 0.9),
        root.CFrame * CFrame.new(0.5, -1.8, 0), color
    )

    -- Welds keep the display dummy assembled. This is a stationary test target,
    -- not an animated NPC rig; replace it with your own rig for a production game.
    for _, part in ipairs({ torso, head, leftArm, rightArm, leftLeg, rightLeg }) do
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = part
        weld.Parent = root
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.Name = "Humanoid"
    humanoid.RequiresNeck = false
    humanoid.BreakJointsOnDeath = false
    humanoid.MaxHealth = isBoss and 450 or 100
    humanoid.Health = humanoid.MaxHealth
    humanoid.DisplayName = name
    humanoid.Parent = model

    model.PrimaryPart = root
    model.Parent = enemiesFolder
    attachRespawn(model, enemiesFolder)
end

local enemies = getOrCreateFolder(Workspace, "Enemies")
local destinations = getOrCreateFolder(Workspace, "FarmDestinations")
local collectibles = getOrCreateFolder(Workspace, "Collectibles")

makePoint(destinations, "SpawnPoint", Vector3.new(0, 0.5, 0), Color3.fromRGB(0, 220, 180))
makePoint(destinations, "QuestBoard", Vector3.new(0, 0.5, -18), Color3.fromRGB(100, 180, 255))
makePoint(destinations, "BossArena", Vector3.new(0, 0.5, -48), Color3.fromRGB(255, 130, 80))

createDemoNpc(enemies, "Bandit", Vector3.new(14, 0, -18), Color3.fromRGB(190, 100, 75), false)
createDemoNpc(enemies, "Desert Bandit", Vector3.new(-14, 0, -25), Color3.fromRGB(220, 170, 90), false)
createDemoNpc(enemies, "Ice Guard", Vector3.new(14, 0, -37), Color3.fromRGB(115, 180, 235), false)
createDemoNpc(enemies, "Demo Boss", Vector3.new(0, 0, -55), Color3.fromRGB(175, 100, 240), true)

local function makeCollectible(folder, name, position, color)
    if folder:FindFirstChild(name) then
        return
    end

    local fruit = Instance.new("Part")
    fruit.Name = name
    fruit.Shape = Enum.PartType.Ball
    fruit.Size = Vector3.new(2.4, 2.4, 2.4)
    fruit.Position = position + Vector3.new(0, 2.5, 0)
    fruit.Anchored = true
    fruit.CanCollide = false
    fruit.Material = Enum.Material.Neon
    fruit.Color = color
    fruit.Parent = folder

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 1.3
    light.Range = 9
    light.Parent = fruit

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Label"
    billboard.Size = UDim2.fromOffset(150, 28)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = fruit

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.35
    label.TextScaled = true
    label.Parent = billboard
end

makeCollectible(collectibles, "Demo Fruit - Flame", Vector3.new(9, 0, -9), Color3.fromRGB(255, 105, 40))
makeCollectible(collectibles, "Demo Fruit - Ice", Vector3.new(-9, 0, -9), Color3.fromRGB(80, 200, 255))

print("[BloxGrindStudio] Demo setup ready. Replace stationary dummy NPCs with rigged NPC models for production.")
