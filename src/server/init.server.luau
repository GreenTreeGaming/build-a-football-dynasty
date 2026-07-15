--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script:WaitForChild("Services")

local ProfileService = require(
    Services:WaitForChild("ProfileService")
)

local DraftService = require(
    Services:WaitForChild("DraftService")
)

local function getOrCreateFolder(
    parent: Instance,
    name: string
): Folder
    local existing = parent:FindFirstChild(name)

    if existing then
        assert(
            existing:IsA("Folder"),
            string.format("%s must be a Folder", name)
        )

        return existing
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent

    return folder
end

local function getOrCreateRemoteFunction(
    parent: Instance,
    name: string
): RemoteFunction
    local existing = parent:FindFirstChild(name)

    if existing then
        assert(
            existing:IsA("RemoteFunction"),
            string.format("%s must be a RemoteFunction", name)
        )

        return existing
    end

    local remoteFunction = Instance.new("RemoteFunction")
    remoteFunction.Name = name
    remoteFunction.Parent = parent

    return remoteFunction
end

local function guardedInvoke(callback: (...any) -> any)
    return function(player: Player, ...: any): any
        local arguments = table.pack(...)

        local succeeded, result = pcall(function()
            return callback(
                player,
                table.unpack(arguments, 1, arguments.n)
            )
        end)

        if not succeeded then
            warn(
                string.format(
                    "Remote request failed for user %d: %s",
                    player.UserId,
                    tostring(result)
                )
            )

            return {
                Ok = false,
                Error = "An unexpected server error occurred.",
            }
        end

        return result
    end
end

ProfileService.Start()

local remotes = getOrCreateFolder(
    ReplicatedStorage,
    "Remotes"
)

local getProfileRemote = getOrCreateRemoteFunction(
    remotes,
    "GetProfile"
)

local startDraftRemote = getOrCreateRemoteFunction(
    remotes,
    "StartDraft"
)

local selectFootballerRemote = getOrCreateRemoteFunction(
    remotes,
    "SelectFootballer"
)

getProfileRemote.OnServerInvoke = guardedInvoke(function(player: Player)
    return {
        Ok = true,
        Data = {
            Profile = ProfileService.GetSnapshot(player),
        },
    }
end)

startDraftRemote.OnServerInvoke = guardedInvoke(
    function(player: Player)
        return DraftService.StartDraft(player)
    end
)

selectFootballerRemote.OnServerInvoke = guardedInvoke(
    function(
        player: Player,
        draftId: any,
        footballerId: any
    )
        return DraftService.SelectFootballer(
            player,
            draftId,
            footballerId
        )
    end
)

Players.PlayerRemoving:Connect(function(player)
    DraftService.CleanupPlayer(player)
end)

print("[Soccer Dynasty] Server initialized")