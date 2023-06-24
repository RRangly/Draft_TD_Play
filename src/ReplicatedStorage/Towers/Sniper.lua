local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local ClientLoad = ReplicatedStorage.ClientLoad
local Animation = ReplicatedStorage.Animations.MinigunShot

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
    }
}

function Sniper.update(data, towerIndex, deltaTime)
    local towerManager = data.Towers
    local mobManager = data.Mobs
    local waypoints = data.Map.WayPoints
    local player = data.Player
    local tower = towerManager.Towers[towerIndex]
    local stats = Sniper.Stats[tower.Level]
    if towerManager:attackAvailable(towerIndex, mobManager.Mobs) then
        local target
        if tower.Target == "Closest" then
            target = towerManager:findClosestMob(towerIndex, mobManager.Mobs)
        elseif tower.Target == "Lowest Health" then
            target = towerManager:findLowestHealth(towerIndex, mobManager.Mobs)
        elseif tower.Target == "First" then
            target = towerManager:findFirstMob(towerIndex, mobManager.Mobs, waypoints)
        end
        local model = tower.Model
        local mobPart = mobManager.Mobs[target].Object.PrimaryPart
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(mobPart.Position.X, model:GetPivot().Position.Y, mobPart.Position.Z)))
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            towerManager:playSound(player, "GunShot")
            mobManager:TakeDamage(data.Coins, target, stats.Damage)
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end

return Sniper