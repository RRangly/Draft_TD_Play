local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HealthDisplayGui = ReplicatedStorage.ClientAssets:FindFirstChild("HealthDisplayGui")
local Player = Players.LocalPlayer
local PlayerChar = Player.Character or Player.CharacterAdded:Wait()
local playerRootPart = PlayerChar:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera

local MobHealthDisplay = {
    Displays = {}
}
MobHealthDisplay.__index = MobHealthDisplay

function MobHealthDisplay:updateDisplay(mob)
    local gui = self.Gui
    local sides = {gui.FrontGui, gui.BackGui}
    for _, side in pairs(sides) do
        side.HealthBar.Bar.Size = UDim2.new(mob.Health / mob.MaxHealth, 0, 1, 0)
        side.HealthText.Text = mob.Health .. " / " .. mob.MaxHealth
    end
end

function MobHealthDisplay.display(mob)
    local display = {
        Char = mob.Object;
        Gui = HealthDisplayGui:Clone();
    }
    setmetatable(display, MobHealthDisplay)
    local maxHealth = mob.MaxHealth
    local health = mob.Health
    local head = display.Char.Head
    local gui = display.Gui
    gui.Parent = head
    gui.Name = "HealthDisplayGui"
    local sides = {gui.FrontGui, gui.BackGui}
    for _, side in pairs(sides) do
        side.HealthBar.Bar.Size = UDim2.new(health / maxHealth, 0, 1, 0)
        side.HealthText.Text = health .. " / " .. maxHealth
    end
    local updateGUI
    updateGUI = RunService.Heartbeat:Connect(function()
        if not display.Char then
            updateGUI:Disconnect()
        end
        local headPosition = head.Position
        gui.CFrame = CFrame.new(Vector3.new(headPosition.X, headPosition.Y + 2, headPosition.Z), camera.CFrame.Position)
    end)
    return display
end

function MobHealthDisplay.update(mobs)
    local toRemove = {}
    for i, display in pairs(MobHealthDisplay.Displays) do
        local match = false
        for _, mob in pairs(mobs) do
            if mob.Object == display.Char then
                display:updateDisplay(mob)
                match = true
            end
        end
        if not match then
            table.insert(toRemove, i)
        end
    end
    for i = #toRemove, 1, -1 do
        table.remove(MobHealthDisplay.Displays, toRemove[i])
    end
    for _, mob in pairs(mobs) do
        if not mob.Object.Head:FindFirstChild("HealthDisplayGui") then
           table.insert(MobHealthDisplay.Displays,  MobHealthDisplay.display(mob))
        end
    end
end

return MobHealthDisplay