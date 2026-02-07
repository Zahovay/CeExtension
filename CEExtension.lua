-- CE hooks

local orig_CreateSettingsContent = ConsumesManager_CreateSettingsContent
if type(orig_CreateSettingsContent) == "function" then
    function ConsumesManager_CreateSettingsContent(parentFrame)
        orig_CreateSettingsContent(parentFrame)
    end
end

local orig_UpdatePresetsConsumables = ConsumesManager_UpdatePresetsConsumables
if type(orig_UpdatePresetsConsumables) == "function" then
    function ConsumesManager_UpdatePresetsConsumables()
        if ConsumesManager_Options.showColdEmbrace then
            if type(CE_UpdatePresetsConsumables) == "function" then
                CE_UpdatePresetsConsumables()
            else
                orig_UpdatePresetsConsumables()
            end
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
        if type(CE_SetClassDropdownToCurrent) == "function" then
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

if ConsumesManager_Options.showColdEmbrace then
    if type(CE_InjectItemlist) == "function" then
        CE_InjectItemlist()
    end
end
