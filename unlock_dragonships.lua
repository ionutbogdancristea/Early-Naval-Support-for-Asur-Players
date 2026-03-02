local PLAYER_FACTION_KEY  = "wh2_main_hef_order_of_loremasters"
local AISLINN_FACTION_KEY = "wh3_dlc27_hef_aislinn"

cm:add_first_tick_callback(function()

    local local_faction = cm:get_local_faction_name(true)
    if local_faction ~= PLAYER_FACTION_KEY then
        return
    end

    local aislinn = cm:get_faction(AISLINN_FACTION_KEY)

    if aislinn and not aislinn:is_dead() then
        cm:force_confederation(PLAYER_FACTION_KEY, AISLINN_FACTION_KEY)
    end

end)
