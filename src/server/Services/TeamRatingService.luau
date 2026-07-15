--!strict

local TeamRatingService = {}

export type EligibleSlot = {
	SlotKey: string,
	Label: string,
	Position: string,
	FitQuality: number,
}

export type TeamSummary = {
	Attack: number,
	Midfield: number,
	Defense: number,
	Overall: number,
	Chemistry: number,
	PositionChemistry: number,
	LinkChemistry: number,
	IdentityBonus: number,
	FilledSlots: number,
	TotalSlots: number,
	IsComplete: boolean,
	Bonuses: { string },
}

local POSITION_FIT: { [string]: { [string]: number } } = {
	GK = {
		GK = 1,
	},

	LB = {
		LB = 1,
		CB = 0.78,
	},

	CB = {
		CB = 1,
		LB = 0.76,
		RB = 0.76,
	},

	RB = {
		RB = 1,
		CB = 0.78,
	},

	CDM = {
		CM = 0.94,
		CB = 0.84,
	},

	CM = {
		CM = 1,
	},

	CAM = {
		CM = 0.94,
		ST = 0.82,
		LW = 0.8,
		RW = 0.8,
	},

	LW = {
		LW = 1,
		RW = 0.84,
		ST = 0.82,
	},

	RW = {
		RW = 1,
		LW = 0.84,
		ST = 0.82,
	},

	ST = {
		ST = 1,
		LW = 0.8,
		RW = 0.8,
	},
}

local ATTACK_SLOT_KEYS: { [string]: boolean } = {
	LW = true,
	ST = true,
	RW = true,
}

local MIDFIELD_SLOT_KEYS: { [string]: boolean } = {
	LCM = true,
	CM = true,
	RCM = true,
}

local DEFENSE_SLOT_KEYS: { [string]: boolean } = {
	GK = true,
	LB = true,
	LCB = true,
	RCB = true,
	RB = true,
}

local function round(value: number): number
	return math.floor(value + 0.5)
end

local function clamp(value: number, minimum: number, maximum: number): number
	return math.max(minimum, math.min(maximum, value))
end

