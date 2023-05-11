local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HealthDisplayGui = ReplicatedStorage.ClientAssets:FindFirstChild("HealthDisplayGui")
local Player = Players.LocalPlayer
local PlayerChar = Player.Character or Player.CharacterAdded:Wait()
local playerRootPart = PlayerChar:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera

local function displayHealthBar(humanoid)
    local char = humanoid.Parent
    local maxHealth = humanoid.MaxHealth
    local health = humanoid.Health
    local head = char.Head
    local guiClone = HealthDisplayGui:Clone()
    guiClone.Parent = head
    guiClone.Name = "HealthDisplayGui"
    local guis = {guiClone.FrontGui, guiClone.BackGui}
    for _, gui in pairs(guis) do
        gui.HealthBar.Bar.Size = UDim2.new(health / maxHealth, 0, 1, 0)
        gui.HumanoidHealthText.Text = health .. " / " .. maxHealth
    end
    
    local updateGUI = RunService.Heartbeat:Connect(function()
        local headPosition = head.Position
        guiClone.CFrame = CFrame.new(Vector3.new(headPosition.X, headPosition.Y + 2, headPosition.Z), camera.CFrame.Position)
    end)

    local healthUpdate = humanoid.HealthChanged:Connect(function()
        if not guiClone then
            return
        end
        health = humanoid.Health
        for _, gui in pairs(guis) do
            if gui:FindFirstChild("HealthBar") then
                gui.HealthBar.Bar.Size = UDim2.new(health / maxHealth, 0, 1, 0)
            end
            if gui:FindFirstChild("HumanoidHealthText") then
                gui.HumanoidHealthText.Text = health .. " / " .. maxHealth
            end
        end
    end)

    humanoid.Died:Once(function()
        updateGUI:Disconnect()
        healthUpdate:Disconnect()
        guiClone:Destroy()
    end)
end


while true do
    for _, humanoid in pairs(game.Workspace:GetDescendants()) do
        if humanoid:IsA("Humanoid") and humanoid.Parent ~= game.Players.LocalPlayer.Character then
            local char = humanoid.Parent
            local head = char.Head
            if (humanoid.RootPart.CFrame.Position - playerRootPart.CFrame.Position).Magnitude <= 60 then
                if head:FindFirstChild("HealthDisplayGui") then
                    continue
                end
                displayHealthBar(humanoid)
            else
                if head:FindFirstChild("HealthDisplayGui") then
                    head.HealthDisplayGui:Destroy()
                end
            end
        end
    end
    wait()
end