-- CE utility helpers

function CE_GetLastWord(text)
    if type(GetLastWord) == "function" then
        return GetLastWord(text)
    end
    if type(text) ~= "string" or text == "" then
        return ""
    end

    local lastSpace = nil
    local i = 1
    while true do
        local s = string.find(text, " ", i, true)
        if not s then
            break
        end
        lastSpace = s
        i = s + 1
    end

    if lastSpace then
        return string.sub(text, lastSpace + 1)
    end
    return text
end

function CE_GetFirstWord(text)
    if type(text) ~= "string" or text == "" then
        return ""
    end
    local spacePos = string.find(text, " ", 1, true)
    if spacePos then
        return string.sub(text, 1, spacePos - 1)
    end
    return text
end

function CE_GetConfig()
    local cfg = _G and _G.CE_Config or nil
    if type(cfg) ~= "table" then
        return nil
    end
    return cfg
end

function CE_BuildOriginalClassList()
    local classes = {}
    if type(classPresets) == "table" then
        for className in pairs(classPresets) do
            table.insert(classes, className)
        end
    end
    if type(SortClassesByLastWord) == "function" then
        SortClassesByLastWord(classes)
    end
    return classes
end

function CE_BuildTalentClassList()
    local cfg = CE_GetConfig()
    if not cfg or not cfg.CLASS_TALENTS then
        return CE_BuildOriginalClassList()
    end

    local classes = {}
    for classToken, talents in pairs(cfg.CLASS_TALENTS) do
        local className = (cfg.CLASS_DISPLAY and cfg.CLASS_DISPLAY[classToken]) or classToken
        for i = 1, table.getn(talents) do
            local talentName = talents[i]
            table.insert(classes, talentName .. " " .. className)
        end
    end
    if type(SortClassesByLastWord) == "function" then
        SortClassesByLastWord(classes)
    end
    return classes
end
