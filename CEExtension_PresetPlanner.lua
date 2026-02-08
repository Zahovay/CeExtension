-- CE raid consumables planner window

local function CE_GetPresetWindowSize()
    local mainFrame = ConsumesManager_MainFrame
    local baseWidth = (mainFrame and mainFrame.GetWidth and mainFrame:GetWidth()) or WindowWidth or 480
    local baseHeight = (mainFrame and mainFrame.GetHeight and mainFrame:GetHeight()) or 512
    return math.floor(baseWidth + 450), math.floor(baseHeight - 150)
end

local function CE_SetTabButtonState(button, isActive)
    if not button then
        return
    end
    local trim = 0.08
    local texture = isActive and "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"
        or "Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab"
    button:SetNormalTexture(texture)
    button:SetPushedTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetAllPoints(button)
        normalTexture:SetTexCoord(1 - trim, trim, 1, 0)
    end
    if button.SetHighlightTexture then
        button:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
    end
    local pushedTexture = button:GetPushedTexture()
    if pushedTexture then
        pushedTexture:SetAllPoints(button)
        pushedTexture:SetTexCoord(1 - trim, trim, 1, 0)
    end
    local highlightTexture = button:GetHighlightTexture()
    if highlightTexture then
        highlightTexture:SetAllPoints(button)
        highlightTexture:SetTexCoord(1 - trim, trim, 1, 0)
    end
end

local function CE_GetPlannerPotionItems()
    local results = {}
    local seen = {}

    if type(consumablesCategories) == "table" then
        for categoryName, items in pairs(consumablesCategories) do
            local categoryLower = type(categoryName) == "string" and string.lower(categoryName) or ""
            local isPotionCategory = string.find(categoryLower, "potion", 1, true) ~= nil
                or string.find(categoryLower, "elixir", 1, true) ~= nil
                or string.find(categoryLower, "flask", 1, true) ~= nil
            if isPotionCategory and type(items) == "table" then
                for i = 1, table.getn(items) do
                    local item = items[i]
                    if item and item.id and not seen[item.id] then
                        table.insert(results, { id = item.id, name = item.name or "" })
                        seen[item.id] = true
                    end
                end
            end
        end
    end

    if table.getn(results) == 0 and type(consumablesNameToID) == "table" then
        for itemName, itemId in pairs(consumablesNameToID) do
            if type(itemName) == "string" then
                local nameLower = string.lower(itemName)
                local isPotionItem = string.find(nameLower, "potion", 1, true) ~= nil
                    or string.find(nameLower, "elixir", 1, true) ~= nil
                    or string.find(nameLower, "flask", 1, true) ~= nil
                if isPotionItem and not seen[itemId] then
                    table.insert(results, { id = itemId, name = itemName })
                    seen[itemId] = true
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return results
end

local function CE_ClearPlannerRows(parentFrame)
    if not parentFrame or not parentFrame.plannerRows then
        return
    end
    local count = table.getn(parentFrame.plannerRows)
    for i = 1, count do
        local row = parentFrame.plannerRows[i]
        if row and row.Hide then
            row:Hide()
        end
    end
    parentFrame.plannerRows = {}
end

