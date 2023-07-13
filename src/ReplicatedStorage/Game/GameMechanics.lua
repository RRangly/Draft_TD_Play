local GameMechanics = {}

function GameMechanics.create(p0: Vector3, p1: Vector3)
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

function GameMechanics.mobMovementPrediction(data, mobIndex, distance)
    local mobManager = data.MobManager
    local wayPoints = data.MapManager.WayPoints
    local mob = mobManager.Mobs[mobIndex]
    local mobPart = mob.Object.PrimaryPart

    local mobVector = Vector3.new(mobPart.Position.X, 0, mobPart.Position.Z)
    local mobWaypoint = mob.Waypoint

    local i = mobWaypoint
    local mobPlace
    repeat
        local waypoint = wayPoints[i]
        if not waypoint then
            return waypoint[i - 1]
        end
        local waypointVector = Vector3.new(waypoint.X, 0, waypoint.Z)
        local waypointDistance = (waypointVector - mobVector).Magnitude
        if waypointDistance >= distance then
            mobPlace = mobVector + (waypointVector - mobVector).Unit * distance
            distance = 0
        else
            distance -= waypointDistance
            i += 1
        end
    until distance <= 0
    return Vector3.new(mobPlace.X, mobPart.Position.Y, mobPlace.Z)
end

return GameMechanics