--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")

local GameConfig = require(Config:WaitForChild("GameConfig"))
local Formations = require(Config:WaitForChild("Formations"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetProfile = Remotes:WaitForChild("GetProfile") :: RemoteFunction
local StartDraft = Remotes:WaitForChild("StartDraft") :: RemoteFunction
local SelectFootballer =
	Remotes:WaitForChild("SelectFootballer") :: RemoteFunction

local existingGui = playerGui:FindFirstChild("DraftPrototype")
if existingGui then
	existingGui:Destroy()
end

type CardTheme = {
	Top: Color3,
	Bottom: Color3,
	Accent: Color3,
	Ink: Color3,
	Glow: Color3,
}

type OptionSlot = {
	Button: TextButton,
	Visual: Frame,
	Scale: UIScale,
	Card: any?,
}

type SlotStyle = {
	Stroke: UIStroke,
	Color: Color3,
	Thickness: number,
	Transparency: number,
}

local COLORS = {
	Background = Color3.fromRGB(5, 8, 17),
	Panel = Color3.fromRGB(15, 22, 37),
	PanelLight = Color3.fromRGB(24, 34, 55),
	PanelBright = Color3.fromRGB(31, 44, 69),
	White = Color3.fromRGB(250, 252, 255),
	Muted = Color3.fromRGB(168, 181, 204),
	DarkText = Color3.fromRGB(17, 22, 34),
	Green = Color3.fromRGB(63, 232, 132),
	GreenDark = Color3.fromRGB(12, 142, 72),
	Yellow = Color3.fromRGB(255, 222, 77),
	Orange = Color3.fromRGB(255, 143, 49),
	Red = Color3.fromRGB(255, 86, 104),
	Blue = Color3.fromRGB(70, 155, 255),
	Purple = Color3.fromRGB(177, 91, 255),
	Cyan = Color3.fromRGB(68, 228, 242),
}

local RARITY_THEME: { [string]: CardTheme } = {
	Common = {
		Top = Color3.fromRGB(87, 98, 119),
		Bottom = Color3.fromRGB(40, 47, 62),
		Accent = Color3.fromRGB(197, 207, 221),
		Ink = Color3.fromRGB(31, 38, 51),
		Glow = Color3.fromRGB(146, 162, 185),
	},
	Rare = {
		Top = Color3.fromRGB(48, 126, 236),
		Bottom = Color3.fromRGB(17, 58, 145),
		Accent = Color3.fromRGB(183, 220, 255),
		Ink = Color3.fromRGB(12, 45, 117),
		Glow = Color3.fromRGB(69, 155, 255),
	},
	Epic = {
		Top = Color3.fromRGB(162, 79, 225),
		Bottom = Color3.fromRGB(74, 30, 125),
		Accent = Color3.fromRGB(235, 208, 255),
		Ink = Color3.fromRGB(67, 25, 111),
		Glow = Color3.fromRGB(184, 94, 255),
	},
	Legendary = {
		Top = Color3.fromRGB(247, 167, 41),
		Bottom = Color3.fromRGB(142, 73, 5),
		Accent = Color3.fromRGB(255, 236, 173),
		Ink = Color3.fromRGB(102, 54, 7),
		Glow = Color3.fromRGB(255, 179, 52),
	},
	Mythic = {
		Top = Color3.fromRGB(238, 67, 112),
		Bottom = Color3.fromRGB(94, 17, 76),
		Accent = Color3.fromRGB(255, 202, 226),
		Ink = Color3.fromRGB(91, 17, 66),
		Glow = Color3.fromRGB(255, 70, 153),
	},
	Icon = {
		Top = Color3.fromRGB(250, 244, 211),
		Bottom = Color3.fromRGB(161, 133, 65),
		Accent = Color3.fromRGB(255, 252, 226),
		Ink = Color3.fromRGB(83, 63, 18),
		Glow = Color3.fromRGB(255, 234, 142),
	},
}

local CARD_TYPE_LABELS: { [string]: string } = {
	Standard = "STANDARD",
	RisingStar = "RISING STAR",
	Captain = "CAPTAIN",
	Hero = "HERO",
	Legend = "LEGEND",
	Rainbow = "RAINBOW",
	Eclipse = "ECLIPSE",
}

local function create(
	className: string,
	properties: { [string]: any }?,
	parent: Instance?
): Instance
	local instance = Instance.new(className)

	if properties then
		for propertyName, value in pairs(properties) do
			(instance :: any)[propertyName] = value
		end
	end

	if parent then
		instance.Parent = parent
	end

	return instance
end

local function addCorner(target: Instance, radiusScale: number)
	create("UICorner", {
		CornerRadius = UDim.new(radiusScale, 0),
	}, target)
end

local function addStroke(
	target: Instance,
	color: Color3,
	thickness: number,
	transparency: number?
): UIStroke
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, target) :: UIStroke
end

local function addGradient(
	target: Instance,
	first: Color3,
	second: Color3,
	rotation: number?
): UIGradient
	return create("UIGradient", {
		Rotation = rotation or 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, first),
			ColorSequenceKeypoint.new(1, second),
		}),
	}, target) :: UIGradient
end

local function addTextConstraint(
	target: Instance,
	minimum: number,
	maximum: number
)
	create("UITextSizeConstraint", {
		MinTextSize = minimum,
		MaxTextSize = maximum,
	}, target)
end

local function addAspectConstraint(
	target: Instance,
	aspectRatio: number,
	dominantAxis: Enum.DominantAxis?
)
	create("UIAspectRatioConstraint", {
		AspectRatio = aspectRatio,
		AspectType = Enum.AspectType.FitWithinMaxSize,
		DominantAxis = dominantAxis or Enum.DominantAxis.Width,
	}, target)
end

local function addSizeConstraint(
	target: Instance,
	maximum: Vector2
)
	create("UISizeConstraint", {
		MaxSize = maximum,
	}, target)
end

local function addScale(
	target: Instance,
	initialScale: number
): UIScale
	return create("UIScale", {
		Scale = initialScale,
	}, target) :: UIScale
end

local function tween(
	target: Instance,
	info: TweenInfo,
	properties: { [string]: any }
): Tween
	local animation = TweenService:Create(target, info, properties)
	animation:Play()
	return animation
end

local function getTheme(rarity: string): CardTheme
	return RARITY_THEME[rarity] or RARITY_THEME.Common
end

local function getCardTypeLabel(cardType: string?): string
	if not cardType then
		return "STANDARD"
	end

	return CARD_TYPE_LABELS[cardType] or string.upper(cardType)
end

local function getInitials(displayName: string): string
	local initials = {}

	for token in string.gmatch(displayName, "[^%s]+") do
		local first = string.sub(token, 1, 1)

		if first ~= "" then
			table.insert(initials, string.upper(first))
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

