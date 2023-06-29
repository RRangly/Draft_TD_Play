local Research = {}
Research.__index = Research

local ResearchInfos = {
    Minigunner = {
        ResearchCost = 500;
        ResearchResource = {"Iron"}
    }
}

function Research.new()
    local research = {
        Completed = {
            Mortar = true;
            Archer = true;
        };
        ResearchTable = {};
        RsearchCapa = {};
    }
    setmetatable(research, Research)
    return research
end

return Research