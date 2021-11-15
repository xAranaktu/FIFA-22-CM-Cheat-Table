
--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

-- This script will export transfers history to CSV.
-- The TRANSFERS_HISTORY.csv file will be created in the same directory where you have the Cheat Table
-- The game resets transfer history at the beginning of every season, so you need to run the script at the end of every season.


-- Don't touch anything below

local NG_FA_TEAMID = 111592

function transfer_dbg(current_addr, from)
    --local dbg_playerid = readInteger(current_addr)  -- 0x0
    --print(string.format("%s - %s: 0x%X", from, get_player_fullname(dbg_playerid), current_addr))
end

function GetUserAcceptedPlayerTransfers(NegotiationsStorageDaoImpl)
    local result = {}

    local Hist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["USER_PLAYER_HIST_OFF"])
    local sz = USER_PLAYER_TRANSFER_HIST_STRUCT["size"]

    local _start = readPointer(Hist)
    local _end = readPointer(Hist + 8)

    local current_addr = _start

    local count = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetUserAcceptedPlayerTransfers")

        local seller_accepted = readBytes(current_addr + USER_PLAYER_TRANSFER_HIST_STRUCT['seller_accepted'], 1, true)[1] == 1
        local buyer_accepted = readBytes(current_addr + USER_PLAYER_TRANSFER_HIST_STRUCT['buyer_accepted'], 1, true)[1] == 1

        if buyer_accepted or seller_accepted then
            local playerid = readInteger(current_addr + USER_PLAYER_TRANSFER_HIST_STRUCT["playerid"])
            local toteamid = readInteger(current_addr + USER_PLAYER_TRANSFER_HIST_STRUCT["toteamid"])
            local fromteamid = readInteger(current_addr + USER_PLAYER_TRANSFER_HIST_STRUCT["fromteamid"])
            local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

            local actions_vec_begin_addr = current_addr + USER_PLAYER_TRANSFER_HIST_STRUCT["actions_vec"]
            local last_action = get_last_vec_elem(actions_vec_begin_addr, Action_STRUCT["size"])
            local last_action_date = readInteger(last_action + Action_STRUCT['action_date'])

            result[key] = {
                playerid = playerid,
                toteamid = toteamid,
                fromteamid = fromteamid,
                date = last_action_date
            }

            count = count + 1
        end
        current_addr = current_addr + sz
    end

    return result
end

function GetUserAcceptedClubLoans(NegotiationsStorageDaoImpl)
    local result = {}

    local UserClubHist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["USER_CLUB_LOAN_HIST_OFF"])
    local sz = USER_CLUB_LOAN_HIST_STRUCT["size"]

    local _start = readPointer(UserClubHist)
    local _end = readPointer(UserClubHist + 8)

    local current_addr = _start

    local count = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetUserAcceptedLoansTransfers")

        local actions_vec_begin_addr = current_addr + USER_CLUB_LOAN_HIST_STRUCT["actions_vec"]

        if is_vec_valid(actions_vec_begin_addr) then
            local last_action = get_last_vec_elem(actions_vec_begin_addr, Action_STRUCT["size"])
            local last_action_type = readBytes(last_action + Action_STRUCT['action_type'], 1, true)[1]

            local buyer_accepted = last_action_type == 4
            local seller_accepted = last_action_type == 0

            if buyer_accepted or seller_accepted then
                -- if buyer_accepted then
                --     -- Get last from requests
                --     local requests_begin_addr = current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["requests_vec"]
                --     if is_vec_valid(requests_begin_addr) then
                --         local last_request = get_last_vec_elem(requests_begin_addr, USER_TRANSFER_REQUEST_STRUCT["size"])
                --         transfer_sum = readInteger(last_request + USER_TRANSFER_REQUEST_STRUCT["sum"])
                --     end
                -- else
                --     -- Get last from offers
                --     local offers_begin_addr = current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["offers_vec"]
                --     if is_vec_valid(offers_begin_addr) then
                --         local last_offer = get_last_vec_elem(offers_begin_addr, USER_TRANSFER_OFFER_STRUCT["size"])
                --         transfer_sum = readInteger(last_offer + USER_TRANSFER_OFFER_STRUCT["sum"])
                --     end
                -- end

                -- Date from last action
                local last_action_date = readInteger(last_action + Action_STRUCT['action_date'])

                local playerid = readInteger(current_addr + USER_CLUB_LOAN_HIST_STRUCT["playerid"])
                local toteamid = readInteger(current_addr + USER_CLUB_LOAN_HIST_STRUCT["toteamid"])
                local fromteamid = readInteger(current_addr + USER_CLUB_LOAN_HIST_STRUCT["fromteamid"])
                local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

                result[key] = {
                    playerid = playerid,
                    toteamid = toteamid,
                    fromteamid = fromteamid,
                    sum = transfer_sum,
                    date = last_action_date
                }
                count = count + 1
            end
        end

        current_addr = current_addr + sz
    end

    --print(string.format("UserClubTransfers Accepted: %d", count))
    return result
