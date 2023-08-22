local BaseManager = {}
BaseManager.__index = BaseManager

function BaseManager.new(pIndex)
    local base = {
        PIndex = pIndex;
        Health = 100;
        MaxHealth = 100;
    }
    setmetatable(base, BaseManager)
    return base
end

return BaseManager