--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")

local Footballers = require(Config:WaitForChild("Footballers"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local Formations = require(Config:WaitForChild("Formations"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetProfile = Remotes:WaitForChild("GetProfile") :: RemoteFunction
local StartDraft = Remotes:WaitForChild("StartDraft") :: RemoteFunction
local SelectFootballer = Remotes:WaitForChild("SelectFootballer") :: RemoteFunction

local existingGui = playerGui:FindFirstChild("DraftPrototype")
if existingGui then
    existingGui:Destroy()
end

local footballersById: { [string]: any } = {}
for _, footballer in ipairs(Footballers) do
    footballersById[footballer.Id] = footballer
end

local RARITY_THEME = {
    Common = {
        Primary = Color3.fromRGB(80, 90, 110),
        Secondary = Color3.fromRGB(52, 60, 75),
        Accent = Color3.fromRGB(170, 182, 198),
    },
    Rare = {
        Primary = Color3.fromRGB(44, 102, 205),
        Secondary = Color3.fromRGB(25, 63, 138),
        Accent = Color3.fromRGB(158, 201, 255),
    },
    Epic = {
        Primary = Color3.fromRGB(139, 69, 196),
        Secondary = Color3.fromRGB(86, 39, 128),
        Accent = Color3.fromRGB(220, 186, 255),
    },
    Legendary = {
        Primary = Color3.fromRGB(225, 149, 33),
        Secondary = Color3.fromRGB(151, 95, 12),
        Accent = Color3.fromRGB(255, 223, 158),
    },
    Icon = {
        Primary = Color3.fromRGB(219, 214, 189),
        Secondary = Color3.fromRGB(145, 133, 96),
        Accent = Color3.fromRGB(255, 246, 209),
    },
}

local function create(className: string, props: { [string]: any }?, parent: Instance?): Instance
    local instance = Instance.new(className)

    if props then
        for key, value in pairs(props) do
            (instance :: any)[key] = value
        end
    end

    if parent then
        instance.Parent = parent
    end

    return instance
end

local function addCorner(target: Instance, radius: number)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius),
    }, target)
end

local function addStroke(target: Instance, color: Color3, thickness: number, transparency: number?)
    create("UIStroke", {
        Color = color,
        Thickness = thickness,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, target)
end

local function addPadding(target: Instance, left: number, right: number, top: number, bottom: number)
    create("UIPadding", {
        PaddingLeft = UDim.new(0, left),
        PaddingRight = UDim.new(0, right),
        PaddingTop = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom),
    }, target)
end

local function addGradient(target: Instance, colorA: Color3, colorB: Color3, rotation: number?)
    local gradient = create("UIGradient", {
        Rotation = rotation or 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, colorA),
            ColorSequenceKeypoint.new(1, colorB),
        }),
    }, target)

    return gradient
end

local function getTheme(rarity: string)
    return RARITY_THEME[rarity] or RARITY_THEME.Common
end

local function getInitials(fullName: string): string
    local initials = {}

    for token in string.gmatch(fullName, "[^%s]+") do
        local character = string.sub(token, 1, 1)
        if character ~= "" then
            table.insert(initials, string.upper(character))
        end
    end

    if #initials == 0 then
        return "?"
    end

    if #initials == 1 then
        return initials[1]
    end

    return initials[1] .. initials[2]
end

local function invokeServer(remoteFunction: RemoteFunction, ...: any): (boolean, any)
    local arguments = table.pack(...)

    return pcall(function()
        return remoteFunction:InvokeServer(table.unpack(arguments, 1, arguments.n))
    end)
end

local screenGui = create("ScreenGui", {
    Name = "DraftPrototype",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local background = create("Frame", {
    Name = "Background",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(9, 13, 21),
    BorderSizePixel = 0,
}, screenGui)

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundColor3 = Color3.fromRGB(17, 23, 35),
    BorderSizePixel = 0,
}, background)

local titleLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 12),
    Size = UDim2.fromOffset(520, 30),
    Font = Enum.Font.GothamBlack,
    Text = "BUILD A FOOTBALL DYNASTY",
    TextColor3 = Color3.fromRGB(248, 248, 248),
    TextSize = 26,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local subtitleLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 42),
    Size = UDim2.fromOffset(520, 22),
    Font = Enum.Font.Gotham,
    Text = "11-player draft • formation board • collectible card picks",
    TextColor3 = Color3.fromRGB(157, 170, 189),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local coinsLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -24, 16, 0),
    Size = UDim2.fromOffset(220, 28),
    Font = Enum.Font.GothamBold,
    Text = "Coins: ...",
    TextColor3 = Color3.fromRGB(255, 220, 96),
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Right,
}, header)

local clubSummaryLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -24, 44, 0),
    Size = UDim2.fromOffset(320, 20),
    Font = Enum.Font.Gotham,
    Text = "Club loading...",
    TextColor3 = Color3.fromRGB(178, 188, 206),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Right,
}, header)

local topArea = create("Frame", {
    Name = "TopArea",
    Position = UDim2.fromOffset(0, 76),
    Size = UDim2.new(1, 0, 0.58, 0),
    BackgroundTransparency = 1,
}, background)

local pitchPanel = create("Frame", {
    Name = "PitchPanel",
    Position = UDim2.fromOffset(22, 18),
    Size = UDim2.new(0.60, -32, 1, -36),
    BackgroundColor3 = Color3.fromRGB(15, 79, 40),
    BorderSizePixel = 0,
}, topArea)
addCorner(pitchPanel, 18)
addStroke(pitchPanel, Color3.fromRGB(255, 255, 255), 1, 0.88)
addGradient(pitchPanel, Color3.fromRGB(17, 92, 47), Color3.fromRGB(8, 54, 26), 90)

local pitchInner = create("Frame", {
    Name = "PitchInner",
    Position = UDim2.fromOffset(14, 14),
    Size = UDim2.new(1, -28, 1, -28),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
}, pitchPanel)

local function createPitchLine(props: { [string]: any })
    local line = create("Frame", props, pitchInner)
    line.BorderSizePixel = 0
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BackgroundTransparency = 0.55
    return line
end

createPitchLine({
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.fromScale(0.5, 0.03),
    Size = UDim2.new(0.92, 0, 0, 2),
})

createPitchLine({
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.fromScale(0.5, 0.97),
    Size = UDim2.new(0.92, 0, 0, 2),
})

createPitchLine({
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.fromScale(0.04, 0.5),
    Size = UDim2.new(0, 2, 0.94, 0),
})

createPitchLine({
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.fromScale(0.96, 0.5),
    Size = UDim2.new(0, 2, 0.94, 0),
})

createPitchLine({
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.92, 0, 0, 2),
})

local centreCircle = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(112, 112),
    BackgroundTransparency = 1,
}, pitchInner)
addCorner(centreCircle, 999)
addStroke(centreCircle, Color3.fromRGB(255, 255, 255), 2, 0.55)

local topBox = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.fromScale(0.5, 0.03),
    Size = UDim2.new(0.36, 0, 0.17, 0),
    BackgroundTransparency = 1,
}, pitchInner)
addStroke(topBox, Color3.fromRGB(255, 255, 255), 2, 0.55)

local bottomBox = create("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.fromScale(0.5, 0.97),
    Size = UDim2.new(0.36, 0, 0.17, 0),
    BackgroundTransparency = 1,
}, pitchInner)
addStroke(bottomBox, Color3.fromRGB(255, 255, 255), 2, 0.55)

local sidePanel = create("Frame", {
    Name = "SidePanel",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -22, 18, 0),
    Size = UDim2.new(0.40, -12, 1, -36),
    BackgroundColor3 = Color3.fromRGB(18, 24, 36),
    BorderSizePixel = 0,
}, topArea)
addCorner(sidePanel, 18)
addStroke(sidePanel, Color3.fromRGB(255, 255, 255), 1, 0.92)

local formationLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 16),
    Size = UDim2.new(1, -36, 0, 26),
    Font = Enum.Font.GothamBold,
    Text = "FORMATION: 4-3-3",
    TextColor3 = Color3.fromRGB(250, 250, 250),
    TextSize = 19,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidePanel)

local draftStatusLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 46),
    Size = UDim2.new(1, -36, 0, 50),
    Font = Enum.Font.Gotham,
    Text = "Open a draft to begin building your XI.",
    TextColor3 = Color3.fromRGB(188, 198, 216),
    TextSize = 15,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, sidePanel)

local actionButton = create("TextButton", {
    Position = UDim2.fromOffset(18, 106),
    Size = UDim2.new(1, -36, 0, 46),
    BackgroundColor3 = Color3.fromRGB(42, 164, 98),
    BorderSizePixel = 0,
    Font = Enum.Font.GothamBold,
    Text = string.format("START 11-PLAYER DRAFT — %d COINS", GameConfig.DraftCost),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 15,
}, sidePanel)
addCorner(actionButton, 10)

local noteLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 162),
    Size = UDim2.new(1, -36, 0, 48),
    Font = Enum.Font.Gotham,
    Text = "Each pick fills one slot on the pitch. The highlighted slot is the current position being drafted.",
    TextColor3 = Color3.fromRGB(154, 167, 187),
    TextSize = 13,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, sidePanel)

local currentPickTitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 220),
    Size = UDim2.new(1, -36, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "CURRENT PICK",
    TextColor3 = Color3.fromRGB(250, 250, 250),
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidePanel)

local currentPickCardHost = create("Frame", {
    Position = UDim2.fromOffset(18, 250),
    Size = UDim2.new(1, -36, 0, 180),
    BackgroundColor3 = Color3.fromRGB(23, 31, 46),
    BorderSizePixel = 0,
}, sidePanel)
addCorner(currentPickCardHost, 14)

local currentPickMessage = create("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "No draft active",
    TextColor3 = Color3.fromRGB(186, 198, 216),
    TextSize = 18,
    TextWrapped = true,
}, currentPickCardHost)

local recentClubTitle = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(18, 442),
    Size = UDim2.new(1, -36, 0, 22),
    Font = Enum.Font.GothamBold,
    Text = "RECENT CLUB PLAYERS",
    TextColor3 = Color3.fromRGB(250, 250, 250),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidePanel)

local recentClubLabel = create("TextLabel", {
    Position = UDim2.fromOffset(18, 470),
    Size = UDim2.new(1, -36, 1, -488),
    BackgroundColor3 = Color3.fromRGB(23, 31, 46),
    BorderSizePixel = 0,
    Font = Enum.Font.Gotham,
    Text = "No players owned yet.",
    TextColor3 = Color3.fromRGB(202, 209, 223),
    TextSize = 14,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, sidePanel)
addCorner(recentClubLabel, 12)
addPadding(recentClubLabel, 12, 12, 10, 10)

local bottomArea = create("Frame", {
    Name = "BottomArea",
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.fromScale(0.5, 1),
    Size = UDim2.new(1, 0, 0.42, 0),
    BackgroundColor3 = Color3.fromRGB(12, 17, 27),
    BorderSizePixel = 0,
}, background)

local optionsHeader = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 12),
    Size = UDim2.new(1, -44, 0, 26),
    Font = Enum.Font.GothamBold,
    Text = "DRAFT OPTIONS",
    TextColor3 = Color3.fromRGB(250, 250, 250),
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
}, bottomArea)

local optionsSubheader = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(22, 38),
    Size = UDim2.new(1, -44, 0, 20),
    Font = Enum.Font.Gotham,
    Text = "Choose one player card for the highlighted pitch slot.",
    TextColor3 = Color3.fromRGB(168, 179, 197),
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, bottomArea)

local optionsScroller = create("ScrollingFrame", {
    Position = UDim2.fromOffset(18, 70),
    Size = UDim2.new(1, -36, 1, -84),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 6,
    CanvasSize = UDim2.fromOffset(0, 0),
    ScrollingDirection = Enum.ScrollingDirection.X,
    AutomaticCanvasSize = Enum.AutomaticSize.None,
}, bottomArea)

