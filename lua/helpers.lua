function onScriptActivate()
    -- Check if user has set up CT correctly
    -- local status, error = pcall(gCTManager:memory_manager:get_validated_address)
    -- if not status then
    --     showMessage('Error during script activation, error:\n' .. error)
    --     print("Read guide to avoid problems like this: https://github.com/xAranaktu/FIFA-22-CM-Cheat-Table/wiki/Getting-Started")
    --     assert(false, error)
    -- end
end

function is_cm_loaded()
    local modules = enumModules()
    for _, module in ipairs(modules) do
        if module.Name == 'FootballCompEng_Win64_retail.dll' then
            -- We are in career mode
            return true
        end
    end

    -- We are outside career mode
    return false
end

function get_comp_name_from_objid(_id)
    local result = string.format("Unknown_%d", _id)

    local cid = COMP_OBJID_CID[_id]
    if cid == nil then return result end

    local result = COMP_NAMES[cid] or result
    return result
end

function get_player_name(playerid)
    if type(playerid) ~= "number" then
        playerid = tonumber(playerid)
    end
    local playername = ""

    if not playerid then return playername end

    local cached_player_names = gCTManager.game_db_manager:get_cached_player_names()
    local pname = cached_player_names[playerid]
    if pname then
        playername = pname["knownas"] or ""
    end

    return playername
end

function get_player_fullname(playerid)
    if type(playerid) ~= "number" then
        playerid = tonumber(playerid)
    end
    local playername = ""

    if not playerid then return playername end

    local cached_player_names = gCTManager.game_db_manager:get_cached_player_names()
    local pname = cached_player_names[playerid]
    if pname then
        playername = pname["alt_fullname"] or ""
    end

    return playername
end

function get_user_clubteamid()
    if not is_cm_loaded() then return 0 end
    local game_db_manager = gCTManager.game_db_manager

    local addr = readPointer("pUsersTableFirstRecord")
    if not addr or addr == 0 then return 0 end

    local clubteamid = game_db_manager:get_table_record_field_value(addr, "career_users", "clubteamid")
    return clubteamid
end

function get_pos_name(posid)
    return POS_TO_NAME[posid] or "INVALID"
end

function get_player_clubteamrecord(playerid)
    local game_db_manager = gCTManager.game_db_manager
    if type(playerid) == 'string' then
        playerid = tonumber(playerid)
    end

    -- - 78, International
    -- - 2136, International Women
    -- - 76, Rest of World
    -- - 383, Create Player League
    local invalid_leagues = {
        76, 78, 2136, 383
    }

    local arr_flds = {
        {
            name = "playerid",
            expr = "eq",
            values = {playerid}
        }
    }

    local addr = game_db_manager:find_record_addr(
        "teamplayerlinks", arr_flds
    )

    if #addr <= 0 then
        --self.logger:warning(string.format("No teams for playerid: %d", playerid))
        return 0
    end

    local fnIsLeagueValid = function(invalid_leagues, leagueid)
        for j=1, #invalid_leagues do
            local invalid_leagueid = invalid_leagues[j]
            if invalid_leagueid == leagueid then return false end
        end
        return true
    end

    for i=1, #addr do
        local found_addr = addr[i]
        local teamid = game_db_manager:get_table_record_field_value(found_addr, "teamplayerlinks", "teamid")
        local arr_flds_2 = {
            {
                name = "teamid",
                expr = "eq",
                values = {teamid}
            }
        }
        local found_addr2 = game_db_manager:find_record_addr(
            "leagueteamlinks", arr_flds_2, 1
        )[1]
        local leagueid = game_db_manager:get_table_record_field_value(found_addr2, "leagueteamlinks", "leagueid")
        if fnIsLeagueValid(invalid_leagues, leagueid) then
            --self.logger:debug(string.format("found: %X, teamid: %d, leagueid: %d", found_addr, teamid, leagueid))
            writeQword("pTeamplayerlinksTableCurrentRecord", found_addr)
            return found_addr
        end 
    end

    --self.logger:warning(string.format("No club teams for playerid: %d", playerid))
    return 0
end

