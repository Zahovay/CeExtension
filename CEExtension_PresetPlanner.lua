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

local function CE_BuildPlannerRows(scrollChild, parentFrame, items)
    if not scrollChild or not parentFrame then
        return
    end

    parentFrame.plannerRows = parentFrame.plannerRows or {}

    local lineHeight = 24
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

    local tabName = parentFrame.plannerTabName or "Tab"
    tabName = string.gsub(tabName, "%s+", "")

    for i = 1, count do
        local item = items[i]
        local row = parentFrame.plannerRows[i]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild)
            row:SetHeight(lineHeight)
            row.checkbox = CreateFrame("CheckButton", nil, row)
            row.checkbox:SetWidth(16)
            row.checkbox:SetHeight(16)
            row.checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            row.checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            row.checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            row.checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.label:SetJustifyH("LEFT")

            row:SetScript("OnMouseDown", function()
                row.checkbox:SetChecked(not row.checkbox:GetChecked())
            end)

            row.labelHit = CreateFrame("Button", nil, row)
            row.labelHit:EnableMouse(true)
            row.labelHit:SetScript("OnClick", function()
                row.checkbox:SetChecked(not row.checkbox:GetChecked())
            end)

            row.amountInputName = "CEPlannerAmountInput" .. tabName .. "_" .. i .. "_" .. (item.id or 0)
            row.amountInput = CreateFrame("EditBox", row.amountInputName, row, "InputBoxTemplate")
            row.amountInput:SetWidth(36)
            row.amountInput:SetHeight(16)
            row.amountInput:SetAutoFocus(false)
            row.amountInput:SetNumeric(true)
            row.amountInput:SetText("0")

            row.excludedBox = CreateFrame("CheckButton", nil, row)
            row.excludedBox:SetWidth(16)
            row.excludedBox:SetHeight(16)
            row.excludedBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            row.excludedBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            row.excludedBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            row.excludedBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            row.excludedLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.excludedLabel:SetJustifyH("LEFT")

            row.excludedHit = CreateFrame("Button", nil, row)
            row.excludedHit:EnableMouse(true)
            row.excludedHit:SetScript("OnClick", function()
                row.excludedBox:SetChecked(not row.excludedBox:GetChecked())
            end)

            row.optionalBox = CreateFrame("CheckButton", nil, row)
            row.optionalBox:SetWidth(16)
            row.optionalBox:SetHeight(16)
            row.optionalBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            row.optionalBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            row.optionalBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            row.optionalBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            row.optionalLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.optionalLabel:SetJustifyH("LEFT")

            row.optionalHit = CreateFrame("Button", nil, row)
            row.optionalHit:EnableMouse(true)
            row.optionalHit:SetScript("OnClick", function()
                row.optionalBox:SetChecked(not row.optionalBox:GetChecked())
            end)

            row.mandatoryBox = CreateFrame("CheckButton", nil, row)
            row.mandatoryBox:SetWidth(16)
            row.mandatoryBox:SetHeight(16)
            row.mandatoryBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            row.mandatoryBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            row.mandatoryBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            row.mandatoryBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            row.mandatoryLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.mandatoryLabel:SetJustifyH("LEFT")

            row.mandatoryHit = CreateFrame("Button", nil, row)
            row.mandatoryHit:EnableMouse(true)
            row.mandatoryHit:SetScript("OnClick", function()
                row.mandatoryBox:SetChecked(not row.mandatoryBox:GetChecked())
            end)

            row.SetStatus = function(target)
                row.mandatoryBox:SetChecked(false)
                row.optionalBox:SetChecked(false)
                row.excludedBox:SetChecked(false)
                if target then
                    target:SetChecked(true)
                end
            end

            row.mandatoryBox:SetScript("OnClick", function()
                row.SetStatus(row.mandatoryBox:GetChecked() and row.mandatoryBox or nil)
            end)
            row.optionalBox:SetScript("OnClick", function()
                row.SetStatus(row.optionalBox:GetChecked() and row.optionalBox or nil)
            end)
            row.excludedBox:SetScript("OnClick", function()
                row.SetStatus(row.excludedBox:GetChecked() and row.excludedBox or nil)
            end)

            row.UpdateEnabled = function()
                local enabled = row.checkbox:GetChecked() == 1
                if enabled then
                    row.label:SetTextColor(1, 1, 1)
                    if row.amountInput and row.amountInput.Enable then
                        row.amountInput:Enable()
                        row.amountInput:SetAlpha(1)
                    end
                    if row.mandatoryBox and row.mandatoryBox.Enable then
                        row.mandatoryBox:Enable()
                        row.mandatoryBox:SetAlpha(1)
                    end
                    if row.optionalBox and row.optionalBox.Enable then
                        row.optionalBox:Enable()
                        row.optionalBox:SetAlpha(1)
                    end
                    if row.excludedBox and row.excludedBox.Enable then
                        row.excludedBox:Enable()
                        row.excludedBox:SetAlpha(1)
                    end
                    if row.mandatoryLabel then
                        row.mandatoryLabel:SetTextColor(1, 1, 1)
                    end
                    if row.optionalLabel then
                        row.optionalLabel:SetTextColor(1, 1, 1)
                    end
                    if row.excludedLabel then
                        row.excludedLabel:SetTextColor(1, 1, 1)
                    end
                else
                    row.label:SetTextColor(0.6, 0.6, 0.6)
                    if row.amountInput and row.amountInput.Disable then
                        row.amountInput:Disable()
                        row.amountInput:SetAlpha(0.6)
                    end
                    if row.mandatoryBox and row.mandatoryBox.Disable then
                        row.mandatoryBox:Disable()
                        row.mandatoryBox:SetAlpha(0.6)
                    end
                    if row.optionalBox and row.optionalBox.Disable then
                        row.optionalBox:Disable()
                        row.optionalBox:SetAlpha(0.6)
                    end
                    if row.excludedBox and row.excludedBox.Disable then
                        row.excludedBox:Disable()
                        row.excludedBox:SetAlpha(0.6)
                    end
                    if row.mandatoryLabel then
                        row.mandatoryLabel:SetTextColor(0.6, 0.6, 0.6)
                    end
                    if row.optionalLabel then
                        row.optionalLabel:SetTextColor(0.6, 0.6, 0.6)
                    end
                    if row.excludedLabel then
                        row.excludedLabel:SetTextColor(0.6, 0.6, 0.6)
                    end
                end
            end

            row.checkbox:SetScript("OnClick", function()
                row.UpdateEnabled()
            end)
            row.labelHit:SetScript("OnClick", function()
                row.checkbox:SetChecked(not row.checkbox:GetChecked())
                row.UpdateEnabled()
            end)
            row:SetScript("OnMouseDown", function()
                row.checkbox:SetChecked(not row.checkbox:GetChecked())
                row.UpdateEnabled()
            end)

            row.mandatoryHit:SetScript("OnClick", function()
                row.SetStatus(row.mandatoryBox:GetChecked() and nil or row.mandatoryBox)
            end)
            row.optionalHit:SetScript("OnClick", function()
                row.SetStatus(row.optionalBox:GetChecked() and nil or row.optionalBox)
            end)
            row.excludedHit:SetScript("OnClick", function()
                row.SetStatus(row.excludedBox:GetChecked() and nil or row.excludedBox)
            end)

            parentFrame.plannerRows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -((i - 1) * lineHeight))
        row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -4, -((i - 1) * lineHeight))
        row:Show()

        row.checkbox:ClearAllPoints()
        row.checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)

        row.label:ClearAllPoints()
        row.label:SetPoint("LEFT", row.checkbox, "RIGHT", 6, 0)
        row.label:SetText(item.name or "")

        row.labelHit:ClearAllPoints()
        row.labelHit:SetPoint("TOPLEFT", row.label, "TOPLEFT", 0, 0)
        row.labelHit:SetPoint("BOTTOMRIGHT", row.label, "BOTTOMRIGHT", 0, 0)

        row.amountInput:ClearAllPoints()
        row.amountInput:SetPoint("RIGHT", row, "RIGHT", 8, 0)

        row.excludedLabel:ClearAllPoints()
        row.excludedLabel:SetPoint("RIGHT", row.amountInput, "LEFT", -40, 0)
        row.excludedLabel:SetText("Excluded")

        row.excludedBox:ClearAllPoints()
        row.excludedBox:SetPoint("RIGHT", row.excludedLabel, "LEFT", -4, 0)

        row.excludedHit:ClearAllPoints()
        row.excludedHit:SetPoint("TOPLEFT", row.excludedLabel, "TOPLEFT", 0, 0)
        row.excludedHit:SetPoint("BOTTOMRIGHT", row.excludedLabel, "BOTTOMRIGHT", 0, 0)

        row.optionalLabel:ClearAllPoints()
        row.optionalLabel:SetPoint("RIGHT", row.excludedBox, "LEFT", -22, 0)
        row.optionalLabel:SetText("Optional")

        row.optionalBox:ClearAllPoints()
        row.optionalBox:SetPoint("RIGHT", row.optionalLabel, "LEFT", -4, 0)

        row.optionalHit:ClearAllPoints()
        row.optionalHit:SetPoint("TOPLEFT", row.optionalLabel, "TOPLEFT", 0, 0)
        row.optionalHit:SetPoint("BOTTOMRIGHT", row.optionalLabel, "BOTTOMRIGHT", 0, 0)

        row.mandatoryLabel:ClearAllPoints()
        row.mandatoryLabel:SetPoint("RIGHT", row.optionalBox, "LEFT", -22, 0)
        row.mandatoryLabel:SetText("Mandatory")

        row.mandatoryBox:ClearAllPoints()
        row.mandatoryBox:SetPoint("RIGHT", row.mandatoryLabel, "LEFT", -4, 0)

        row.mandatoryHit:ClearAllPoints()
        row.mandatoryHit:SetPoint("TOPLEFT", row.mandatoryLabel, "TOPLEFT", 0, 0)
        row.mandatoryHit:SetPoint("BOTTOMRIGHT", row.mandatoryLabel, "BOTTOMRIGHT", 0, 0)

        if row.UpdateEnabled then
            row.UpdateEnabled()
        end
    end

    local existingCount = table.getn(parentFrame.plannerRows)
    for i = count + 1, existingCount do
        local row = parentFrame.plannerRows[i]
        if row and row.Hide then
            row:Hide()
        end
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
        local updater = parentFrame.plannerOnShowUpdate
        if not updater then
            updater = CreateFrame("Frame", nil, parentFrame)
            parentFrame.plannerOnShowUpdate = updater
        end
        updater:SetScript("OnUpdate", function()
            updater:SetScript("OnUpdate", nil)
            CE_UpdatePlannerList(parentFrame)
        end)
    end)
end

CE_UpdatePlannerList = function(parentFrame)
    if not parentFrame or not parentFrame.plannerBuilt then
        return
    end
    local width = 0
    if parentFrame.GetWidth then
        width = parentFrame:GetWidth() or 0
    end
    if width <= 0 and parentFrame.plannerScrollFrame and parentFrame.plannerScrollFrame.GetWidth then
        width = parentFrame.plannerScrollFrame:GetWidth() or 0
    end
    if parentFrame.plannerScrollChild and width > 0 then
        parentFrame.plannerScrollChild:SetWidth(width - 40)
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
    if type(CE_UpdatePlannerList) == "function" then
        CE_UpdatePlannerList(frame.tabContents[index])
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
        content.plannerTabName = raidName or ("Tab" .. i)
        frame.tabContents[i] = content
        CE_CreatePlannerList(content)
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
