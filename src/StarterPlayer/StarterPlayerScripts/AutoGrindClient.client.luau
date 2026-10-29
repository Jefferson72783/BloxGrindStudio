-- Luau | StarterPlayerScripts | Roblox Studio | LocalScript
-- UI and visual helpers for an experience you own. Gameplay actions are checked on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("AutoGrindRemote")

local theme = {
    background = Color3.fromRGB(15, 20, 32),
    sidebar = Color3.fromRGB(18, 26, 41),
    panel = Color3.fromRGB(24, 33, 50),
    panelSoft = Color3.fromRGB(29, 40, 59),
    accent = Color3.fromRGB(0, 218, 180),
    accentDim = Color3.fromRGB(18, 87, 84),
    text = Color3.fromRGB(241, 246, 252),
    muted = Color3.fromRGB(145, 160, 180),
    border = Color3.fromRGB(48, 63, 84),
    danger = Color3.fromRGB(235, 90, 104),
}

local serverState = {
    farmEnabled = false,
    autoQuest = false,
    targetMode = "Nearest",
    questName = "Carregando...",
    questProgress = 0,
    questGoal = 0,
    level = 1,
    beli = 0,
    xp = 0,
    status = "Conectando ao servidor...",
}
local clientState = {
    enemyEsp = false,
    fruitFinder = false,
}
local toggleWidgets = {}
local navigationButtons = {}
local pageFrames = {}
local highlightHandles = {}
local metricLabels = {}
local statusLabel
local questLabel
local targetLabel

local function make(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(parent, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 10),
    }, parent)
end

local function addStroke(parent, color, transparency)
    make("UIStroke", {
        Color = color or theme.border,
        Transparency = transparency or 0,
        Thickness = 1,
    }, parent)
end

local function addLabel(parent, text, size, position, fontSize, color, bold)
    return make("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = size,
        Position = position,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or theme.text,
        TextSize = fontSize or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

local function addButton(parent, text, size, position, callback, primary)
    local button = make("TextButton", {
        Name = "ActionButton",
        Size = size,
        Position = position,
        BackgroundColor3 = primary and theme.accent or theme.panelSoft,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = primary and theme.background or theme.text,
        TextSize = 12,
    }, parent)
    addCorner(button, 8)
    button.Activated:Connect(callback)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = primary and Color3.fromRGB(70, 238, 205) or theme.border
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = primary and theme.accent or theme.panelSoft
    end)
    return button
end

local gui = make("ScreenGui", {
    Name = "BloxGrindStudioGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = false,
}, playerGui)

local main = make("Frame", {
    Name = "MainWindow",
    Size = UDim2.fromOffset(760, 500),
    Position = UDim2.new(0.5, -380, 0.5, -250),
    BackgroundColor3 = theme.background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
addCorner(main, 14)
addStroke(main, theme.border, 0.15)

local sidebar = make("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 170, 1, 0),
    BackgroundColor3 = theme.sidebar,
    BorderSizePixel = 0,
}, main)

addLabel(sidebar, "BLOX", UDim2.new(1, -28, 0, 29), UDim2.fromOffset(20, 20), 24, theme.accent, true)
addLabel(sidebar, "GRIND STUDIO", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(21, 48), 10, theme.muted, true)
make("Frame", {
    Size = UDim2.new(1, -36, 0, 1),
    Position = UDim2.fromOffset(18, 78),
    BackgroundColor3 = theme.border,
    BorderSizePixel = 0,
}, sidebar)

local navArea = make("Frame", {
    Name = "Navigation",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(10, 95),
    Size = UDim2.new(1, -20, 0, 250),
}, sidebar)
make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, navArea)

