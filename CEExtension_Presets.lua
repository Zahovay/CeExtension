-- CE presets rendering

CE_TooltipAllowed = CE_TooltipAllowed or {}

local CE_CachedNameToId = nil
local CE_CachedLowerNameToId = nil

local function CE_GetNameLookups()
    local nameToId = consumablesNameToID or {}
    if CE_CachedNameToId ~= nameToId then
        CE_CachedNameToId = nameToId
        CE_CachedLowerNameToId = {}
        for itemName, itemId in pairs(nameToId) do
            CE_CachedLowerNameToId[string.lower(itemName)] = itemId
        end
    end
    return nameToId, CE_CachedLowerNameToId or {}
end

local function CE_AppendEntries(target, entries)
    if type(target) ~= "table" or type(entries) ~= "table" then
        return
    end
    local i = 1
    while entries[i] do
        table.insert(target, entries[i])
        i = i + 1
    end
end

local function CE_GetSpecGroups(data, selectedClass)
    if not data or type(data.SpecMandatory) ~= "table" then
        return nil
    end
    if not selectedClass or selectedClass == "" then
        return nil
    end
    local selectedLower = string.lower(selectedClass)
    for specLabel, entries in pairs(data.SpecMandatory) do
        if string.lower(specLabel) == selectedLower then
            return entries
        end
    end
    return nil
end

local function CE_GetRoleEntries(data, role, specGroups)
    if not role or not data or type(data.RoleMandatory) ~= "table" then
        return nil
    end
    local roleEntries = data.RoleMandatory[role]
    if type(roleEntries) ~= "table" then
        return nil
    end
    if role == "caster" and type(specGroups) == "table" and table.getn(specGroups) > 0 then
        local merged = {}
        CE_AppendEntries(merged, roleEntries)
        CE_AppendEntries(merged, specGroups)
        return merged
    end
    return roleEntries
end

local function CE_BuildGroups(data, role, specGroups, selectedClass)
    local groups = {}
    if data.MandatoryGroups and type(data.MandatoryGroups) == "table" and table.getn(data.MandatoryGroups) > 0 then
        table.insert(groups, { label = "Mandatory", entries = data.MandatoryGroups })
    end

    local roleEntries = CE_GetRoleEntries(data, role, specGroups)
    if roleEntries then
        table.insert(groups, { label = "Role: " .. role, entries = roleEntries })
    elseif type(specGroups) == "table" and table.getn(specGroups) > 0 and selectedClass and selectedClass ~= "" then
        table.insert(groups, { label = "Spec: " .. selectedClass, entries = specGroups })
    end

    if data.OptionalGroups and type(data.OptionalGroups) == "table" and table.getn(data.OptionalGroups) > 0 then
        table.insert(groups, { label = "Optional", entries = data.OptionalGroups })
    end

    return groups
end

local function CE_ClearPresets(parentFrame)
    if not parentFrame then
        return
    end

    if not parentFrame.presetsConsumables then
        parentFrame.presetsConsumables = {}
    end

    local count = 0
    for _ in pairs(parentFrame.presetsConsumables) do
        count = count + 1
    end

    for i = 1, count do
        local consumable = parentFrame.presetsConsumables[i]
        if consumable and consumable.frame and consumable.frame.Hide then
            consumable.frame:Hide()
        end
    end

    parentFrame.presetsConsumables = {}

    if parentFrame.noItemsMessage then
        parentFrame.noItemsMessage:Hide()
    end
end

function CE_LogRoleInfo()
    if not ConsumesManager_Options.showColdEmbrace then
        return
    end

    local roleModule = RaidConsumables and RaidConsumables.Role
    if not roleModule or type(roleModule.Detect) ~= "function" then
        return
    end

    local role, info = roleModule.Detect()
    local classTag = info and info.class or "unknown"
    local tabIndex = info and info.primaryTab or 0
    local tabName = (info and info.tabs and info.tabs[tabIndex]) or "unknown"

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("CE: class=%s, primaryTab=%s, role=%s", classTag, tabName, role or "unknown"))
    end
end

function CE_InferRoleFromSelectedClass()
    local selected = ConsumesManager_SelectedClass
    if not selected or selected == "" then
        return nil
    end

    local name = string.lower(selected)

    if string.find(name, "tank", 1, true) or string.find(name, "protection", 1, true) then
        return "tank"
    end
    if string.find(name, "healer", 1, true) or string.find(name, "holy", 1, true) or string.find(name, "restoration", 1, true) or string.find(name, "discipline", 1, true) then
        return "healer"
    end
    if string.find(name, "ranged", 1, true) or string.find(name, "hunter", 1, true) then
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