local optionsLayout = create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 14),
}, optionsScroller)

local pitchSlotFrames: { [string]: Frame } = {}
local currentDraft: any = nil
local currentProfile: any = nil
local busy = false

local function setBusy(value: boolean)
    busy = value
    actionButton.Active = not value
    actionButton.AutoButtonColor = not value
end

local function setStatusText(text: string)
    draftStatusLabel.Text = text
end

local function buildInventorySummary(profile: any): string
    local inventory = profile and profile.Inventory

    if typeof(inventory) ~= "table" or #inventory == 0 then
        return "No players owned yet."
    end

    local parts = {}
    local startIndex = math.max(1, #inventory - 5)

    for index = #inventory, startIndex, -1 do
        local owned = inventory[index]
        local definition = footballersById[owned.FootballerId]
        if definition then
            table.insert(parts, string.format("• %s (%s %d)", definition.DisplayName, definition.Position, definition.Overall))
        end
    end

    return table.concat(parts, "\n")
end

local function renderProfile(profile: any)
    currentProfile = profile

    local coins = 0
    if profile and typeof(profile.Coins) == "number" then
        coins = profile.Coins
    end

    local inventoryCount = 0
    if profile and typeof(profile.Inventory) == "table" then
        inventoryCount = #profile.Inventory
    end

    coinsLabel.Text = string.format("Coins: %d", coins)
    clubSummaryLabel.Text = string.format("Club players owned: %d", inventoryCount)
    recentClubLabel.Text = buildInventorySummary(profile)
end

local function clearPitchSlots()
    for _, frame in pairs(pitchSlotFrames) do
        frame:Destroy()
    end
    pitchSlotFrames = {}
end

local function createPitchSlot(slotInfo: any, formationSlot: any, isActive: boolean)
    local selected = slotInfo.Selected
    local slotFrame = create("Frame", {
        Name = slotInfo.SlotKey,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(formationSlot.X, formationSlot.Y),
        Size = UDim2.fromOffset(92, 92),
        BackgroundColor3 = if selected then Color3.fromRGB(25, 34, 52) else Color3.fromRGB(17, 28, 20),
        BorderSizePixel = 0,
    }, pitchInner)
    addCorner(slotFrame, 16)

    if selected then
        addStroke(
            slotFrame,
            if isActive then Color3.fromRGB(255, 215, 98) else Color3.fromRGB(100, 134, 190),
            if isActive then 3 else 2,
            0
        )
    else
        addStroke(
            slotFrame,
            if isActive then Color3.fromRGB(255, 215, 98) else Color3.fromRGB(255, 255, 255),
            if isActive then 3 else 1,
            if isActive then 0 else 0.75
        )
    end

    local topLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 6),
        Size = UDim2.new(1, -16, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = slotInfo.Label,
        TextColor3 = Color3.fromRGB(240, 245, 250),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, slotFrame)

    if selected then
        local overallLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 24),
            Size = UDim2.new(1, -16, 0, 24),
            Font = Enum.Font.GothamBlack,
            Text = tostring(selected.Overall),
            TextColor3 = Color3.fromRGB(255, 236, 153),
            TextSize = 24,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, slotFrame)

        local nameLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(8, 50),
            Size = UDim2.new(1, -16, 0, 30),
            Font = Enum.Font.Gotham,
            Text = selected.DisplayName,
            TextColor3 = Color3.fromRGB(230, 235, 245),
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, slotFrame)
    else
        local placeholderLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.58),
            Size = UDim2.new(1, -12, 0, 40),
            Font = Enum.Font.GothamBold,
            Text = slotInfo.Position,
            TextColor3 = Color3.fromRGB(218, 228, 220),
            TextSize = 26,
            TextTransparency = 0.12,
        }, slotFrame)
    end

    pitchSlotFrames[slotInfo.SlotKey] = slotFrame
end

