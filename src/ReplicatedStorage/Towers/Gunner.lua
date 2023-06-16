local Gunner = {
    Name = "Gunner";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 1;
            AttackRange = 20;
            Damage = 2;
            Cost = 80;
        },
        {
            LevelName = "Faster Reload";
            AttackSpeed = 0.7;
            AttackRange = 20;
            Damage = 2;
            Cost = 120;
        },
        {
            LevelName = "Better Bullets";
            AttackSpeed = 0.6;
            AttackRange = 24;
            Damage = 3;
            Cost = 250;
        },
        {
            LevelName = "Glock 17";
            AttackSpeed = 0.6;
            AttackRange = 30;
            Damage = 5;
            Cost = 500;
        },
        {
            LevelName = "Trained Gunner";
            AttackSpeed = 0.4;
            AttackRange = 45;
            Damage = 5;
            Cost = 900;
        }
    };
    Placement = {
        Area = 1;
        Type = "Plain";
    }
}


function Gunner.update(data, towerIndex, deltaTime)
    local towerManager = data.Towers
    local mobManager = data.Mobs
    local waypoints = data.Map.WayPoints
    local player = data.Player
    local tower = towerManager.Towers[towerIndex]
    local stats = Gunner.Stats[tower.Level]
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

return Gunner