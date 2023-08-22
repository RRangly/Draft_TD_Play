local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Data
if RunService:IsServer() then
    Data = require(ServerScriptService.Modules.Data)
end

local Archer = {
    Name = "Archer";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 0.5;
            AttackRange = 25;
            Damage = 2;
            ArrowSpeed = 0.5;
            Cost = 400;
        },
        {
            LevelName = "Better Arrows";
            AttackSpeed = 0.5;
            AttackRange = 28;
            Damage = 3;
            ArrowSpeed = 0.4;
            Cost = 400;
        },
        {
            LevelName = "Improved Archery";
            AttackSpeed = 0.4;
            AttackRange = 36;
            Damage = 4;
            ArrowSpeed = 0.4;
            Cost = 400;
        },
        {
            LevelName = "Optimized Quiver";
            AttackSpeed = 0.3;
            AttackRange = 25;
            Damage = 4;
            ArrowSpeed = 0.3;
            Cost = 400;
        },
        {
            LevelName = "Professional";
            AttackSpeed = 0.5;
            AttackRange = 25;
            Damage = 5;
            ArrowSpeed = 0.2;
            Cost = 400;
        }
    };
    Placement = {
        Area = 1;
        Type = "Plain";
        Height = 2.3;
    }
}


function Archer.update(pIndex, towerIndex, deltaTime)
    local data = Data[pIndex]
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Archer.Stats[tower.Level]
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
            local arrow = Instance.new("Part", Workspace)
            arrow.Size = Vector3.new(2, 2, 2)
            arrow.CFrame = CFrame.new(model:GetPivot().Position, mobPart.Position)
            arrow.CanCollide = false
            arrow.Anchored = true
            local direction = (mobPart.Position - arrow.Position).Unit
            for i = 1, stats.AttackRange, 1 do
                arrow.Position = arrow.Position + direction * i
                task.wait(stats.ArrowSpeed / stats.AttackRange)
            end
            --[[
            local arrowTween = TweenService:Create(arrow, TweenInfo.new(tweenTime), {Position = arrow.Position + direction * stats.AttackRange})
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
            ]]
            arrow:Destroy()
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
    return {}
end

return Archer