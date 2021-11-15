--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

-- This script will automatically extend the contracts of players in your team
-- 5 years by default


local new_contract_length = 12 * 5 -- 5 years

-- Don't touch anything below

gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

function update_contractvaliduntil(contracts)
    local contracts_to_update = 0
    local updated_contracts = 0

    for playerid, contractvaliduntil in pairs(contracts) do
        contracts_to_update = contracts_to_update + 1
    end
    
    local first_record = game_db_manager.tables["players"]["first_record"]
    local record_size = game_db_manager.tables["players"]["record_size"]
    local written_records = game_db_manager.tables["players"]["written_records"]

    local row = 0
    local current_addr = first_record
    local last_byte = 0
    local is_record_valid = true

    local new_value = 1
    while true do
        if row >= written_records then
            break
        end
        
        if updated_contracts >= contracts_to_update then
            break
        end
        
        current_addr = first_record + (record_size*row)
        last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
        is_record_valid = not (bAnd(last_byte, 128) > 0)
        if is_record_valid then
            local playerid = game_db_manager:get_table_record_field_value(current_addr, "players", "playerid")
            if playerid > 0 then
                local contractvaliduntil = contracts[playerid]
                if contractvaliduntil ~= nil then
                    game_db_manager:set_table_record_field_value(current_addr, "players", "contractvaliduntil", contractvaliduntil)
                    updated_contracts = updated_contracts + 1
                end
            end
        end
        row = row + 1
    end
    
    local failed_to_update = contracts_to_update - updated_contracts
    
    if failed_to_update > 0 then
        print(string.format("Failed to update %d contracts", failed_to_update))
    end
    
    print(string.format("Updated Contracts: %d", updated_contracts))
end

function update_contracts()
    -- use to update "contractvaliduntil" in players table
    local result = {}

    -- Current DATE
    local int_current_date = game_db_manager:get_table_record_field_value(
        readPointer("pCareerCalendarTableCurrentRecord"), "career_calendar", "currdate"
    )


    local first_record = game_db_manager.tables["career_playercontract"]["first_record"]
    local record_size = game_db_manager.tables["career_playercontract"]["record_size"]
    local written_records = game_db_manager.tables["career_playercontract"]["written_records"]

    local row = 0
    local current_addr = first_record
    local last_byte = 0
    local is_record_valid = true
    
    local s_currentdate = tostring(int_current_date)
    local current_year = tonumber(string.sub(s_currentdate, 1, 4))

    while true do
        if row >= written_records then
            break
        end
        current_addr = first_record + (record_size*row)
        last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
        is_record_valid = not (bAnd(last_byte, 128) > 0)
        if is_record_valid then
            local contract_status = game_db_manager:get_table_record_field_value(current_addr, "career_playercontract", "contract_status")
            local is_loaned_in = contract_status == 1 or contract_status == 3 or contract_status == 5
            
            -- Ignore players that are loaned in
            if not is_loaned_in then
                local playerid = game_db_manager:get_table_record_field_value(current_addr, "career_playercontract", "playerid")
                if playerid > 0 then
                    local contract_date = game_db_manager:get_table_record_field_value(current_addr, "career_playercontract", "contract_date")
                    local last_status_change_date = game_db_manager:get_table_record_field_value(current_addr, "career_playercontract", "last_status_change_date")
                    
                    -- Set contract date to current date
                    if contract_date < int_current_date then
                        game_db_manager:set_table_record_field_value(current_addr, "career_playercontract", "contract_date", int_current_date)
                    end
                    
                    
                    -- last_status change date to current date
                    if last_status_change_date < int_current_date then
                        game_db_manager:set_table_record_field_value(current_addr, "career_playercontract", "last_status_change_date", int_current_date)
                    end
                    
                    game_db_manager:set_table_record_field_value(current_addr, "career_playercontract", "duration_months", new_contract_length)
                    
                    local contractvaliduntil = current_year + math.floor(new_contract_length / 12)
                    
                    result[playerid] = contractvaliduntil
                end
            end
        end
        row = row + 1
    end
    
    return result
end

update_contractvaliduntil(update_contracts())

showMessage("Done")