local function getFitText(card: any): string
	local labels = card.EligibleSlotLabels

	if typeof(labels) ~= "table" or #labels == 0 then
		return "NO OPEN POSITION"
	end

	local shown = {}

	for index = 1, math.min(#labels, 3) do
		table.insert(shown, labels[index])
	end

	local suffix = if #labels > 3 then " +" else ""

	return "CAN PLAY  " .. table.concat(shown, "  •  ") .. suffix
end

local function invokeServer(
	remote: RemoteFunction,
	...: any
): (boolean, any)
	local arguments = table.pack(...)

	return pcall(function()
		return remote:InvokeServer(
			table.unpack(arguments, 1, arguments.n)
		)
	end)
end

local screenGui = create("ScreenGui", {
	Name = "DraftPrototype",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui) :: ScreenGui

local backdrop = create("Frame", {
	Name = "Backdrop",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COLORS.Background,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, screenGui) :: Frame

addGradient(
	backdrop,
	Color3.fromRGB(16, 27, 48),
	Color3.fromRGB(4, 7, 15),
	90
)

for index = 1, 6 do
	local beam = create("Frame", {
		Name = "StadiumBeam",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(
			0.08 + ((index - 1) * 0.17),
			-0.15
		),
		Size = UDim2.fromScale(0.06, 1.35),
		Rotation = if index % 2 == 0 then 12 else -12,
		BackgroundColor3 = if index % 3 == 0
			then COLORS.Yellow
			else COLORS.Blue,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
	}, backdrop) :: Frame

	addGradient(
		beam,
		Color3.fromRGB(255, 255, 255),
		beam.BackgroundColor3,
		90
	)
end

local app = create("Frame", {
	Name = "App",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.97, 0.94),
	BackgroundColor3 = Color3.fromRGB(8, 13, 24),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, backdrop) :: Frame

addAspectConstraint(app, 16 / 9, Enum.DominantAxis.Width)
addSizeConstraint(app, Vector2.new(1520, 855))
addCorner(app, 0.018)
addStroke(app, Color3.fromRGB(75, 110, 165), 2, 0.35)

local appScale = addScale(app, 1)

local header = create("Frame", {
	Name = "Header",
	Size = UDim2.fromScale(1, 0.115),
	BackgroundColor3 = Color3.fromRGB(17, 24, 40),
	BorderSizePixel = 0,
}, app) :: Frame

local logo = create("Frame", {
	Name = "Logo",
	Position = UDim2.fromScale(0.02, 0.17),
	Size = UDim2.fromScale(0.068, 0.66),
	BackgroundColor3 = COLORS.Green,
	BorderSizePixel = 0,
	Rotation = -2,
}, header) :: Frame
addCorner(logo, 0.2)
addStroke(logo, Color3.fromRGB(190, 255, 217), 2, 0.15)
addGradient(logo, COLORS.Green, COLORS.GreenDark, 135)

local logoText = create("TextLabel", {
	Name = "LogoText",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "XI",
	TextColor3 = COLORS.White,
	TextScaled = true,
}, logo) :: TextLabel
addTextConstraint(logoText, 20, 34)

local brand = create("Frame", {
	Name = "Brand",
	Position = UDim2.fromScale(0.105, 0.13),
	Size = UDim2.fromScale(0.39, 0.74),
	BackgroundTransparency = 1,
}, header) :: Frame

local titleLabel = create("TextLabel", {
	Name = "Title",
	Size = UDim2.fromScale(1, 0.6),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "FOOTBALL DYNASTY",
	TextColor3 = COLORS.White,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, brand) :: TextLabel
addTextConstraint(titleLabel, 20, 35)

local subtitleLabel = create("TextLabel", {
	Name = "Subtitle",
	Position = UDim2.fromScale(0, 0.61),
	Size = UDim2.fromScale(1, 0.3),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "THE ULTIMATE DRAFT ROOM",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, brand) :: TextLabel
addTextConstraint(subtitleLabel, 10, 16)

local headerMetrics = create("Frame", {
	Name = "HeaderMetrics",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.66, 0.5),
	Size = UDim2.fromScale(0.31, 0.58),
	BackgroundTransparency = 1,
}, header) :: Frame

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0.016, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, headerMetrics)

local metricLabels: { [string]: TextLabel } = {}

local function createHeaderMetric(
	key: string,
	label: string,
	accent: Color3,
	order: number
)
	local metric = create("Frame", {
		Name = key,
		Size = UDim2.fromScale(0.18, 0.82),
		BackgroundColor3 = COLORS.PanelLight,
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, headerMetrics) :: Frame
	addCorner(metric, 0.2)
	addStroke(metric, accent, 1, 0.32)

	local labelText = create("TextLabel", {
		Name = "Label",
		Position = UDim2.fromScale(0.06, 0.05),
		Size = UDim2.fromScale(0.88, 0.34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = label,
		TextColor3 = accent,
		TextScaled = true,
	}, metric) :: TextLabel
	addTextConstraint(labelText, 8, 12)

	local valueText = create("TextLabel", {
		Name = "Value",
		Position = UDim2.fromScale(0.06, 0.38),
		Size = UDim2.fromScale(0.88, 0.53),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "--",
		TextColor3 = COLORS.White,
		TextScaled = true,
	}, metric) :: TextLabel
	addTextConstraint(valueText, 13, 22)

	metricLabels[key] = valueText
end

createHeaderMetric("Overall", "OVR", COLORS.Yellow, 1)
createHeaderMetric("Chemistry", "CHEM", COLORS.Green, 2)
createHeaderMetric("Attack", "ATT", COLORS.Red, 3)
createHeaderMetric("Midfield", "MID", COLORS.Blue, 4)
createHeaderMetric("Defense", "DEF", COLORS.Purple, 5)

local wallet = create("Frame", {
	Name = "Wallet",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.98, 0.5),
	Size = UDim2.fromScale(0.175, 0.64),
	BackgroundColor3 = COLORS.PanelLight,
	BorderSizePixel = 0,
}, header) :: Frame
addCorner(wallet, 0.18)
addStroke(wallet, COLORS.Yellow, 1, 0.35)

local coin = create("Frame", {
	Name = "Coin",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0.045, 0.5),
	Size = UDim2.fromScale(0.23, 0.72),
	BackgroundColor3 = COLORS.Yellow,
	BorderSizePixel = 0,
}, wallet) :: Frame
addAspectConstraint(coin, 1, Enum.DominantAxis.Height)
addCorner(coin, 0.5)
addGradient(
	coin,
	Color3.fromRGB(255, 242, 108),
	Color3.fromRGB(221, 147, 26),
	135
)

local coinText = create("TextLabel", {
	Name = "CoinText",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "$",
	TextColor3 = Color3.fromRGB(103, 65, 7),
	TextScaled = true,
}, coin) :: TextLabel
addTextConstraint(coinText, 15, 25)

local walletText = create("Frame", {
	Name = "WalletText",
	Position = UDim2.fromScale(0.31, 0.13),
	Size = UDim2.fromScale(0.64, 0.74),
	BackgroundTransparency = 1,
}, wallet) :: Frame

local coinsLabel = create("TextLabel", {
	Name = "Coins",
	Size = UDim2.fromScale(1, 0.55),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "0 COINS",
	TextColor3 = COLORS.Yellow,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
}, walletText) :: TextLabel
addTextConstraint(coinsLabel, 13, 22)

local ownedLabel = create("TextLabel", {
	Name = "Owned",
	Position = UDim2.fromScale(0, 0.58),
	Size = UDim2.fromScale(1, 0.3),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "0 PLAYERS",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
}, walletText) :: TextLabel
addTextConstraint(ownedLabel, 8, 13)

local body = create("Frame", {
	Name = "Body",
	Position = UDim2.fromScale(0, 0.115),
	Size = UDim2.fromScale(1, 0.885),
	BackgroundTransparency = 1,
}, app) :: Frame

local pitchView = create("Frame", {
	Name = "PitchView",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = true,
}, body) :: Frame

local pitchPanel = create("Frame", {
	Name = "PitchPanel",
	Position = UDim2.fromScale(0.035, 0.055),
	Size = UDim2.fromScale(0.65, 0.88),
	BackgroundColor3 = Color3.fromRGB(8, 102, 48),
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, pitchView) :: Frame
addAspectConstraint(pitchPanel, 1.55, Enum.DominantAxis.Width)
addCorner(pitchPanel, 0.035)
addStroke(pitchPanel, Color3.fromRGB(177, 238, 191), 2, 0.4)
addGradient(
	pitchPanel,
	Color3.fromRGB(20, 142, 67),
	Color3.fromRGB(5, 68, 34),
	90
)

for stripeIndex = 1, 8 do
	create("Frame", {
		Name = "Stripe",
		Position = UDim2.fromScale((stripeIndex - 1) / 8, 0),
		Size = UDim2.fromScale(1 / 8, 1),
		BackgroundColor3 = COLORS.White,
		BackgroundTransparency = if stripeIndex % 2 == 0
			then 0.94
			else 1,
		BorderSizePixel = 0,
	}, pitchPanel)
end

local pitchInner = create("Frame", {
	Name = "PitchInner",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.92, 0.9),
	BackgroundTransparency = 1,
	ClipsDescendants = false,
}, pitchPanel) :: Frame

local lineColor = Color3.fromRGB(238, 250, 240)

local function createPitchLine(properties: { [string]: any })
	create("Frame", properties, pitchInner)
end

createPitchLine({
	Name = "Top",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.02),
	Size = UDim2.fromScale(0.96, 0.006),
	BackgroundColor3 = lineColor,
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
})

createPitchLine({
	Name = "Bottom",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.98),
	Size = UDim2.fromScale(0.96, 0.006),
	BackgroundColor3 = lineColor,
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
})

createPitchLine({
	Name = "Left",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0.02, 0.5),
	Size = UDim2.fromScale(0.004, 0.96),
	BackgroundColor3 = lineColor,
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
})

createPitchLine({
	Name = "Right",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.98, 0.5),
	Size = UDim2.fromScale(0.004, 0.96),
	BackgroundColor3 = lineColor,
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
})

createPitchLine({
	Name = "Half",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.96, 0.006),
	BackgroundColor3 = lineColor,
	BackgroundTransparency = 0.38,
	BorderSizePixel = 0,
})

local centreCircle = create("Frame", {
	Name = "CentreCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.16, 0.28),
	BackgroundTransparency = 1,
}, pitchInner) :: Frame
addAspectConstraint(centreCircle, 1, Enum.DominantAxis.Height)
addCorner(centreCircle, 0.5)
addStroke(centreCircle, lineColor, 2, 0.38)

local topBox = create("Frame", {
	Name = "TopBox",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.02),
	Size = UDim2.fromScale(0.34, 0.18),
	BackgroundTransparency = 1,
}, pitchInner) :: Frame
addStroke(topBox, lineColor, 2, 0.38)

local bottomBox = create("Frame", {
	Name = "BottomBox",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.98),
	Size = UDim2.fromScale(0.34, 0.18),
	BackgroundTransparency = 1,
}, pitchInner) :: Frame
addStroke(bottomBox, lineColor, 2, 0.38)

local dashboard = create("Frame", {
	Name = "Dashboard",
	Position = UDim2.fromScale(0.715, 0.055),
	Size = UDim2.fromScale(0.25, 0.88),
	BackgroundColor3 = COLORS.Panel,
	BorderSizePixel = 0,
}, pitchView) :: Frame
addCorner(dashboard, 0.04)
addStroke(dashboard, Color3.fromRGB(71, 95, 135), 2, 0.38)

local dashboardTitle = create("TextLabel", {
	Name = "Title",
	Position = UDim2.fromScale(0.06, 0.045),
	Size = UDim2.fromScale(0.88, 0.08),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "YOUR DYNASTY XI",
	TextColor3 = COLORS.White,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, dashboard) :: TextLabel
addTextConstraint(dashboardTitle, 15, 25)

local dashboardSubtitle = create("TextLabel", {
	Name = "Subtitle",
	Position = UDim2.fromScale(0.06, 0.125),
	Size = UDim2.fromScale(0.88, 0.045),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "BUILD THE BEST TEAM YOU CAN",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, dashboard) :: TextLabel
addTextConstraint(dashboardSubtitle, 8, 13)

local progressTrack = create("Frame", {
	Name = "ProgressTrack",
	Position = UDim2.fromScale(0.06, 0.205),
	Size = UDim2.fromScale(0.88, 0.07),
	BackgroundColor3 = Color3.fromRGB(34, 45, 65),
	BorderSizePixel = 0,
}, dashboard) :: Frame
addCorner(progressTrack, 0.3)

local progressFill = create("Frame", {
	Name = "ProgressFill",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = COLORS.Green,
	BorderSizePixel = 0,
}, progressTrack) :: Frame
addCorner(progressFill, 0.3)
addGradient(progressFill, COLORS.Green, COLORS.Cyan, 0)

local progressLabel = create("TextLabel", {
	Name = "ProgressLabel",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "0 / 11 PLAYERS",
	TextColor3 = COLORS.White,
	TextScaled = true,
	ZIndex = 2,
}, progressTrack) :: TextLabel
addTextConstraint(progressLabel, 9, 14)

local summaryPanel = create("Frame", {
	Name = "SummaryPanel",
	Position = UDim2.fromScale(0.06, 0.315),
	Size = UDim2.fromScale(0.88, 0.39),
	BackgroundColor3 = COLORS.PanelLight,
	BorderSizePixel = 0,
}, dashboard) :: Frame
addCorner(summaryPanel, 0.05)

local summaryTitle = create("TextLabel", {
	Name = "SummaryTitle",
	Position = UDim2.fromScale(0.06, 0.05),
	Size = UDim2.fromScale(0.88, 0.12),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "LIVE TEAM RATING",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, summaryPanel) :: TextLabel
addTextConstraint(summaryTitle, 9, 14)

local bigOverall = create("TextLabel", {
	Name = "BigOverall",
	Position = UDim2.fromScale(0.06, 0.18),
	Size = UDim2.fromScale(0.44, 0.44),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "--",
	TextColor3 = COLORS.Yellow,
	TextScaled = true,
}, summaryPanel) :: TextLabel
addTextConstraint(bigOverall, 38, 68)

local overallCaption = create("TextLabel", {
	Name = "OverallCaption",
	Position = UDim2.fromScale(0.06, 0.59),
	Size = UDim2.fromScale(0.44, 0.1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "TEAM OVR",
	TextColor3 = COLORS.White,
	TextScaled = true,
}, summaryPanel) :: TextLabel
addTextConstraint(overallCaption, 9, 15)

local chemistryRing = create("Frame", {
	Name = "ChemistryRing",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.75, 0.43),
	Size = UDim2.fromScale(0.36, 0.55),
	BackgroundColor3 = Color3.fromRGB(18, 31, 43),
	BorderSizePixel = 0,
}, summaryPanel) :: Frame
addAspectConstraint(chemistryRing, 1, Enum.DominantAxis.Height)
addCorner(chemistryRing, 0.5)
addStroke(chemistryRing, COLORS.Green, 3, 0.12)

local chemistryValue = create("TextLabel", {
	Name = "ChemistryValue",
	Position = UDim2.fromScale(0.08, 0.14),
	Size = UDim2.fromScale(0.84, 0.48),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "--",
	TextColor3 = COLORS.Green,
	TextScaled = true,
}, chemistryRing) :: TextLabel
addTextConstraint(chemistryValue, 22, 39)

local chemistryCaption = create("TextLabel", {
	Name = "ChemistryCaption",
	Position = UDim2.fromScale(0.08, 0.61),
	Size = UDim2.fromScale(0.84, 0.19),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "CHEM",
	TextColor3 = COLORS.White,
	TextScaled = true,
}, chemistryRing) :: TextLabel
addTextConstraint(chemistryCaption, 8, 13)

local lineRatings = create("Frame", {
	Name = "LineRatings",
	Position = UDim2.fromScale(0.06, 0.75),
	Size = UDim2.fromScale(0.88, 0.17),
	BackgroundTransparency = 1,
}, summaryPanel) :: Frame

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0.025, 0),
}, lineRatings)

