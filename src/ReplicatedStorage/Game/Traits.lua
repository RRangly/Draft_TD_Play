local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Data
if RunService:IsServer() then
    Data = require(ServerScriptService.Modules.Data)
end

local Traits = {
    {
        Name = "Freezer";
        Event = "MobDamage";
        Description = "Freeze mobs for 0.5 seconds each attack(dosent stack)";
        Invoke = function(pIndex, info)
            task.spawn(function()
                local mobIndex = info[1]
                local mobDead = info[2]
                if not mobDead then
                    Data[pIndex].MobManager:freeze(mobIndex, 0.5)
                end
            end)
        end
    },
    {
        Name = "Sharp Shooter";
        Event = "MobDamage";
        Description = "Deal 2x coins";
        Invoke = function(pIndex, info)
            local mobIndex = info[1]
            local mobDead = info[2]
            local damage = info[3]
            if not mobDead then
                Data[pIndex].MobManager:takeDamage(mobIndex, damage)
            end
        end
    },
    {
        Name = "Golden Shot";
        Event = "MobDamage";
        Description = "Recieve 1.5x coins";
        Invoke = function(pIndex, info)
            local mobDead = info[2]
            local damage = info[3]
            if not mobDead then
                Data[pIndex].CoinManager.Coins += math.round(damage / 2)
            end
        end
    },
}
return Traits