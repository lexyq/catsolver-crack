--Discord lexyqqw

local bit_lib = require("bit")
local gs_color = require("gamesense/color")

ui.new_label("RAGE", "Other", "CATSOLVER")

local main_mode_combobox = ui.new_combobox("RAGE", "Other", "\aCC0000FFMode:", {
    "Resolver + Predict",
    "Lag Function",
    "Exploit Function",
    "Misc Function"
})

local enable_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Resolver")
local resolver_mode_combobox = ui.new_combobox("RAGE", "Other", "Resolver Mode", {
    "Low",
    "Medium",
    "High",
    "Neverlose",
    "Exploiter"
})
local prediction_mode_combobox = ui.new_combobox("RAGE", "Other", "Prediction Mode", {
    "Static",
    "Adaptive",
    "Dynamic",
    "Neverlose"
})
local prediction_strength_slider = ui.new_slider("RAGE", "Other", "Prediction Strength", 0, 50, 15, true, "%")
local autofire_threshold_slider = ui.new_slider("RAGE", "Other", "Autofire Threshold", 0, 100, 50, true, "%")
local enable_extra_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Extra Resolver")
local priority_hitbox_multiselect = ui.new_multiselect("RAGE", "Other", "Priority Hitbox", {
    "Head",
    "Chest",
    "Stomach"
})
local priority_strength_slider = ui.new_slider("RAGE", "Other", "Priority Strength", 1, 100, 50, true, "%")
local anti_dt_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Anti-DT Resolver")
local instant_peek_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Instant Peek Resolver")
local instant_peek_strength_slider = ui.new_slider("RAGE", "Other", "Instant Peek Strength", 0, 60, 30, true, "%")
local anti_prediction_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Anti-Prediction Position")
local anti_prediction_strength_slider = ui.new_slider("RAGE", "Other", "Anti-Prediction Strength", 0, 90, 45, true, "%")
local anti_defensive_dt_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Anti-Defensive DT")
local anti_defensive_dt_strength_slider = ui.new_slider("RAGE", "Other", "Anti-Defensive DT Strength", 0, 20, 10, true, "ticks")

local enable_lag_peek_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Lag Peak")
local lag_peek_strength_slider = ui.new_slider("RAGE", "Other", "Lag Peak Strength", 0, 100, 50, true, "%")
local enable_lag_exploit_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Lag Exploit")

local enable_fake_flick_exploit_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Fake Flick Exploit")
local fake_flick_strength_slider = ui.new_slider("RAGE", "Other", "Fake Flick Strength", 0, 90, 45, true, "%")
local enable_internal_backtrack_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Internal Backtrack")
local backtrack_ticks_slider = ui.new_slider("RAGE", "Other", "Backtrack Ticks", 0, 100, 45, true, "%")

local enable_trash_talk_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Trash Talk")
local trash_talk_mode_combobox = ui.new_combobox("RAGE", "Other", "Trash Talk Mode", {
    "Trash",
    "Trash with ads"
})
local enable_clantag_spammer_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Clan Tag Spammer")
local clantag_change_speed_slider = ui.new_slider("RAGE", "Other", "Clan Tag Change Speed", 1, 20, 5, true, "s", 0.1)

local last_yaw_map = {}
local last_velocity_map = {}

local last_hurt_time = globals.curtime()

local function normalize_yaw(angle)
    angle = tonumber(angle) or 0
    while angle > 180 do angle = angle - 360 end
    while angle < -180 do angle = angle + 360 end
    return angle
end

