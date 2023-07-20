local Workspace = game:GetService("Workspace")
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

function GameMechanics.mobMovementPrediction(mob, waypoints, distance)
    local mobPart = mob.Object.PrimaryPart

    local mobVector = mob.Position
    local mobWaypoint = mob.Waypoint

    local i = mobWaypoint
    local mobPlace
    repeat
        local waypoint = waypoints[i]
        if not waypoint then
            return {WayPoint = i; Position = waypoints[i - 1]}
        end
        local waypointDistance = (waypoint - mobVector).Magnitude
        if waypointDistance >= distance then
            mobPlace = mobVector + (waypoint - mobVector).Unit * distance
            distance = 0
        else
            mobVector = waypoint
            distance -= waypointDistance
            i += 1
        end
    until distance <= 0
    return {WayPoint = i; Position = Vector3.new(mobPlace.X, mobPart.Position.Y, mobPlace.Z);}
end

return GameMechanics