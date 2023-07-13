local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameMechanics = require(ReplicatedStorage.Game.GameMechanics)
local ShellSpeed = 1

local Mortar = {
    Name = "Mortar";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 3;
            AttackRange = 34;
            Damage = 4;
            ExploRad = 6;
            Cost = 850;
        },
        {
            LevelName = "Better Bombs";
            AttackSpeed = 3;
            AttackRange = 36;
            Damage = 5;
            ExploRad = 8;
            Cost = 1100;
        },
        {
            LevelName = "Improved Reloading";
            AttackSpeed = 2.6;
            AttackRange = 38;
            Damage = 6;
            ExploRad = 8;
            Cost = 1300;
        },
        {
            LevelName = "Optimized Mortar";
            AttackSpeed = 2.2;
            AttackRange = 42;
            Damage = 6;
            ExploRad = 10;
            Cost = 1600;
        },
        {
            LevelName = "Professional";
            AttackSpeed = 2;
            AttackRange = 48;
            Damage = 10;
            ExploRad = 12;
            Cost = 2800;
        }
    };
    Placement = {
        Area = 1;
        Type = "Cliff";
    }
}

function Mortar.playAnim(model, targetPos)
    local points = GameMechanics.create(model:GetPivot().Position, targetPos)
    local tilt = model.Tilt
    local cannon = tilt.Cannon
    cannon.Anchored = false

    local relativePos = points[10] - tilt.Position
    local x = math.sqrt(relativePos.X^2 + relativePos.Z^2)
    local y = relativePos.Y
    local angle = math.deg(math.atan2(y, x))
    tilt.CFrame *= CFrame.Angles(-math.rad(tilt.Orientation.X - (angle - 90)), 0, 0)

    local ammoClone = model.Ammo:Clone()
    ammoClone.Parent = Workspace
    ammoClone.Name = "Clone"
    ammoClone.Transparency = 0
    ammoClone.CanCollide = false
    for _, point in pairs(points) do
        ammoClone.CFrame = CFrame.new(ammoClone.Position, point)
        task.wait(ShellSpeed / 19)
        ammoClone.CFrame = CFrame.new(point)
    end
    ammoClone:Destroy()
end

function Mortar.update(data, towerIndex, deltaTime)
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local waypoints = data.MapManager.WayPoints
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Mortar.Stats[tower.Level]
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
        local targetPos = GameMechanics.mobMovementPrediction(data, target, mobManager.Mobs[target].Object.Humanoid.WalkSpeed * ShellSpeed)
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(targetPos.X, model:GetPivot().Position.Y, targetPos.Z)))
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            clientLoad:playSound("GunShot")
            Mortar.playAnim(model, targetPos)
            local exp = Instance.new("Part", Workspace)
            exp.Shape = Enum.PartType.Ball
            exp.Size = Vector3.new(stats.ExploRad, stats.ExploRad, stats.ExploRad)
            exp.CanCollide = false
            exp.Position = targetPos
            exp.Transparency = 0
            exp.Anchored = true
            for i, mob in pairs(mobManager.Mobs) do
                local mobPos = mob.Object:GetPivot().Position
                if (mobPos - targetPos).Magnitude < stats.ExploRad then
                    mobManager:TakeDamage(data.CoinManager, i, stats.Damage)
                end
            end
            wait(0.5)
            exp:Destroy()
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end

return Mortar