local contentHeader = make("Frame", {
    Name = "Header",
    Position = UDim2.fromOffset(170, 0),
    Size = UDim2.new(1, -170, 0, 70),
    BackgroundTransparency = 1,
}, main)
addLabel(contentHeader, "Control Panel", UDim2.new(1, -160, 0, 26), UDim2.fromOffset(22, 14), 20, theme.text, true)
addLabel(contentHeader, "STUDIO TOOLKIT  /  CLIENT STATUS", UDim2.new(1, -170, 0, 16), UDim2.fromOffset(23, 42), 9, theme.muted, true)

local hideButton = addButton(
    contentHeader, "—", UDim2.fromOffset(34, 30), UDim2.new(1, -78, 0, 19),
    function() main.Visible = false end, false
)
hideButton.TextSize = 16
local closeButton = addButton(
    contentHeader, "×", UDim2.fromOffset(30, 30), UDim2.new(1, -38, 0, 19),
    function() main.Visible = false end, false
)
closeButton.TextSize = 18

local pageHost = make("Frame", {
    Name = "PageHost",
    Position = UDim2.fromOffset(186, 78),
    Size = UDim2.new(1, -202, 1, -94),
    BackgroundTransparency = 1,
}, main)

local function createPage(name, order)
    local page = make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
        LayoutOrder = order,
    }, pageHost)
    make("UIPadding", {
        PaddingTop = UDim.new(0, 3),
        PaddingBottom = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 6),
    }, page)
    make("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    pageFrames[name] = page
    return page
end

local function addPageHeading(page, title, description)
    local frame = make("Frame", {
        Name = "PageHeading",
        Size = UDim2.new(1, -6, 0, 48),
        BackgroundTransparency = 1,
    }, page)
    addLabel(frame, title, UDim2.new(1, 0, 0, 25), UDim2.fromOffset(0, 0), 17, theme.text, true)
    addLabel(frame, description, UDim2.new(1, 0, 0, 19), UDim2.fromOffset(0, 26), 10, theme.muted, false)
    return frame
end

local function addCard(page, height)
    local card = make("Frame", {
        Name = "Card",
        Size = UDim2.new(1, -6, 0, height),
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
    }, page)
    addCorner(card, 11)
    addStroke(card, theme.border, 0.35)
    return card
end

local function updateToggleWidget(key, enabled)
    local widget = toggleWidgets[key]
    if not widget then
        return
    end
    widget.enabled = enabled
    widget.button.Text = enabled and "ON" or "OFF"
    widget.button.BackgroundColor3 = enabled and theme.accentDim or theme.panelSoft
    widget.button.TextColor3 = enabled and theme.accent or theme.muted
end

local function addToggleRow(page, title, description, key, initialValue, callback)
    local row = make("Frame", {
        Name = "ToggleRow",
        Size = UDim2.new(1, -6, 0, 66),
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
    }, page)
    addCorner(row, 10)
    addStroke(row, theme.border, 0.45)
    addLabel(row, title, UDim2.new(1, -115, 0, 24), UDim2.fromOffset(14, 9), 12, theme.text, true)
    addLabel(row, description, UDim2.new(1, -115, 0, 24), UDim2.fromOffset(14, 32), 10, theme.muted, false)

    local button = addButton(
        row, initialValue and "ON" or "OFF",
        UDim2.fromOffset(64, 31), UDim2.new(1, -78, 0.5, -15),
        function()
            local widget = toggleWidgets[key]
            local enabled = not widget.enabled
            updateToggleWidget(key, enabled)
            callback(enabled)
        end,
        false
    )

    toggleWidgets[key] = { button = button, enabled = initialValue }
    updateToggleWidget(key, initialValue)
    return row
end

local function addTextCard(page, title, text, height)
    local card = addCard(page, height or 78)
    addLabel(card, title, UDim2.new(1, -24, 0, 22), UDim2.fromOffset(14, 9), 12, theme.text, true)
    local detail = addLabel(card, text, UDim2.new(1, -24, 1, -34), UDim2.fromOffset(14, 32), 10, theme.muted, false)
    return card, detail
end

local function addDestinationRow(page, title, description, destinationKey)
    local row = make("Frame", {
        Name = "DestinationRow",
        Size = UDim2.new(1, -6, 0, 66),
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
    }, page)
    addCorner(row, 10)
    addStroke(row, theme.border, 0.45)
    addLabel(row, title, UDim2.new(1, -135, 0, 22), UDim2.fromOffset(14, 9), 12, theme.text, true)
    addLabel(row, description, UDim2.new(1, -135, 0, 20), UDim2.fromOffset(14, 32), 10, theme.muted, false)
    addButton(row, "IR", UDim2.fromOffset(76, 32), UDim2.new(1, -90, 0.5, -16), function()
        remote:FireServer("Teleport", destinationKey)
    end, true)
end

local function addTargetSelector(page)
    local row = make("Frame", {
        Name = "TargetSelector",
        Size = UDim2.new(1, -6, 0, 72),
        BackgroundColor3 = theme.panel,
        BorderSizePixel = 0,
    }, page)
    addCorner(row, 10)
    addStroke(row, theme.border, 0.45)
    addLabel(row, "Filtro de alvo", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(14, 7), 12, theme.text, true)
    targetLabel = addLabel(row, "Atual: Nearest", UDim2.new(1, -210, 0, 19), UDim2.fromOffset(14, 36), 10, theme.muted, false)
    addButton(row, "NEAREST", UDim2.fromOffset(86, 30), UDim2.new(1, -190, 0, 31), function()
        remote:FireServer("SetTarget", "Nearest")
    end, false)
    addButton(row, "BOSSES", UDim2.fromOffset(82, 30), UDim2.new(1, -96, 0, 31), function()
        remote:FireServer("SetTarget", "Boss")
    end, true)
end

local overview = createPage("Overview", 1)
addPageHeading(overview, "Visão geral", "Resumo rápido da sessão atual.")
local _, heroStatus = addTextCard(
    overview, "ESTADO DO SISTEMA", "Conectando ao servidor...", 72
)
statusLabel = heroStatus

local metricCard = addCard(overview, 88)
local metricNames = {
    { key = "level", title = "LEVEL" },
    { key = "beli", title = "BELI" },
    { key = "xp", title = "XP" },
}
for index, metric in ipairs(metricNames) do
    local x = 12 + (index - 1) * 174
    addLabel(metricCard, metric.title, UDim2.fromOffset(150, 20), UDim2.fromOffset(x, 13), 9, theme.muted, true)
    metricLabels[metric.key] = addLabel(
        metricCard, "—", UDim2.fromOffset(150, 32), UDim2.fromOffset(x, 36), 20, theme.accent, true
    )
end

local _, questDetail = addTextCard(
    overview, "MISSÃO ATIVA", "Aguardando dados...", 72
)
questLabel = questDetail

local farmPage = createPage("Farm", 2)
addPageHeading(farmPage, "Farm", "Recursos de gameplay do seu próprio place.")
addToggleRow(
    farmPage, "Auto Farm", "Persegue alvos elegíveis e ataca dentro do alcance definido.",
    "farmEnabled", false,
    function(enabled) remote:FireServer("SetFarm", enabled) end
)
addToggleRow(
    farmPage, "Auto Quest", "Aceita missões configuradas e contabiliza eliminações elegíveis.",
    "autoQuest", false,
    function(enabled) remote:FireServer("SetQuest", enabled) end
)
addTargetSelector(farmPage)
addTextCard(
    farmPage, "REQUISITOS", "NPCs em Workspace/Enemies com Humanoid, HumanoidRootPart e AutoFarmTarget=true.", 72
)

local visualsPage = createPage("Visuals", 3)
addPageHeading(visualsPage, "Visuals", "Destaques locais para NPCs e coletáveis do seu mapa.")
addToggleRow(
    visualsPage, "Enemy Highlights", "Destaca modelos dentro de Workspace/Enemies.",
    "enemyEsp", false,
    function(enabled) clientState.enemyEsp = enabled end
)
addToggleRow(
    visualsPage, "Fruit / Item Finder", "Destaca objetos em Workspace/Collectibles.",
    "fruitFinder", false,
    function(enabled) clientState.fruitFinder = enabled end
)
addTextCard(
    visualsPage, "COMO FUNCIONA", "Os efeitos são locais à sua interface e só leem pastas presentes no place atual.", 74
)

local travelPage = createPage("Travel", 4)
addPageHeading(travelPage, "Travel", "Viaje apenas para destinos definidos no Workspace.")
addDestinationRow(travelPage, "Spawn", "Ponto inicial configurado pelo desenvolvedor.", "Spawn")
addDestinationRow(travelPage, "Quest Board", "Local configurado para iniciar missões.", "QuestBoard")
addDestinationRow(travelPage, "Boss Arena", "Arena de chefes criada no seu mapa.", "BossArena")
addTextCard(
    travelPage, "CONFIGURAÇÃO", "Crie Workspace/FarmDestinations e adicione SpawnPoint, QuestBoard e BossArena.", 72
)

local settingsPage = createPage("Settings", 5)
addPageHeading(settingsPage, "Settings", "Controles gerais e atalho de interface.")
addTextCard(
    settingsPage, "ATALHO", "Pressione RightShift para mostrar ou ocultar esta janela.", 68
)
local stopCard = addCard(settingsPage, 76)
addLabel(stopCard, "Desligar módulos", UDim2.new(1, -135, 0, 22), UDim2.fromOffset(14, 9), 12, theme.text, true)
addLabel(stopCard, "Pausa o farm e a seleção automática de missões.", UDim2.new(1, -135, 0, 24), UDim2.fromOffset(14, 34), 10, theme.muted, false)
addButton(stopCard, "STOP ALL", UDim2.fromOffset(98, 34), UDim2.new(1, -112, 0.5, -17), function()
    clientState.enemyEsp = false
    clientState.fruitFinder = false
    updateToggleWidget("enemyEsp", false)
    updateToggleWidget("fruitFinder", false)
    remote:FireServer("StopAll")
end, false)
local hideCard = addCard(settingsPage, 64)
addLabel(hideCard, "Ocultar interface", UDim2.new(1, -132, 1, 0), UDim2.fromOffset(14, 0), 12, theme.text, true)
addButton(hideCard, "HIDE", UDim2.fromOffset(82, 32), UDim2.new(1, -96, 0.5, -16), function()
    main.Visible = false
end, false)

local function selectPage(name)
    for pageName, page in pairs(pageFrames) do
        page.Visible = pageName == name
    end
    for pageName, button in pairs(navigationButtons) do
        local selected = pageName == name
        button.BackgroundColor3 = selected and theme.accentDim or theme.sidebar
        button.TextColor3 = selected and theme.accent or theme.muted
    end
end

local navItems = {
    { name = "Overview", label = "⌂   Overview" },
    { name = "Farm", label = "⚔   Farm" },
    { name = "Visuals", label = "◎   Visuals" },
    { name = "Travel", label = "↗   Travel" },
    { name = "Settings", label = "⚙   Settings" },
}
for index, item in ipairs(navItems) do
    local button = make("TextButton", {
        Name = item.name .. "Nav",
        Size = UDim2.new(1, 0, 0, 39),
        BackgroundColor3 = theme.sidebar,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = item.label,
        TextSize = 11,
        TextColor3 = theme.muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = index,
    }, navArea)
    addCorner(button, 8)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
    }, button)
    navigationButtons[item.name] = button
    button.Activated:Connect(function()
        selectPage(item.name)
    end)