local dashboardLineLabels: { [string]: TextLabel } = {}

local function createLineRating(
	key: string,
	label: string,
	accent: Color3
)
	local item = create("Frame", {
		Name = key,
		Size = UDim2.fromScale(0.3, 0.86),
		BackgroundColor3 = Color3.fromRGB(34, 45, 67),
		BorderSizePixel = 0,
	}, lineRatings) :: Frame
	addCorner(item, 0.18)
	addStroke(item, accent, 1, 0.35)

	local labelText = create("TextLabel", {
		Name = "Label",
		Position = UDim2.fromScale(0.06, 0.08),
		Size = UDim2.fromScale(0.42, 0.84),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = label,
		TextColor3 = accent,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, item) :: TextLabel
	addTextConstraint(labelText, 8, 13)

	local valueText = create("TextLabel", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.94, 0.08),
		Size = UDim2.fromScale(0.42, 0.84),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "--",
		TextColor3 = COLORS.White,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, item) :: TextLabel
	addTextConstraint(valueText, 11, 18)

	dashboardLineLabels[key] = valueText
end

createLineRating("Attack", "ATT", COLORS.Red)
createLineRating("Midfield", "MID", COLORS.Blue)
createLineRating("Defense", "DEF", COLORS.Purple)

local statusCard = create("Frame", {
	Name = "StatusCard",
	Position = UDim2.fromScale(0.06, 0.74),
	Size = UDim2.fromScale(0.88, 0.13),
	BackgroundColor3 = COLORS.PanelLight,
	BorderSizePixel = 0,
}, dashboard) :: Frame
addCorner(statusCard, 0.12)