function get_players_addrs()
    local result = {}

    local game_db_manager = gCTManager.game_db_manager
    local memory_manager = gCTManager.memory_manager

    local first_record = game_db_manager.tables["players"]["first_record"]
    local record_size = game_db_manager.tables["players"]["record_size"]
    local written_records = game_db_manager.tables["players"]["written_records"]

    local row = 0
    local current_addr = first_record
    local last_byte = 0
    local is_record_valid = true

    while true do
        if row >= written_records then
            break
        end
        current_addr = first_record + (record_size*row)
        last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
        is_record_valid = not (bAnd(last_byte, 128) > 0)
        if is_record_valid then
            local playerid = game_db_manager:get_table_record_field_value(current_addr, "players", "playerid")

            result[playerid] = current_addr
        end
        row = row + 1
    end

    return result
end

function get_playerids_for_team(tid)
    local result = {}
    if tid <= 0 then return result end

    local game_db_manager = gCTManager.game_db_manager
    local memory_manager = gCTManager.memory_manager

    local first_record = game_db_manager.tables["teamplayerlinks"]["first_record"]
    local record_size = game_db_manager.tables["teamplayerlinks"]["record_size"]
    local written_records = game_db_manager.tables["teamplayerlinks"]["written_records"]

    local row = 0
    local current_addr = first_record
    local last_byte = 0
    local is_record_valid = true

    while true do
        if row >= written_records then
            break
        end
        current_addr = first_record + (record_size*row)
        last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
        is_record_valid = not (bAnd(last_byte, 128) > 0)
        if is_record_valid then
            local artificialkey = game_db_manager:get_table_record_field_value(current_addr, "teamplayerlinks", "artificialkey")
            if artificialkey > 0 then
                local rec_teamid = game_db_manager:get_table_record_field_value(current_addr, "teamplayerlinks", "teamid")
                if rec_teamid == tid then
                    local playerid = game_db_manager:get_table_record_field_value(current_addr, "teamplayerlinks", "playerid")
                    table.insert(result, playerid)
                end
            end
        end
        row = row + 1
    end

    return result
end

function get_user_team_playerids()
    return get_playerids_for_team(get_user_clubteamid())
end

function can_edit_player(pids, pid)
    for i=1, #pids do
        if pid == pids[i] then return true end
    end
    return false
end

function get_mode_manager_impl_ptr(manager_name)
    local result = 0

    if not is_cm_loaded() then
        return result
    end

    --print(string.format("get_mode_manager_impl_ptr: %s ", manager_name))
    local offset = MODE_MANAGERS_OFFSETS[manager_name]
    local result = gCTManager.memory_manager:read_multilevel_pointer(
        readPointer("pModeManagers"),
        {0x0, offset, 0x0}
    )

    --print(string.format("result 0x%X", result))
    return result
end

-- ScoutManager Start
function ya_reveal_data()
    local mgr = get_mode_manager_impl_ptr("YouthPlayerUtil")
    if not mgr or mgr == 0 then return end
    --print(string.format("%X", mgr))
    local ya_settings = readPointer(mgr + YOUTHPLAYERUTIL_STRUCT["settings_offset"])
    local current_addr = ya_settings + YOUTHPLAYERUTIL_STRUCT["pot_var_off"]
    --print(string.format("%X", current_addr))

    local _max = YOUTHPLAYERUTIL_STRUCT["variance_n"] * 2

    -- Max Display ovr/pot = 99
    writeInteger(ya_settings + YOUTHPLAYERUTIL_STRUCT["max_display_val_offset"], 99)

    for i=1, _max do
        writeInteger(current_addr, 0)
        current_addr = current_addr + 4
    end
end

function ya_free_missions()
    local mgr = get_mode_manager_impl_ptr("ScoutManager")
    if not mgr or mgr == 0 then return end

    local _max = 3
    local current_addr = mgr + SCOUTMANAGER_STRUCT["base_mission_cost_off"]

    for i=1, _max do
        writeInteger(current_addr, 0)
        current_addr = current_addr + 4
    end

end

function ya_max_per_report()
    local mgr = get_mode_manager_impl_ptr("ScoutManager")
    if not mgr or mgr == 0 then return end

    local _max = SCOUTMANAGER_STRUCT["max_exp"] * SCOUTMANAGER_STRUCT["ranges_num"]
    local current_addr = mgr + SCOUTMANAGER_STRUCT["players_per_report_off"]
    local max_per_report = 15

    for i=1, _max do
        writeInteger(current_addr, max_per_report)
        current_addr = current_addr + 4
    end

end

-- ScoutManager End

-- PlayerStatusManager Startt

