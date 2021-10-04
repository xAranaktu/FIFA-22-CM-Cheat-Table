--- HOW TO USE:
--- https://i.imgur.com/xZMqzTc.gifv
--- 1. Open Cheat table as usuall and enter your career.
--- 2. In Cheat Engine click on "Memory View" button.
--- 3. Press "CTRL + L" to open lua engine
--- 4. Then press "CTRL + O" and open this script
--- 5. Click on 'Execute' button to execute script and wait for 'done' message box.

--- AUTHOR: ARANAKTU

--- It may take a few mins. Cheat Engine will stop responding and it's normal behaviour. Wait until you get 'Done' message.

--- This script will edit players shoes. 
--- By default only Black/White shoes will be replaced by a random shoe model from the "shoe_id_list" with random color.
--- You can set 'randomize_all' variable to true if you want to randoize all shoes. 

local randomize_all = false

-- Don't change anything below
gCTManager:init_ptrs()
local game_db_manager = gCTManager.game_db_manager
local memory_manager = gCTManager.memory_manager

local shoe_id_list = {
    16, --- adidas NEMEZIZ MESSI 19.1 302 REDIRECT
    17, --- adidas COPA 19+ 302 REDIRECT
    18, --- adidas NEMEZIZ 19+ 302 REDIRECT
    19, --- adidas PREDATOR 19+ 302 REDIRECT
    20, --- adidas X19+ 302 REDIRECT
    22, --- adidas NEMEZIZ 19+ INNER GAME
    23, --- adidas PREDATOR 19+ INPUT CODE
    24, --- adidas X19+ INNER GAME
    25, --- adidas COPA 19+ HARD WIRED
    26, --- adidas NEMEZIZ 19+ HARD WIRED
    27, --- adidas PREDATOR 19+ HARD WIRED
    28, --- adidas X19+ HARD WIRED
    29, --- adidas COPA 20+ ENCRYPTION
    30, --- adidas NEMEZIZ 19+ ENCRYPTION
    31, --- adidas PREDATOR 19+ ENCRYPTION
    32, --- adidas X19+ ENCRYPTION
    33, --- Lotto Solista 100 III Gravity
    34, --- JOMA Propulsion
    35, --- ASICS DS LIGHT X-FLY 4 - White/Green
    36, --- ASICS DS LIGHT AVANTE - Red/White
    37, --- Hummel Rapid X Blade Bluebird
    38, --- New Balance Furon V5 - Bayside/Supercell
    39, --- New Balance Tekela V2 - Supercell/Bayside
    40, --- New Balance Furon V5 - Sulphur Yellow/Phantom/White
    41, --- New Balance Tekela V2 - Yellow/Phantom/Castlerock
    42, --- New Balance Furon V6 - Neo Flame/Neo Crimson/Silver
    43, --- New Balance Tekela V2 - Vision Blue/Neo Classic Blue
    44, --- New Balance Furon V6 - White/Silver Metalic
    45, --- UA Magnetico Control - Black/Glow Orange/White
    46, --- UA Magnetico Control - Glow Orange/White/Black
    47, --- UA Magnetico Pro - Glow Orange/White/Black
    48, --- UA Magnetico Pro - White/Glow Orange/Black
    49, --- Pirma Gladiator Activity
    50, --- Pirma Supreme Legion
    51, --- Mizuno Morelia Neo II - Chinese Red/Silver
    52, --- Mizuno Morelia Neo II - Safety Yellow/Blue
    53, --- Mizuno Morelia Neo II - White/Gold
    54, --- Mizuno Morelia Neo II Beta - Silver/Gold
    55, --- Mizuno Morelia Neo II Beta - Black/Silver
    56, --- Mizuno Rebula 3 Japan - Black/Yellow
    57, --- PUMA FUTURE Anthem
    58, --- PUMA ONE Anthem
    59, --- PUMA FUTUE Rush
    60, --- PUMA ONE Rush
    61, --- umbro Medusae 3 Elite – Black/White
    62, --- umbro Velocita 4 Pro - Black/White
    63, --- umbro Medusae 3 Elite – White/Plum
    64, --- umbro Velocita 4 Pro - White/Plum
    65, --- umbro Medusae 3 Elite – Black/Black
    66, --- umbro Velocita 5 Pro - Black/Black
    67, --- umbro Medusae 3 Elite – White/Medieval Blue/Blue Radiance
    68, --- umbro Velocita 5 Pro – White/Medieval Blue/Blue Radiance
    69, --- Nike Mercurial Superfly Elite - Blue
    70, --- Nike PHANTOM VSN - Volt
    71, --- Nike PHANTOM VNM - Volt
    72, --- Nike Tiempo Elite - Black
    73, --- Nike Neymar Jr. Vapor Elite
    74, --- Nike Mercurial Superfly Elite - Blue Void
    75, --- Nike PHANTOM VNM - Bright Mango.White
    76, --- Nike PHANTOM VSN - Dark Grey. Bright Mango
    77, --- Nike Mercurial Superfly Elite - Lemon Yellow
    78, --- Nike Mercurial Superfly Elite - Laser Crimson
    79, --- Nike Mercurial Vapor Elite - Remastered
    80, --- Nike PHANTOM VNM - Laser Crimson
    81, --- Nike PHANTOM VNM - Remastered
    82, --- Nike PHANTOM VSN - Laser Crimson
    83, --- Nike PHANTOM VSN - Remastered
    84, --- Nike Tiempo Elite - Laser Crimson
    85, --- Nike Tiempo Elite - Remastered
    86, --- PUMA FUTURE FLASH
    87, --- PUMA FUTURE SPARKS
    88, --- PUMA ONE SPARKS
    89, --- PUMA FUTURE Winterized
    90, --- PUMA ONE Winterized
    91, --- adidas COPA 20+ MUTATOR
    92, --- adidas NEMEZIZ 19+ MUTATOR
    93, --- adidas X19+ MUTATOR
    94, --- adidas PREDATOR 20+ MUTATOR
    130, --- adidas X GHOSTED 20+ INFLIGHT
    131, --- adidas COPA 20+ INFLIGHT
    132, --- adidas NEMEZIZ 19+ INFLIGHT
    133, --- adidas PREDATOR 20+ INFLIGHT
    134, --- adidas COPA 20+ DARK MOTION
    135, --- adidas NEMEZIZ 19+ DARK MOTION
    136, --- adidas PREDATOR 20+ DARK MOTION
    137, --- adidas X GHOSTED 20+ DARK MOTION
    139, --- adidas X GHOSTED 20+ PF
    142, --- adidas PREDATOR 20+ HYPE
    143, --- adidas X GHOSTED+ GLORY HUNTER
    144, --- adidas COPA 20+ GLORY HUNTER
    145, --- adidas PREDATOR 20+ GLORY HUNTER
    154, --- Nike Mercurial Superfly VII Elite Safari
    155, --- Nike Mercurial Vapor XIII Elite Safari
    156, --- Nike Mercurial Vapor XIII Elite - Yellow
    157, --- Nike Phantom GT Elite - Black/Silver
    158, --- Nike Phantom GT Elite - White/Pink Blast
    159, --- Nike Phantom GT Elite DF - Black/Silver
    160, --- Nike Phantom GT Elite DF - White.Pink Blast
    161, --- Nike Tiempo Legend XIII Elite - White.Hyper Royal
    162, --- UA Magnetico SL - Black
    163, --- UA Magnetico SL - Beta Red
    164, --- UA Clone Magnetico – White
    165, --- UA Clone Magnetico – Beta Red
    166, --- BootName_166_Auth-FullChar
    167, --- JOMA PROW.2011 PROPULSION LIMON FLUOR
    168, --- Lotto Maestro 100 IV
    169, --- Mizuno Morelia Neo III Beta - Black
    170, --- Mizuno Morelia Neo III Beta - Blue
    171, --- Mizuno Rebula Cup Japan - White
    172, --- Mizuno Wave Cup Legend
    177, --- ASICS DS LIGHT AVANTE
    178, --- ASICS DS LIGHT X-FLY 4
    179, --- adidas COPA 20+ UNIFORIA
    180, --- adidas NEMEZIZ 19+ UNIFORIA
    181, --- adidas PREDATOR 20+ UNIFORIA
    182, --- adidas X 19+ UNIFORIA
    183, --- umbro TOCCO PRO - Black/White
    184, --- umbro TOCCO PRO - Blue Sapphire/Lime Punch
    185, --- umbro TOCCO PRO - White/Carrot
    186, --- umbro VELOCITA 5 PRO - Black/White
    187, --- umbro VELOCITA 5 PRO - Blue Sapphire/Lime Punch
    188, --- umbro VELOCITA 5 PRO - White/Carrot
    189, --- Pirma GHOST PREMIER
    190, --- Pirma IMPERIO LETAL
    191, --- PUMA Chasing Adrenaline FUTURE
    192 --- PUMA Chasing Adrenaline ULTRA
    -- 196, --- Nike Mercurial Superfly - Pink Blast/White/Black
    -- 197, --- Nike Mercurial Superfly - White/Black
    -- 220, --- Nike Mercurial Vapor - White.Black
    -- 221, --- New Balance Furon V6 Ignite Hype Pack
    -- 222, --- New Balance Tekela V3 Ignite Hype Pack
    -- 226, --- PUMA ONE 19.1 - Black.Bleu Azure/Red Blast
    -- 227, --- New Balance Furon v4 Pro - Flame/Aztec Gold
    -- 228, --- New Balance Tekela v1 Pro - Polaris/Galaxy
    -- 229, --- New Balance Furon v4 Pro - Bright Cherry/Black
    -- 504, --- Nike Tiempo Legend Elite - Black/Crimson
    -- 505, --- Nike Vapor Elite - Wolf Grey
    -- 506, --- Nike Neymar Vapor XII Silêncio
    -- 507, --- adidas NEMEZIZ 19.1 302 REDIRECT
    -- 508, --- adidas NEMEZIZ 19.1 HARD WIRED
    -- 509, --- adidas PREDATOR 19.1 Black/Black/Matte Gold
    -- 510, --- adidas Predator White and Gold
    -- 511, --- adidas PREDATOR 19.1 HARD WIRED
    -- 512, --- Nike Lunar Gato II
    -- 513, --- Nike React Gato
    -- 514, --- New Balance Audazo V4 Pro
    -- 515, --- PUMA 365 Roma 1TT - NRGY Red/Rhubarb
    -- 516, --- PUMA 365 Roma 1TT - Gray Dawn/NRGY Red
    -- 517, --- umbro Chaleira 2 Pro - White/Black/Regal Blue
    -- 547, --- adidas Samba - Black
    -- 548, --- adidas Samba - Blue
    -- 549 --- adidas Samba - White
}

