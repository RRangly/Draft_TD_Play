local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local ClientLoad = ReplicatedStorage.ClientLoad
local Animation = ReplicatedStorage.Animations.MinigunShot

local Minigunner = {
    Name = "Minigunner";
    Stats = {
        {
            LevelName = "Basic";
            PreAttack = 1;
            AttackSpeed = 0.2;
            AttackRange = 24;
            Damage = 1;
            Cost = 250;
        },
        {
            LevelName = "Better Bullets";
            PreAttack = 1;
            AttackSpeed = 0.2;
            AttackRange = 26;
            Damage = 2;
            Cost = 500;
        },
        {
            LevelName = "Farther Range";
            PreAttack = 2;
            AttackSpeed = 0.2;
            AttackRange = 30;
            Damage = 1;
            Cost = 800;
        },
        {
            LevelName = "Faster Shooting";
            PreAttack = 1;
            AttackSpeed = 0.12;
            AttackRange = 35;
            Damage = 5;
            Cost = 1000;
        },
        {
            LevelName = "Superiority";
            PreAttack = 1;
            AttackSpeed = 0.1;
            AttackRange = 45;
            Damage = 12;
            Cost = 1500;
        },
    };
    Placement = {
        Area = 1;
        Type = "Plain";
        Height = 3.01
    }
}

function Minigunner.playAnim(model, targetPos)
    local animController = model.AnimationController
    local animator = animController.Animator
    local loading = animator:LoadAnimation(Animation)
    loading:Play()

    local minigun = model.Minigun
    local barrel = minigun.Barrel
    local firePoint = barrel.FirePoint

    local ori = barrel.Orientation
    barrel.Orientation = Vector3.new(ori.X, ori.Y, ori.Z + 30)

    print("Affecting")
    local effect = Instance.new("Folder", barrel)
    local bulletTrail = barrel.BulletTrail:Clone()
    bulletTrail.Parent = effect
    local trailPart = Instance.new("Part", effect)
    trailPart.Size = Vector3.new(1, 1, 1)
    --trailPart.Transparency = 1
    trailPart.Anchored = true
    trailPart.CFrame = CFrame.new(firePoint.Position, targetPos)
    trailPart.CanCollide = false
    --trailPart.CanQuery = false
    local trailStart = Instance.new("Attachment", trailPart)
    local trailEnd = Instance.new("Attachment", trailPart)
    trailStart.CFrame = CFrame.new(0, 0, -1.5)
    bulletTrail.Enabled = true
    bulletTrail.Attachment0 = trailStart
    bulletTrail.Attachment1 = trailEnd
    local tween = TweenService:Create(trailPart, TweenInfo.new(0.1), {Position = targetPos})
    tween:Play()
    tween.Completed:Wait()
    effect:Destroy()
end

function Minigunner.update(data, towerIndex, deltaTime)
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local waypoints = data.MapManager.WayPoints
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Minigunner.Stats[tower.Level]
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
        tower.PreAttackCD += deltaTime
        if not (tower.PreAttackCD >= stats.PreAttack) then
            tower.AttackCD = 0;
            return
        end
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            clientLoad:playSound("MinigunShot")
            clientLoad:playAnimation(towerIndex, mobPart.Position)
            mobManager:TakeDamage(data.CoinManager, target, stats.Damage)
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end

return Minigunner