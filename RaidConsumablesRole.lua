-- RaidConsumablesRole.lua
-- Simple on-demand role detection from class and talents (Classic 1.12)

local RC = RaidConsumables or {}
RC.Role = RC.Role or {}

-- Return an uppercase class token (e.g. "PRIEST").
local function getClassToken()
    -- Turtle/Classic: second return of UnitClass is the stable class token
    local _, classToken = UnitClass("player")
    if classToken and classToken ~= "" then
        return string.upper(classToken)
    end

    -- Fallback: some servers only return one value
    local localized = UnitClass("player")
    if localized and localized ~= "" then
        return string.upper(localized)
    end

    return ""
end

local function safeGetTalentTabPoints(tab)
    -- GetTalentTabInfo returns: name, icon, pointsSpent, background
    local name, _, pointsSpent = GetTalentTabInfo(tab)
    return name, pointsSpent or 0
end

local function maxTabIndex(numTabs)
    local maxPoints, maxIndex = -1, 1
    local names = {}
    for i = 1, numTabs do
        local name, points = safeGetTalentTabPoints(i)
        names[i] = name
        if points > maxPoints then
            maxPoints = points
            maxIndex = i
        end
    end
    return maxIndex, names
end

-- Class + talent-tab to role mapping.
-- For classes with no meaningful spec split (e.g. ROUGE/HUNTER/MAGE/WARLOCK), only `default` is used.
local CLASS_ROLE_BY_TAB = {
    PRIEST  = { [1] = "healer", [2] = "healer", [3] = "caster", default = "healer" },
    PALADIN = { [1] = "healer", [2] = "tank",   [3] = "melee",  default = "healer" },
    SHAMAN  = { [1] = "caster", [2] = "melee",  [3] = "healer", default = "healer" },
    DRUID   = { [1] = "caster", [2] = "melee",  [3] = "healer", default = "healer" },
    WARRIOR = { [1] = "melee",  [2] = "melee",  [3] = "tank",   default = "melee"  },
    ROGUE   = { default = "melee"  },
    HUNTER  = { default = "ranged" },
    MAGE    = { default = "caster" },
    WARLOCK = { default = "caster" },
}

-- Returns: role string, and a small info table for debugging/introspection.
function RC.Role.Detect()
    local classTag = getClassToken()

    -- Ensure talent API is available when we run (some servers gate it)
    if IsAddOnLoaded and LoadAddOn then
        if not IsAddOnLoaded("Blizzard_TalentUI") then
            LoadAddOn("Blizzard_TalentUI")
        end
    end

    local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0

    local tabIndex, tabNames = 1, {}
    if numTabs > 0 then
        tabIndex, tabNames = maxTabIndex(numTabs)
    end

    local role = "unknown"
    local cfg = CLASS_ROLE_BY_TAB[classTag]
    if cfg then
        -- If we have a specific mapping for this tab, use it, otherwise fall back to class default.
        role = cfg[tabIndex] or cfg.default or role
    end

    return role, { class = classTag, tabs = tabNames, primaryTab = tabIndex }
end

function RC.Role.GetRoleGroups(role)
    if not RC.Data or not RC.Data.RoleMandatory then
        return {}
    end
    return RC.Data.RoleMandatory[role] or {}
end

RaidConsumables = RC
