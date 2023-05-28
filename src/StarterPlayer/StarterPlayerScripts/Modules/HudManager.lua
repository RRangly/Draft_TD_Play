local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SoundFX = ReplicatedStorage.SoundFX

local Towers = ReplicatedStorage.Towers
local TowerModels = ReplicatedStorage.TowerModels
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis
local PlayerGuiAssets = ReplicatedStorage.PlayerGuiAssets

local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local CurrentGui

local TowerManager = {}

function TowerManager.statChange(textLabel, index, statName, present, upgrade)
    textLabel.TextSize = 28
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Position = UDim2.new(0, 10, index * 0.1, 10)
    --textLabel = Instance.new("TextLabel")
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Text = statName .. ": " .. present .. " -> " .. upgrade
end

function TowerManager.updateSelection(towers, towerIndex)
    if TowerManager.SelectFrame then
        TowerManager.SelectFrame:Destroy()
    end
    if not towerIndex then
        return
    end
    local tower = towers[towerIndex]
    local towerInfo = require(Towers:FindFirstChild(tower.Name))
    local presentStats = towerInfo.Stats[tower.Level]
    local clone = PlayerGuiAssets.TowerSelectFrame:Clone()
    TowerManager.SelectFrame = clone
    clone.Parent = CurrentGui

    local present = clone.Present
    local towerLevel = present.TowerLevel
    towerLevel.Text = tower.Level
    local towerName = present.TowerName
    towerName.Text = tower.Name
    local sellButton = present.Sell
    sellButton.MouseButton1Click:Connect(function()
        RemoteEvent:FireServer("SellTower", towerIndex)
    end)

    local upgrade = clone.Upgrade
    local upgradeStats = towerInfo.Stats[tower.Level + 1]
    local nextName = upgrade.NextName
    nextName.Text = upgradeStats.LevelName
    local nextLevel = upgrade.NextLevel
    nextLevel.Text = tower.Level + 1
    local statChangeList = upgrade.StatChangeList
    local index = 0
    for statName, statVal in pairs(presentStats) do
        if statName == "LevelName" then
            continue
        end
        if upgradeStats[statName] ~= statVal then
            TowerManager.statChange(Instance.new("TextLabel", statChangeList), index, statName, statVal, upgradeStats[statName])
            index += 1
        end
    end
    local upgradeButton = upgrade.Upgrade
    upgradeButton.MouseButton1Click:Connect(function()
        RemoteEvent:FireServer("UpgradeServer", towerIndex)
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

function TowerManager.checkPlacementAvailable(towerType, towerPosition)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local origin = Vector3.new(towerPosition.X, towerPosition.Y + 1, towerPosition.Z)
    local ending = Vector3.new(towerPosition.X, towerPosition.Y - 3000, towerPosition.Z)
    local ray = Workspace:Raycast(origin, ending, rayCastParam)
    local mapType
    if ray then
        mapType = ray.Instance:GetAttribute("MapType")
        if mapType == towerType then
            return ray
        end
    end
    return false
end

function TowerManager.startPlacement(tower)
    print("SP", tower, TowerManager)
    TowerManager.Placing = {
        Tower = tower;
    }
end

function TowerManager.placeTower(coins)
    local placing = TowerManager.Placing
    local rayCast = TowerManager.RayCast
    if not rayCast then
        return
    end
    local towerInfo = require(Towers:FindFirstChild(TowerManager.Placing.Tower))
    local placeable = TowerManager.checkPlacementAvailable(towerInfo.Placement.Type, rayCast.Position)
    if not placeable or coins < towerInfo.Stats.Cost then
        print("CantPlace")
        return
    end
    if placing.Model then
        placing.Model:Destroy()
    end
    TowerManager.Placing = nil
    RemoteEvent:FireServer("PlaceTower", placing.Tower, rayCast.Position)
end

function TowerManager.cancelPlacement()
    local placing = TowerManager.Placing
    if placing.Model then
        placing.Model:Destroy()
    end
    TowerManager.Placing = nil
end

function TowerManager.selectTower(towers)
    local rayCast = TowerManager.mouseRayCast("EveryThing")
    for i, tower in pairs(towers) do
        local model = rayCast[1]:IsDescendantOf(tower.Model)
        if model then
            TowerManager.Selected = {
                Index = i;
                TowerInfo = tower;
            }
            print("Selected", TowerManager.Selected)
            TowerManager.updateSelection(towers, i)
            return TowerManager.Selected
        end
    end
    TowerManager.Selected = nil
    TowerManager.updateSelection(towers, nil)
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
                TowerManager.startPlacement(tower)
            end
        end)
    end
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
        if rayCast then
            if not TowerManager.Placing.Model then
                print("ModelReplace")
                local model = TowerModels:FindFirstChild(TowerManager.Placing.Tower):Clone()
                TowerManager.Placing.Model = model
                model.Parent = Workspace
                for _, part in pairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CollisionGroup = "Towers"
                        part.CanTouch = false
                        part.CanQuery = false
                        part.Material = Enum.Material.ForceField
                    end
                end
            end
            placeable = TowerManager.checkPlacementAvailable(towerInfo.Placement.Type, rayCast[2])
            local pos = TowerManager.RayCast.Position
            local yUpper = TowerManager.Placing.Model:GetExtentsSize().Y / 2
            if placeable then
                TowerManager.Placing.Model:MoveTo(Vector3.new(pos.X, placeable.Position.Y + yUpper, pos.Z))
            else
                
                TowerManager.Placing.Model:MoveTo(Vector3.new(pos.X, pos.Y + yUpper, pos.Z))
            end
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

function BaseManager.updateBaseHp(Base)
    local greenFactor = 255
    local redFactor = 255
    local maxHp = Base.MaxHealth
    local hp = Base.Health
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

local WaveManager = {}

function WaveManager.starting(wave)
    local message = CurrentGui.WaveStartingMessage
    message.Visible = true
    for i = 5, 1, -1 do
        message.Text = "Wave ".. wave .. " Starting in "..  i .. " seconds"
        task.wait(1)
    end
    message.Visible = false
end

function WaveManager.updateWave(wave)
    local waveText = CurrentGui.WaveText
    waveText.Text = "Wave " .. wave
end

local CoinManager = {}

function CoinManager.updateCoins(coins)
    local audio = SoundFX.Money_Gain
    audio:Play()
    local coinText = CurrentGui.CoinText
    coinText.Text = "Coins " .. coins.Coins
end

local HudManager = {
    BaseManager = BaseManager;
    TowerManager = TowerManager;
    WaveManager = WaveManager;
    CoinManager = CoinManager;
}

function HudManager.start()
    CurrentGui = PlayerGuis.Hud:Clone()
    CurrentGui.Parent = PlayerGui
end

return HudManager