end

addLabel(sidebar, "BUILD  0.1.0", UDim2.new(1, -24, 0, 20), UDim2.new(0, 18, 1, -42), 9, theme.muted, true)
selectPage("Overview")

local function formatNumber(number)
    local value = tostring(math.floor(tonumber(number) or 0))
    local negative = value:sub(1, 1) == "-"
    if negative then
        value = value:sub(2)
    end

    local formatted = value:reverse():gsub("(%d%d%d)", "%1."):reverse()
    formatted = formatted:gsub("^%.", ""):gsub("%.$", "")
    return (negative and "-" or "") .. formatted
end

local function applyServerState(newState)
    if type(newState) ~= "table" then
        return
    end
    serverState = newState

    if statusLabel then
        statusLabel.Text = tostring(serverState.status or "—")
    end
    if questLabel then
        local goal = tonumber(serverState.questGoal) or 0
        local progress = tonumber(serverState.questProgress) or 0
        questLabel.Text = ("%s  |  %d/%d"):format(
            tostring(serverState.questName or "Nenhuma"), progress, goal
        )
    end
    if metricLabels.level then
        metricLabels.level.Text = formatNumber(serverState.level)
    end
    if metricLabels.beli then
        metricLabels.beli.Text = formatNumber(serverState.beli)
    end
    if metricLabels.xp then
        metricLabels.xp.Text = formatNumber(serverState.xp)
    end
    if targetLabel then
        targetLabel.Text = "Atual: " .. tostring(serverState.targetMode or "Nearest")
    end

    updateToggleWidget("farmEnabled", serverState.farmEnabled == true)
    updateToggleWidget("autoQuest", serverState.autoQuest == true)
