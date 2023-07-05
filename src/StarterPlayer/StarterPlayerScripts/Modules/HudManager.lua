local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SoundFX = ReplicatedStorage.SoundFX

local Towers = ReplicatedStorage.Towers
local TowerModels = ReplicatedStorage.TowerModels
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis
local PlayerGuiAssets = ReplicatedStorage.PlayerGuiAssets
local ClientAssets = ReplicatedStorage.ClientAssets

local Data = require(script.Parent.Data)
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local CurrentGui

local TowerManager = {
    Selected = {}
}

function TowerManager.statChange(textLabel, index, statName, present, upgrade)
    textLabel.TextSize = 28
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Position = UDim2.new(0, 10, index * 0.1, 10)
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Text = statName .. ": " .. present .. " -> " .. upgrade
end

function TowerManager.updateSelection(coins, towers, towerIndex)
    if TowerManager.Selected.RangeDisplay then
        local part = TowerManager.Selected.RangeDisplay
        local tween = TweenService:Create(part, TweenInfo.new(0.5), {Size = Vector3.new(0.2, 0, 0)})
        tween:Play()
        tween.Completed:Once(function()
            part:Destroy()
        end)
    end
    if TowerManager.SelectFrame then
        TowerManager.SelectFrame:Destroy()
    end
    if not towerIndex then
        return
    end

    local clone = PlayerGuiAssets.TowerSelectFrame:Clone()
    TowerManager.SelectFrame = clone
    clone.Parent = CurrentGui
    local tower = towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))

    local presentStats = towerInfo.Stats[tower.Level]

    TowerManager.Selected.RangeDisplay = ClientAssets.TowerRangeDisplay:Clone()
    TowerManager.Selected.RangeDisplay.Parent = Workspace
    local towerPosition = tower.Model:GetPivot().Position
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local origin = Vector3.new(towerPosition.X, towerPosition.Y + 1, towerPosition.Z)
    local ending = Vector3.new(towerPosition.X, towerPosition.Y - 3000, towerPosition.Z)
    local ray = Workspace:Raycast(origin, ending, rayCastParam)
    local displayPos = Vector3.new(ray.Position.X, ray.Position.Y + 0.1, ray.Position.Z)
    TowerManager.Selected.RangeDisplay.Position = displayPos
    local tween = TweenService:Create(TowerManager.Selected.RangeDisplay, TweenInfo.new(0.5), {Size = Vector3.new(0.2, presentStats.AttackRange * 2, presentStats.AttackRange * 2)})
    tween:Play()

    local present = clone.Present
    local towerLevel = present.TowerLevel
    towerLevel.Text = tower.Level
    local towerName = present.TowerName
    towerName.Text = tower.Name
    local sellButton = present.Sell
    sellButton.MouseButton1Click:Connect(function()
        TowerManager.Selected.Index = nil
        RemoteEvent:FireServer("ManageTower", "Sell", towerIndex)
    end)
    local switchTarget = present.SwitchTarget
    switchTarget.MouseButton1Click:Connect(function()
        RemoteEvent:FireServer("ManageTower", "SwitchTarget", towerIndex)
    end)
    switchTarget.Text = tower.Target

    local upgrade = clone.Upgrade
    local upgradeStats = towerInfo.Stats[tower.Level + 1]
    local nextName = upgrade.NextName
    nextName.Text = upgradeStats.LevelName
    local nextLevel = upgrade.NextLevel
    nextLevel.Text = tower.Level + 1
    local statChangeList = upgrade.StatChangeList
    local index = 0
    for statName, statVal in pairs(presentStats) do
        if statName == "LevelName" or statName == "Cost" then
            continue
        end
        if upgradeStats[statName] ~= statVal then
            TowerManager.statChange(Instance.new("TextLabel", statChangeList), index, statName, statVal, upgradeStats[statName])
            index += 1
        end
    end
    local upgradeButton = upgrade.Upgrade
    upgradeButton.Text = "Upgrade: " .. upgradeStats.Cost
    upgradeButton.MouseButton1Click:Connect(function()
        if coins >= upgradeStats.Cost then
            RemoteEvent:FireServer("ManageTower", "Upgrade", towerIndex)
        else
            print("Not Enough Money!")
        end
    end)
