-- ConsumesManager CE (Cold Embrace) extension

-- Table for required amounts per item ID (you can edit/fill this)
ConsumesManager_ColdEmbraceRequirements = ConsumesManager_ColdEmbraceRequirements or {}

-- Option flag: whether CE display is enabled
ConsumesManager_Options = ConsumesManager_Options or {}
ConsumesManager_Options.showColdEmbrace = ConsumesManager_Options.showColdEmbrace or false

local CE_InferRoleFromSelectedClass
local CE_UpdatePresetsConsumables
local CE_LogRoleInfo
local CE_InitClassDropdown
local CE_SetClassDropdownToCurrent
local CE_UpdateRaidsDropdown

local function CE_GetLastWord(text)
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

local function CE_GetFirstWord(text)
    if type(text) ~= "string" or text == "" then
        return ""
    end
    local spacePos = string.find(text, " ", 1, true)
    if spacePos then
        return string.sub(text, 1, spacePos - 1)
    end
    return text
end

local function CE_GetConfig()
    local cfg = _G and _G.CE_Config or nil
    if type(cfg) ~= "table" then
        return nil
    end
    return cfg
end

local function CE_BuildOriginalClassList()
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

local function CE_BuildTalentClassList()
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

CE_LogRoleInfo = function()
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

CE_SetClassDropdownToCurrent = function()
    if not ConsumesManager_Options.showColdEmbrace then
        return
    end

    local cfg = CE_GetConfig()

    local roleModule = RaidConsumables and RaidConsumables.Role
    if not roleModule or type(roleModule.Detect) ~= "function" then
        return
    end

    local classDropdown = _G["ConsumesManager_PresetsClassDropdown"]
    if not classDropdown then
        return
    end

    local role, info = roleModule.Detect()
    local classToken = info and info.class or nil
    local tabIndex = info and info.primaryTab or 0
    local tabName = (info and info.tabs and info.tabs[tabIndex]) or ""

    local className = (cfg.CLASS_DISPLAY and cfg.CLASS_DISPLAY[classToken or ""]) or ""
    local talentFirst = CE_GetFirstWord(tabName)
    if className == "" or talentFirst == "" then
        return
    end

    local label = talentFirst .. " " .. className
    ConsumesManager_SelectedClass = label

    local entries = CE_BuildTalentClassList()
    local selectedIndex = 0
    for i = 1, table.getn(entries) do
        if entries[i] == label then
            selectedIndex = i
            break
        end
    end

    local color = (cfg.CLASS_COLORS and cfg.CLASS_COLORS[className]) or "ffffff"
    if type(UIDropDownMenu_SetSelectedID) == "function" and selectedIndex > 0 then
        UIDropDownMenu_SetSelectedID(classDropdown, selectedIndex)
    end
    if type(UIDropDownMenu_SetText) == "function" then
        UIDropDownMenu_SetText("|cff" .. color .. label .. "|r", classDropdown)
    end

    ConsumesManager_UpdatePresetsConsumables()
end

local function CE_SetRaidDropdownToNaxxramas()
    if not ConsumesManager_Options.showColdEmbrace then
        return
    end

    ConsumesManager_SelectedRaid = "Naxxramas"
    CE_UpdateRaidsDropdown()
end

CE_UpdateRaidsDropdown = function()
    if not ConsumesManager_Options.showColdEmbrace then
        return
    end

    local cfg = CE_GetConfig()
    if not cfg then
        return
    end

    local raidDropdown = _G["ConsumesManager_PresetsRaidDropdown"]
    if not raidDropdown then
        return
    end

    UIDropDownMenu_ClearAll(raidDropdown)
    UIDropDownMenu_Initialize(raidDropdown, function()
        local selectedIndex = 0
        local desired = ConsumesManager_SelectedRaid or "Naxxramas"
        local raids = cfg.ORDERED_RAIDS or {}
        for i = 1, table.getn(raids) do
            local raidName = raids[i]
            local raidIndex = i
            local info = {}
            info.text = raidName
            info.func = function()
                UIDropDownMenu_SetSelectedID(raidDropdown, raidIndex)
                ConsumesManager_SelectedRaid = raidName
                ConsumesManager_UpdatePresetsConsumables()
            end
            UIDropDownMenu_AddButton(info)
            if raidName == desired then
                selectedIndex = i
            end
        end

        if selectedIndex > 0 then
            UIDropDownMenu_SetSelectedID(raidDropdown, selectedIndex)
            if type(UIDropDownMenu_SetText) == "function" then
                UIDropDownMenu_SetText(raids[selectedIndex], raidDropdown)
            end
            ConsumesManager_SelectedRaid = raids[selectedIndex]
        else
            UIDropDownMenu_SetSelectedID(raidDropdown, 0)
            if type(UIDropDownMenu_SetText) == "function" then
                UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)
            end
            ConsumesManager_SelectedRaid = nil
        end
    end)
