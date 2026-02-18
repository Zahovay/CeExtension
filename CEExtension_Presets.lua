-- CE presets rendering

CE_TooltipAllowed = CE_TooltipAllowed or {}

local CE_PRESETS_SCROLLFRAME_TOP_Y_DEFAULT = -40
local CE_PRESETS_SCROLLFRAME_TOP_Y_CE = -20

function CE_ApplyPresetsTabSpacing(enabled)
    local scrollFrame = getglobal("ConsumesManager_PresetsScrollFrame")
    if not scrollFrame or type(scrollFrame.ClearAllPoints) ~= "function" then
        return
    end

    local classDropdown = getglobal("ConsumesManager_PresetsClassDropdown")
    if not classDropdown then
        return
    end

    local parentFrame = scrollFrame:GetParent()
    if not parentFrame then
        return
    end

    local topY = enabled and CE_PRESETS_SCROLLFRAME_TOP_Y_CE or CE_PRESETS_SCROLLFRAME_TOP_Y_DEFAULT

    scrollFrame:ClearAllPoints()
    scrollFrame:SetPoint("TOPLEFT", classDropdown, "BOTTOMLEFT", -135, topY)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -25, -5)
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
                if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
                    DEFAULT_CHAT_FRAME:AddMessage("Item not found in bags.")
                end
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
        label:SetText((item.name or "") .. " (" .. (item.totalCount or 0) .. "/" .. (item.required or 0) .. ")")
    else
        label:SetText((item.name or "") .. " (" .. (item.required or 0) .. "/" .. (item.totalCount or 0) .. ")")
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
        local playerInventory = (ConsumesManager_Data and ConsumesManager_Data[realmName] and ConsumesManager_Data[realmName][playerName] and ConsumesManager_Data[realmName][playerName].inventory) or {}
        local countInInventory = (item.id and playerInventory[item.id]) or 0
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
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.IsShown or not ConsumesManager_MainFrame:IsShown() then
        return
    end

    local parentFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[3]
    if not parentFrame then
        return
    end

    if type(ConsumesManager_Options) == "table" then
        CE_ApplyPresetsTabSpacing(ConsumesManager_Options.showColdEmbrace and true or false)
    end

    local scrollChild = parentFrame.scrollChild
    if not scrollChild then
        return
    end

    CE_ClearPresets(parentFrame)
    CE_TooltipAllowed = {}

    local raidName = (type(CE_NormalizeRaidName) == "function" and CE_NormalizeRaidName(ConsumesManager_SelectedRaid)) or (ConsumesManager_SelectedRaid or "Naxxramas")
    local selectedClass = ConsumesManager_SelectedClass
    if type(selectedClass) ~= "string" or selectedClass == "" then
        if parentFrame.messageLabel then
            parentFrame.messageLabel:SetText("|cffff0000Select a class in the Presets tab.|r")
            parentFrame.messageLabel:Show()
        end
        if parentFrame.orderByNameButton then parentFrame.orderByNameButton:Hide() end
        if parentFrame.orderByAmountButton then parentFrame.orderByAmountButton:Hide() end
        return
    end

    local preset = (type(CE_GetPresetEntry) == "function" and CE_GetPresetEntry(selectedClass, raidName)) or nil

    if type(preset) ~= "table" or type(preset.id) ~= "table" then
        if parentFrame.messageLabel then
            parentFrame.messageLabel:SetText("|cffff0000No CE preset found for this class/raid.|r")
            parentFrame.messageLabel:Show()
        end
        if parentFrame.orderByNameButton then parentFrame.orderByNameButton:Hide() end
        if parentFrame.orderByAmountButton then parentFrame.orderByAmountButton:Hide() end
        return
    end

    if parentFrame.messageLabel then
        parentFrame.messageLabel:Hide()
    end

    local function CE_GetName(itemId)
        if type(consumablesList) == "table" then
            local name = consumablesList[itemId]
            if type(name) == "string" and name ~= "" then
                return name
            end
        end
        return nil
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

    ConsumesManager_Options.ceGroupCollapsed = ConsumesManager_Options.ceGroupCollapsed or {}
    local collapsedStates = ConsumesManager_Options.ceGroupCollapsed

    local function CE_BuildPresetItemsForStatus(status)
        local items = {}
        local req = type(preset.req) == "table" and preset.req or {}
        for i = 1, table.getn(preset.id) do
            local itemId = preset.id[i]
            if type(itemId) == "number" then
                local entry = req[itemId]
                local entryStatus = (entry and entry.status) or "mandatory"
                if type(entryStatus) == "string" then
                    entryStatus = string.lower(entryStatus)
                else
                    entryStatus = "mandatory"
                end
                if entryStatus == status then
                    local required = entry and tonumber(entry.amount) or 0
                    if required < 0 then required = 0 end
                    local name = CE_GetName(itemId) or ("Item " .. tostring(itemId))
                    local totalCount = CE_GetTotalCount(itemId)
                    table.insert(items, { id = itemId, name = name, required = required, totalCount = totalCount })
                end
            end
        end
        table.sort(items, function(a, b)
            return (a.name or "") < (b.name or "")
        end)
        return items
    end

    local function CE_GetGroupStatus(items)
        local hasMissing = false
        local hasPartial = false
        for i = 1, table.getn(items) do
            local item = items[i]
            if item and item.required and item.required > 0 and item.totalCount < item.required then
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
                if item.required and item.totalCount and item.required > 0 and item.totalCount >= item.required then
                    ownedTotal = ownedTotal + 1
                end
            end
        end
        return requiredTotal, ownedTotal
    end

    local function CE_IsPrepared(items)
        if type(items) ~= "table" then
            return true
        end
        for i = 1, table.getn(items) do
            local item = items[i]
            if item and item.required and item.required > 0 and item.totalCount < item.required then
                return false
            end
        end
        return true
    end

    local lineHeight = 18
    local index = 0
    local hasAnyVisibleItems = false
    local showUseButton = ConsumesManager_Options.showUseButton or false

    local mandatoryItems = CE_BuildPresetItemsForStatus("mandatory")
    local optionalItems = CE_BuildPresetItemsForStatus("optional")

    if table.getn(mandatoryItems) > 0 or table.getn(optionalItems) > 0 then
        local mandatoryPrepared = CE_IsPrepared(mandatoryItems)
        local optionalPrepared = CE_IsPrepared(optionalItems)

        local statusText = "Not prepared for " .. raidName
        local statusColor = "red"
        if mandatoryPrepared then
            if optionalPrepared then
                statusText = "Fully prepared for " .. raidName
                statusColor = "green"
            else
                statusText = "Mostly prepared for " .. raidName
                statusColor = "orange"
            end
        end

        index = index + 1
        local statusFrame = CreateFrame("Frame", "ConsumesManager_CEStatusFrame" .. index, scrollChild)
        statusFrame:SetWidth(scrollChild:GetWidth() - 10)
        statusFrame:SetHeight(lineHeight)
        statusFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
        statusFrame:Show()

        local statusLabel = statusFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        statusLabel:SetPoint("LEFT", statusFrame, "LEFT", 0, 1)
        statusLabel:SetText(statusText)
        statusLabel:SetJustifyH("LEFT")
        if statusColor == "green" then
            statusLabel:SetTextColor(0, 1, 0)
        elseif statusColor == "orange" then
            statusLabel:SetTextColor(1, 0.4, 0)
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

    local function renderGroup(label, items, groupIndex)
        if table.getn(items) == 0 then
            return
        end

        local groupKey = (raidName or "") .. "|" .. (label or "") .. "|" .. tostring(groupIndex)
        local statusColor = CE_GetGroupStatus(items)
        local requiredTotal, ownedTotal = CE_GetGroupTotals(items)
        local isCollapsed = collapsedStates[groupKey] and true or false
        local mode = ConsumesManager_Options and ConsumesManager_Options.ceConfigMode or "requiredmode"
        index = CE_AddGroupHeader(scrollChild, index + 1, lineHeight, label, parentFrame, groupKey, isCollapsed, statusColor, requiredTotal, ownedTotal, mode)
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

    renderGroup("Mandatory", mandatoryItems, 1)
    renderGroup("Optional", optionalItems, 2)

    if parentFrame.orderByNameButton then
        parentFrame.orderByNameButton:Hide()
    end
    if parentFrame.orderByAmountButton then
        parentFrame.orderByAmountButton:Hide()
    end

    scrollChild:SetHeight(index * lineHeight + 40)
    if type(ConsumesManager_UpdatePresetsScrollBar) == "function" then
        ConsumesManager_UpdatePresetsScrollBar()
    end

    if not hasAnyVisibleItems then
        if parentFrame.messageLabel then
            parentFrame.noItemsMessage = parentFrame.messageLabel
            parentFrame.noItemsMessage:SetText("|cffff0000No CE groups available.|r")
            parentFrame.noItemsMessage:Show()
        end
    end
end
