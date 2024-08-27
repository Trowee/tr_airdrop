Config = {}

Config.Framework = 'qb' -- 'esx' or 'qb'
Config.Inventory = 'qb' -- 'qb' or 'ox'
Config.Target = 'qb' -- ox for ox_target or qb for qb-target

Config.NPCLocation = vector4(1536.7802, 3593.3811, 38.7665, 211.9744)

Config.Blip = true

Config.BreakingTime = 5000 -- You can configure time that player needs to break crate (in ms)

Config.Items = {
    {label = 'Pistol', item = 'WEAPON_PISTOL', price = 15000},
    {label = 'SMG', item = 'WEAPON_SMG', price = 25000},
    {label = 'Assault Rifle', item = 'WEAPON_ASSAULTRIFLE', price = 35000},
    {label = 'Armor', item = 'armor', price = 5000},
    {label = 'Lockpick', item = 'lockpick', price = 1000}
}

-------------- Set all possible airdrop locations here

Config.DropLocations = {
    vector3(1073.6320, 2364.3940, 44.1181),
    vector3(307.1485, 2879.8325, 43.5057),
    vector3(-65.5743, 1894.7319, 196.0679),
}

Config.DropRadius = 15.0 -- What is radius that when player enters airdrop starts falling
Config.AirdropHeight = 100.0 -- Height of airdrop
