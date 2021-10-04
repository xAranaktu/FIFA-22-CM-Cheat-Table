--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

--- Set headmodel to generic for given playerids

local to_generic = {
  -- 231443,
  -- 158023
}

-- Don't touch anything below

function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
end

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
        local headassetid = game_db_manager:get_table_record_field_value(current_addr, "players", "headassetid")
        if playerid > 0 and headassetid == playerid and inTable(to_generic, playerid) then
            game_db_manager:set_table_record_field_value(current_addr, "players", "hashighqualityhead", 0)
            game_db_manager:set_table_record_field_value(current_addr, "players", "headclasscode", 1)
            game_db_manager:set_table_record_field_value(current_addr, "players", "headassetid", playerid)

            updated_players = updated_players + 1
        end
    end
    row = row + 1
end

showMessage(string.format("Done\nUpdated head models: %d", updated_players))