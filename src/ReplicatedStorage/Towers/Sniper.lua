local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Data
if RunService:IsServer() then
    Data = require(ServerScriptService.Modules.Data)
end

local Sniper = {
    Name = "Sniper";
    Stats = {
        {
            LevelName = "Basic";
            PreAttack = 1;
            AttackSpeed = 2.5;
            AttackRange = 46;
            Damage = 12;
            Cost = 250;
        },
        {
            LevelName = "Better Bullets";
            PreAttack = 1;
            AttackSpeed = 2.5;
            AttackRange = 46;
            Damage = 18;
            Cost = 500;
        },
        {
            LevelName = "Farther Range";
            PreAttack = 2;
            AttackSpeed = 2.5;
            AttackRange = 56;
            Damage = 18;
            Cost = 800;
        },
        {
            LevelName = "Faster Shooting";
            PreAttack = 1;
            AttackSpeed = 2;
            AttackRange = 56;
            Damage = 20;
            Cost = 1000;
        },
        {
            LevelName = "Superiority";
            PreAttack = 1;
            AttackSpeed = 1.6;
            AttackRange = 70;
            Damage = 30;
            Cost = 1500;
        },
    };
    Placement = {
        Area = 1;
        Type = "Cliff";
        Height = 1.9;
    }
}

function Sniper.update(pIndex, towerIndex, deltaTime)
    local data = Data[pIndex]
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Sniper.Stats[tower.Level]
    if towerManager:attackAvailable(towerIndex) then
        local target
        if tower.Target == "Closest" then
            target = towerManager:findClosestMob(towerIndex)
        elseif tower.Target == "Lowest Health" then
            target = towerManager:findLowestHealth(towerIndex)
        elseif tower.Target == "First" then
            target = towerManager:findFirstMob(towerIndex)
        end
        local model = tower.Model
        local mobPart = mobManager.Mobs[target].Object.PrimaryPart
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(mobPart.Position.X, model:GetPivot().Position.Y, mobPart.Position.Z)))
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            clientLoad:playSound("GunShot")
            return {mobManager:takeDamage(target, stats.Damage)}
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
    return {}
end

return Sniper