local function CE_BuildPlannerRows(scrollChild, parentFrame, items)
    if not scrollChild or not parentFrame then
        return
    end

    CE_ClearPlannerRows(parentFrame)
    parentFrame.plannerRows = {}

    local lineHeight = 18
    local count = table.getn(items)
    if count == 0 then
        local emptyLabel = parentFrame.plannerEmptyLabel
        if not emptyLabel then
            emptyLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            parentFrame.plannerEmptyLabel = emptyLabel
        end
        emptyLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)
        emptyLabel:SetText("No potions found.")
        emptyLabel:SetJustifyH("LEFT")
        emptyLabel:Show()
        scrollChild:SetHeight(lineHeight)
        return
    end

    if parentFrame.plannerEmptyLabel then
        parentFrame.plannerEmptyLabel:Hide()
    end

    for i = 1, count do
        local item = items[i]
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetWidth(scrollChild:GetWidth() - 10)
        row:SetHeight(lineHeight)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * lineHeight))

        local checkbox = CreateFrame("CheckButton", nil, row)
        checkbox:SetWidth(16)
        checkbox:SetHeight(16)
        checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)
        checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 6, 0)
        label:SetText(item.name or "")
        label:SetJustifyH("LEFT")

        row:SetScript("OnMouseDown", function()
            checkbox:SetChecked(not checkbox:GetChecked())
        end)

        local labelHit = CreateFrame("Button", nil, row)
        labelHit:SetPoint("TOPLEFT", label, "TOPLEFT", 0, 0)
        labelHit:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 0, 0)
        labelHit:EnableMouse(true)
        labelHit:SetScript("OnClick", function()
            checkbox:SetChecked(not checkbox:GetChecked())
        end)

        table.insert(parentFrame.plannerRows, row)
    end

    scrollChild:SetHeight(count * lineHeight)
end

local CE_UpdatePlannerList

local function CE_CreatePlannerList(parentFrame)
    if not parentFrame or parentFrame.plannerBuilt then
        return
    end

    local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -26, 8)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    if parentFrame.GetWidth and parentFrame:GetWidth() > 0 then
        scrollChild:SetWidth(parentFrame:GetWidth() - 40)
    else
        scrollChild:SetWidth(1)
    end
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
    scrollBar:SetMinMaxValues(0, 0)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(0)
    scrollBar:SetWidth(16)
    scrollBar:SetScript("OnValueChanged", function()
        scrollFrame:SetVerticalScroll(this:GetValue())
    end)

    scrollFrame:SetScript("OnMouseWheel", function()
        local current = scrollBar:GetValue()
        local step = 18
        local minVal, maxVal = scrollBar:GetMinMaxValues()
        local newVal = current - (step * arg1)
        if newVal < minVal then
            newVal = minVal
        elseif newVal > maxVal then
            newVal = maxVal
        end
        scrollBar:SetValue(newVal)
    end)

    parentFrame.plannerScrollFrame = scrollFrame
    parentFrame.plannerScrollChild = scrollChild
    parentFrame.plannerScrollBar = scrollBar
    parentFrame.plannerBuilt = true

    local existingOnShow = parentFrame:GetScript("OnShow")
    parentFrame:SetScript("OnShow", function()
        if existingOnShow then
            existingOnShow()
        end
        CE_UpdatePlannerList(parentFrame)
    end)
end

CE_UpdatePlannerList = function(parentFrame)
    if not parentFrame or not parentFrame.plannerBuilt then
        return
    end
    if parentFrame.plannerScrollChild and parentFrame.GetWidth and parentFrame:GetWidth() > 0 then
        parentFrame.plannerScrollChild:SetWidth(parentFrame:GetWidth() - 40)
    end
    local items = CE_GetPlannerPotionItems()
    CE_BuildPlannerRows(parentFrame.plannerScrollChild, parentFrame, items)

    local scrollFrame = parentFrame.plannerScrollFrame
    local scrollBar = parentFrame.plannerScrollBar
    local scrollChild = parentFrame.plannerScrollChild
    if scrollFrame and scrollBar and scrollChild then
        local totalHeight = scrollChild:GetHeight()
        local shownHeight = scrollFrame:GetHeight()
        local maxScroll = math.max(0, totalHeight - shownHeight)
        scrollBar:SetMinMaxValues(0, maxScroll)
        if maxScroll > 0 then
            scrollBar:Show()
        else
            scrollBar:Hide()
        end
    end
end

local function CE_RefreshPlannerTabs(frame)
    if not frame or not frame.tabContents then
        return
    end
    local count = table.getn(frame.tabContents)
    for i = 1, count do
        CE_UpdatePlannerList(frame.tabContents[i])
    end
end

