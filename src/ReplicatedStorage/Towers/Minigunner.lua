local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

function Minigunner.playAnim(model)
    local animController = model.AnimationController
    local animator = animController.Animator
    local loading = animator:LoadAnimation(Animation)
    loading:Play()

    --[[
    local minigun = model.Minigun
    local barrel = minigun.Barrel
    local ori = barrel.Orientation
    barrel.Orientation = Vector3.new(ori.X, ori.Y, ori.Z + 30)
    ]]
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
            mobs:TakeDamage(target, stats.Damage)
            towerManager:playSound(player, "MinigunShot")
            towerManager:playAnimation(player, towerIndex)
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end


return Minigunner