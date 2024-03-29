local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Towers = ReplicatedStorage.Towers

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

function Draft.startDraft(players)
    local towerCards = {}

    for i, module in pairs(Towers:GetChildren()) do
        towerCards[i] = module.Name
    end

    for i = #towerCards, 2, -1 do
        local j = math.random(i)
        towerCards[i], towerCards[j] = towerCards[j], towerCards[i]
    end

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
    for i = 1, 2, 1 do
        RemoteEvent:FireClient(players[i], "DraftBegin", playerCards[i])
    end
    local currentSet = {1, 1}

    DraftSelect.Event:Connect(function(player, pickNum)
        local playerNum = nil
        for i = 1, 2, 1 do
            if player == players[i] then
                playerNum = i
            end
        end

        if not playerNum then
            return
        end

        table.insert(playerPickedCards[playerNum], playerCards[playerNum][currentSet[playerNum]][pickNum])
        table.insert(playerPickedCards[opposite(playerNum)], playerCards[playerNum][currentSet[playerNum]][opposite(pickNum)])
        print("Draftselect", currentSet[1], currentSet[2])
        
        currentSet[playerNum] += 1
        if currentSet[1] > (numCards / 4) and currentSet[2] > (numCards / 4) then
            print("DraftEnded")
            DraftEnd:Fire({
                playerPickedCards[1],
                playerPickedCards[2]
            })
        end
    end)
end

function Draft.singleDraft(player)
    local towerCards = {}

    for i, module in pairs(Towers:GetChildren()) do
        towerCards[i] = module.Name
    end

    for i = #towerCards, 2, -1 do
        local j = math.random(i)
        towerCards[i], towerCards[j] = towerCards[j], towerCards[i]
    end

    local numCards = 6
    local playerCards = {
        {},
        {},
        {},
    }

    for i = 1, numCards do
        table.insert(playerCards[math.ceil(i / 2)], towerCards[i])
    end

    local playerPickedCards = {}
    RemoteEvent:FireClient(player, "DraftBegin", playerCards)
    local currentSet = 1

    DraftSelect.Event:Connect(function(eventPlayer, pickNum)
        if eventPlayer ~= player then
            return
        end
        table.insert(playerPickedCards, playerCards[currentSet][pickNum])
        currentSet += 1
        if currentSet > (numCards / 2) then
            DraftEnd:Fire(playerPickedCards)
        end
    end)
end

function Draft.megadraft(players)
    local cards = {}

    for i, module in pairs(Towers:GetChildren()) do
        cards[i] = module.Name
    end

    for i = #cards, 2, -1 do
        local j = math.random(i)
        cards[i], cards[j] = cards[j], cards[i]
    end
    local draftInfo = {
        Cards = {};
        Picks = {};
        Turn = 1;
        Total = 0;
    }
    for i = 1, 8, 1 do
        table.insert(draftInfo.Cards, cards[i])
    end
    for i = 1, #players, 1 do
        draftInfo.Picks[i] = {}
        RemoteEvent:FireClient(players[i], "DraftBegin", draftInfo.Cards, i)
    end
    DraftSelect.Event:Connect(function(player, pickNum)
        local playerNum = nil
        for i = 1, #players, 1 do
            if player == players[i] then
                playerNum = i
            end
        end
        if not (playerNum == draftInfo.Turn) then
            return
        end
        if draftInfo.Cards[pickNum] then
            table.insert(draftInfo.Picks[playerNum], draftInfo.Cards[pickNum])
            draftInfo.Cards[pickNum] = nil
            draftInfo.Turn += 1
            if draftInfo.Turn > #players then
                draftInfo.Turn = 1
            end
            for i = 1, #players, 1 do
                RemoteEvent:FireClient(players[i], "DraftUpdate", "Pick", playerNum, pickNum, draftInfo.Turn)
            end
            draftInfo.Total += 1
            if draftInfo.Total >= 4 then
                for i = 1, #players, 1 do
                    RemoteEvent:FireClient(players[i], "DraftUpdate", "End")
                end
                DraftEnd:Fire(draftInfo.Picks)
            end
        end
    end)
end

return Draft