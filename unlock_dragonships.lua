local PLAYER_FACTION_KEY  = "wh2_main_hef_order_of_loremasters"
local AISLINN_FACTION_KEY = "wh3_dlc27_hef_aislinn"

local SAVE_KEY_SETUP  = "unlock_dragonships_setup_done"
local SAVE_KEY_SPAWN  = "unlock_dragonships_spawned_done"
local SAVE_KEY_SUPPLY = "unlock_dragonships_supplies_seeded"

local DRAGONSHIPS = {
    { subtype = "wh3_dlc27_hef_dragonship_captain_01", art = "wh3_dlc27_art_set_hef_dragonship_captain_1" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_02", art = "wh3_dlc27_art_set_hef_dragonship_captain_2" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_03", art = "wh3_dlc27_art_set_hef_dragonship_captain_3" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_04", art = "wh3_dlc27_art_set_hef_dragonship_captain_4" },
    { subtype = "wh3_dlc27_hef_dragonship_captain_05", art = "wh3_dlc27_art_set_hef_dragonship_captain_5" },
}

local function spawn_dragonships_once_for_faction(faction_key)
    local faction = cm:get_faction(faction_key)
    if faction:is_null_interface() or faction:is_dead() then return end

    local spawn_key = SAVE_KEY_SPAWN .. "_" .. faction_key
    if cm:get_saved_value(spawn_key) then return end

    for i = 1, #DRAGONSHIPS do
        cm:spawn_character_to_pool(
            faction_key,
            "names_name_1819815097",
            "names_name_509665994",
            "", "",
            50,
            true,
            "general",
            DRAGONSHIPS[i].subtype,
            true,
            DRAGONSHIPS[i].art
        )
    end

    cm:set_saved_value(spawn_key, true)
end

local DRAGONSHIP_SUPPLIES_RESOURCE_KEY = "wh3_dlc27_hef_naval_supplies"
local DRAGONSHIP_SUPPLIES_FACTOR_KEY   = "faction"
local DRAGONSHIP_SUPPLIES_PER_TURN     = 300

cm:add_first_tick_callback(function()
    if cm:get_local_faction_name(true) ~= PLAYER_FACTION_KEY then return end

    if not cm:get_saved_value(SAVE_KEY_SETUP) then
        local aislinn = cm:get_faction(AISLINN_FACTION_KEY)
        if aislinn and not aislinn:is_dead() then
            cm:force_confederation(PLAYER_FACTION_KEY, AISLINN_FACTION_KEY)
        end

        spawn_dragonships_once_for_faction(PLAYER_FACTION_KEY)
        cm:set_saved_value(SAVE_KEY_SETUP, true)
    end

    if not cm:get_saved_value(SAVE_KEY_SUPPLY) then
        cm:faction_add_pooled_resource(
            PLAYER_FACTION_KEY,
            DRAGONSHIP_SUPPLIES_RESOURCE_KEY,
            DRAGONSHIP_SUPPLIES_FACTOR_KEY,
            500
        )
        cm:set_saved_value(SAVE_KEY_SUPPLY, true)
    end
end)

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
