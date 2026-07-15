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
    IgnoreGuiInset = false,
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
    Position = UDim2.new(1, -24, 0, 16),
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
    Position = UDim2.new(1, -24, 0, 44),
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
    Size = UDim2.new(1, 0, 0.57, -76),
    BackgroundTransparency = 1,
}, background)

local pitchPanel = create("Frame", {
    Name = "PitchPanel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -72, 1, -34),
    BackgroundColor3 = Color3.fromRGB(10, 74, 36),
    BorderSizePixel = 0,
}, topArea)

addCorner(pitchPanel, 18)

addStroke(
    pitchPanel,
    Color3.fromRGB(167, 204, 175),
    2,
    0.5
)

addGradient(
    pitchPanel,
    Color3.fromRGB(13, 92, 45),
    Color3.fromRGB(6, 50, 25),
    90
)

local pitchInner = create("Frame", {
    Name = "PitchInner",
    Position = UDim2.fromOffset(24, 18),
    Size = UDim2.new(1, -48, 1, -36),
    BackgroundTransparency = 1,
    ClipsDescendants = false,
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

local bottomArea = create("Frame", {
    Name = "BottomArea",
    Position = UDim2.fromScale(0, 0.57),
    Size = UDim2.new(1, 0, 0.43, 0),
    BackgroundColor3 = Color3.fromRGB(10, 15, 24),
    BorderSizePixel = 0,
}, background)

local draftInfoBar = create("Frame", {
    Name = "DraftInfoBar",
    Position = UDim2.fromOffset(34, 14),
    Size = UDim2.new(1, -68, 0, 48),
    BackgroundColor3 = Color3.fromRGB(20, 27, 40),
    BorderSizePixel = 0,
}, bottomArea)

addCorner(draftInfoBar, 12)

local optionsHeader = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(16, 5),
    Size = UDim2.new(0.55, -16, 0, 22),

    Font = Enum.Font.GothamBold,
    Text = "START YOUR DRAFT",
    TextColor3 = Color3.fromRGB(250, 250, 250),
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, draftInfoBar)

local optionsSubheader = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(16, 26),
    Size = UDim2.new(0.7, -16, 0, 16),

    Font = Enum.Font.Gotham,
    Text = "Choose a footballer for each position.",
    TextColor3 = Color3.fromRGB(162, 174, 194),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, draftInfoBar)

local actionButton = create("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.fromOffset(260, 34),

    BackgroundColor3 = Color3.fromRGB(44, 178, 105),
    BorderSizePixel = 0,

    Font = Enum.Font.GothamBold,
    Text = string.format(
        "START DRAFT — %d COINS",
        GameConfig.DraftCost
    ),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
}, draftInfoBar)

addCorner(actionButton, 9)

local optionsContainer = create("Frame", {
    Name = "OptionsContainer",
    Position = UDim2.fromOffset(34, 74),
    Size = UDim2.new(1, -68, 1, -88),
    BackgroundTransparency = 1,
}, bottomArea)

local optionsLayout = create("UIGridLayout", {
    CellPadding = UDim2.fromOffset(14, 0),
    CellSize = UDim2.new(
        1 / GameConfig.DraftChoicesPerPick,
        -10,
        1,
        0
    ),

    FillDirection = Enum.FillDirection.Horizontal,
    FillDirectionMaxCells = GameConfig.DraftChoicesPerPick,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, optionsContainer)

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
    optionsSubheader.Text = text
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
    clubSummaryLabel.Text = string.format(
        "Club players owned: %d",
        inventoryCount
    )
end

local function clearPitchSlots()
    for _, frame in pairs(pitchSlotFrames) do
        frame:Destroy()
    end
    pitchSlotFrames = {}
end

local function createPitchSlot(
    slotInfo: any,
    formationSlot: any,
    isActive: boolean
)
    local selected = slotInfo.Selected

    local slotFrame = create("Frame", {
        Name = slotInfo.SlotKey,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(
            formationSlot.X,
            formationSlot.Y
        ),
        Size = UDim2.fromOffset(66, 78),

        BackgroundColor3 = if selected
            then Color3.fromRGB(26, 36, 50)
            else Color3.fromRGB(12, 30, 18),

        BackgroundTransparency = if selected then 0 else 0.18,
        BorderSizePixel = 0,
    }, pitchInner)

    addCorner(slotFrame, 12)

    addStroke(
        slotFrame,
        if isActive
            then Color3.fromRGB(255, 214, 75)
            else Color3.fromRGB(205, 220, 210),
        if isActive then 3 else 1,
        if isActive then 0 else 0.45
    )

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(6, 5),
        Size = UDim2.new(1, -12, 0, 14),

        Font = Enum.Font.GothamBold,
        Text = slotInfo.Label,
        TextColor3 = Color3.fromRGB(225, 234, 227),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, slotFrame)

    if selected then
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 20),
            Size = UDim2.new(1, -12, 0, 25),

            Font = Enum.Font.GothamBlack,
            Text = tostring(selected.Overall),
            TextColor3 = Color3.fromRGB(255, 226, 115),
            TextSize = 22,
        }, slotFrame)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(5, 47),
            Size = UDim2.new(1, -10, 0, 24),

            Font = Enum.Font.GothamMedium,
            Text = selected.DisplayName,
            TextColor3 = Color3.fromRGB(245, 247, 250),
            TextSize = 9,
            TextWrapped = true,
        }, slotFrame)
    else
        create("TextLabel", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.58),
            Size = UDim2.new(1, -10, 0, 30),

            Font = Enum.Font.GothamBlack,
            Text = slotInfo.Position,
            TextColor3 = Color3.fromRGB(213, 227, 216),
            TextSize = 18,
        }, slotFrame)
    end

    pitchSlotFrames[slotInfo.SlotKey] = slotFrame