local function calculate_prediction_offset(enemy_index)
    if not ui.get(enable_resolver_checkbox) or not enemy_index or not entity.is_alive(enemy_index) then
        return 0
    end

    local vel_x = entity.get_prop(enemy_index, "m_vecVelocity[0]") or 0
    local vel_y = entity.get_prop(enemy_index, "m_vecVelocity[1]") or 0
    local velocity = math.sqrt(vel_x^2 + vel_y^2)

    local prediction_mode = ui.get(prediction_mode_combobox)
    local prediction_strength = ui.get(prediction_strength_slider)
    local angle_offset = 0
    local current_yaw = entity.get_prop(enemy_index, "m_angEyeAngles[1]") or 0

    if prediction_mode == "Static" then
        angle_offset = prediction_strength
    elseif prediction_mode == "Adaptive" then
        angle_offset = prediction_strength * (velocity / 250)
    elseif prediction_mode == "Dynamic" then
        angle_offset = prediction_strength * (velocity / 300) + math.random(-5, 5)
    elseif prediction_mode == "Neverlose" then
        local prev_yaw = last_yaw_map[enemy_index] or current_yaw
        local prev_velocity = last_velocity_map[enemy_index] or velocity
        local yaw_delta = current_yaw - prev_yaw
        local velocity_delta = velocity - prev_velocity
        angle_offset = yaw_delta + (velocity_delta * (prediction_strength / 100))
    end

    last_yaw_map[enemy_index] = current_yaw
    last_velocity_map[enemy_index] = velocity

    return angle_offset
end

local function apply_global_prediction()
    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        local offset = calculate_prediction_offset(player_index)
        if offset then
            local current_yaw = entity.get_prop(player_index, "m_angEyeAngles[1]") or 0
            entity.set_prop(player_index, "m_angEyeAngles[1]", current_yaw + offset)
        end
    end
end


local function apply_resolver(enemy_index)
    if not ui.get(enable_resolver_checkbox) or not enemy_index or not entity.is_alive(enemy_index) then
        return
    end

    local yaw = entity.get_prop(enemy_index, "m_angEyeAngles[1]") or 0
    local resolver_mode = ui.get(resolver_mode_combobox)
    local strength = ui.get(prediction_strength_slider) or 0

    if resolver_mode == "Low" then
        yaw = yaw + strength / 2
    elseif resolver_mode == "Medium" then
        yaw = yaw + math.random(-strength, strength)
    elseif resolver_mode == "High" then
        yaw = yaw + ((globals.tickcount() % 2 == 0) and strength or -strength)
    elseif resolver_mode == "Neverlose" then
        yaw = yaw + math.random(-60, 60)
    elseif resolver_mode == "Exploiter" then
        yaw = yaw + 35
    end

    entity.set_prop(enemy_index, "m_angEyeAngles[1]", normalize_yaw(yaw))
end


local function apply_priority_hitbox_logic(enemy_index)
    if not ui.get(enable_extra_resolver_checkbox) or not enemy_index or not entity.is_alive(enemy_index) then
        return
    end

    local selected_hitboxes = ui.get(priority_hitbox_multiselect)
    local hitbox_map = {}
    for _, hitbox_name in ipairs(selected_hitboxes) do
        if hitbox_name == "Head" then table.insert(hitbox_map, 0)
        elseif hitbox_name == "Chest" then table.insert(hitbox_map, 2)
        elseif hitbox_name == "Stomach" then table.insert(hitbox_map, 3)
        end
    end

    if #hitbox_map == 0 then return end

    local strength = ui.get(priority_strength_slider) or 10
    local yaw = entity.get_prop(enemy_index, "m_angEyeAngles[1]") or 0

    for _, hitbox_id in ipairs(hitbox_map) do
        if hitbox_id == 0 then yaw = yaw + strength
        elseif hitbox_id == 2 then yaw = yaw + strength / 2
        elseif hitbox_id == 3 then yaw = yaw - strength / 2
        end
    end
    entity.set_prop(enemy_index, "m_angEyeAngles[1]", yaw)
end

