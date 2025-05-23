local your_mod_name = core.get_current_modname()

local function get_settings_boolean(setting_name, default)
    return core.settings:get_bool(setting_name, default)
end

local function get_settings_number(setting_name, default)
    return tonumber(core.settings:get(setting_name)) or default
end

local settings = {
    	aux1 = get_settings_boolean(your_mod_name .. ".aux1", true),
    	double_tap = get_settings_boolean(your_mod_name .. ".double_tap", true),
    	particles = get_settings_boolean(your_mod_name .. ".particles", true),
    	tap_interval = get_settings_number(your_mod_name .. ".tap_interval", 0.5),
        liquid = get_settings_boolean(your_mod_name .. ".liquid", false),
        snow = get_settings_boolean(your_mod_name .. ".snow", false),
        starve = get_settings_boolean(your_mod_name .. ".starve", false),
        drain_rate = get_settings_number(your_mod_name .. ".drain_rate", 20),
        starve_below = get_settings_number(your_mod_name..".starve_below", 1),
        detection_step = get_settings_number(your_mod_name .. ".detection_step", 0.1),
        sprint_step = get_settings_number(your_mod_name .. ".sprint_step", 0.5),
        drain_step = get_settings_number(your_mod_name .. ".drain_step", 0.5),
        cancel_step = get_settings_number(your_mod_name .. ".cancel_step", 0.3),
}

hbhunger.HUNGER_TICK = get_settings_number(your_mod_name .. ".HUNGER_TICK",800)
hbhunger.EXHAUST_DIG = get_settings_number(your_mod_name .. ".EXHAUST_DIG",3.0)
hbhunger.EXHAUST_PLACE = get_settings_number(your_mod_name .. ".EXHAUST_PLACE",1) 
hbhunger.EXHAUST_MOVE = get_settings_number(your_mod_name .. ".EXHAUST_MOVE",0.3) 
hbhunger.EXHAUST_LVL = get_settings_number(your_mod_name .. ".EXHAUST_LVL",160) 
hbhunger.SAT_MAX = get_settings_number(your_mod_name .. ".SAT_MAX",30) 
hbhunger.SAT_INIT = get_settings_number(your_mod_name .. ".SAT_INIT",20)
hbhunger.SAT_HEAL = get_settings_number(your_mod_name .. ".SAT_HEAL",15)


dg_sprint_core.RegisterStep(your_mod_name, "DETECT", settings.detection_step, function(player, state, dtime)
	local detected = dg_sprint_core.IsSprintKeyDetected(player, settings.aux1, settings.double_tap, settings.tap_interval) and dg_sprint_core.IsMoving(player) and not player:get_attach()
	if detected ~= state.detected then
		state.detected = detected
	end

end)

dg_sprint_core.RegisterStep(your_mod_name, "SPRINT", settings.sprint_step, function(player, state, dtime)
	local detected = state.detected
	dg_sprint_core.Sprint(your_mod_name, player, detected, {speed = 0.8, jump = 0.1})
	if detected and settings.particles then
		dg_sprint_core.ShowParticles(player:get_pos())
	end
	if detected ~= state.is_sprinting then
		state.is_sprinting = detected
	end
	
end)


dg_sprint_core.RegisterStep(your_mod_name, "DRAIN", settings.drain_step, function(player, state, dtime)
        local is_sprinting = state.is_sprinting
        if is_sprinting then
	        if dg_sprint_core.ExtraDrainCheck(player) then
	                if not player or not player:is_player() or player.is_fake_player == true then
	                        return
	                end
	                local name = player:get_player_name()
	                local exhaus = hbhunger.exhaustion[name]
                        exhaus = exhaus + settings.drain_rate
                        if exhaus > hbhunger.EXHAUST_LVL then
                                exhaus = 0 
                                local h = tonumber(hbhunger.hunger[name])
	                        h = h - 1
	                        if h < 0 then h = 0 end
	                        hbhunger.hunger[name] = h
	                        hbhunger.set_hunger_raw(player)
                                
                        end
                        hbhunger.exhaustion[name] = exhaus
                end
        end        
end)

dg_sprint_core.RegisterStep(your_mod_name , "SPRINT_CANCELLATIONS", settings.cancel_step, function(player, state, dtime)
    local pos = player:get_pos()
    local node_pos = { x = pos.x, y = pos.y + 0.5, z = pos.z }

    local cancel = false

	if settings.liquid and dg_sprint_core.IsNodeLiquid(player, node_pos) then
        cancel = true
    elseif settings.snow and dg_sprint_core.IsNodeSnow(player, node_pos) then
        cancel = true
    elseif settings.starve then
        if settings.starve_below == -1 then return end
        local info = hunger_ng.get_hunger_information(player:get_player_name())
        if info.hunger.exact <= settings.starve_below then
            cancel = true
        end
    end

    dg_sprint_core.prevent_detection(player, cancel, your_mod_name .. ":SPRINT_CANCELLATIONS")
end)