local function createCurrentPickCard(slotLabel: string, position: string)
    currentPickCardHost:ClearAllChildren()
    addCorner(currentPickCardHost, 14)

    local glow = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(42, 164, 98),
        BackgroundTransparency = 0.82,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
    }, currentPickCardHost)
    addCorner(glow, 14)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 14),
        Size = UDim2.new(1, -32, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = "NOW DRAFTING",
        TextColor3 = Color3.fromRGB(174, 224, 194),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, currentPickCardHost)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 40),
        Size = UDim2.new(1, -32, 0, 34),
        Font = Enum.Font.GothamBlack,
        Text = slotLabel,
        TextColor3 = Color3.fromRGB(250, 250, 250),
        TextSize = 28,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, currentPickCardHost)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 80),
        Size = UDim2.new(1, -32, 0, 26),
        Font = Enum.Font.GothamBold,
        Text = "Position requirement: " .. position,
        TextColor3 = Color3.fromRGB(221, 229, 240),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, currentPickCardHost)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(16, 112),
        Size = UDim2.new(1, -32, 0, 42),
        Font = Enum.Font.Gotham,
        Text = "Pick one of the cards below. The selected player will immediately fill this slot on the pitch.",
        TextColor3 = Color3.fromRGB(181, 192, 210),
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    }, currentPickCardHost)
end

local function clearOptions()
    for _, child in ipairs(optionsScroller:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function updateScrollerCanvas()
    optionsScroller.CanvasSize = UDim2.fromOffset(
        optionsLayout.AbsoluteContentSize.X + 12,
        0
    )
end

optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollerCanvas)

local function createStatPill(parent: Instance, text: string, backgroundColor: Color3)
    local pill = create("Frame", {
        BackgroundColor3 = backgroundColor,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(72, 24),
    }, parent)
    addCorner(pill, 999)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
    }, pill)

    return pill
end

