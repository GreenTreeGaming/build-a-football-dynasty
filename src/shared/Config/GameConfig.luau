--!strict

local GameConfig = {
	StartingCoins = 500,
	DraftCost = 100,

	-- How many choices the player sees for each squad slot.
	DraftChoicesPerPick = 3,

	-- Entire draft session lifetime.
	DraftLifetimeSeconds = 10 * 60,

	-- Prevent spam.
	DraftRequestCooldownSeconds = 0.75,

	-- Initial formation used by the draft.
	DefaultFormationId = "F433",
}

return table.freeze(GameConfig)