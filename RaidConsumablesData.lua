-- RaidConsumablesData.lua
-- Defines consumable groups for Naxxramas prep (Classic 1.12 / Turtle WoW)

local RC = RaidConsumables or {}
RC.Data = RC.Data or {}

-- Each entry may be either:
--   { names = { "Item1", "Item2" }, required = N }
-- or a simple array { "Item1", "Item2" } (required then defaults to 1).
-- Names must match in-game item names exactly (case-insensitive compare is used).
RC.Data.MandatoryGroups = {
    { names = { "Elixir of Fortitude" }, required = 4 },
    { names = { "Elixir of Poison Resistance", "Powerful Anti-Venom" }, required = 5 },
    { names = { "Greater Fire Protection Potion" }, required = 5 },
    { names = { "Greater Frost Protection Potion" }, required = 10 },
    { names = { "Greater Shadow Protection Potion" }, required = 10 },
    { names = { "Greater Nature Protection Potion" }, required = 10 },
    { names = { "Heavy Runecloth Bandage" }, required = 20 },
    { names = { "Major Healing Potion" }, required = 10 },
    { names = { "Rumsey Rum Black Label", "Medivh's Merlot" }, required = 10 },
    { names = { "Spirit of Zanza" }, required = 2 },
    { names = { "Tea with Sugar", "Nordanaar Herbal Tea" }, required = 10 },
}

-- Optional groups can be scanned and reported but not required for "prepared".
RC.Data.OptionalGroups = {
    { names = { "Frozen Rune" }, required = 5 },
    { names = { "Juju Chill" }, required = 5 },
    { names = { "Juju Flurry" }, required = 20 },
    { names = { "Major Troll's Blood Potion" }, required = 4 },
}

-- Role-specific mandatory groups (minimal baseline; extend as needed)
RC.Data.RoleMandatory = {
    caster = {
        { names = { "Blessed Wizard Oil" }, required = 4 },
        { names = { "Gilneas Hot Stew" }, required = 4 },
        { names = { "Dreamshard Elixir" }, required = 4 },
        { names = { "Mageblood Potion" }, required = 4 },
        { names = { "Major Mana Potion" }, required = 10 },
        { names = { "Brilliant Wizard Oil" }, required = 4 },
        { names = { "Greater Arcane Elixir" }, required = 4 },
        { names = { "Flask of Supreme Power" }, required = 4 },
        { names = { "Limited Invulnerability Potion" }, required = 4 },
    },
    healer = {
        { names = { "Brilliant Mana Oil" }, required = 2 },
        { names = { "Dreamshard Elixir" }, required = 4 },
        { names = { "Limited Invulnerability Potion" }, required = 5 },
        { names = { "Mageblood Potion" }, required = 4 },
        { names = { "Major Mana Potion" }, required = 10 },
        { names = { "Sagefish Delight" }, required = 20 },
    },
    melee = {
        { names = { "Blessed Sunfruit" }, required = 20 },
        { names = { "Consecrated Sharpening Stone" }, required = 4 },
        { names = { "Danonzo's Tel'Abim Surprise" }, required = 20 },
        { names = { "Dense Sharpening Stone", "Elemental Sharpening Stone" }, required = 1 },
        { names = { "Dreamshard Elixir" }, required = 4 },
        { names = { "Elixir of Giants" }, required = 4 },
        { names = { "Elixir of the Mongoose" }, required = 4 },
        { names = { "Free Action Potion" }, required = 5 },
        { names = { "Greater Arcane Elixir" }, required = 4 },
        { names = { "Limited Invulnerability Potion" }, required = 5 },
    },
    tank = {
        { names = { "Greater Stoneshield Potion" }, required = 10 },
        { names = { "Flask of the Titans" }, required = 2 },
        { names = { "Blessed Wizard Oil" }, required = 4 },
        { names = { "Brilliant Wizard Oil" }, required = 1 },
        { names = { "Consecrated Sharpening Stone" }, required = 4 },
        { names = { "Dense Sharpening Stone", "Elemental Sharpening Stone" }, required = 1 },
        { names = { "Dreamshard Elixir" }, required = 4 },
        { names = { "Elixir of Giants" }, required = 4 },
        { names = { "Elixir of Superior Defense" }, required = 4 },
        { names = { "Elixir of the Mongoose" }, required = 4 },
        { names = { "Free Action Potion" }, required = 5 },
        { names = { "Greater Arcane Elixir" }, required = 4 },
        { names = { "Hardened Mushroom", "Dirge's Kickin' Chimaerok Chops" }, required = 20 },
    },
    ranged = {
        { names = { "Danonzo's Tel'Abim Surprise" }, required = 20 },
        { names = { "Blessed Sunfruit" }, required = 20 },
    },
}

RC.Data.SpecMandatory = {
    ["Fire Mage"] = {
        { names = { "Elixir of Greater Firepower" }, required = 4 },
    },
    ["Frost Mage"] = {
        { names = { "Elixir of Frost Power" }, required = 4 },
    },
    ["Arcane Mage"] = {
        { names = { "Greater Arcane Elixir" }, required = 4 },
    },
    ["Shadow Priest"] = {
        { names = { "Elixir of Shadow Power" }, required = 4 },
    },
    ["Affliction Warlock"] = {
        { names = { "Elixir of Shadow Power" }, required = 4 },
    },
    ["Fire Warlock"] = {
        { names = { "Elixir of Greater Firepower" }, required = 4 },
    },
}

RaidConsumables = RC
