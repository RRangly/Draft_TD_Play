local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

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

local NotificationManager = {}

function NotificationManager.new(text: string)
    local notiFrame = CurrentGui.NotificationFrame
    local notiText = PlayerGuiAssets.NotificationText:Clone()
    notiText.Parent = notiFrame
    notiText.Position = UDim2.new(0, 0, 0, 0)
    notiText.Text = text
    local tween = TweenService:Create(notiText, TweenInfo.new(2.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 1, 0)})
    tween:Play()
    tween.Completed:Wait()
    notiText:Destroy()
end

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

function TowerManager.updateSelection(towerIndex)
    local towers = Data.Data.TowerManager.Towers
    if TowerManager.Selected.Index ~= towerIndex then
        local rangeDisplay = TowerManager.Selected.RangeDisplay
        if rangeDisplay then
            local tween = TweenService:Create(TowerManager.Selected.RangeDisplay, TweenInfo.new(0.5), {Size = Vector3.new(0.2, 0, 0)})
            tween:Play()
            tween.Completed:Once(function()
                rangeDisplay:Destroy()
            end)
        end
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

    if TowerManager.Selected.Index ~= towerIndex then
        TowerManager.Selected.RangeDisplay = ClientAssets.TowerRangeDisplay:Clone()
        TowerManager.Selected.RangeDisplay.Parent = tower.Model
        local towerPosition = tower.Model:GetPivot().Position
        local displayPos = Vector3.new(towerPosition.X, towerPosition.Y - towerInfo.Placement.Height + 0.1, towerPosition.Z)
        TowerManager.Selected.RangeDisplay.Position = displayPos
        local tween = TweenService:Create(TowerManager.Selected.RangeDisplay, TweenInfo.new(0.5), {Size = Vector3.new(presentStats.AttackRange * 2, 0.001, presentStats.AttackRange * 2)})
        tween:Play()
    end

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
    local nextLevel = upgrade.NextLevel
    local upgradeButton = upgrade.Upgrade
    if upgradeStats then
        nextName.Text = upgradeStats.LevelName
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
        upgradeButton.Text = "Upgrade: " .. upgradeStats.Cost
        upgradeButton.MouseButton1Click:Connect(function()
            if Data.Data.CoinManager.Coins >= upgradeStats.Cost then
                RemoteEvent:FireServer("ManageTower", "Upgrade", towerIndex)
            else
                NotificationManager.new("Too Expensive!")
            end
        end)
    else
        nextName.Text = "Maxed!"
        nextLevel.Text = tower.Level
        upgradeButton.Text = "Maxed!"
    end
    TowerManager.Selected.Index = towerIndex
end

function TowerManager.mouseRayCast(collisionGroup)
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = collisionGroup
    local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 1000, rayCastParam)
    if rayResult then
        return {rayResult.Instance, rayResult.Position}
    else
        return nil
    end
end

function TowerManager.checkPlacementAvailable(towerType, part)
    --[[
    local start = Vector3.new(position.X, position.Y + 1, position.Z)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local ray = Workspace:Raycast(start, Vector3.new(0, -10, 0), rayCastParam)
    if ray and ray.Instance:GetAttribute("Placement") == towerType then
        return ray.Position
    end
    ]]
    if part:GetAttribute("Placement") == towerType then
        return true
    end
    return false
end

function TowerManager.startPlacement(tower, index)
    local towerInfo = require(Towers:FindFirstChild(tower))
    local highLights = Workspace.Map:GetChildren()[1].HighLights
    for _, obj in pairs(highLights:GetChildren()) do
        obj.FillTransparency = 1
        obj.OutlineTransparency = 1
        obj.Enabled = true
        local fillT = 0.5
        if obj.Name == towerInfo.Placement.Type then
            obj.FillColor = Color3.fromRGB(0, 255, 0)
            fillT = 0.3
        else
            obj.FillColor = Color3.fromRGB(255, 0, 0)
        end
        local tween = TweenService:Create(obj, TweenInfo.new(0.5), {FillTransparency = fillT; OutlineTransparency = 0;})
        tween:Play()
    end
    if TowerManager.Placing and TowerManager.Placing.Model then
        TowerManager.Placing.Model:Destroy()
    end
    TowerManager.Placing = {
        Tower = tower;
        TowerIndex = index
    }
end

function TowerManager.endPlacement()
    local highLights = Workspace.Map:GetChildren()[1].HighLights
    for _, obj in pairs(highLights:GetChildren()) do
        task.spawn(function()
            local tween = TweenService:Create(obj, TweenInfo.new(0.5), {FillTransparency = 1; OutlineTransparency = 1;})
            tween:Play()
            tween.Completed:Wait()
            obj.Enabled = false
        end)
    end
    if TowerManager.Placing.Model then
        TowerManager.Placing.Model:Destroy()
    end
    TowerManager.Placing = nil
end

function TowerManager.placeTower()
    local placing = TowerManager.Placing
    local rayCast = TowerManager.RayCast
    if rayCast then
        local towerInfo = require(Towers:FindFirstChild(TowerManager.Placing.Tower))
        local placeable = TowerManager.checkPlacementAvailable(towerInfo.Placement.Type, rayCast.Part)
        if placeable then
            RemoteEvent:FireServer("PlaceTower", placing.TowerIndex, rayCast.Position)
            TowerManager.endPlacement()
            return
        end
    end
    NotificationManager.new("Can't Place Here!")
end

