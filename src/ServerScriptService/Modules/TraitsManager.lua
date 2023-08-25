local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local TraitSelect = ServerStorage.ServerEvents.TraitSelect
local Data = require(ServerScriptService.Modules.Data)
local Traits = require(ReplicatedStorage.Game.Traits)
local TraitsManager = {}
TraitsManager.__index = TraitsManager

function TraitsManager:newTraits()
    local player = Data[self.PIndex].Player
    local traitSel = {}
    for x = 1, 3, 1 do
        local i = math.random(1, #self.AvailTraits)
        traitSel[x] = self.AvailTraits[i]
        table.remove(self.AvailTraits, i)
    end
    RemoteEvent:FireClient(player, "TraitSelect", traitSel)
    local connection
    connection = TraitSelect.Event:Connect(function(pl, sel)
        if player ~= pl then
            return
        end
        for x = 1, 3, 1 do
            if x == sel then
                table.insert(self.Traits[Traits[traitSel[x]].Event], Traits[traitSel[x]])
                continue
            end
            table.insert(self.AvailTraits, traitSel[x])
        end
        connection:Disconnect()
    end)
end

function TraitsManager:invoke(invokeType: string, ...)
    for i, traits in self.Traits do
        if i == invokeType then
            for _, trait in ipairs(traits) do 
                trait.Invoke(self.PIndex, ...)
            end
        end
    end
end

function TraitsManager.new(pIndex)
    local traitsManager = {
        PIndex = pIndex;
        AvailTraits = {};
        Traits = {
            MobDamage = {};
        }
    }
    for i = 1, #Traits, 1 do
        traitsManager.AvailTraits[i] = i
    end
    setmetatable(traitsManager, TraitsManager)
    return traitsManager
end

return TraitsManager