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
    { names = { "Nature Protection Potion" }, required = 10 },
    { names = { "Heavy Runecloth Bandage" }, required = 20 },
    { names = { "Major Healing Potion" }, required = 10 },
    { names = { "Rumsey Rum Black Label", "Medivh's Merlot" }, required = 10 },
    { names = { "Spirit of Zanza" }, required = 2 },
    { names = { "Tea with Sugar", "Nordannar Herbal Tea" }, required = 10 },
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
        { names = { "Blessed Wizard Oil", "Brilliant Wizard Oil" }, required = 4 },
        { names = { "Elixir of Shadow Power" }, required = 4 },
        { names = { "Greater Arcane Elixir" }, required = 4 },
        { names = { "Flask of Surpreme Power" }, required = 4 },
        { names = { "Lesser Invulnerability Potion" }, required = 4 },
        { names = { "Gilneas Hot Stew" }, required = 4 },
        { names = { "Dreamshard Elixir" }, required = 4 },
        { names = { "Mageblood Potion" }, required = 4 },
        { names = { "Major Mana Potion" }, required = 10 },
    },
    healer = {
        { names = { "Brilliant Mana Oil" }, required = 2 },
        { names = { "Dreamshard Elixir" }, required = 4 },
        { names = { "Mageblood Potion" }, required = 4 },
        { names = { "Major Mana Potion" }, required = 10 },
    },
    melee = {
        { names = { "Consecrated Sharpening Stone" }, required = 4 },
        { names = { "Elixir of Giants" }, required = 4 },
        { names = { "Elixir of the Mongoose" }, required = 4 },
    },
    tank = {
        { names = { "Greater Stoneshield Potion" }, required = 10 },
        { names = { "Flask of the Titans" }, required = 2 },
    },
    ranged = {
        { names = { "Danonzo's Tel'Abim Surprise" }, required = 20 },
        { names = { "Blessed Sunfruit", "Sour Mountain Berry" }, required = 20 },
    },
}

RaidConsumables = RC
