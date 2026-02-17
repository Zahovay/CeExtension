-- ConsumesManager CE (Cold Embrace) extension init

ConsumesManager_ColdEmbraceRequirements = ConsumesManager_ColdEmbraceRequirements or {}

ConsumesManager_Options = ConsumesManager_Options or {}
ConsumesManager_Options.showColdEmbrace = ConsumesManager_Options.showColdEmbrace or false

-- When enabled, opening the main window / planner will auto-detect the player's
-- class + primary talent tab and switch the class selector accordingly.
-- Default: enabled (preserves old behavior).
if ConsumesManager_Options.ceAutoSelectClass == nil then
	ConsumesManager_Options.ceAutoSelectClass = true
end