local statusTitle = create("TextLabel", {
	Name = "StatusTitle",
	Position = UDim2.fromScale(0.05, 0.08),
	Size = UDim2.fromScale(0.9, 0.37),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "READY TO DRAFT",
	TextColor3 = COLORS.White,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statusCard) :: TextLabel
addTextConstraint(statusTitle, 10, 17)

local statusBody = create("TextLabel", {
	Name = "StatusBody",
	Position = UDim2.fromScale(0.05, 0.46),
	Size = UDim2.fromScale(0.9, 0.42),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Roll five players and build your XI.",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, statusCard) :: TextLabel
addTextConstraint(statusBody, 8, 13)

local dashboardButtonShadow = create("Frame", {
	Name = "ButtonShadow",
	Position = UDim2.fromScale(0.06, 0.895),
	Size = UDim2.fromScale(0.88, 0.085),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.45,
	BorderSizePixel = 0,
}, dashboard) :: Frame
addCorner(dashboardButtonShadow, 0.18)

local dashboardButton = create("TextButton", {
	Name = "DashboardButton",
	Position = UDim2.fromScale(0.06, 0.885),
	Size = UDim2.fromScale(0.88, 0.085),
	BackgroundColor3 = COLORS.Green,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBlack,
	Text = string.format("START DRAFT  •  %d", GameConfig.DraftCost),
	TextColor3 = COLORS.White,
	TextScaled = true,
	AutoButtonColor = false,
}, dashboard) :: TextButton
addCorner(dashboardButton, 0.18)
addStroke(dashboardButton, Color3.fromRGB(190, 255, 215), 2, 0.15)
addGradient(dashboardButton, COLORS.Green, COLORS.GreenDark, 135)
addTextConstraint(dashboardButton, 12, 20)
local dashboardButtonScale = addScale(dashboardButton, 1)

local rollView = create("Frame", {
	Name = "RollView",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(7, 12, 23),
	BorderSizePixel = 0,
	Visible = false,
}, body) :: Frame

local rollTop = create("Frame", {
	Name = "RollTop",
	Position = UDim2.fromScale(0.035, 0.035),
	Size = UDim2.fromScale(0.93, 0.12),
	BackgroundColor3 = COLORS.Panel,
	BorderSizePixel = 0,
}, rollView) :: Frame
addCorner(rollTop, 0.12)
addStroke(rollTop, Color3.fromRGB(77, 105, 150), 2, 0.4)

local pickBadge = create("Frame", {
	Name = "PickBadge",
	Position = UDim2.fromScale(0.018, 0.14),
	Size = UDim2.fromScale(0.09, 0.72),
	BackgroundColor3 = COLORS.Yellow,
	BorderSizePixel = 0,
	Rotation = -2,
}, rollTop) :: Frame
addCorner(pickBadge, 0.2)
addStroke(pickBadge, Color3.fromRGB(255, 245, 182), 2, 0.12)
addGradient(
	pickBadge,
	Color3.fromRGB(255, 237, 97),
	Color3.fromRGB(230, 158, 27),
	135
)

local pickBadgeText = create("TextLabel", {
	Name = "PickBadgeText",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "1/11",
	TextColor3 = Color3.fromRGB(91, 58, 5),
	TextScaled = true,
}, pickBadge) :: TextLabel
addTextConstraint(pickBadgeText, 13, 23)

local rollHeading = create("Frame", {
	Name = "RollHeading",
	Position = UDim2.fromScale(0.125, 0.12),
	Size = UDim2.fromScale(0.55, 0.76),
	BackgroundTransparency = 1,
}, rollTop) :: Frame

local rollTitle = create("TextLabel", {
	Name = "RollTitle",
	Size = UDim2.fromScale(1, 0.58),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "ROLL YOUR NEXT FIVE",
	TextColor3 = COLORS.White,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, rollHeading) :: TextLabel
addTextConstraint(rollTitle, 17, 29)

local rollSubtitle = create("TextLabel", {
	Name = "RollSubtitle",
	Position = UDim2.fromScale(0, 0.6),
	Size = UDim2.fromScale(1, 0.32),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Every card can fill an open position.",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, rollHeading) :: TextLabel
addTextConstraint(rollSubtitle, 9, 15)

local viewSquadButton = create("TextButton", {
	Name = "ViewSquad",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.965, 0.5),
	Size = UDim2.fromScale(0.18, 0.56),
	BackgroundColor3 = COLORS.PanelBright,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBlack,
	Text = "VIEW SQUAD",
	TextColor3 = COLORS.White,
	TextScaled = true,
	AutoButtonColor = false,
}, rollTop) :: TextButton
addCorner(viewSquadButton, 0.18)
addStroke(viewSquadButton, COLORS.Blue, 2, 0.28)
addTextConstraint(viewSquadButton, 10, 17)

local cardsStage = create("Frame", {
	Name = "CardsStage",
	Position = UDim2.fromScale(0.025, 0.175),
	Size = UDim2.fromScale(0.95, 0.69),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, rollView) :: Frame

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0.017, 0),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, cardsStage)

local rollFooter = create("Frame", {
	Name = "RollFooter",
	Position = UDim2.fromScale(0.035, 0.875),
	Size = UDim2.fromScale(0.93, 0.095),
	BackgroundColor3 = COLORS.Panel,
	BorderSizePixel = 0,
}, rollView) :: Frame
addCorner(rollFooter, 0.14)
addStroke(rollFooter, Color3.fromRGB(77, 105, 150), 1, 0.45)

local footerStatus = create("TextLabel", {
	Name = "FooterStatus",
	Position = UDim2.fromScale(0.025, 0.16),
	Size = UDim2.fromScale(0.61, 0.68),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Press ROLL PICKS to reveal your choices.",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
}, rollFooter) :: TextLabel
addTextConstraint(footerStatus, 10, 16)

local rollActionButton = create("TextButton", {
	Name = "RollAction",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.975, 0.5),
	Size = UDim2.fromScale(0.3, 0.68),
	BackgroundColor3 = COLORS.Green,
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBlack,
	Text = "ROLL 5 PICKS",
	TextColor3 = COLORS.White,
	TextScaled = true,
	AutoButtonColor = false,
}, rollFooter) :: TextButton
addCorner(rollActionButton, 0.18)
addStroke(rollActionButton, Color3.fromRGB(190, 255, 215), 2, 0.15)
addGradient(rollActionButton, COLORS.Green, COLORS.GreenDark, 135)
addTextConstraint(rollActionButton, 13, 22)
local rollButtonScale = addScale(rollActionButton, 1)

local effectsLayer = create("Frame", {
	Name = "EffectsLayer",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 100,
}, app) :: Frame

local screenFlash = create("Frame", {
	Name = "ScreenFlash",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COLORS.White,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 101,
}, effectsLayer) :: Frame

local pullBanner = create("Frame", {
	Name = "PullBanner",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.48),
	Size = UDim2.fromScale(0.52, 0.2),
	BackgroundColor3 = COLORS.Panel,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 110,
}, effectsLayer) :: Frame
addCorner(pullBanner, 0.08)
local pullBannerStroke =
	addStroke(pullBanner, COLORS.Yellow, 4, 1)
local pullBannerScale = addScale(pullBanner, 0.65)

local pullTierLabel = create("TextLabel", {
	Name = "Tier",
	Position = UDim2.fromScale(0.05, 0.1),
	Size = UDim2.fromScale(0.9, 0.28),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "HUGE PULL!",
	TextColor3 = COLORS.Yellow,
	TextScaled = true,
	ZIndex = 111,
}, pullBanner) :: TextLabel
addTextConstraint(pullTierLabel, 16, 29)

local pullPlayerLabel = create("TextLabel", {
	Name = "Player",
	Position = UDim2.fromScale(0.05, 0.37),
	Size = UDim2.fromScale(0.9, 0.42),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	Text = "PLAYER NAME",
	TextColor3 = COLORS.White,
	TextScaled = true,
	ZIndex = 111,
}, pullBanner) :: TextLabel
addTextConstraint(pullPlayerLabel, 23, 42)

local pullMetaLabel = create("TextLabel", {
	Name = "Meta",
	Position = UDim2.fromScale(0.05, 0.78),
	Size = UDim2.fromScale(0.9, 0.14),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "96 OVR • ICON",
	TextColor3 = COLORS.Muted,
	TextScaled = true,
	ZIndex = 111,
}, pullBanner) :: TextLabel
addTextConstraint(pullMetaLabel, 10, 17)

local pitchSlotFrames: { [string]: Frame } = {}
local pitchSlotStyles: { [string]: SlotStyle } = {}
local optionSlots: { OptionSlot } = {}

local currentDraft: any = nil
local pendingOptions: { any } = {}
local busy = false
local optionsRevealed = false
local viewingSquadDuringDraft = false
local revealGeneration = 0
local dashboardAction = "START"
local rollAction = "ROLL"

local function setTextStatus(
	title: string,
	bodyText: string,
	isError: boolean?
)
	statusTitle.Text = title
	statusBody.Text = bodyText
	statusBody.TextColor3 = if isError
		then COLORS.Red
		else COLORS.Muted
end

local function setFooterStatus(
	text: string,
	isError: boolean?
)
	footerStatus.Text = text
	footerStatus.TextColor3 = if isError
		then COLORS.Red
		else COLORS.Muted
end

local function setButtonEnabled(
	button: TextButton,
	enabled: boolean
)
	button.Active = enabled
	button.BackgroundTransparency = if enabled then 0 else 0.25
	button.TextTransparency = if enabled then 0 else 0.2
end

local function updateTeamSummary(summary: any)
	local function setMetric(key: string, value: any)
		local label = metricLabels[key]

		if label then
			label.Text = if typeof(value) == "number"
				then tostring(value)
				else "--"
		end
	end

	if typeof(summary) ~= "table" then
		setMetric("Overall", nil)
		setMetric("Chemistry", nil)
		setMetric("Attack", nil)
		setMetric("Midfield", nil)
		setMetric("Defense", nil)

		bigOverall.Text = "--"
		chemistryValue.Text = "--"

		for _, label in pairs(dashboardLineLabels) do
			label.Text = "--"
		end

		return
	end

	setMetric("Overall", summary.Overall)
	setMetric("Chemistry", summary.Chemistry)
	setMetric("Attack", summary.Attack)
	setMetric("Midfield", summary.Midfield)
	setMetric("Defense", summary.Defense)

	bigOverall.Text = tostring(summary.Overall or 0)
	chemistryValue.Text = tostring(summary.Chemistry or 0)
	dashboardLineLabels.Attack.Text = tostring(summary.Attack or 0)
	dashboardLineLabels.Midfield.Text = tostring(summary.Midfield or 0)
	dashboardLineLabels.Defense.Text = tostring(summary.Defense or 0)
end

local function renderProfile(profile: any)
	local coins = 0
	local owned = 0

	if typeof(profile) == "table" then
		if typeof(profile.Coins) == "number" then
			coins = profile.Coins
		end

		if typeof(profile.Inventory) == "table" then
			owned = #profile.Inventory
		end
	end

	coinsLabel.Text = string.format("%d COINS", coins)
	ownedLabel.Text = string.format(
		"%d PLAYER%s",
		owned,
		if owned == 1 then "" else "S"
	)
end

local function clearPitchSlots()
	for _, frame in pairs(pitchSlotFrames) do
		frame:Destroy()
	end

	pitchSlotFrames = {}
	pitchSlotStyles = {}
end

local function clearSlotHighlights()
	for _, style in pairs(pitchSlotStyles) do
		style.Stroke.Color = style.Color
		style.Stroke.Thickness = style.Thickness
		style.Stroke.Transparency = style.Transparency
	end
end

local function highlightSlots(slotKeys: any)
	clearSlotHighlights()

	if typeof(slotKeys) ~= "table" then
		return
	end

	for _, slotKey in ipairs(slotKeys) do
		local style = pitchSlotStyles[slotKey]

		if style then
			style.Stroke.Color = COLORS.Green
			style.Stroke.Thickness = 4
			style.Stroke.Transparency = 0
		end
	end
end

local function createPitchSlot(
	slotInfo: any,
	formationSlot: any
)
	local selected = slotInfo.Selected
	local theme = if selected
		then getTheme(selected.Rarity)
		else RARITY_THEME.Common

	local shadow = create("Frame", {
		Name = slotInfo.SlotKey .. "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(
			formationSlot.X + 0.005,
			formationSlot.Y + 0.012
		),
		Size = UDim2.fromScale(0.1, 0.19),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
	}, pitchInner) :: Frame
	addAspectConstraint(shadow, 0.78, Enum.DominantAxis.Height)
	addSizeConstraint(shadow, Vector2.new(92, 112))
	addCorner(shadow, 0.16)

	local slotFrame = create("Frame", {
		Name = slotInfo.SlotKey,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(
			formationSlot.X,
			formationSlot.Y
		),
		Size = UDim2.fromScale(0.1, 0.19),
		BackgroundColor3 = if selected
			then theme.Bottom
			else Color3.fromRGB(8, 38, 21),
		BackgroundTransparency = if selected then 0 else 0.06,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, pitchInner) :: Frame
	addAspectConstraint(slotFrame, 0.78, Enum.DominantAxis.Height)
	addSizeConstraint(slotFrame, Vector2.new(92, 112))
	addCorner(slotFrame, 0.16)

	if selected then
		addGradient(slotFrame, theme.Top, theme.Bottom, 135)
	end

	local strokeColor = if selected
		then theme.Accent
		else Color3.fromRGB(211, 234, 216)

	local stroke = addStroke(
		slotFrame,
		strokeColor,
		if selected then 2 else 1,
		if selected then 0.12 else 0.38
	)

	pitchSlotStyles[slotInfo.SlotKey] = {
		Stroke = stroke,
		Color = strokeColor,
		Thickness = if selected then 2 else 1,
		Transparency = if selected then 0.12 else 0.38,
	}

	local slotLabel = create("TextLabel", {
		Name = "Slot",
		Position = UDim2.fromScale(0.08, 0.05),
		Size = UDim2.fromScale(0.84, 0.16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = slotInfo.Label,
		TextColor3 = COLORS.White,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, slotFrame) :: TextLabel
	addTextConstraint(slotLabel, 8, 12)

	if selected then
		local overall = create("TextLabel", {
			Name = "Overall",
			Position = UDim2.fromScale(0.08, 0.22),
			Size = UDim2.fromScale(0.84, 0.3),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = tostring(
				slotInfo.EffectiveOverall
					or selected.Overall
			),
			TextColor3 = theme.Accent,
			TextScaled = true,
		}, slotFrame) :: TextLabel
		addTextConstraint(overall, 17, 28)

		local name = create("TextLabel", {
			Name = "Name",
			Position = UDim2.fromScale(0.06, 0.55),
			Size = UDim2.fromScale(0.88, 0.34),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			Text = selected.DisplayName,
			TextColor3 = COLORS.White,
			TextScaled = true,
			TextWrapped = true,
		}, slotFrame) :: TextLabel
		addTextConstraint(name, 8, 11)
	else
		local position = create("TextLabel", {
			Name = "Position",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.58),
			Size = UDim2.fromScale(0.84, 0.38),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = slotInfo.Position,
			TextColor3 = Color3.fromRGB(216, 237, 221),
			TextScaled = true,
		}, slotFrame) :: TextLabel
		addTextConstraint(position, 14, 23)
	end

	pitchSlotFrames[slotInfo.SlotKey] = slotFrame
	pitchSlotFrames[slotInfo.SlotKey .. "Shadow"] = shadow
end

local function renderPitch(draft: any)
	local formationId = if draft
		then draft.FormationId
		else GameConfig.DefaultFormationId

	local formation = Formations[formationId]

	if not formation then
		warn("Formation missing:", formationId)
		return
	end

	clearPitchSlots()

	if draft and typeof(draft.Slots) == "table" then
		for index, slotInfo in ipairs(draft.Slots) do
			local formationSlot = formation.Slots[index]

			if formationSlot then
				createPitchSlot(slotInfo, formationSlot)
			end
		end
	else
		for _, formationSlot in ipairs(formation.Slots) do
			createPitchSlot({
				SlotKey = formationSlot.Key,
				Label = formationSlot.Label,
				Position = formationSlot.Position,
				Selected = nil,
			}, formationSlot)
		end
	end
end

local function clearCards()
	for _, slot in ipairs(optionSlots) do
		slot.Button:Destroy()
	end

	optionSlots = {}
end

local function addContainedShine(
	visual: Frame,
	color: Color3,
	duration: number
)
	local shineMask = create("Frame", {
		Name = "ShineMask",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 4,
	}, visual) :: Frame

	local shine = create("Frame", {
		Name = "ContainedShine",
		Position = UDim2.fromScale(-0.28, -0.16),
		Size = UDim2.fromScale(0.1, 1.24),
		Rotation = 16,
		BackgroundColor3 = color,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, shineMask) :: Frame

	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, shine)

	tween(
		shine,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut,
			-1,
			false,
			0.35
		),
		{ Position = UDim2.fromScale(1.06, -0.12) }
	)
end

local function createCardBack(
	order: number,
	cardWidth: number
): OptionSlot
	local button = create("TextButton", {
		Name = "CardBack",
		Size = UDim2.fromScale(cardWidth, 0.93),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Active = false,
		LayoutOrder = order,
		ClipsDescendants = true,
	}, cardsStage) :: TextButton
	addAspectConstraint(button, 0.68, Enum.DominantAxis.Height)
	addSizeConstraint(button, Vector2.new(250, 370))

	local shadow = create("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.525, 0.53),
		Size = UDim2.fromScale(0.96, 0.96),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.52,
		BorderSizePixel = 0,
	}, button) :: Frame
	addCorner(shadow, 0.08)

	local visual = create("Frame", {
		Name = "Visual",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.96, 0.96),
		BackgroundColor3 = Color3.fromRGB(7, 13, 28),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, button) :: Frame
	addCorner(visual, 0.08)
	addStroke(visual, Color3.fromRGB(110, 205, 255), 3, 0.1)

	local outerGlow = create("Frame", {
		Name = "OuterGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.985, 0.985),
		BackgroundColor3 = Color3.fromRGB(61, 169, 255),
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
	}, visual) :: Frame
	addCorner(outerGlow, 0.08)

	local shell = create("Frame", {
		Name = "Shell",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.95),
		BackgroundColor3 = Color3.fromRGB(4, 9, 24),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, visual) :: Frame
	addCorner(shell, 0.075)
	addStroke(shell, Color3.fromRGB(183, 234, 255), 1, 0.7)

	local shellGradient = create("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 54, 134)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(6, 20, 70)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 10, 38)),
		}),
	}, shell) :: UIGradient

	tween(
		shellGradient,
		TweenInfo.new(
			3.2,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		),
		{ Rotation = 220 }
	)

	local stripeMask = create("Frame", {
		Name = "StripeMask",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	}, shell) :: Frame

	for stripeIndex = 1, 7 do
		create("Frame", {
			Name = "Stripe",
			Position = UDim2.fromScale(
				0.03 + (stripeIndex - 1) * 0.145,
				-0.08
			),
			Size = UDim2.fromScale(0.045, 1.18),
			Rotation = 24,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, stripeMask)
	end

	local topRibbon = create("Frame", {
		Name = "TopRibbon",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.045),
		Size = UDim2.fromScale(0.78, 0.085),
		BackgroundColor3 = Color3.fromRGB(7, 19, 44),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, shell) :: Frame
	addCorner(topRibbon, 0.22)
	addStroke(topRibbon, Color3.fromRGB(102, 204, 255), 1, 0.45)

	local topRibbonText = create("TextLabel", {
		Name = "TopRibbonText",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "DYNASTY DRAFT",
		TextColor3 = Color3.fromRGB(213, 242, 255),
		TextScaled = true,
		ZIndex = 4,
	}, topRibbon) :: TextLabel
	addTextConstraint(topRibbonText, 8, 13)

	local portalGlow = create("Frame", {
		Name = "PortalGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.41),
		Size = UDim2.fromScale(0.62, 0.45),
		BackgroundColor3 = Color3.fromRGB(62, 221, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, shell) :: Frame
	addAspectConstraint(portalGlow, 1, Enum.DominantAxis.Height)
	addCorner(portalGlow, 0.5)

	local portal = create("Frame", {
		Name = "Portal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.41),
		Size = UDim2.fromScale(0.56, 0.4),
		BackgroundColor3 = Color3.fromRGB(5, 17, 43),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, shell) :: Frame
	addAspectConstraint(portal, 1, Enum.DominantAxis.Height)
	addCorner(portal, 0.5)
	addStroke(portal, Color3.fromRGB(63, 221, 255), 4, 0.05)

	local innerPortal = create("Frame", {
		Name = "InnerPortal",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.78),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.96,
		BorderSizePixel = 0,
		ZIndex = 3,
	}, portal) :: Frame
	addCorner(innerPortal, 0.5)

	local question = create("TextLabel", {
		Name = "Question",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "?",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		ZIndex = 4,
	}, innerPortal) :: TextLabel
	addTextConstraint(question, 50, 88)

	for dotIndex = 1, 6 do
		local angle = (dotIndex / 6) * math.pi * 2
		local dot = create("Frame", {
			Name = "OrbitDot",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(
				0.5 + math.cos(angle) * 0.38,
				0.5 + math.sin(angle) * 0.38
			),
			Size = UDim2.fromScale(0.05, 0.05),
			BackgroundColor3 = Color3.fromRGB(116, 227, 255),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, portal) :: Frame
		addAspectConstraint(dot, 1, Enum.DominantAxis.Width)
		addCorner(dot, 0.5)

		tween(
			dot,
			TweenInfo.new(
				0.85 + dotIndex * 0.08,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{
				BackgroundTransparency = 0.85,
				Size = UDim2.fromScale(0.03, 0.03),
			}
		)
	end

	local mysteryLabel = create("TextLabel", {
		Name = "MysteryLabel",
		Position = UDim2.fromScale(0.08, 0.71),
		Size = UDim2.fromScale(0.84, 0.12),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "MYSTERY PICK",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		ZIndex = 4,
	}, shell) :: TextLabel
	addTextConstraint(mysteryLabel, 16, 27)

	local subtitle = create("TextLabel", {
		Name = "Subtitle",
		Position = UDim2.fromScale(0.08, 0.82),
		Size = UDim2.fromScale(0.84, 0.07),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = string.format("CARD %d", order),
		TextColor3 = Color3.fromRGB(168, 214, 255),
		TextScaled = true,
		ZIndex = 4,
	}, shell) :: TextLabel
	addTextConstraint(subtitle, 9, 15)

	local footer = create("Frame", {
		Name = "Footer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.82, 0.07),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, shell) :: Frame
	addCorner(footer, 0.28)

	local footerText = create("TextLabel", {
		Name = "FooterText",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "ROLL TO REVEAL",
		TextColor3 = Color3.fromRGB(16, 36, 83),
		TextScaled = true,
		ZIndex = 5,
	}, footer) :: TextLabel
	addTextConstraint(footerText, 10, 16)

	addContainedShine(shell, Color3.fromRGB(220, 247, 255), 1.9)

	local scale = addScale(button, 0.82)

	tween(
		scale,
		TweenInfo.new(
			0.32 + order * 0.04,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{ Scale = 1 }
	)

	return {
		Button = button,
		Visual = visual,
		Scale = scale,
		Card = nil,
	}
end

local function addContainedSparkles(
	visual: Frame,
	color: Color3,
	count: number
)
	for index = 1, count do
		local random = Random.new(index * 1879)
		local sparkle = create("Frame", {
			Name = "ContainedSparkle",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(
				random:NextNumber(0.08, 0.92),
				random:NextNumber(0.15, 0.7)
			),
			Size = UDim2.fromScale(
				random:NextNumber(0.018, 0.032),
				random:NextNumber(0.018, 0.032)
			),
			Rotation = 45,
			BackgroundColor3 = color,
			BackgroundTransparency = random:NextNumber(0.1, 0.45),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, visual) :: Frame
		addAspectConstraint(sparkle, 1, Enum.DominantAxis.Width)

		tween(
			sparkle,
			TweenInfo.new(
				random:NextNumber(0.65, 1.15),
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{
				BackgroundTransparency = 0.9,
				Rotation = 135,
			}
		)
	end
end

local function decorateCard(
	visual: Frame,
	card: any,
	theme: CardTheme,
	stroke: UIStroke
)
	local cardType = card.CardType or "Standard"

	local shell = create("Frame", {
		Name = "Shell",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.955, 0.955),
		BackgroundColor3 = Color3.fromRGB(7, 12, 24),
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 1,
		ClipsDescendants = true,
	}, visual) :: Frame
	addCorner(shell, 0.075)
	addStroke(shell, Color3.fromRGB(255, 255, 255), 1, 0.84)

	local shellGradient = addGradient(
		shell,
		theme.Top,
		theme.Bottom,
		135
	)
	shellGradient.Offset = Vector2.new(0, 0)

	local innerFrame = create("Frame", {
		Name = "InnerFrame",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.93, 0.93),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	}, shell) :: Frame
	addCorner(innerFrame, 0.07)
	addStroke(innerFrame, theme.Accent, 2, 0.2)

	local bevelTop = create("Frame", {
		Name = "BevelTop",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.82, 0.06),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, innerFrame) :: Frame
	addCorner(bevelTop, 0.4)

	local bevelBottom = create("Frame", {
		Name = "BevelBottom",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.96),
		Size = UDim2.fromScale(0.82, 0.05),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.92,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, innerFrame) :: Frame
	addCorner(bevelBottom, 0.4)

	local patternMask = create("Frame", {
		Name = "PatternMask",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 2,
	}, innerFrame) :: Frame

	local crestGlow = create("Frame", {
		Name = "CrestGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.39),
		Size = UDim2.fromScale(0.68, 0.48),
		BackgroundColor3 = theme.Glow,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, innerFrame) :: Frame
	addAspectConstraint(crestGlow, 1.02, Enum.DominantAxis.Height)
	addCorner(crestGlow, 0.5)

	local accentLeft = create("Frame", {
		Name = "AccentLeft",
		Position = UDim2.fromScale(0.055, 0.075),
		Size = UDim2.fromScale(0.022, 0.84),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, innerFrame) :: Frame
	addCorner(accentLeft, 0.5)

	local accentRight = create("Frame", {
		Name = "AccentRight",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.945, 0.075),
		Size = UDim2.fromScale(0.022, 0.84),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, innerFrame) :: Frame
	addCorner(accentRight, 0.5)

	local function cornerGem(
		xScale: number,
		yScale: number,
		sizeScale: number,
		color: Color3
	)
		local gem = create("Frame", {
			Name = "CornerGem",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(xScale, yScale),
			Size = UDim2.fromScale(sizeScale, sizeScale),
			Rotation = 45,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.24,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, patternMask) :: Frame
		addAspectConstraint(gem, 1, Enum.DominantAxis.Width)

		tween(
			gem,
			TweenInfo.new(
				0.95 + (xScale * 0.2),
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{
				BackgroundTransparency = 0.82,
				Rotation = 135,
			}
		)
	end

	if cardType == "Rainbow" then
		local rainbow = create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 88, 142)),
				ColorSequenceKeypoint.new(0.18, Color3.fromRGB(255, 217, 72)),
				ColorSequenceKeypoint.new(0.38, Color3.fromRGB(79, 236, 143)),
				ColorSequenceKeypoint.new(0.58, Color3.fromRGB(70, 163, 255)),
				ColorSequenceKeypoint.new(0.79, Color3.fromRGB(189, 92, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 88, 142)),
			}),
		}, innerFrame) :: UIGradient

		tween(
			rainbow,
			TweenInfo.new(
				3.2,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.InOut,
				-1
			),
			{ Rotation = 360 }
		)

		tween(
			stroke,
			TweenInfo.new(
				1.4,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{ Thickness = 5, Transparency = 0 }
		)

		addContainedSparkles(innerFrame, Color3.fromRGB(255, 255, 255), 10)
		addContainedShine(innerFrame, Color3.fromRGB(255, 255, 255), 1.5)
		cornerGem(0.16, 0.19, 0.032, Color3.fromRGB(255, 223, 101))
		cornerGem(0.84, 0.22, 0.03, Color3.fromRGB(87, 214, 255))
		cornerGem(0.2, 0.69, 0.028, Color3.fromRGB(255, 117, 183))
		cornerGem(0.8, 0.66, 0.026, Color3.fromRGB(124, 255, 153))
	elseif cardType == "Eclipse" then
		local eclipseGradient = create("UIGradient", {
			Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 54, 211)),
				ColorSequenceKeypoint.new(0.48, Color3.fromRGB(10, 10, 22)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 15, 86)),
			}),
		}, innerFrame) :: UIGradient

		tween(
			eclipseGradient,
			TweenInfo.new(
				2.8,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{ Rotation = 210 }
		)

		local moonRing = create("Frame", {
			Name = "MoonRing",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.82, 0.19),
			Size = UDim2.fromScale(0.12, 0.12),
			BackgroundColor3 = theme.Accent,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, patternMask) :: Frame
		addAspectConstraint(moonRing, 1, Enum.DominantAxis.Width)
		addCorner(moonRing, 0.5)

		local moonCut = create("Frame", {
			Name = "MoonCut",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.64, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundColor3 = Color3.fromRGB(8, 11, 20),
			BorderSizePixel = 0,
			ZIndex = 4,
		}, moonRing) :: Frame
		addCorner(moonCut, 0.5)

		addContainedSparkles(innerFrame, theme.Accent, 5)
		addContainedShine(innerFrame, Color3.fromRGB(236, 226, 255), 1.85)
	elseif cardType == "RisingStar" then
		local starGradient = create("UIGradient", {
			Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 242, 255)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(26, 105, 198)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 38, 92)),
			}),
		}, innerFrame) :: UIGradient

		tween(
			starGradient,
			TweenInfo.new(
				2.3,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{ Rotation = 205 }
		)

		for index = 1, 5 do
			local ray = create("Frame", {
				Name = "StarRay",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.39),
				Size = UDim2.fromScale(0.014, 0.26),
				Rotation = (index - 1) * 36,
				BackgroundColor3 = theme.Accent,
				BackgroundTransparency = 0.6,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, patternMask) :: Frame
			addCorner(ray, 0.5)
		end

		addContainedSparkles(innerFrame, Color3.fromRGB(214, 252, 255), 8)
		addContainedShine(innerFrame, Color3.fromRGB(219, 254, 255), 1.95)
		cornerGem(0.17, 0.2, 0.03, theme.Accent)
		cornerGem(0.83, 0.26, 0.026, theme.Accent)
	elseif cardType == "Captain" then
		addGradient(
			innerFrame,
			Color3.fromRGB(32, 77, 148),
			Color3.fromRGB(8, 23, 54),
			135
		)

		local captainBand = create("Frame", {
			Name = "CaptainBand",
			Position = UDim2.fromScale(0.09, 0.11),
			Size = UDim2.fromScale(0.38, 0.065),
			Rotation = -10,
			BackgroundColor3 = COLORS.Yellow,
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, patternMask) :: Frame
		addCorner(captainBand, 0.24)

		local captainText = create("TextLabel", {
			Name = "CaptainText",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.23, 0.145),
			Size = UDim2.fromScale(0.16, 0.055),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = "C",
			TextColor3 = Color3.fromRGB(92, 59, 4),
			TextScaled = true,
			Rotation = -10,
			ZIndex = 4,
		}, patternMask) :: TextLabel
		addTextConstraint(captainText, 14, 24)

		local captainSeal = create("Frame", {
			Name = "CaptainSeal",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.84, 0.22),
			Size = UDim2.fromScale(0.11, 0.11),
			BackgroundColor3 = COLORS.Yellow,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, patternMask) :: Frame
		addAspectConstraint(captainSeal, 1, Enum.DominantAxis.Width)
		addCorner(captainSeal, 0.5)

		local sealText = create("TextLabel", {
			Name = "SealText",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = "CAP",
			TextColor3 = Color3.fromRGB(76, 48, 4),
			TextScaled = true,
			ZIndex = 4,
		}, captainSeal) :: TextLabel
		addTextConstraint(sealText, 7, 11)

		addContainedShine(innerFrame, Color3.fromRGB(255, 240, 163), 1.9)
	elseif cardType == "Hero" then
		local heroGradient = create("UIGradient", {
			Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(244, 95, 54)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(148, 30, 37)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(49, 10, 18)),
			}),
		}, innerFrame) :: UIGradient

		tween(
			heroGradient,
			TweenInfo.new(
				2.1,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{ Rotation = 195 }
		)

		for rayIndex = 1, 7 do
			local ray = create("Frame", {
				Name = "HeroRay",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.4),
				Size = UDim2.fromScale(0.022, 0.29),
				Rotation = -54 + (rayIndex - 1) * 18,
				BackgroundColor3 = COLORS.Yellow,
				BackgroundTransparency = 0.74,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, patternMask) :: Frame
			addCorner(ray, 0.5)
		end

		addContainedShine(innerFrame, Color3.fromRGB(255, 234, 154), 1.65)
	elseif cardType == "Legend" then
		local legendGradient = create("UIGradient", {
			Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 219)),
				ColorSequenceKeypoint.new(0.38, Color3.fromRGB(219, 184, 91)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(108, 76, 18)),
			}),
		}, innerFrame) :: UIGradient

		tween(
			legendGradient,
			TweenInfo.new(
				2.9,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				-1,
				true
			),
			{ Rotation = 205 }
		)

		local crown = create("Frame", {
			Name = "CrownPlate",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.07),
			Size = UDim2.fromScale(0.4, 0.08),
			BackgroundColor3 = Color3.fromRGB(255, 244, 203),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 3,
		}, patternMask) :: Frame
		addCorner(crown, 0.28)
		addStroke(crown, Color3.fromRGB(255, 248, 221), 1, 0.5)

		local crownText = create("TextLabel", {
			Name = "CrownText",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			Text = "LEGEND",
			TextColor3 = Color3.fromRGB(112, 75, 18),
			TextScaled = true,
			ZIndex = 4,
		}, crown) :: TextLabel
		addTextConstraint(crownText, 9, 13)

		for index = 1, 5 do
			local leftLeaf = create("TextLabel", {
				Name = "LeftLeaf",
				Position = UDim2.fromScale(0.12, 0.26 + (index - 1) * 0.06),
				Size = UDim2.fromScale(0.055, 0.042),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				Text = "✦",
				TextColor3 = Color3.fromRGB(255, 241, 191),
				TextScaled = true,
				ZIndex = 3,
			}, patternMask) :: TextLabel
			addTextConstraint(leftLeaf, 9, 12)

			local rightLeaf = create("TextLabel", {
				Name = "RightLeaf",
				Position = UDim2.fromScale(0.825, 0.26 + (index - 1) * 0.06),
				Size = UDim2.fromScale(0.055, 0.042),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				Text = "✦",
				TextColor3 = Color3.fromRGB(255, 241, 191),
				TextScaled = true,
				ZIndex = 3,
			}, patternMask) :: TextLabel
			addTextConstraint(rightLeaf, 9, 12)
		end

		addContainedShine(innerFrame, Color3.fromRGB(255, 253, 233), 1.4)
		addContainedSparkles(innerFrame, Color3.fromRGB(255, 244, 203), 6)
	else
		local brushedMask = create("Frame", {
			Name = "BrushedMask",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
		}, patternMask) :: Frame

		for stripeIndex = 1, 5 do
			create("Frame", {
				Name = "BrushedStripe",
				Position = UDim2.fromScale(
					0.1 + (stripeIndex - 1) * 0.16,
					0.08 + (stripeIndex - 1) * 0.11
				),
				Size = UDim2.fromScale(0.34, 0.022),
				Rotation = -18,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, brushedMask)
			addCorner(brushedMask.BrushedStripe, 0.5)
		end

		addContainedShine(innerFrame, Color3.fromRGB(255, 255, 255), 2)
	end
end

local function buildFinalCard(
	slot: OptionSlot,
	card: any
)
	if slot.Visual.Parent then
		slot.Visual:Destroy()
	end

	local theme = getTheme(card.Rarity)

	local visual = create("Frame", {
		Name = "Visual",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.96, 0.96),
		BackgroundColor3 = Color3.fromRGB(6, 11, 20),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, slot.Button) :: Frame
	addCorner(visual, 0.08)

	local stroke = addStroke(
		visual,
		theme.Accent,
		if (card.RevealTier or 1) >= 5 then 4 else 3,
		0.02
	)

	local glow = create("Frame", {
		Name = "OuterGlow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.99, 0.99),
		BackgroundColor3 = theme.Glow,
		BackgroundTransparency = 0.94,
		BorderSizePixel = 0,
	}, visual) :: Frame
	addCorner(glow, 0.08)

	decorateCard(visual, card, theme, stroke)

	slot.Visual = visual
	slot.Card = card
	slot.Button.Name = card.Id

	local headerPanel = create("Frame", {
		Name = "HeaderPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.045),
		Size = UDim2.fromScale(0.9, 0.145),
		BackgroundColor3 = Color3.fromRGB(7, 14, 28),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 6,
	}, visual) :: Frame
	addCorner(headerPanel, 0.22)

	local overall = create("TextLabel", {
		Name = "Overall",
		Position = UDim2.fromScale(0.045, 0.08),
		Size = UDim2.fromScale(0.31, 0.58),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = tostring(card.Overall),
		TextColor3 = Color3.fromRGB(255, 248, 215),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
	}, headerPanel) :: TextLabel
	addTextConstraint(overall, 28, 43)

	local ovrText = create("TextLabel", {
		Name = "OvrText",
		Position = UDim2.fromScale(0.045, 0.67),
		Size = UDim2.fromScale(0.18, 0.17),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "OVR",
		TextColor3 = theme.Accent,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 8,
	}, headerPanel) :: TextLabel
	addTextConstraint(ovrText, 8, 12)

	local rarityMarks = create("TextLabel", {
		Name = "RarityMarks",
		Position = UDim2.fromScale(0.42, 0.08),
		Size = UDim2.fromScale(0.18, 0.18),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = string.rep("★", math.clamp(math.floor((card.RevealTier or 1) / 2) + 1, 1, 4)),
		TextColor3 = theme.Accent,
		TextScaled = true,
		ZIndex = 8,
	}, headerPanel) :: TextLabel
	addTextConstraint(rarityMarks, 8, 12)

	local positionBadge = create("Frame", {
		Name = "PositionBadge",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.955, 0.5),
		Size = UDim2.fromScale(0.26, 0.66),
		BackgroundColor3 = COLORS.White,
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, headerPanel) :: Frame
	addCorner(positionBadge, 0.28)

	local positionText = create("TextLabel", {
		Name = "Position",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = card.Position,
		TextColor3 = COLORS.White,
		TextScaled = true,
		ZIndex = 9,
	}, positionBadge) :: TextLabel
	addTextConstraint(positionText, 13, 20)

	local portraitShell = create("Frame", {
		Name = "PortraitShell",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.41),
		Size = UDim2.fromScale(0.58, 0.42),
		BackgroundColor3 = COLORS.White,
		BackgroundTransparency = 0.95,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 6,
	}, visual) :: Frame
	addAspectConstraint(portraitShell, 1.02, Enum.DominantAxis.Height)
	addCorner(portraitShell, 0.28)
	addStroke(portraitShell, theme.Accent, 3, 0.06)

	local portraitRing = create("Frame", {
		Name = "PortraitRing",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.88, 0.88),
		BackgroundColor3 = COLORS.White,
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, portraitShell) :: Frame
	addAspectConstraint(portraitRing, 1, Enum.DominantAxis.Height)
	addCorner(portraitRing, 0.5)

	local initials = create("TextLabel", {
		Name = "Initials",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = getInitials(card.DisplayName),
		TextColor3 = COLORS.White,
		TextScaled = true,
		ZIndex = 8,
	}, portraitRing) :: TextLabel
	addTextConstraint(initials, 42, 66)

	local namePlate = create("Frame", {
		Name = "NamePlate",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromScale(0.84, 0.105),
		BackgroundColor3 = Color3.fromRGB(7, 14, 28),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, visual) :: Frame
	addCorner(namePlate, 0.22)
	addStroke(namePlate, Color3.fromRGB(255, 255, 255), 1, 0.82)

	local name = create("TextLabel", {
		Name = "PlayerName",
		Position = UDim2.fromScale(0.05, 0.07),
		Size = UDim2.fromScale(0.9, 0.86),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = card.DisplayName,
		TextColor3 = COLORS.White,
		TextScaled = true,
		TextWrapped = true,
		ZIndex = 9,
	}, namePlate) :: TextLabel
	addTextConstraint(name, 16, 25)

	local typeRibbon = create("Frame", {
		Name = "TypeRibbon",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.747),
		Size = UDim2.fromScale(0.7, 0.074),
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, visual) :: Frame
	addCorner(typeRibbon, 0.25)
	addStroke(typeRibbon, Color3.fromRGB(255, 255, 255), 1, 0.7)

	local leftTail = create("Frame", {
		Name = "LeftTail",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(0.065, 0.58),
		Rotation = 24,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, typeRibbon) :: Frame
	addCorner(leftTail, 0.18)

	local rightTail = create("Frame", {
		Name = "RightTail",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(0.065, 0.58),
		Rotation = -24,
		BackgroundColor3 = theme.Accent,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 7,
	}, typeRibbon) :: Frame
	addCorner(rightTail, 0.18)

	local typeText = create("TextLabel", {
		Name = "Type",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = getCardTypeLabel(card.CardType),
		TextColor3 = theme.Ink,
		TextScaled = true,
		ZIndex = 9,
	}, typeRibbon) :: TextLabel
	addTextConstraint(typeText, 10, 16)

	local fitBadge = create("Frame", {
		Name = "FitBadge",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.835),
		Size = UDim2.fromScale(0.88, 0.085),
		BackgroundColor3 = Color3.fromRGB(6, 14, 26),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, visual) :: Frame
	addCorner(fitBadge, 0.18)
	addStroke(
		fitBadge,
		if (card.BestFitQuality or 0) >= 0.999
			then COLORS.Green
			else COLORS.Yellow,
		2,
		0.06
	)

	local fitText = create("TextLabel", {
		Name = "FitText",
		Position = UDim2.fromScale(0.035, 0.06),
		Size = UDim2.fromScale(0.93, 0.88),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = getFitText(card),
		TextColor3 = COLORS.White,
		TextScaled = true,
		ZIndex = 9,
	}, fitBadge) :: TextLabel
	addTextConstraint(fitText, 11, 16)

	local selectBar = create("Frame", {
		Name = "SelectBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.975),
		Size = UDim2.fromScale(0.88, 0.07),
		BackgroundColor3 = COLORS.White,
		BorderSizePixel = 0,
		ZIndex = 8,
	}, visual) :: Frame
	addCorner(selectBar, 0.24)
	addStroke(selectBar, Color3.fromRGB(255, 255, 255), 1, 0.6)

	local selectGradient = addGradient(
		selectBar,
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(219, 225, 236),
		90
	)
	selectGradient.Offset = Vector2.new(0, 0)

	local selectText = create("TextLabel", {
		Name = "Select",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = "ADD TO MY XI",
		TextColor3 = theme.Ink,
		TextScaled = true,
		ZIndex = 9,
	}, selectBar) :: TextLabel
	addTextConstraint(selectText, 11, 17)

	slot.Button.MouseEnter:Connect(function()
		if busy or not optionsRevealed then
			return
		end

		highlightSlots(card.EligibleSlotKeys)

		tween(
			slot.Scale,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad),
			{ Scale = 1.06 }
		)

		tween(
			stroke,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad),
			{ Thickness = 5, Transparency = 0 }
		)

		tween(
			selectBar,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad),
			{ BackgroundColor3 = theme.Accent }
		)
	end)

	slot.Button.MouseLeave:Connect(function()
		clearSlotHighlights()

		tween(
			slot.Scale,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad),
			{ Scale = 1 }
		)

		tween(
			stroke,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad),
			{
				Thickness =
					if (card.RevealTier or 1) >= 5 then 4 else 3,
				Transparency = 0.02,
			}
		)

		tween(
			selectBar,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad),
			{ BackgroundColor3 = COLORS.White }
		)
	end)
