-- CE Buy tab: shows only unfulfilled preset items
-- Classic Turtle WoW (1.12) / Lua 5.0 compatible

-- ==================
-- Buy Tab UI (tab button + content)
-- ==================

local function CE_CreateBuyTabButton(tabIndex, xOffset, tooltipText)
    if not ConsumesManager_MainFrame then
        return nil
    end

    local tab = CreateFrame("Button", "ConsumesManager_MainFrameTabCEBuy", ConsumesManager_MainFrame)
    tab:SetWidth(36)
    tab:SetHeight(36)
    tab:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", xOffset, -30)
    tab:SetNormalTexture("Interface\\ItemsFrame\\UI-ItemsFrame-InActiveTab")
    local normalTexture = tab:GetNormalTexture()
    if normalTexture then
        normalTexture:SetAllPoints(tab)
    end

    local iconBorder = tab:CreateTexture(nil, "BACKGROUND")
    iconBorder:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
    iconBorder:SetWidth(36)
    iconBorder:SetHeight(36)
    iconBorder:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab.iconBorder = iconBorder

    local icon = tab:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
    icon:SetWidth(22)
    icon:SetHeight(22)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab.icon = icon

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

local function CE_BuyTabSetDropdownText(dropdown, text)
    if dropdown and type(UIDropDownMenu_SetText) == "function" then
        UIDropDownMenu_SetText(text, dropdown)
    end
end

local function CE_BuyTabFindIndex(list, value)
    if type(list) ~= "table" or type(value) ~= "string" or value == "" then
        return 0
    end
    for i = 1, table.getn(list) do
        if list[i] == value then
            return i
        end
    end
    return 0
end

local function CE_BuyTabSyncDropdowns(content)
    if not content then
        return
    end

    local useCE = ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace
    local cfg = useCE and (CE_GetConfig and CE_GetConfig() or nil) or nil

    local raidDropdown = content.buyRaidDropdown
    local classDropdown = content.buyClassDropdown

    -- Sync class dropdown
    do
        local entries = useCE and (type(CE_BuildTalentClassList) == "function" and CE_BuildTalentClassList() or {})
            or (type(CE_BuildOriginalClassList) == "function" and CE_BuildOriginalClassList() or {})

        local selectedClass = ConsumesManager_SelectedClass
        if type(selectedClass) ~= "string" then
            selectedClass = ""
        end
        local classIndex = CE_BuyTabFindIndex(entries, selectedClass)

        if classDropdown and type(UIDropDownMenu_SetSelectedID) == "function" then
            UIDropDownMenu_SetSelectedID(classDropdown, classIndex > 0 and classIndex or 0)
        end

        if classDropdown and type(UIDropDownMenu_SetText) == "function" then
            if classIndex > 0 then
                local lastWord = type(CE_GetLastWord) == "function" and CE_GetLastWord(selectedClass) or ""
                local color = (cfg and cfg.CLASS_COLORS and cfg.CLASS_COLORS[lastWord]) or "ffffff"
                UIDropDownMenu_SetText("|cff" .. color .. selectedClass .. "|r", classDropdown)
            else
                UIDropDownMenu_SetText("Select |cffffff00Class|r", classDropdown)
            end
        end
    end

    -- Sync raid dropdown
    do
        local raids = (cfg and cfg.ORDERED_RAIDS) or orderedRaids or {}
        local desired = (type(CE_NormalizeRaidName) == "function" and CE_NormalizeRaidName(ConsumesManager_SelectedRaid))
            or (ConsumesManager_SelectedRaid or "")
        if type(desired) ~= "string" then
            desired = ""
        end
        local raidIndex = CE_BuyTabFindIndex(raids, desired)

        if raidDropdown and type(UIDropDownMenu_SetSelectedID) == "function" then
            UIDropDownMenu_SetSelectedID(raidDropdown, raidIndex > 0 and raidIndex or 0)
        end
        if raidDropdown and type(UIDropDownMenu_SetText) == "function" then
            UIDropDownMenu_SetText(raidIndex > 0 and raids[raidIndex] or "Select |cffffff00Raid|r", raidDropdown)
        end
    end
