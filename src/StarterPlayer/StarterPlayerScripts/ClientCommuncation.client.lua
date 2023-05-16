local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local ClientEvents = ReplicatedStorage.ClientEvents

--local TowerUpdate = ClientEvents.TowerUpdate

RemoteEvent.OnClientEvent:Connect(function(eventName, ...)
    local event = ClientEvents:FindFirstChild(eventName)
    if not event then
        print("Event non-existent!")
    else
        event:Fire(...)
    end
end)