local ServerStorage = game:GetService("ServerStorage")

local DraftEnd = ServerStorage.ServerEvents.DraftEnd
local Draft = require(script.Parent.Draft)
local MobManager = require(script.Parent.MobManager)
local MapManager = require(script.Parent.MapManager)
local TowerManager = require(script.Parent.TowerManager)

local Game = {}

local PlayerDatas = {}
function Game.start(player1, player2)
    local draft = Draft.startDraft(player1, player2)
    PlayerDatas[1].Towers = draft[1]
    PlayerDatas[2].Towers = draft[2]
    DraftEnd.Event:Wait()
    wait(2)
    MapManager.load("Basic")
    wait(2)
    TowerManager.place(player1, "Minigunner", Vector3.new(12.5, 5, 40))
    wait(2)
    MobManager.startGame()
end

function Game.singleTest(player)
    wait(2)
    MapManager.load("Basic")
    wait(2)
    TowerManager.place(player, "Minigunner", Vector3.new(12.5, 5, 40))
    wait(2)
    MobManager.startGame()
end
return Game