local function renderCardOption(card: any)
    local theme = getTheme(card.Rarity)

    local cardButton = create("TextButton", {
        Size = UDim2.fromOffset(214, 286),
        BackgroundColor3 = theme.Primary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = true,
    }, optionsScroller)
    addCorner(cardButton, 20)
    addStroke(cardButton, theme.Accent, 2, 0.18)
    addGradient(cardButton, theme.Primary, theme.Secondary, 135)

    local shine = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromScale(0.5, 0.02),
        Size = UDim2.new(0.82, 0, 0.18, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
    }, cardButton)
    addCorner(shine, 999)

    local overallBadge = create("Frame", {
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(58, 58),
        BackgroundColor3 = Color3.fromRGB(255, 244, 204),
        BorderSizePixel = 0,
    }, cardButton)
    addCorner(overallBadge, 16)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 6),
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBlack,
        Text = tostring(card.Overall),
        TextColor3 = Color3.fromRGB(49, 38, 8),
        TextSize = 24,
    }, overallBadge)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.GothamBold,
        Text = "OVR",
        TextColor3 = Color3.fromRGB(72, 56, 17),
        TextSize = 12,
    }, overallBadge)

    local positionBadge = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 12, 0),
        Size = UDim2.fromOffset(54, 30),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
    }, cardButton)
    addCorner(positionBadge, 999)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = card.Position,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
    }, positionBadge)

    local rarityBadge = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromScale(0.5, 0.11),
        Size = UDim2.fromOffset(112, 24),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
    }, cardButton)
    addCorner(rarityBadge, 999)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = string.upper(card.Rarity),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 11,
    }, rarityBadge)

    local portraitRing = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromScale(0.5, 0.22),
        Size = UDim2.fromOffset(112, 112),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
    }, cardButton)
    addCorner(portraitRing, 999)
    addStroke(portraitRing, theme.Accent, 2, 0.35)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(1, 0, 0, 76),
        Font = Enum.Font.GothamBlack,
        Text = getInitials(card.DisplayName),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0.08,
        TextSize = 44,
    }, portraitRing)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 148),
        Size = UDim2.new(1, -36, 0, 22),
        Font = Enum.Font.GothamBlack,
        Text = card.DisplayName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 19,
        TextWrapped = true,
    }, cardButton)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 172),
        Size = UDim2.new(1, -36, 0, 18),
        Font = Enum.Font.Gotham,
        Text = string.format("%s  •  %s", card.Position, card.Rarity),
        TextColor3 = Color3.fromRGB(235, 239, 245),
        TextSize = 12,
    }, cardButton)

    local metaLine = table.concat({
        card.Nation or "Unknown Nation",
        card.Club or "Free Agent",
    }, "  •  ")

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(18, 194),
        Size = UDim2.new(1, -36, 0, 18),
        Font = Enum.Font.Gotham,
        Text = metaLine,
        TextColor3 = Color3.fromRGB(214, 222, 233),
        TextSize = 11,
        TextWrapped = true,
    }, cardButton)

    local statsRow = create("Frame", {
        Position = UDim2.fromOffset(16, 220),
        Size = UDim2.new(1, -32, 0, 26),
        BackgroundTransparency = 1,
    }, cardButton)

    local statsLayout = create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, statsRow)

    createStatPill(statsRow, tostring(card.Overall) .. " OVR", Color3.fromRGB(255, 255, 255))
    createStatPill(statsRow, card.Position, Color3.fromRGB(255, 255, 255))
    createStatPill(statsRow, card.Rarity, Color3.fromRGB(255, 255, 255))

    local chooseButton = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.96),
        Size = UDim2.new(1, -32, 0, 34),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
    }, cardButton)
    addCorner(chooseButton, 12)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBold,
        Text = "CHOOSE PLAYER",
        TextColor3 = theme.Secondary,
        TextSize = 14,
    }, chooseButton)

    cardButton.Activated:Connect(function()
        if busy or not currentDraft then
            return
        end

        setBusy(true)
        setStatusText("Signing " .. card.DisplayName .. "...")

        local requestSucceeded, response = invokeServer(
            SelectFootballer,
            currentDraft.DraftId,
            card.Id
        )

        setBusy(false)

        if not requestSucceeded then
            setStatusText("Could not contact the server.")
            return
        end

        if typeof(response) ~= "table" or response.Ok ~= true then
            setStatusText(response and response.Error or "Failed to select player.")
            return
        end

        local data = response.Data
        renderProfile(data.Profile)
        currentDraft = data.Draft

        if currentDraft and currentDraft.IsComplete then
            setStatusText("Draft complete! Your full XI is now built.")
        else
            setStatusText(string.format("%s selected successfully.", data.Selected.DisplayName))
        end

        -- Re-render after selection.
        task.defer(function()
            local draft = currentDraft
            if not draft then
                return
            end

            local formation = Formations[draft.FormationId]
            if not formation then
                return
            end

            clearPitchSlots()

            for index, slotInfo in ipairs(draft.Slots) do
                local formationSlot = formation.Slots[index]
                local isActive = (draft.ActiveSlotKey == slotInfo.SlotKey)
                createPitchSlot(slotInfo, formationSlot, isActive)
            end

            clearOptions()

            if draft.IsComplete then
                currentPickCardHost:ClearAllChildren()
                addCorner(currentPickCardHost, 14)

                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = Enum.Font.GothamBlack,
                    Text = "DRAFT COMPLETE",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 28,
                }, currentPickCardHost)

                optionsSubheader.Text = "Your XI is complete. Start another draft whenever you're ready."
                actionButton.Text = string.format("START NEW DRAFT — %d COINS", GameConfig.DraftCost)
                return
            end

            actionButton.Text = "DRAFT IN PROGRESS"
            optionsSubheader.Text = string.format(
                "Pick %d of %d • currently drafting %s",
                draft.CurrentPickIndex,
                draft.TotalPicks,
                draft.ActiveSlotLabel or "slot"
            )

            createCurrentPickCard(draft.ActiveSlotLabel or "Unknown", draft.ActivePosition or "Unknown")

            for _, option in ipairs(draft.CurrentOptions) do
                renderCardOption(option)
            end

            updateScrollerCanvas()
        end)
    end)
end

