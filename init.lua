local storage = minetest.get_mod_storage()
--Create an table for the functions
level_api = {}
--Localized since only used in init.lua
local function save_data(data)
    storage:set_string("lvl", minetest.serialize(data))
end

--localize for performance
local chat_send_player = minetest.chat_send_player

function level_api.get_data()
    local data = storage:get_string("lvl")
    if data ~= "" then
        data = minetest.deserialize(data)
    else
        data = {}
    end
    return data
end
--localize the data on startup for performance
local data = level_api.get_data()
  
function level_api.get_next_level(level, xp, totxp)
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
--localize for performance
local get_next_level = level_api.get_next_level

function level_api.add_xp(player_name, new_xp)
    --local data = get_data()
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
--localize for performance
local add_xp = level_api.add_xp

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    --local data = get_data()

    if not data[player_name] then
        data[player_name] = {level = 1, xp = 0, totxp = 0}
        save_data(data)
    end
end)

minetest.register_chatcommand("level", {
    description = "Zeige dein Level und XP an.",
    privs = {},
    func = function(name, param)
        --local data = get_data()
        local player_data = data[name]

        if player_data then
            local level = player_data.level
            local xp = player_data.xp
            chat_send_player(name, "Level: " .. level .. ", XP: " .. xp)
        end
    end
})

minetest.register_chatcommand("reset_level", {
    description = "Resete ein Level eines Spielers",
    privs = {server},
    params = "[player_name]",
    func = function(name, param)
        local target_player = param or name
        local target_player = minetest.get_player_by_name(target_player)
         
        if target_player then
            --local data = get_data()

            data[name] = {level = 1, xp = 0, totxp = 100}
            save_data(data)
    
            chat_send_player(name, "Dein Level wurde auf "..data[name].level.." und deine XP auf "..data[name].xp.." gesetzt.")
        else
            chat_send_player(name, "Player nicht gefunden.")
        end
    end
})

minetest.register_chatcommand("addxp", {
    description = "Füge XP hinzu",
    privs = {server},
    params = "<xp> [player_name]",
    func = function(name, param)
        local args = param:split(" ")
        local xp = tonumber(args[1])
        local target_player_name = args[2] or name

        if not xp then
            chat_send_player(name, "Gib die XP-Menge an.")
            return false
        end

        local target_player = minetest.get_player_by_name(target_player_name)
        if target_player then
            add_xp(target_player_name, xp)
            chat_send_player(player_name, "Dem Spieler " .. target_player_name .. " wurden " .. xp .. " XP hinzugefügt.")
            return true
        else
            chat_send_player(player_name, "Spieler " .. target_player_name .. " nicht gefunden.")
            return false
        end
    end 
})
