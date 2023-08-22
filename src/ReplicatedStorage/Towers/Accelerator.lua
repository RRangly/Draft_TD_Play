local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Data
if RunService:IsServer() then
    Data = require(ServerScriptService.Modules.Data)
end

local Accelerator = {
    Name = "Accelerator";
    Stats = {
        {
            LevelName = "Basic";
            PreAttack = 1.5;
            AttackSpeed = 0.2;
            AttackRange = 24;
            Damage = 2;
            Cost = 650;
        },
        {
            LevelName = "Better Charge";
            PreAttack = 1.5;
            AttackSpeed = 0.2;
            AttackRange = 26;
            Damage = 4;
            Cost = 400;
        },
        {
            LevelName = "Farther Range";
            PreAttack = 1;
            AttackSpeed = 0.18;
            AttackRange = 34;
            Damage = 5;
            Cost = 900;
        },
        {
            LevelName = "Faster Shooting";
            PreAttack = 1;
            AttackSpeed = 0.12;
            AttackRange = 38;
            Damage = 8;
            Cost = 1400;
        },
        {
            LevelName = "Superiority";
            PreAttack = 0.8;
            AttackSpeed = 0.1;
            AttackRange = 45;
            Damage = 12;
            Cost = 2500;
        },
    };
    Placement = {
        Area = 1;
        Type = "Plain";
        Height = 2.9;
    }
}

function Accelerator.playAnim(model, animName, animLength)
    local animator = model.AnimationController.Animator
    animator = Instance.new("Animator")
    for _, animation in pairs(animator:GetPlayingAnimationTracks()) do
        animation:Stop(0.5)
    end
    animator:LoadAnimation()
end

function Accelerator.update(playerIndex, towerIndex, deltaTime)
    local data = Data[playerIndex]
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Accelerator.Stats[tower.Level]
    if towerManager:attackAvailable(towerIndex) then
        local target
        if tower.Target == "Closest" then
            target = towerManager:findClosestMob(towerIndex)
        elseif tower.Target == "Lowest Health" then
            target = towerManager:findLowestHealth(towerIndex, mobManager.Mobs)
        elseif tower.Target == "First" then
            target = towerManager:findFirstMob(towerIndex)
        end
        local model = tower.Model
        local mobPart = mobManager.Mobs[target].Object.PrimaryPart
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(mobPart.Position.X, model:GetPivot().Position.Y, mobPart.Position.Z)))
        tower.PreAttackCD += deltaTime
        if not (tower.PreAttackCD >= stats.PreAttack) then
            tower.AttackCD = 0;
        end
        tower.AttackCD += deltaTime
        if tower.AttackCD >= stats.AttackSpeed then
            tower.AttackCD = 0
            clientLoad:playSound("MinigunShot")
            clientLoad:playAnimation(towerIndex, mobPart.Position)
            return {mobManager:takeDamage(target, stats.Damage)}
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
    return {}
end

return Accelerator