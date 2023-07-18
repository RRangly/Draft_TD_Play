local Scout = {
    Name = "Scout";
    Stats = {
        {
            LevelName = "Scout";
            AttackSpeed = 0.8;
            AttackRange = 15;
            Damage = 1;
            Cost = 50;
        },
        {
            LevelName = "Training";
            AttackSpeed = 0.7;
            AttackRange = 20;
            Damage = 2;
            Cost = 100;
        },
        {
            LevelName = "Reload Skills";
            AttackSpeed = 0.5;
            AttackRange = 20;
            Damage = 2;
            Cost = 220;
        },
        {
            LevelName = "CIA";
            AttackSpeed = 0.4;
            AttackRange = 25;
            Damage = 2;
            Cost = 400;
        },
        {
            LevelName = "KGB";
            AttackSpeed = 0.4;
            AttackRange = 20;
            Damage = 4;
            Cost = 550;
        },
    };
    Placement = {
        Area = 1;
        Type = "Plain";
        Height = 2.95;
    }
}


function Scout.update(data, towerIndex, deltaTime)
    local towerManager = data.TowerManager
    local mobManager = data.MobManager
    local waypoints = data.MapManager.WayPoints
    local clientLoad = data.ClientLoad
    local tower = towerManager.Towers[towerIndex]
    local stats = Scout.Stats[tower.Level]
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

return Scout