end

local function CE_BuyTabSyncPresetDropdowns()
    -- Keep Presets tab dropdowns visually in sync with the backend state.
    local presetClassDropdown = _G and _G["ConsumesManager_PresetsClassDropdown"]
    local presetRaidDropdown = _G and _G["ConsumesManager_PresetsRaidDropdown"]

    local useCE = ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace
    local cfg = useCE and (CE_GetConfig and CE_GetConfig() or nil) or nil

    if presetClassDropdown then
        local entries = useCE and (type(CE_BuildTalentClassList) == "function" and CE_BuildTalentClassList() or {})
            or (type(CE_BuildOriginalClassList) == "function" and CE_BuildOriginalClassList() or {})
        local selectedClass = ConsumesManager_SelectedClass
        if type(selectedClass) ~= "string" then
            selectedClass = ""
        end
        local classIndex = CE_BuyTabFindIndex(entries, selectedClass)
        if type(UIDropDownMenu_SetSelectedID) == "function" then
            UIDropDownMenu_SetSelectedID(presetClassDropdown, classIndex > 0 and classIndex or 0)
        end
        if type(UIDropDownMenu_SetText) == "function" then
            if classIndex > 0 then
                local lastWord = type(CE_GetLastWord) == "function" and CE_GetLastWord(selectedClass) or ""
                local color = (cfg and cfg.CLASS_COLORS and cfg.CLASS_COLORS[lastWord]) or "ffffff"
                UIDropDownMenu_SetText("|cff" .. color .. selectedClass .. "|r", presetClassDropdown)
            else
                UIDropDownMenu_SetText("Select |cffffff00Class|r", presetClassDropdown)
            end
        end
    end

    if presetRaidDropdown then
        local raids = (cfg and cfg.ORDERED_RAIDS) or orderedRaids or {}
        local desired = (type(CE_NormalizeRaidName) == "function" and CE_NormalizeRaidName(ConsumesManager_SelectedRaid))
            or (ConsumesManager_SelectedRaid or "")
        if type(desired) ~= "string" then
            desired = ""
        end
        local raidIndex = CE_BuyTabFindIndex(raids, desired)
        if type(UIDropDownMenu_SetSelectedID) == "function" then
            UIDropDownMenu_SetSelectedID(presetRaidDropdown, raidIndex > 0 and raidIndex or 0)
        end
        if type(UIDropDownMenu_SetText) == "function" then
            UIDropDownMenu_SetText(raidIndex > 0 and raids[raidIndex] or "Select |cffffff00Raid|r", presetRaidDropdown)
        end
    end
end

local function CE_BuyTabGetStore()
    ConsumesManager_Options = ConsumesManager_Options or {}
    ConsumesManager_Options.ceBuyTab = ConsumesManager_Options.ceBuyTab or {}

    local store = ConsumesManager_Options.ceBuyTab
    if type(store.boughtMarks) ~= "table" then
        store.boughtMarks = {}
    end
    if type(store.boughtBaseCounts) ~= "table" then
        store.boughtBaseCounts = {}
    end
    return store
end

local function CE_BuyTabClearBoughtMarks()
    local store = CE_BuyTabGetStore()
    store.boughtMarks = {}
    store.boughtBaseCounts = {}
end

local function CE_BuyTabGetPlayerCount(itemId)
    if type(itemId) ~= "number" then
        return 0
    end
    if type(GetItemCount) == "function" then
        local c = GetItemCount(itemId)
        if type(c) == "number" then
            return c
        end
    end
    return 0
end

