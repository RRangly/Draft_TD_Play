local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Traits = require(ReplicatedStorage.Game.Traits)

local TraitsManager = {}
TraitsManager.__index = TraitsManager

function TraitsManager:newTraits()
    for i = 1, 3, 1 do
        table.insert(self.traits(Traits[math.random(1, #Traits)].Name))
    end
end

function TraitsManager.new()
    local traitsManager = {
        traits = {}
    }
    setmetatable(traitsManager, TraitsManager)
end

return TraitsManager