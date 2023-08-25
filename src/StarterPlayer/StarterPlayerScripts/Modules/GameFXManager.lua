local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Towers = ReplicatedStorage.Towers
local SoundFX = ReplicatedStorage.SoundFX

local GameFX = {}

function GameFX.executeLoad(data, instance)
    local loadType = instance.Name
    if loadType == "PlaySound" then
        local sound = SoundFX:FindFirstChild(instance.Value)
        sound:Play()
    elseif loadType == "PlayAnim" then
        local towerIndex = instance.Value
        local towerInfo = data.Towers.Towers[towerIndex]
        local tower = require(Towers:FindFirstChild(towerInfo.Name))
        tower.playAnim(towerInfo.Model, instance:GetAttribute("TargetPos"))
    end
    instance:Destroy()
end

return GameFX