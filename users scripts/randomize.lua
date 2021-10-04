--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- Fun script, don't recommend to use it in long term careers.
--- High chance that it will broke your squad file/career save

--- This script will randomize position, attributes, ovr, potential, age, nationality of all players.


local random_position = true
local random_attributes = true
local random_age = true
local random_nationality = true

local attribute_min = 21
local attribute_max = 99

local age_change_range_min = -5
local age_change_range_max = 5
local age_max = 40  -- Not older than 40 years
local age_min = 16  -- Not younger than 16 years


-- Don't change anything below
local playersEditorFormManager = require 'lua/GUI/forms/playerseditorform/manager';

gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

local nationalities = {
    149,
    1,
    97,
    194,
    2,
    98,
    62,
    63,
    52,
    3,
    64,
    195,
    4,
    5,
    65,
    150,
    151,
    66,
    6,
    7,
    67,
    99,
    68,
    152,
    53,
    8,
    100,
    54,
    69,
    153,
    9,
    101,
    102,
    225,
    154,
    103,
    70,
    104,
    71,
    105,
    106,
    55,
    155,
    213,
    56,
    214,
    107,
    110,
    196,
    72,
    10,
    73,
    85,
    11,
    12,
    108,
    13,
    109,
    74,
    207,
    57,
    111,
    76,
    14,
    112,
    113,
    208,
    142,
    114,
    16,
    197,
    17,
    18,
    115,
    116,
    20,
    21,
    117,
    205,
    22,
    206,
    77,
    157,
    78,
    118,
    119,
    79,
    80,
    34,
    81,
    158,
    23,
    24,
    159,
    160,
    161,
    162,
    26,
    27,
    82,
    163,
    164,
    165,
    120,
    166,
    167,
    219,
    168,
    169,
    170,
    28,
    171,
    121,
    122,
    123,
    29,
    30,
    31,
    172,
    124,
    125,
    173,
    174,
    126,
    32,
    127,
    128,
    83,
    33,
    175,
    15,
    84,
    129,
    130,
    176,
    131,
    177,
    215,
    198,
    86,
    132,
    133,
    19,
    35,
    36,
    178,
    179,
    180,
    87,
    199,
    58,
    59,
    181,
    37,
    38,
    88,
    182,
    25,
    39,
    40,
    134,
    200,
    41,
    183,
    42,
    136,
    51,
    137,
    138,
    184,
    43,
    44,
    201,
    139,
    140,
    218,
    45,
    185,
    89,
    90,
    91,
    141,
    92,
    46,
    47,
    186,
    135,
    202,
    187,
    143,
    188,
    212,
    144,
    203,
    93,
    145,
    48,
    189,
    94,
    96,
    146,
    49,
    190,
    95,
    60,
    191,
    204,
    61,
    192,
    50,
    193,
    147,
    148
}

local attributes_fields = {
    "gkdiving",
    "gkhandling",
    "gkkicking",
    "gkpositioning",
    "gkreflexes",
    "crossing",
    "finishing",
    "headingaccuracy",
    "shortpassing",
    "volleys",
    "marking",
    "standingtackle",
    "slidingtackle",
    "dribbling",
    "curve",
    "freekickaccuracy",
    "longpassing",
    "ballcontrol",
    "shotpower",
    "jumping",
    "stamina",
    "strength",
    "longshots",
    "acceleration",
    "sprintspeed",
    "agility",
    "reactions",
    "balance",
    "aggression",
    "composure",
    "interceptions",
    "positioning",
    "vision",
    "penalties"
}

local pgs = get_players_in_player_growth_system()

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
            -- Randomize position
            local new_primary_pos = nil
            if random_position then
                new_primary_pos = math.random(0, 27)
                if new_primary_pos == 1 then
                    new_primary_pos = 5     -- Replace SW with CB
                end
                game_db_manager:set_table_record_field_value(current_addr, "players", "preferredposition1", new_primary_pos)
            end
            if random_attributes then
                local primary_pos = new_primary_pos or game_db_manager:get_table_record_field_value(current_addr, "players", "preferredposition1")

                -- Randomize attributes
                local new_ovr = 0
                local ovr_formula = OVR_FORMULA_2[primary_pos]
                
                for _, fld in ipairs(attributes_fields) do
                    local new_attr_val = math.random(attribute_min, attribute_max)
                    if ovr_formula[fld] then
                        new_ovr = new_ovr + (new_attr_val * ovr_formula[fld])
                    end

                    game_db_manager:set_table_record_field_value(current_addr, "players", fld, new_attr_val)
                    playersEditorFormManager:update_xp_in_player_growth_system(playerid, pgs[playerid], fld, new_attr_val)
                end
                new_ovr = math.floor(new_ovr) + game_db_manager:get_table_record_field_value(current_addr, "players", "modifier")
                game_db_manager:set_table_record_field_value(current_addr, "players", "overallrating", new_ovr)
                local new_pot = new_ovr + 5
                if new_pot >= 99 then
                    new_pot = 99
                end
                game_db_manager:set_table_record_field_value(current_addr, "players", "potential", new_pot)
            end


            -- Randomize age
            if random_age then
                local playerbirthdate = game_db_manager:get_table_record_field_value(current_addr, "players", "birthdate")
                
                local bdate = days_to_date(playerbirthdate)
                
                local player_current_age = calculate_age(current_date, bdate)
                local new_age = player_current_age + math.random(age_change_range_min, age_change_range_max)

                if player_current_age ~= new_age then
                    if new_age > age_max then 
                        new_age = age_max
                    elseif new_age < age_min then
                        new_age = age_min
                    end

                    playerbirthdate = playerbirthdate + ((player_current_age - new_age) * 366)
                    game_db_manager:set_table_record_field_value(current_addr, "players", "birthdate", playerbirthdate)
                end
            end

            -- Randomize nationality
            if random_nationality then
                local new_nationality = nationalities[math.random(1, #nationalities-1)]
                game_db_manager:set_table_record_field_value(current_addr, "players", "nationality", new_nationality)
            end
        end
    end
    row = row + 1
end

showMessage("Done")