end

local function renderEmptyFormation()
    local formation =
        Formations[GameConfig.DefaultFormationId]

    if not formation then
        warn(
            "Default formation is missing:",
            GameConfig.DefaultFormationId
        )
        return
    end

    clearPitchSlots()

    for _, formationSlot in ipairs(formation.Slots) do
        createPitchSlot({
            SlotKey = formationSlot.Key,
            Label = formationSlot.Label,
            Position = formationSlot.Position,
            Selected = nil,
        }, formationSlot, false)
    end
end

local function clearOptions()
    for _, child in ipairs(optionsContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function renderCardOption(card: any)
    local theme = getTheme(card.Rarity)

    local cardButton = create("TextButton", {
        BackgroundColor3 = theme.Primary,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = true,
    }, optionsContainer)

    addCorner(cardButton, 16)
    addStroke(cardButton, theme.Accent, 2, 0.22)
    addGradient(
        cardButton,
        theme.Primary,
        theme.Secondary,
        135
    )

    local glow = create("Frame", {
        Position = UDim2.fromScale(0.06, 0.04),
        Size = UDim2.fromScale(0.88, 0.2),
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
    }, cardButton)

    addCorner(glow, 999)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.07, 0.05),
        Size = UDim2.fromScale(0.28, 0.18),

        Font = Enum.Font.GothamBlack,
        Text = tostring(card.Overall),
        TextColor3 = Color3.fromRGB(255, 244, 207),
        TextSize = 30,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, cardButton)

    create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(0.93, 0.07),
        Size = UDim2.fromScale(0.28, 0.12),

        Font = Enum.Font.GothamBold,
        Text = card.Position,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, cardButton)

    local portrait = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.43),
        Size = UDim2.fromScale(0.52, 0.42),

        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
    }, cardButton)

    addCorner(portrait, 999)
    addStroke(portrait, theme.Accent, 2, 0.35)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),

        Font = Enum.Font.GothamBlack,
        Text = getInitials(card.DisplayName),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 38,
    }, portrait)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.06, 0.67),
        Size = UDim2.fromScale(0.88, 0.1),

        Font = Enum.Font.GothamBold,
        Text = card.DisplayName,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        TextScaled = true,
    }, cardButton)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.06, 0.77),
        Size = UDim2.fromScale(0.88, 0.07),

        Font = Enum.Font.Gotham,
        Text = string.upper(card.Rarity),
        TextColor3 = theme.Accent,
        TextSize = 11,
    }, cardButton)

    local selectBar = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.fromScale(0.5, 0.95),
        Size = UDim2.fromScale(0.86, 0.11),

        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
    }, cardButton)

    addCorner(selectBar, 9)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),

        Font = Enum.Font.GothamBold,
        Text = "SELECT",
        TextColor3 = theme.Secondary,
        TextSize = 12,
    }, selectBar)

    cardButton.Activated:Connect(function()
        if busy or not currentDraft then
            return
        end

        setBusy(true)
        setStatusText(
            "Signing " .. card.DisplayName .. "..."
        )

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

        if typeof(response) ~= "table"
            or response.Ok ~= true
        then
            setStatusText(
                response and response.Error
                    or "Selection failed."
            )
            return
        end

        renderProfile(response.Data.Profile)
        renderDraft(response.Data.Draft)
    end)
end

local renderDraft: (any) -> ()

renderDraft = function(draft: any)
    currentDraft = draft

    if not draft then
        renderEmptyFormation()
        clearOptions()

        optionsHeader.Text = "START YOUR DRAFT"
        optionsSubheader.Text =
            "Choose a footballer for each position."

        actionButton.Text = string.format(
            "START DRAFT — %d COINS",
            GameConfig.DraftCost
        )

        return
    end

    local formation = Formations[draft.FormationId]

    if not formation then
        setStatusText("Formation data is missing.")
        return
    end

    clearPitchSlots()

    for index, slotInfo in ipairs(draft.Slots) do
        local formationSlot = formation.Slots[index]

        if formationSlot then
            local isActive =
                draft.ActiveSlotKey == slotInfo.SlotKey

            createPitchSlot(
                slotInfo,
                formationSlot,
                isActive
            )
        end
    end

    clearOptions()

    if draft.IsComplete then
        optionsHeader.Text = "DRAFT COMPLETE"
        optionsSubheader.Text =
            "Your starting eleven is ready."

        actionButton.Text = string.format(
            "START NEW DRAFT — %d COINS",
            GameConfig.DraftCost
        )

        return
    end

    optionsHeader.Text = string.format(
        "PICK %d OF %d — %s",
        draft.CurrentPickIndex,
        draft.TotalPicks,
        draft.ActiveSlotLabel or "POSITION"
    )

    optionsSubheader.Text = string.format(
        "Choose a %s for the highlighted slot.",
        draft.ActivePosition or "player"
    )

    actionButton.Text = "DRAFT IN PROGRESS"

    for _, option in ipairs(draft.CurrentOptions) do
        renderCardOption(option)
    end
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
