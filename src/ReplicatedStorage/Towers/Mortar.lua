local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ParabolcTrajectory = require(ReplicatedStorage.Game.ParabolicTrajectory)

local Mortar = {
    Name = "Mortar";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 0.5;
            AttackRange = 34;
            Damage = 2;
            ExploRad = 6;
            Cost = 400;
        },
        {
            LevelName = "Better Bombs";
            AttackSpeed = 0.5;
            AttackRange = 36;
            Damage = 3;
            ExploRad = 8;
            Cost = 400;
        },
        {
            LevelName = "Improved Reloading";
            AttackSpeed = 0.4;
            AttackRange = 38;
            Damage = 4;
            ExploRad = 8;
            Cost = 400;
        },
        {
            LevelName = "Optimized Mortar";
            AttackSpeed = 0.3;
            AttackRange = 42;
            Damage = 4;
            ExploRad = 10;
            Cost = 400;
        },
        {
            LevelName = "Professional";
            AttackSpeed = 0.3;
            AttackRange = 48;
            Damage = 5;
            ExploRad = 12;
            Cost = 400;
        }
    };
    Placement = {
        Area = 1;
        Type = "Cliff";
    }
}

function Mortar.playAnim(model, targetPos)
    local points = ParabolcTrajectory.create(model:GetPivot().Position, targetPos)
    local parts = {}
    for i, point in pairs(points) do
        parts[i] = Instance.new("Part", Workspace)
        parts[i].Size = Vector3.new(0.5, 0.5, 0.5)
        parts[i].Position = point
        parts[i].Anchored = true
        parts[i].CanCollide = false
    end
    local tilt = model.Tilt
    local cannon = tilt.Cannon
    cannon.Anchored = false
    wait(0.5)
    for _, part in parts do
        part:Destroy()
    end
    local relativePos = points[10] - tilt.Position
    local x = math.sqrt(relativePos.X^2 + relativePos.Z^2)
    local y = relativePos.Y
    local angle = math.deg(math.atan2(y, x))
    print("Poses", points[1], "|", tilt.Position)
    print("Angle", relativePos, angle)
    tilt.CFrame *= CFrame.Angles(-math.rad(tilt.Orientation.X - (angle - 90)), 0, 0)
    local ammoClone = model.Ammo:Clone()
    ammoClone.Parent = Workspace
    ammoClone.Name = "Clone"
    ammoClone.Transparency = 0
    ammoClone.CanCollide = false
    for _, point in pairs(points) do
        ammoClone.CFrame = CFrame.new(ammoClone.Position, point)
        local tween  = TweenService:Create(ammoClone, TweenInfo.new(0.2 / 20), {Position = point})
        tween:Play()
        tween.Completed:Wait()
    end
    ammoClone:Destroy()
end

function Mortar.update(data, towerIndex, deltaTime)
    local towerManager = data.Towers
    local mobManager = data.Mobs
    local waypoints = data.Map.WayPoints
    local player = data.Player
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
        local mobPart = mobManager.Mobs[target].Object.PrimaryPart
        local targetPos = mobPart.Position
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(targetPos.X, model:GetPivot().Position.Y, targetPos.Z)))
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            towerManager:playSound(player, "GunShot")
            Mortar.playAnim(model, targetPos)
            local exp = Instance.new("Part", Workspace)
            exp.Shape = Enum.PartType.Ball
            exp.Size = Vector3.new(stats.ExploRad, stats.ExploRad, stats.ExploRad)
            exp.CanCollide = false
            exp.Position = targetPos
            exp.Transparency = 0.5
            for i, mob in pairs(mobManager.Mobs) do
                local mobPos = mob.Object:GetPivot().Position
                if (mobPos - targetPos).Magnitude < stats.ExploRad then
                    mobManager:TakeDamage(data.Coins, i, stats.Damage)
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