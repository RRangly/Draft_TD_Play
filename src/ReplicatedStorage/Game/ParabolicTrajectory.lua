local ParabolcTrajectory = {}

function ParabolcTrajectory.create(p0: Vector3, p1: Vector3)
    local points = {}
    local stepSize = 1 / 19
    local heightFactor = 0.35
    local ySub = ((-10 * heightFactor) ^ 2)
    for i = 1, 19 do
        local t = i * stepSize
        local x = p0.X + (p1.X - p0.X) * t
        local y = p0.Y + -(((i - 10) * heightFactor) ^ 2) + ySub
        local z = p0.Z + (p1.Z - p0.Z) * t
        table.insert(points, Vector3.new(x, y, z))
    end
    return points
end

return ParabolcTrajectory