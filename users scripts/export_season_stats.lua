--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

-- This script will export current season stats (goals scored, assists etc.) to CSV.
-- The SEASON_STATS.csv file will be created in the same directory where you have the Cheat Table
-- The game resets stats at the beginning of every season, so you need to run the script at the end of every season.



-- Don't touch anything below

-- Functions 
function get_player_position(addr)
    local game_db_manager = gCTManager.game_db_manager
    
    local pos_id = -1
    if addr then
        pos_id = game_db_manager:get_table_record_field_value(addr, "players", "preferredposition1")
    end
    
    return get_pos_name(pos_id)
end

function get_player_club_teamname(pid)
    local game_db_manager = gCTManager.game_db_manager
    local result = "UNKNOWN"
    local addr = get_player_clubteamrecord(pid)
    
    if addr == 0 then return result end
    local teamname = game_db_manager:get_table_record_field_value(addr, "teams", "teamname") or ""
    local teamid = game_db_manager:get_table_record_field_value(addr, "teams", "teamid") or 0

    result = string.format("%s (ID: %d)", teamname, teamid)
    
    return result
end

-- STUFF

gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

-- IFCEInterface
local impl = get_mode_manager_impl_ptr("IFCEInterface")
-- print(string.format("impl: 0x%X", impl))

if impl == 0 then 
    showMessage("Can't find IFCEInterface. Not in career mode?")
    return
end

local _start = gCTManager.memory_manager:read_multilevel_pointer(
    impl,
    {IFCEInterface_STRUCT['FCEData'], IFCEInterface_STRUCT['FCEData_lists'], IFCEInterface_STRUCT['PlayersStats_off'], IFCEInterface_STRUCT['PlayersStats_begin']}
)

if _start == 0 then
    showMessage("Can't find begin of players stats array")
    return
end

-- Player Names
game_db_manager:cache_player_names()

-- Current DATE
local int_current_date = game_db_manager:get_table_record_field_value(
    readPointer("pCareerCalendarTableCurrentRecord"), "career_calendar", "currdate"
)

local current_date = {
    day = 1,
    month = 7,
    year = 2021
}

if int_current_date > 20080101 then
    local s_currentdate = tostring(int_current_date)
    current_date = {
        day = tonumber(string.sub(s_currentdate, 7, 8)),
        month = tonumber(string.sub(s_currentdate, 5, 6)),
        year = tonumber(string.sub(s_currentdate, 1, 4)),
    }
end

-- 
local playerid_addr_map = get_players_addrs()

-- File
local filename = string.format("SEASON_STATS_%d_%d_%d.csv", current_date.day, current_date.month, current_date.year)
local file = io.open(filename, "w+")
io.output(file)

local columns = {
    "position",
    "playerid",
    "playername",
    --"team",
    "competition",
    "appearances",
    "AVG",
    "MOTMs",
    "goals",
    "assists",
    "yellow_cards",
    "two_yellow",
    "red_cards",
    "saves",
    "goals_conceded",
    "cleansheets",
}

local col_to_key = {
    position = "position",
    playerid = "playerid",
    playername = "playername",
    --team = "teamname",
    competition = "compname",
    appearances = "app",
    AVG = "avg",
    MOTMs = "motm",
    goals = "goals",
    assists = "assists",
    yellow_cards = "yellow",
    two_yellow = "two_yellow",
    red_cards = "red",
    saves = "saves",
    goals_conceded = "goals_conceded",
    cleansheets = "clean_sheets",
}

-- Columns
io.write(table.concat(columns, ","))
io.write("\n")
local players = {}

local limit = IFCEInterface_STRUCT['PlayersStats_n']
local size_of =  FCEData_PlayerStats_STRUCT['size']
local current_addr = _start
--print(string.format("First: 0x%X", current_addr))
for i=0, limit, 1 do
    local is_in_use = readBytes(current_addr + FCEData_PlayerStats_STRUCT['is_in_use'], 1, true)[1]
    
    if is_in_use > 0 then

        local pid = readInteger(current_addr + FCEData_PlayerStats_STRUCT['playerid'])
        
        -- Ignore if PlayeID == 0
        -- Ignore if PlayeID == 4294967295 (-1)
        if pid > 0 and pid < 4294967295 then
            local app = readBytes(current_addr + FCEData_PlayerStats_STRUCT['app'], 1, true)[1]
            
            if app > 0 then
                local player = players[pid] or {}
                local stats = player.stats or {}
                
                if player.name == nil then
                    player.name = get_player_fullname(pid)
                    player.position = get_player_position(playerid_addr_map[pid])
                    --player.teamname = get_player_club_teamname(pid)
                end
                

                local compobjid = readSmallInteger(current_addr + FCEData_PlayerStats_STRUCT['compobjid'])
                stats[compobjid] = {}

                stats[compobjid]["playerid"] = pid
                stats[compobjid]["playername"] = player.name
                stats[compobjid]["position"] = player.position
                --player[compobjid]["teamname"] = player.teamname
                
                stats[compobjid]["goals"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['goals'], 1, true)[1]
                stats[compobjid]["yellow"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['yellow'], 1, true)[1] >> 2
                stats[compobjid]["red"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['red'], 1, true)[1] >> 2
                stats[compobjid]["assists"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['assists'], 1, true)[1]
                stats[compobjid]["clean_sheets"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['clean_sheets'], 1, true)[1]
                stats[compobjid]["compobjid"] = compobjid
                stats[compobjid]["compname"] = get_comp_name_from_objid(compobjid)
                
                -- Not sure
                stats[compobjid]["motm"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['motm'], 1, true)[1]
                stats[compobjid]["saves"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['saves'], 1, true)[1]
                stats[compobjid]["goals_conceded"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['goals_conceded'], 1, true)[1]
                stats[compobjid]["two_yellow"] = readBytes(current_addr + FCEData_PlayerStats_STRUCT['two_yellow'], 1, true)[1]


                local avg = readSmallInteger(current_addr + FCEData_PlayerStats_STRUCT['avg'])
                if app > 1 then 
                    avg = (avg / app) / 10 
                elseif app == 1 then
                    avg = avg / 10
                end
                
                stats[compobjid]["app"] = app
                stats[compobjid]["avg"] = string.format("%0.2f", avg)
                
                player.stats = stats
                players[pid] = player
            end
        end
    end
    current_addr = current_addr + size_of
end

for playerid, data in pairs(players) do
    for compobjid, stat in pairs(data.stats) do
        local row = {}
        for i=1, #columns do
            local colname = columns[i]
            local _key = col_to_key[colname]
            table.insert(row, stat[_key])
        end
        io.write(table.concat(row, ","))
        io.write("\n")
    end

end
io.close(file)

showMessage("Done")