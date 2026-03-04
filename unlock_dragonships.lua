local PLAYER_FACTION_KEY  = "wh2_main_hef_order_of_loremasters"
local AISLINN_FACTION_KEY = "wh3_dlc27_hef_aislinn"
local TOWER_FACTION_KEY   = "wh3_dlc27_special_tower_of_the_sun_secondary"

local SAVE_KEY_SETUP   = "unlock_dragonships_setup_done"
local SAVE_KEY_SPAWN   = "unlock_dragonships_spawned_done"
local SAVE_KEY_SUPPLY  = "unlock_dragonships_supplies_seeded"
local SAVE_KEY_TOWER   = "unlock_dragonships_tower_done"

local DRAGONSHIPS = {
    { subtype = "wh3_dlc27_hef_dragonship_captain_01", art = "wh3_dlc27_art_set_hef_dragonship_captain_1" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_02", art = "wh3_dlc27_art_set_hef_dragonship_captain_2" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_03", art = "wh3_dlc27_art_set_hef_dragonship_captain_3" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_04", art = "wh3_dlc27_art_set_hef_dragonship_captain_4" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_05", art = "wh3_dlc27_art_set_hef_dragonship_captain_5" },
}

local DRAGONSHIP_NAME_KEYS = {
    ["wh3_dlc27_hef_dragonship_captain_01"] = { forename = "names_name_9931010001", surname = "names_name_9931010002" },
    ["wh3_dlc27_hef_dragonship_captain_02"] = { forename = "names_name_9931010003", surname = "names_name_9931010004" },
    ["wh3_dlc27_hef_dragonship_captain_03"] = { forename = "names_name_9931010005", surname = "names_name_9931010006" },
    ["wh3_dlc27_hef_dragonship_captain_04"] = { forename = "names_name_9931010007", surname = "names_name_9931010008" },
    ["wh3_dlc27_hef_dragonship_captain_05"] = { forename = "names_name_9931010009", surname = "names_name_9931010010" },
}

local function is_dragonship_subtype(st)
    return st == "wh3_dlc27_hef_dragonship_captain_01"
        or st == "wh3_dlc27_hef_dragonship_captain_02"
        or st == "wh3_dlc27_hef_dragonship_captain_03"
        or st == "wh3_dlc27_hef_dragonship_captain_04"
        or st == "wh3_dlc27_hef_dragonship_captain_05"
end

local function spawn_dragonships_once_for_faction(faction_key)
    local faction = cm:get_faction(faction_key)
    if faction:is_null_interface() or faction:is_dead() then return end

    local spawn_key = SAVE_KEY_SPAWN .. "_" .. faction_key
    if cm:get_saved_value(spawn_key) then return end

    for i = 1, #DRAGONSHIPS do
        local subtype = DRAGONSHIPS[i].subtype
        local n = DRAGONSHIP_NAME_KEYS[subtype]

        local forename = (n and n.forename) or "names_name_1819815097"
        local surname  = (n and n.surname)  or "names_name_509665994"

        cm:spawn_character_to_pool(
            faction_key,
            forename,
            surname,
            "", "",
            50,
            true,
            "general",
            subtype,
            true,
            DRAGONSHIPS[i].art
        )
    end

    cm:set_saved_value(spawn_key, true)
end

-- Dragonship supplies
local DRAGONSHIP_SUPPLIES_RESOURCE_KEY = "wh3_dlc27_hef_naval_supplies"
local DRAGONSHIP_SUPPLIES_FACTOR_KEY   = "faction"
local DRAGONSHIP_SUPPLIES_PER_TURN     = 300

-- Sea immunity bundle (already created in DB)
local DRAGONSHIP_SEA_IMMUNITY_BUNDLE = "unlock_dragonship_sea_immunity_bundle"

local function apply_sea_immunity_to_force(mf)
    if mf:is_null_interface() then return end
    if mf:has_effect_bundle(DRAGONSHIP_SEA_IMMUNITY_BUNDLE) then return end

    cm:apply_effect_bundle_to_force(
        DRAGONSHIP_SEA_IMMUNITY_BUNDLE,
        mf:command_queue_index(),
        9999
    )
end

