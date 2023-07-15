local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts
local Modules = PlayerScripts:WaitForChild("Modules")

local Draft = require(Modules:WaitForChild("Draft"))
local MobHealthDisplay = require(Modules:WaitForChild("MobHealthDisplay"))
local HudManager = require(Modules:WaitForChild("HudManager"))
local GameFXManager = require(Modules:WaitForChild("GameFXManager"))
local Data = require(Modules:WaitForChild("Data"))

local PlayerGui = Player.PlayerGui

local RemoteEvent = ReplicatedStorage.ServerCommunication
local ClientEvents = ReplicatedStorage.ClientEvents
local DraftBegin = ClientEvents.DraftBegin
local GameStarted = ClientEvents.GameStarted
local WaveReady = ClientEvents.WaveReady
local WaveStart = ClientEvents.WaveStart
local Update = ClientEvents.Update

RemoteEvent:FireServer("GameLoaded")
local function startGame(data)
    Data.Data = data
    HudManager.start()
    HudManager.TowerManager.update()
    HudManager.BaseManager.update()
    HudManager.WaveManager.update()
    HudManager.CoinManager.update()
    HudManager.ShopManager.update()
end

local draftCards, playerNum = DraftBegin.Event:Wait()
Draft.draftBegin(draftCards, playerNum)

local connection = Player.CharacterAdded:Connect(function()
    Draft.draftBegin(draftCards, playerNum)
end)

local gameStarted = GameStarted.Event:Wait()
connection:Disconnect()
startGame(gameStarted)

Player.CharacterAdded:Connect(function()
    startGame(Data.Data)
end)

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

UserInputService.InputBegan:Connect(function(inputObj)
    local placing = HudManager.TowerManager.Placing
    if inputObj.KeyCode == Enum.KeyCode.F and placing then
        HudManager.TowerManager.endPlacement()
    end
    local mouseLocation = UserInputService:GetMouseLocation()
    local frames = PlayerGui:GetGuiObjectsAtPosition(mouseLocation.X, mouseLocation.Y - 36)
    local clickThrough = true
    for _, frame in pairs(frames) do
        if not frame:GetAttribute("ClickThrough") then
            clickThrough = false
        end
    end
    if clickThrough then
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            print("Clicked")
            if placing then
                print("Place")
                HudManager.TowerManager.placeTower()
            else
                HudManager.TowerManager.selectTower(Data.Data.TowerManager.Towers)
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