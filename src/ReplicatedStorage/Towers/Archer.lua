local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Archer = {
    Name = "Archer";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 0.5;
            AttackRange = 25;
            Damage = 2;
            ArrowSpeed = 28;
            Cost = 400;
        },
        {
            LevelName = "Better Arrows";
            AttackSpeed = 0.5;
            AttackRange = 28;
            Damage = 3;
            ArrowSpeed = 32;
            Cost = 400;
        },
        {
            LevelName = "Improved Archery";
            AttackSpeed = 0.4;
            AttackRange = 36;
            Damage = 4;
            ArrowSpeed = 40;
            Cost = 400;
        },
        {
            LevelName = "Optimized Quiver";
            AttackSpeed = 0.3;
            AttackRange = 25;
            Damage = 4;
            ArrowSpeed = 40;
            Cost = 400;
        },
        {
            LevelName = "Professional";
            AttackSpeed = 0.5;
            AttackRange = 25;
            Damage = 5;
            ArrowSpeed = 48;
            Cost = 400;
        }
    };
    Placement = {
        Area = 1;
        Type = "Plain";
    }
}


function Archer.update(data, towerIndex, deltaTime)
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local waypoints = data.MapManager.WayPoints
    local player = data.Player
    local tower = towerManager.Towers[towerIndex]
    local stats = Archer.Stats[tower.Level]
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
            local arrow = Instance.new("Part", Workspace)
            arrow.Size = Vector3.new(2, 2, 2)
            arrow.CFrame = CFrame.new(model:GetPivot().Position, mobPart.Position)
            arrow.CanCollide = false
            local direction = (mobPart.Position - arrow.Position).Unit
            local tweenTime = stats.AttackRange / stats.ArrowSpeed
            local arrowTween = TweenService:Create(arrow, TweenInfo.new(tweenTime), {CFrame = arrow.CFrame + direction * stats.AttackRange})
            arrowTween:Play()
            local alreadyHit = {}
            arrow.Touched:Connect(function(otherPart)
                if otherPart.CollisionGroup == "GameAssets" then
                    for _, i in alreadyHit do
                        if not mobManager.Mobs[i] then
                            table.remove(alreadyHit, i)
                            continue
                        end
                        if otherPart:IsDescendantOf(mobManager.Mobs[i].Object) then
                            return
                        end
                    end
                    for i, mob in mobManager.Mobs do
                        if otherPart:IsDescendantOf(mob.Object) then
                            table.insert(alreadyHit, i)
                            mobManager:TakeDamage(data.CoinManager, i, stats.Damage)
                        end
                    end
                end
            end)
            arrowTween.Completed:Wait()
            arrow:Destroy()
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end

return Archer