local function should_have_sea_immunity(c)
    if c:is_null_interface() then return false end
    if c:faction():name() ~= PLAYER_FACTION_KEY then return false end
    if not c:has_military_force() then return false end
    if not c:character_type("general") then return false end

    local st = c:character_subtype_key()
    return st == "wh3_dlc27_hef_aislinn" or is_dragonship_subtype(st)
end

local function ensure_sea_immunity_for_player_lords()
    local f = cm:get_faction(PLAYER_FACTION_KEY)
    if f:is_null_interface() or f:is_dead() then return end

    local cl = f:character_list()
    for i = 0, cl:num_items() - 1 do
        local c = cl:item_at(i)
        if should_have_sea_immunity(c) then
            local mf = c:military_force()
            if not mf:is_null_interface() then
                apply_sea_immunity_to_force(mf)
            end
        end
    end
end

-- Horde growth bundle
local DRAGONSHIP_GROWTH_BUNDLE = "unlock_dragonship_growth_bundle"

local function apply_growth_to_force(mf)
    if mf:is_null_interface() then return end
    if mf:has_effect_bundle(DRAGONSHIP_GROWTH_BUNDLE) then return end

    cm:apply_effect_bundle_to_force(
        DRAGONSHIP_GROWTH_BUNDLE,
        mf:command_queue_index(),
        9999
    )
end

local function apply_bundles_if_qualifies(c)
    if not should_have_sea_immunity(c) then return end
    local mf = c:military_force()
    if mf:is_null_interface() then return end
    apply_sea_immunity_to_force(mf)
    apply_growth_to_force(mf)
end

-- Turn 1 setup
cm:add_first_tick_callback(function()
    if cm:get_local_faction_name(true) ~= PLAYER_FACTION_KEY then return end

    -- One-time: confed Aislinn + add dragonships
    if not cm:get_saved_value(SAVE_KEY_SETUP) then
        local aislinn = cm:get_faction(AISLINN_FACTION_KEY)
        if aislinn and not aislinn:is_dead() then
            cm:force_confederation(PLAYER_FACTION_KEY, AISLINN_FACTION_KEY)
        end

        spawn_dragonships_once_for_faction(PLAYER_FACTION_KEY)
        cm:set_saved_value(SAVE_KEY_SETUP, true)
    end

    -- One-time: try confed Tower faction; if it doesn't stick, transfer region
    if not cm:get_saved_value(SAVE_KEY_TOWER) then
        local tower = cm:get_faction(TOWER_FACTION_KEY)
        if tower and not tower:is_dead() then
            cm:force_confederation(PLAYER_FACTION_KEY, TOWER_FACTION_KEY)
        end

        local region_key = "wh3_main_combi_region_tower_of_the_stars"
        local region = cm:get_region(region_key)
        if region and not region:is_null_interface() then
            local owner = region:owning_faction()
            if owner and not owner:is_null_interface() and owner:name() ~= PLAYER_FACTION_KEY then
                cm:transfer_region_to_faction(region_key, PLAYER_FACTION_KEY)
            end
        end

        cm:set_saved_value(SAVE_KEY_TOWER, true)
    end

    -- One-time: seed supplies
    if not cm:get_saved_value(SAVE_KEY_SUPPLY) then
        cm:faction_add_pooled_resource(
            PLAYER_FACTION_KEY,
            DRAGONSHIP_SUPPLIES_RESOURCE_KEY,
            DRAGONSHIP_SUPPLIES_FACTOR_KEY,
            500
        )
        cm:set_saved_value(SAVE_KEY_SUPPLY, true)
    end

    -- After confed/spawns, make sure any existing qualifying lords get the bundles
    cm:callback(function()
        ensure_sea_immunity_for_player_lords()
        -- growth too, while we're here
        local f = cm:get_faction(PLAYER_FACTION_KEY)
        if not f:is_null_interface() and not f:is_dead() then
            local cl = f:character_list()
            for i = 0, cl:num_items() - 1 do
                local c = cl:item_at(i)
                apply_bundles_if_qualifies(c)
            end
        end
    end, 0.2)
end)

