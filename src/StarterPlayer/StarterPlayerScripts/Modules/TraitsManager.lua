local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvent = ReplicatedStorage.ServerCommunication
local TraitsGui = ReplicatedStorage.PlayerGuis.TraitsGui
local Traits = require(ReplicatedStorage.Game.Traits)

local TraitsManager = {}

function TraitsManager.SelectTraits(selections)
    local gui = TraitsGui:Clone()
    gui.Parent = PlayerGui
    local traits = gui.Traits:GetChildren()
    local sel = nil
    local connections = {}
    for i = 1, 3, 1 do
        local frame = traits[i]
        local trait = Traits[selections[i]]
        frame.Title.Text = trait.Name
        frame.Description.Text = trait.Description
        connections[i] = frame.InputBegan:Connect(function(inputObj)
            if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
                if sel then
                    local selPos = traits[sel].Position
                    local tween = TweenService:Create(traits[sel], TweenInfo.new(0.5), {Position = UDim2.new(selPos.X.Scale, 0, 0, 0)})
                    tween:Play()
                end
                if sel == i then
                    sel = nil
                    return
                end
                sel = i
                local selPos = traits[sel].Position
                local tween = TweenService:Create(traits[sel], TweenInfo.new(0.5), {Position = UDim2.new(selPos.X.Scale, 0, -0.15, 0)})
                tween:Play()
            end
        end)
    end
    local SelButton = gui.Select
    connections[4] = SelButton.MouseButton1Click:Connect(function()
        if sel then
            RemoteEvent:FireServer("TraitSelect", sel)
            for i in ipairs(connections) do
                connections[i]:Disconnect()
            end
            gui:Destroy()
        end
    end)
end

return TraitsManager