end

local function createGlobalParticles(


	color: Color3,
	count: number
)
	for index = 1, count do
		local random = Random.new(index * 9973)
		local particle = create("Frame", {
			Name = "PullParticle",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(
				random:NextNumber(0.12, 0.88),
				random:NextNumber(0.3, 0.62)
			),
			Size = UDim2.fromScale(
				random:NextNumber(0.005, 0.011),
				random:NextNumber(0.009, 0.02)
			),
			Rotation = random:NextInteger(-30, 30),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 106,
		}, effectsLayer) :: Frame
		addCorner(particle, 0.2)

		local duration = random:NextNumber(0.8, 1.4)

		tween(
			particle,
			TweenInfo.new(
				duration,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Position = UDim2.fromScale(
					random:NextNumber(0.04, 0.96),
					random:NextNumber(0.02, 0.98)
				),
				Rotation = random:NextInteger(120, 420),
				BackgroundTransparency = 1,
			}
		)

		task.delay(duration + 0.05, function()
			if particle.Parent then
				particle:Destroy()
			end
		end)
	end
end

local function playHighPull(card: any)
	local tier = card.RevealTier or 1

	if tier < 4 then
		return
	end

	local theme = getTheme(card.Rarity)
	local bannerText = if tier >= 6
		then "ULTIMATE PULL!"
		elseif tier == 5
		then "HUGE PULL!"
		else "SPECIAL PULL!"

	pullBanner.Visible = true
	pullBanner.BackgroundColor3 = theme.Bottom
	pullBanner.BackgroundTransparency = 0.08
	pullBannerStroke.Color = theme.Accent
	pullBannerStroke.Transparency = 0
	pullTierLabel.Text = bannerText
	pullTierLabel.TextColor3 = theme.Accent
	pullPlayerLabel.Text = card.DisplayName
	pullMetaLabel.Text = string.format(
		"%d OVR  •  %s  •  %s",
		card.Overall,
		card.Position,
		getCardTypeLabel(card.CardType)
	)

	pullBannerScale.Scale = 0.62
	tween(
		pullBannerScale,
		TweenInfo.new(
			0.32,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{ Scale = 1 }
	)

	screenFlash.BackgroundColor3 = theme.Glow
	screenFlash.BackgroundTransparency = if tier >= 5 then 0.35 else 0.55

	tween(
		screenFlash,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad),
		{ BackgroundTransparency = 1 }
	)

	tween(
		appScale,
		TweenInfo.new(
			0.14,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out,
			0,
			true
		),
		{ Scale = if tier >= 5 then 1.025 else 1.012 }
	)

	createGlobalParticles(
		theme.Accent,
		if tier >= 5 then 28 else 16
	)

	task.delay(if tier >= 5 then 1.15 else 0.8, function()
		if pullBanner.Visible then
			tween(
				pullBannerScale,
				TweenInfo.new(
					0.22,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.In
				),
				{ Scale = 0.65 }
			)

			task.delay(0.22, function()
				pullBanner.Visible = false
			end)
		end
	end)