end

function GetUserAcceptedClubTransfers(NegotiationsStorageDaoImpl)
    local result = {}

    local UserClubHist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["USER_CLUB_HIST_OFF"])
    local sz = USER_CLUB_TRANSFER_HIST_STRUCT["size"]

    local _start = readPointer(UserClubHist)
    local _end = readPointer(UserClubHist + 8)

    local current_addr = _start

    local count = 0
    local transfer_sum = 0
    local exchange_playerid = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetUserAcceptedClubTransfers")

        local actions_vec_begin_addr = current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["actions_vec"]

        if is_vec_valid(actions_vec_begin_addr) then
            local last_action = get_last_vec_elem(actions_vec_begin_addr, Action_STRUCT["size"])
            local last_action_type = readBytes(last_action + Action_STRUCT['action_type'], 1, true)[1]

            local buyer_accepted = last_action_type == 4
            local seller_accepted = last_action_type == 0
            
            -- print(string.format(
            --     "addr: 0x%x, last_action: 0x%X, type: %d",
            --     current_addr,
            --     last_action, last_action_type
            -- ))
    
            if buyer_accepted or seller_accepted then
                transfer_sum = 0
                exchange_playerid = 0
                if buyer_accepted then
                    -- Get last from requests
                    local requests_begin_addr = current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["requests_vec"]
                    if is_vec_valid(requests_begin_addr) then
                        local last_request = get_last_vec_elem(requests_begin_addr, USER_TRANSFER_REQUEST_STRUCT["size"])
                        transfer_sum = readInteger(last_request + USER_TRANSFER_REQUEST_STRUCT["sum"])
                        exchange_playerid = readInteger(last_request + USER_TRANSFER_REQUEST_STRUCT["exchange_playerid"])
                    end
                else
                    -- Get last from offers
                    local offers_begin_addr = current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["offers_vec"]
                    if is_vec_valid(offers_begin_addr) then
                        local last_offer = get_last_vec_elem(offers_begin_addr, USER_TRANSFER_OFFER_STRUCT["size"])
                        transfer_sum = readInteger(last_offer + USER_TRANSFER_OFFER_STRUCT["sum"])
                        exchange_playerid = readInteger(last_offer + USER_TRANSFER_OFFER_STRUCT["exchange_playerid"])
                    end
                end

                -- Date from last action
                local last_action_date = readInteger(last_action + Action_STRUCT['action_date'])

                local playerid = readInteger(current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["playerid"])
                local toteamid = readInteger(current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["toteamid"])
                local fromteamid = readInteger(current_addr + USER_CLUB_TRANSFER_HIST_STRUCT["fromteamid"])
                local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

                if exchange_playerid == 4294967295 then
                    exchange_playerid = 0
                end

                result[key] = {
                    playerid = playerid,
                    toteamid = toteamid,
                    fromteamid = fromteamid,
                    exchange_playerid = exchange_playerid,
                    sum = transfer_sum,
                    date = last_action_date
                }
                count = count + 1
            end
        end

        current_addr = current_addr + sz
    end

    --print(string.format("UserClubTransfers Accepted: %d", count))
    return result
