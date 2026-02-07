-- CE UI helpers

local function CE_GetFooterTextRegion()
    if not ConsumesManager_MainFrame or type(ConsumesManager_MainFrame.GetRegions) ~= "function" then
        return nil
    end

    local regions = { ConsumesManager_MainFrame:GetRegions() }
    for i = 1, table.getn(regions) do
        local region = regions[i]
        if region and region.GetObjectType and region:GetObjectType() == "FontString" and region.GetText then
            local text = region:GetText()
            if type(text) == "string" and string.find(text, "Made by Horyoshi", 1, true) then
                return region
            end
        end
    end

    return nil
end

function CE_UpdateFooterText()
    local footerText = CE_GetFooterTextRegion()
    if not footerText then
        return
    end

    local baseText = "Made by Horyoshi (v" .. GetAddOnMetadata("ConsumesManager", "Version") .. ")"
    if ConsumesManager_Options.showColdEmbrace then
        footerText:SetText(baseText .. " CeExtension by Zahobab (0.1.0)")
    else
        footerText:SetText(baseText)
    end
end

local function CE_SetRaidDropdownToDefault()
    local raidDropdown = _G and _G["ConsumesManager_PresetsRaidDropdown"]
    if not raidDropdown then
        return
    end
    ConsumesManager_SelectedRaid = nil
    if type(UIDropDownMenu_SetSelectedID) == "function" then
        UIDropDownMenu_SetSelectedID(raidDropdown, 0)
    end
    if type(UIDropDownMenu_SetText) == "function" then
        UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)
    end
end

function CE_ResetDropdownSelections()
    local classDropdown = _G and _G["ConsumesManager_PresetsClassDropdown"]
    if classDropdown then
        ConsumesManager_SelectedClass = nil
        if type(UIDropDownMenu_SetSelectedID) == "function" then
            UIDropDownMenu_SetSelectedID(classDropdown, 0)
        end
        if type(UIDropDownMenu_SetText) == "function" then
            UIDropDownMenu_SetText("Select |cffffff00Class|r", classDropdown)
        end
    end
    CE_SetRaidDropdownToDefault()
end

function CE_SetClassDropdownToCurrent()
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

function CE_SetRaidDropdownToNaxxramas()
    if not ConsumesManager_Options.showColdEmbrace then
        return
    end

    ConsumesManager_SelectedRaid = "Naxxramas"
    CE_UpdateRaidsDropdown()
end

function CE_UpdateRaidsDropdown()
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

function CE_InitClassDropdown(classDropdown)
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

function CE_CreateSettingsCheckbox(parentFrame)
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
        local wasEnabled = ConsumesManager_Options.showColdEmbrace and true or false

        if checked and not wasEnabled then
            ConsumesManager_Options.showColdEmbrace = true
            CE_InjectItemlist()
            CE_SetClassDropdownToCurrent()
            CE_SetRaidDropdownToNaxxramas()
            CE_UpdateFooterText()
        elseif not checked and wasEnabled then
            ConsumesManager_Options.showColdEmbrace = false
            CE_ResetDropdownSelections()
            CE_RemoveInjectedItemlist()
            CE_UpdateFooterText()
        else
            ConsumesManager_Options.showColdEmbrace = checked and true or false
            CE_UpdateFooterText()
        end
        if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
            ConsumesManager_UpdatePresetsConsumables()
        end
        CE_UpdateCETabEnabledState()
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

local function CE_CreateCETabCheckbox(parentFrame)
    if not parentFrame then
        return
    end

    local existingFrame = parentFrame.CECheckboxFrame
    local existingCheckbox = parentFrame.CECheckbox

    local checkboxFrame = existingFrame or CreateFrame("Frame", nil, parentFrame)
    checkboxFrame:SetParent(parentFrame)
    checkboxFrame:ClearAllPoints()
    checkboxFrame:SetWidth(WindowWidth - 60)
    checkboxFrame:SetHeight(18)
    checkboxFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -50)
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
    label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
    label:SetText("Enable Cold Embrace extension")
    label:SetJustifyH("LEFT")

    checkbox:SetScript("OnClick", function()
        local checked = checkbox:GetChecked()
        local wasEnabled = ConsumesManager_Options.showColdEmbrace and true or false

        if checked and not wasEnabled then
            ConsumesManager_Options.showColdEmbrace = true
            CE_InjectItemlist()
            CE_SetClassDropdownToCurrent()
            CE_SetRaidDropdownToNaxxramas()
            CE_UpdateFooterText()
        elseif not checked and wasEnabled then
            ConsumesManager_Options.showColdEmbrace = false
            CE_ResetDropdownSelections()
            CE_RemoveInjectedItemlist()
            CE_UpdateFooterText()
        else
            ConsumesManager_Options.showColdEmbrace = checked and true or false
            CE_UpdateFooterText()
        end
        if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
            ConsumesManager_UpdatePresetsConsumables()
        end
    end)

    checkboxFrame:SetScript("OnMouseDown", function()
        checkbox:Click()
    end)

    parentFrame.CECheckboxFrame = checkboxFrame
    parentFrame.CECheckbox = checkbox
end

