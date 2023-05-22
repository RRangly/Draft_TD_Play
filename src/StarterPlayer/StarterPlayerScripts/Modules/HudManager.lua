local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")


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

function TowerManager.mouseRayCast()
    local mousePosition = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local rayResult = Workspace:Raycast(ray.Origin, ray.Direction * 100, rayCastParam)
    if rayResult then
        return {rayResult.Instance, rayResult.Position}
    else
        return nil
    end
end

function TowerManager.checkPlacementAvailable(towerPosition)
    local rayCastParam = RaycastParams.new()
    rayCastParam.CollisionGroup = "Towers"
    local origin = Vector3.new(towerPosition.X, towerPosition.Y + 1, towerPosition.Z)
    local ending = Vector3.new(towerPosition.X, towerPosition.Y - 1000, towerPosition.Z)
    local ray = Workspace:Raycast(origin, ending, rayCastParam)
    local mapType
    if ray then
        mapType = ray.Instance:GetAttribute("MapType")
        print("MapType", mapType)
        if mapType == "Cliff" or mapType == "Plain" then
            return mapType
        end
        print("rayDebug", towerPosition, "|", origin, "|", ending, "|", ray.Position)
    end
    return false
end

function TowerManager.startPlacement(tower)
    print("SP", tower, TowerManager)
    TowerManager.Placing = {
        Tower = tower;
    }
end

function TowerManager.placeTower()
    local placing = TowerManager.Placing
    local rayCast = TowerManager.RayCast
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
    local rayCast = TowerManager.RayCast
    for i, tower in pairs(towers) do
        local model = rayCast.Part.Parent
        if model == tower.Model then
            TowerManager.Selected = {
                Index = i;
                TowerInfo = tower;
            }
        else
            TowerManager.Selected = nil
        end
    end
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
        frame.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                TowerManager.startPlacement(tower)
            end
        end)
    end
end

RunService.RenderStepped:Connect(function()
    local rayCast = TowerManager.mouseRayCast()
    local placeable
    if rayCast then
        TowerManager.RayCast = {}
        TowerManager.RayCast.Part = rayCast[1]
        TowerManager.RayCast.Position = rayCast[2]
        placeable = TowerManager.checkPlacementAvailable(rayCast[2])
    else
        TowerManager.RayCast = nil
    end
    if TowerManager.Placing then
        if rayCast then
            if not TowerManager.Placing.Model then
                print("ModelReplace")
                local model = TowerModels:FindFirstChild(TowerManager.Placing.Tower):Clone()
                TowerManager.Placing.Model = model
                model.Parent = Workspace
                for _, part in pairs(model:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CollisionGroup = "Towers"
                        part.CanCollide = false
                        part.CanTouch = false
                        part.CanQuery = false
                        part.Material = Enum.Material.ForceField
                        print("Placeable", placeable)
                    end
                end
            end
            TowerManager.Placing.Model:MoveTo(TowerManager.RayCast.Position)
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
        message.Text = wave .. " Starting in "..  i .. " seconds"
        task.wait(1)
    end
    message.Visible = false
end

function WaveManager.updateWave(wave)
    local waveText = CurrentGui.WaveText
    waveText.Text = "Wave" .. wave
end
local HudManager = {
    BaseManager = BaseManager;
    TowerManager = TowerManager;
    WaveManager = WaveManager;
}

function HudManager.start()
    CurrentGui = PlayerGuis.Hud:Clone()
    CurrentGui.Parent = PlayerGui
end

return HudManager