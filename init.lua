local your_mod_name = core.get_current_modname()
local api = dg_sprint_core.v2
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
	fov = get_settings_boolean(your_mod_name .. ".fov", true),
	fov_value = get_settings_number(your_mod_name..".fov_value", 15),
	fov_time_stop = get_settings_number(your_mod_name .. ".fov_time_stop", 0.4),
	fov_time_start = get_settings_number(your_mod_name..".fov_time_start", 0.2),
        drain_rate = get_settings_number(your_mod_name .. ".drain_rate", 20),
        starve_below = get_settings_number(your_mod_name..".starve_below", 1),
        detection_step = get_settings_number(your_mod_name .. ".detection_step", 0.1),
        sprint_step = get_settings_number(your_mod_name .. ".sprint_step", 0.5),
        drain_step = get_settings_number(your_mod_name .. ".drain_step", 0.5),
        cancel_step = get_settings_number(your_mod_name .. ".cancel_step", 0.3),
	jump = get_settings_number(your_mod_name .. ".jump", 0.1),
        speed = get_settings_number(your_mod_name .. ".speed", 0.8),
}

hbhunger.HUNGER_TICK = get_settings_number(your_mod_name .. ".HUNGER_TICK",800)
hbhunger.EXHAUST_DIG = get_settings_number(your_mod_name .. ".EXHAUST_DIG",3.0)
hbhunger.EXHAUST_PLACE = get_settings_number(your_mod_name .. ".EXHAUST_PLACE",1)
hbhunger.EXHAUST_MOVE = get_settings_number(your_mod_name .. ".EXHAUST_MOVE",0.3)
hbhunger.EXHAUST_LVL = get_settings_number(your_mod_name .. ".EXHAUST_LVL",160)
hbhunger.SAT_MAX = get_settings_number(your_mod_name .. ".SAT_MAX",30)
hbhunger.SAT_INIT = get_settings_number(your_mod_name .. ".SAT_INIT",20)
hbhunger.SAT_HEAL = get_settings_number(your_mod_name .. ".SAT_HEAL",15)


api.register_server_step(your_mod_name, "DETECT", settings.detection_step, function(player, state, dtime)
	local control = player:get_player_control()
	local detected = api.sprint_key_detected(player, (settings.aux1 and control.aux1), (settings.double_tap and control.up), settings.tap_interval)
	if detected ~= state.detected then
		state.detected = detected
	end

end)

api.register_server_step(your_mod_name, "SPRINT", settings.sprint_step, function(player, state, dtime)
	if not settings.fov then
        settings.fov_value = 0
    end
    if state.detected then
        local sprint_settings = {speed = settings.speed, jump = settings.jump, particles = settings.particles, fov = settings.fov_value, transition = settings.fov_time_start}
        api.set_sprint(your_mod_name, player, state.detected, sprint_settings)
    else
        local sprint_settings = {speed = settings.speed, jump = settings.jump, particles = settings.particles, fov = settings.fov_value, transition = settings.fov_time_stop}
        api.set_sprint(your_mod_name, player, state.detected, sprint_settings)
    end
end)

api.register_server_step(your_mod_name, "DRAIN", settings.drain_step, function(player, state, dtime)
	if not player or not player:is_player() or player.is_fake_player == true then return end
        if state.detected and api.is_player_draining(player) then
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

end)

api.register_server_step(your_mod_name , "SPRINT_CANCELLATIONS", settings.cancel_step, function(player, state, dtime)
    local pos = player:get_pos()
    local node_pos = { x = pos.x, y = pos.y + 0.5, z = pos.z }

    local cancel = false

	if settings.liquid and api.tools.node_is_liquid(player, node_pos) then
        cancel = true
    elseif settings.snow and api.tools.node_is_snowy_group(player, node_pos) then
        cancel = true
    elseif settings.starve then
        if settings.starve_below == -1 then return end
        local info = hunger_ng.get_hunger_information(player:get_player_name())
        if info.hunger.exact <= settings.starve_below then
            cancel = true
        end
    end

     api.set_sprint_cancel(player, cancel, your_mod_name .. ":SPRINT_CANCELLATIONS")
end)
