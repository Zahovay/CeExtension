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

function CE_NormalizeRaidName(raidName)
    if type(raidName) ~= "string" or raidName == "" then
        return "Naxxramas"
    end
    -- Trim whitespace to keep keys stable between dropdowns/UI sources.
    raidName = string.gsub(raidName, "^%s+", "")
    raidName = string.gsub(raidName, "%s+$", "")
    return raidName
end

function CE_GetPlannerStore()
    ConsumesManager_Options = ConsumesManager_Options or {}
    ConsumesManager_Options.cePlanner = ConsumesManager_Options.cePlanner or {}
    return ConsumesManager_Options.cePlanner
end

local function CE_BuildLowerNameToId(nameToId)
    local lower = {}
    if type(nameToId) ~= "table" then
        return lower
    end
    for itemName, itemId in pairs(nameToId) do
        if type(itemName) == "string" then
            lower[string.lower(itemName)] = itemId
        end
    end
    return lower
end

local function CE_GetItemIdByNameInsensitive(nameToId, lowerNameToId, itemName)
    if type(itemName) ~= "string" or itemName == "" then
        return nil
    end
    if type(nameToId) == "table" then
        local direct = nameToId[itemName]
        if direct then
            return direct
        end
    end
    if type(lowerNameToId) == "table" then
        return lowerNameToId[string.lower(itemName)]
    end
    return nil
end

function CE_BuildPlannerDefaultsFromData(raidName)
    raidName = CE_NormalizeRaidName(raidName)
    local defaults = {}

    local data = RaidConsumables and RaidConsumables.Data
    if not data then
        return defaults
    end

    -- Today Data.lua is Naxx-focused; keep other raids empty by default.
    if raidName ~= "Naxxramas" then
        return defaults
    end

    local nameToId = consumablesNameToID or {}
    local lowerNameToId = CE_BuildLowerNameToId(nameToId)

    local function applyEntry(entry, status)
        local names = nil
        local required = 1

        if type(entry) == "table" then
            names = entry.names or entry
            required = tonumber(entry.required) or 1
        else
            names = { entry }
            required = 1
        end

        if type(names) ~= "table" then
            names = { names }
        end

        local firstResolved = false
        for i = 1, table.getn(names) do
            local name = names[i]
            local itemId = CE_GetItemIdByNameInsensitive(nameToId, lowerNameToId, name)
            if itemId then
                defaults[itemId] = defaults[itemId] or {}
                defaults[itemId].amount = required
                defaults[itemId].status = status
                if not firstResolved then
                    defaults[itemId].enabled = true
                    firstResolved = true
                else
                    defaults[itemId].enabled = defaults[itemId].enabled or false
                end
            end
        end
    end

    if type(data.MandatoryGroups) == "table" then
        for i = 1, table.getn(data.MandatoryGroups) do
            applyEntry(data.MandatoryGroups[i], "mandatory")
        end
    end
    if type(data.OptionalGroups) == "table" then
        for i = 1, table.getn(data.OptionalGroups) do
            applyEntry(data.OptionalGroups[i], "optional")
        end
    end

    return defaults
end

function CE_EnsurePlannerDefaultsForRaid(raidName)
    raidName = CE_NormalizeRaidName(raidName)
    local store = CE_GetPlannerStore()
    store[raidName] = store[raidName] or {}
    local raidStore = store[raidName]

    if raidStore.__initialized then
        return raidStore
    end

    local defaults = CE_BuildPlannerDefaultsFromData(raidName)
    for itemId, entry in pairs(defaults) do
        if type(itemId) == "number" and type(entry) == "table" then
            if type(raidStore[itemId]) ~= "table" then
                raidStore[itemId] = {}
            end
            local target = raidStore[itemId]
            if target.enabled == nil then
                target.enabled = entry.enabled and true or false
            end
            if target.amount == nil then
                target.amount = tonumber(entry.amount) or 0
            end
            if target.status == nil then
                target.status = entry.status
            end
        end
    end

    raidStore.__initialized = true
    return raidStore
end

