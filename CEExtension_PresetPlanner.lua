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
    CE_SelectPresetTab(frame, frame.selectedTab or 1)
end