local function renderDraft(draft: any)
    currentDraft = draft

    if not draft then
        clearPitchSlots()
        clearOptions()
        currentPickCardHost:ClearAllChildren()
        addCorner(currentPickCardHost, 14)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = "No draft active",
            TextColor3 = Color3.fromRGB(186, 198, 216),
            TextSize = 18,
            TextWrapped = true,
        }, currentPickCardHost)

        formationLabel.Text = "FORMATION: 4-3-3"
        optionsSubheader.Text = "Choose one player card for the highlighted pitch slot."
        actionButton.Text = string.format("START 11-PLAYER DRAFT — %d COINS", GameConfig.DraftCost)
        return
    end

    local formation = Formations[draft.FormationId]
    if not formation then
        setStatusText("Formation data missing on client.")
        return
    end

    formationLabel.Text = "FORMATION: " .. formation.Name

    clearPitchSlots()
    for index, slotInfo in ipairs(draft.Slots) do
        local formationSlot = formation.Slots[index]
        local isActive = (draft.ActiveSlotKey == slotInfo.SlotKey)
        createPitchSlot(slotInfo, formationSlot, isActive)
    end

    clearOptions()

    if draft.IsComplete then
        createCurrentPickCard("Draft Complete", "XI Finished")
        currentPickCardHost:ClearAllChildren()
        addCorner(currentPickCardHost, 14)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 34),
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.GothamBlack,
            Text = "DRAFT COMPLETE",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 28,
        }, currentPickCardHost)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(18, 84),
            Size = UDim2.new(1, -36, 0, 54),
            Font = Enum.Font.Gotham,
            Text = "Your full XI has been drafted and placed on the pitch.",
            TextColor3 = Color3.fromRGB(188, 198, 216),
            TextSize = 15,
            TextWrapped = true,
        }, currentPickCardHost)

        optionsSubheader.Text = "Your XI is complete. Start another draft whenever you're ready."
        actionButton.Text = string.format("START NEW DRAFT — %d COINS", GameConfig.DraftCost)
        setStatusText("Draft complete! Your squad is ready.")
        return
    end

    actionButton.Text = "DRAFT IN PROGRESS"

    setStatusText(string.format(
        "Pick %d of %d • drafting %s (%s)",
        draft.CurrentPickIndex,
        draft.TotalPicks,
        draft.ActiveSlotLabel or "slot",
        draft.ActivePosition or "position"
    ))

    optionsSubheader.Text = string.format(
        "Pick %d of %d • currently drafting %s",
        draft.CurrentPickIndex,
        draft.TotalPicks,
        draft.ActiveSlotLabel or "slot"
    )

    createCurrentPickCard(draft.ActiveSlotLabel or "Unknown", draft.ActivePosition or "Unknown")

    for _, option in ipairs(draft.CurrentOptions) do
        renderCardOption(option)
    end

    updateScrollerCanvas()
end

actionButton.Activated:Connect(function()
    if busy then
        return
    end

    if currentDraft and not currentDraft.IsComplete then
        setStatusText("Finish the current draft before starting another one.")
        return
    end

    setBusy(true)
    setStatusText("Generating your 11-player draft...")

    local requestSucceeded, response = invokeServer(StartDraft)

    setBusy(false)

    if not requestSucceeded then
        setStatusText("Could not contact the server.")
        return
    end

    if typeof(response) ~= "table" or response.Ok ~= true then
        setStatusText(response and response.Error or "Failed to start draft.")
        return
    end

    local data = response.Data
    renderProfile(data.Profile)
    renderDraft(data.Draft)
end)

local function loadProfile()
    setStatusText("Loading your club...")

    local requestSucceeded, response = invokeServer(GetProfile)

    if not requestSucceeded then
        setStatusText("Could not contact the server.")
        return
    end

    if typeof(response) ~= "table" or response.Ok ~= true then
        setStatusText(response and response.Error or "Failed to load profile.")
        return
    end

    renderProfile(response.Data.Profile)
    renderDraft(nil)
    setStatusText("Profile loaded. Start a draft to build your XI.")
end

task.defer(loadProfile)