end

remote.OnClientEvent:Connect(function(action, payload)
    if action == "State" then
        applyServerState(payload)
    end
end)

local function collectDesiredHighlights()
    local desired = {}

    if clientState.enemyEsp then
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, object in ipairs(enemies:GetChildren()) do
                if object:IsA("Model") and (
                    object:GetAttribute("AutoFarmTarget") == true
                    or CollectionService:HasTag(object, "FarmTarget")
                ) then
                    desired[object] = {
                        fill = Color3.fromRGB(0, 218, 180),
                        outline = Color3.fromRGB(205, 255, 243),
                    }
                end
            end
        end
    end

    if clientState.fruitFinder then
        local collectibles = Workspace:FindFirstChild("Collectibles")
        if collectibles then
            for _, object in ipairs(collectibles:GetChildren()) do
                if object:IsA("Model") or object:IsA("BasePart") then
                    desired[object] = {
                        fill = Color3.fromRGB(255, 190, 70),
                        outline = Color3.fromRGB(255, 240, 190),
                    }
                end
            end
        end
    end

    return desired
end

local function refreshHighlights()
    local desired = collectDesiredHighlights()

    for object, highlight in pairs(highlightHandles) do
        if not object.Parent or not desired[object] then
            highlight:Destroy()
            highlightHandles[object] = nil
        end
    end

    for object, colors in pairs(desired) do
        local highlight = highlightHandles[object]
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "BGS_LocalHighlight"
            highlight.Adornee = object
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = Workspace
            highlightHandles[object] = highlight
        end
        highlight.FillColor = colors.fill
        highlight.OutlineColor = colors.outline
        highlight.FillTransparency = 0.68
        highlight.OutlineTransparency = 0.08
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

task.spawn(function()
    while gui.Parent do
        refreshHighlights()
        task.wait(0.6)
    end
end)

task.spawn(function()
    while gui.Parent do
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local level = leaderstats:FindFirstChild("Level")
            local beli = leaderstats:FindFirstChild("Beli")
            local xp = leaderstats:FindFirstChild("XP")
            if level then metricLabels.level.Text = formatNumber(level.Value) end
            if beli then metricLabels.beli.Text = formatNumber(beli.Value) end
            if xp then metricLabels.xp.Text = formatNumber(xp.Value) end
        end
        task.wait(1)
    end
end)

remote:FireServer("GetState")
print("[BloxGrindStudio] Client UI ready.")