end

function GetCPUAcceptedPlayerTransfers(NegotiationsStorageDaoImpl)
    local result = {}

    local Hist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["CPU_PLAYER_HIST_OFF"])
    local sz = CPU_PLAYER_TRANSFER_HIST_STRUCT["size"]

    local _start = readPointer(Hist)
    local _end = readPointer(Hist + 8)

    local current_addr = _start

    local count = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetCPUAcceptedPlayerTransfers")

        local seller_accepted = readBytes(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT['seller_accepted'], 1, true)[1] == 1
        local buyer_accepted = readBytes(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT['buyer_accepted'], 1, true)[1] == 1

        if buyer_accepted or seller_accepted then
            local playerid = readInteger(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT["playerid"])
            local toteamid = readInteger(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT["toteamid"])
            local fromteamid = readInteger(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT["fromteamid"])
            local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

            result[key] = {
                playerid = playerid,
                toteamid = toteamid,
                fromteamid = fromteamid,
            }

            count = count + 1
        end
        current_addr = current_addr + sz
    end

    return result
end

function GetCPUAcceptedClubTransfers(NegotiationsStorageDaoImpl)
    local result = {}

    local CpuClubHist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["CPU_CLUB_HIST_OFF"])
    local sz = CPU_CLUB_TRANSFER_HIST_STRUCT["size"]

    local _start = readPointer(CpuClubHist)
    local _end = readPointer(CpuClubHist + 8)

    local current_addr = _start

    local count = 0
    local transfer_sum = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetCPUAcceptedClubTransfers")
        local seller_accepted = readBytes(current_addr + CPU_CLUB_TRANSFER_HIST_STRUCT['seller_accepted'], 1, true)[1] == 1
        local buyer_accepted = readBytes(current_addr + CPU_CLUB_TRANSFER_HIST_STRUCT['buyer_accepted'], 1, true)[1] == 1
    
        if buyer_accepted or seller_accepted then
            transfer_sum = 0
            if buyer_accepted then
                -- Get last from requests
                local requests_begin_addr = current_addr + CPU_CLUB_TRANSFER_HIST_STRUCT["requests_vec"]
                if is_vec_valid(requests_begin_addr) then
                    local last_request = get_last_vec_elem(requests_begin_addr, CPU_TRANSFER_REQUEST_STRUCT["size"])
                    transfer_sum = readInteger(last_request + CPU_TRANSFER_REQUEST_STRUCT["sum"])
                end
            else
                -- Get last from offers
                local offers_begin_addr = current_addr + CPU_CLUB_TRANSFER_HIST_STRUCT["offers_vec"]
                if is_vec_valid(offers_begin_addr) then
                    local last_offer = get_last_vec_elem(offers_begin_addr, CPU_TRANSFER_OFFER_STRUCT["size"])
                    transfer_sum = readInteger(last_offer + CPU_TRANSFER_OFFER_STRUCT["sum"])
                end
            end

            local last_action_idx = readInteger(current_addr + CPU_CLUB_TRANSFER_HIST_STRUCT["last_action_idx"])
            local last_action_off = CPU_CLUB_TRANSFER_HIST_STRUCT["actions_arr"] + (Action_STRUCT["size"] * last_action_idx)
            local last_action = current_addr + last_action_off

            local last_action_date = readInteger(last_action + Action_STRUCT['action_date'])
            --local last_action_type = readBytes(last_action + Action_STRUCT['action_type'], 1, true)[1]

            local playerid = readInteger(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT["playerid"])
            local toteamid = readInteger(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT["toteamid"])
            local fromteamid = readInteger(current_addr + CPU_PLAYER_TRANSFER_HIST_STRUCT["fromteamid"])
            local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

            result[key] = {
                playerid = playerid,
                toteamid = toteamid,
                fromteamid = fromteamid,
                sum = transfer_sum,
                date = last_action_date
            }

            -- if playerid == 213661 then
            --     print(string.format("Christensen: 0x%X", current_addr))
            -- end
            count = count + 1
            
        end
        current_addr = current_addr + sz
    end

    -- print(string.format("CPUClubTransfers Accepted: %d", count))
    return result
