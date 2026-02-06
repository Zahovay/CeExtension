-- CE config data (loaded before CEExtension.lua)

CE_Config = CE_Config or {}

CE_Config.CLASS_DISPLAY = {
    WARRIOR = "Warrior",
    MAGE = "Mage",
    ROGUE = "Rogue",
    PRIEST = "Priest",
    PALADIN = "Paladin",
    DRUID = "Druid",
    SHAMAN = "Shaman",
    HUNTER = "Hunter",
    WARLOCK = "Warlock",
}

CE_Config.CLASS_TALENTS = {
    WARRIOR = { "Arms", "Fury", "Protection" },
    MAGE = { "Arcane", "Fire", "Frost" },
    ROGUE = { "Assassination", "Combat", "Subtlety" },
    PRIEST = { "Discipline", "Holy", "Shadow" },
    PALADIN = { "Holy", "Protection", "Retribution" },
    DRUID = { "Balance", "Feral", "Restoration" },
    SHAMAN = { "Elemental", "Enhancement", "Restoration" },
    HUNTER = { "Beast", "Marksmanship", "Survival" },
    WARLOCK = { "Affliction", "Demonology", "Destruction" },
}

CE_Config.CLASS_COLORS = {
    Rogue = "fff569",
    Mage = "69ccf0",
    Warrior = "c79c6e",
    Hunter = "abd473",
    Druid = "ff7d0a",
    Priest = "ffffff",
    Warlock = "9482c9",
    Shaman = "0070dd",
    Paladin = "f58cba",
}

CE_Config.ORDERED_RAIDS = {
    "Molten Core",
    "Blackwing Lair",
    "Emerald Sanctum",
    "Temple of Ahn'Qiraj",
    "Naxxramas",
    "The Tower of Karazhan",
}
