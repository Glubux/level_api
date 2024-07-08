local storage = minetest.get_mod_storage()

function save_data(data)
    storage:set_string("lvl", minetest.serialize(data))
end

function get_data()
    local data = storage:get_string("lvl")
    if data ~= "" then
        data = minetest.deserialize(data)
    else
        data = {}
    end
    return data
end

function get_next_level(level, xp, totxp)
    if level <= 10 then
        -- linear
        local require_xp = math.floor(100 * level) -- benötigtes XP für lvlUP
        if xp >= require_xp then
            level = level + 1
            xp = xp - require_xp
        end
    elseif level <= 20 then
        -- quadratisch
        local require_xp = math.floor(1000 + ((level - 10) ^ 2) * 20) -- benötigtes XP für lvlUP
        if xp >= require_xp then
            level = level + 1
            xp = xp - require_xp
        end
    else
        -- exponentiell
        local require_xp = math.floor(3000 + (1.5 ^ (level - 20)) * 200) -- benötigtes XP für lvlUP
        if xp >= require_xp then
            level = level + 1
            xp = xp - require_xp
        end
    end
    return level, xp, totxp
end

function add_xp(player_name, new_xp)
    local data = get_data()
    local player_data = data[player_name]

    if player_data then
        local current_level = player_data.level or 1
        local current_xp = player_data.xp or 0
        local current_totxp = player_data.totxp or 0

        current_totxp = current_totxp + new_xp
        local new_level, new_xp, new_totxp = get_next_level(current_level, current_xp + new_xp, current_totxp)
        data[player_name] = {level = new_level, xp = new_xp, totxp = new_totxp}
        save_data(data)
    end
end

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    local data = get_data()

    if not data[player_name] then
        data[player_name] = {level = 1, xp = 0, totxp = 0}
        save_data(data)
    end
end)

minetest.register_chatcommand("level", {
    description = "Zeige dein Level und XP an.",
    privs = {},
    func = function(player_name, params)
        local data = get_data()
        local player_data = data[player_name]

        if player_data then
            local level = player_data.level
            local xp = player_data.xp

            minetest.chat_send_player(player_name, "Level: " .. level .. ", XP: " .. xp)
        end
    end
})

minetest.register_chatcommand("reset_level", {
    description = "Resete ein Level eines Spielers",
    privs = {server},
    params = "[player_name]",
    func = function(player_name, params)
        local target_player = params or player_name
        local target_player = minetest.get_player_by_name(target_player)
        
        if target_player then
            local data = get_data()

            data[player_name] = {level = 1, xp = 0, totxp = 100}
            save_data(data)
    
            minetest.chat_send_player(player_name, "Dein Level wurde auf "..data[player_name].level.." und deine XP auf "..data[player_name].xp.." gesetzt.")
        else
            minetest.chat_send_player(player_name, "Player nicht gefunden.")
        end
    end
})

minetest.register_chatcommand("addxp", {
    description = "Füge XP hinzu",
    privs = {server},
    params = "<xp> [player_name]",
    func = function(player_name, params)
        local args = params:split(" ")
        local xp = tonumber(args[1])
        local target_player_name = args[2] or player_name

        if not xp then
            minetest.chat_send_player(player_name, "Gib die XP-Menge an.")
            return false
        end

        local target_player = minetest.get_player_by_name(target_player_name)
        if target_player then
            add_xp(target_player_name, xp)
            minetest.chat_send_player(player_name, "Dem Spieler " .. target_player_name .. " wurden " .. xp .. " XP hinzugefügt.")
            return true
        else
            minetest.chat_send_player(player_name, "Spieler " .. target_player_name .. " nicht gefunden.")
            return false
        end
    end
})