function TowerManager.selectTower(towerManager)
    local rayCast = TowerManager.mouseRayCast("EveryThing")
    if rayCast then
        for i, tower in pairs(towerManager) do
            local model = rayCast[1]:IsDescendantOf(tower.Model)
            if model then
                TowerManager.updateSelection(i)
                return TowerManager.Selected
            end
        end
    end
    TowerManager.updateSelection(nil)
end

function TowerManager.updateCards()
    local cards = Data.Data.TowerManager.Cards
    CurrentGui.TowersFrame:ClearAllChildren()
    for i, tower in pairs(cards) do
        local towerInfo = require(Towers:FindFirstChild(tower))
        local frame = PlayerGuiAssets.TowerFrame:Clone()
        frame.Parent = CurrentGui.TowersFrame
        frame.Position = UDim2.new(0.09 * (i - 1) + 0.01, 0, 0.5, 0)
        frame.TowerName.Text = towerInfo.Name
        frame.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                TowerManager.startPlacement(tower, i)
            end
        end)
    end
end

function TowerManager.update()
    print("Update", TowerManager.Selected.Index)
    TowerManager.updateSelection(TowerManager.Selected.Index)
    TowerManager.updateCards()
end

RunService.RenderStepped:Connect(function()
    local rayCast = TowerManager.mouseRayCast("Towers")
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
                        part.Anchored = true
                        part.CanCollide = true
                        part.CanTouch = false
                        part.CanQuery = false
                        part.Material = Enum.Material.ForceField
                    end
                end
            end
            local placeable = TowerManager.checkPlacementAvailable(towerInfo.Placement.Type, TowerManager.RayCast.Part)
            local pos = Vector3.new(TowerManager.RayCast.Position.X, TowerManager.RayCast.Position.Y + towerInfo.Placement.Height, TowerManager.RayCast.Position.Z)
            TowerManager.Placing.Model:PivotTo(CFrame.new(pos))
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

function BaseManager.updateBaseHp()
    local baseManager = Data.Data.BaseManager

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
    BaseManager.updateBaseHp()
end

local WaveManager = {}

function WaveManager.arrowBlink()
    local arrows = Workspace.Map:GetChildren()[1].Arrows:GetChildren()
    task.spawn(function()
        local transparency = 0;
        local tway = -0.05;
        local passed = 0
        repeat
            if transparency <= -0.2 then
                tway = 0.05
            elseif transparency >= 1.3 then
                tway = -0.1
            end
            transparency += tway
            for _, obj in pairs(arrows) do
                obj.Transparency = transparency
            end
            task.wait(0.05)
            passed += 1
        until passed > 199
        for _, obj in pairs(arrows) do
            obj.Transparency = 1
        end
    end)
end

function WaveManager.starting(wave)
    local waveText = CurrentGui.WaveText
    waveText.Visible = true
    for i = 10, 1, -1 do
        waveText.Text = "Wave ".. wave .. " Starting in "..  i .. " seconds"
        task.wait(1)
    end
    waveText.Visible = false
end

function WaveManager.updateWave()
    local wave = Data.Data.WaveManager.CurrentWave
    local waveText = CurrentGui.WaveText
    waveText.Text = "Wave " .. wave
end

function WaveManager.update()
    WaveManager.updateWave()
end

local CoinManager = {}

function CoinManager.updateCoins()
    local coins = Data.Data.CoinManager.Coins
    local coinText = CurrentGui.CoinText
    coinText.Text = "Coins " .. coins
end

function CoinManager.update()
    CoinManager.updateCoins()
end

local ShopManager = {}

function ShopManager.updateShop()
    if CurrentGui:FindFirstChild("ShopMenu") then
        CurrentGui:FindFirstChild("ShopMenu"):Destroy()
    end
    local shopManager = Data.Data.ShopManager
    local shopFrame = PlayerGuiAssets.ShopMenu:Clone()
    shopFrame.Parent = CurrentGui
    local shopItems = shopManager.ShopItems
    local rerollCost = math.floor(1.1 ^ shopManager.ReRoll * 115)
    local chunkCost = math.floor(1.1 ^ shopManager.Chunks * 825)
    shopFrame.ReRoll.Cost.Text = rerollCost
    shopFrame.ReRoll.MouseButton1Click:Connect(function()
        if Data.Data.CoinManager.Coins >= rerollCost then
            RemoteEvent:FireServer("ManageShop", "ReRoll")
        end
    end)
    shopFrame.PurchaseChunk.Cost.Text = chunkCost
    shopFrame.PurchaseChunk.MouseButton1Click:Connect(function()
        print("Coins", Data.Data.CoinManager.Coins)
        if Data.Data.CoinManager.Coins >= chunkCost then
           RemoteEvent:FireServer("ManageShop", "Chunk")
        end
    end)
    for i = 1, 3, 1 do
        local frame = shopFrame.ShopItems:FindFirstChild(i)
        if not shopItems[i] then
            frame:Destroy()
            continue
        end
        local card = require(Towers:FindFirstChild(shopItems[i]))
        local cost = card.Stats[1].Cost
        frame.CardName.Text = card.Name
        frame.CardCost.Text = cost
        frame.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                if Data.Data.CoinManager.Coins >= cost then
                    RemoteEvent:FireServer("ManageShop", "Pick", i)
                end
            end
        end)
    end
end

function ShopManager.update()
    ShopManager.updateShop()
end

local HudManager = {
    BaseManager = BaseManager;
    TowerManager = TowerManager;
    WaveManager = WaveManager;
    CoinManager = CoinManager;
    ShopManager = ShopManager;
    NotificationManager = NotificationManager;
}

function HudManager.start()
    CurrentGui = PlayerGuis.Hud:Clone()
    CurrentGui.Parent = PlayerGui
end

return HudManager