function CE_GetPlannerRaidRequirements(raidName)
    raidName = CE_NormalizeRaidName(raidName)
    local raidStore = CE_EnsurePlannerDefaultsForRaid(raidName)
    return raidStore
end

function CE_GetConsumableNameById(itemId)
    if not itemId then
        return nil
    end
    if type(consumablesList) == "table" then
        local name = consumablesList[itemId]
        if type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(consumablesCategories) == "table" then
        for _, items in pairs(consumablesCategories) do
            if type(items) == "table" then
                for i = 1, table.getn(items) do
                    local item = items[i]
                    if item and item.id == itemId and type(item.name) == "string" and item.name ~= "" then
                        return item.name
                    end
                end
            end
        end
    end
    return nil
end

-- =========================
-- CE Preset Tab Data Model
-- =========================
--
-- Goal: provide a single saved data source that represents what the Presets tab uses:
-- a table shaped like ConsumesManager's `classPresets`:
--
--   store[className] = {
--     { raid = "Naxxramas", id = { 13452, ... } },
--     ...
--   }
--
-- The Presets UI then works unchanged, and the planner edits this same store.

local function CE_BuildConsumablesNameToId()
    local nameToId = {}
    local lowerToId = {}
    if type(consumablesCategories) ~= "table" then
        return nameToId, lowerToId
    end
    for _, items in pairs(consumablesCategories) do
        if type(items) == "table" then
            for i = 1, table.getn(items) do
                local item = items[i]
                if item and item.id and type(item.name) == "string" and item.name ~= "" then
                    nameToId[item.name] = item.id
                    lowerToId[string.lower(item.name)] = item.id
                end
            end
        end
    end
    return nameToId, lowerToId
end

local function CE_GetItemIdByName(nameToId, lowerToId, itemName)
    if type(itemName) ~= "string" or itemName == "" then
        return nil
    end
    if type(nameToId) == "table" and nameToId[itemName] then
        return nameToId[itemName]
    end
    if type(lowerToId) == "table" then
        return lowerToId[string.lower(itemName)]
    end
    return nil
end

local function CE_SpecToFallbackPresetClass(specName)
    if type(specName) ~= "string" or specName == "" then
        return nil
    end

    -- If the original presets already have this exact key, prefer it.
    if type(classPresets) == "table" and classPresets[specName] then
        return specName
    end

    -- CE dropdown format is "<Talent> <Class>".
    local className = CE_GetLastWord(specName)
    local talent = CE_GetFirstWord(specName)

    if className == "Rogue" then
        return "Rogue"
    end

    if className == "Mage" then
        if talent == "Fire" then return "Fire Mage" end
        if talent == "Frost" then return "Frost Mage" end
        if talent == "Arcane" then return "Arcane Mage" end
        return "Fire Mage"
    end

    if className == "Priest" then
        if talent == "Shadow" then return "Shadow Priest" end
        if talent == "Holy" then return "Holy Priest" end
        if talent == "Discipline" then return "Discipline Priest" end
        return "Holy Priest"
    end

    if className == "Warlock" then
        -- ConsumesManager's presets use "Shadow Warlock" and "Fire Warlock".
        if talent == "Destruction" then return "Fire Warlock" end
        return "Shadow Warlock" -- Affliction/Demonology default here.
    end

    if className == "Hunter" then
        if talent == "Marksmanship" then return "Marksmanship Hunter" end
        if talent == "Survival" then return "Survival Hunter" end
        return "Survival Hunter" -- Beast fallback.
    end

    if className == "Warrior" then
        if talent == "Protection" then return "Protection Warrior" end
        return "Fury Warrior" -- Arms/Fury fallback.
    end

    if className == "Shaman" then
        if talent == "Elemental" then return "Elemental Shaman" end
        if talent == "Restoration" then return "Restoration Shaman" end
        return "Enhancement Shaman"
    end

    if className == "Paladin" then
        if talent == "Holy" then return "Holy Paladin" end
        if talent == "Protection" then return "Protection Paladin" end
        if talent == "Retribution" then return "Retribution Paladin" end
        return "Holy Paladin"
    end

    if className == "Druid" then
        if talent == "Restoration" then return "Restoration Druid" end
        if talent == "Balance" then return "Moonkin DPS Druid" end
        return "Cat DPS Druid" -- Feral fallback.
    end

    return nil