-- Per-turn supply income
core:add_listener(
    "UnlockDragonships_AddSuppliesEachTurn",
    "FactionTurnStart",
    function(context) return context:faction():name() == PLAYER_FACTION_KEY end,
    function()
        cm:faction_add_pooled_resource(
            PLAYER_FACTION_KEY,
            DRAGONSHIP_SUPPLIES_RESOURCE_KEY,
            DRAGONSHIP_SUPPLIES_FACTOR_KEY,
            DRAGONSHIP_SUPPLIES_PER_TURN
        )
    end,
    true
)

-- Apply sea immunity and growth when a qualifying lord is CREATED (covers some cases)
core:add_listener(
    "UnlockDragonships_Bundles_CharacterCreated",
    "CharacterCreated",
    function(context)
        return should_have_sea_immunity(context:character())
    end,
    function(context)
        apply_bundles_if_qualifies(context:character())
    end,
    true
)

-- NEW: Apply bundles when a lord is RECRUITED (very common “wounded came back” / “re-hired” path)
core:add_listener(
    "UnlockDragonships_Bundles_CharacterRecruited",
    "CharacterRecruited",
    function(context)
        local c = context:character()
        return should_have_sea_immunity(c)
    end,
    function(context)
        -- Delay a hair: recruitment sometimes finishes before the force is fully “live”
        local cqi = context:character():command_queue_index()
        cm:callback(function()
            local c = cm:get_character_by_cqi(cqi)
            if c and not c:is_null_interface() then
                apply_bundles_if_qualifies(c)
            end
        end, 0.1)
    end,
    true
)

-- NEW: Apply bundles on rank-up as a safety net (covers odd edge cases)
core:add_listener(
    "UnlockDragonships_Bundles_CharacterRankUp",
    "CharacterRankUp",
    function(context)
        local c = context:character()
        return should_have_sea_immunity(c)
    end,
    function(context)
        apply_bundles_if_qualifies(context:character())
    end,
    true
)local PLAYER_FACTION_KEY  = "wh2_main_hef_order_of_loremasters"
local AISLINN_FACTION_KEY = "wh3_dlc27_hef_aislinn"
local TOWER_FACTION_KEY   = "wh3_dlc27_special_tower_of_the_sun_secondary"

local SAVE_KEY_SETUP   = "unlock_dragonships_setup_done"
local SAVE_KEY_SPAWN   = "unlock_dragonships_spawned_done"
local SAVE_KEY_SUPPLY  = "unlock_dragonships_supplies_seeded"
local SAVE_KEY_TOWER   = "unlock_dragonships_tower_done"

local DRAGONSHIPS = {
    { subtype = "wh3_dlc27_hef_dragonship_captain_01", art = "wh3_dlc27_art_set_hef_dragonship_captain_1" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_02", art = "wh3_dlc27_art_set_hef_dragonship_captain_2" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_03", art = "wh3_dlc27_art_set_hef_dragonship_captain_3" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_04", art = "wh3_dlc27_art_set_hef_dragonship_captain_4" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_05", art = "wh3_dlc27_art_set_hef_dragonship_captain_5" },
}

local DRAGONSHIP_NAME_KEYS = {
    ["wh3_dlc27_hef_dragonship_captain_01"] = { forename = "names_name_9931010001", surname = "names_name_9931010002" },
    ["wh3_dlc27_hef_dragonship_captain_02"] = { forename = "names_name_9931010003", surname = "names_name_9931010004" },
    ["wh3_dlc27_hef_dragonship_captain_03"] = { forename = "names_name_9931010005", surname = "names_name_9931010006" },
    ["wh3_dlc27_hef_dragonship_captain_04"] = { forename = "names_name_9931010007", surname = "names_name_9931010008" },
    ["wh3_dlc27_hef_dragonship_captain_05"] = { forename = "names_name_9931010009", surname = "names_name_9931010010" },
}

local function is_dragonship_subtype(st)
    return st == "wh3_dlc27_hef_dragonship_captain_01"
        or st == "wh3_dlc27_hef_dragonship_captain_02"
        or st == "wh3_dlc27_hef_dragonship_captain_03"
        or st == "wh3_dlc27_hef_dragonship_captain_04"
        or st == "wh3_dlc27_hef_dragonship_captain_05"