-- weird
client.set_event_callback("aim_fire", function(event)
    if not ui.get(anti_dt_resolver_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player then return end

    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        if entity.is_alive(player_index) then
            local sim_time = entity.get_prop(player_index, "m_flSimulationTime") or 0
            local old_sim_time = entity.get_prop(player_index, "m_flOldSimulationTime") or 0
            local sim_time_delta = sim_time - old_sim_time

            if sim_time_delta < 0.01 then
                local eye_yaw = entity.get_prop(player_index, "m_angEyeAngles[1]") or 0
                entity.set_prop(player_index, "m_angEyeAngles[1]", eye_yaw + math.random(-45, 45))
            end
        end
    end
end)

client.set_event_callback("player_hurt", function(event)
    local victim_index = client.userid_to_entindex(event.userid)
    if victim_index == entity.get_local_player() then
        last_hurt_time = globals.curtime()
    end
end)


client.set_event_callback("create_move", function(cmd)
    if not ui.get(enable_internal_backtrack_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local current_yaw = entity.get_prop(local_player, "m_angEyeAngles[1]") or 0
    local time_since_hurt = globals.curtime() - last_hurt_time

    if time_since_hurt < 2 then
        entity.set_prop(local_player, "m_angEyeAngles[1]", current_yaw + math.random(-45, 45))
    else
        entity.set_prop(local_player, "m_angEyeAngles[1]", current_yaw + math.random(-15, 15))
    end
end)

local function handle_anti_prediction(cmd)
    if not ui.get(anti_prediction_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local strength = ui.get(anti_prediction_strength_slider)
    local original_yaw = cmd.yaw
    local offset = math.random(-strength, strength)
    cmd.yaw = original_yaw + offset
end

local function handle_fake_flick(cmd)
    if not ui.get(enable_fake_flick_exploit_checkbox) then return end
    
    if bit_lib.band(cmd.buttons, 1) ~= 0 then 
        local strength = ui.get(fake_flick_strength_slider)
        cmd.yaw = cmd.yaw + (math.random(0, 1) == 1 and strength or -strength)
    end
end

client.set_event_callback("create_move", function(cmd)
    if not ui.get(enable_lag_exploit_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player then return end

    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        local has_fired = entity.get_prop(player_index, "m_hActiveWeapon") and
                          bit_lib.band(entity.get_prop(player_index, "m_iShotsFired") or 0, 1) ~= 0
        if has_fired then
            cmd.choked_commands = 14
            return
        end
    end
end)

local function handle_autofire(cmd)
    if not (ui.get(resolver_mode_combobox) == "High" or ui.get(resolver_mode_combobox) == "Neverlose") then return end
    if not (ui.get(prediction_mode_combobox) == "Dynamic" or ui.get(prediction_mode_combobox) == "Neverlose") then return end
    
    local threshold = ui.get(autofire_threshold_slider)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        if entity.is_alive(player_index) then
            if math.random(0, 100) <= threshold then
                cmd.buttons = bit_lib.bor(cmd.buttons, 1) 
            end
        end
    end
end

local function handle_anti_defensive_dt(cmd)
    if not ui.get(anti_defensive_dt_checkbox) then return end

    local base_shift = ui.get(anti_defensive_dt_strength_slider)
    local final_shift = base_shift

    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        local sim_time = entity.get_prop(player_index, "m_flSimulationTime")
        if sim_time and sim_time > 0 then
            final_shift = final_shift + 2
        end
    end
    cmd.shift_tick = final_shift
end

local function handle_lag_peek(cmd)
    if not ui.get(enable_lag_peek_checkbox) then return end
    local strength = ui.get(lag_peek_strength_slider)
    local offset = math.random(-strength, strength)
    cmd.yaw = cmd.yaw + offset
end

local function handle_internal_backtrack_tick(cmd)
    if not ui.get(enable_internal_backtrack_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local ticks_to_backtrack = ui.get(backtrack_ticks_slider) or 0
    cmd.tick_count = globals.tickcount() - ticks_to_backtrack
end

client.set_event_callback("create_move", function()
    if not ui.get(instant_peek_resolver_checkbox) then return end
    
    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        if entity.is_alive(player_index) then
            local vel_x = entity.get_prop(player_index, "m_vecVelocity[0]") or 0
            local vel_y = entity.get_prop(player_index, "m_vecVelocity[1]") or 0
            local velocity = math.sqrt(vel_x^2 + vel_y^2)

            if velocity > 250 then
                local current_yaw = entity.get_prop(player_index, "m_angEyeAngles[1]") or 0
                local strength = ui.get(instant_peek_strength_slider)
                entity.set_prop(player_index, "m_angEyeAngles[1]", current_yaw + math.random(-strength, strength))
            end
        end
    end
end)



local trash_talk_messages = {
    ["Trash"] = {
        "1 ezz",
        "Cry n1gga",
        "Ohh, sorry i fuSCKING your mom, and k1ll1ng y0ur sister",
        "1 = your iq",
        "pls delete cs:go and go cry about it mom",
        "Ez",
        "Why u cry? oh sry i forgot, i k1ll1ng your mom"
    },
    ["Trash with ads"] = {
        "U fucking by dsc.gg/newerahvh - The Best Resolver",
        "Oh sry 1, dsc.gg/newerahvh $ for resolver, ez",
        "Why u cry? i use dsc.gg/newerahvh, $ for use",
        "Pls leave hvh or buy resolver, dsc.gg/newerahvh!",
        "Your resolver is ugly, better buy this dsc.gg/newerahvh",
        "Your mom fuSCKING by dsc.gg/newerahvh"
    }
}

local function send_trash_talk_message()
    if not ui.get(enable_trash_talk_checkbox) then return end
    
    local mode = ui.get(trash_talk_mode_combobox)
    local message_pool = trash_talk_messages[mode]
    if message_pool then
        local random_message = message_pool[math.random(#message_pool)]
        client.exec("say " .. random_message)
    end
end

client.set_event_callback("player_death", function(event)
    local attacker_index = client.userid_to_entindex(event.attacker)
    local local_player = entity.get_local_player()
    if attacker_index == local_player then
        send_trash_talk_message()
    end
end)


local clantag_frames = {
    "C2TS0LV3R", "C2TS0LV3R", "CATS0LV3R", "CATS0LV3R",
    "C2TSOLVER", "C2TSOLVER", "CATSOLVER", "CATSOLVE",
    "CATSOLV", "CATSOL", "CATSO", "CATS", "CAT", "CA", "C",
    "C", "CA", "CAT", "CATS", "CATSO", "CATSOL", "CATSOLV",
    "CATSOLVE", "CATSOLVER"
}
local last_clantag_update_time, clantag_current_frame = 0, 1

local function animate_clantag()
    if not ui.get(enable_clantag_spammer_checkbox) then
        client.set_clan_tag("")
        return
    end

    local current_time = globals.realtime()
    local change_interval = ui.get(clantag_change_speed_slider) * 0.1

    if current_time - last_clantag_update_time >= change_interval then
        client.set_clan_tag(clantag_frames[clantag_current_frame])
        clantag_current_frame = clantag_current_frame + 1
        if clantag_current_frame > #clantag_frames then
            clantag_current_frame = 1
        end
        last_clantag_update_time = current_time
    end
end



local function on_create_move(cmd)
    handle_autofire(cmd)
    handle_anti_defensive_dt(cmd)
    handle_lag_peek(cmd)
    handle_fake_flick(cmd)
    handle_internal_backtrack_tick(cmd)
    handle_anti_prediction(cmd)
end

local function on_paint()
    apply_global_prediction()
    local players = entity.get_players(true)
    for _, player_index in ipairs(players) do
        apply_resolver(player_index)
        -- apply_priority_hitbox_logic(player_index)
    end
    animate_clantag()
end


client.set_event_callback("create_move", on_create_move)
client.set_event_callback("paint", on_paint)


local function update_ui_visibility()
    local selected_mode = ui.get(main_mode_combobox)

    local is_resolver_mode = (selected_mode == "Resolver + Predict")
    local is_lag_mode = (selected_mode == "Lag Function")
    local is_exploit_mode = (selected_mode == "Exploit Function")
    local is_misc_mode = (selected_mode == "Misc Function")

    ui.set_visible(enable_resolver_checkbox, is_resolver_mode)
    ui.set_visible(resolver_mode_combobox, is_resolver_mode and ui.get(enable_resolver_checkbox))
    ui.set_visible(prediction_mode_combobox, is_resolver_mode and ui.get(enable_resolver_checkbox))
    ui.set_visible(prediction_strength_slider, is_resolver_mode and ui.get(enable_resolver_checkbox))
    
    local show_autofire = (ui.get(resolver_mode_combobox) == "High" or ui.get(resolver_mode_combobox) == "Neverlose") or
                          (ui.get(prediction_mode_combobox) == "Dynamic" or ui.get(prediction_mode_combobox) == "Neverlose")
    ui.set_visible(autofire_threshold_slider, is_resolver_mode and show_autofire)

    ui.set_visible(enable_extra_resolver_checkbox, is_resolver_mode and ui.get(enable_resolver_checkbox))
    ui.set_visible(priority_hitbox_multiselect, is_resolver_mode and ui.get(enable_extra_resolver_checkbox))
    ui.set_visible(priority_strength_slider, is_resolver_mode and ui.get(enable_extra_resolver_checkbox))
    
    ui.set_visible(anti_dt_resolver_checkbox, is_resolver_mode)
    ui.set_visible(anti_defensive_dt_checkbox, is_resolver_mode)
    ui.set_visible(anti_defensive_dt_strength_slider, is_resolver_mode and ui.get(anti_defensive_dt_checkbox))
    ui.set_visible(anti_prediction_checkbox, is_resolver_mode)
    ui.set_visible(anti_prediction_strength_slider, is_resolver_mode and ui.get(anti_prediction_checkbox))
    ui.set_visible(instant_peek_resolver_checkbox, is_resolver_mode)
    ui.set_visible(instant_peek_strength_slider, is_resolver_mode and ui.get(instant_peek_resolver_checkbox))
    
    ui.set_visible(enable_lag_peek_checkbox, is_lag_mode)
    ui.set_visible(lag_peek_strength_slider, is_lag_mode and ui.get(enable_lag_peek_checkbox))
    ui.set_visible(enable_lag_exploit_checkbox, is_lag_mode)

    ui.set_visible(enable_fake_flick_exploit_checkbox, is_exploit_mode)
    ui.set_visible(fake_flick_strength_slider, is_exploit_mode and ui.get(enable_fake_flick_exploit_checkbox))
    ui.set_visible(enable_internal_backtrack_checkbox, is_exploit_mode)
    ui.set_visible(backtrack_ticks_slider, is_exploit_mode and ui.get(enable_internal_backtrack_checkbox))
    
    ui.set_visible(enable_trash_talk_checkbox, is_misc_mode)
    ui.set_visible(trash_talk_mode_combobox, is_misc_mode and ui.get(enable_trash_talk_checkbox))
    ui.set_visible(enable_clantag_spammer_checkbox, is_misc_mode)
    ui.set_visible(clantag_change_speed_slider, is_misc_mode and ui.get(enable_clantag_spammer_checkbox))
end

local ui_elements_with_callbacks = {
    main_mode_combobox, enable_resolver_checkbox, resolver_mode_combobox, prediction_mode_combobox,
    enable_lag_peek_checkbox, enable_lag_exploit_checkbox, enable_fake_flick_exploit_checkbox,
    enable_internal_backtrack_checkbox, enable_extra_resolver_checkbox, enable_trash_talk_checkbox,
    anti_dt_resolver_checkbox, instant_peek_resolver_checkbox, anti_defensive_dt_checkbox,
    enable_clantag_spammer_checkbox, clantag_change_speed_slider, anti_prediction_checkbox
}
for _, element in ipairs(ui_elements_with_callbacks) do
    ui.set_callback(element, update_ui_visibility)
end

update_ui_visibility()