end

local function CE_InferRoleFromClassName(specName)
    if type(specName) ~= "string" or specName == "" then
        return nil
    end
    local name = string.lower(specName)

    if string.find(name, "tank", 1, true) or string.find(name, "protection", 1, true) then
        return "tank"
    end
    if string.find(name, "healer", 1, true) or string.find(name, "holy", 1, true) or string.find(name, "restoration", 1, true) or string.find(name, "discipline", 1, true) then
        return "healer"
    end
    if string.find(name, "hunter", 1, true) or string.find(name, "ranged", 1, true) then
        return "ranged"
    end
    if string.find(name, "mage", 1, true) or string.find(name, "warlock", 1, true) or string.find(name, "shadow priest", 1, true) or string.find(name, "elemental", 1, true) or string.find(name, "moonkin", 1, true) or string.find(name, "balance", 1, true) then
        return "caster"
    end
    if string.find(name, "rogue", 1, true) or string.find(name, "warrior", 1, true) or string.find(name, "enhancement", 1, true) or string.find(name, "cat", 1, true) or string.find(name, "melee", 1, true) or string.find(name, "fury", 1, true) or string.find(name, "retribution", 1, true) or string.find(name, "feral", 1, true) then
        return "melee"
    end
    return nil
end

local function CE_AppendIdsUnique(targetList, seen, ids)
    if type(targetList) ~= "table" or type(seen) ~= "table" or type(ids) ~= "table" then
        return
    end
    for i = 1, table.getn(ids) do
        local id = ids[i]
        if type(id) == "number" and not seen[id] then
            table.insert(targetList, id)
            seen[id] = true
        end
    end
end

local function CE_BuildPresetFromRaidConsumablesData(specName)
    local ids = {}
    local seen = {}
    local req = {}
    local data = RaidConsumables and RaidConsumables.Data
    if type(data) ~= "table" then
        return ids, req
    end

    local nameToId, lowerToId = CE_BuildConsumablesNameToId()

    local function applyEntries(entries, status)
        if type(entries) ~= "table" then
            return
        end
        for i = 1, table.getn(entries) do
            local entry = entries[i]
            local names = nil
            local required = 1
            if type(entry) == "table" then
                names = entry.names or entry
                required = tonumber(entry.required) or 1
            else
                names = { entry }
                required = 1
            end
            if type(names) ~= "table" then
                names = { names }
            end

            local resolved = {}
            for j = 1, table.getn(names) do
                local itemName = names[j]
                local itemId = CE_GetItemIdByName(nameToId, lowerToId, itemName)
                if itemId then
                    table.insert(resolved, itemId)
                end
            end

            -- Store requirements for all resolved alternatives.
            for j = 1, table.getn(resolved) do
                local itemId = resolved[j]
                req[itemId] = req[itemId] or {}
                if req[itemId].amount == nil then
                    req[itemId].amount = required
                end
                if req[itemId].status == nil then
                    req[itemId].status = status
                end
            end

            -- But include only the first resolved item in the Presets-tab list by default.
            local primary = resolved[1]
            if primary and not seen[primary] then
                table.insert(ids, primary)
                seen[primary] = true
            end
        end
    end

    applyEntries(data.MandatoryGroups, "mandatory")
    applyEntries(data.OptionalGroups, "optional")

    local role = CE_InferRoleFromClassName(specName)
    if role and type(data.RoleMandatory) == "table" then
        applyEntries(data.RoleMandatory[role], "mandatory")
    end

    if type(data.SpecMandatory) == "table" and type(data.SpecMandatory[specName]) == "table" then
        applyEntries(data.SpecMandatory[specName], "mandatory")
    end

    return ids, req
end

function CE_GetPresetTabStore()
    ConsumesManager_Options = ConsumesManager_Options or {}
    ConsumesManager_Options.cePresetTab = ConsumesManager_Options.cePresetTab or {}
    return ConsumesManager_Options.cePresetTab