end

local function spawn_dragonships_once_for_faction(faction_key)
    local faction = cm:get_faction(faction_key)
    if faction:is_null_interface() or faction:is_dead() then return end

    local spawn_key = SAVE_KEY_SPAWN .. "_" .. faction_key
    if cm:get_saved_value(spawn_key) then return end

    for i = 1, #DRAGONSHIPS do
        local subtype = DRAGONSHIPS[i].subtype
        local n = DRAGONSHIP_NAME_KEYS[subtype]

        local forename = (n and n.forename) or "names_name_1819815097"
        local surname  = (n and n.surname)  or "names_name_509665994"

        cm:spawn_character_to_pool(
            faction_key,
            forename,
            surname,
            "", "",
            50,
            true,
            "general",
            subtype,
            true,
            DRAGONSHIPS[i].art
        )
    end

    cm:set_saved_value(spawn_key, true)
end

-- Dragonship supplies
local DRAGONSHIP_SUPPLIES_RESOURCE_KEY = "wh3_dlc27_hef_naval_supplies"
local DRAGONSHIP_SUPPLIES_FACTOR_KEY   = "faction"
local DRAGONSHIP_SUPPLIES_PER_TURN     = 300

-- Sea immunity bundle (already created in DB)
local DRAGONSHIP_SEA_IMMUNITY_BUNDLE = "unlock_dragonship_sea_immunity_bundle"

local function apply_sea_immunity_to_force(mf)
    if mf:is_null_interface() then return end
    if mf:has_effect_bundle(DRAGONSHIP_SEA_IMMUNITY_BUNDLE) then return end

    cm:apply_effect_bundle_to_force(
        DRAGONSHIP_SEA_IMMUNITY_BUNDLE,
        mf:command_queue_index(),
        9999
    )
end

local function should_have_sea_immunity(c)
    if c:is_null_interface() then return false end
    if c:faction():name() ~= PLAYER_FACTION_KEY then return false end
    if not c:has_military_force() then return false end
    if not c:character_type("general") then return false end

    local st = c:character_subtype_key()
    return st == "wh3_dlc27_hef_aislinn" or is_dragonship_subtype(st)
end

local function ensure_sea_immunity_for_player_lords()
    local f = cm:get_faction(PLAYER_FACTION_KEY)
    if f:is_null_interface() or f:is_dead() then return end

    local cl = f:character_list()
    for i = 0, cl:num_items() - 1 do
        local c = cl:item_at(i)
        if should_have_sea_immunity(c) then
            local mf = c:military_force()
            if not mf:is_null_interface() then
                apply_sea_immunity_to_force(mf)
            end
        end
    end
end

-- Horde growth bundle
local DRAGONSHIP_GROWTH_BUNDLE = "unlock_dragonship_growth_bundle"

local function apply_growth_to_force(mf)
    if mf:is_null_interface() then return end
    if mf:has_effect_bundle(DRAGONSHIP_GROWTH_BUNDLE) then return end

    cm:apply_effect_bundle_to_force(
        DRAGONSHIP_GROWTH_BUNDLE,
        mf:command_queue_index(),
        9999
    )
end

local function apply_bundles_if_qualifies(c)
    if not should_have_sea_immunity(c) then return end
    local mf = c:military_force()
    if mf:is_null_interface() then return end
    apply_sea_immunity_to_force(mf)
    apply_growth_to_force(mf)
end