local function CE_CreateBuyTabContent(tabIndex)
    if not ConsumesManager_MainFrame then
        return nil
    end

    local content = CreateFrame("Frame", nil, ConsumesManager_MainFrame)
    local baseWidth = (type(WindowWidth) == "number" and WindowWidth)
        or (ConsumesManager_MainFrame and ConsumesManager_MainFrame.GetWidth and ConsumesManager_MainFrame:GetWidth())
        or 480
    if baseWidth < 200 then
        baseWidth = 200
    end
    content:SetWidth(baseWidth - 50)
    content:SetHeight(380)
    content:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 30, -80)
    content:Hide()

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -5)
    title:SetText("|cffffff00Buy list|r")
    title:SetJustifyH("LEFT")
    content.CEBuyTitle = title

    local subtitle = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText("Only unfulfilled preset items")
    subtitle:SetJustifyH("LEFT")
    content.CEBuySubtitle = subtitle

    local raidDropdown = CreateFrame("Frame", "ConsumesManager_BuyRaidDropdown", content, "UIDropDownMenuTemplate")
    raidDropdown:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", -20, -14)
    if type(UIDropDownMenu_SetWidth) == "function" then
        UIDropDownMenu_SetWidth(120, raidDropdown)
    end
    CE_BuyTabSetDropdownText(raidDropdown, "Select |cffffff00Raid|r")
    content.buyRaidDropdown = raidDropdown

    local raidDropdownText = getglobal and getglobal("ConsumesManager_BuyRaidDropdownText")
    if raidDropdownText and raidDropdownText.SetJustifyH then
        raidDropdownText:SetJustifyH("LEFT")
    end

    local classDropdown = CreateFrame("Frame", "ConsumesManager_BuyClassDropdown", content, "UIDropDownMenuTemplate")
    classDropdown:SetPoint("LEFT", raidDropdown, "RIGHT", -20, 0)
    if type(UIDropDownMenu_SetWidth) == "function" then
        UIDropDownMenu_SetWidth(120, classDropdown)
    end
    CE_BuyTabSetDropdownText(classDropdown, "Select |cffffff00Class|r")
    content.buyClassDropdown = classDropdown

    local classDropdownText = getglobal and getglobal("ConsumesManager_BuyClassDropdownText")
    if classDropdownText and classDropdownText.SetJustifyH then
        classDropdownText:SetJustifyH("LEFT")
    end

    UIDropDownMenu_Initialize(classDropdown, function()
        local useCE = ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace
        local entries = useCE and (type(CE_BuildTalentClassList) == "function" and CE_BuildTalentClassList() or {})
            or (type(CE_BuildOriginalClassList) == "function" and CE_BuildOriginalClassList() or {})
        local cfg = CE_GetConfig and CE_GetConfig() or nil

        for idx = 1, table.getn(entries) do
            local cName = entries[idx]
            local cIndex = idx
            local info = {}
            local lastWord = type(CE_GetLastWord) == "function" and CE_GetLastWord(cName) or ""
            local color = (cfg and cfg.CLASS_COLORS and cfg.CLASS_COLORS[lastWord]) or "ffffff"
            info.text = "|cff" .. color .. cName .. "|r"
            info.func = function()
                if type(UIDropDownMenu_SetSelectedID) == "function" then
                    UIDropDownMenu_SetSelectedID(classDropdown, cIndex)
                end
                ConsumesManager_SelectedClass = cName
                if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
                    if type(ConsumesManager_UpdateRaidsDropdown) == "function" then
                        ConsumesManager_UpdateRaidsDropdown()
                    end
                    ConsumesManager_UpdatePresetsConsumables()
                end
                CE_BuyTabSyncPresetDropdowns()
                CE_BuyTabClearBoughtMarks()
                if type(CE_UpdateBuyConsumables) == "function" then
                    CE_UpdateBuyConsumables()
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_Initialize(raidDropdown, function()
        local useCE = ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace
        local cfg = useCE and (CE_GetConfig and CE_GetConfig() or nil) or nil
        local raids = (cfg and cfg.ORDERED_RAIDS) or orderedRaids or {}
        local desired = CE_NormalizeRaidName and CE_NormalizeRaidName(ConsumesManager_SelectedRaid) or (ConsumesManager_SelectedRaid or "")
        local selectedIndex = 0

        for i = 1, table.getn(raids) do
            local raidName = raids[i]
            local raidIndex = i
            local info = {}
            info.text = raidName
            info.func = function()
                if type(UIDropDownMenu_SetSelectedID) == "function" then
                    UIDropDownMenu_SetSelectedID(raidDropdown, raidIndex)
                end
                ConsumesManager_SelectedRaid = raidName
                if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
                    ConsumesManager_UpdatePresetsConsumables()
                end
                CE_BuyTabSyncPresetDropdowns()
                CE_BuyTabClearBoughtMarks()
                if type(CE_UpdateBuyConsumables) == "function" then
                    CE_UpdateBuyConsumables()
                end
            end
            UIDropDownMenu_AddButton(info)
            if raidName == desired then
                selectedIndex = i
            end
        end

        if type(UIDropDownMenu_SetSelectedID) == "function" then
            UIDropDownMenu_SetSelectedID(raidDropdown, selectedIndex > 0 and selectedIndex or 0)
        end
        CE_BuyTabSetDropdownText(raidDropdown, selectedIndex > 0 and raids[selectedIndex] or "Select |cffffff00Raid|r")
    end)

    -- Prefill from the same backend state as the Presets tab
    CE_BuyTabSyncDropdowns(content)

    local scrollFrame = CreateFrame("ScrollFrame", "ConsumesManager_BuyScrollFrame", content)
    scrollFrame:SetPoint("TOPLEFT", classDropdown, "BOTTOMLEFT", -135, -20)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -25, -5)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(content:GetWidth() - 40)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    content.scrollChild = scrollChild
    content.scrollFrame = scrollFrame

    local scrollBar = CreateFrame("Slider", "ConsumesManager_BuyScrollBar", content)
    scrollBar:SetPoint("TOPRIGHT", content, "TOPRIGHT", -2, -35)
    scrollBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -2, 16)
    scrollBar:SetWidth(16)
    scrollBar:SetOrientation('VERTICAL')
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = 1, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollBar:SetScript("OnValueChanged", function()
        local val = this:GetValue()
        content.scrollFrame:SetVerticalScroll(val)
    end)
    content.scrollBar = scrollBar
    scrollBar:Hide()

    if scrollBar.SetValueStep then
        scrollBar:SetValueStep(20)
    end

    scrollFrame:SetScript("OnMouseWheel", function()
        local d = arg1
        local cur = this:GetVerticalScroll()
        local mx = this.range or 0
        local new = 0
        if d < 0 then
            new = math.min(cur + 20, mx)
        else
            new = math.max(cur - 20, 0)
        end
        this:SetVerticalScroll(new)
        content.scrollBar:SetValue(new)
    end)

    local messageLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetText("|cffff0000Please select both a Raid and a Class.|r")
    messageLabel:SetPoint("CENTER", content, "CENTER", 0, 0)
    messageLabel:Hide()
    content.messageLabel = messageLabel

    content:SetScript("OnShow", function()
        CE_BuyTabSyncDropdowns(content)
        CE_BuyTabSyncPresetDropdowns()
        if type(CE_UpdateBuyConsumables) == "function" then
            CE_UpdateBuyConsumables()
        end
    end)

    return content
