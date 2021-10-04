--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

-- This script will change:
-- Age of all players
-- By default it will make all players 16 yo

-- All players will be 16 you
-- Feel free to change 16 to any other number you want.
local new_age = 16

-- Don't touch anything below

gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

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
        if playerid > 0 then
            local playerbirthdate = game_db_manager:get_table_record_field_value(current_addr, "players", "birthdate")
            
            local bdate = days_to_date(playerbirthdate)
            
            local player_current_age = calculate_age(current_date, bdate)

            if player_current_age ~= new_age then
                playerbirthdate = playerbirthdate + ((player_current_age - new_age) * 366)
                game_db_manager:set_table_record_field_value(current_addr, "players", "birthdate", playerbirthdate)
            end

        end
    end
    row = row + 1
end

showMessage("Done")