-- Turn 1 setup
cm:add_first_tick_callback(function()
    if cm:get_local_faction_name(true) ~= PLAYER_FACTION_KEY then return end

    -- One-time: confed Aislinn + add dragonships
    if not cm:get_saved_value(SAVE_KEY_SETUP) then
        local aislinn = cm:get_faction(AISLINN_FACTION_KEY)
        if aislinn and not aislinn:is_dead() then
            cm:force_confederation(PLAYER_FACTION_KEY, AISLINN_FACTION_KEY)
        end

        spawn_dragonships_once_for_faction(PLAYER_FACTION_KEY)
        cm:set_saved_value(SAVE_KEY_SETUP, true)
    end

    -- One-time: try confed Tower faction; if it doesn't stick, transfer region
    if not cm:get_saved_value(SAVE_KEY_TOWER) then
        local tower = cm:get_faction(TOWER_FACTION_KEY)
        if tower and not tower:is_dead() then
            cm:force_confederation(PLAYER_FACTION_KEY, TOWER_FACTION_KEY)
        end

        local region_key = "wh3_main_combi_region_tower_of_the_stars"
        local region = cm:get_region(region_key)
        if region and not region:is_null_interface() then
            local owner = region:owning_faction()
            if owner and not owner:is_null_interface() and owner:name() ~= PLAYER_FACTION_KEY then
                cm:transfer_region_to_faction(region_key, PLAYER_FACTION_KEY)
            end
        end

        cm:set_saved_value(SAVE_KEY_TOWER, true)
    end

    -- One-time: seed supplies
    if not cm:get_saved_value(SAVE_KEY_SUPPLY) then
        cm:faction_add_pooled_resource(
            PLAYER_FACTION_KEY,
            DRAGONSHIP_SUPPLIES_RESOURCE_KEY,
            DRAGONSHIP_SUPPLIES_FACTOR_KEY,
            500
        )
        cm:set_saved_value(SAVE_KEY_SUPPLY, true)
    end

    -- After confed/spawns, make sure any existing qualifying lords get the bundles
    cm:callback(function()
        ensure_sea_immunity_for_player_lords()
        -- growth too, while we're here
        local f = cm:get_faction(PLAYER_FACTION_KEY)
        if not f:is_null_interface() and not f:is_dead() then
            local cl = f:character_list()
            for i = 0, cl:num_items() - 1 do
                local c = cl:item_at(i)
                apply_bundles_if_qualifies(c)
            end
        end
    end, 0.2)
end)

-- Per-turn supply income
core:add_listener(
    "UnlockDragonships_AddSuppliesEachTurn",
    "FactionTurnStart",
    function(context) return context:faction():name() == PLAYER_FACTION_KEY end,
    function()
        cm:faction_add_pooled_resource(
            PLAYER_FACTION_KEY,
            DRAGONSHIP_SUPPLIES_RESOURCE_KEY,
            DRAGONSHIP_SUPPLIES_FACTOR_KEY,
            DRAGONSHIP_SUPPLIES_PER_TURN
        )
    end,
    true
)

-- Apply sea immunity and growth when a qualifying lord is CREATED (covers some cases)
core:add_listener(
    "UnlockDragonships_Bundles_CharacterCreated",
    "CharacterCreated",
    function(context)
        return should_have_sea_immunity(context:character())
    end,
    function(context)
        apply_bundles_if_qualifies(context:character())
    end,
    true
)

-- Apply bundles when a lord is RECRUITED (very common “wounded came back” / “re-hired” path)
core:add_listener(
    "UnlockDragonships_Bundles_CharacterRecruited",
    "CharacterRecruited",
    function(context)
        local c = context:character()
        return should_have_sea_immunity(c)
    end,
    function(context)
        -- Delay a hair: recruitment sometimes finishes before the force is fully “live”
        local cqi = context:character():command_queue_index()
        cm:callback(function()
            local c = cm:get_character_by_cqi(cqi)
            if c and not c:is_null_interface() then
                apply_bundles_if_qualifies(c)
            end
        end, 0.1)
    end,
    true
)

-- Apply bundles on rank-up as a safety net (covers odd edge cases)
core:add_listener(
    "UnlockDragonships_Bundles_CharacterRankUp",
    "CharacterRankUp",
    function(context)
        local c = context:character()
        return should_have_sea_immunity(c)
    end,
    function(context)
        apply_bundles_if_qualifies(context:character())
    end,
    true
)

-- Keep bundles alive
core:add_listener(
    "UnlockDragonships_Bundles_Maintain",
    "FactionTurnStart",
    function(context) return context:faction():name() == PLAYER_FACTION_KEY end,
    function(context)
        local f = context:faction()
        local cl = f:character_list()

        for i = 0, cl:num_items() - 1 do
            local c = cl:item_at(i)
            apply_bundles_if_qualifies(c)
        end
    end,
    true
)