end

function CE_CreateBuyTab()
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs or not ConsumesManager_Tabs then
        return
    end

    if not (ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace) then
        return
    end

    local tabIndex = 7
    local xOffset = 270
    local tooltipText = "Buy (missing consumables)"

    if ConsumesManager_MainFrame.CEBuyTabButton and ConsumesManager_MainFrame.CEBuyTabContent then
        ConsumesManager_MainFrame.CEBuyTabButton:Show()
        ConsumesManager_Tabs[tabIndex] = ConsumesManager_MainFrame.CEBuyTabButton
        ConsumesManager_MainFrame.tabs[tabIndex] = ConsumesManager_MainFrame.CEBuyTabContent
        return
    end

    local tab = CE_CreateBuyTabButton(tabIndex, xOffset, tooltipText)
    local content = CE_CreateBuyTabContent(tabIndex)
    if not tab or not content then
        return
    end

    ConsumesManager_Tabs[tabIndex] = tab
    ConsumesManager_MainFrame.tabs[tabIndex] = content
    ConsumesManager_MainFrame.CEBuyTabButton = tab
    ConsumesManager_MainFrame.CEBuyTabContent = content
end

function CE_RemoveBuyTab()
    local mainFrame = ConsumesManager_MainFrame
    if not mainFrame then
        return
    end

    local tabIndex = 7
    local tab = mainFrame.CEBuyTabButton
    local content = mainFrame.CEBuyTabContent

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

    mainFrame.CEBuyTabButton = nil
    mainFrame.CEBuyTabContent = nil