local function CE_CreateCETabButton(tabIndex, xOffset, tooltipText)
    if not ConsumesManager_MainFrame then
        return nil
    end

    local tab = CreateFrame("Button", "ConsumesManager_MainFrameTabCE", ConsumesManager_MainFrame)
    tab:SetWidth(36)
    tab:SetHeight(36)
    tab:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", xOffset, -30)
    tab:SetNormalTexture("Interface\\ItemsFrame\\UI-ItemsFrame-InActiveTab")

    local icon = tab:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Buttons\\WHITE8x8")
    icon:SetVertexColor(1, 1, 1, 0)
    icon:SetWidth(34)
    icon:SetHeight(34)
    icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab.icon = icon

    local iconText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    iconText:SetPoint("CENTER", tab, "CENTER", 0, 0)
    iconText:SetText("CE")
    iconText:SetTextColor(1, 0.85, 0.2)
    tab.iconText = iconText

    local hoverTexture = tab:CreateTexture(nil, "HIGHLIGHT")
    hoverTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    hoverTexture:SetBlendMode("ADD")
    hoverTexture:SetAllPoints(tab)
    tab.hoverTexture = hoverTexture

    local activeHighlight = tab:CreateTexture(nil, "OVERLAY")
    activeHighlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    activeHighlight:SetBlendMode("ADD")
    activeHighlight:SetAllPoints(tab)
    activeHighlight:SetWidth(36)
    activeHighlight:SetHeight(36)
    activeHighlight:Hide()
    tab.activeHighlight = activeHighlight

    tab.tooltipText = tooltipText
    tab:SetScript("OnEnter", function()
        if type(ShowTooltip) == "function" then
            ShowTooltip(tab, tab.tooltipText)
        end
    end)
    tab:SetScript("OnLeave", function()
        if type(HideTooltip) == "function" then
            HideTooltip()
        end
    end)

    tab.isEnabled = true
    tab.originalOnClick = function()
        ConsumesManager_ShowTab(tabIndex)
    end
    tab:SetScript("OnClick", tab.originalOnClick)

    return tab
end

local function CE_CreateCETabContent(tabIndex)
    if not ConsumesManager_MainFrame then
        return nil
    end

    local content = CreateFrame("Frame", nil, ConsumesManager_MainFrame)
    content:SetWidth(WindowWidth - 50)
    content:SetHeight(380)
    content:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 30, -80)
    content:Hide()

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -5)
    title:SetText("|cffffff00Cold Embrace|r")
    content.CETitle = title

    local subtitle = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("CE tab content goes here.")
    content.CESubtitle = subtitle

    CE_CreateCETabCheckbox(content)

    return content
end

local function CE_UpdateCETabEnabledState()
    local enabled = ConsumesManager_Options.showColdEmbrace and true or false
    local mainFrame = ConsumesManager_MainFrame
    if not mainFrame then
        return
    end

    local tab = mainFrame.CETabButton
    if tab and tab.iconText then
        if enabled then
            tab.iconText:SetTextColor(1, 0.85, 0.2)
        else
            tab.iconText:SetTextColor(0.6, 0.6, 0.6)
        end
    end

    local content = mainFrame.CETabContent
    if content then
        if content.CETitle then
            if enabled then
                content.CETitle:SetTextColor(1, 0.85, 0.2)
            else
                content.CETitle:SetTextColor(0.6, 0.6, 0.6)
            end
        end
        if content.CESubtitle then
            if enabled then
                content.CESubtitle:SetTextColor(1, 1, 1)
            else
                content.CESubtitle:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end
end

function CE_CreateCETab()
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs or not ConsumesManager_Tabs then
        return
    end

    local tabIndex = 6
    local xOffset = 230
    local tooltipText = "Cold Embrace"

    if ConsumesManager_MainFrame.CETabButton and ConsumesManager_MainFrame.CETabContent then
        ConsumesManager_MainFrame.CETabButton:Show()
        ConsumesManager_MainFrame.CETabContent:Hide()
        ConsumesManager_Tabs[tabIndex] = ConsumesManager_MainFrame.CETabButton
        ConsumesManager_MainFrame.tabs[tabIndex] = ConsumesManager_MainFrame.CETabContent
        CE_UpdateCETabEnabledState()
        return
    end

    local tab = CE_CreateCETabButton(tabIndex, xOffset, tooltipText)
    local content = CE_CreateCETabContent(tabIndex)
    if not tab or not content then
        return
    end

    ConsumesManager_Tabs[tabIndex] = tab
    ConsumesManager_MainFrame.tabs[tabIndex] = content
    ConsumesManager_MainFrame.CETabButton = tab
    ConsumesManager_MainFrame.CETabContent = content
    CE_UpdateCETabEnabledState()
end

function CE_RemoveCETab()
    local mainFrame = ConsumesManager_MainFrame
    if not mainFrame then
        return
    end

    local tabIndex = 6
    local tab = mainFrame.CETabButton
    local content = mainFrame.CETabContent

    if content and content.IsShown and content:IsShown() then
        ConsumesManager_ShowTab(1)
    end

    if tab then
        tab:Hide()
    end
    if content then
        content:Hide()
    end

    if ConsumesManager_Tabs then
        ConsumesManager_Tabs[tabIndex] = nil
    end
    if mainFrame.tabs then
        mainFrame.tabs[tabIndex] = nil
    end

    mainFrame.CETabButton = nil
    mainFrame.CETabContent = nil
end

function CE_UpdateCETabState()
    CE_CreateCETab()
end
