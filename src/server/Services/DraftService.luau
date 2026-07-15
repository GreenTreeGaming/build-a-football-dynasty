--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")

local Footballers = require(Config:WaitForChild("Footballers"))
local GameConfig = require(Config:WaitForChild("GameConfig"))
local Formations = require(Config:WaitForChild("Formations"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local TeamRatingService = require(
	script.Parent:WaitForChild("TeamRatingService")
)

type PublicFootballer = {
	Id: string,
	DisplayName: string,
	Position: string,
	Overall: number,
	Rarity: string,
	CardType: string,
	Archetype: string,
	Nation: string,
	Club: string,
	League: string,
	RevealTier: number,

	EligibleSlotKeys: { string },
	EligibleSlotLabels: { string },
	BestSlotKey: string,
	BestSlotLabel: string,
	BestFitQuality: number,
}

type DraftSlotState = {
	SlotKey: string,
	Label: string,
	Position: string,
	Selected: PublicFootballer?,
	FitQuality: number?,
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

type Candidate = {
	Definition: any,
	EligibleSlots: { any },
	BestSlot: any,
}

local DraftService = {}

local random = Random.new()
local activeDrafts: { [Player]: DraftSession } = {}
local lastDraftRequestAt: { [Player]: number } = {}

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

local function copyStringArray(values: { string }): { string }
	local copy = table.create(#values)

	for _, value in ipairs(values) do
		table.insert(copy, value)
	end

	return copy
end

local function copyPublicFootballer(
	card: PublicFootballer
): PublicFootballer
	return {
		Id = card.Id,
		DisplayName = card.DisplayName,
		Position = card.Position,
		Overall = card.Overall,
		Rarity = card.Rarity,
		CardType = card.CardType,
		Archetype = card.Archetype,
		Nation = card.Nation,
		Club = card.Club,
		League = card.League,
		RevealTier = card.RevealTier,

		EligibleSlotKeys =
			copyStringArray(card.EligibleSlotKeys),

		EligibleSlotLabels =
			copyStringArray(card.EligibleSlotLabels),

		BestSlotKey = card.BestSlotKey,
		BestSlotLabel = card.BestSlotLabel,
		BestFitQuality = card.BestFitQuality,
	}
end

local function toPublicFootballer(
	candidate: Candidate
): PublicFootballer
	local slotKeys = table.create(#candidate.EligibleSlots)
	local slotLabels = table.create(#candidate.EligibleSlots)

	for _, eligibleSlot in ipairs(candidate.EligibleSlots) do
		table.insert(slotKeys, eligibleSlot.SlotKey)
		table.insert(slotLabels, eligibleSlot.Label)
	end

	local definition = candidate.Definition

	return {
		Id = definition.Id,
		DisplayName = definition.DisplayName,
		Position = definition.Position,
		Overall = definition.Overall,
		Rarity = definition.Rarity,
		CardType = definition.CardType,
		Archetype = definition.Archetype,
		Nation = definition.Nation,
		Club = definition.Club,
		League = definition.League,
		RevealTier = definition.RevealTier,

		EligibleSlotKeys = slotKeys,
		EligibleSlotLabels = slotLabels,
		BestSlotKey = candidate.BestSlot.SlotKey,
		BestSlotLabel = candidate.BestSlot.Label,
		BestFitQuality = candidate.BestSlot.FitQuality,
	}
end

local function getOpenSlotKeys(
	slots: { DraftSlotState }
): { string }
	local openSlotKeys = {}

	for _, slot in ipairs(slots) do
		if not slot.Selected then
			table.insert(openSlotKeys, slot.SlotKey)
		end
	end

	return openSlotKeys
end

local function getFilledSlotCount(
	slots: { DraftSlotState }
): number
	local count = 0

	for _, slot in ipairs(slots) do
		if slot.Selected then
			count += 1
		end
	end

	return count
end

local function serializeDraft(draft: DraftSession)
	local slots = table.create(#draft.Slots)

	for index, slot in ipairs(draft.Slots) do
		local effectiveOverall = nil

		if slot.Selected then
			local fitQuality = slot.FitQuality
				or TeamRatingService.GetFitQuality(
					slot.Selected.Position,
					slot.Position
				)

			effectiveOverall =
				TeamRatingService.GetEffectiveOverall(
					slot.Selected.Overall,
					fitQuality
				)
		end

		table.insert(slots, {
			Index = index,
			SlotKey = slot.SlotKey,
			Label = slot.Label,
			Position = slot.Position,
			Selected = if slot.Selected
				then copyPublicFootballer(slot.Selected)
				else nil,
			FitQuality = slot.FitQuality,
			EffectiveOverall = effectiveOverall,
		})
	end

	local options = table.create(#draft.CurrentOptions)

	for _, option in ipairs(draft.CurrentOptions) do
		table.insert(options, copyPublicFootballer(option))
	end

	return {
		DraftId = draft.DraftId,
		FormationId = draft.FormationId,
		FormationName = draft.FormationName,
		CurrentPickIndex = draft.CurrentPickIndex,
		TotalPicks = #draft.Slots,
		IsComplete = draft.IsComplete,

		ExpiresIn = math.max(
			0,
			math.ceil(draft.ExpiresAt - os.clock())
		),

		OpenSlotKeys = getOpenSlotKeys(draft.Slots),
		Slots = slots,
		CurrentOptions = options,
		TeamSummary = TeamRatingService.Calculate(
			draft.Slots
		),
	}
end

local function buildExcludedIds(
	draft: DraftSession
): { [string]: boolean }
	local excluded: { [string]: boolean } = {}

	for _, slot in ipairs(draft.Slots) do
		if slot.Selected then
			excluded[slot.Selected.Id] = true
		end
	end

	return excluded
end

local function buildCandidatePool(
	draft: DraftSession
): { Candidate }
	local excludedIds = buildExcludedIds(draft)
	local candidates: { Candidate } = {}

	for _, definition in ipairs(Footballers) do
		if not excludedIds[definition.Id] then
			local eligibleSlots =
				TeamRatingService.GetEligibleOpenSlots(
					definition,
					draft.Slots
				)

			local bestSlot = eligibleSlots[1]

			if bestSlot then
				table.insert(candidates, {
					Definition = definition,
					EligibleSlots = eligibleSlots,
					BestSlot = bestSlot,
				})
			end
		end
	end

	return candidates
end

local function getCandidateWeight(
	candidate: Candidate,
	usedPositions: { [string]: boolean }
): number
	local baseWeight = candidate.Definition.Weight or 1

	local fitMultiplier =
		0.72 + candidate.BestSlot.FitQuality * 0.28

	local diversityMultiplier =
		if usedPositions[candidate.Definition.Position]
			then 0.58
			else GameConfig.PositionDiversityMultiplier

	return math.max(
		0.001,
		baseWeight
			* fitMultiplier
			* diversityMultiplier
	)
end

local function pickWeightedCandidate(
	candidates: { Candidate },
	usedPositions: { [string]: boolean }
): Candidate?
	if #candidates == 0 then
		return nil
	end

	local totalWeight = 0

	for _, candidate in ipairs(candidates) do
		totalWeight += getCandidateWeight(
			candidate,
			usedPositions
		)
	end

	local target = random:NextNumber(0, totalWeight)
	local accumulated = 0

	for _, candidate in ipairs(candidates) do
		accumulated += getCandidateWeight(
			candidate,
			usedPositions
		)

		if target <= accumulated then
			return candidate
		end
	end

	return candidates[#candidates]
end

local function removeCandidate(
	candidates: { Candidate },
	candidateToRemove: Candidate
)
	for index, candidate in ipairs(candidates) do
		if candidate == candidateToRemove then
			table.remove(candidates, index)
			return
		end
	end
end

local function findGuaranteedExactCandidate(
	candidates: { Candidate },
	openSlots: { DraftSlotState }
): Candidate?
	local shuffledSlots = table.clone(openSlots)

	for index = #shuffledSlots, 2, -1 do
		local swapIndex = random:NextInteger(1, index)

		shuffledSlots[index], shuffledSlots[swapIndex] =
			shuffledSlots[swapIndex], shuffledSlots[index]
	end

	for _, openSlot in ipairs(shuffledSlots) do
		local exactCandidates: { Candidate } = {}

		for _, candidate in ipairs(candidates) do
			for _, eligibleSlot in ipairs(candidate.EligibleSlots) do
				if eligibleSlot.SlotKey == openSlot.SlotKey
					and eligibleSlot.FitQuality >= 0.999
				then
					table.insert(exactCandidates, candidate)
					break
				end
			end
		end

		if #exactCandidates > 0 then
			return pickWeightedCandidate(
				exactCandidates,
				{}
			)
		end
	end

	return nil
end

local function buildMixedOptions(
	draft: DraftSession
): { PublicFootballer }
	local candidates = buildCandidatePool(draft)

	if #candidates == 0 then
		return {}
	end

	local openSlots: { DraftSlotState } = {}

	for _, slot in ipairs(draft.Slots) do
		if not slot.Selected then
			table.insert(openSlots, slot)
		end
	end

	local selectedCandidates: { Candidate } = {}
	local usedPositions: { [string]: boolean } = {}

	-- Guarantee at least one natural-position choice for an open slot.
	local guaranteed = findGuaranteedExactCandidate(
		candidates,
		openSlots
	)

	if guaranteed then
		table.insert(selectedCandidates, guaranteed)

		usedPositions[
			guaranteed.Definition.Position
		] = true

		removeCandidate(candidates, guaranteed)
	end

	while #selectedCandidates
		< GameConfig.DraftChoicesPerPick
		and #candidates > 0
	do
		local chosen = pickWeightedCandidate(
			candidates,
			usedPositions
		)

		if not chosen then
			break
		end

		table.insert(selectedCandidates, chosen)

		usedPositions[
			chosen.Definition.Position
		] = true

		removeCandidate(candidates, chosen)
	end

	-- Do not reveal which option was the guaranteed exact-fit card.
	for index = #selectedCandidates, 2, -1 do
		local swapIndex = random:NextInteger(1, index)

		selectedCandidates[index],
			selectedCandidates[swapIndex] =
			selectedCandidates[swapIndex],
			selectedCandidates[index]
	end

	local options =
		table.create(#selectedCandidates)

	for _, candidate in ipairs(selectedCandidates) do
		table.insert(
			options,
			toPublicFootballer(candidate)
		)
	end

	return options
end

local function createDraftSession(): DraftSession
	local formation = Formations[
		GameConfig.DefaultFormationId
	]

	assert(
		formation,
		"Default formation not found: "
			.. tostring(GameConfig.DefaultFormationId)
	)

	local slots = table.create(#formation.Slots)

	for _, formationSlot in ipairs(formation.Slots) do
		table.insert(slots, {
			SlotKey = formationSlot.Key,
			Label = formationSlot.Label,
			Position = formationSlot.Position,
			Selected = nil,
			FitQuality = nil,
		})
	end

	local draft: DraftSession = {
		DraftId = HttpService:GenerateGUID(false),
		FormationId = formation.Id,
		FormationName = formation.Name,

		ExpiresAt = os.clock()
			+ GameConfig.DraftLifetimeSeconds,

		CurrentPickIndex = 1,
		Slots = slots,
		CurrentOptions = {},
		IsComplete = false,
	}

	draft.CurrentOptions = buildMixedOptions(draft)

	return draft
end

local function findSlotByKey(
	slots: { DraftSlotState },
	slotKey: string
): DraftSlotState?
	for _, slot in ipairs(slots) do
		if slot.SlotKey == slotKey then
			return slot
		end
	end

	return nil
end

function DraftService.StartDraft(player: Player)
	local now = os.clock()
	local existingDraft = activeDrafts[player]

	if existingDraft then
		if now < existingDraft.ExpiresAt
			and not existingDraft.IsComplete
		then
			return success({
				Draft = serializeDraft(existingDraft),
				Profile =
					ProfileService.GetSnapshot(player),
			})
		end

		activeDrafts[player] = nil
	end

	local previousRequest =
		lastDraftRequestAt[player]

	if previousRequest
		and now - previousRequest
			< GameConfig.DraftRequestCooldownSeconds
	then
		return failure(
			"Please wait before opening another draft."
		)
	end

	lastDraftRequestAt[player] = now

	-- Validate that the catalog can produce a draft before charging.
	local draft = createDraftSession()

	if #draft.CurrentOptions == 0 then
		return failure(
			"The player catalog cannot fill this formation."
		)
	end

	if not ProfileService.SpendCoins(
		player,
		GameConfig.DraftCost
	) then
		return failure(string.format(
			"You need %d coins to start a draft.",
			GameConfig.DraftCost
		))
	end

	activeDrafts[player] = draft

	return success({
		Draft = serializeDraft(draft),
		Profile = ProfileService.GetSnapshot(player),
	})
end

function DraftService.SelectFootballer(
	player: Player,
	draftId: any,
	footballerId: any
)
	if typeof(draftId) ~= "string" then
		return failure("Invalid draft ID.")
	end

	if typeof(footballerId) ~= "string" then
		return failure("Invalid footballer ID.")
	end

	local draft = activeDrafts[player]

	if not draft then
		return failure(
			"You do not have an active draft."
		)
	end

	if os.clock() >= draft.ExpiresAt then
		activeDrafts[player] = nil
		return failure("Your draft expired.")
	end

	if draft.DraftId ~= draftId then
		return failure(
			"That draft is no longer active."
		)
	end

	if draft.IsComplete then
		return failure(
			"This draft is already complete."
		)
	end

	local chosenCard: PublicFootballer? = nil

	for _, option in ipairs(draft.CurrentOptions) do
		if option.Id == footballerId then
			chosenCard = option
			break
		end
	end

	if not chosenCard then
		return failure(
			"That footballer was not offered."
		)
	end

	-- Recompute placement on the server. Never trust client fit data.
	local bestOpenSlot =
		TeamRatingService.FindBestOpenSlot(
			chosenCard,
			draft.Slots
		)

	if not bestOpenSlot then
		return failure(
			"That footballer no longer fits an open slot."
		)
	end

	local targetSlot = findSlotByKey(
		draft.Slots,
		bestOpenSlot.SlotKey
	)

	if not targetSlot or targetSlot.Selected then
		return failure(
			"The selected squad slot is unavailable."
		)
	end

	targetSlot.Selected =
		copyPublicFootballer(chosenCard)

	targetSlot.FitQuality =
		bestOpenSlot.FitQuality

	ProfileService.AddFootballer(
		player,
		chosenCard.Id
	)

	local filledSlotCount =
		getFilledSlotCount(draft.Slots)

	draft.CurrentPickIndex =
		math.min(filledSlotCount + 1, #draft.Slots)

	if filledSlotCount >= #draft.Slots then
		draft.IsComplete = true
		draft.CurrentOptions = {}

		local serializedDraft =
			serializeDraft(draft)

		activeDrafts[player] = nil

		return success({
			Selected =
				copyPublicFootballer(chosenCard),

			PlacedSlotKey =
				bestOpenSlot.SlotKey,

			Draft = serializedDraft,
			TeamSummary =
				serializedDraft.TeamSummary,

			Profile =
				ProfileService.GetSnapshot(player),
		})
	end

	draft.CurrentOptions =
		buildMixedOptions(draft)

	if #draft.CurrentOptions == 0 then
		return failure(
			"No valid mixed-position choices remain."
		)
	end

	local serializedDraft = serializeDraft(draft)

	return success({
		Selected =
			copyPublicFootballer(chosenCard),

		PlacedSlotKey =
			bestOpenSlot.SlotKey,

		Draft = serializedDraft,
		TeamSummary =
			serializedDraft.TeamSummary,

		Profile =
			ProfileService.GetSnapshot(player),
	})
end

function DraftService.CleanupPlayer(player: Player)
	activeDrafts[player] = nil
	lastDraftRequestAt[player] = nil
end

return table.freeze(DraftService)