end

function CE_UpdateBuyTabState()
    if ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace then
        CE_CreateBuyTab()
    else
        CE_RemoveBuyTab()
    end
end

-- ==================
-- Buy Tab rendering (unfulfilled items)
-- ==================

local function CE_ClearBuyRows(parentFrame)
    if not parentFrame then
        return
    end

    parentFrame.buyConsumables = parentFrame.buyConsumables or {}
    local count = 0
    for _ in pairs(parentFrame.buyConsumables) do
        count = count + 1
    end

    for i = 1, count do
        local row = parentFrame.buyConsumables[i]
        if row and row.frame and row.frame.Hide then
            row.frame:Hide()
        end
    end

    parentFrame.buyConsumables = {}

    if parentFrame.noItemsMessage then
        parentFrame.noItemsMessage:Hide()
    end
end

local function CE_UpdateBuyScrollBar(parentFrame, scrollChildHeight)
    if not parentFrame or not parentFrame.scrollFrame or not parentFrame.scrollBar then
        return
    end

    local scrollFrame = parentFrame.scrollFrame
    local scrollChild = parentFrame.scrollChild
    local scrollBar = parentFrame.scrollBar
    if not scrollChild then
        return
    end

    local totalHeight = (type(scrollChildHeight) == "number" and scrollChildHeight) or scrollChild:GetHeight()
    local shownHeight = (parentFrame.GetHeight and parentFrame:GetHeight() or 0) - 20
    if shownHeight < 0 then
        shownHeight = 0
    end

    if totalHeight > shownHeight then
        local maxScroll = totalHeight - shownHeight
        scrollFrame.range = maxScroll
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(math.min(scrollBar:GetValue(), maxScroll))
        scrollBar:Show()
    else
        scrollFrame.range = 0
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValue(0)
        scrollBar:Hide()
    end
end

