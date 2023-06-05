local MapBlock = {}
MapBlock.__index = MapBlock

function MapBlock.new(x, y)
    
    local blockInfo = {
        X = x;
        Y = y;
        HasPlacement = false;
    }
    setmetatable(blockInfo, MapBlock)
end

function MapBlock.checkNeighbours()
    
end

return MapBlock