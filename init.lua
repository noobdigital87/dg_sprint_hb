local api = dg_sprint_core

local mod_name = core.get_current_modname()
local player_data  = {}
local dg_lib = dofile(core.get_modpath(mod_name) .. "/lib.lua")

local settings = {
    drain_rate = tonumber(core.settings:get(mod_name .. ".drain_rate")) or 5,
    cancel_sprint_on_snow = core.settings:get_bool(mod_name .. ".snow_cancel_sprint", false),
    cancel_sprint_in_liquid = core.settings:get_bool(mod_name .. ".liquid_cancel_sprint", false),
}
settings.drain_rate = settings.drain_rate * 100
-- Create a new player data table
local function create_pdata()
    return {
        on_ground = true,
        in_liquid = false,

   }
end

-- Register the player data when they join the game
-- Enable or disable features based on the mod's settings
core.register_on_joinplayer(function(player, last_login)
        local name = player:get_player_name()
        player_data[name] = create_pdata()
        api.enable_aux1(player, core.settings:get_bool(mod_name .. ".aux1", true))
        api.enable_double_tap(player, core.settings:get_bool(mod_name .. ".double_tap", true))
        api.enable_particles(player, core.settings:get_bool(mod_name .. ".particles", true))
        api.enable_drain(player, true)
end)

core.register_on_leaveplayer(function(player)
        player_data[player:get_player_name()] = nil
end)

-- Sprint when key is detected and not attached to an object.
api.register_step(mod_name.. ":SPRINT", (0.2), function(player, dtime)
        local key_detected = api.is_key_detected(player) and not player:get_attach()
        api.sprint(player, key_detected)
end)

-- Drain hunger when sprinting on ground or in liquid.
api.register_step(mod_name.. ":DRAIN", (0.5), function(player, dtime)
        local control = player:get_player_control()

        -- Check if player is draining and on ground or in liquid.
local draining = api.is_draining(player) and (player_data[player:get_player_name()].on_ground or player_data[player:get_player_name()].in_liquid)


        -- Check for jump to start draining even when not on ground or in liquid
        if not player_data[player:get_player_name()].in_liquid and control.jump and not draining then
            draining = true
        end

        -- Drain hunger when sprinting and conditions are met.
        if draining then
            local player_name = player:get_player_name()
            local current_hunger = hbhunger.hunger[player_name] or hbhunger.SAT_INIT
                hbhunger.exhaustion[player_name] = (hbhunger.exhaustion[player_name] or 0) + dtime * settings.drain_rate
            if hbhunger.exhaustion[player_name] >= hbhunger.EXHAUST_LVL then
                hbhunger.exhaustion[player_name] = 0
                if current_hunger > 0 then
                    current_hunger = current_hunger - 1
                    hbhunger.hunger[player_name] = current_hunger
                    hbhunger.set_hunger_raw(player)
                end
            end
        end
end)

if settings.cancel_sprint_in_liquid or settings.cancel_sprint_on_snow then
        api.register_step(mod_name.. ":SPRINT_CANCELLATIONS", (0.3), function(player, dtime)
                local name = player:get_player_name()
                local pos = player:get_pos()
                local def = dg_lib.getNodeDefinition(player,{ x = pos.x, y = pos.y + 0.5, z = pos.z })
                local cancel = false
                if def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid") then
                        if settings.cancel_sprint_in_liquid then
                                cancel = true
                        end
                        player_data[name].in_liquid = true
                else
                        player_data[name].in_liquid = false
                        if def and def.groups and def.groups and def.groups.snowy and def.groups.snowy > 0 then
                                if settings.cancel_sprint_on_snow then
                                        cancel = true
                                end
                        end
                end
                api.cancel_sprint(player, cancel, mod_name .. ":SPRINT_CANCELLATIONS")
        end)
end

-- Prevent key detection when going backwards
local NAME_CANCEL = ":CANCEL_BACKWARDS"

api.register_step(mod_name.. ":" .. NAME_CANCEL, 0.1, function(player, dtime)
        local control = player:get_player_control()
        if not control.down then
                api.prevent_detection(player, false, mod_name .. ":" .. NAME_CANCEL)
        else
                api.prevent_detection(player, true, mod_name .. ":" .. NAME_CANCEL)
        end
end)



api.register_step(mod_name.. ":GROUND", 0.4, function(player, dtime)
        local pos = player:get_pos()
        local node_below = core.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
        if node_below then
                local def = core.registered_nodes[node_below.name]
                if def and def.walkable then
                        player_data[player:get_player_name()].on_ground = true
                else
                        player_data[player:get_player_name()].on_ground = false
                end
        end
end)