end

function TowerManager.mouseRayCast(collisionGroup)
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = collisionGroup
    local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 100, rayCastParam)
    if rayResult then
        return {rayResult.Instance, rayResult.Position}
    else
        return nil
    end
end

function TowerManager.getTileCoord(block)
    local pos = block.Position
    local chunk = Vector2.new(math.floor(pos.X / 50), math.floor(pos.Z / 50))
    local tile = Vector2.new(math.floor((pos.X - chunk.X * 50) / 5), math.floor((pos.Z - chunk.Y * 50) / 5))
    return chunk, tile
end

function TowerManager.checkPlacementAvailable(towerType, block)
    local tileType = block:GetAttribute("Type")
    if tileType == towerType then
        return true
    else
        print("Type", tileType, towerType)
    end
    return false
end

function TowerManager.startPlacement(tower, index)
    print("SP", tower, TowerManager)
    TowerManager.Placing = {
        Tower = tower;
        TowerIndex = index
    }
end

function TowerManager.placeTower()
    local placing = TowerManager.Placing
    local rayCast = TowerManager.RayCast

    if rayCast then
        local towerInfo = require(Towers:FindFirstChild(TowerManager.Placing.Tower))
        local chunkPos, tilePos = TowerManager.getTileCoord(rayCast.Part)
        local available = TowerManager.checkPlacementAvailable(towerInfo.Placement.Type, rayCast.Part)
        if available then
            TowerManager.Placing = nil
            RemoteEvent:FireServer("PlaceTower", placing.TowerIndex, {Chunk = chunkPos; Tile = tilePos;})
        end
    end
    if placing.Model then
        placing.Model:Destroy()
    end
end

function TowerManager.cancelPlacement()
    local placing = TowerManager.Placing
    if placing.Model then
        placing.Model:Destroy()
    end
    TowerManager.Placing = nil
end

function TowerManager.selectTower(coins, towers)
    local rayCast = TowerManager.mouseRayCast("EveryThing")
    if rayCast then
        for i, tower in pairs(towers) do
            local model = rayCast[1]:IsDescendantOf(tower.Model)
            if model then
                TowerManager.Selected.Index = i;
                print("Selected", TowerManager.Selected)
                TowerManager.updateSelection(coins, towers, i)
                return TowerManager.Selected
            end
        end
    end
    TowerManager.updateSelection(coins, towers, nil)
    TowerManager.Selected.Index = nil
end

function TowerManager.updateCards(cards)
    CurrentGui.TowersFrame:ClearAllChildren()
    local xInterval = 1 / (#cards + 1)
    for i, tower in pairs(cards) do
        local towerInfo = require(Towers:FindFirstChild(tower))
        local frame = PlayerGuiAssets.TowerFrame:Clone()
        frame.Parent = CurrentGui.TowersFrame
        frame.Position = UDim2.new(xInterval * i, 0, 0, 0)
        frame.TowerName.Text = towerInfo.Name
        frame.CostLabel.Text = towerInfo.Stats[1].Cost
        frame.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                TowerManager.startPlacement(tower, i)
            end
        end)
    end
end

function TowerManager.update()
    local data = Data.Data
    TowerManager.updateSelection(data.CoinManager.Coins, data.TowerManager.Towers, TowerManager.Selected.Index)
    TowerManager.updateCards(data.TowerManager.Cards)
end