end

local function CE_BuildPresetTabDefaults()
    local store = {}
    local cfg = CE_GetConfig()
    local raids = (cfg and cfg.ORDERED_RAIDS) or { "Naxxramas" }
    local classes = (type(CE_BuildTalentClassList) == "function" and CE_BuildTalentClassList()) or {}

    for ci = 1, table.getn(classes) do
        local specName = classes[ci]
        store[specName] = {}

        for ri = 1, table.getn(raids) do
            local raidName = raids[ri]
            local ids = {}
            local req = {}

            if raidName == "Naxxramas" then
                ids, req = CE_BuildPresetFromRaidConsumablesData(specName)
            else
                local fallbackClass = CE_SpecToFallbackPresetClass(specName)
                if fallbackClass and type(classPresets) == "table" and type(classPresets[fallbackClass]) == "table" then
                    local presets = classPresets[fallbackClass]
                    for pi = 1, table.getn(presets) do
                        local preset = presets[pi]
                        if preset and preset.raid == raidName and type(preset.id) == "table" then
                            -- Copy list
                            local copied = {}
                            local seen = {}
                            CE_AppendIdsUnique(copied, seen, preset.id)
                            ids = copied
                            break
                        end
                    end
                end
            end

            table.insert(store[specName], { raid = raidName, id = ids, req = req })
        end
    end

    return store
end

function CE_EnsurePresetTabDefaults()
    local store = CE_GetPresetTabStore()

    local function ensureReqForPresetEntry(className, preset)
        if type(preset) ~= "table" then
            return
        end
        preset.id = type(preset.id) == "table" and preset.id or {}
        preset.req = type(preset.req) == "table" and preset.req or {}

        -- For Naxx, seed amounts/status from RaidConsumablesData first.
        if preset.raid == "Naxxramas" and type(className) == "string" and className ~= "" then
            local _, defaultsReq = CE_BuildPresetFromRaidConsumablesData(className)
            if type(defaultsReq) == "table" then
                for itemId, def in pairs(defaultsReq) do
                    if type(itemId) == "number" and type(def) == "table" then
                        preset.req[itemId] = preset.req[itemId] or {}
                        local r = preset.req[itemId]

                        local defAmount = tonumber(def.amount) or 0
                        local curAmount = tonumber(r.amount)
                        if r.amount == nil or curAmount == nil or (curAmount == 0 and defAmount > 0) then
                            r.amount = defAmount
                        end
                        if r.status == nil then
                            r.status = def.status
                        end
                    end
                end
            end
        end

        -- Ensure every selected item has at least a requirement entry.
        for i = 1, table.getn(preset.id) do
            local itemId = preset.id[i]
            if type(itemId) == "number" then
                preset.req[itemId] = preset.req[itemId] or { amount = 0, status = "mandatory" }
                if preset.req[itemId].amount == nil then
                    preset.req[itemId].amount = 0
                end
                if preset.req[itemId].status == nil then
                    preset.req[itemId].status = "mandatory"
                end
            end
        end
    end

    local function migrateToV3()
        -- Ensure req exists everywhere, and backfill Naxx amounts/status.
        for className, presets in pairs(store) do
            if type(className) == "string" and type(presets) == "table" then
                for i = 1, table.getn(presets) do
                    local preset = presets[i]
                    ensureReqForPresetEntry(className, preset)
                end
            end
        end
        store.__version = 3
    end

    -- First-time init.
    if not store.__initialized then
        local defaults = CE_BuildPresetTabDefaults()
        for className, presets in pairs(defaults) do
            if type(className) == "string" and type(presets) == "table" then
                store[className] = presets
            end
        end
        store.__initialized = true
        store.__version = 3
        return store
    end

    -- Existing store: migrate forward if needed.
    local v = tonumber(store.__version) or 1
    if v < 3 then
        migrateToV3()
    end
    return store
end

