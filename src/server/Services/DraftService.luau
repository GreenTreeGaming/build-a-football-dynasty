--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Utility = Shared:WaitForChild("Utility")

local Footballers = require(Config:WaitForChild("Footballers"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local Formations = require(Config:WaitForChild("Formations"))
local WeightedRandom = require(Utility:WaitForChild("WeightedRandom"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

type PublicFootballer = {
	Id: string,
	DisplayName: string,
	Position: string,
	Overall: number,
	Rarity: string,
	Nation: string?,
	Club: string?,
}

type DraftSlotState = {
	SlotKey: string,
	Label: string,
	Position: string,
	Selected: PublicFootballer?,
}

type DraftSession = {
	DraftId: string,
	FormationId: string,
	FormationName: string,
	ExpiresAt: number,
	CurrentPickIndex: number,
	Slots: { DraftSlotState },
	CurrentOptions: { PublicFootballer },
	IsComplete: boolean,
}

local DraftService = {}

local random = Random.new()

local activeDrafts: { [Player]: DraftSession } = {}
local lastDraftRequestAt: { [Player]: number } = {}

local POSITION_COMPATIBILITY: { [string]: { string } } = {
	GK = { "GK" },

	LB = { "LB", "RB", "CB" },
	CB = { "CB", "LB", "RB", "CDM" },
	RB = { "RB", "LB", "CB" },

	CDM = { "CDM", "CM", "CB" },
	CM = { "CM", "CDM", "CAM" },
	CAM = { "CAM", "CM", "RW", "LW" },

	LW = { "LW", "RW", "ST", "CAM" },
	RW = { "RW", "LW", "ST", "CAM" },
	ST = { "ST", "LW", "RW", "CAM" },
}

local function success(data: any)
	return {
		Ok = true,
		Data = data,
	}
end

local function failure(message: string)
	return {
		Ok = false,
		Error = message,
	}
end

local function copyPublicFootballer(card: PublicFootballer): PublicFootballer
	return {
		Id = card.Id,
		DisplayName = card.DisplayName,
		Position = card.Position,
		Overall = card.Overall,
		Rarity = card.Rarity,
		Nation = card.Nation,
		Club = card.Club,
	}
end

local function toPublicFootballer(definition: any): PublicFootballer
	return {
		Id = definition.Id,
		DisplayName = definition.DisplayName,
		Position = definition.Position,
		Overall = definition.Overall,
		Rarity = definition.Rarity,
		Nation = definition.Nation,
		Club = definition.Club,
	}
end

local function serializeDraft(draft: DraftSession)
	local slots = table.create(#draft.Slots)

	for index, slot in ipairs(draft.Slots) do
		table.insert(slots, {
			Index = index,
			SlotKey = slot.SlotKey,
			Label = slot.Label,
			Position = slot.Position,
			Selected = if slot.Selected then copyPublicFootballer(slot.Selected) else nil,
		})
	end

	local options = table.create(#draft.CurrentOptions)
	for _, option in ipairs(draft.CurrentOptions) do
		table.insert(options, copyPublicFootballer(option))
	end

	local activeSlot = nil
	if not draft.IsComplete then
		activeSlot = draft.Slots[draft.CurrentPickIndex]
	end

	return {
		DraftId = draft.DraftId,
		FormationId = draft.FormationId,
		FormationName = draft.FormationName,
		CurrentPickIndex = draft.CurrentPickIndex,
		TotalPicks = #draft.Slots,
		IsComplete = draft.IsComplete,
		ExpiresIn = math.max(0, math.ceil(draft.ExpiresAt - os.clock())),
		ActiveSlotKey = if activeSlot then activeSlot.SlotKey else nil,
		ActiveSlotLabel = if activeSlot then activeSlot.Label else nil,
		ActivePosition = if activeSlot then activeSlot.Position else nil,
		Slots = slots,
		CurrentOptions = options,
	}
end

local function isCompatible(slotPosition: string, footballerPosition: string): boolean
	local compatible = POSITION_COMPATIBILITY[slotPosition]
	if not compatible then
		return footballerPosition == slotPosition
	end

	return table.find(compatible, footballerPosition) ~= nil
end

local function buildCandidatePool(slotPosition: string, excludedIds: { [string]: boolean }): { any }
	local exact = {}
	local compatible = {}
	local fallback = {}
	local seen: { [string]: boolean } = {}

	for _, footballer in ipairs(Footballers) do
		if not excludedIds[footballer.Id] then
			table.insert(fallback, footballer)

			if footballer.Position == slotPosition then
				table.insert(exact, footballer)
				seen[footballer.Id] = true
			end
		end
	end

	for _, footballer in ipairs(Footballers) do
		if not excludedIds[footballer.Id] and not seen[footballer.Id] then
			if isCompatible(slotPosition, footballer.Position) then
				table.insert(compatible, footballer)
				seen[footballer.Id] = true
			end
		end
	end

	local pool = {}

	for _, footballer in ipairs(exact) do
		table.insert(pool, footballer)
	end

	for _, footballer in ipairs(compatible) do
		table.insert(pool, footballer)
	end

	if #pool < GameConfig.DraftChoicesPerPick then
		for _, footballer in ipairs(fallback) do
			if not seen[footballer.Id] then
				table.insert(pool, footballer)
				seen[footballer.Id] = true
			end
		end
	end

	return pool
end

local function buildOptionsForSlot(draft: DraftSession, slotPosition: string): { PublicFootballer }
	local excludedIds: { [string]: boolean } = {}

	for _, slot in ipairs(draft.Slots) do
		if slot.Selected then
			excludedIds[slot.Selected.Id] = true
		end
	end

	local candidates = buildCandidatePool(slotPosition, excludedIds)

	local pickedDefinitions = WeightedRandom.pickUnique(
		candidates,
		GameConfig.DraftChoicesPerPick,
		function(footballer)
			local baseWeight = footballer.Weight or 1

			if footballer.Position == slotPosition then
				return baseWeight * 3
			end

			if isCompatible(slotPosition, footballer.Position) then
				return baseWeight * 1.5
			end

			return baseWeight * 0.35
		end,
		random
	)

	local publicCards = table.create(#pickedDefinitions)
	for _, definition in ipairs(pickedDefinitions) do
		table.insert(publicCards, toPublicFootballer(definition))
	end

	return publicCards
end

local function createDraftSession(): DraftSession
	local formation = Formations[GameConfig.DefaultFormationId]
	assert(formation, "Default formation not found")

	local slots = table.create(#formation.Slots)

	for _, formationSlot in ipairs(formation.Slots) do
		table.insert(slots, {
			SlotKey = formationSlot.Key,
			Label = formationSlot.Label,
			Position = formationSlot.Position,
			Selected = nil,
		})
	end

	local draft: DraftSession = {
		DraftId = HttpService:GenerateGUID(false),
		FormationId = formation.Id,
		FormationName = formation.Name,
		ExpiresAt = os.clock() + GameConfig.DraftLifetimeSeconds,
		CurrentPickIndex = 1,
		Slots = slots,
		CurrentOptions = {},
		IsComplete = false,
	}

	draft.CurrentOptions = buildOptionsForSlot(draft, draft.Slots[1].Position)

	return draft
end

function DraftService.StartDraft(player: Player)
	local now = os.clock()

	local existingDraft = activeDrafts[player]
	if existingDraft then
		if now < existingDraft.ExpiresAt and not existingDraft.IsComplete then
			return success({
				Draft = serializeDraft(existingDraft),
				Profile = ProfileService.GetSnapshot(player),
			})
		end

		activeDrafts[player] = nil
	end

	local previousRequest = lastDraftRequestAt[player]
	if previousRequest and now - previousRequest < GameConfig.DraftRequestCooldownSeconds then
		return failure("Please wait before opening another draft.")
	end

	lastDraftRequestAt[player] = now

	if not ProfileService.SpendCoins(player, GameConfig.DraftCost) then
		return failure(string.format("You need %d coins to start a draft.", GameConfig.DraftCost))
	end

	local draft = createDraftSession()
	activeDrafts[player] = draft

	return success({
		Draft = serializeDraft(draft),
		Profile = ProfileService.GetSnapshot(player),
	})
end

function DraftService.SelectFootballer(player: Player, draftId: any, footballerId: any)
	if typeof(draftId) ~= "string" then
		return failure("Invalid draft ID.")
	end

	if typeof(footballerId) ~= "string" then
		return failure("Invalid footballer ID.")
	end

	local draft = activeDrafts[player]
	if not draft then
		return failure("You do not have an active draft.")
	end

	if os.clock() >= draft.ExpiresAt then
		activeDrafts[player] = nil
		return failure("Your draft expired.")
	end

	if draft.DraftId ~= draftId then
		return failure("That draft is no longer active.")
	end

	if draft.IsComplete then
		return failure("This draft is already complete.")
	end

	local activeSlot = draft.Slots[draft.CurrentPickIndex]
	if not activeSlot then
		return failure("No active draft slot exists.")
	end

	local chosenCard: PublicFootballer? = nil
	for _, option in ipairs(draft.CurrentOptions) do
		if option.Id == footballerId then
			chosenCard = option
			break
		end
	end

	if not chosenCard then
		return failure("That footballer was not offered for this pick.")
	end

	activeSlot.Selected = copyPublicFootballer(chosenCard)
	ProfileService.AddFootballer(player, chosenCard.Id)

	local selectedPayload = copyPublicFootballer(chosenCard)

	if draft.CurrentPickIndex >= #draft.Slots then
		draft.IsComplete = true
		draft.CurrentOptions = {}

		local serializedCompletedDraft = serializeDraft(draft)
		activeDrafts[player] = nil

		return success({
			Selected = selectedPayload,
			Draft = serializedCompletedDraft,
			Profile = ProfileService.GetSnapshot(player),
		})
	end

	draft.CurrentPickIndex += 1
	local nextSlot = draft.Slots[draft.CurrentPickIndex]
	draft.CurrentOptions = buildOptionsForSlot(draft, nextSlot.Position)

	return success({
		Selected = selectedPayload,
		Draft = serializeDraft(draft),
		Profile = ProfileService.GetSnapshot(player),
	})
end

function DraftService.CleanupPlayer(player: Player)
	activeDrafts[player] = nil
	lastDraftRequestAt[player] = nil
end

return table.freeze(DraftService)