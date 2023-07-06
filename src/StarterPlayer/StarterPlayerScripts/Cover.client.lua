local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGuis = ReplicatedStorage.PlayerGuis
local PlayerGui = Player.PlayerGui
local GameStarted = ReplicatedStorage.ClientEvents.GameStarted

local Cover = PlayerGuis.Cover:Clone()
Cover.Parent = PlayerGui

local connection = Player.CharacterAdded:Connect(function()
    if not PlayerGui:FindFirstChild("Cover") then
        Cover = PlayerGuis.Cover:Clone()
        Cover.Parent = PlayerGui
    end
end)

GameStarted.Event:Wait()
connection:Disconnect()
Cover:Destroy()