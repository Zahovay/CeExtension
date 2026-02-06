-- ConsumesManager CE (Cold Embrace) extension

-- Table for required amounts per item ID (you can edit/fill this)
ConsumesManager_ColdEmbraceRequirements = ConsumesManager_ColdEmbraceRequirements or {}

-- Option flag: whether CE display is enabled
ConsumesManager_Options = ConsumesManager_Options or {}
ConsumesManager_Options.showColdEmbrace = ConsumesManager_Options.showColdEmbrace or false

local CE_InferRoleFromSelectedClass
local CE_BuildRequiredById
local CE_UpdatePresetsConsumables
local CE_LogRoleInfo

local function CE_UpdatePresetLabels()
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs or not ConsumesManager_MainFrame.tabs[3] then
        return
    end

    local parentFrame = ConsumesManager_MainFrame.tabs[3]
    local realmName = GetRealmName and GetRealmName() or nil
    local playerName = UnitName and UnitName("player") or nil

    if not parentFrame.presetsConsumables or not ConsumesManager_Data or not realmName then
        return
    end

    local function GetOwnAmount(itemID)
        local total = 0
        if ConsumesManager_Data[realmName] and ConsumesManager_Options.Characters and type(ConsumesManager_Options.Characters) == "table" then
            for character, isSelected in pairs(ConsumesManager_Options.Characters) do
                if isSelected and ConsumesManager_Data[realmName][character] and type(ConsumesManager_Data[realmName][character]) == "table" then
                    local charInventory = ConsumesManager_Data[realmName][character].inventory or {}
                    local charBank      = ConsumesManager_Data[realmName][character].bank or {}
                    local charMail      = ConsumesManager_Data[realmName][character].mail or {}
                    total = total + (charInventory[itemID] or 0) + (charBank[itemID] or 0) + (charMail[itemID] or 0)
                end
            end
        end
        return total
    end

    local useCE = ConsumesManager_Options.showColdEmbrace
    local requiredById = nil
    if useCE then
        local role = CE_InferRoleFromSelectedClass()
        requiredById = CE_BuildRequiredById(role)
    end

    for _, info in ipairs(parentFrame.presetsConsumables) do
        if info.label and info.id then
            local itemID = info.id
            local text = info.label:GetText() or ""
            local name = text
            local nameEnd = string.find(text, " %(")
            if nameEnd then
                name = string.sub(text, 1, nameEnd - 1)
            end

            local ownAmount = GetOwnAmount(itemID)
            if useCE then
                local requiredAmount = 0
                if requiredById and requiredById[itemID] then
                    requiredAmount = requiredById[itemID]
                end
                info.label:SetText(string.format("%s (%d/%d)", name, requiredAmount, ownAmount))
                if info.label.SetTextColor then
                    if ownAmount < requiredAmount then
                        info.label:SetTextColor(1, 0, 0)
                    else
                        info.label:SetTextColor(0, 1, 0)
                    end
                end
            else
                info.label:SetText(string.format("%s (%d)", name, ownAmount))
            end
        end
    end
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

    if string.find(name, "tank", 1, true) then
        return "tank"
    end
    if string.find(name, "healer", 1, true) or string.find(name, "holy", 1, true) or string.find(name, "restoration", 1, true) or string.find(name, "discipline", 1, true) then
        return "healer"
    end
    if string.find(name, "ranged", 1, true) or string.find(name, "hunter", 1, true) then
        return "ranged"
    end
    if string.find(name, "mage", 1, true) or string.find(name, "warlock", 1, true) or string.find(name, "shadow priest", 1, true) or string.find(name, "elemental", 1, true) or string.find(name, "moonkin", 1, true) then
        return "caster"
    end
    if string.find(name, "rogue", 1, true) or string.find(name, "warrior", 1, true) or string.find(name, "enhancement", 1, true) or string.find(name, "cat", 1, true) or string.find(name, "melee", 1, true) or string.find(name, "fury", 1, true) or string.find(name, "retribution", 1, true) then
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

    local labels = {}
    if data.MandatoryGroups and type(data.MandatoryGroups) == "table" and table.getn(data.MandatoryGroups) > 0 then
        table.insert(labels, "Mandatory")
    end
    if data.OptionalGroups and type(data.OptionalGroups) == "table" and table.getn(data.OptionalGroups) > 0 then
        table.insert(labels, "Optional")
    end

    local role = CE_InferRoleFromSelectedClass()
    if role and data.RoleMandatory and data.RoleMandatory[role] and type(data.RoleMandatory[role]) == "table" and table.getn(data.RoleMandatory[role]) > 0 then
        table.insert(labels, "Role: " .. role)
    end

    local lineHeight = 18
    local index = 0

    for i = 1, table.getn(labels) do
        local labelText = labels[i]
        if labelText then
            index = index + 1
            local frame = CreateFrame("Frame", "ConsumesManager_CEGroupFrame" .. index, scrollChild)
            frame:SetWidth(scrollChild:GetWidth() - 10)
            frame:SetHeight(lineHeight)
            frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
            frame:Show()

            local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            label:SetPoint("LEFT", frame, "LEFT", 0, 0)
            label:SetText(labelText)
            label:SetJustifyH("LEFT")

            table.insert(parentFrame.presetsConsumables, {
                frame = frame,
                label = label,
                isCategory = true
            })
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

    if index == 0 then
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
        if not ConsumesManager_Options.showColdEmbrace then
            CE_UpdatePresetLabels()
        end
    end
end

local orig_ShowMainWindow = ConsumesManager_ShowMainWindow
if type(orig_ShowMainWindow) == "function" then
    function ConsumesManager_ShowMainWindow()
        orig_ShowMainWindow()
        CE_LogRoleInfo()
    end
end