function get_squad_role_addr(playerid)
    local stattusmgr_ptr = get_mode_manager_impl_ptr("PlayerStatusManager")
    local _start = readPointer(stattusmgr_ptr + PLAYERROLE_STRUCT['_start'])
    local _end = readPointer(stattusmgr_ptr + PLAYERROLE_STRUCT['_end'])
    if (not _start) or (not _end) then
        return 0
    end

        --self.logger:debug(string.format("Player Role _start: %X", _start))
    --self.logger:debug(string.format("Player Role _end: %X", _end))
    local _max = 55
    local current_addr = _start
    local player_found = false
    for i=1, _max do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        --self.logger:debug(string.format("Player Role current_addr: %X", current_addr))
        local pid = readInteger(current_addr + PLAYERROLE_STRUCT["pid"])
        --local role = readInteger(current_addr + PLAYERROLE_STRUCT["role"])
        --self.logger:debug(string.format("Player Role PID: %d, Role: %d", pid, role))
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERROLE_STRUCT["size"]
    end
    if not player_found then
        return 0
    end
    return current_addr
end

-- PlayerStatusManager End

-- PlayerContractManager Start
function get_player_release_clause_addr(playerid)
    local rlc_ptr = get_mode_manager_impl_ptr("PlayerContractManager")
    local _start = readPointer(rlc_ptr + PLAYERRLC_STRUCT['_start'])
    local _end = readPointer(rlc_ptr + PLAYERRLC_STRUCT['_end'])
    if (not _start) or (not _end) then
        return -1
    end

    local current_addr = _start
    local player_found = false
    local _max = 26001
    for i=1, _max do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        local pid = readInteger(current_addr + PLAYERRLC_STRUCT['pid'])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERRLC_STRUCT['size']
    end
    if not player_found then
        return 0
    end
    return current_addr

end
-- PlayerContractManager End

-- FitnessManager Start
function _print_user_team_stamina_addresses()
    local playerids = get_user_team_playerids()
    for i=1, #playerids do
        local playerid = playerids[i]
        local current_addr = get_player_fitness_addr(playerid)

        if current_addr > 0 then
            print(string.format("%d - 0x%X", playerid, current_addr))
        end

    end
end