local function average(values: { number }): number
	if #values == 0 then
		return 0
	end

	local total = 0

	for _, value in ipairs(values) do
		total += value
	end

	return round(total / #values)
end

local function getLargestCount(counts: { [string]: number }): number
	local largest = 0

	for _, count in pairs(counts) do
		largest = math.max(largest, count)
	end

	return largest
end

function TeamRatingService.GetFitQuality(
	playerPosition: string,
	slotPosition: string
): number
	local positionFits = POSITION_FIT[playerPosition]

	if not positionFits then
		return 0
	end

	return positionFits[slotPosition] or 0
end

function TeamRatingService.GetEligibleOpenSlots(
	footballer: any,
	slots: { any }
): { EligibleSlot }
	local eligible: { EligibleSlot } = {}

	for _, slot in ipairs(slots) do
		if not slot.Selected then
			local fitQuality = TeamRatingService.GetFitQuality(
				footballer.Position,
				slot.Position
			)

			if fitQuality > 0 then
				table.insert(eligible, {
					SlotKey = slot.SlotKey,
					Label = slot.Label,
					Position = slot.Position,
					FitQuality = fitQuality,
				})
			end
		end
	end

	table.sort(eligible, function(left, right)
		if left.FitQuality == right.FitQuality then
			return left.SlotKey < right.SlotKey
		end

		return left.FitQuality > right.FitQuality
	end)

	return eligible
end

function TeamRatingService.FindBestOpenSlot(
	footballer: any,
	slots: { any }
): EligibleSlot?
	local eligible = TeamRatingService.GetEligibleOpenSlots(
		footballer,
		slots
	)

	return eligible[1]
end

function TeamRatingService.GetEffectiveOverall(
	overall: number,
	fitQuality: number
): number
	-- Position mistakes matter, but a great player is still useful.
	local penalty = round((1 - fitQuality) * 20)

	return clamp(overall - penalty, 1, 99)
end

function TeamRatingService.Calculate(
	slots: { any }
): TeamSummary
	local attackRatings: { number } = {}
	local midfieldRatings: { number } = {}
	local defenseRatings: { number } = {}
	local allRatings: { number } = {}
	local fitQualities: { number } = {}

	local clubCounts: { [string]: number } = {}
	local leagueCounts: { [string]: number } = {}
	local nationCounts: { [string]: number } = {}
	local archetypeCounts: { [string]: number } = {}

	local filledSlots = 0

	for _, slot in ipairs(slots) do
		local footballer = slot.Selected

		if footballer then
			filledSlots += 1
			local fitQuality = TeamRatingService.GetFitQuality(
				footballer.Position,
				slot.Position
			)

			local effectiveOverall =
				TeamRatingService.GetEffectiveOverall(
					footballer.Overall,
					fitQuality
				)

			table.insert(allRatings, effectiveOverall)
			table.insert(fitQualities, fitQuality)

			if ATTACK_SLOT_KEYS[slot.SlotKey] then
				table.insert(attackRatings, effectiveOverall)
			elseif MIDFIELD_SLOT_KEYS[slot.SlotKey] then
				table.insert(midfieldRatings, effectiveOverall)
			elseif DEFENSE_SLOT_KEYS[slot.SlotKey] then
				table.insert(defenseRatings, effectiveOverall)
			end

			clubCounts[footballer.Club] =
				(clubCounts[footballer.Club] or 0) + 1

			leagueCounts[footballer.League] =
				(leagueCounts[footballer.League] or 0) + 1

			nationCounts[footballer.Nation] =
				(nationCounts[footballer.Nation] or 0) + 1

			archetypeCounts[footballer.Archetype] =
				(archetypeCounts[footballer.Archetype] or 0) + 1
		end
	end

	local attack = average(attackRatings)
	local midfield = average(midfieldRatings)
	local defense = average(defenseRatings)

	local overall = 0

	if filledSlots > 0 then
		if attack > 0 and midfield > 0 and defense > 0 then
			overall = round(
				attack * 0.4
					+ midfield * 0.32
					+ defense * 0.28
			)
		else
			overall = average(allRatings)
		end
	end

	local positionChemistry = 0

	if #fitQualities > 0 then
		local fitTotal = 0

		for _, fitQuality in ipairs(fitQualities) do
			fitTotal += fitQuality
		end

		-- Correct positioning supplies up to 40 chemistry.
		positionChemistry = round(
			fitTotal / #fitQualities * 40
		)
	end

	local identityTotal = 0

	for _, slot in ipairs(slots) do
		local footballer = slot.Selected

		if footballer then
			local clubTeammates = math.max(
				0,
				(clubCounts[footballer.Club] or 1) - 1
			)

			local leagueTeammates = math.max(
				0,
				(leagueCounts[footballer.League] or 1) - 1
			)

			local nationTeammates = math.max(
				0,
				(nationCounts[footballer.Nation] or 1) - 1
			)

			local archetypeTeammates = math.max(
				0,
				(archetypeCounts[footballer.Archetype] or 1) - 1
			)

			-- Squad identity supplies up to 55 chemistry:
			-- club 25, league 15, nation 10, archetype 5.
			identityTotal +=
				math.min(clubTeammates, 2) / 2 * 25
				+ math.min(leagueTeammates, 4) / 4 * 15
				+ math.min(nationTeammates, 3) / 3 * 10
				+ math.min(archetypeTeammates, 2) / 2 * 5
		end
	end

	local linkChemistry = 0

	if filledSlots > 0 then
		linkChemistry = round(
			identityTotal / filledSlots
		)
	end

	local identityBonus = 0
	local bonuses: { string } = {}

	if getLargestCount(clubCounts) >= 3 then
		identityBonus += 2
		table.insert(bonuses, "Club Core")
	end

	if getLargestCount(leagueCounts) >= 4 then
		identityBonus += 2
		table.insert(bonuses, "League Identity")
	end

	if getLargestCount(nationCounts) >= 3 then
		identityBonus += 1
		table.insert(bonuses, "National Link")
	end

	local chemistry = clamp(
		linkChemistry
			+ positionChemistry
			+ identityBonus,
		0,
		100
	)

	return {
		Attack = attack,
		Midfield = midfield,
		Defense = defense,
		Overall = overall,
		Chemistry = chemistry,
		PositionChemistry = positionChemistry,
		LinkChemistry = linkChemistry,
		IdentityBonus = identityBonus,
		FilledSlots = filledSlots,
		TotalSlots = #slots,
		IsComplete = filledSlots == #slots,
		Bonuses = bonuses,
	}
end

return table.freeze(TeamRatingService)
