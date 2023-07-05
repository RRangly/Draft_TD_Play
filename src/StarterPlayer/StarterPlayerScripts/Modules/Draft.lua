local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Towers = ReplicatedStorage.Towers
local RemoteEvent = ReplicatedStorage.ServerCommunication
local PlayerGuis = ReplicatedStorage.PlayerGuis
local GuiAssets = ReplicatedStorage.PlayerGuiAssets
local Cover = PlayerGuis.Cover:Clone()

local ClientEvents = ReplicatedStorage.ClientEvents
local DraftUpdate = ReplicatedStorage.ClientEvents.DraftUpdate
local GameStarted = ClientEvents.GameStarted
local DraftEnd = false

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

Cover.Parent = PlayerGui
local Draft = {
    Cards = {}
}

local function endDraft(gui, playerNum)
    gui.DraftFrame:Destroy()
    gui.PickedFrame:Destroy()
    gui.DraftInfo:Destroy()
    local endFrame = gui.EndFrame
    local xIndex = 1 / (#Draft.Cards[playerNum] + 1)
    coroutine.wrap(function()
        for i, cardName in pairs(Draft.Cards[playerNum]) do
            local clone = GuiAssets.DraftCard:Clone()
            clone.Parent = endFrame
            clone.CardName.Text = cardName
            clone.Position = UDim2.new(xIndex * i, 0, 1, 0)
            local tween = TweenService:Create(clone, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(xIndex * i, 0, 0.5, 0)})
            tween:Play()
            task.wait(0.5)
        end
    end)()
    GameStarted.Event:Wait()
    Cover:Destroy()
    gui:Destroy()
end

function Draft.updateDraftGui(gui, draftCards, pickPlayer, pickNum, nextTurn)
    if not Draft.Cards[pickPlayer] then
        Draft.Cards[pickPlayer] = {}
    end
    local pickedCard = draftCards[pickNum]
    table.insert(Draft.Cards[pickPlayer], pickedCard)
    local draftFrame = gui.DraftFrame
    local draftInfo = gui.DraftInfo
    local pickedFrame = gui.PickedFrame
    pickedFrame = Instance.new("Frame")
    draftInfo.Text = "player " .. pickPlayer .. " has picked " .. pickedCard
    local cardFrame = draftFrame:FindFirstChild(pickNum)
    local clone = cardFrame:Clone()
    clone.AnchorPoint = Vector2.new(0, 0)
    clone.Position = UDim2.new(0, cardFrame.AbsolutePosition.X, 0,cardFrame.AbsolutePosition.Y)
    clone.Size = UDim2.new(0, cardFrame.AbsoluteSize.X, 0, cardFrame.AbsoluteSize.Y)
    clone.Parent = gui
    cardFrame:Destroy()
    local tween = TweenService:Create(clone, TweenInfo.new(1.5), {
        Position = UDim2.new(1.1, 0, 1.1, 0);
        Size = UDim2.new(0.08, 0, 0.12, 0);
    })
    tween:Play()
    tween.Completed:Wait()
    clone:Destroy()
    if draftInfo then
        draftInfo.Text = "player " .. nextTurn .. "'s turn"
    end
end

function Draft.draftBegin(draftCards, playerNum)
    local draftGui = PlayerGuis.DraftGui:Clone()
    local draftCard = GuiAssets.DraftCard
    draftGui.Parent = PlayerGui
    local draftFrame = draftGui.DraftFrame
    local draftInfo = draftGui.DraftInfo

    local turn = 1
    local columns = 4
    local rows = math.ceil(#draftCards / columns)
    local xIndex = 1 / (columns + 1)
    local yIndex = 1 / (rows + 1)
    for row = 1, rows, 1 do
        local y = yIndex * row
        for column = 1, columns, 1 do
            local x = xIndex * column   
            local cardI = (row - 1) * columns + column
            local card = draftCards[cardI]
            if not card then
                continue
            end
            local clone = draftCard:Clone()
            clone.Parent = draftFrame
            clone.Name = cardI
            clone.CardName.Text = card
            clone.Position = UDim2.new(x, 0, y, 0)
            clone.InputBegan:Connect(function(inputObj)
                if inputObj.UserInputType == Enum.UserInputType.MouseButton1 and turn == playerNum then
                    RemoteEvent:FireServer("DraftSelect", cardI)
                end
            end)
        end
    end
    draftInfo.Text = "player " .. turn .. "'s turn"

    DraftUpdate.Event:Connect(function(type, pickPlayer, pickNum, nextTurn)
        if type == "Pick" then
            Draft.updateDraftGui(draftGui, draftCards, pickPlayer, pickNum, nextTurn)
            turn = nextTurn
        elseif type == "End" then
            task.wait(1)
            endDraft(draftGui, playerNum)
        end
    end)
end

return Draft