local BaseManager = {}
BaseManager.__index = BaseManager

function BaseManager.new()
    local base = {
        Health = 50;
        MaxHealth = 50;
    }
    setmetatable(base, BaseManager)
    return base
end

return BaseManager