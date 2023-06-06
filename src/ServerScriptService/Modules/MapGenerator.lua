local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local MapAssets = ReplicatedStorage.MapAssets
local MapBlock = ServerScriptService.Modules.MapBlock

local MapGenerator = {}
MapGenerator.__index = MapGenerator

function MapGenerator.oppositeDirection(direction)
    local returnVal = direction + 2
    if returnVal > 4 then
        returnVal -= 4
    end
    return returnVal
end

function MapGenerator.generateMap(player)
    local map = {
        Chunks = {};
        PathGenDirection = 2;
        LastChunk = {X = 0; Y = 0;}
    }
    setmetatable(map, MapGenerator)
    map.Chunks[0] = {}
    map.Chunks[0][0] = {
        Tiles = {}
    }
    local chunk = map.Chunks[0][0]
    for x = 0, 8, 1 do
        chunk.Tiles[x] = {}
        for y = 0, 8, 1 do
            local block = MapAssets.MapPart:Clone()
            block.Parent = Workspace
            block.Size = Vector3.new(4.9, 1, 4.9)
            block.Position = Vector3.new(x * 5, 5, y * 5)
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            local path = false
            if y == 4 then
                coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                path = true
            end
            chunk.Tiles[x][y] = {
                Object = block;
                Placed = false;
                Path = path;
            }
        end
    end
    --[[
    for x = 3, 8 do
        map.Blocks[x] = {}
        local y = 2
        local block = MapAssets.MapPart:Clone()
        block.Parent = Workspace
        block.Size = Vector3.new(4.9, 1, 4.9)
        block.Position = Vector3.new(x * 5, 5, y * 5)
        local coordText = block.CoordGui.CoordText
        coordText.Text = "( " .. x .. " , " .. y .. " )"
        coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        map.LastPath = {X = x; Y = y; Direction = map.PathGenDirection;}
        table.insert(map.PathToBe, map.LastPath)
        map.Blocks[x][y] = {
            Object = block;
            Placed = false;
            Path = true;
        }
    end
    ]]
    player.Character:MoveTo(Vector3.new(2.5, 5, 12.5))
    return map
end

function MapGenerator:getBetween(chunk, coord1, coord2)
    local x
    local y

    if coord1.X == coord2.X then
        x = coord1.X
        if coord1.Y > coord2.Y then
            y = coord1.Y - 1
        elseif coord1.Y < coord2.Y then
            y = coord1.Y + 1
        end
    elseif coord1.Y == coord2.Y then
        y = coord1.Y
        if coord1.X > coord2.X then
            x = coord1.X - 1
        elseif coord1.X < coord2.X then
            x = coord1.X + 1
        end
    end

    return {chunk.Tiles[x][y], x, y}
end

function MapGenerator:getNeighbours(chunk, x, y)
    local x1 = chunk.Tiles[x]
    local x2 = chunk.Tiles[x + 1]
    local x3 = chunk.Tiles[x - 1]
    local returnVal = {}
    if x1 then
        returnVal[1] = x1[y + 1]
        returnVal[3] = x1[y - 1]
    end
    if x2 then
        returnVal[2] = x2[y]
    end
    if x3 then
        returnVal[4] = x3[y]
    end
    return {
        {returnVal[1], x, y + 1},
        {returnVal[2], x + 1, y},
        {returnVal[3], x, y - 1},
        {returnVal[4], x - 1, y},
    }
end

function MapGenerator:getSecondNeighbours(chunk, x, y)
    local x1 = chunk.Tiles[x]
    local x2 = chunk.Tiles[x + 2]
    local x3 = chunk.Tiles[x - 2]
    local returnVal = {}
    if x1 then
        returnVal[1] = x1[y + 2]
        returnVal[3] = x1[y - 2]
    end
    if x2 then
        returnVal[2] = x2[y]
    end
    if x3 then
        returnVal[4] = x3[y]
    end
    print("ReturnVals", {
        {returnVal[1], x, y + 2},
        {returnVal[2], x + 2, y},
        {returnVal[3], x, y - 2},
        {returnVal[4], x - 2, y},
    })
    return {
        {returnVal[1], x, y + 2},
        {returnVal[2], x + 2, y},
        {returnVal[3], x, y - 2},
        {returnVal[4], x - 2, y},
    }
end

