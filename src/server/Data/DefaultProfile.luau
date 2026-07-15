export type OwnedFootballer = {
	InstanceId: string,
	FootballerId: string,
	AcquiredAt: number,
}

export type Profile = {
	SchemaVersion: number,
	Coins: number,
	Wins: number,
	Losses: number,
	OwnedFootballers: { OwnedFootballer },
	StartingSquad: { [string]: string? },
}

local DefaultProfile: Profile = {
	SchemaVersion = 1,
	Coins = 1_000,
	Wins = 0,
	Losses = 0,
	OwnedFootballers = {},
	StartingSquad = {
		GK = nil,
		LB = nil,
		CB1 = nil,
		CB2 = nil,
		RB = nil,
		CM1 = nil,
		CM2 = nil,
		CAM = nil,
		LW = nil,
		RW = nil,
		ST = nil,
	},
}

return table.freeze(DefaultProfile)