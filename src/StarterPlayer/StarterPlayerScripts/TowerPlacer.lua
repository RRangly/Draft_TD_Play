local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Towers = ReplicatedStorage.Towers
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local TowerPlacer = {}

function TowerPlacer.activate(
    
)
return TowerPlacer