function heal_all_in_player_team()
    local playerids = get_user_team_playerids()
    for i=1, #playerids do
        local playerid = playerids[i]
        local current_addr = get_player_fitness_addr(playerid)
        
        if current_addr == 0 then
            current_addr = get_player_fitness_addr(4294967295)
        end
        
        if current_addr > 0 then
            writeInteger(current_addr + PLAYERFITESS_STRUCT["pid"], playerid)
            writeInteger(current_addr + PLAYERFITESS_STRUCT["tid"], 4294967295)
            writeInteger(current_addr + PLAYERFITESS_STRUCT["full_fit_date"], 20080101)
            writeInteger(current_addr + PLAYERFITESS_STRUCT["partial_fit_date"], 20080101)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["days_since_game"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["fitness"], 100)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["is_injured"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["inj_part"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["inj_type"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["recovery_stage"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["in_use"], 1)
        end

    end
end

function refill_stamina_in_player_team()
    local playerids = get_user_team_playerids()
    for i=1, #playerids do
        local playerid = playerids[i]
        local current_addr = get_player_fitness_addr(playerid)
        -- print(string.format("%d - 0x%X", playerid, current_addr))
        if current_addr > 0 then
            -- writeBytes(current_addr + PLAYERFITESS_STRUCT["fitness"], 100)
        end
    end
end

function get_player_fitness_addr(playerid)
    local fitness_ptr = get_mode_manager_impl_ptr("FitnessManager")
    local _start = readPointer(fitness_ptr + PLAYERFITESS_STRUCT['fitness_start_offset'])
    local _end = readPointer(fitness_ptr + PLAYERFITESS_STRUCT['fitness_end_offset'])

    -- print(string.format("fitness_ptr 0x%X 0x%X - 0x%X", fitness_ptr, _start, _end))

    if (not _start) or (not _end) then
        return -1
    end
    
    local current_addr = _start
    local player_found = false
    local _max = 2000
    for i=1, _max do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        --self.logger:debug(string.format("Player Fitness current_addr: %X", current_addr))
        local pid = readInteger(current_addr + PLAYERFITESS_STRUCT["pid"])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERFITESS_STRUCT["size"]
    end
    if not player_found then
        return 0
    end
    -- self.logger:debug(string.format("Player Fitness found at: %X", current_addr))
    return current_addr
end


function set_all_players_sharpness(new_val)
    local fitness_ptr = get_mode_manager_impl_ptr("FitnessManager")
    local current = readPointer(fitness_ptr + PLAYERFITESS_STRUCT["sharpness_start_offset"])
    set_players_sharpness(current, new_val)
end

function get_player_sharpness_addr(current_addr, playerid)
    -- print(string.format("current_addr 0x%X", current_addr))
    if current_addr == 0 then return 0 end

    local pid = readInteger(current_addr + PLAYERFITESS_STRUCT['sharpness_pid'])
    if pid == playerid then
        return current_addr
    elseif pid > playerid then
        return get_player_sharpness_addr(readPointer(current_addr + PLAYERFITESS_STRUCT['sharpness_prev']), playerid)
    else
        return get_player_sharpness_addr(readPointer(current_addr + PLAYERFITESS_STRUCT['sharpness_next']), playerid)
    end
end

function set_player_sharpness(current_addr, new_val)
    writeBytes(current_addr + PLAYERFITESS_STRUCT["sharpness_value"], new_val)
end

function set_players_sharpness(current_addr, new_val)
    if current_addr == 0 then return end
    -- local pid = readInteger(current + PLAYERFITESS_STRUCT['sharpness_pid'])

    set_player_sharpness(current_addr, new_val)
    local _next = readPointer(current_addr + PLAYERFITESS_STRUCT['sharpness_next'])
    local _prev = readPointer(current_addr + PLAYERFITESS_STRUCT['sharpness_prev'])

    set_players_sharpness(_next, new_val)
    set_players_sharpness(_prev, new_val)
end

function set_sharpness_for_pid(playerid, new_val)
    local fitness_ptr = get_mode_manager_impl_ptr("FitnessManager")
    local current = readPointer(fitness_ptr + PLAYERFITESS_STRUCT["sharpness_start_offset"])
    local player_addr = get_player_sharpness_addr(current, playerid)
    -- print(string.format("player_addr 0x%X", player_addr))
    set_player_sharpness(player_addr, new_val)
end
-- FitnessManager End

-- PlayerMoraleManager Start
function get_player_morale_addr(playerid)
    local size_of =  PLAYERMORALE_STRUCT['size']
    local morale_ptr = get_mode_manager_impl_ptr("PlayerMoraleManager")
    
    local _start = readPointer(morale_ptr + PLAYERMORALE_STRUCT['_start'])
    local _end = readPointer(morale_ptr + PLAYERMORALE_STRUCT['_end'])
    if (not _start) or (not _end) then
        return 0
    end

    local squad_size = ((_end - _start) // size_of) + 1
    local current_addr = _start
    local player_found = false
    for i=0, squad_size, 1 do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        local pid = readInteger(current_addr + PLAYERMORALE_STRUCT['pid'])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERMORALE_STRUCT['size']
    end
    if not player_found then
        return 0
    end

    return current_addr
end


function set_players_morale(morale)
    local size_of =  PLAYERMORALE_STRUCT['size']
    local morale_ptr = get_mode_manager_impl_ptr("PlayerMoraleManager")
    
    local _start = readPointer(morale_ptr + PLAYERMORALE_STRUCT['_start'])
    local _end = readPointer(morale_ptr + PLAYERMORALE_STRUCT['_end'])
    if (not _start) or (not _end) then
        return nil
    end
    
    local squad_size = ((_end - _start) // size_of) + 1
    local morale = PLAYERMORALE_STRUCT["values_array"][morale]
    morale_ptr = _start
    for i=0, squad_size, 1 do
        local pid = readInteger(morale_ptr + PLAYERMORALE_STRUCT['pid'])
        if morale_ptr == _end then
            break
        end
    
        writeInteger(morale_ptr+PLAYERMORALE_STRUCT['morale_val'], morale)
        writeInteger(morale_ptr+PLAYERMORALE_STRUCT['contract'], morale)
        writeInteger(morale_ptr+PLAYERMORALE_STRUCT['playtime'], morale)
    
        morale_ptr = morale_ptr + size_of
    end
end
-- PlayerMoraleManager End

-- PlayerFormManager Start

function get_player_form_addr(playerid)
    local result = 0

    local size_of =  PLAYERFORM_STRUCT['size']
    local form_ptr = get_mode_manager_impl_ptr("PlayerFormManager")
    if not form_ptr then
        return result
    end

    form_ptr = readPointer(form_ptr + PLAYERFORM_STRUCT['players_form_list_offset'])

    local _start = readPointer(form_ptr + PLAYERFORM_STRUCT['_start'])
    local _end = readPointer(form_ptr + PLAYERFORM_STRUCT['_end'])

    if (not _start) or (not _end) then
        return result
    end

    local squad_size = ((_end - _start) // size_of) + 1
    local current_addr = _start
    local player_found = false
    for i=0, squad_size, 1 do
        if current_addr == _end then
            break
        end

        local pid = readInteger(current_addr + PLAYERFORM_STRUCT['pid'])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + size_of
    end
    if not player_found then
        -- self.logger:debug("player form not found")
        return 0
    end
    return current_addr
end

function set_players_form(frm)
    local size_of =  PLAYERFORM_STRUCT['size']
    local form_ptr = get_mode_manager_impl_ptr("PlayerFormManager")
    if not form_ptr then
        return
    end

    form_ptr = readPointer(form_ptr + PLAYERFORM_STRUCT['players_form_list_offset'])

    local _start = readPointer(form_ptr + PLAYERFORM_STRUCT['_start'])
    local _end = readPointer(form_ptr + PLAYERFORM_STRUCT['_end'])

    if (not _start) or (not _end) then
        return
    end
    local form_val = PLAYERFORM_STRUCT["values_array"][frm]

    local squad_size = ((_end - _start) // size_of) + 1
    local current_addr = _start

    for i=0, squad_size, 1 do
        local pid = readInteger(current_addr + PLAYERFORM_STRUCT['pid'])
        if current_addr == _end then
            break
        end
        -- -- print(string.format("PlayerID: %d, %X", pid, current_addr))
        writeInteger(current_addr+PLAYERFORM_STRUCT['form'], frm)
        for j=0, 9 do
            local off = PLAYERFORM_STRUCT['last_games_avg_1'] + (j * 4)
            writeInteger(current_addr+off, form_val)
        end
        writeInteger(current_addr+PLAYERFORM_STRUCT['recent_avg'], form_val)

        current_addr = current_addr + size_of
    end
end
-- PlayerFormManager End

-- PlayerGrowthManager Start

function get_players_in_player_growth_system()
    local result = {}
    local _max = 55

    local pgs_ptr = get_mode_manager_impl_ptr("PlayerGrowthManager")
    if not pgs_ptr then
        return result
    end

    local _start = readPointer(pgs_ptr + PLAYERGROWTHSYSTEM_STRUCT["_start"])
    local _end = readPointer(pgs_ptr + PLAYERGROWTHSYSTEM_STRUCT["_end"])
    if (not _start) or (not _end) then
        return result
    end

    local current_addr = _start
    for i=1, _max do
        if current_addr >= _end then
            return result
        end
        local pid = readInteger(current_addr + PLAYERGROWTHSYSTEM_STRUCT["pid"])
        result[pid] = current_addr
        current_addr = current_addr + PLAYERGROWTHSYSTEM_STRUCT["size"]
    end
    return result
end

function get_field_offset_in_player_growth_system(field_name)
    local fields_ordered_array = PlayerGrowthManager_Data["fields_ordered_array"]
    for i=1, #fields_ordered_array do
        if field_name == fields_ordered_array[i] then
            return i * 4
        end
    end

    return 0
end

function get_xp_to_apply_in_player_growth_system(field_name, new_value)
    -- Make sure new value is valid
    if new_value < 1 then
        new_value = 1
    else
        if field_name == "attackingworkrate" or field_name == "defensiveworkrate" then
            if new_value > 3 then
                new_value = 3
            end
        elseif field_name == "weakfootabilitytypecode" or field_name == "skillmoves" then
            if new_value > 5 then
                new_value = 5
            end
        elseif new_value > 99 then
            new_value = 99
        end
    end

    local xp_points_to_apply = 1000
    if field_name == "attackingworkrate" or field_name == "defensiveworkrate" then
        xp_points_to_apply = PlayerGrowthManager_Data["xp_to_wr"][new_value]
    elseif field_name == "weakfootabilitytypecode" or field_name == "skillmoves" then
        xp_points_to_apply = PlayerGrowthManager_Data["xp_to_star"][new_value]
    else
        xp_points_to_apply = PlayerGrowthManager_Data["xp_to_attribute"][new_value]
    end

    return xp_points_to_apply
end

-- PlayerGrowthManager End

function value_to_date(value)
    -- Convert value from the game to human readable form (format: DD/MM/YYYY)
    -- ex. 20180908 -> 08/09/2018
    local to_string = string.format('%d', value)
    return string.format(
        '%s/%s/%s',
        string.sub(to_string, 7),
        string.sub(to_string, 5, 6),
        string.sub(to_string, 1, 4)
    )
end

function date_to_value(d)
    local m_date, _ = string.gsub(d, '%D', '')
    if string.len(m_date) ~= 8 then
        m_date = "01/01/2008"
    end
    m_date = string.format(
        '%s%s%s',
        string.sub(m_date, 5),
        string.sub(m_date, 3, 4),
        string.sub(m_date, 1, 2)
    )
    return tonumber(m_date)
end

function encodeURI(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
            function (c) return string.format ("%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
   end
   return str
end

function math.round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

function days_to_date(days)
    local result = {
        day = 0,
        month = 0,
        year = 0
    }

    local a, b, c, d, e, m
    a = days + 2331205
    b = math.floor((4*a+3)/146097)
    c = math.floor((-b * 146097 / 4) + a)
    d = math.floor((4 * c + 3)/1461)
    e = math.floor(-1461 * d / 4 + c)
    m = math.floor((5*e+2)/153)
    
    result["day"] = math.ceil(-(153 * m + 2) / 5) + e + 1
    result["month"] = math.ceil(-m / 10) * 12 + m + 3
    result["year"] = b * 100 + d - 4800 + math.floor(m / 10)

    return result
end

function date_to_days(date)
    local a = math.floor((14 - date["month"]) / 12)
    local m = date["month"] + 12 * a - 3;
    local y = date["year"] + 4800 - a;
    return date["day"] + math.floor((153 * m + 2) / 5) + y * 365 + math.floor(y/4) - math.floor(y/100) + math.floor(y/400) - 2331205;
end

function getProcessNameFromProcessID(iProcessID)
    if iProcessID < 1 then return 0 end
    local plist = createStringlist()
    getProcesslist(plist)
    for i=1, strings_getCount(plist)-1 do
        local process = strings_getString(plist, i)
        local offset = string.find(process,'-')
        local pid = tonumber('0x'..string.sub(process,1,offset-1))
        local pname = string.sub(process,offset+1)
        if pid == iProcessID then return pname end
    end
    return 0
end

function calculate_age(current_date, birthdate)
    local age = current_date["year"] - birthdate["year"]

    if (current_date["month"] < birthdate["month"] or (current_date["month"] == birthdate["month"] and current_date["day"] < birthdate["day"] )) then
        age = age - 1
    end
    return age
end
  
function getOpenedProcessName()
    local process = getOpenedProcessID()
    if process ~= 0 and getProcessIDFromProcessName(nil) == getOpenedProcessID() then
        if checkOpenedProcess(nil) == true then return nil end
        return nil
    end
    return getProcessNameFromProcessID(process)
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function getfield (f)
    if DEBUG_MODE then
        print("getfield - f: " .. f)
    end
    local v = _G    -- start with the table of globals
    for w in string.gmatch(f, "[%w_]+") do
        if v == nil then
            print(string.format("No globals... field: %s", f), "ERROR")
            assert(false)
        end
        v = v[w]
    end
    return v
end

function setfield (f, v)
    if DEBUG_MODE then
        print("setfield - f: " .. f .. " v: " .. v)
    end
    local t = _G    -- start with the table of globals
    for w, d in string.gmatch(f, "([%w_]+)(.?)") do
        if d == "." then      -- not last field?
        
        t[w] = t[w] or {}   -- create table if absent
        t = t[w]            -- get the table

        if (type(t) == "string") then return end
        else                  -- last field
            t[w] = v            -- do the assignment
        end
    end
end

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function toBits(num)
    local t={} -- will contain the bits
    local bits=32
    for b=bits,1,-1 do
        rest=math.floor((math.fmod(num,2)))
        t[b]=rest
        num=(num-rest)/2
    end
    return string.reverse(table.concat(t))
end

function _validated_color(comp)
    local saved_onChange = comp.OnChange
    comp.OnChange = nil

    local icolor_value = tonumber(comp.Text)
    if icolor_value == nil then
        comp.Text = 255
    elseif icolor_value > 255 then
        comp.Text = 255
    elseif icolor_value < 0 then
        comp.Text = 0
    end

    comp.OnChange = saved_onChange
    return tonumber(comp.Text)
end

function deactive_all(record)
    for i=0, record.Count-1 do
        if record[i].Active then record[i].Active = false end
        if record.Child[i].Count > 0 then
            deactive_all(record.Child[i])
        end
    end
end
