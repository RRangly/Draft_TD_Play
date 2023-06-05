local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local MapAssets = ReplicatedStorage.MapAssets
local MapBlock = ServerScriptService.Modules.MapBlock

local MapGenerator = {}
MapGenerator.__index = MapGenerator

function MapGenerator.generateMap(player)
    local map = {
        Blocks = {};
        PathGenDirection = 2;
        PathToBe = {}
    }
    setmetatable(map, MapGenerator)
    for x = 0, 3, 1 do
        map.Blocks[x] = {}
        for y = 0, 4, 1 do
            local block = MapAssets.MapPart:Clone()
            block.Parent = Workspace
            block.Size = Vector3.new(4.9, 1, 4.9)
            block.Position = Vector3.new(x * 5, 5, y * 5)
            local coordText = block.CoordGui.CoordText
            coordText.Text = "( " .. x .. " , " .. y .. " )"
            local path = false
            if y == 2 then
                coordText.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                map.LastPath = {X = x; Y = y; Direction = map.PathGenDirection;}
                path = true
            end
            map.Blocks[x][y] = {
                Object = block;
                Placed = false;
                Path = path;
            }
        end
    end
    for x = 3, 7 do
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
    player.Character:MoveTo(Vector3.new(2.5, 5, 12.5))
    return map
end

function MapGenerator:getNeighbours(x, y)
    local x1 = self.Blocks[x]
    local x2 = self.Blocks[x + 1]
    local x3 = self.Blocks[x - 1]
    local returnVal = {}
    if x1 then
        returnVal[1] = x1[y + 1]
        returnVal[3] = x1[y - 1]
    end
    if x2 then
        returnVal[2] = x2[y]
    end
    if x3 then
        returnVal[3] = x3[y]
    end
    return {
        {returnVal[1], x, y + 1},
        {returnVal[2], x + 1, y},
        {returnVal[3], x, y - 1},
        {returnVal[4], x - 1, y},
    }
end

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
    local tobeNe2 = self:getNeighbours(tobeNe1[2], tobeNe1[3])[tobe]
    if tobeNe1[1] and tobeNe1[1].Path then
        changing = false
    end
    if tobeNe2[1] and tobeNe2[1].Path then
        changing = false
    end
    if changing then
        self.PathGenDirection = tobe
    else
        print("DirectionChangeCancelled", tobe, tobeNe1, tobeNe2)
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

return MapGenerator