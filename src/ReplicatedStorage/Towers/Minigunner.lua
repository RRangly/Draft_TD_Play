local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientLoad = ReplicatedStorage.ClientLoad

local Minigunner = {
    Name = "Minigunner";
    Stats = {
        PreAttack = 3;
        AttackSpeed = 0.2;
        AttackRange = 20;
        Damage = 5;
        Cost = 250;
    };
    Placement = {
        Area = 1;
        Type = "Plain";
    }
}

function Minigunner.playAnim(model)
    local minigun = model.Minigun
    local barrel = minigun.Barrel
    local ori = barrel.Orientation
    barrel.Orientation = Vector3.new(ori.X, ori.Y, ori.Z + 30)
end

function Minigunner.update(player, towerManager, towerIndex, mobs, deltaTime)
    local tower = towerManager.Towers[towerIndex]
    if towerManager:attackAvailable(towerIndex, mobs.Mobs) then
        local model = tower.Model
        local mobPart = mobs.Mobs[towerManager:findClosestMob(towerIndex, mobs.Mobs)].Object.PrimaryPart
        model:PivotTo(CFrame.new(model:GetPivot().Position, Vector3.new(mobPart.Position.X, model:GetPivot().Position.Y, mobPart.Position.Z)))
        tower.PreAttackCD += deltaTime
        if not (tower.PreAttackCD >= Minigunner.Stats.PreAttack) then
            tower.AttackCD = 0;
            return
        end
        tower.AttackCD += deltaTime
        if tower.AttackCD >= Minigunner.Stats.AttackSpeed then
            tower.AttackCD = 0
            mobs:TakeDamage(towerManager:findClosestMob(towerIndex, mobs.Mobs), Minigunner.Stats.Damage)
            towerManager:playSound("MinigunShot")
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end


return Minigunner