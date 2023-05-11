local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Towers = ReplicatedStorage.Towers
local Mobs = ReplicatedStorage.Mobs

local RemoteEvent = ReplicatedStorage.ServerCommunication
local DraftSelect = ServerStorage.ServerEvents.DraftSelect
local DraftEnd = ServerStorage.ServerEvents.DraftEnd
local Draft = {}

local function opposite(input)
    if input == 1 then
        return 2
    elseif input == 2 then
        return 1
    end
end

function Draft.startDraft(player1, player2)
    local towerCards = {}

    for i, module in pairs(Towers:GetChildren()) do
        towerCards[i] = module.Name
    end

    -- Shuffle the towerCards table using the Fisher-Yates algorithm
    for i = #towerCards, 2, -1 do
        local j = math.random(i)
        towerCards[i], towerCards[j] = towerCards[j], towerCards[i]
    end

    -- Choose 16 random tower cards from the shuffled table
    local numCards = 4
    local playerCards = {
        {{}},
        {{}},
    }
    for i = 1, numCards do
        if i <= numCards / 2 then
            table.insert(playerCards[1][math.ceil(i / 2)], towerCards[i])
        else
            table.insert(playerCards[2][math.ceil((i - (numCards / 2)) / 2)], towerCards[i])
        end
    end
    local playerPickedCards = {{}, {}}
    RemoteEvent:FireClient(player1, "DraftBegin", playerCards[1])
    RemoteEvent:FireClient(player2, "DraftBegin", playerCards[2])
    local currentSet = {1, 1}
    DraftSelect.Event:Connect(function(player, pickNum)
        if player ~= player1 and player ~= player2 then
            return
        end
        local playerNum
        if player == player1 then
            playerNum = 1
            if currentSet[playerNum] > (numCards / 4) then
                return
            end
        elseif player == player2 then
            playerNum = 2
            if currentSet[playerNum] > (numCards / 4) then
                return
            end
        end
        table.insert(playerPickedCards[playerNum], playerCards[playerNum][currentSet[playerNum]][pickNum])
        table.insert(playerPickedCards[opposite(playerNum)], playerCards[playerNum][currentSet[playerNum]][opposite(pickNum)])
        print("Draftselect", currentSet[1], currentSet[2])
        currentSet[playerNum] += 1
        if currentSet[1] > (numCards / 4) and currentSet[2] > (numCards / 4) then
            print("DraftEnded")
            RemoteEvent:FireClient(player1, "TowerSelection", playerPickedCards[1])
            RemoteEvent:FireClient(player2, "TowerSelection", playerPickedCards[2])
            DraftEnd:Fire()
            return {
                playerPickedCards[1],
                playerPickedCards[2]
            }
        end
    end)
end

return Draft