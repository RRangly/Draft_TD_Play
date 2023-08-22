local ServerScriptService = game:GetService("ServerScriptService")
local Data = require(ServerScriptService.Modules.Data)

local Traits = {
    {
        Name = "Freezer";
        Event = "MobDamage";
        Invoke = function(pIndex, mobIndex, mobDead)
            if not mobDead then
                Data[pIndex].MobManager:Freeze(mobIndex, 0.5)
            end
        end
    },
    {
        Name = "Sharp Shooter";
        Event = "MobDamage";
    },
    Golden_Shot = {
        Name = "Golden Shot";
        Event = "MobDamage";
    },
    Supporter = {
        Name = "Supporter";
        Event = "MobDamage";
    }
}

return Traits