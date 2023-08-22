local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Data
if RunService:IsServer() then
    Data = require(ServerScriptService.Modules.Data)
end

local Soldier = {
    Name = "Soldier";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 0.5;
            AttackRange = 20;
            Damage = 2;
            Cost = 100;
        },
        {
            LevelName = "Faster Reload";
            AttackSpeed = 0.4;
            AttackRange = 24;
            Damage = 3;
            Cost = 200;
        },
        {
            LevelName = "Better Bullets";
            AttackSpeed = 0.4;
            AttackRange = 28;
            Damage = 4;
            Cost = 250;
        },
        {
            LevelName = "AK-47";
            AttackSpeed = 0.3;
            AttackRange = 30;
            Damage = 5;
            Cost = 350;
        },
        {
            LevelName = "Trained Soldier";
            AttackSpeed = 0.2;
            AttackRange = 36;
            Damage = 7;
            Cost = 600;
        }
    };
    Placement = {
        Area = 1;
        Type = "Plain";
        Height = 4.45;
    }
}


function Soldier.update(pIndex, towerIndex, deltaTime)
    local data = Data[pIndex]
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Soldier.Stats[tower.Level]
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

return Soldier