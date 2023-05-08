local ServerStorage = game:GetService("ServerStorage")

local DraftEnd = ServerStorage.ServerEvents.DraftEnd
local Draft = require(script.Parent.Draft)
local MobManager = require(script.Parent.MobManager)
local MapManager = require(script.Parent.MapManager)
local TowerManager = require(script.Parent.TowerManager)

local Game = {}

function Game.start(player1, player2)
    Draft.startDraft(player1, player2)
    DraftEnd.Event:Wait()
    wait(2)
    MapManager.load("Basic")
    wait(2)
    TowerManager.place(player1, "Minigunner", Vector3.new(12.5, 5, 40))
    wait(2)
    MobManager.Spawn("Zombie")
end
return Game