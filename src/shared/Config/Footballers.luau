--!strict

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
	| "Epic"
	| "Legendary"
	| "Icon"

export type FootballerDefinition = {
	Id: string,
	DisplayName: string,
	Position: Position,
	Overall: number,
	Rarity: Rarity,

	-- Higher weight means the footballer appears more frequently.
	Weight: number,
}

local footballers: { FootballerDefinition } = {
	{
		Id = "tomas_varga",
		DisplayName = "Tomas Varga",
		Position = "GK",
		Overall = 69,
		Rarity = "Common",
		Weight = 100,
	},
	{
		Id = "marco_santos",
		DisplayName = "Marco Santos",
		Position = "CB",
		Overall = 71,
		Rarity = "Common",
		Weight = 100,
	},
	{
		Id = "ibrahim_diallo",
		DisplayName = "Ibrahim Diallo",
		Position = "LB",
		Overall = 72,
		Rarity = "Common",
		Weight = 100,
	},
	{
		Id = "luca_bianchi",
		DisplayName = "Luca Bianchi",
		Position = "CM",
		Overall = 73,
		Rarity = "Common",
		Weight = 100,
	},
	{
		Id = "kenji_sato",
		DisplayName = "Kenji Sato",
		Position = "RW",
		Overall = 74,
		Rarity = "Common",
		Weight = 100,
	},
	{
		Id = "noah_fischer",
		DisplayName = "Noah Fischer",
		Position = "ST",
		Overall = 75,
		Rarity = "Common",
		Weight = 100,
	},

	{
		Id = "malik_okafor",
		DisplayName = "Malik Okafor",
		Position = "CB",
		Overall = 78,
		Rarity = "Rare",
		Weight = 40,
	},
	{
		Id = "enzo_morel",
		DisplayName = "Enzo Morel",
		Position = "GK",
		Overall = 79,
		Rarity = "Rare",
		Weight = 40,
	},
	{
		Id = "dario_mensah",
		DisplayName = "Dario Mensah",
		Position = "LW",
		Overall = 80,
		Rarity = "Rare",
		Weight = 40,
	},
	{
		Id = "mateo_silva",
		DisplayName = "Mateo Silva",
		Position = "CAM",
		Overall = 81,
		Rarity = "Rare",
		Weight = 40,
	},
	{
		Id = "yusuf_demir",
		DisplayName = "Yusuf Demir",
		Position = "CDM",
		Overall = 82,
		Rarity = "Rare",
		Weight = 40,
	},

	{
		Id = "rafael_costa",
		DisplayName = "Rafael Costa",
		Position = "CB",
		Overall = 85,
		Rarity = "Epic",
		Weight = 12,
	},
	{
		Id = "ari_navarro",
		DisplayName = "Ari Navarro",
		Position = "CAM",
		Overall = 86,
		Rarity = "Epic",
		Weight = 12,
	},
	{
		Id = "thiago_vale",
		DisplayName = "Thiago Vale",
		Position = "ST",
		Overall = 87,
		Rarity = "Epic",
		Weight = 12,
	},
	{
		Id = "andre_kamara",
		DisplayName = "Andre Kamara",
		Position = "RW",
		Overall = 88,
		Rarity = "Epic",
		Weight = 12,
	},

	{
		Id = "gabriel_montoya",
		DisplayName = "Gabriel Montoya",
		Position = "CM",
		Overall = 91,
		Rarity = "Legendary",
		Weight = 3,
	},
	{
		Id = "elias_moreau",
		DisplayName = "Elias Moreau",
		Position = "ST",
		Overall = 92,
		Rarity = "Legendary",
		Weight = 3,
	},

	{
		Id = "leo_ventura",
		DisplayName = "Leo Ventura",
		Position = "RW",
		Overall = 96,
		Rarity = "Icon",
		Weight = 1,
	},
}

for _, footballer in ipairs(footballers) do
	table.freeze(footballer)
end

return table.freeze(footballers)