local function CE_BuildGroupItems(entries, getItemIdByName, getTotalCount, getGroupEntry)
    local items = {}
    if entries and type(entries) == "table" then
        for j = 1, table.getn(entries) do
            local entry = entries[j]
            local names, required = getGroupEntry(entry)
            for k = 1, table.getn(names) do
                local itemName = names[k]
                local itemId = getItemIdByName(itemName)
                local totalCount = itemId and getTotalCount(itemId) or 0
                table.insert(items, {
                    id = itemId,
                    name = itemName,
                    required = required,
                    totalCount = totalCount
                })
            end
        end
    end
    return items
end

local function CE_AddGroupHeader(scrollChild, index, lineHeight, labelText, parentFrame, groupKey, isCollapsed, statusColor, requiredTotal, ownedTotal, mode)
    local groupFrame = CreateFrame("Frame", "ConsumesManager_CEGroupFrame" .. index, scrollChild)
    groupFrame:SetWidth(scrollChild:GetWidth() - 10)
    groupFrame:SetHeight(lineHeight)
    groupFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
    groupFrame:Show()
    groupFrame:EnableMouse(true)

    local groupLabel = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    groupLabel:SetPoint("LEFT", groupFrame, "LEFT", 0, 0)
    if isCollapsed then
        local left = requiredTotal or 0
        local right = ownedTotal or 0
        if mode == "ownedmode" then
            left, right = right, left
        end
        groupLabel:SetText("[+] " .. (labelText or "") .. " (" .. left .. "/" .. right .. ")")
    else
        groupLabel:SetText("[-] " .. (labelText or ""))
    end
    groupLabel:SetJustifyH("LEFT")

    if isCollapsed and statusColor then
        if statusColor == "green" then
            groupLabel:SetTextColor(0, 1, 0)
        elseif statusColor == "orange" then
            groupLabel:SetTextColor(1, 0.4, 0)
        elseif statusColor == "red" then
            groupLabel:SetTextColor(1, 0, 0)
        end
    else
        groupLabel:SetTextColor(1, 1, 1)
    end

    groupFrame:SetScript("OnMouseDown", function()
        if not groupKey then
            return
        end
        ConsumesManager_Options.ceGroupCollapsed = ConsumesManager_Options.ceGroupCollapsed or {}
        ConsumesManager_Options.ceGroupCollapsed[groupKey] = not isCollapsed
        if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
            ConsumesManager_UpdatePresetsConsumables()
        end
    end)

    table.insert(parentFrame.presetsConsumables, {
        frame = groupFrame,
        label = groupLabel,
        isCategory = true
    })

    return index + 1
end

local function CE_AddItemRow(scrollChild, index, lineHeight, item, showUseButton, realmName, playerName, parentFrame)
    if not item then
        return index, false
    end

    local frame = CreateFrame("Frame", "ConsumesManager_PresetsConsumableFrame" .. index, scrollChild)
    frame:SetWidth(scrollChild:GetWidth() - 10)
    frame:SetHeight(lineHeight)
    frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
    frame:Show()
    frame:EnableMouse(true)

    local useButton = nil
    if showUseButton and item.id then
        useButton = CreateFrame("Button", "ConsumesManager_PresetsUseButton" .. index, frame, "UIPanelButtonTemplate")
        useButton:SetWidth(40)
        useButton:SetHeight(16)
        useButton:SetPoint("LEFT", frame, "LEFT", 0, 0)
        useButton:SetText("Use")
        useButton:SetScript("OnClick", function()
            local bag, slot = ConsumesManager_FindItemInBags(item.id)
            if bag and slot then
                UseContainerItem(bag, slot)
            else
                DEFAULT_CHAT_FRAME:AddMessage("Item not found in bags.")
            end
        end)
    end

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if showUseButton and useButton then
        label:SetPoint("LEFT", useButton, "RIGHT", 4, 0)
    else
        label:SetPoint("LEFT", frame, "LEFT", 0, 0)
    end
    local mode = ConsumesManager_Options and ConsumesManager_Options.ceConfigMode or "requiredmode"
    if mode == "ownedmode" then
        label:SetText(item.name .. " (" .. item.totalCount .. "/" .. item.required .. ")")
    else
        label:SetText(item.name .. " (" .. item.required .. "/" .. item.totalCount .. ")")
    end
    label:SetJustifyH("LEFT")

    if item.required and item.totalCount < item.required then
        if item.totalCount == 0 then
            label:SetTextColor(1, 0, 0)
        else
            label:SetTextColor(1, 0.4, 0)
        end
    else
        label:SetTextColor(0, 1, 0)
    end

    if item.id then
        frame:SetScript("OnEnter", function()
            ConsumesManager_ShowConsumableTooltip(item.id)
        end)
        frame:SetScript("OnLeave", function()
            if ConsumesManager_CustomTooltip and ConsumesManager_CustomTooltip.Hide then
                ConsumesManager_CustomTooltip:Hide()
            end
        end)
    end

    if useButton then
        local playerInventory = (ConsumesManager_Data[realmName] and ConsumesManager_Data[realmName][playerName] and ConsumesManager_Data[realmName][playerName].inventory) or {}
        local countInInventory = playerInventory[item.id] or 0
        if countInInventory > 0 then
            useButton:Enable()
        else
            useButton:Disable()
        end
    end

    table.insert(parentFrame.presetsConsumables, {
        frame = frame,
        label = label,
        useButton = useButton,
        id = item.id
    })

    return index + 1, true
