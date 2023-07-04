local WaveManager = {}
WaveManager.__index = WaveManager

function WaveManager:startWave(mobManager)
    local GenerationFunctions = {
        Default = mobManager.generateDefaultMob;
        Speed = mobManager.generateSpeedMob;
        Tank = mobManager.generateTankMob;
        Special = mobManager.generateSpecialMob;
    }
    self.CurrentWave += 1
    local difficultyWeight = 1.095^self.CurrentWave * 100
    local waveType = math.random(1, 10)
    local mobsDistribution
    local totalMob
    if waveType < 3 then
        totalMob = math.floor(difficultyWeight / math.random(41, 46))
        mobsDistribution = {
            Default = math.ceil(totalMob * 0.2);
            Tank = math.ceil(totalMob * 0.55);
            Speed = math.ceil(totalMob * 0.1);
            Special = math.ceil(totalMob * 0.15);
        }
    elseif waveType < 5 then
        totalMob = math.floor(difficultyWeight / math.random(26, 33))
        mobsDistribution = {
            Default = math.ceil(totalMob * 0.2);
            Tank = math.ceil(totalMob * 0.15);
            Speed = math.ceil(totalMob * 0.5);
            Special = math.ceil(totalMob * 0.15);
        }
    else
        totalMob = math.floor(difficultyWeight / math.random(22, 28))
        mobsDistribution = {
            Default = math.ceil(totalMob * 0.6);
            Tank = math.ceil(totalMob * 0.15);
            Speed = math.ceil(totalMob * 0.1);
            Special = math.ceil(totalMob * 0.15);
        }
    end
    local mobWeight = math.floor(difficultyWeight / 35)
    local toSpawn = {}
    for mobType, mobAmount in pairs(mobsDistribution) do
        for _ = 1, mobAmount, 1 do
            local mob = GenerationFunctions[mobType](mobWeight)
            table.insert(toSpawn, math.random(1, #toSpawn + 1), mob)
        end
    end
    mobManager:spawnWave(toSpawn)
end

function WaveManager.startGame()
    local wave = {
        CurrentWave = 0;
    }
    setmetatable(wave, WaveManager)
    return wave
end

return WaveManager