end

function GetCPUAcceptedClubLoans(NegotiationsStorageDaoImpl)
    local result = {}

    local Hist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["CPU_CLUB_LOAN_HIST_OFF"])
    local sz = CPU_CLUB_LOAN_HIST_STRUCT["size"]

    local _start = readPointer(Hist)
    local _end = readPointer(Hist + 8)

    local current_addr = _start

    local count = 0
    local fee = 0
    local contract_len = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetCPUAcceptedClubLoans")
        local seller_accepted = readBytes(current_addr + CPU_CLUB_LOAN_HIST_STRUCT['seller_accepted'], 1, true)[1] == 1
        local buyer_accepted = readBytes(current_addr + CPU_CLUB_LOAN_HIST_STRUCT['buyer_accepted'], 1, true)[1] == 1
    
        if buyer_accepted or seller_accepted then
            fee = 0
            contract_len = 0
            if buyer_accepted then
                -- Get last from requests
                local requests_begin_addr = current_addr + CPU_CLUB_LOAN_HIST_STRUCT["requests_vec"]
                if is_vec_valid(requests_begin_addr) then
                    local last_request = get_last_vec_elem(requests_begin_addr, CPU_LOAN_REQUEST_STRUCT["size"])
                    contract_len = readInteger(last_request + CPU_LOAN_REQUEST_STRUCT["contract_len"])
                    fee = readInteger(last_request + CPU_LOAN_REQUEST_STRUCT["fee"])
                end
            else
                -- Get last from offers
                local offers_begin_addr = current_addr + CPU_CLUB_LOAN_HIST_STRUCT["offers_vec"]
                if is_vec_valid(offers_begin_addr) then
                    local last_offer = get_last_vec_elem(offers_begin_addr, CPU_LOAN_OFFER_STRUCT["size"])
                    contract_len = readInteger(last_offer + CPU_LOAN_OFFER_STRUCT["contract_len"])
                    fee = readInteger(last_offer + CPU_LOAN_OFFER_STRUCT["fee"])
                end
            end

            if fee == 4294967295 then
                fee = "-"
            end

            local last_action_idx = readInteger(current_addr + CPU_CLUB_LOAN_HIST_STRUCT["last_action_idx"])
            local last_action_off = CPU_CLUB_LOAN_HIST_STRUCT["actions_arr"] + (Action_STRUCT["size"] * last_action_idx)
            local last_action = current_addr + last_action_off

            local last_action_date = readInteger(last_action + Action_STRUCT['action_date'])
            --local last_action_type = readBytes(last_action + Action_STRUCT['action_type'], 1, true)[1]

            local playerid = readInteger(current_addr + CPU_CLUB_LOAN_HIST_STRUCT["playerid"])
            local toteamid = readInteger(current_addr + CPU_CLUB_LOAN_HIST_STRUCT["toteamid"])
            local fromteamid = readInteger(current_addr + CPU_CLUB_LOAN_HIST_STRUCT["fromteamid"])
            local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

            result[key] = {
                playerid = playerid,
                toteamid = toteamid,
                fromteamid = fromteamid,
                is_loan = true,
                contract_len = contract_len,
                fee = fee,
                date = last_action_date
            }

            -- if playerid == 213661 then
            --     print(string.format("Christensen: 0x%X", current_addr))
            -- end
            count = count + 1
            
        end
        current_addr = current_addr + sz
    end

    -- print(string.format("CPUClubTransfers Accepted: %d", count))
    return result
end

