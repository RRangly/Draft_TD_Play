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
    player.Character:MoveTo(Vector3.new(2.5, 5, 12.5))
    return map
end

function MapGenerator:floodFill(visited, filledAmount, x, y, trialChunk)
    if not visited[x] then
        visited[x] = {}
    end
    visited[x][y] = true
    if filledAmount >= 15 then
        return false
    end
    local neighbours = self:getChunkNeighbours(x, y)
    for _, info in pairs(neighbours) do
        if info[1] then
            continue
        end
        if info[2] == trialChunk.X and info[3] == trialChunk.Y then
            continue
        end
        if visited[info[2]] then
            if visited[info[2]][info[3]] then
                continue
            end
        end
        local result = self:floodFill(visited, filledAmount + 1, info[2], info[3], trialChunk)
        if result == false then
            return false
        end
    end
    return true
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

function MapGenerator:getChunkNeighbours(x, y)
    local chunks = self.Chunks
    local x1 = chunks[x]
    local x2 = chunks[x + 1]
    local x3 = chunks[x - 1]
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
    return {
        {returnVal[1], x, y + 2},
        {returnVal[2], x + 2, y},
        {returnVal[3], x, y - 2},
        {returnVal[4], x - 2, y},
    }
end

function MapGenerator:generatePath(chunk, startCoord, endCoord)
    chunk.Tiles[startCoord.X][startCoord.Y].Visited = true
    if startCoord.X == endCoord.X and startCoord.Y == endCoord.Y then
        chunk.Tiles[startCoord.X][startCoord.Y].Path = true
        return true
    end
    local neighbours = self:getSecondNeighbours(chunk, startCoord.X, startCoord.Y)
    local toDel = {}
    for i = #neighbours, 1, -1 do
        local info = neighbours[i]
        if not info[1] or info[1].Visited then
            table.remove(neighbours, i)
        end
    end

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
    end
    chunk.Tiles[startCoord.X][startCoord.Y].Visited = false
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
    local neighbours = self:getChunkNeighbours(chunkPos.X, chunkPos.Y)
    local formedLoop = false

    repeat
        repeat
            dir = math.random(1, 4)
            local trialChunk = {X = neighbours[dir][2]; Y = neighbours[dir][3];}
            for _, neighbour in pairs(self:getChunkNeighbours(trialChunk.X, trialChunk.Y)) do
                if neighbour[1] then
                    continue
                end
                local result = self:floodFill({}, 0, neighbour[2], neighbour[3], trialChunk)
                if result then
                    formedLoop = result
                end
            end
        until dir ~= MapGenerator.oppositeDirection(self.PathGenDirection) and not neighbours[dir][1] and not formedLoop
    until not formedLoop

    self.PathGenDirection = dir
    local endCoord
    if self.PathGenDirection == 1 then
        endCoord = {X = 4; Y = 8;}
        for i = 0, 8, 1 do
            chunk.Tiles[i][9] = {
                Path = false;
                Visited = false;
            }
            if i == 4 then
                chunk.Tiles[i][9].Path = true
            end
        end
    elseif self.PathGenDirection == 2 then
        endCoord = {X = 8; Y = 4;}
        chunk.Tiles[9] = {}
        for i = 0, 8, 1 do
            chunk.Tiles[9][i] = {
                Path = false;
                Visited = false;
            }
            if i == 4 then
                chunk.Tiles[9][i].Path = true
            end
        end
    elseif self.PathGenDirection == 3 then
        endCoord = {X = 4; Y = 0;}
        for i = 0, 8, 1 do
            chunk.Tiles[i][-1] = {
                Path = false;
                Visited = false;
            }
            if i == 4 then
                chunk.Tiles[i][-1].Path = true
            end
        end
    elseif self.PathGenDirection == 4 then
        endCoord = {X = 0; Y = 4;}
        chunk.Tiles[-1] = {}
        for i = 0, 8, 1 do
            chunk.Tiles[-1][i] = {
                Path = false;
                Visited = false;
            }
            if i == 4 then
                chunk.Tiles[-1][i].Path = true
            end
        end
    end
    self:generatePath(chunk, startCoord, endCoord)

    if not self.Chunks[chunkPos.X] then
        self.Chunks[chunkPos.X] = {}
    end

    self.Chunks[chunkPos.X][chunkPos.Y] = {
        Tiles = {}
    }

    for x, xTile in pairs(chunk.Tiles) do
        self.Chunks[chunkPos.X][chunkPos.Y].Tiles[x] = {}
        for y, tile in pairs(xTile) do
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

return MapGenerator