end

CE_InitClassDropdown = function(classDropdown)
    local useCE = ConsumesManager_Options.showColdEmbrace
    local entries = useCE and CE_BuildTalentClassList() or CE_BuildOriginalClassList()
    local cfg = CE_GetConfig()
    if useCE and not cfg then
        return
    end

    local idx = 1
    while entries[idx] do
        local cName = entries[idx]
        local cIndex = idx
        local info = {}
        local lastWord = CE_GetLastWord(cName)
        local color = (cfg and cfg.CLASS_COLORS and cfg.CLASS_COLORS[lastWord]) or "ffffff"
        info.text = "|cff" .. color .. cName .. "|r"
        info.func = function()
            UIDropDownMenu_SetSelectedID(classDropdown, cIndex)
            ConsumesManager_SelectedClass = cName
            if not useCE and type(ConsumesManager_UpdateRaidsDropdown) == "function" then
                ConsumesManager_UpdateRaidsDropdown()
            end
            ConsumesManager_UpdatePresetsConsumables()
        end
        UIDropDownMenu_AddButton(info)
        idx = idx + 1
    end
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

CE_InferRoleFromSelectedClass = function()
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

CE_UpdatePresetsConsumables = function()
    local parentFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[3]
    if not parentFrame then
        return
    end

    local scrollChild = parentFrame.scrollChild
    if not scrollChild then
        return
    end

    CE_ClearPresets(parentFrame)

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

    local nameToId = consumablesNameToID or {}
    local lowerNameToId = {}
    for itemName, itemId in pairs(nameToId) do
        lowerNameToId[string.lower(itemName)] = itemId
    end

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

    local function CE_GetTotalCount(itemId)
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
        return totalCount
    end

    local groups = {}
    if data.MandatoryGroups and type(data.MandatoryGroups) == "table" and table.getn(data.MandatoryGroups) > 0 then
        table.insert(groups, { label = "Mandatory", entries = data.MandatoryGroups })
    end
    if data.OptionalGroups and type(data.OptionalGroups) == "table" and table.getn(data.OptionalGroups) > 0 then
        table.insert(groups, { label = "Optional", entries = data.OptionalGroups })
    end

    local role = CE_InferRoleFromSelectedClass()
    if role and data.RoleMandatory and data.RoleMandatory[role] and type(data.RoleMandatory[role]) == "table" and table.getn(data.RoleMandatory[role]) > 0 then
        table.insert(groups, { label = "Role: " .. role, entries = data.RoleMandatory[role] })
    end

    local lineHeight = 18
    local index = 0
    local hasAnyVisibleItems = false
    local showUseButton = ConsumesManager_Options.showUseButton or false

    for i = 1, table.getn(groups) do
        local group = groups[i]
        local entries = group and group.entries or nil

        local items = {}
        if entries and type(entries) == "table" then
            for j = 1, table.getn(entries) do
                local entry = entries[j]
                local names, required = CE_GetGroupEntry(entry)
                for k = 1, table.getn(names) do
                    local itemName = names[k]
                    local itemId = CE_GetItemIdByName(itemName)
                    local totalCount = itemId and CE_GetTotalCount(itemId) or 0
                    table.insert(items, {
                        id = itemId,
                        name = itemName,
                        required = required,
                        totalCount = totalCount
                    })
                end
            end
        end

        if table.getn(items) > 0 then
            index = index + 1
            local groupFrame = CreateFrame("Frame", "ConsumesManager_CEGroupFrame" .. index, scrollChild)
            groupFrame:SetWidth(scrollChild:GetWidth() - 10)
            groupFrame:SetHeight(lineHeight)
            groupFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
            groupFrame:Show()

            local groupLabel = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            groupLabel:SetPoint("LEFT", groupFrame, "LEFT", 0, 0)
            groupLabel:SetText(group.label or "")
            groupLabel:SetJustifyH("LEFT")

            table.insert(parentFrame.presetsConsumables, {
                frame = groupFrame,
                label = groupLabel,
                isCategory = true
            })

            index = index + 1

            for j = 1, table.getn(items) do
                local item = items[j]
                if item then
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
                    label:SetText(item.name .. " (" .. item.required .. "/" .. item.totalCount .. ")")
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

                    index = index + 1
                    hasAnyVisibleItems = true
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


