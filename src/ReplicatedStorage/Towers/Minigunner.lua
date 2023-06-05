local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ClientLoad = ReplicatedStorage.ClientLoad
local Animation = ReplicatedStorage.Animations.MinigunShot

local Minigunner = {
    Name = "Minigunner";
    Stats = {
        {
            LevelName = "Basic";
            PreAttack = 2;
            AttackSpeed = 0.2;
            AttackRange = 20;
            Damage = 5;
            Cost = 250;
        },
        {
            LevelName = "Better Bullets";
            PreAttack = 2;
            AttackSpeed = 0.2;
            AttackRange = 20;
            Damage = 10;
            Cost = 500;
        },
        {
            LevelName = "Farther Range";
            PreAttack = 2;
            AttackSpeed = 0.2;
            AttackRange = 24;
            Damage = 12;
            Cost = 800;
        },
        {
            LevelName = "Faster Shooting";
            PreAttack = 2;
            AttackSpeed = 0.12;
            AttackRange = 27;
            Damage = 12;
            Cost = 1000;
        },
        {
            LevelName = "Superiority";
            PreAttack = 1;
            AttackSpeed = 0.1;
            AttackRange = 35;
            Damage = 15;
            Cost = 1500;
        },
    };
    Placement = {
        Area = 1;
        Type = "Plain";
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

function Minigunner.update(player, towerManager, towerIndex, mobs, waypoints, deltaTime)
    local tower = towerManager.Towers[towerIndex]
    local stats = Minigunner.Stats[tower.Level]
    if towerManager:attackAvailable(towerIndex, mobs.Mobs) then
        local target
        if tower.Target == "Closest" then
            target = towerManager:findClosestMob(towerIndex, mobs.Mobs)
        elseif tower.Target == "Lowest Health" then
            target = towerManager:findLowestHealth(towerIndex, mobs.Mobs)
        elseif tower.Target == "First" then
            target = towerManager:findFirstMob(towerIndex, mobs.Mobs, waypoints)
        end
        local model = tower.Model
        local mobPart = mobs.Mobs[target].Object.PrimaryPart
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(mobPart.Position.X, model:GetPivot().Position.Y, mobPart.Position.Z)))
        tower.PreAttackCD += deltaTime
        if not (tower.PreAttackCD >= stats.PreAttack) then
            tower.AttackCD = 0;
            return
        end
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            towerManager:playSound(player, "MinigunShot")
            towerManager:playAnimation(player, towerIndex, mobPart.Position)
            mobs:TakeDamage(target, stats.Damage)
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end


return Minigunner