end

function CE_UpdatePresetsConsumables()
    local parentFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[3]
    if not parentFrame then
        return
    end

    local scrollChild = parentFrame.scrollChild
    if not scrollChild then
        return
    end

    CE_ClearPresets(parentFrame)
    CE_TooltipAllowed = {}

    if not ConsumesManager_SelectedClass or ConsumesManager_SelectedClass == "" then
        parentFrame.messageLabel:SetText("|cffffffffSelect a |rClass|cffffffff to view CE groups.|r")
        parentFrame.messageLabel:Show()
        if parentFrame.orderByNameButton then
            parentFrame.orderByNameButton:Hide()
        end
        if parentFrame.orderByAmountButton then
            parentFrame.orderByAmountButton:Hide()
        end
        return
    end

    local data = RaidConsumables and RaidConsumables.Data
    if not data then
        parentFrame.messageLabel:SetText("|cffff0000CE data not loaded.|r")
        parentFrame.messageLabel:Show()
        if parentFrame.orderByNameButton then
            parentFrame.orderByNameButton:Hide()
        end
        if parentFrame.orderByAmountButton then
            parentFrame.orderByAmountButton:Hide()
        end
        return
    end

    parentFrame.messageLabel:Hide()

    local nameToId, lowerNameToId = CE_GetNameLookups()

    local function CE_GetItemIdByName(itemName)
        if not itemName then
            return nil
        end
        local id = nameToId[itemName]
        if id then
            return id
        end
        return lowerNameToId[string.lower(itemName)]
    end

    local function CE_GetGroupEntry(entry)
        if type(entry) ~= "table" then
            return { entry }, 1
        end
        local names = entry.names or entry
        local required = entry.required or 1
        if type(names) ~= "table" then
            names = { names }
        end
        return names, required
    end

    local realmName = GetRealmName()
    local playerName = UnitName("player")

    local totalCountCache = {}
    local function CE_GetTotalCount(itemId)
        if not itemId then
            return 0
        end
        if totalCountCache[itemId] ~= nil then
            return totalCountCache[itemId]
        end

        local totalCount = 0
        if ConsumesManager_Data and ConsumesManager_Data[realmName] and ConsumesManager_Options.Characters and type(ConsumesManager_Options.Characters) == "table" then
            for character, isSelected in pairs(ConsumesManager_Options.Characters) do
                if isSelected and ConsumesManager_Data[realmName][character] and type(ConsumesManager_Data[realmName][character]) == "table" then
                    local charInventory = ConsumesManager_Data[realmName][character].inventory or {}
                    local charBank = ConsumesManager_Data[realmName][character].bank or {}
                    local charMail = ConsumesManager_Data[realmName][character].mail or {}
                    totalCount = totalCount + (charInventory[itemId] or 0) + (charBank[itemId] or 0) + (charMail[itemId] or 0)
                end
            end
        end
        totalCountCache[itemId] = totalCount
        return totalCount
    end

    local role = CE_InferRoleFromSelectedClass()
    local selectedClass = ConsumesManager_SelectedClass
    local specGroups = CE_GetSpecGroups(data, selectedClass)
    local groups = CE_BuildGroups(data, role, specGroups, selectedClass)
    ConsumesManager_Options.ceGroupCollapsed = ConsumesManager_Options.ceGroupCollapsed or {}
    local collapsedStates = ConsumesManager_Options.ceGroupCollapsed

    local function CE_GetGroupStatus(items)
        local hasMissing = false
        local hasPartial = false
        for i = 1, table.getn(items) do
            local item = items[i]
            if item and item.required and item.totalCount < item.required then
                if item.totalCount == 0 then
                    hasMissing = true
                else
                    hasPartial = true
                end
            end
        end
        if hasMissing then
            return "red"
        end
        if hasPartial then
            return "orange"
        end
        return "green"
    end

    local function CE_GetGroupTotals(items)
        local requiredTotal = 0
        local ownedTotal = 0
        for i = 1, table.getn(items) do
            local item = items[i]
            if item then
                requiredTotal = requiredTotal + 1
                if item.required and item.totalCount and item.totalCount >= item.required then
                    ownedTotal = ownedTotal + 1
                end
            end
        end
        return requiredTotal, ownedTotal
    end

    local function CE_IsPrepared()
        local checkGroups = {}
        if data.MandatoryGroups and type(data.MandatoryGroups) == "table" then
            table.insert(checkGroups, data.MandatoryGroups)
        end
        if role and data.RoleMandatory and type(data.RoleMandatory[role]) == "table" then
            table.insert(checkGroups, data.RoleMandatory[role])
        end
        if specGroups and type(specGroups) == "table" then
            table.insert(checkGroups, specGroups)
        end

        local i = 1
        while checkGroups[i] do
            local entries = checkGroups[i]
            local j = 1
            while entries[j] do
                local names, required = CE_GetGroupEntry(entries[j])
                local k = 1
                while names[k] do
                    local itemId = CE_GetItemIdByName(names[k])
                    if not itemId then
                        return false
                    end
                    if CE_GetTotalCount(itemId) < required then
                        return false
                    end
                    k = k + 1
                end
                j = j + 1
            end
            i = i + 1
        end

        return true
    end

    local lineHeight = 18
    local index = 0
    local hasAnyVisibleItems = false
    local showUseButton = ConsumesManager_Options.showUseButton or false

    if table.getn(groups) > 0 then
        local prepared = CE_IsPrepared()
        index = index + 1
        local statusFrame = CreateFrame("Frame", "ConsumesManager_CEStatusFrame" .. index, scrollChild)
        statusFrame:SetWidth(scrollChild:GetWidth() - 10)
        statusFrame:SetHeight(lineHeight)
        statusFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
        statusFrame:Show()

        local statusLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        statusLabel:SetPoint("LEFT", statusFrame, "LEFT", 0, 0)
        statusLabel:SetText(prepared and "Fully prepared for Naxx" or "Not prepared for Naxx")
        statusLabel:SetJustifyH("LEFT")
        if prepared then
            statusLabel:SetTextColor(0, 1, 0)
        else
            statusLabel:SetTextColor(1, 0, 0)
        end

        table.insert(parentFrame.presetsConsumables, {
            frame = statusFrame,
            label = statusLabel,
            isCategory = true
        })

        index = index + 1
    end

    for i = 1, table.getn(groups) do
        local group = groups[i]
        local entries = group and group.entries or nil

        local items = CE_BuildGroupItems(entries, CE_GetItemIdByName, CE_GetTotalCount, CE_GetGroupEntry)

        if table.getn(items) > 0 then
            local groupKey = (ConsumesManager_SelectedClass or "") .. "|" .. (group.label or "") .. "|" .. tostring(i)
            local statusColor = CE_GetGroupStatus(items)
            local requiredTotal, ownedTotal = CE_GetGroupTotals(items)
            local isCollapsed = collapsedStates[groupKey] and true or false
            local mode = ConsumesManager_Options and ConsumesManager_Options.ceConfigMode or "requiredmode"
            index = CE_AddGroupHeader(scrollChild, index + 1, lineHeight, group.label or "", parentFrame, groupKey, isCollapsed, statusColor, requiredTotal, ownedTotal, mode)
            hasAnyVisibleItems = true
            if not isCollapsed then
                for j = 1, table.getn(items) do
                    local item = items[j]
                    if item and item.id then
                        CE_TooltipAllowed[item.id] = true
                    end
                    local nextIndex, wasVisible = CE_AddItemRow(scrollChild, index, lineHeight, item, showUseButton, realmName, playerName, parentFrame)
                    index = nextIndex
                    if wasVisible then
                        hasAnyVisibleItems = true
                    end
                end
            end
        end
    end

    if parentFrame.orderByNameButton then
        parentFrame.orderByNameButton:Hide()
    end
    if parentFrame.orderByAmountButton then
        parentFrame.orderByAmountButton:Hide()
    end

    scrollChild:SetHeight(index * lineHeight + 40)
    ConsumesManager_UpdatePresetsScrollBar()

    if not hasAnyVisibleItems then
        parentFrame.noItemsMessage = parentFrame.messageLabel
        parentFrame.noItemsMessage:SetText("|cffff0000No CE groups available.|r")
        parentFrame.noItemsMessage:Show()
    end
end