local function CE_GetOrCreatePresetEntry(className, raidName)
    raidName = CE_NormalizeRaidName(raidName)
    local existing = CE_GetPresetEntry(className, raidName)
    if existing then
        existing.id = type(existing.id) == "table" and existing.id or {}
        existing.req = type(existing.req) == "table" and existing.req or {}
        return existing
    end

    local store = CE_EnsurePresetTabDefaults()
    store[className] = store[className] or {}
    local presets = store[className]
    local created = { raid = raidName, id = {}, req = {} }
    table.insert(presets, created)
    return created
end

-- Read-only preset entry lookup. Returns the preset entry table or nil.
-- Does NOT create missing entries.
function CE_GetPresetEntry(className, raidName)
    if type(className) ~= "string" or className == "" then
        return nil
    end
    raidName = CE_NormalizeRaidName(raidName)

    local store = CE_EnsurePresetTabDefaults()
    local presets = store and store[className]
    if type(presets) ~= "table" then
        return nil
    end

    for i = 1, table.getn(presets) do
        local p = presets[i]
        if p and p.raid == raidName then
            return p
        end
    end
    return nil
end

function CE_GetPresetIdsFor(className, raidName)
    className = type(className) == "string" and className or ""
    raidName = CE_NormalizeRaidName(raidName)
    local entry = CE_GetPresetEntry(className, raidName)
    if entry and type(entry.id) == "table" then
        return entry.id
    end
    return nil
end

function CE_SetPresetIdsFor(className, raidName, ids)
    if type(className) ~= "string" or className == "" then
        return
    end
    raidName = CE_NormalizeRaidName(raidName)
    if type(ids) ~= "table" then
        ids = {}
    end

    local store = CE_EnsurePresetTabDefaults()
    store[className] = store[className] or {}
    local presets = store[className]

    for i = 1, table.getn(presets) do
        local p = presets[i]
        if p and p.raid == raidName then
            p.id = ids
            p.req = type(p.req) == "table" and p.req or {}
            return
        end
    end

    table.insert(presets, { raid = raidName, id = ids, req = {} })
end

function CE_GetPresetReqFor(className, raidName, itemId)
    if type(className) ~= "string" or className == "" then
        return nil
    end
    itemId = tonumber(itemId)
    if type(itemId) ~= "number" then
        return nil
    end
    local entry = CE_GetOrCreatePresetEntry(className, raidName)
    if entry and type(entry.req) == "table" then
        return entry.req[itemId]
    end
    return nil
end

function CE_SetPresetReqFor(className, raidName, itemId, amount, status)
    if type(className) ~= "string" or className == "" then
        return
    end
    itemId = tonumber(itemId)
    if type(itemId) ~= "number" then
        return
    end
    local entry = CE_GetOrCreatePresetEntry(className, raidName)
    entry.req = type(entry.req) == "table" and entry.req or {}
    entry.req[itemId] = entry.req[itemId] or {}
    local r = entry.req[itemId]
    if amount ~= nil then
        r.amount = tonumber(amount) or 0
    end
    if status ~= nil then
        r.status = status
    end
end

function CE_TogglePresetItem(className, raidName, itemId, enabled)
    itemId = tonumber(itemId)
    if type(itemId) ~= "number" then
        return
    end
    local ids = CE_GetPresetIdsFor(className, raidName)
    if type(ids) ~= "table" then
        ids = {}
    end

    local foundIndex = nil
    for i = 1, table.getn(ids) do
        if ids[i] == itemId then
            foundIndex = i
            break
        end
    end

    if enabled then
        if not foundIndex then
            table.insert(ids, itemId)
        end
    else
        if foundIndex then
            table.remove(ids, foundIndex)
        end
    end

    CE_SetPresetIdsFor(className, raidName, ids)

    -- Ensure requirement metadata exists for items the user adds.
    if enabled and type(CE_GetPresetReqFor) == "function" and type(CE_SetPresetReqFor) == "function" then
        local r = CE_GetPresetReqFor(className, raidName, itemId)
        if type(r) ~= "table" then
            CE_SetPresetReqFor(className, raidName, itemId, 0, "mandatory")
        else
            if r.status == nil then
                r.status = "mandatory"
            end
            if r.amount == nil then
                r.amount = 0
            end
        end
    end
end
