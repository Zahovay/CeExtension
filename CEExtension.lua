-- CE hooks

local orig_UpdatePresetsConsumables = ConsumesManager_UpdatePresetsConsumables
if type(orig_UpdatePresetsConsumables) == "function" then
    function ConsumesManager_UpdatePresetsConsumables()
        -- Only do heavy UI work when the main window is actually visible.
        -- This prevents background events (e.g. sync updates) from doing full
        -- Presets re-renders while the UI is closed.
        if ConsumesManager_MainFrame and ConsumesManager_MainFrame.IsShown and not ConsumesManager_MainFrame:IsShown() then
            return
        end
        if ConsumesManager_Options.showColdEmbrace then
            -- In CE mode, render Presets with owned/required counts.
            if type(CE_UpdatePresetsConsumables) == "function" then
                CE_UpdatePresetsConsumables()
            else
                orig_UpdatePresetsConsumables()
            end
        else
            orig_UpdatePresetsConsumables()
        end

        if ConsumesManager_Options.showColdEmbrace and type(CE_UpdateBuyConsumables) == "function" then
            local buyContent = ConsumesManager_MainFrame and ConsumesManager_MainFrame.CEBuyTabContent
            if buyContent and buyContent.IsShown and buyContent:IsShown() then
                CE_UpdateBuyConsumables()
            end
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
                if type(CE_InitClassDropdown) == "function" then
                    CE_InitClassDropdown(classDropdown)
                end
            end)
        end
    end
end

local orig_UpdateRaidsDropdown = ConsumesManager_UpdateRaidsDropdown
if type(orig_UpdateRaidsDropdown) == "function" then
    function ConsumesManager_UpdateRaidsDropdown()
        if ConsumesManager_Options.showColdEmbrace then
            if type(CE_UpdateRaidsDropdown) == "function" then
                CE_UpdateRaidsDropdown()
            else
                orig_UpdateRaidsDropdown()
            end
        else
            orig_UpdateRaidsDropdown()
        end
    end
end

local orig_ShowMainWindow = ConsumesManager_ShowMainWindow
if type(orig_ShowMainWindow) == "function" then
    function ConsumesManager_ShowMainWindow()
        orig_ShowMainWindow()
        if type(CE_CreateCETab) == "function" then
            CE_CreateCETab()
        end
        if type(CE_UpdateBuyTabState) == "function" then
            CE_UpdateBuyTabState()
        end
        local autoSelect = (ConsumesManager_Options and ConsumesManager_Options.ceAutoSelectClass ~= false) and true or false
        if autoSelect and type(CE_SetClassDropdownToCurrent) == "function" then
            CE_SetClassDropdownToCurrent()
        end
        if type(CE_SetRaidDropdownToNaxxramas) == "function" then
            CE_SetRaidDropdownToNaxxramas()
        end
        if type(CE_UpdateFooterText) == "function" then
            CE_UpdateFooterText()
        end
    end
end

local orig_CreateMainWindow = ConsumesManager_CreateMainWindow
if type(orig_CreateMainWindow) == "function" then
    function ConsumesManager_CreateMainWindow()
        orig_CreateMainWindow()
        if type(CE_CreateCETab) == "function" then
            CE_CreateCETab()
        end
        if type(CE_UpdateBuyTabState) == "function" then
            CE_UpdateBuyTabState()
        end
    end
end

local orig_ShowConsumableTooltip = ConsumesManager_ShowConsumableTooltip
if type(orig_ShowConsumableTooltip) == "function" then
    function ConsumesManager_ShowConsumableTooltip(itemID)
        if ConsumesManager_Options.showColdEmbrace and CE_TooltipAllowed and CE_TooltipAllowed[itemID] then
            ConsumesManager_SelectedItems = ConsumesManager_SelectedItems or {}
            local restoreSelected = false
            if not ConsumesManager_SelectedItems[itemID] then
                restoreSelected = true
                ConsumesManager_SelectedItems[itemID] = true
            end
            orig_ShowConsumableTooltip(itemID)
            if restoreSelected then
                ConsumesManager_SelectedItems[itemID] = nil
            end
            return
        end
        orig_ShowConsumableTooltip(itemID)
    end
end

local orig_IsItemInPresets = ConsumesManager_IsItemInPresets
if type(orig_IsItemInPresets) == "function" then
    function ConsumesManager_IsItemInPresets(itemID)
        if ConsumesManager_Options.showColdEmbrace and type(CE_EnsurePresetTabDefaults) == "function" then
            local store = CE_EnsurePresetTabDefaults()
            if type(store) == "table" then
                for _, presets in pairs(store) do
                    if type(presets) == "table" then
                        for i = 1, table.getn(presets) do
                            local preset = presets[i]
                            if preset and type(preset.id) == "table" then
                                for j = 1, table.getn(preset.id) do
                                    if preset.id[j] == itemID then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
                return false
            end
        end
        return orig_IsItemInPresets(itemID)
    end
end

if ConsumesManager_Options.showColdEmbrace then
    if type(CE_InjectItemlist) == "function" then
        CE_InjectItemlist()
    end
end
