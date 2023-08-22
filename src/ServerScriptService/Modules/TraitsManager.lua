local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Traits = require(ReplicatedStorage.Game.Traits)

local TraitsManager = {}
TraitsManager.__index = TraitsManager

function TraitsManager:newTraits()
    --[[
    local newTraits = {}
    for i = 1, 3, 1 do
        newTraits[i] = self.Traits[math.random(1, #Traits)].Name
    end
    ]]
    local i = math.random(1, #self.AvailTraits)
    print("AddingTrait", i, self.AvailTraits[i])
    table.insert(self.Traits[self.AvailTraits[i].Event], i)
    table.remove(self.AvailTraits, i)
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
            SupportEvent = {};
        }
    }
    for i = 1, #Traits, 1 do
        traitsManager.AvailTraits[i] = Traits[i]
    end
    setmetatable(traitsManager, TraitsManager)
    return traitsManager
end

return TraitsManager