local function CE_SelectPresetTab(frame, index)
    if not frame or not frame.tabContents or not frame.tabButtons then
        return
    end
    frame.selectedTab = index
    local count = table.getn(frame.tabContents)
    for i = 1, count do
        local content = frame.tabContents[i]
        local button = frame.tabButtons[i]
        if i == index then
            if content then
                content:Show()
            end
            CE_SetTabButtonState(button, true)
            if button and button.GetFontString and button:GetFontString() then
                button:GetFontString():SetTextColor(1, 0.85, 0.2)
            end
        else
            if content then
                content:Hide()
            end
            CE_SetTabButtonState(button, false)
            if button and button.GetFontString and button:GetFontString() then
                button:GetFontString():SetTextColor(1, 1, 1)
            end
        end
    end
    if type(CE_UpdateTabSeparatorLine) == "function" then
        CE_UpdateTabSeparatorLine(frame, frame.tabButtons[index])
    end
end

function CE_UpdateTabSeparatorLine(frame, activeButton)
    if not frame or not frame.tabLineLeft or not frame.tabLineRight then
        return
    end

    local lineY = frame.tabLineY or -86
    local frameLeft = frame.GetLeft and frame:GetLeft() or nil
    local frameRight = frame.GetRight and frame:GetRight() or nil
    local frameTop = frame.GetTop and frame:GetTop() or nil
    local btnCenter = activeButton and activeButton.GetCenter and activeButton:GetCenter() or nil
    local btnWidth = activeButton and activeButton.GetWidth and activeButton:GetWidth() or nil
    local btnLeft = activeButton and activeButton.GetLeft and activeButton:GetLeft() or nil
    local btnRight = activeButton and activeButton.GetRight and activeButton:GetRight() or nil
    local btnBottom = activeButton and activeButton.GetBottom and activeButton:GetBottom() or nil

    if not frameLeft or not frameRight or (not btnLeft and not btnCenter) or (not btnRight and not btnWidth) then
        frame.tabLineLeft:ClearAllPoints()
        frame.tabLineLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, lineY)
        frame.tabLineLeft:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, lineY)
        frame.tabLineLeft:Show()
        frame.tabLineRight:Hide()
        return
    end

    if frameTop and btnBottom then
        lineY = btnBottom - frameTop
    end

    if not btnLeft or not btnRight then
        btnLeft = btnCenter - (btnWidth / 2)
        btnRight = btnCenter + (btnWidth / 2)
    end

    local overlap = 0
    local leftWidth = btnLeft - frameLeft - 12 + overlap
    local rightWidth = frameRight - 12 - btnRight + overlap

    frame.tabLineLeft:ClearAllPoints()
    frame.tabLineLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, lineY)
    frame.tabLineLeft:SetHeight(1)
    if leftWidth > 0 then
        frame.tabLineLeft:SetWidth(leftWidth)
        frame.tabLineLeft:Show()
    else
        frame.tabLineLeft:Hide()
    end

    frame.tabLineRight:ClearAllPoints()
    frame.tabLineRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, lineY)
    frame.tabLineRight:SetHeight(1)
    if rightWidth > 0 then
        frame.tabLineRight:SetWidth(rightWidth)
        frame.tabLineRight:Show()
    else
        frame.tabLineRight:Hide()
    end
end

