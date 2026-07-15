export type Position =
	"GK"
	| "LB"
	| "CB"
	| "RB"
	| "CDM"
	| "CM"
	| "CAM"
	| "LW"
	| "RW"
	| "ST"

export type Rarity =
	"Common"
	| "Rare"
	| "Elite"
	| "WorldClass"
	| "Icon"

export type Footballer = {
	Id: string,
	DisplayName: string,
	Position: Position,
	Overall: number,
	Rarity: Rarity,
	Nation: string,
	League: string,
	Club: string,
	Pace: number,
	Shooting: number,
	Passing: number,
	Dribbling: number,
	Defending: number,
	Physical: number,
	DraftWeight: number,
}

local Footballers: { [string]: Footballer } = {
	keeper_001 = {
		Id = "keeper_001",
		DisplayName = "Marco Silva",
		Position = "GK",
		Overall = 72,
		Rarity = "Common",
		Nation = "Portugal",
		League = "English League",
		Club = "London Athletic",
		Pace = 41,
		Shooting = 18,
		Passing = 68,
		Dribbling = 45,
		Defending = 73,
		Physical = 70,
		DraftWeight = 100,
	},

	striker_001 = {
		Id = "striker_001",
		DisplayName = "Leo Costa",
		Position = "ST",
		Overall = 84,
		Rarity = "Elite",
		Nation = "Brazil",
		League = "Spanish League",
		Club = "Madrid Royals",
		Pace = 87,
		Shooting = 86,
		Passing = 76,
		Dribbling = 85,
		Defending = 31,
		Physical = 78,
		DraftWeight = 15,
	},

	winger_001 = {
		Id = "winger_001",
		DisplayName = "Jamal Adeyemi",
		Position = "RW",
		Overall = 91,
		Rarity = "WorldClass",
		Nation = "Germany",
		League = "German League",
		Club = "Munich Stars",
		Pace = 96,
		Shooting = 88,
		Passing = 87,
		Dribbling = 94,
		Defending = 42,
		Physical = 72,
		DraftWeight = 3,
	},
}

return table.freeze(Footballers)