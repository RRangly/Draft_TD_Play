local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Draft = require(script.Parent:WaitForChild("Draft"))
local RemoteEvent = ReplicatedStorage.ServerCommunication
local ClientEvents = ReplicatedStorage.ClientEvents

local DraftBegin = ClientEvents.DraftBegin
local TowerUpdate = ClientEvents.TowerUpdate

RemoteEvent.OnClientEvent:Connect(function(eventName, ...)
    local event = ClientEvents:FindFirstChild(eventName)
    if not event then
        print("Event non-existent!")
    else
        event:Fire(...)
    end
end)

DraftBegin.Event:Connect(function(cards)
    Draft.draftBegin(cards)
end)