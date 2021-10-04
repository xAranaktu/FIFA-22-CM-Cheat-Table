--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

--- This script can add/update headmodels
--- You need to edit "headmodels_map", "headvariations_map" by yourself, pattern is simple:
--- [playerid] = headassetid,

local headmodels_map = {
    -- [210406] = 41,   -- Example, replace Zielinski face with Iniesta (https://i.imgur.com/CS5Y7Wg.png)
}

local headvariations_map ={
    -- [210406] = 0,   -- Example, set variation on 0 for Zielinski
}

-- Don't touch anything below
gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

local first_record = game_db_manager.tables["players"]["first_record"]
local record_size = game_db_manager.tables["players"]["record_size"]
local written_records = game_db_manager.tables["players"]["written_records"]

local row = 0
local current_addr = first_record
local last_byte = 0
local is_record_valid = true
local updated_players = 0

while true do
    if row >= written_records then
        break
    end
    current_addr = first_record + (record_size*row)
    last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
    is_record_valid = not (bAnd(last_byte, 128) > 0)
    if is_record_valid then
        local playerid = game_db_manager:get_table_record_field_value(current_addr, "players", "playerid")
        local headassetid = headmodels_map[playerid]
        if playerid > 0 and headassetid then
            game_db_manager:set_table_record_field_value(current_addr, "players", "hashighqualityhead", 1)
            game_db_manager:set_table_record_field_value(current_addr, "players", "headclasscode", 0)
            game_db_manager:set_table_record_field_value(current_addr, "players", "headassetid", headassetid)

            local variation = headvariations_map[playerid]
            if variation then
                game_db_manager:set_table_record_field_value(current_addr, "players", "headvariation", variation)
            end

            updated_players = updated_players + 1
        end
    end
    row = row + 1
end

showMessage(string.format("Done\nUpdated head models: %d", updated_players))