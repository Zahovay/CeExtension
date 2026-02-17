-- CE itemlist injection

local CE_InjectedState = {
    itemsById = {},
    addedCategories = {}
}

local function CE_GetAdditionalItems()
    local data = RaidConsumables and RaidConsumables.Data
    if not data or type(data.AdditionalItems) ~= "table" then
        return {}
    end
    return data.AdditionalItems
end

local function CE_ForEachAdditionalItem(fn)
    if type(fn) ~= "function" then
        return
    end
    local items = CE_GetAdditionalItems()
    local i = 1
    while items[i] do
        fn(items[i])
        i = i + 1
    end
end

local function CE_AddToConsumablesLookups(item)
    if not item then
        return
    end
    if type(consumablesList) == "table" then
        consumablesList[item.id] = item.name
    end
    if type(consumablesTexture) == "table" then
        consumablesTexture[item.id] = item.texture
    end
    if type(consumablesDescription) == "table" then
        consumablesDescription[item.id] = item.description
    end
    if type(consumablesMats) == "table" then
        consumablesMats[item.id] = item.mats or {}
    end
end

local function CE_RemoveFromConsumablesLookups(item)
    if not item then
        return
    end
    if type(consumablesList) == "table" then
        consumablesList[item.id] = nil
    end
    if type(consumablesTexture) == "table" then
        consumablesTexture[item.id] = nil
    end
    if type(consumablesDescription) == "table" then
        consumablesDescription[item.id] = nil
    end
    if type(consumablesMats) == "table" then
        consumablesMats[item.id] = nil
    end
end

local function CE_FindItemIndex(categoryList, itemId)
    if type(categoryList) ~= "table" then
        return nil
    end
    for i = 1, table.getn(categoryList) do
        local entry = categoryList[i]
        if entry and entry.id == itemId then
            return i
        end
    end
    return nil
end

function CE_InjectItemlist()
    if type(consumablesCategories) ~= "table" then
        return
    end

    CE_ForEachAdditionalItem(function(item)
        local categoryName = item.category or "Utility Items"
        local category = consumablesCategories[categoryName]
        if not category then
            category = {}
            consumablesCategories[categoryName] = category
            CE_InjectedState.addedCategories[categoryName] = true
        end

        if not CE_FindItemIndex(category, item.id) then
            table.insert(category, {
                id = item.id,
                name = item.name,
                mats = item.mats,
                texture = item.texture,
                description = item.description
            })
            CE_InjectedState.itemsById[item.id] = categoryName
            CE_AddToConsumablesLookups(item)
        end
    end)
end

function CE_RemoveInjectedItemlist()
    if type(consumablesCategories) ~= "table" then
        return
    end

    CE_ForEachAdditionalItem(function(item)
        local categoryName = CE_InjectedState.itemsById[item.id]
        local category = categoryName and consumablesCategories[categoryName] or nil
        if category then
            local index = CE_FindItemIndex(category, item.id)
            if index then
                table.remove(category, index)
                CE_RemoveFromConsumablesLookups(item)
            end
        end
        CE_InjectedState.itemsById[item.id] = nil
    end)

    for categoryName in pairs(CE_InjectedState.addedCategories) do
        local category = consumablesCategories[categoryName]
        if category and table.getn(category) == 0 then
            consumablesCategories[categoryName] = nil
        end
        CE_InjectedState.addedCategories[categoryName] = nil
    end
end
