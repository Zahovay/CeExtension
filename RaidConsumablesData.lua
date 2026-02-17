-- RaidConsumablesData.lua
-- Defines consumable groups for Naxxramas prep (Classic 1.12 / Turtle WoW)

local RC = RaidConsumables or {}
RC.Data = RC.Data or {}

-- Each entry is ID-first:
--   { ids = { 13452, 12345 }, required = N }
-- or a simple array { 13452, 12345 } (required defaults to 1).
RC.Data.MandatoryGroups = {
    { ids = { 3825 }, required = 4 },
    { ids = { 3386, 19440 }, required = 5 },
    { ids = { 13457 }, required = 5 },
    { ids = { 13456 }, required = 10 },
    { ids = { 13459 }, required = 10 },
    { ids = { 13458 }, required = 10 },
    { ids = { 14530 }, required = 20 },
    { ids = { 13446 }, required = 10 },
    { ids = { 21151, 61174 }, required = 10 },
    { ids = { 20079 }, required = 2 },
    { ids = { 15723, 61675 }, required = 10 },
}

-- Optional groups can be scanned and reported but not required for "prepared".
RC.Data.OptionalGroups = {
    { ids = { 22682 }, required = 5 },
    { ids = { 12457 }, required = 5 },
    { ids = { 12450 }, required = 20 },
    { ids = { 20004 }, required = 4 },
}

-- Role-specific mandatory groups (minimal baseline; extend as needed)
RC.Data.RoleMandatory = {
    caster = {
        { ids = { 23123 }, required = 4 },
        { ids = { 84041 }, required = 4 },
        { ids = { 61224 }, required = 4 },
        { ids = { 20007 }, required = 4 },
        { ids = { 13444 }, required = 10 },
        { ids = { 20749 }, required = 4 },
        { ids = { 13454 }, required = 4 },
        { ids = { 13512 }, required = 4 },
        { ids = { 3387 }, required = 4 },
    },
    healer = {
        { ids = { 20748 }, required = 2 },
        { ids = { 61224 }, required = 4 },
        { ids = { 3387 }, required = 5 },
        { ids = { 20007 }, required = 4 },
        { ids = { 13444 }, required = 10 },
        { ids = { 21217 }, required = 20 },
    },
    melee = {
        { ids = { 13810 }, required = 20 },
        { ids = { 23122 }, required = 4 },
        { ids = { 60976 }, required = 20 },
        { ids = { 12404, 18262 }, required = 1 },
        { ids = { 61224 }, required = 4 },
        { ids = { 9206 }, required = 4 },
        { ids = { 13452 }, required = 4 },
        { ids = { 5634 }, required = 5 },
        { ids = { 13454 }, required = 4 },
        { ids = { 3387 }, required = 5 },
    },
    tank = {
        { ids = { 13455 }, required = 10 },
        { ids = { 13510 }, required = 2 },
        { ids = { 23123 }, required = 4 },
        { ids = { 20749 }, required = 1 },
        { ids = { 23122 }, required = 4 },
        { ids = { 12404, 18262 }, required = 1 },
        { ids = { 61224 }, required = 4 },
        { ids = { 9206 }, required = 4 },
        { ids = { 13445 }, required = 4 },
        { ids = { 13452 }, required = 4 },
        { ids = { 5634 }, required = 5 },
        { ids = { 13454 }, required = 4 },
        { ids = { 51717, 21023 }, required = 20 },
    },
    ranged = {
        { ids = { 60976 }, required = 20 },
        { ids = { 13810 }, required = 20 },
    },
}

RC.Data.SpecMandatory = {
    ["Fire Mage"] = {
        { ids = { 21546 }, required = 4 },
    },
    ["Frost Mage"] = {
        { ids = { 17708 }, required = 4 },
    },
    ["Arcane Mage"] = {
        { ids = { 13454 }, required = 4 },
    },
    ["Shadow Priest"] = {
        { ids = { 9264 }, required = 4 },
    },
    ["Affliction Warlock"] = {
        { ids = { 9264 }, required = 4 },
    },
    ["Fire Warlock"] = {
        { ids = { 21546 }, required = 4 },
    },
}

RC.Data.AdditionalItems = {
    {
        id = 19440,
        name = "Powerful Anti-Venom",
        category = "Protection Potions",
        mats = { "Looted or purchased" },
        texture = "Interface\\Icons\\INV_DRINK_14",
        description = "Cures poison effects."
    },
    {
        id = 15723,
        name = "Tea with Sugar",
        category = "Protection Potions",
        mats = { "Looted or purchased" },
        texture = "Interface\\Icons\\INV_DRINK_15",
        description = "Restores health and mana."
    },
    {
        id = 22682,
        name = "Frozen Rune",
        category = "Protection Potions",
        mats = { "Looted or purchased" },
        texture = "Interface\\Icons\\INV_MISC_RUNE_09",
        description = "Restores health and mana."
    },
    {
        id = 13810,
        name = "Blessed Sunfruit",
        category = "Food Buffs",
        mats = { "Looted or purchased" },
        texture = "Interface\\Icons\\INV_Misc_Food_41",
        description = "Restores health over time."
    },
    {
        id = 51711,
        name = "Sour Mountain Berry",
        category = "Food Buffs",
        mats = { "Looted or purchased" },
        texture = "Interface\\Icons\\INV_Misc_Food_74",
        description = "Restores health over time."
    },
}

RaidConsumables = RC