function GetCPUAcceptedPlayerLoans(NegotiationsStorageDaoImpl)
    local result = {}

    local Hist = readPointer(NegotiationsStorageDaoImpl + NegotiationsStorageDaoImpl_STRUCT["CPU_PLAYER_LOAN_HIST_OFF"])
    local sz = CPU_PLAYER_LOAN_HIST_STRUCT["size"]

    local _start = readPointer(Hist)
    local _end = readPointer(Hist + 8)

    local current_addr = _start

    local count = 0
    local fee = 0
    local contract_len = 0
    while current_addr < _end do
        transfer_dbg(current_addr, "GetCPUAcceptedPlayerLoans")
        local seller_accepted = readBytes(current_addr + CPU_PLAYER_LOAN_HIST_STRUCT['seller_accepted'], 1, true)[1] == 1
        local buyer_accepted = readBytes(current_addr + CPU_PLAYER_LOAN_HIST_STRUCT['buyer_accepted'], 1, true)[1] == 1
    
        if buyer_accepted or seller_accepted then
            --fee = 0
            --contract_len = 0
            -- if buyer_accepted then
            --     -- Get last from requests
            --     local requests_begin_addr = current_addr + CPU_PLAYER_LOAN_HIST_STRUCT["requests_vec"]
            --     if is_vec_valid(requests_begin_addr) then
            --         local last_request = get_last_vec_elem(requests_begin_addr, CPU_LOAN_REQUEST_STRUCT["size"])
            --         contract_len = readInteger(last_request + CPU_LOAN_REQUEST_STRUCT["contract_len"])
            --         fee = readInteger(last_request + CPU_LOAN_REQUEST_STRUCT["fee"])
            --     end
            -- else
            --     -- Get last from offers
            --     local offers_begin_addr = current_addr + CPU_PLAYER_LOAN_HIST_STRUCT["offers_vec"]
            --     if is_vec_valid(offers_begin_addr) then
            --         local last_offer = get_last_vec_elem(offers_begin_addr, CPU_LOAN_OFFER_STRUCT["size"])
            --         contract_len = readInteger(last_offer + CPU_LOAN_OFFER_STRUCT["contract_len"])
            --         fee = readInteger(last_offer + CPU_LOAN_OFFER_STRUCT["fee"])
            --     end
            -- end

            local last_action_idx = readInteger(current_addr + CPU_PLAYER_LOAN_HIST_STRUCT["last_action_idx"])
            local last_action_off = CPU_PLAYER_LOAN_HIST_STRUCT["actions_arr"] + (Action_STRUCT["size"] * last_action_idx)
            local last_action = current_addr + last_action_off

            local last_action_date = readInteger(last_action + Action_STRUCT['action_date'])
            --local last_action_type = readBytes(last_action + Action_STRUCT['action_type'], 1, true)[1]

            local playerid = readInteger(current_addr + CPU_PLAYER_LOAN_HIST_STRUCT["playerid"])
            local toteamid = readInteger(current_addr + CPU_PLAYER_LOAN_HIST_STRUCT["toteamid"])
            local fromteamid = readInteger(current_addr + CPU_PLAYER_LOAN_HIST_STRUCT["fromteamid"])
            local key = string.format("P%d-F%d-T%d", playerid, fromteamid, toteamid)

            result[key] = {
                playerid = playerid,
                toteamid = toteamid,
                fromteamid = fromteamid,
                is_loan = true,
                contract_len = "-",
                fee = "-",
                date = last_action_date
            }
            count = count + 1
            
        end
        current_addr = current_addr + sz
    end

    -- print(string.format("CPUClubTransfers Accepted: %d", count))
    return result
end

-- STUFF
gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

local mgr = get_mode_manager_impl_ptr("TransferManager")
if not mgr or mgr == 0 then return end

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

-- File
local transfer_history = {}
local filename = string.format("TRANSFERS_HISTORY_%d_%d_%d.csv", current_date.day, current_date.month, current_date.year)
local file = io.open(filename, "w+")
io.output(file)

local columns = {
    "playerid",
    "playername",
    "from",
    "to",
    "sum",
    "exchange_playerid",
    "exchange_playername",
    "date",
    "contract_length",
    "fee",
}

