local Soldier = {
    Name = "Soldier";
    Stats = {
        {
            LevelName = "Basic";
            AttackSpeed = 0.5;
            AttackRange = 20;
            Damage = 2;
            Cost = 150;
        },
        {
            LevelName = "Faster Reload";
            AttackSpeed = 0.4;
            AttackRange = 20;
            Damage = 2;
            Cost = 80;
        },
        {
            LevelName = "Better Bullets";
            AttackSpeed = 04;
            AttackRange = 24;
            Damage = 3;
            Cost = 250;
        },
        {
            LevelName = "Glock 17";
            AttackSpeed = 0.4;
            AttackRange = 30;
            Damage = 5;
            Cost = 500;
        },
        {
            LevelName = "Trained Gunner";
            AttackSpeed = 0.3;
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


function Soldier.update(data, towerIndex, deltaTime)
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local waypoints = data.MapManager.WayPoints
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Soldier.Stats[tower.Level]
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
            clientLoad:playSound("GunShot")
            mobManager:TakeDamage(data.CoinManager, target, stats.Damage)
        end
    else
        tower.AttackCD = 0
        tower.PreAttackCD = 0
    end
end

return Soldier