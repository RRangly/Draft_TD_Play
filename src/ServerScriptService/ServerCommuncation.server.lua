local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local ServerEvents = ServerStorage.ServerEvents

RemoteEvent.OnServerEvent:Connect(function(player, eventName, ...)
    local event = ServerEvents:FindFirstChild(eventName)
    if not event then
        print("Event non-existent!")
    else
        event:Fire(player, ...)
    end
end)