local NegotiationsStorageDao = readPointer(mgr + TRANSFER_MANAGER_STRUCT["NegotiationsStorageDao_offset"])
local NegotiationsStorageDaoImpl = readPointer(NegotiationsStorageDao + NegotiationsStorageDao_STRUCT["impl"])

local cpu_player_accepted = GetCPUAcceptedPlayerTransfers(NegotiationsStorageDaoImpl)
local cpu_club_accepted = GetCPUAcceptedClubTransfers(NegotiationsStorageDaoImpl)

local cpu_club_loans_accepted = GetCPUAcceptedClubLoans(NegotiationsStorageDaoImpl)
local cpu_player_loans_accepted = GetCPUAcceptedPlayerLoans(NegotiationsStorageDaoImpl)

local user_club_accepted = GetUserAcceptedClubTransfers(NegotiationsStorageDaoImpl)
local user_club_accepted_loans = GetUserAcceptedClubLoans(NegotiationsStorageDaoImpl)
local user_player_accepted = GetUserAcceptedPlayerTransfers(NegotiationsStorageDaoImpl)

for key, _ in pairs(cpu_player_accepted) do
    local is_fa = _.fromteamid == NG_FA_TEAMID or _.toteamid == NG_FA_TEAMID

    local data = nil
    if is_fa then
        data = _
        data["sum"] = 0
    else
        data = user_club_accepted[key] or cpu_club_accepted[key]
    end

    if data then
        local playername = get_player_fullname(data["playerid"])

        local entry = {
            playerid = data["playerid"],
            playername = playername,
            from = get_team_label_by_id(data["fromteamid"]),
            to = get_team_label_by_id(data["toteamid"]),
            sum = data["sum"],
            date = data["date"],
            contract_length = "-",
            fee = "-",
        }

        if data["exchange_playerid"] and data["exchange_playerid"] > 0 then
            entry["exchange_playerid"] = data["exchange_playerid"]
            entry["exchange_playername"] = get_player_fullname(entry["exchange_playerid"])
        end

        table.insert(transfer_history, entry)
    end
end

for key, _ in pairs(user_player_accepted) do
    local is_fa = _.fromteamid == NG_FA_TEAMID or _.toteamid == NG_FA_TEAMID

    local data = nil
    if is_fa then
        data = _
        data["sum"] = 0
    else
        data = user_club_accepted[key] or cpu_club_accepted[key]
    end

    if data then
        local playername = get_player_fullname(data["playerid"])

        local entry = {
            playerid = data["playerid"],
            playername = playername,
            from = get_team_label_by_id(data["fromteamid"]),
            to = get_team_label_by_id(data["toteamid"]),
            sum = data["sum"],
            date = data["date"],
            contract_length = "-",
            fee = "-",
        }

        if data["exchange_playerid"] and data["exchange_playerid"] > 0 then
            entry["exchange_playerid"] = data["exchange_playerid"]
            entry["exchange_playername"] = get_player_fullname(entry["exchange_playerid"])
        end

        table.insert(transfer_history, entry)
    end
end

for key, _ in pairs(cpu_player_loans_accepted) do
    local data = cpu_club_loans_accepted[key]
    if data then
        local playername = get_player_fullname(data["playerid"])

        local entry = {
            playerid = data["playerid"],
            playername = playername,
            from = get_team_label_by_id(data["fromteamid"]),
            to = get_team_label_by_id(data["toteamid"]),
            sum = "LOAN",
            date = data["date"],
            contract_length = data["contract_len"] or "-",
            fee = data["fee"] or "-",
        }

        table.insert(transfer_history, entry)
    end
end

-- Columns
io.write(table.concat(columns, ","))
io.write("\n")

for i=1, #transfer_history do
    local itm = transfer_history[i]

    local row = {}
    for i=1, #columns do
        local colname = columns[i]
        table.insert(row, itm[colname] or "-")
    end
    io.write(table.concat(row, ","))
    io.write("\n")
end

io.close(file)
showMessage("Done")