function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end
    return false
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
    current_addr = first_record + (record_size*row)
    last_byte = readBytes(current_addr+record_size-1, 1, true)[1]
    is_record_valid = not (bAnd(last_byte, 128) > 0)
    if is_record_valid then
        local playerid = game_db_manager:get_table_record_field_value(current_addr, "players", "playerid")
        if playerid > 0 then
            local current_shoe = game_db_manager:get_table_record_field_value(current_addr, "players", "shoetypecode")

            if randomize_all or not inTable(shoe_id_list, current_shoe) then
                -- Random Shoe
                local new_shoe_id = shoe_id_list[math.random(1, #shoe_id_list)]

                -- Random shoecolorcode1
                local new_color_one = math.random(0, 31)

                -- Random shoecolorcode2
                local new_color_two = math.random(0, 31)

                game_db_manager:set_table_record_field_value(current_addr, "players", "shoedesigncode", 0)
                game_db_manager:set_table_record_field_value(current_addr, "players", "shoetypecode", new_shoe_id)
                game_db_manager:set_table_record_field_value(current_addr, "players", "shoecolorcode1", new_color_one)
                game_db_manager:set_table_record_field_value(current_addr, "players", "shoecolorcode1", new_color_two)
            end

        end
    end
    row = row + 1
end

showMessage("Done")