end

local function animateReveal(
	slot: OptionSlot,
	card: any,
	order: number,
	generation: number
): boolean
	local spinner = slot.Visual:FindFirstChild("Mystery")
	local question = if spinner
		then spinner:FindFirstChild("Question")
		else nil

	for tickIndex = 1, 7 + order do
		if generation ~= revealGeneration then
			return false
		end

		if question and question:IsA("TextLabel") then
			question.Text = tostring(
				Random.new(
					order * 1000 + tickIndex
				):NextInteger(65, 97)
			)
		end

		tween(
			slot.Scale,
			TweenInfo.new(
				0.055,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out,
				0,
				true
			),
			{ Scale = 0.92 }
		)

		task.wait(0.075)
	end

	if generation ~= revealGeneration then
		return false
	end

	tween(
		slot.Scale,
		TweenInfo.new(
			0.15,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		),
		{ Scale = 0.72 }
	)

	task.wait(0.15)

	if generation ~= revealGeneration then
		return false
	end

	buildFinalCard(slot, card)

	tween(
		slot.Scale,
		TweenInfo.new(
			0.34,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{ Scale = 1 }
	)

	playHighPull(card)

	task.wait(
		if (card.RevealTier or 1) >= 5
			then 0.8
			elseif (card.RevealTier or 1) >= 4
			then 0.42
			else 0.15
	)

	return true
end

local renderDraft: (any) -> ()

local function selectCard(slot: OptionSlot)
	local card = slot.Card

	if busy
		or not optionsRevealed
		or not currentDraft
		or not card
	then
		return
	end

	busy = true
	clearSlotHighlights()

	for _, optionSlot in ipairs(optionSlots) do
		optionSlot.Button.Active = false
	end

	setFooterStatus(
		"Adding "
			.. card.DisplayName
			.. " to "
			.. tostring(card.BestSlotLabel or "your XI")
			.. "..."
	)

	tween(
		slot.Scale,
		TweenInfo.new(
			0.16,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.In
		),
		{ Scale = 0.88 }
	)

	local success, response = invokeServer(
		SelectFootballer,
		currentDraft.DraftId,
		card.Id
	)

	busy = false

	if not success then
		setFooterStatus("Could not contact the server.", true)

		for _, optionSlot in ipairs(optionSlots) do
			optionSlot.Button.Active = true
		end

		return
	end

	if typeof(response) ~= "table"
		or response.Ok ~= true
		or typeof(response.Data) ~= "table"
	then
		setFooterStatus(
			if typeof(response) == "table"
				then response.Error or "Selection failed."
				else "Selection failed.",
			true
		)

		for _, optionSlot in ipairs(optionSlots) do
			optionSlot.Button.Active = true
		end

		return
	end

	renderProfile(response.Data.Profile)
	renderDraft(response.Data.Draft)
end

local function renderCardBacks(options: { any })
	clearCards()

	local count = math.max(1, #options)
	local width = math.clamp(0.89 / count, 0.155, 0.175)

	for index, _ in ipairs(options) do
		local slot = createCardBack(index, width)
		table.insert(optionSlots, slot)
	end
end

local function revealOptions()
	if busy
		or optionsRevealed
		or not currentDraft
		or #pendingOptions == 0
	then
		return
	end

	busy = true
	rollAction = "WAIT"
	setButtonEnabled(rollActionButton, false)
	rollActionButton.Text = "ROLLING..."
	setFooterStatus("Rolling five mixed-position players...")

	local generation = revealGeneration

	for index, card in ipairs(pendingOptions) do
		local slot = optionSlots[index]

		if not slot then
			break
		end

		local completed = animateReveal(
			slot,
			card,
			index,
			generation
		)

		if not completed then
			busy = false
			return
		end
	end

	if generation ~= revealGeneration then
		busy = false
		return
	end

	for _, slot in ipairs(optionSlots) do
		local capturedSlot = slot

		capturedSlot.Button.Active = true
		capturedSlot.Button.Activated:Connect(function()
			selectCard(capturedSlot)
		end)
	end

	optionsRevealed = true
	busy = false
	rollAction = "CHOOSE"
	rollActionButton.Text = "CHOOSE A PLAYER"
	setButtonEnabled(rollActionButton, false)
	setFooterStatus(
		"Choose any card. The large position bar shows exactly where it can play."
	)
end

local function showPitchView()
	pitchView.Visible = true
	rollView.Visible = false
	viewingSquadDuringDraft = currentDraft ~= nil
end

local function showRollView()
	if not currentDraft or currentDraft.IsComplete then
		return
	end

	pitchView.Visible = false
	rollView.Visible = true
	viewingSquadDuringDraft = false
end

local function setDashboardButton(
	action: string,
	text: string,
	enabled: boolean
)
	dashboardAction = action
	dashboardButton.Text = text
	setButtonEnabled(dashboardButton, enabled)
end

local function renderCompletion(summary: any)
	setTextStatus(
		"DYNASTY XI COMPLETE!",
		string.format(
			"FINAL OVR %d  •  CHEM %d  •  ATT %d  •  MID %d  •  DEF %d",
			summary.Overall or 0,
			summary.Chemistry or 0,
			summary.Attack or 0,
			summary.Midfield or 0,
			summary.Defense or 0
		)
	)

	setDashboardButton(
		"START",
		string.format("NEW DRAFT  •  %d", GameConfig.DraftCost),
		true
	)

	screenFlash.BackgroundColor3 = COLORS.Green
	screenFlash.BackgroundTransparency = 0.45
	tween(
		screenFlash,
		TweenInfo.new(0.7, Enum.EasingStyle.Quad),
		{ BackgroundTransparency = 1 }
	)
	createGlobalParticles(COLORS.Green, 34)
	createGlobalParticles(COLORS.Yellow, 22)
end

renderDraft = function(draft: any)
	revealGeneration += 1
	currentDraft = draft
	pendingOptions = {}
	optionsRevealed = false
	busy = false
	clearSlotHighlights()

	renderPitch(draft)

	if not draft then
		updateTeamSummary(nil)
		progressFill.Size = UDim2.fromScale(0, 1)
		progressLabel.Text = "0 / 11 PLAYERS"

		setTextStatus(
			"READY TO DRAFT",
			"Roll five players each round and build your starting XI."
		)

		setDashboardButton(
			"START",
			string.format(
				"START DRAFT  •  %d",
				GameConfig.DraftCost
			),
			true
		)

		showPitchView()
		return
	end

	local summary = draft.TeamSummary
	updateTeamSummary(summary)

	local total = draft.TotalPicks or 11
	local current = draft.CurrentPickIndex or 1
	local filled = if summary and summary.FilledSlots
		then summary.FilledSlots
		else math.max(0, current - 1)

	progressFill.Size = UDim2.fromScale(
		math.clamp(filled / total, 0, 1),
		1
	)
	progressLabel.Text = string.format(
		"%d / %d PLAYERS",
		filled,
		total
	)

	if draft.IsComplete then
		renderCompletion(summary or {})
		showPitchView()
		return
	end

	local options = draft.CurrentOptions

	if typeof(options) ~= "table" or #options == 0 then
		setTextStatus(
			"NO VALID PICKS",
			"The remaining squad cannot be filled by the current catalog.",
			true
		)
		setDashboardButton("ERROR", "NO OPTIONS", false)
		showPitchView()
		return
	end

	for _, option in ipairs(options) do
		table.insert(pendingOptions, option)
	end

	pickBadgeText.Text = string.format(
		"%d/%d",
		current,
		total
	)
	rollTitle.Text = "ROLL YOUR NEXT FIVE"
	rollSubtitle.Text = string.format(
		"%d squad positions still need players.",
		total - filled
	)

	renderCardBacks(pendingOptions)

	rollAction = "ROLL"
	rollActionButton.Text = string.format(
		"ROLL %d PICKS",
		#pendingOptions
	)
	setButtonEnabled(rollActionButton, true)
	setFooterStatus(
		"Press ROLL PICKS. Every revealed player can fill an open position."
	)

	setTextStatus(
		"DRAFT IN PROGRESS",
		string.format(
			"%d of %d positions filled. Roll your next choices.",
			filled,
			total
		)
	)
	setDashboardButton("RETURN", "RETURN TO PICKS", true)
	showRollView()
end

local function requestDraft()
	if busy then
		return
	end

	busy = true
	setDashboardButton("WAIT", "OPENING DRAFT...", false)
	setTextStatus(
		"OPENING DRAFT ROOM",
		"Generating five valid mixed-position choices..."
	)

	local success, response = invokeServer(StartDraft)
	busy = false

	if not success then
		setTextStatus(
			"SERVER ERROR",
			"Could not contact the server.",
			true
		)
		setDashboardButton(
			"START",
			string.format(
				"START DRAFT  •  %d",
				GameConfig.DraftCost
			),
			true
		)
		return
	end

	if typeof(response) ~= "table"
		or response.Ok ~= true
		or typeof(response.Data) ~= "table"
	then
		setTextStatus(
			"DRAFT FAILED",
			if typeof(response) == "table"
				then response.Error or "Unable to start draft."
				else "Unable to start draft.",
			true
		)
		setDashboardButton(
			"START",
			string.format(
				"START DRAFT  •  %d",
				GameConfig.DraftCost
			),
			true
		)
		return
	end

	renderProfile(response.Data.Profile)
	renderDraft(response.Data.Draft)
end

dashboardButton.MouseEnter:Connect(function()
	if not dashboardButton.Active then
		return
	end

	tween(
		dashboardButtonScale,
		TweenInfo.new(0.13, Enum.EasingStyle.Quad),
		{ Scale = 1.035 }
	)
end)

dashboardButton.MouseLeave:Connect(function()
	tween(
		dashboardButtonScale,
		TweenInfo.new(0.13, Enum.EasingStyle.Quad),
		{ Scale = 1 }
	)
end)

dashboardButton.Activated:Connect(function()
	if busy or not dashboardButton.Active then
		return
	end

	if dashboardAction == "START" then
		requestDraft()
	elseif dashboardAction == "RETURN" then
		showRollView()
	end
end)

rollActionButton.MouseEnter:Connect(function()
	if not rollActionButton.Active then
		return
	end

	tween(
		rollButtonScale,
		TweenInfo.new(0.13, Enum.EasingStyle.Quad),
		{ Scale = 1.035 }
	)
end)

rollActionButton.MouseLeave:Connect(function()
	tween(
		rollButtonScale,
		TweenInfo.new(0.13, Enum.EasingStyle.Quad),
		{ Scale = 1 }
	)
end)

rollActionButton.Activated:Connect(function()
	if busy or not rollActionButton.Active then
		return
	end

	if rollAction == "ROLL" then
		revealOptions()
	end
end)

viewSquadButton.Activated:Connect(function()
	if not currentDraft then
		return
	end

	showPitchView()
	setDashboardButton("RETURN", "RETURN TO PICKS", true)
end)

local function loadProfile()
	setDashboardButton("WAIT", "LOADING CLUB...", false)
	setTextStatus("LOADING CLUB", "Preparing your draft room...")

	local success, response = invokeServer(GetProfile)

	if not success then
		setTextStatus(
			"SERVER ERROR",
			"Could not contact the server.",
			true
		)
		setDashboardButton("START", "RETRY", true)
		return
	end

	if typeof(response) ~= "table"
		or response.Ok ~= true
		or typeof(response.Data) ~= "table"
	then
		setTextStatus(
			"LOAD FAILED",
			if typeof(response) == "table"
				then response.Error or "Unable to load club."
				else "Unable to load club.",
			true
		)
		setDashboardButton("START", "RETRY", true)
		return
	end

	renderProfile(response.Data.Profile)
	renderDraft(nil)
end

task.defer(loadProfile)