local function CE_AddBuyItemRow(scrollChild, index, lineHeight, item, parentFrame)
    if not item then
        return index
    end

    local frameName = "ConsumesManager_BuyConsumableFrame" .. index
    local frame = _G[frameName]
    if not frame then
        frame = CreateFrame("Frame", frameName, scrollChild)
    end
    frame:SetParent(scrollChild)
    frame:ClearAllPoints()
    frame:SetWidth(scrollChild:GetWidth() - 10)
    frame:SetHeight(lineHeight)
    frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
    frame:Show()
    frame:EnableMouse(true)

    local buyButton = frame.buyButton
    if not buyButton then
        buyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.buyButton = buyButton
        buyButton:SetHeight(16)
        buyButton:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    end
    buyButton:SetWidth(52)
    buyButton:SetText("Search")
    buyButton:Show()

    local boughtCheck = frame.boughtCheck
    if not boughtCheck then
        boughtCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.boughtCheck = boughtCheck
        boughtCheck:SetWidth(16)
        boughtCheck:SetHeight(16)
        boughtCheck:SetPoint("LEFT", frame, "LEFT", 0, 0)
    end
    boughtCheck:Show()

    local label = frame.label
    if not label then
        label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.label = label
        label:SetPoint("LEFT", frame, "LEFT", 0, 0)
        label:SetJustifyH("LEFT")
    end
    label:ClearAllPoints()
    label:SetPoint("LEFT", boughtCheck, "RIGHT", 2, 0)
    label:SetPoint("RIGHT", buyButton, "LEFT", -4, 0)

    local hit = frame.hit
    if not hit then
        hit = CreateFrame("Frame", nil, frame)
        frame.hit = hit
        hit:EnableMouse(true)
    end
    hit:ClearAllPoints()
    hit:SetPoint("TOPLEFT", boughtCheck, "TOPRIGHT", 2, 0)
    hit:SetPoint("BOTTOMRIGHT", buyButton, "BOTTOMLEFT", -4, 0)
    hit:Show()
    if frame.GetFrameLevel and hit.SetFrameLevel and buyButton.SetFrameLevel then
        hit:SetFrameLevel(frame:GetFrameLevel() + 1)
        buyButton:SetFrameLevel(hit:GetFrameLevel() + 1)
    end

    local mode = ConsumesManager_Options and ConsumesManager_Options.ceConfigMode or "requiredmode"
    if mode == "ownedmode" then
        label:SetText((item.name or "") .. " (" .. (item.totalCount or 0) .. "/" .. (item.required or 0) .. ")")
    else
        label:SetText((item.name or "") .. " (" .. (item.required or 0) .. "/" .. (item.totalCount or 0) .. ")")
    end
    -- Items in the Buy tab are filtered to only unfulfilled items.
    if item.totalCount == 0 then
        label:SetTextColor(1, 0, 0)
    else
        label:SetTextColor(1, 0.4, 0)
    end

    if item and item.id then
        hit:SetScript("OnEnter", function()
            ConsumesManager_ShowConsumableTooltip(item.id)
        end)
    else
        hit:SetScript("OnEnter", nil)
    end

    buyButton:SetScript("OnEnter", hit:GetScript("OnEnter"))

    hit:SetScript("OnLeave", function()
        if ConsumesManager_CustomTooltip and ConsumesManager_CustomTooltip.Hide then
            ConsumesManager_CustomTooltip:Hide()
        end
    end)

    buyButton:SetScript("OnLeave", hit:GetScript("OnLeave"))

    do
        local store = CE_BuyTabGetStore()
        local isMarked = store.boughtMarks and store.boughtMarks[item.id]
        boughtCheck:SetChecked(isMarked and true or false)

        local function CE_ApplyBoughtMark(now)
            local s = CE_BuyTabGetStore()
            local id = item.id
            if type(id) ~= "number" then
                return
            end

            if now then
                s.boughtMarks[id] = true
                s.boughtBaseCounts[id] = CE_BuyTabGetPlayerCount(id)
            else
                s.boughtMarks[id] = nil
                s.boughtBaseCounts[id] = nil
            end

            if type(CE_UpdateBuyConsumables) == "function" then
                CE_UpdateBuyConsumables()
            end
        end

        boughtCheck:SetScript("OnEnter", function()
            if GameTooltip and GameTooltip.SetOwner and GameTooltip.SetText then
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText("Mark as bought (temporary)", 1, 1, 1)
                if GameTooltip.AddLine then
                    GameTooltip:AddLine("Moves this item to the end of the list.", 0.8, 0.8, 0.8, true)
                    GameTooltip:AddLine("Clears automatically when items appear in your bags.", 0.8, 0.8, 0.8, true)
                end
                GameTooltip:Show()
            end
        end)
        boughtCheck:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        boughtCheck:SetScript("OnClick", function()
            CE_ApplyBoughtMark(this:GetChecked() and true or false)
        end)

        frame.CE_ApplyBoughtMark = CE_ApplyBoughtMark
    end

    local function CE_BuyRowTriggerSearch()
        if type(CE_AuxTryUseItem) == "function" and CE_AuxTryUseItem(item.id, item.name) then
            return
        end

        -- Blizzard AH fallback (for users not running aux): only works when the AH is open.
        if AuctionFrame and AuctionFrame.IsVisible and AuctionFrameBrowse_Search and BrowseName and BrowseName.SetText then
            if AuctionFrame:IsVisible() then
                BrowseName:SetText(item.name or "")
                AuctionFrameBrowse_Search()
                return
            end
        end

        -- Nothing available; show a brief warning.
        do
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage("Open the Auction House first.", 1, 0, 0, 1.0)
            end
        end
    end

    buyButton:SetScript("OnClick", function()
        CE_BuyRowTriggerSearch()
    end)

    hit:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then
            local now = boughtCheck and boughtCheck.GetChecked and (boughtCheck:GetChecked() and true or false) or false
            now = not now
            if boughtCheck and boughtCheck.SetChecked then
                boughtCheck:SetChecked(now)
            end
            if frame.CE_ApplyBoughtMark then
                frame.CE_ApplyBoughtMark(now)
            end
        elseif arg1 == "RightButton" then
            CE_BuyRowTriggerSearch()
        end
    end)

    parentFrame.buyConsumables = parentFrame.buyConsumables or {}
    table.insert(parentFrame.buyConsumables, {
        frame = frame,
        label = label,
        buyButton = buyButton,
        id = item.id
    })

    return index + 1
