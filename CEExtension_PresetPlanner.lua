-- CE raid consumables planner window

local function CE_GetPresetWindowSize()
    local mainFrame = ConsumesManager_MainFrame
    local baseWidth = (mainFrame and mainFrame.GetWidth and mainFrame:GetWidth()) or WindowWidth or 480
    local baseHeight = (mainFrame and mainFrame.GetHeight and mainFrame:GetHeight()) or 512
    return math.floor(baseWidth + 450), math.floor(baseHeight - 100)
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

local function CE_GetPlannerItems(raidName)
    raidName = CE_NormalizeRaidName and CE_NormalizeRaidName(raidName) or (raidName or "Naxxramas")

    local selectedClass = ConsumesManager_SelectedClass
    if type(selectedClass) ~= "string" then
        selectedClass = ""
    end

    local results = {}
    local seen = {}

    local function getName(itemId)
        if type(consumablesList) == "table" then
            local name = consumablesList[itemId]
            if type(name) == "string" then
                return name
            end
        end
        return ""
    end

    -- Keep the planner list stable across raid selection by including the union of
    -- all items configured for this class across all raids (both selected ids and
    -- requirement metadata).
    if selectedClass ~= "" and type(CE_EnsurePresetTabDefaults) == "function" then
        local store = CE_EnsurePresetTabDefaults()
        local presets = store and store[selectedClass]
        if type(presets) == "table" then
            for pi = 1, table.getn(presets) do
                local entry = presets[pi]
                if type(entry) == "table" then
                    if type(entry.req) == "table" then
                        for itemId in pairs(entry.req) do
                            if type(itemId) == "number" and not seen[itemId] then
                                local name = getName(itemId)
                                if name == "" then
                                    name = tostring(itemId)
                                end
                                table.insert(results, { id = itemId, name = name })
                                seen[itemId] = true
                            end
                        end
                    end
                    if type(entry.id) == "table" then
                        for i = 1, table.getn(entry.id) do
                            local itemId = entry.id[i]
                            if type(itemId) == "number" and not seen[itemId] then
                                local name = getName(itemId)
                                if name == "" then
                                    name = tostring(itemId)
                                end
                                table.insert(results, { id = itemId, name = name })
                                seen[itemId] = true
                            end
                        end
                    end
                end
            end
        end
    end

    -- Also include potion-like items so users can add extras easily.
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

    local selectedClass = ConsumesManager_SelectedClass
    if type(selectedClass) ~= "string" then
        selectedClass = ""
    end

    local lineHeight = 24
    local count = table.getn(items)
    if selectedClass == "" then
        local emptyLabel = parentFrame.plannerEmptyLabel
        if not emptyLabel then
            emptyLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            parentFrame.plannerEmptyLabel = emptyLabel
        end
        emptyLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)
        emptyLabel:SetText("Select a Class.")
        emptyLabel:SetJustifyH("LEFT")
        emptyLabel:Show()
        scrollChild:SetHeight(lineHeight)
        return
    end

    if count == 0 then
        local emptyLabel = parentFrame.plannerEmptyLabel
        if not emptyLabel then
            emptyLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            parentFrame.plannerEmptyLabel = emptyLabel
        end
        emptyLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, -10)
        emptyLabel:SetText("No preset items found for this raid.")
        emptyLabel:SetJustifyH("LEFT")
        emptyLabel:Show()
        scrollChild:SetHeight(lineHeight)
        return
    end

    if parentFrame.plannerEmptyLabel then
        parentFrame.plannerEmptyLabel:Hide()
    end

    local raidName = parentFrame.plannerTabName or "Naxxramas"
    local tabName = raidName
    tabName = string.gsub(tabName, "%s+", "")

    local presetSet = {}
    if selectedClass ~= "" and type(CE_GetPresetIdsFor) == "function" then
        local ids = CE_GetPresetIdsFor(selectedClass, raidName)
        if type(ids) == "table" then
            for i = 1, table.getn(ids) do
                local itemId = ids[i]
                if type(itemId) == "number" then
                    presetSet[itemId] = true
                end
            end
        end
    end

    -- Load requirements metadata for this preset.
    local reqById = {}
    if selectedClass ~= "" and type(CE_GetPresetEntry) == "function" then
        local entry = CE_GetPresetEntry(selectedClass, raidName)
        if entry and type(entry.req) == "table" then
            reqById = entry.req
        end
    end

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
                if target then
                    target:SetChecked(true)
                end
            end

            row.optionalBox:SetScript("OnClick", function()
                row.SetStatus(row.optionalBox:GetChecked() and row.optionalBox or nil)
                if row.SaveState then
                    row.SaveState()
                end
            end)

            row.mandatoryBox:SetScript("OnClick", function()
                row.SetStatus(row.mandatoryBox:GetChecked() and row.mandatoryBox or nil)
                if row.SaveState then
                    row.SaveState()
                end
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
                    if row.mandatoryHit and row.mandatoryHit.Enable then
                        row.mandatoryHit:Enable()
                        row.mandatoryHit:SetAlpha(1)
                    end
                    if row.optionalHit and row.optionalHit.Enable then
                        row.optionalHit:Enable()
                        row.optionalHit:SetAlpha(1)
                    end
                    if row.mandatoryLabel then
                        row.mandatoryLabel:SetTextColor(1, 1, 1)
                    end
                    if row.optionalLabel then
                        row.optionalLabel:SetTextColor(1, 1, 1)
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
                    if row.mandatoryHit and row.mandatoryHit.Disable then
                        row.mandatoryHit:Disable()
                        row.mandatoryHit:SetAlpha(0.6)
                    end
                    if row.optionalHit and row.optionalHit.Disable then
                        row.optionalHit:Disable()
                        row.optionalHit:SetAlpha(0.6)
                    end
                    if row.mandatoryLabel then
                        row.mandatoryLabel:SetTextColor(0.6, 0.6, 0.6)
                    end
                    if row.optionalLabel then
                        row.optionalLabel:SetTextColor(0.6, 0.6, 0.6)
                    end
                end
            end

            row.checkbox:SetScript("OnClick", function()
                row.UpdateEnabled()
                if row.SaveState then
                    row.SaveState()
                end
            end)
            row.labelHit:SetScript("OnClick", function()
                row.checkbox:SetChecked(not row.checkbox:GetChecked())
                row.UpdateEnabled()
                if row.SaveState then
                    row.SaveState()
                end
            end)
            row:SetScript("OnMouseDown", function()
                row.checkbox:SetChecked(not row.checkbox:GetChecked())
                row.UpdateEnabled()
                if row.SaveState then
                    row.SaveState()
                end
            end)

            row.mandatoryHit:SetScript("OnClick", function()
                if row.checkbox:GetChecked() ~= 1 then
                    return
                end
                row.SetStatus(row.mandatoryBox:GetChecked() and nil or row.mandatoryBox)
                if row.SaveState then
                    row.SaveState()
                end
            end)
            row.optionalHit:SetScript("OnClick", function()
                if row.checkbox:GetChecked() ~= 1 then
                    return
                end
                row.SetStatus(row.optionalBox:GetChecked() and nil or row.optionalBox)
                if row.SaveState then
                    row.SaveState()
                end
            end)

            -- Saving on every keypress causes lots of refresh churn.
            -- Save amount when the user finishes editing (focus lost / Enter).
            row.amountInput:SetScript("OnEnterPressed", function()
                row.amountInput:ClearFocus()
            end)
            row.amountInput:SetScript("OnEditFocusLost", function()
                if row.SaveAmount then
                    row.SaveAmount()
                end
            end)

            parentFrame.plannerRows[i] = row
        end

        -- Ensure row reflects stored state (and persists changes back).
        row.itemId = item and item.id or nil
        row._applyingState = true
        local enabled = row.itemId and presetSet[row.itemId] and true or false
        row.checkbox:SetChecked(enabled and 1 or 0)

        -- Restore amount/status controls; values come from requirements metadata.
        if row.amountInput then row.amountInput:Show() end
        if row.optionalBox then row.optionalBox:Show() end
        if row.optionalLabel then row.optionalLabel:Show() end
        if row.optionalHit then row.optionalHit:Show() end
        if row.mandatoryBox then row.mandatoryBox:Show() end
        if row.mandatoryLabel then row.mandatoryLabel:Show() end
        if row.mandatoryHit then row.mandatoryHit:Show() end

        local req = row.itemId and reqById and reqById[row.itemId] or nil
        local amt = req and tonumber(req.amount) or 0
        if row.amountInput and row.amountInput.SetText then
            row.amountInput:SetText(tostring(amt))
        end
        local status = req and req.status or "mandatory"
        if status == "optional" then
            row.SetStatus(row.optionalBox)
        else
            row.SetStatus(row.mandatoryBox)
        end
        row._applyingState = false

        row.SaveState = function()
            if row._applyingState then
                return
            end
            if selectedClass == "" or type(CE_TogglePresetItem) ~= "function" then
                return
            end

            local itemId = tonumber(row.itemId)
            if not itemId then
                return
            end
            local isEnabled = row.checkbox:GetChecked() == 1
            CE_TogglePresetItem(selectedClass, raidName, itemId, isEnabled)
            local status = (row.optionalBox and row.optionalBox.GetChecked and row.optionalBox:GetChecked() == 1) and "optional" or "mandatory"
            if type(CE_SetPresetReqFor) == "function" then
                -- Preserve amount here; amount is saved separately on focus-loss.
                CE_SetPresetReqFor(selectedClass, raidName, itemId, nil, status)
            end
            if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
                ConsumesManager_UpdatePresetsConsumables()
            end
        end

        row.SaveAmount = function()
            if row._applyingState then
                return
            end
            if selectedClass == "" or type(CE_SetPresetReqFor) ~= "function" then
                return
            end

            local itemId = tonumber(row.itemId)
            if not itemId then
                return
            end

            local amountText = row.amountInput and row.amountInput.GetText and row.amountInput:GetText() or "0"
            local amount = tonumber(amountText) or 0
            CE_SetPresetReqFor(selectedClass, raidName, itemId, amount, nil)
            if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
                ConsumesManager_UpdatePresetsConsumables()
            end
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

        row.optionalLabel:ClearAllPoints()
        row.optionalLabel:SetPoint("RIGHT", row.amountInput, "LEFT", -40, 0)
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

local function CE_GetPlannerOrderedRaids()
    local cfg = CE_GetConfig()
    local raids = (cfg and cfg.ORDERED_RAIDS) or {}
    return type(raids) == "table" and raids or {}
end

local function CE_GetDefaultCopyFromRaid(currentRaid)
    local raids = CE_GetPlannerOrderedRaids()
    local normalizedCurrent = CE_NormalizeRaidName and CE_NormalizeRaidName(currentRaid) or currentRaid
    for i = 1, table.getn(raids) do
        local r = raids[i]
        if type(r) == "string" then
            local nr = CE_NormalizeRaidName and CE_NormalizeRaidName(r) or r
            if nr ~= normalizedCurrent then
                return r
            end
        end
    end
    return nil
end

local function CE_UpdatePlannerCopyControls(parentFrame)
    if not parentFrame then
        return
    end

    local currentRaid = parentFrame.plannerTabName or ""
    local raids = CE_GetPlannerOrderedRaids()
    local hasOtherRaid = false
    local normalizedCurrent = CE_NormalizeRaidName and CE_NormalizeRaidName(currentRaid) or currentRaid
    for i = 1, table.getn(raids) do
        local r = raids[i]
        if type(r) == "string" then
            local nr = CE_NormalizeRaidName and CE_NormalizeRaidName(r) or r
            if nr ~= normalizedCurrent then
                hasOtherRaid = true
                break
            end
        end
    end

    if not hasOtherRaid then
        parentFrame.copyFromRaid = nil
        if parentFrame.copyFromButton then
            parentFrame.copyFromButton:Disable()
        end
        if parentFrame.copyFromDropDown and UIDropDownMenu_SetText then
            UIDropDownMenu_SetText("-", parentFrame.copyFromDropDown)
        end
        return
    end

    if type(parentFrame.copyFromRaid) ~= "string" or parentFrame.copyFromRaid == "" then
        parentFrame.copyFromRaid = CE_GetDefaultCopyFromRaid(currentRaid)
    else
        local normalizedSelected = CE_NormalizeRaidName and CE_NormalizeRaidName(parentFrame.copyFromRaid) or parentFrame.copyFromRaid
        if normalizedSelected == normalizedCurrent then
            parentFrame.copyFromRaid = CE_GetDefaultCopyFromRaid(currentRaid)
        end
    end

    if parentFrame.copyFromDropDown and UIDropDownMenu_SetSelectedValue then
        UIDropDownMenu_SetSelectedValue(parentFrame.copyFromDropDown, parentFrame.copyFromRaid)
        if UIDropDownMenu_SetText then
            UIDropDownMenu_SetText(parentFrame.copyFromRaid or "-", parentFrame.copyFromDropDown)
        end
    end
    if parentFrame.copyFromButton then
        parentFrame.copyFromButton:Enable()
    end
end

local function CE_CreatePlannerList(parentFrame)
    if not parentFrame or parentFrame.plannerBuilt then
        return
    end

    -- Header row (space for planner actions)
    local header = CreateFrame("Frame", nil, parentFrame)
    header:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -4)
    header:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -8, -4)
    header:SetHeight(54)
    parentFrame.plannerHeader = header

    local row1 = CreateFrame("Frame", nil, header)
    row1:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
    row1:SetPoint("TOPRIGHT", header, "TOPRIGHT", 0, 0)
    row1:SetHeight(26)

    local row2 = CreateFrame("Frame", nil, header)
    row2:SetPoint("TOPLEFT", row1, "BOTTOMLEFT", 0, 0)
    row2:SetPoint("TOPRIGHT", row1, "BOTTOMRIGHT", 0, 0)
    row2:SetHeight(26)

    -- Search (left)
    local searchLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("LEFT", row2, "LEFT", 0, 0)
    searchLabel:SetText("Search:")
    searchLabel:SetWidth(50)
    searchLabel:SetJustifyH("RIGHT")
    parentFrame.searchLabel = searchLabel

    local searchInputName = "CEPlannerSearchInput_" .. (string.gsub(parentFrame.plannerTabName or "", "%s+", ""))
    local searchInput = CreateFrame("EditBox", searchInputName, header, "InputBoxTemplate")
    searchInput:SetWidth(180)
    searchInput:SetHeight(16)
    searchInput:SetAutoFocus(false)
    searchInput:SetPoint("LEFT", searchLabel, "RIGHT", 30, 0)
    searchInput:SetText(parentFrame.searchText or "")
    searchInput:SetScript("OnTextChanged", function()
        parentFrame.searchText = this:GetText() or ""
        if type(CE_UpdatePlannerList) == "function" then
            CE_UpdatePlannerList(parentFrame)
        end
    end)
    searchInput:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    parentFrame.searchInput = searchInput

    local tabName = parentFrame.plannerTabName or ""
    tabName = string.gsub(tabName, "%s+", "")

    -- Selected-only filter (shared across all raid tabs)
    local selectedOnlyBox = CreateFrame("CheckButton", nil, header)
    selectedOnlyBox:SetWidth(16)
    selectedOnlyBox:SetHeight(16)
    selectedOnlyBox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    selectedOnlyBox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    selectedOnlyBox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    selectedOnlyBox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    selectedOnlyBox:SetPoint("LEFT", searchInput, "RIGHT", 14, 0)

    local selectedOnlyLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    selectedOnlyLabel:SetPoint("LEFT", selectedOnlyBox, "RIGHT", 4, 0)
    selectedOnlyLabel:SetText("Selected only")

    local owner = parentFrame.GetParent and parentFrame:GetParent() or nil
    selectedOnlyBox:SetChecked(owner and owner.cePlannerSelectedOnly and true or false)

    local function CE_ApplySelectedOnly(checked)
        local o = parentFrame.GetParent and parentFrame:GetParent() or nil
        if o then
            o.cePlannerSelectedOnly = checked and true or false
            if type(o.tabContents) == "table" and type(CE_UpdatePlannerList) == "function" then
                for i = 1, table.getn(o.tabContents) do
                    CE_UpdatePlannerList(o.tabContents[i])
                end
            elseif type(CE_UpdatePlannerList) == "function" then
                CE_UpdatePlannerList(parentFrame)
            end
        elseif type(CE_UpdatePlannerList) == "function" then
            CE_UpdatePlannerList(parentFrame)
        end
    end

    selectedOnlyBox:SetScript("OnClick", function()
        CE_ApplySelectedOnly(this:GetChecked() and true or false)
    end)

    local selectedOnlyHit = CreateFrame("Button", nil, header)
    selectedOnlyHit:EnableMouse(true)
    selectedOnlyHit:SetPoint("TOPLEFT", selectedOnlyLabel, "TOPLEFT", -2, 2)
    selectedOnlyHit:SetPoint("BOTTOMRIGHT", selectedOnlyLabel, "BOTTOMRIGHT", 2, -2)
    selectedOnlyHit:SetScript("OnClick", function()
        local checked = not (selectedOnlyBox:GetChecked() and true or false)
        selectedOnlyBox:SetChecked(checked)
        CE_ApplySelectedOnly(checked)
    end)
    parentFrame.selectedOnlyHit = selectedOnlyHit
    parentFrame.selectedOnlyBox = selectedOnlyBox
    parentFrame.selectedOnlyLabel = selectedOnlyLabel

    local copyButton = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    copyButton:SetWidth(70)
    copyButton:SetHeight(20)
    copyButton:SetPoint("RIGHT", row1, "RIGHT", 0, 0)
    copyButton:SetText("Copy")
    if copyButton.GetFontString and copyButton:GetFontString() then
        copyButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
    end
    copyButton:SetScript("OnClick", function()
        local selectedClass = ConsumesManager_SelectedClass
        if type(selectedClass) ~= "string" or selectedClass == "" then
            return
        end
        local fromRaid = parentFrame.copyFromRaid
        local toRaid = parentFrame.plannerTabName
        if type(fromRaid) ~= "string" or fromRaid == "" or type(toRaid) ~= "string" or toRaid == "" then
            return
        end
        if type(CE_CopyPresetRaidConfig) == "function" then
            local ok = CE_CopyPresetRaidConfig(selectedClass, fromRaid, toRaid)
            if ok and type(CE_UpdatePlannerList) == "function" then
                CE_UpdatePlannerList(parentFrame)
            end
        end
    end)
    parentFrame.copyFromButton = copyButton

    local dropDownName = "CEPlannerCopyFromDropDown_" .. tabName
    local copyDropDown = CreateFrame("Frame", dropDownName, header, "UIDropDownMenuTemplate")
    copyDropDown:SetPoint("RIGHT", copyButton, "LEFT", -10, -2)
    UIDropDownMenu_SetWidth(150, copyDropDown)
    UIDropDownMenu_Initialize(copyDropDown, function()
        local raids = CE_GetPlannerOrderedRaids()
        local current = parentFrame.plannerTabName or ""
        local normalizedCurrent = CE_NormalizeRaidName and CE_NormalizeRaidName(current) or current

        for i = 1, table.getn(raids) do
            local raidName = raids[i]
            if type(raidName) == "string" then
                local normalizedRaid = CE_NormalizeRaidName and CE_NormalizeRaidName(raidName) or raidName
                if normalizedRaid ~= normalizedCurrent then
                    local info = {}
                    info.text = raidName
                    info.value = raidName
                    info.func = function()
                        parentFrame.copyFromRaid = raidName
                        UIDropDownMenu_SetSelectedValue(copyDropDown, raidName)
                        if UIDropDownMenu_SetText then
                            UIDropDownMenu_SetText(raidName, copyDropDown)
                        end
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end
        end
    end)
    parentFrame.copyFromDropDown = copyDropDown

    local copyLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    copyLabel:SetPoint("RIGHT", copyDropDown, "LEFT", 0, 0)
    copyLabel:SetText("Copy from:")
    parentFrame.copyFromLabel = copyLabel

    -- Class/talent selector (same data as Presets tab selector)
    local classLabel = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    classLabel:SetPoint("LEFT", row1, "LEFT", 0, 0)
    classLabel:SetText("Class:")
    classLabel:SetWidth(50)
    classLabel:SetJustifyH("RIGHT")
    parentFrame.classLabel = classLabel

    local classDropDownName = "CEPlannerClassDropDown_" .. tabName
    local classDropDown = CreateFrame("Frame", classDropDownName, header, "UIDropDownMenuTemplate")
    classDropDown:SetPoint("LEFT", classLabel, "RIGHT", 6, -2)
    UIDropDownMenu_SetWidth(170, classDropDown)
    parentFrame.classDropDown = classDropDown

    UIDropDownMenu_Initialize(classDropDown, function()
        local useCE = ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace
        local entries = (useCE and type(CE_BuildTalentClassList) == "function" and CE_BuildTalentClassList())
            or (type(CE_BuildOriginalClassList) == "function" and CE_BuildOriginalClassList())
            or {}
        local cfg = useCE and type(CE_GetConfig) == "function" and CE_GetConfig() or nil

        local idx = 1
        while entries[idx] do
            local cName = entries[idx]
            local cIndex = idx
            local info = {}
            local lastWord = type(CE_GetLastWord) == "function" and CE_GetLastWord(cName) or ""
            local color = (cfg and cfg.CLASS_COLORS and cfg.CLASS_COLORS[lastWord]) or "ffffff"
            info.text = "|cff" .. color .. cName .. "|r"
            info.func = function()
                UIDropDownMenu_SetSelectedID(classDropDown, cIndex)
                ConsumesManager_SelectedClass = cName
                if not useCE and type(ConsumesManager_UpdateRaidsDropdown) == "function" then
                    ConsumesManager_UpdateRaidsDropdown()
                end
                if type(ConsumesManager_UpdatePresetsConsumables) == "function" then
                    ConsumesManager_UpdatePresetsConsumables()
                end

                local owner = parentFrame.GetParent and parentFrame:GetParent() or nil
                if owner and type(owner.tabContents) == "table" and type(CE_UpdatePlannerList) == "function" then
                    for i = 1, table.getn(owner.tabContents) do
                        CE_UpdatePlannerList(owner.tabContents[i])
                    end
                elseif type(CE_UpdatePlannerList) == "function" then
                    CE_UpdatePlannerList(parentFrame)
                end
            end
            UIDropDownMenu_AddButton(info)
            idx = idx + 1
        end
    end)

    local scrollFrame = CreateFrame("ScrollFrame", nil, parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 8, -60)
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

    CE_UpdatePlannerCopyControls(parentFrame)

    -- Keep class dropdown in sync with the Presets tab selection.
    if parentFrame.classDropDown and type(UIDropDownMenu_SetSelectedID) == "function" then
        local selectedClass = ConsumesManager_SelectedClass
        local useCE = ConsumesManager_Options and ConsumesManager_Options.showColdEmbrace
        local entries = (useCE and type(CE_BuildTalentClassList) == "function" and CE_BuildTalentClassList())
            or (type(CE_BuildOriginalClassList) == "function" and CE_BuildOriginalClassList())
            or {}
        local cfg = useCE and type(CE_GetConfig) == "function" and CE_GetConfig() or nil

        local selectedIndex = 0
        if type(selectedClass) == "string" and selectedClass ~= "" then
            for i = 1, table.getn(entries) do
                if entries[i] == selectedClass then
                    selectedIndex = i
                    break
                end
            end
        end

        if selectedIndex > 0 then
            UIDropDownMenu_SetSelectedID(parentFrame.classDropDown, selectedIndex)
            if type(UIDropDownMenu_SetText) == "function" then
                local lastWord = type(CE_GetLastWord) == "function" and CE_GetLastWord(selectedClass) or ""
                local color = (cfg and cfg.CLASS_COLORS and cfg.CLASS_COLORS[lastWord]) or "ffffff"
                UIDropDownMenu_SetText("|cff" .. color .. selectedClass .. "|r", parentFrame.classDropDown)
            end
        else
            UIDropDownMenu_SetSelectedID(parentFrame.classDropDown, 0)
            if type(UIDropDownMenu_SetText) == "function" then
                UIDropDownMenu_SetText("Select |cffffff00Class|r", parentFrame.classDropDown)
            end
        end
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
    local items = CE_GetPlannerItems(parentFrame.plannerTabName)

    -- Apply selected-only filter if enabled (state is shared on the owner frame).
    local owner = parentFrame.GetParent and parentFrame:GetParent() or nil
    local selectedOnly = owner and owner.cePlannerSelectedOnly and true or false
    if parentFrame.selectedOnlyBox and parentFrame.selectedOnlyBox.GetChecked then
        local isChecked = parentFrame.selectedOnlyBox:GetChecked() and true or false
        if isChecked ~= selectedOnly then
            parentFrame.selectedOnlyBox:SetChecked(selectedOnly)
        end
    end

    local q = parentFrame.searchText
    if type(q) == "string" then
        q = string.lower(string.gsub(q, "^%s+", ""))
        q = string.lower(string.gsub(q, "%s+$", ""))
    else
        q = ""
    end
    if q ~= "" and type(items) == "table" then
        local filtered = {}
        for i = 1, table.getn(items) do
            local item = items[i]
            if item then
                local nameLower = type(item.name) == "string" and string.lower(item.name) or ""
                local idText = item.id and tostring(item.id) or ""
                if (nameLower ~= "" and string.find(nameLower, q, 1, true) ~= nil)
                    or (idText ~= "" and string.find(string.lower(idText), q, 1, true) ~= nil) then
                    table.insert(filtered, item)
                end
            end
        end
        items = filtered
    end

    if selectedOnly and type(items) == "table" then
        local selectedClass = ConsumesManager_SelectedClass
        if type(selectedClass) == "string" and selectedClass ~= "" and type(CE_GetPresetIdsFor) == "function" then
            local presetSet = {}
            local ids = CE_GetPresetIdsFor(selectedClass, parentFrame.plannerTabName)
            if type(ids) == "table" then
                for i = 1, table.getn(ids) do
                    local itemId = ids[i]
                    if type(itemId) == "number" then
                        presetSet[itemId] = true
                    end
                end
            end

            local filtered = {}
            for i = 1, table.getn(items) do
                local item = items[i]
                local itemId = item and item.id
                if type(itemId) == "number" and presetSet[itemId] then
                    table.insert(filtered, item)
                end
            end
            items = filtered
        end
    end

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
        local raidName = raids[i]
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

    local autoSelect = (ConsumesManager_Options and ConsumesManager_Options.ceAutoSelectClass ~= false) and true or false
    if autoSelect and type(CE_SetClassDropdownToCurrent) == "function" then
        CE_SetClassDropdownToCurrent()
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
