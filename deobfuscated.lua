-- discord lexyqqw
local bit = require("bit")
local gamesense_color = require("gamesense/color") 


local main_label = ui.new_label("RAGE", "Other", "CATSOLVER")

local mode_combobox = ui.new_combobox("RAGE", "Other", "\aCC0000FFMode:", {
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
local enable_instant_peek_resolver_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Instant Peek Resolver")
local instant_peek_strength_slider = ui.new_slider("RAGE", "Other", "Instant Peek Strength", 0, 60, 30, true, "%")
local enable_anti_prediction_checkbox = ui.new_checkbox("RAGE", "Other", "Enable Anti-Prediction Position")
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


local clan_tags = {
    "C2TS0LV3R", "C2TS0LV3R", "CATS0LV3R", "CATS0LV3R", "C2TSOLVER", "C2TSOLVER", "CATSOLVER",
    "CATSOLVER", "CATSOLV", "CATSOL", "CATSO", "CATS", "CAT", "CA", "C", "C", "CA", "CAT", "CATS",
    "CATSO", "CATSOL", "CATSOLV", "CATSOLVE", "CATSOLVER"
}
local last_clantag_update_time, clantag_index = 0, 1

local function update_clan_tag()
    if not ui.get(enable_clantag_spammer_checkbox) then
        client.set_clan_tag("")
        return
    end

    local current_time = globals.realtime()
    local update_interval = ui.get(clantag_change_speed_slider) * 0.1

    if current_time - last_clantag_update_time >= update_interval then
        client.set_clan_tag(clan_tags[clantag_index])
        clantag_index = clantag_index + 1
        if clantag_index > #clan_tags then
            clantag_index = 1
        end
        last_clantag_update_time = current_time
    end
end

local last_yaw, last_velocity = {}, {}

local function normalize_yaw(yaw)
    yaw = tonumber(yaw) or 0
    while yaw > 180 do yaw = yaw - 360 end
    while yaw < -180 do yaw = yaw + 360 end
    return yaw
end

local function calculate_prediction_offset(entity_id)
    if not ui.get(enable_resolver_checkbox) then return end
    if not entity_id or not entity.is_alive(entity_id) then return end

    local vel_x = entity.get_prop(entity_id, "m_vecVelocity[0]") or 0
    local vel_y = entity.get_prop(entity_id, "m_vecVelocity[1]") or 0
    local velocity_2d = math.sqrt(vel_x^2 + vel_y^2)

    local prediction_mode = ui.get(prediction_mode_combobox)
    local prediction_strength = ui.get(prediction_strength_slider)
    local offset = 0
    local current_yaw = entity.get_prop(entity_id, "m_angEyeAngles[1]") or 0

    if prediction_mode == "Static" then
        offset = prediction_strength
    elseif prediction_mode == "Adaptive" then
        offset = prediction_strength * (velocity_2d / 250)
    elseif prediction_mode == "Dynamic" then
        offset = prediction_strength * (velocity_2d / 300) + math.random(-5, 5)
    elseif prediction_mode == "Neverlose" then
        local prev_yaw = last_yaw[entity_id] or current_yaw
        local prev_velocity = last_velocity[entity_id] or velocity_2d
        local yaw_delta = current_yaw - prev_yaw
        local velocity_delta = velocity_2d - prev_velocity
        offset = yaw_delta + (velocity_delta * (prediction_strength / 100))
        last_yaw[entity_id] = current_yaw
        last_velocity[entity_id] = velocity_2d
    end

    return offset
end

local function apply_prediction(event)
    local prediction_strength = ui.get(prediction_strength_slider) or 0
    local players = entity.get_players(true)
    for i, player_id in ipairs(players) do
        local offset = calculate_prediction_offset(player_id)
        if offset then
            local current_yaw = entity.get_prop(player_id, "m_angEyeAngles[1]") or 0
            entity.set_prop(player_id, "m_angEyeAngles[1]", current_yaw + offset)
        end
    end
end

local function apply_resolver(entity_id)
    if not ui.get(enable_resolver_checkbox) or not entity_id or not entity.is_alive(entity_id) then
        return
    end

    local yaw = entity.get_prop(entity_id, "m_angEyeAngles[1]") or 0
    local resolver_mode = ui.get(resolver_mode_combobox)
    local prediction_strength = ui.get(prediction_strength_slider) or 0 

    if resolver_mode == "Low" then
        yaw = yaw + prediction_strength / 2
    elseif resolver_mode == "Medium" then
        yaw = yaw + math.random(-prediction_strength, prediction_strength)
    elseif resolver_mode == "High" then
        yaw = yaw + ((globals.tickcount() % 2 == 0) and prediction_strength or -prediction_strength)
    elseif resolver_mode == "Neverlose" then
        yaw = yaw + math.random(-60, 60)
    elseif resolver_mode == "Exploiter" then
        yaw = yaw + 35
    end

    yaw = normalize_yaw(yaw)
    entity.set_prop(entity_id, "m_angEyeAngles[1]", yaw)
end

local function on_paint_resolver()
    local players = entity.get_players(true)
    for i, player_id in ipairs(players) do
        apply_resolver(player_id)
    end
end


local function apply_priority_hitbox_resolver(entity_id)
    if not ui.get(enable_extra_resolver_checkbox) then return end
    if not entity_id or not entity.is_alive(entity_id) then return end

    local selected_hitboxes = ui.get(priority_hitbox_multiselect)
    local hitbox_map = {}
    for _, hitbox_name in ipairs(selected_hitboxes) do
        if hitbox_name == "Head" then
            table.insert(hitbox_map, 0)
        elseif hitbox_name == "Chest" then
            table.insert(hitbox_map, 2)
        elseif hitbox_name == "Stomach" then
            table.insert(hitbox_map, 3)
        end
    end

    if #hitbox_map == 0 then return end

    local strength = ui.get(priority_strength_slider) or 10
    local yaw = entity.get_prop(entity_id, "m_angEyeAngles[1]") or 0

    for _, hitbox_id in ipairs(hitbox_map) do
        if hitbox_id == 0 then -- Head
            yaw = yaw + strength
        elseif hitbox_id == 2 then -- Chest
            yaw = yaw + strength / 2
        elseif hitbox_id == 3 then -- Stomach
            yaw = yaw - strength / 2
        end
    end
    entity.set_prop(entity_id, "m_angEyeAngles[1]", yaw)
end

local function on_create_move_instant_peek()
    if not ui.get(enable_instant_peek_resolver_checkbox) then return end
    
    local players = entity.get_players(true)
    for _, player_id in ipairs(players) do
        if entity.is_alive(player_id) then
            local vel_x = entity.get_prop(player_id, "m_vecVelocity[0]") or 0
            local vel_y = entity.get_prop(player_id, "m_vecVelocity[1]") or 0
            local velocity_2d = math.sqrt(vel_x^2 + vel_y^2)

            if velocity_2d > 250 then
                local current_yaw = entity.get_prop(player_id, "m_angEyeAngles[1]") or 0
                local strength = ui.get(instant_peek_strength_slider)
                entity.set_prop(player_id, "m_angEyeAngles[1]", current_yaw + math.random(-strength, strength))
            end
        end
    end
end

local function on_create_move_anti_prediction(user_cmd)
    if not ui.get(enable_anti_prediction_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local strength = ui.get(anti_prediction_strength_slider)
    local current_yaw = user_cmd.yaw
    local random_offset = math.random(-strength, strength)
    user_cmd.yaw = current_yaw + random_offset
end

local function on_aim_fire_anti_dt(event)
    if not ui.get(anti_dt_resolver_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player then return end
    
    local players = entity.get_players(true)
    for _, player_id in ipairs(players) do
        if entity.is_alive(player_id) then
            local sim_time = entity.get_prop(player_id, "m_flSimulationTime") or 0
            local old_sim_time = entity.get_prop(player_id, "m_flOldSimulationTime") or 0
            local sim_diff = sim_time - old_sim_time

            if sim_diff < 0.01 then
                local current_yaw = entity.get_prop(player_id, "m_angEyeAngles[1]") or 0
                entity.set_prop(player_id, "m_angEyeAngles[1]", current_yaw + math.random(-45, 45))
            end
        end
    end
end

local function on_create_move_anti_defensive_dt(user_cmd)
    if not ui.get(mode_combobox) or not ui.get(anti_defensive_dt_checkbox) then return end
    
    local strength = ui.get(anti_defensive_dt_strength_slider)
    local shift_amount = strength
    
    local players = entity.get_players(true)
    for _, player_id in ipairs(players) do
        local sim_time = entity.get_prop(player_id, "m_flSimulationTime")
        if sim_time and sim_time > 0 then
            shift_amount = shift_amount + 2
        end
    end
    user_cmd.shift_tick = shift_amount
end


local last_hurt_time = globals.curtime()
client.set_event_callback("player_hurt", function(event)
    local victim_userid = client.userid_to_entindex(event.userid)
    if victim_userid == entity.get_local_player() then
        last_hurt_time = globals.curtime()
    end
end)

local function on_create_move_internal_backtrack(user_cmd)
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
end

local function on_create_move_lag_exploit(user_cmd)
    if not ui.get(enable_lag_exploit_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player then return end
    
    local players = entity.get_players(true)
    for _, player_id in ipairs(players) do
        local is_shooting = entity.get_prop(player_id, "m_hActiveWeapon") and
                              bit.band(entity.get_prop(player_id, "m_iShotsFired") or 0, 1) ~= 0
        if is_shooting then
            user_cmd.choked_commands = 14 
            return
        end
    end
end

local function on_create_move_fake_flick(user_cmd)
    if not ui.get(mode_combobox) or not ui.get(enable_fake_flick_exploit_checkbox) then return end
    
    if bit.band(user_cmd.buttons, 1) ~= 0 then
        local strength = ui.get(fake_flick_strength_slider)
        user_cmd.yaw = user_cmd.yaw + (math.random(0, 1) == 1 and strength or -strength)
    end
end

local function on_create_move_lag_peek(user_cmd)
    if not ui.get(mode_combobox) or not ui.get(enable_lag_peek_checkbox) then return end
    
    local strength = ui.get(lag_peek_strength_slider)
    local random_offset = math.random(-strength, strength)
    user_cmd.yaw = user_cmd.yaw + random_offset
end

local function on_create_move_backtrack_override(user_cmd)
    if not ui.get(enable_internal_backtrack_checkbox) then return end
    
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end
    
    local backtrack_amount = ui.get(backtrack_ticks_slider) or 0
    user_cmd.tick_count = globals.tickcount() - backtrack_amount
end

local function on_create_move_exploit_backtrack(user_cmd)
    if not ui.get(mode_combobox) or ui.get(resolver_mode_combobox) ~= "Exploiter" then
        return
    end

    local players = entity.get_players(true)
    for i, player_id in ipairs(players) do
        if entity.is_alive(player_id) then
            local backtrack_amount = ui.get(backtrack_ticks_slider)
            user_cmd.tick_count = globals.tickcount - backtrack_amount
        end
    end
end



local trash_talk_messages = {
    ["Trash"] = {
        "1 ezz",
        "Cry n1gga",
        "Ohh, sorry i fuSК1ng your mom, and k1ll1ng y0ur sister",
        "1 = your iq",
        "pls delete cs:go and go cry about it mom",
        "Ez",
        "Why u cry? oh sry i forgot, i k1ll1ng your mom"
    },
    ["Trash with ads"] = {
        "U fucking by dsc.gg/newerahvh - The Best Resolver",
        "Oh sry 1, dsc.gg/newerahvh 3$ for resolver, ez",
        "Why u cry? i use dsc.gg/newerahvh, 3$ for use",
        "Pls leave hvh or buy resolver, dsc.gg/newerahvh!",
        "Your resolver is ugly, better buy this dsc.gg/newerahvh",
        "Your mom fuSК1ng by dsc.gg/newerahvh"
    }
}

local function send_trash_talk_message()
    if not ui.get(enable_trash_talk_checkbox) then return end
    
    local mode = ui.get(trash_talk_mode_combobox)
    local message_list = trash_talk_messages[mode]
    
    if message_list then
        local random_message = message_list[math.random(#message_list)]
        client.exec("say " .. random_message)
    end
end

client.set_event_callback("player_death", function(event)
    local attacker_entindex = client.userid_to_entindex(event.attacker)
    local local_player = entity.get_local_player()
    if attacker_entindex == local_player then
        send_trash_talk_message()
    end
end)


local function on_create_move_autofire(user_cmd)
    if not ui.get(mode_combobox) or not ui.get(enable_resolver_checkbox) then return end
    if not (ui.get(resolver_mode_combobox) == "High" or ui.get(resolver_mode_combobox) == "Neverlose") then return end
    if not (ui.get(prediction_mode_combobox) == "Dynamic" or ui.get(prediction_mode_combobox) == "Neverlose") then return end
    
    local threshold = ui.get(autofire_threshold_slider)
    local local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

    local players = entity.get_players(true)
    for _, player_id in ipairs(players) do
        if entity.is_alive(player_id) then
            local random_chance = math.random(0, 100)
            if random_chance <= threshold then
                user_cmd.buttons = bit.bor(user_cmd.buttons, 1)
            end
        end
    end
end


local function update_ui_visibility()
    local selected_mode = ui.get(mode_combobox)
    local resolver_tab_visible = selected_mode == "Resolver + Predict"
    local lag_tab_visible = selected_mode == "Lag Function"
    local exploit_tab_visible = selected_mode == "Exploit Function"
    local misc_tab_visible = selected_mode == "Misc Function"

    ui.set_visible(enable_resolver_checkbox, resolver_tab_visible)
    ui.set_visible(resolver_mode_combobox, resolver_tab_visible and ui.get(enable_resolver_checkbox))
    ui.set_visible(prediction_mode_combobox, resolver_tab_visible and ui.get(enable_resolver_checkbox))
    ui.set_visible(prediction_strength_slider, resolver_tab_visible and ui.get(enable_resolver_checkbox))
    
    local resolver_mode = ui.get(resolver_mode_combobox)
    local prediction_mode = ui.get(prediction_mode_combobox)
    local is_high_resolver = resolver_mode == "High" or resolver_mode == "Neverlose" or resolver_mode == "Exploiter"
    local is_dynamic_prediction = prediction_mode == "Dynamic" or prediction_mode == "Neverlose"
    ui.set_visible(autofire_threshold_slider, resolver_tab_visible and is_high_resolver and is_dynamic_prediction)
    
    ui.set_visible(enable_extra_resolver_checkbox, resolver_tab_visible and ui.get(enable_resolver_checkbox))
    ui.set_visible(priority_hitbox_multiselect, resolver_tab_visible and ui.get(enable_extra_resolver_checkbox))
    ui.set_visible(priority_strength_slider, resolver_tab_visible and ui.get(enable_extra_resolver_checkbox))
    ui.set_visible(anti_dt_resolver_checkbox, resolver_tab_visible)
    ui.set_visible(anti_defensive_dt_checkbox, resolver_tab_visible)
    ui.set_visible(anti_defensive_dt_strength_slider, resolver_tab_visible and ui.get(anti_defensive_dt_checkbox))
    ui.set_visible(enable_anti_prediction_checkbox, resolver_tab_visible)
    ui.set_visible(anti_prediction_strength_slider, resolver_tab_visible and ui.get(enable_anti_prediction_checkbox))
    ui.set_visible(enable_instant_peek_resolver_checkbox, resolver_tab_visible)
    ui.set_visible(instant_peek_strength_slider, resolver_tab_visible and ui.get(enable_instant_peek_resolver_checkbox))

    ui.set_visible(enable_lag_peek_checkbox, lag_tab_visible)
    ui.set_visible(lag_peek_strength_slider, lag_tab_visible and ui.get(enable_lag_peek_checkbox))
    ui.set_visible(enable_lag_exploit_checkbox, lag_tab_visible)

    ui.set_visible(enable_fake_flick_exploit_checkbox, exploit_tab_visible)
    ui.set_visible(fake_flick_strength_slider, exploit_tab_visible and ui.get(enable_fake_flick_exploit_checkbox))
    ui.set_visible(enable_internal_backtrack_checkbox, exploit_tab_visible)
    ui.set_visible(backtrack_ticks_slider, exploit_tab_visible and ui.get(enable_internal_backtrack_checkbox))

    ui.set_visible(enable_trash_talk_checkbox, misc_tab_visible)
    ui.set_visible(trash_talk_mode_combobox, misc_tab_visible and ui.get(enable_trash_talk_checkbox))
    ui.set_visible(enable_clantag_spammer_checkbox, misc_tab_visible)
    ui.set_visible(clantag_change_speed_slider, misc_tab_visible and ui.get(enable_clantag_spammer_checkbox))
end


ui.set_callback(mode_combobox, update_ui_visibility)
ui.set_callback(enable_resolver_checkbox, update_ui_visibility)
ui.set_callback(resolver_mode_combobox, update_ui_visibility)
ui.set_callback(prediction_mode_combobox, update_ui_visibility)
ui.set_callback(enable_lag_peek_checkbox, update_ui_visibility)
ui.set_callback(enable_lag_exploit_checkbox, update_ui_visibility)
ui.set_callback(enable_fake_flick_exploit_checkbox, update_ui_visibility)
ui.set_callback(enable_internal_backtrack_checkbox, update_ui_visibility)
ui.set_callback(enable_extra_resolver_checkbox, update_ui_visibility)
ui.set_callback(enable_trash_talk_checkbox, update_ui_visibility)
ui.set_callback(anti_dt_resolver_checkbox, update_ui_visibility)
ui.set_callback(enable_instant_peek_resolver_checkbox, update_ui_visibility)
ui.set_callback(anti_defensive_dt_checkbox, update_ui_visibility)
ui.set_callback(enable_clantag_spammer_checkbox, update_ui_visibility)
ui.set_callback(clantag_change_speed_slider, update_ui_visibility)
ui.set_callback(enable_anti_prediction_checkbox, update_ui_visibility)
ui.set_callback(anti_prediction_strength_slider, update_ui_visibility)

local function on_create_move(user_cmd)
    on_create_move_autofire(user_cmd)
    on_create_move_anti_defensive_dt(user_cmd)
    on_create_move_lag_peek(user_cmd)
    on_create_move_fake_flick(user_cmd)
    on_create_move_exploit_backtrack(user_cmd)
    on_create_move_internal_backtrack(user_cmd)
	on_create_move_backtrack_override(user_cmd)
    on_create_move_lag_exploit(user_cmd)
    on_create_move_instant_peek()
    on_create_move_anti_prediction(user_cmd)
end

client.set_event_callback("create_move", on_create_move)

local function on_paint()
    apply_prediction()
    on_paint_resolver()
    update_clan_tag()
end

client.set_event_callback("paint", on_paint)

client.set_event_callback("aim_fire", on_aim_fire_anti_dt)

update_ui_visibility()
