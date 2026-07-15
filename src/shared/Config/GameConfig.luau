--!strict

local GameConfig = {
	StartingCoins = 1_000,
	DraftCost = 100,

	-- Five mixed-position choices are rolled every round.
	DraftChoicesPerPick = 5,

	-- New positions are strongly preferred while still allowing duplicates.
	PositionDiversityMultiplier = 2.15,

	DraftLifetimeSeconds = 10 * 60,
	DraftRequestCooldownSeconds = 0.75,
	DefaultFormationId = "F433",
}

return table.freeze(GameConfig)
