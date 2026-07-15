--!strict

export type FormationSlot = {
	Key: string,
	Label: string,
	Position: string,
	X: number,
	Y: number,
}

export type Formation = {
	Id: string,
	Name: string,
	Slots: { FormationSlot },
}

local formations: { [string]: Formation } = {
	F433 = {
		Id = "F433",
		Name = "4-3-3",
		Slots = {
			{ Key = "GK", Label = "GK", Position = "GK", X = 0.50, Y = 0.88 },

			{ Key = "LB", Label = "LB", Position = "LB", X = 0.18, Y = 0.71 },
			{ Key = "LCB", Label = "LCB", Position = "CB", X = 0.38, Y = 0.74 },
			{ Key = "RCB", Label = "RCB", Position = "CB", X = 0.62, Y = 0.74 },
			{ Key = "RB", Label = "RB", Position = "RB", X = 0.82, Y = 0.71 },

			{ Key = "LCM", Label = "LCM", Position = "CM", X = 0.30, Y = 0.50 },
			{ Key = "CM", Label = "CM", Position = "CM", X = 0.50, Y = 0.56 },
			{ Key = "RCM", Label = "RCM", Position = "CM", X = 0.70, Y = 0.50 },

			{ Key = "LW", Label = "LW", Position = "LW", X = 0.18, Y = 0.23 },
			{ Key = "ST", Label = "ST", Position = "ST", X = 0.50, Y = 0.16 },
			{ Key = "RW", Label = "RW", Position = "RW", X = 0.82, Y = 0.23 },
		},
	},
}

return table.freeze(formations)