end

local function CE_AddBuyGroupHeader(scrollChild, index, lineHeight, labelText, parentFrame)
    local frameName = "ConsumesManager_BuyGroupFrame" .. index
    local groupFrame = _G[frameName]
    if not groupFrame then
        groupFrame = CreateFrame("Frame", frameName, scrollChild)
    end
    groupFrame:SetParent(scrollChild)
    groupFrame:ClearAllPoints()
    groupFrame:SetWidth(scrollChild:GetWidth() - 10)
    groupFrame:SetHeight(lineHeight)
    groupFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((index - 1) * lineHeight))
    groupFrame:Show()

    local groupLabel = groupFrame.label
    if not groupLabel then
        groupLabel = groupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        groupFrame.label = groupLabel
        groupLabel:SetPoint("LEFT", groupFrame, "LEFT", 0, 0)
        groupLabel:SetJustifyH("LEFT")
        groupLabel:SetTextColor(1, 1, 1)
    end
    groupLabel:SetText(labelText or "")

    parentFrame.buyConsumables = parentFrame.buyConsumables or {}
    table.insert(parentFrame.buyConsumables, {
        frame = groupFrame,
        label = groupLabel,
        isCategory = true
    })

    return index + 1
end

function CE_UpdateBuyConsumables()
    local parentFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[7]
    if not parentFrame then
        return
    end

    local scrollChild = parentFrame.scrollChild
    if not scrollChild then
        return
    end

    if not (ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace) then
        CE_ClearBuyRows(parentFrame)
        return
    end

    CE_ClearBuyRows(parentFrame)

    local raidName = (type(CE_NormalizeRaidName) == "function" and CE_NormalizeRaidName(ConsumesManager_SelectedRaid))
        or (ConsumesManager_SelectedRaid or "Naxxramas")
    local selectedClass = ConsumesManager_SelectedClass
    if type(selectedClass) ~= "string" or selectedClass == "" then
        if parentFrame.messageLabel then
            parentFrame.messageLabel:SetText("|cffff0000Please select both a Raid and a Class.|r")
            parentFrame.messageLabel:Show()
        end
        return
    end

    local preset = (type(CE_GetPresetEntry) == "function" and CE_GetPresetEntry(selectedClass, raidName)) or nil
    if type(preset) ~= "table" or type(preset.id) ~= "table" then
        if parentFrame.messageLabel then
            parentFrame.messageLabel:SetText("|cffff0000No CE preset found for this class/raid.|r")
            parentFrame.messageLabel:Show()
        end
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

    local req = type(preset.req) == "table" and preset.req or {}
    local missingMandatory = {}
    local missingOptional = {}
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
            local required = entry and tonumber(entry.amount) or 0
            if required < 0 then required = 0 end
            local totalCount = CE_GetTotalCount(itemId)

            -- Filter: show only unfulfilled (numeric decision; no UI color checks)
            if required > 0 and totalCount < required then
                local name = CE_GetName(itemId) or ("Item " .. tostring(itemId))
                local target = (entryStatus == "optional") and missingOptional or missingMandatory
                table.insert(target, { id = itemId, name = name, required = required, totalCount = totalCount })
            end
        end
    end

    -- Manual "bought" marks: move marked items to the bottom, and clear marks
    -- once any marked item count increases in the player's bags.
    do
        local store = CE_BuyTabGetStore()
        local marks = store and store.boughtMarks or nil
        local base = store and store.boughtBaseCounts or nil

        local function anyMarkClearedByBagUpdate()
            if type(marks) ~= "table" or type(base) ~= "table" then
                return false
            end
            for itemId, _ in pairs(marks) do
                if type(itemId) == "number" then
                    local cur = CE_BuyTabGetPlayerCount(itemId)
                    local prev = tonumber(base[itemId]) or 0
                    if cur > prev then
                        return true
                    end
                end
            end
            return false
        end

        if anyMarkClearedByBagUpdate() then
            CE_BuyTabClearBoughtMarks()
            marks = nil
        end

        if type(marks) == "table" then
            for i = 1, table.getn(missingMandatory) do
                local it = missingMandatory[i]
                it.isBought = (it and it.id and marks[it.id]) and true or false
            end
            for i = 1, table.getn(missingOptional) do
                local it = missingOptional[i]
                it.isBought = (it and it.id and marks[it.id]) and true or false
            end
        end
    end

    local boughtItems = {}
    local function partitionBought(list)
        local out = {}
        for i = 1, table.getn(list) do
            local it = list[i]
            if it and it.isBought then
                table.insert(boughtItems, it)
            else
                table.insert(out, it)
            end
        end
        return out
    end

    missingMandatory = partitionBought(missingMandatory)
    missingOptional = partitionBought(missingOptional)

    table.sort(missingMandatory, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    table.sort(missingOptional, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    table.sort(boughtItems, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    local lineHeight = 18
    local index = 1
    if table.getn(missingMandatory) == 0 and table.getn(missingOptional) == 0 and table.getn(boughtItems) == 0 then
        if parentFrame.messageLabel then
            parentFrame.noItemsMessage = parentFrame.messageLabel
            parentFrame.noItemsMessage:SetText("|cff00ff00All preset items are fulfilled.|r")
            parentFrame.noItemsMessage:Show()
        end
        scrollChild:SetHeight(lineHeight)
        CE_UpdateBuyScrollBar(parentFrame, lineHeight)
        return
    end

    if table.getn(missingMandatory) > 0 then
        index = CE_AddBuyGroupHeader(scrollChild, index, lineHeight, "Mandatory", parentFrame)
        for j = 1, table.getn(missingMandatory) do
            index = CE_AddBuyItemRow(scrollChild, index, lineHeight, missingMandatory[j], parentFrame)
        end
    end

    if table.getn(missingOptional) > 0 then
        index = CE_AddBuyGroupHeader(scrollChild, index, lineHeight, "Optional", parentFrame)
        for j = 1, table.getn(missingOptional) do
            index = CE_AddBuyItemRow(scrollChild, index, lineHeight, missingOptional[j], parentFrame)
        end
    end

    if table.getn(boughtItems) > 0 then
        index = CE_AddBuyGroupHeader(scrollChild, index, lineHeight, "Bought", parentFrame)
        for j = 1, table.getn(boughtItems) do
            index = CE_AddBuyItemRow(scrollChild, index, lineHeight, boughtItems[j], parentFrame)
        end
    end

    local height = (index - 1) * lineHeight + 40
    scrollChild:SetHeight(height)
    CE_UpdateBuyScrollBar(parentFrame, height)
end
