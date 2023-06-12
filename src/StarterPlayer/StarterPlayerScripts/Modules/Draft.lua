local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Towers = ReplicatedStorage.Towers
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Draft = {}

local function endDraft(gui)
    gui:Destroy()
end

local function updateDraftGui(frames, cards)
    local pick1 = frames.Pick1
    local pick2 = frames.Pick2

    pick1.CardName.Text = Towers:FindFirstChild(cards[1]).Name
    pick2.CardName.Text = Towers:FindFirstChild(cards[2]).Name
end

function Draft.draftBegin(draftCards)
    local draftGui = PlayerGuis.DraftGui:Clone()
    draftGui.Parent = PlayerGui
    local currentPick = 1
    local picks = draftGui.Picks

    updateDraftGui(picks, draftCards[currentPick])
    local pick1 = picks.Pick1
    local pick2 = picks.Pick2

    pick1.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            RemoteEvent:FireServer("DraftSelect", 1)
            if currentPick >= #draftCards then
                endDraft(draftGui)
                return
            end
            currentPick += 1
            updateDraftGui(picks, draftCards[currentPick])
        end
    end)

    pick2.InputBegan:Connect(function(inputObj)
        if inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
            RemoteEvent:FireServer("DraftSelect", 2)
            if currentPick >= #draftCards then
                endDraft(draftGui)
                return
            end
            currentPick += 1
            updateDraftGui(picks, draftCards[currentPick])
        end
    end)
end

return Draft