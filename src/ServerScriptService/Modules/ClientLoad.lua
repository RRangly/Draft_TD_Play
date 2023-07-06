local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientLoadFol = ReplicatedStorage.ClientLoad

local ClientLoad = {}
ClientLoad.__index = ClientLoad

function ClientLoad:playSound(soundName)
    local instance = Instance.new("StringValue", self.Folder)
    instance.Name = "PlaySound"
    instance.Value = soundName
    task.spawn(function()
        task.wait(0.2)
        instance:Destroy()
    end)
end

function ClientLoad:playAnimation(towerIndex, targetPos)
    local instance = Instance.new("IntValue", self.Folder)
    instance.Name = "PlayAnim"
    instance.Value = towerIndex
    instance:SetAttribute("TargetPos", targetPos)
    task.spawn(function()
        task.wait(0.2)
        instance:Destroy()
    end)
    instance:Destroy()
end

function ClientLoad:playParticle(towerIndex, target)
    local instance = Instance.new("StringValue", self.Folder)
    instance.Name = "PlayParticle"
    instance.Value = towerIndex
    instance:SetAttribute("Target", target)
    task.spawn(function()
        task.wait(0.2)
        instance:Destroy()
    end)
    instance:Destroy()
end

function ClientLoad.new(player)
    local folder = Instance.new("Folder", ClientLoadFol)
    folder.Name = player.UserId
    local clientLoad = {
        Player = player;
        Folder = folder
    }
    setmetatable(clientLoad, ClientLoad)
    return clientLoad
end
return ClientLoad