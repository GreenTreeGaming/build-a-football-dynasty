--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")

local GameConfig = require(Config:WaitForChild("GameConfig"))

type OwnedFootballer = {
	InstanceId: string,
	FootballerId: string,
	AcquiredAt: number,
}

type Profile = {
	SchemaVersion: number,
	Coins: number,
	Inventory: { OwnedFootballer },
}

type ProfileSnapshot = {
	SchemaVersion: number,
	Coins: number,
	Inventory: { OwnedFootballer },
}

local ProfileService = {}

local profiles: { [Player]: Profile } = {}
local started = false

local function createProfile(): Profile
	return {
		SchemaVersion = 1,
		Coins = GameConfig.StartingCoins,
		Inventory = {},
	}
end

local function getOrCreateProfile(player: Player): Profile
	local existingProfile = profiles[player]

	if existingProfile then
		return existingProfile
	end

	local newProfile = createProfile()
	profiles[player] = newProfile

	return newProfile
end

local function cloneInventory(
	inventory: { OwnedFootballer }
): { OwnedFootballer }
	local copy = table.create(#inventory)

	for _, ownedFootballer in ipairs(inventory) do
		table.insert(copy, {
			InstanceId = ownedFootballer.InstanceId,
			FootballerId = ownedFootballer.FootballerId,
			AcquiredAt = ownedFootballer.AcquiredAt,
		})
	end

	return copy
end

function ProfileService.Start()
	if started then
		return
	end

	started = true

	Players.PlayerAdded:Connect(function(player)
		getOrCreateProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		profiles[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		getOrCreateProfile(player)
	end
end

function ProfileService.GetSnapshot(player: Player): ProfileSnapshot
	local profile = getOrCreateProfile(player)

	return {
		SchemaVersion = profile.SchemaVersion,
		Coins = profile.Coins,
		Inventory = cloneInventory(profile.Inventory),
	}
end

function ProfileService.SpendCoins(
	player: Player,
	amount: number
): boolean
	assert(amount >= 0, "amount must not be negative")

	local profile = getOrCreateProfile(player)

	if profile.Coins < amount then
		return false
	end

	profile.Coins -= amount

	return true
end

function ProfileService.AddFootballer(
	player: Player,
	footballerId: string
): OwnedFootballer
	local profile = getOrCreateProfile(player)

	local ownedFootballer: OwnedFootballer = {
		InstanceId = HttpService:GenerateGUID(false),
		FootballerId = footballerId,
		AcquiredAt = os.time(),
	}

	table.insert(profile.Inventory, ownedFootballer)

	return {
		InstanceId = ownedFootballer.InstanceId,
		FootballerId = ownedFootballer.FootballerId,
		AcquiredAt = ownedFootballer.AcquiredAt,
	}
end

return table.freeze(ProfileService)