local function CE_CreateSettingsCheckbox(parentFrame)
    if not parentFrame then
        return
    end

    local scrollChild = parentFrame.scrollChild
    if not scrollChild then
        return
    end

    local existingFrame = parentFrame.CESettingsFrame
    local existingCheckbox = parentFrame.CESettingsCheckbox

    local function FindChildByName(parent, name)
        if not parent or not name then
            return nil
        end
        local children = { parent:GetChildren() }
        for i = 1, table.getn(children) do
            local child = children[i]
            if child and child.GetName and child:GetName() == name then
                return child
            end
        end
        return nil
    end

    local anchor = FindChildByName(scrollChild, "ConsumesManager_ShowUseButtonFrame")
        or FindChildByName(scrollChild, "ConsumesManager_EnableCategoriesFrame")
        or scrollChild

    local checkboxFrame = existingFrame or CreateFrame("Frame", nil, scrollChild)
    checkboxFrame:SetParent(scrollChild)
    checkboxFrame:ClearAllPoints()
    checkboxFrame:SetWidth(WindowWidth - 10)
    checkboxFrame:SetHeight(18)

    if anchor and anchor ~= scrollChild then
        checkboxFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    else
        checkboxFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -20)
    end

    checkboxFrame:EnableMouse(true)

    local checkbox = existingCheckbox or CreateFrame("CheckButton", nil, checkboxFrame)
    checkbox:SetParent(checkboxFrame)
    checkbox:ClearAllPoints()
    checkbox:SetWidth(16)
    checkbox:SetHeight(16)
    checkbox:SetPoint("LEFT", checkboxFrame, "LEFT", 0, 0)
    checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkbox:SetChecked(ConsumesManager_Options.showColdEmbrace)

    local label = checkboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText("Enable Cold Embrace extension")
    label:SetJustifyH("LEFT")

    checkbox:SetScript("OnClick", function()
        local checked = checkbox:GetChecked()
        ConsumesManager_Options.showColdEmbrace = checked and true or false
        if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
            ConsumesManager_UpdatePresetsConsumables()
        end
    end)

    checkboxFrame:SetScript("OnMouseDown", function()
        checkbox:Click()
    end)

    parentFrame.CESettingsFrame = checkboxFrame
    parentFrame.CESettingsCheckbox = checkbox

    if type(ConsumesManager_UpdateSettingsScrollBar) == "function" then
        ConsumesManager_UpdateSettingsScrollBar()
    end
end

-- Wrap the original functions after they are defined
local orig_CreateSettingsContent = ConsumesManager_CreateSettingsContent
if type(orig_CreateSettingsContent) == "function" then
    function ConsumesManager_CreateSettingsContent(parentFrame)
        orig_CreateSettingsContent(parentFrame)
        CE_CreateSettingsCheckbox(parentFrame)
    end
end

local orig_UpdatePresetsConsumables = ConsumesManager_UpdatePresetsConsumables
if type(orig_UpdatePresetsConsumables) == "function" then
    function ConsumesManager_UpdatePresetsConsumables()
        if ConsumesManager_Options.showColdEmbrace then
            CE_UpdatePresetsConsumables()
        else
            orig_UpdatePresetsConsumables()
        end
        if not ConsumesManager_Options.showColdEmbrace and type(CE_UpdatePresetLabels) == "function" then
            CE_UpdatePresetLabels()
        end
    end
end

local orig_CreatePresetsContent = ConsumesManager_CreatePresetsContent
if type(orig_CreatePresetsContent) == "function" then
    function ConsumesManager_CreatePresetsContent(parentFrame)
        orig_CreatePresetsContent(parentFrame)
        local classDropdown = _G["ConsumesManager_PresetsClassDropdown"]
        if classDropdown and type(UIDropDownMenu_Initialize) == "function" then
            UIDropDownMenu_Initialize(classDropdown, function()
                CE_InitClassDropdown(classDropdown)
            end)
        end
    end
end

local orig_UpdateRaidsDropdown = ConsumesManager_UpdateRaidsDropdown
if type(orig_UpdateRaidsDropdown) == "function" then
    function ConsumesManager_UpdateRaidsDropdown()
        if ConsumesManager_Options.showColdEmbrace then
            CE_UpdateRaidsDropdown()
        else
            orig_UpdateRaidsDropdown()
        end
    end
end

local orig_ShowMainWindow = ConsumesManager_ShowMainWindow
if type(orig_ShowMainWindow) == "function" then
    function ConsumesManager_ShowMainWindow()
        orig_ShowMainWindow()
        CE_LogRoleInfo()
        CE_SetClassDropdownToCurrent()
        CE_SetRaidDropdownToNaxxramas()
    end
end