function MapGenerator:generatePath(chunk, startCoord, endCoord)
    print("Coord", "(", startCoord.X, ",", startCoord.Y, ")")
    chunk.Tiles[startCoord.X][startCoord.Y].Visited = true
    if startCoord.X == endCoord.X and startCoord.Y == endCoord.Y then
        chunk.Tiles[startCoord.X][startCoord.Y].Path = true
        return true
    end
    local neighbours = self:getSecondNeighbours(chunk, startCoord.X, startCoord.Y)

    for i, info in pairs(neighbours) do
        if info[1] == nil or info.Visited then
            table.remove(neighbours, i)
        end
    end

    print("NeighBourList", neighbours)
    while #neighbours > 0 do
        --neighbours = self:getSecondNeighbours(chunk, startCoord.X, startCoord.Y)
        local direction = math.random(1, #neighbours)
        local neighbour = neighbours[direction]
        local result = self:generatePath(chunk, {X = neighbour[2]; Y = neighbour[3];}, endCoord)
        if result then
            chunk.Tiles[startCoord.X][startCoord.Y].Path = true
            local pathWay = self:getBetween(chunk, startCoord, {X = neighbour[2]; Y = neighbour[3];})
            chunk.Tiles[pathWay[2]][pathWay[3]].Path = true
            return true
        else
            table.remove(neighbours, direction)
        end
        print("NeighbourAmount", #neighbours)
    end
    chunk.Tiles[startCoord.X][startCoord.Y].Visited = true
    return false
end

function MapGenerator:generateChunk()
    local chunk = {
        Tiles = {}
    }
    local chunkPos = {}
    local startCoord
    if self.PathGenDirection == 1 then
        startCoord = {X = 4; Y = 0;}
        chunkPos = {X = self.LastChunk.X; Y = self.LastChunk.Y + 1}
    elseif self.PathGenDirection == 2 then
        startCoord = {X = 0; Y = 4;}
        chunkPos = {X = self.LastChunk.X + 1; Y = self.LastChunk.Y;}
    elseif self.PathGenDirection == 3 then
        startCoord = {X = 4; Y = 8;}
        chunkPos = {X = self.LastChunk.X; Y = self.LastChunk.Y - 1}
    elseif self.PathGenDirection == 4 then
        startCoord = {X = 8; Y = 4;}
        chunkPos = {X = self.LastChunk.X - 1; Y = self.LastChunk.Y;}
    end

    for x = 0, 8, 1 do
        chunk.Tiles[x] = {}
        for y = 0, 8, 1 do
            chunk.Tiles[x][y] = {
                Path = false;
                Visited = false;
            }
        end
    end
    
    local dir
    repeat
        dir = math.random(1, 4)
    until dir ~= MapGenerator.oppositeDirection(self.PathGenDirection)
    self.PathGenDirection = dir
    local endCoord
    if self.PathGenDirection == 1 then
        endCoord = {X = 4; Y = 8;}
    elseif self.PathGenDirection == 2 then
        endCoord = {X = 8; Y = 4;}
    elseif self.PathGenDirection == 3 then
        endCoord = {X = 4; Y = 0;}
    elseif self.PathGenDirection == 4 then
        endCoord = {X = 0; Y = 4;}
    end
    --chunk[startCoord.X][startCoord.Y].Visited = true
    --table.insert(path, {X = startCoord.X; Y = startCoord.Y;})
    self:generatePath(chunk, startCoord, endCoord)
    if not self.Chunks[chunkPos.X] then
        self.Chunks[chunkPos.X] = {}
    end
    self.Chunks[chunkPos.X][chunkPos.Y] = {
        Tiles = {}
    }
    for x = 0, 8, 1 do
        self.Chunks[chunkPos.X][chunkPos.Y].Tiles[x] = {}
        for y = 0, 8, 1 do
            local tile = chunk.Tiles[x][y]
            local block = MapAssets.MapPart:Clone()
            block.Parent = Workspace
            block.Size = Vector3.new(4.9, 1, 4.9)
            block.Position = Vector3.new(chunkPos.X * 50 + x * 5, 5, chunkPos.Y * 50 + y * 5)
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            if tile.Path then
                coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
            self.Chunks[chunkPos.X][chunkPos.Y].Tiles[x][y] = {
                Object = block;
                Placed = false;
                Path = tile.Path;
            }
        end
    end
    self.LastChunk = chunkPos
end

--[[
function MapGenerator:genMore(amount)
    local rn = math.random(1, 100)
    local tobe = self.PathGenDirection
    local changing = true
    if rn >= 85 then
        if self.PathGenDirection == 4 then
            tobe = 1
        else
            tobe = self.PathGenDirection + 1
        end
    elseif rn >= 70 then
        if self.PathGenDirection == 1 then
            tobe = 4
        else
            tobe = self.PathGenDirection - 1
        end
    end
    local tobeNe1 = self:getNeighbours(self.LastPath.X, self.LastPath.Y)[tobe]
    local tobeNe = self:getNeighbours(tobeNe1[2], tobeNe1[3])[tobe]
    if tobeNe1[1] and tobeNe1[1].Path then
        changing = false
    end
    local oppDirection = MapGenerator.oppositeDirection(tobe)
    for dir, tile in pairs(tobeNe) do
        if dir == oppDirection then
            continue
        end
        if tile[1] and tile[1].Path then
            changing = false
        end
    end
    if changing then
        self.PathGenDirection = tobe
    else
        print("DirectionChangeCancelled", tobe, tobeNe1, tobeNe)
    end
    for _ = 1, amount, 1 do
        local prevDirection = self.PathToBe[1].Direction
        if prevDirection == 2 or prevDirection == 4 then
            local x = self.PathToBe[1].X
            for y = self.PathToBe[1].Y - 2, self.PathToBe[1].Y + 2, 1 do
                if y == self.PathToBe[1].Y or self.Blocks[x][y] then
                    continue
                end
                local block = MapAssets.MapPart:Clone()
                block.Parent = Workspace
                block.Size = Vector3.new(4.9, 1, 4.9)
                block.Position = Vector3.new(x * 5, 5, y * 5)
                local coordText = block.CoordGui.CoordText
                coordText.Text = "( " .. x .. " , " .. y .. " )"
                self.Blocks[x][y] = {
                    Object = block;
                    Placed = false;
                    Path = false;
                }
            end
        elseif prevDirection == 1 or prevDirection == 3 then
            local y = self.PathToBe[1].Y
            for x = self.PathToBe[1].X - 2, self.PathToBe[1].X + 2, 1 do
                if not self.Blocks[x] then
                    self.Blocks[x] = {}
                end
                if x == self.PathToBe[1].X or self.Blocks[x][y] then
                    continue
                end
                local block = MapAssets.MapPart:Clone()
                block.Parent = Workspace
                block.Size = Vector3.new(4.9, 1, 4.9)
                block.Position = Vector3.new(x * 5, 5, y * 5)
                local coordText = block.CoordGui.CoordText
                coordText.Text = "( " .. x .. " , " .. y .. " )"
                self.Blocks[x][y] = {
                    Object = block;
                    Placed = false;
                    Path = false;
                }
            end
        end
        table.remove(self.PathToBe, 1)

        if self.PathGenDirection == 2 or self.PathGenDirection == 4 then
            local x = self.LastPath.X
            if self.PathGenDirection == 2 then
                x += 1
            else
                x -= 1
            end
            if not self.Blocks[x] then
                self.Blocks[x] = {}
            end
            local y = self.LastPath.Y
            local block = MapAssets.MapPart:Clone()
            block.Parent = Workspace
            block.Size = Vector3.new(4.9, 1, 4.9)
            block.Position = Vector3.new(x * 5, 5, y * 5)
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            self.LastPath = {X = x; Y = y; Direction = self.PathGenDirection;}
            self.Blocks[x][y] = {
                Object = block;
                Placed = false;
                Path = true;
            }
        elseif self.PathGenDirection == 1 or self.PathGenDirection == 3 then
            local y = self.LastPath.Y
            if self.PathGenDirection == 1 then
                y += 1
            else
                y -= 1
            end
            if not self.Blocks[y] then
                self.Blocks[y] = {}
            end
            local x = self.LastPath.X
            local block = MapAssets.MapPart:Clone()
            block.Parent = Workspace
            block.Size = Vector3.new(4.9, 1, 4.9)
            block.Position = Vector3.new(x * 5, 5, y * 5)
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            self.LastPath = {X = x; Y = y; Direction = self.PathGenDirection;}
            self.Blocks[x][y] = {
                Object = block;
                Placed = false;
                Path = true;
            }
        end
        table.insert(self.PathToBe, self.LastPath)
    end
end
]]
return MapGenerator