RunService.RenderStepped:Connect(function()
    local rayCast = TowerManager.mouseRayCast("Towers")
    local placeable
    if rayCast then
        TowerManager.RayCast = {}
        TowerManager.RayCast.Part = rayCast[1]
        TowerManager.RayCast.Position = rayCast[2]
    else
        TowerManager.RayCast = nil
    end
    if TowerManager.Placing then
        local towerInfo = require(Towers:FindFirstChild(TowerManager.Placing.Tower))
        if rayCast and rayCast[1].CollisionGroup == "Tiles" then
            if not TowerManager.Placing.Model then
                print("ModelReplace")
                local model = TowerModels:FindFirstChild(TowerManager.Placing.Tower):Clone()
                TowerManager.Placing.Model = model
                model.Parent = Workspace
                for _, part in pairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CollisionGroup = "Towers"
                        part.Anchored = true
                        part.CanCollide = true
                        part.CanTouch = false
                        part.CanQuery = false
                        part.Material = Enum.Material.ForceField
                    end
                end
            end
            local chunkPos, tilePos = TowerManager.getTileCoord(rayCast[1])
            placeable = TowerManager.checkPlacementAvailable(towerInfo.Placement.Type, rayCast[1])
            TowerManager.Placing.Model:MoveTo(Vector3.new(chunkPos.X * 50 + tilePos.X * 5, 5, chunkPos.Y * 50 + tilePos.Y * 5))
            local model = TowerManager.Placing.Model
            for _, part in pairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    if placeable then
                        part.Color = Color3.new(0, 1, 0)
                    else
                        part.Color = Color3.new(1, 0, 0)
                    end
                end
            end
        else
            if TowerManager.Placing.Model then
                print("ModelDestroyed")
                TowerManager.Placing.Model:Destroy()
                TowerManager.Placing.Model = nil
            end
        end
    end
end)

local BaseManager = {}

function BaseManager.updateBaseHp(baseManager)
    local greenFactor = 255
    local redFactor = 255
    local maxHp = baseManager.MaxHealth
    local hp = baseManager.Health
    if hp / maxHp < 0.5 then
        greenFactor = ((hp / maxHp) * 2) * 255
    end
    if hp / maxHp > 0.5 then
        redFactor = ((1 - (hp / maxHp)) * 2) * 255
    end
    local bar = CurrentGui.BaseHpFrame.HpBar
    local text = CurrentGui.BaseHpFrame.HpText
    bar.Size = UDim2.new(hp / maxHp, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(redFactor, greenFactor, 0)
    text.Text = hp .. " / " .. maxHp
end

function BaseManager.update()
    BaseManager.updateBaseHp(Data.Data.BaseManager)
end
local WaveManager = {}

function WaveManager.starting(wave)
    local message = CurrentGui.WaveStartingMessage
    message.Visible = true
    for i = 10, 1, -1 do
        message.Text = "Wave ".. wave .. " Starting in "..  i .. " seconds"
        task.wait(1)
    end
    message.Visible = false
end

function WaveManager.updateWave(wave)
    local waveText = CurrentGui.WaveText
    waveText.Text = "Wave " .. wave
end

function WaveManager.update()
    WaveManager.updateWave(Data.Data.WaveManager.CurrentWave)
end

local CoinManager = {}

function CoinManager.updateCoins(coins)
    local coinText = CurrentGui.CoinText
    coinText.Text = "Coins " .. coins
end

function CoinManager.update()
    CoinManager.updateCoins(Data.Data.CoinManager.Coins)
end

local ShopManager = {}

function ShopManager.updateShop(shopManager)
    local shopFrame = CurrentGui.Shop
    local shopItems = shopManager.ShopItems
    local rerollCost = math.floor(1.1 ^ shopManager.ReRoll * 115)
    shopFrame.ReRoll.Cost.Text = rerollCost
    shopFrame.ReRoll.MouseButton1Click:Connect(function()
        RemoteEvent:FireServer("ManageShop", "ReRoll")
    end)
    for i = 1, 3, 1 do
        local frame = shopFrame.ShopItems:FindFirstChild(i)
        if not shopItems[i] then
            frame.Visible = false
            continue
        end
        local card = require(Towers:FindFirstChild(shopItems[i]))
        frame.Visible = true
        frame.CardName.Text = card.Name
        frame.CardCost.Text = card.Stats[1].Cost
        frame.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                RemoteEvent:FireServer("ManageShop", "Pick", i)
            end
        end)
    end
end

function ShopManager.update()
    ShopManager.updateShop(Data.Data.ShopManager)
end
local HudManager = {
    BaseManager = BaseManager;
    TowerManager = TowerManager;
    WaveManager = WaveManager;
    CoinManager = CoinManager;
    ShopManager = ShopManager;
}

function HudManager.start()
    CurrentGui = PlayerGuis.Hud:Clone()
    CurrentGui.Parent = PlayerGui
end

return HudManager