local function CE_BuildPresetTabs(frame)
    if not frame or frame.tabsBuilt then
        return
    end

    local cfg = CE_GetConfig()
    local raids = (cfg and cfg.ORDERED_RAIDS) or {}

    frame.tabButtons = {}
    frame.tabContents = {}

    local xOffset = 20
    local yOffset = -60
    local count = table.getn(raids)
    for i = 1, count do
        local raidName = raids[i]
        local index = i
        local button = CreateFrame("Button", nil, frame)
        button:SetHeight(24)
        button:SetText(raidName)
        if button.GetFontString and button:GetFontString() then
            button:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
        end
        local textWidth = 60
        if button.GetFontString and button:GetFontString() then
            textWidth = button:GetFontString():GetStringWidth()
        end
        button:SetWidth(textWidth + 40)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
        button:SetScript("OnClick", function()
            CE_SelectPresetTab(frame, index)
        end)
        CE_SetTabButtonState(button, false)
        frame.tabButtons[i] = button
        xOffset = xOffset + button:GetWidth()
    end

    local tabHeight = 24
    if frame.tabButtons[1] and frame.tabButtons[1].GetHeight then
        tabHeight = frame.tabButtons[1]:GetHeight() or tabHeight
    end
    frame.tabLineY = yOffset - tabHeight

    local tabLineLeft = frame.tabLineLeft
    if not tabLineLeft then
        tabLineLeft = frame:CreateTexture(nil, "OVERLAY")
        frame.tabLineLeft = tabLineLeft
    end
    if tabLineLeft.SetDrawLayer then
        tabLineLeft:SetDrawLayer("OVERLAY", 7)
    end
    tabLineLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    tabLineLeft:SetVertexColor(0.4, 0.4, 0.4, 1)

    local tabLineRight = frame.tabLineRight
    if not tabLineRight then
        tabLineRight = frame:CreateTexture(nil, "OVERLAY")
        frame.tabLineRight = tabLineRight
    end
    if tabLineRight.SetDrawLayer then
        tabLineRight:SetDrawLayer("OVERLAY", 7)
    end
    tabLineRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    tabLineRight:SetVertexColor(0.4, 0.4, 0.4, 1)

    for i = 1, count do
        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -90)
        content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 40)
        content:Hide()
        frame.tabContents[i] = content
        CE_CreatePlannerList(content)
        CE_UpdatePlannerList(content)
    end

    if count == 0 then
        local emptyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -90)
        emptyLabel:SetText("No raids configured.")
        emptyLabel:SetJustifyH("LEFT")
        frame.emptyLabel = emptyLabel
    end

    frame.tabsBuilt = true
end

function CE_ClosePresetConfigWindow()
    local frame = ConsumesManager_CEPresetFrame
    if frame and frame.Hide then
        frame.ceReturnToMain = true
        frame:Hide()
    end
    if ConsumesManager_MainFrame and ConsumesManager_MainFrame.Show then
        ConsumesManager_MainFrame:Show()
    end
end

local function CE_CreatePresetConfigWindow()
    if ConsumesManager_CEPresetFrame then
        return ConsumesManager_CEPresetFrame
    end

    local width, height = CE_GetPresetWindowSize()
    local frame = CreateFrame("Frame", "ConsumesManager_CEPresetFrame", UIParent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    table.insert(UISpecialFrames, "ConsumesManager_CEPresetFrame")
    frame:SetScript("OnHide", function()
        if frame.ceReturnToMain then
            frame.ceReturnToMain = false
            if ConsumesManager_MainFrame and ConsumesManager_MainFrame.Show then
                ConsumesManager_MainFrame:Show()
            end
        end
    end)

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    background:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)

    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)

    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetText("Raid consumables Planner")
    titleText:SetPoint("TOP", frame, "TOP", 0, -2)

    local titleWidth = titleText:GetStringWidth() + 260
    local titleBg = frame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(titleWidth)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", frame, "TOP", 0, 12)

    local saveButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveButton:SetWidth(140)
    saveButton:SetHeight(24)
    saveButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    saveButton:SetText("Save and Close")
    if saveButton.GetFontString and saveButton:GetFontString() then
        saveButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
    end
    saveButton:SetScript("OnClick", function()
        CE_ClosePresetConfigWindow()
    end)

    CE_BuildPresetTabs(frame)
    CE_SelectPresetTab(frame, 1)

    frame:Hide()
    ConsumesManager_CEPresetFrame = frame
    return frame
end

function CE_ShowPresetConfigWindow()
    if not ConsumesManager_Options.showColdEmbrace then
        return
    end
    if not ConsumesManager_MainFrame then
        return
    end

    local frame = CE_CreatePresetConfigWindow()
    local width, height = CE_GetPresetWindowSize()
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER")

    ConsumesManager_MainFrame:Hide()
    frame:Show()
    CE_RefreshPlannerTabs(frame)
    CE_SelectPresetTab(frame, frame.selectedTab or 1)
end
