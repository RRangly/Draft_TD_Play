local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local MapAssets = ReplicatedStorage.MapAssets
local MapFolder = Workspace.Map

local MapSeed = 0.281

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
        LastChunk = {X = 0; Y = 0;};
        WayPoints = {};
    }
    setmetatable(map, MapGenerator)
    map.Chunks[0] = {}
    map.Chunks[0][0] = {
        Tiles = {}
    }
    local chunk = map.Chunks[0][0]
    local chunkXFolder = Instance.new("Folder" , MapFolder)
    chunkXFolder.Name = 0
    local chunkFolder = Instance.new("Folder", chunkXFolder)
    chunkFolder.Name = 0
    for x = 0, 9, 1 do
        chunk.Tiles[x] = {}
        local xFolder = Instance.new("Folder", chunkFolder)
        xFolder.Name = x
        for y = 0, 8, 1 do
            local tileType = "Plain"
            local block = MapAssets.MapPart:Clone()
            block.Parent = xFolder
            block.Position = Vector3.new(x * 5, 5, y * 5)
            block.Name = y
            block.CollisionGroup = "Tiles"
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            local path = false
            if y == 4 then
                coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                path = true
                table.insert(map.WayPoints, 1, Vector3.new(x * 5, 10, y * 5))
                tileType = "Path"
            end
            block:SetAttribute("Type", tileType)
            chunk.Tiles[x][y] = {
                Object = block;
                Placed = false;
                Path = path;
                Type = "Plain";
            }
        end
    end
    player.Character:MoveTo(Vector3.new(2.5, 5, 12.5))
    return map
end

function MapGenerator:floodFill(visited, filledAmount, position, trialChunk)
    if not visited[position.X] then
        visited[position.X] = {}
    end
    visited[position.X][position.Y] = true
    if filledAmount >= 15 then
        return false
    end
    local neighbours = self:getChunkNeighbours(position.X, position.Y)
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
        local result = self:floodFill(visited, filledAmount + 1, Vector2.new(info[2], info[3]), trialChunk)
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

function MapGenerator:getHeight(chunkPos: Vector2, tilePos: Vector2)
    return math.round(((1 + math.noise(chunkPos.X * 10 + tilePos.X, chunkPos.Y * 10 + tilePos.Y, MapSeed)) / 2) - 0.1)
end

function MapGenerator:generatePath(chunk, startCoord, endCoord)
    chunk.Tiles[startCoord.X][startCoord.Y].Visited = true
    if startCoord.X == endCoord.X and startCoord.Y == endCoord.Y then
        chunk.Tiles[startCoord.X][startCoord.Y].Path = true
        table.insert(chunk.Path, 1, startCoord)
        return true
    end
    local neighbours = self:getSecondNeighbours(chunk, startCoord.X, startCoord.Y)
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
        local result = self:generatePath(chunk, Vector2.new(neighbour[2], neighbour[3]), endCoord)
        if result then
            chunk.Tiles[startCoord.X][startCoord.Y].Path = true
            local pathWay = self:getBetween(chunk, startCoord, Vector2.new(neighbour[2], neighbour[3]))
            chunk.Tiles[pathWay[2]][pathWay[3]].Path = true
            table.insert(chunk.Path, 1, startCoord)
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
        Tiles = {};
        Path = {};
    }
    local chunkPos
    local startCoord
    if self.PathGenDirection == 1 then
        startCoord = Vector2.new(4, 0)
        chunkPos = Vector2.new(self.LastChunk.X, self.LastChunk.Y + 1)
    elseif self.PathGenDirection == 2 then
        startCoord = Vector2.new(0, 4)
        chunkPos = Vector2.new(self.LastChunk.X + 1, self.LastChunk.Y)
    elseif self.PathGenDirection == 3 then
        startCoord = Vector2.new(4, 8)
        chunkPos = Vector2.new(self.LastChunk.X, self.LastChunk.Y - 1)
    elseif self.PathGenDirection == 4 then
        startCoord = Vector2.new(8, 4)
        chunkPos = Vector2.new(self.LastChunk.X - 1, self.LastChunk.Y)
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
                local result = self:floodFill({}, 0, Vector2.new(neighbour[2], neighbour[3]), trialChunk)
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
        end
        chunk.Tiles[4][9].Path = true
        table.insert(chunk.Path, 1, Vector2.new(4, 9))
    elseif self.PathGenDirection == 2 then
        endCoord = {X = 8; Y = 4;}
        chunk.Tiles[9] = {}
        for i = 0, 8, 1 do
            chunk.Tiles[9][i] = {
                Path = false;
                Visited = false;
            }
        end
        chunk.Tiles[9][4].Path = true
        table.insert(chunk.Path, 1, Vector2.new(9, 4))
    elseif self.PathGenDirection == 3 then
        endCoord = {X = 4; Y = 0;}
        for i = 0, 8, 1 do
            chunk.Tiles[i][-1] = {
                Path = false;
                Visited = false;
            }
        end
        chunk.Tiles[4][-1].Path = true
        table.insert(chunk.Path, 1, Vector2.new(4, -1))
    elseif self.PathGenDirection == 4 then
        endCoord = {X = 0; Y = 4;}
        chunk.Tiles[-1] = {}
        for i = 0, 8, 1 do
            chunk.Tiles[-1][i] = {
                Path = false;
                Visited = false;
            }
        end
        chunk.Tiles[-1][4].Path = true
        table.insert(chunk.Path, 1, Vector2.new(-1, 4))
    end
    self:generatePath(chunk, startCoord, endCoord)

    if not self.Chunks[chunkPos.X] then
        self.Chunks[chunkPos.X] = {}
        Instance.new("Folder" ,MapFolder).Name = chunkPos.X
    end

    local chunkXFolder = MapFolder:FindFirstChild(chunkPos.X)
    local chunkFolder = Instance.new("Folder", chunkXFolder)
    chunkFolder.Name = chunkPos.Y

    self.Chunks[chunkPos.X][chunkPos.Y] = {
        Tiles = {}
    }

    for _, coord in pairs(chunk.Path) do
        table.insert(self.WayPoints, 1, Vector3.new(chunkPos.X * 50 + coord.X * 5, 10, chunkPos.Y * 50 + coord.Y * 5))
    end
    for x, xTile in pairs(chunk.Tiles) do
        self.Chunks[chunkPos.X][chunkPos.Y].Tiles[x] = {}
        local xFolder = Instance.new("Folder", chunkFolder)
        xFolder.Name = x
        for y, tile in pairs(xTile) do
            local tileHeight = 0
            if not tile.Path then
                tileHeight = self:getHeight(chunkPos, Vector2.new(x, y))
                tile.Height = tileHeight
            end
            local block = MapAssets.MapPart:Clone()
            block.Parent = Workspace
            block.Position = Vector3.new(chunkPos.X * 50 + x * 5, 5 + (tileHeight * 1.5), chunkPos.Y * 50 + y * 5)
            block.Size = Vector3.new(5, tileHeight * 3 + 1, 5)
            block.Parent = xFolder
            block.Name = y
            block.CollisionGroup = "Tiles"
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            local tileType = "Plain"
            if tileHeight > 0 then
                tileType = "Cliff"
            end
            if tile.Path then
                coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                tileType = "Path"
            end
            block:SetAttribute("Type", tileType)
            self.Chunks[chunkPos.X][chunkPos.Y].Tiles[x][y] = {
                Object = block;
                Placed = false;
                Path = tile.Path;
                Type = tileType;
            }
        end
    end

    self.LastChunk = chunkPos
end

return MapGenerator