local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Modules = PlayerScripts:WaitForChild("Modules")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local Draft = require(Modules:WaitForChild("Draft"))
local MobHealthDisplay = require(Modules:WaitForChild("MobHealthDisplay"))
local HudManager = require(Modules:WaitForChild("HudManager"))
local TowerFXManager = require(Modules:FindFirstChild("TowerFXManager"))
local GameFXManager = require(Modules:WaitForChild("GameFXManager"))
local Data = require(Modules:WaitForChild("Data"))

local PlayerGui = Player.PlayerGui

local ClientEvents = ReplicatedStorage.ClientEvents
local DraftBegin = ClientEvents.DraftBegin
local GameStarted = ClientEvents.GameStarted
local WaveReady = ClientEvents.WaveReady
local WaveStart = ClientEvents.WaveStart
local Update = ClientEvents.Update

local function startGame(data)
    Data.Data = data
    HudManager.start()
    --HudManager.TowerManager.updateCards(data.TowerManager.Cards)
    HudManager.TowerManager.update()
    HudManager.BaseManager.update()
    HudManager.WaveManager.update()
    HudManager.CoinManager.update()
    HudManager.ShopManager.update()
end

DraftBegin.Event:Connect(Draft.draftBegin)

Update.Event:Connect(function(dataType, data)
    Data.Data[dataType] = data
    if dataType == "MobManager" then
        MobHealthDisplay.update(data.Mobs)
        return
    end
    if HudManager[dataType] then
        HudManager[dataType].update()
    end
end)

WaveReady.Event:Connect(function(wave)
    HudManager.WaveManager.starting(wave)
end)

WaveStart.Event:Connect(function(wave)
    HudManager.WaveManager.updateWave(wave)
end)

local gameStarted = GameStarted.Event:Wait()
startGame(gameStarted)

UserInputService.InputBegan:Connect(function(inputObj)
    local placing = HudManager.TowerManager.Placing
    if inputObj.KeyCode == Enum.KeyCode.F and placing then
        HudManager.TowerManager.cancelPlacement()
    end
    local mouseLocation = UserInputService:GetMouseLocation()
    local frames = PlayerGui:GetGuiObjectsAtPosition(mouseLocation.X, mouseLocation.Y - 36)
    if #frames == 0 then
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            if placing then
                HudManager.TowerManager.placeTower(Data.Data.CoinManager.Coins)
            else
                HudManager.TowerManager.selectTower(Data.Data.CoinManager, Data.Data.TowerManager.Towers)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local ClientLoad = ReplicatedStorage.ClientLoad:FindFirstChild(Player.UserId)
    if ClientLoad and Data then
        for _, instance in pairs(ClientLoad:GetChildren()) do
            GameFXManager.executeLoad(Data, instance)
        end
    end
end)

Player.CharacterAdded:Connect(function()
    startGame(Data.Data)
end)