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
    16, --- New Balance Furon V6+ Alpha Flair
    17, --- New Balance Tekela V3+ Pro Alpha Flair
    20, --- UA Clone Magnetico Pro FG - Summer Lime
    21, --- UA Clone Magnetico Pro FG - Hi Vis Yellow
    22, --- UA Magnetico Pro SL FG - Summer Lime
    23, --- UA Magnetico Pro SL FG - Hi Vis Yellow
    24, --- umbro TOCCO PRO - Black/Cherry Tomato
    25, --- umbro TOCCO PRO - White/Black/Urban Chic
    26, --- umbro VELOCITA VI PRO - Cherry Tomato/White/Black
    27, --- umbro VELOCITA VI PRO - Urban Chic/High-Rise/Black
    28, --- PUMA FUTURE Z Faster
    29, --- PUMA ULTRA Faster
    36, --- adidas COPA 21+ ESCAPE LIGHT
    37, --- adidas PREDATOR 21+ ESCAPE LIGHT
    38, --- adidas COPA 21+ METEORITE
    39, --- adidas PREDATOR 21+ METEORITE
    40, --- adidas X SPEEDFLOW+ HYPE ADIZERO
    41, --- adidas COPA 21+ NUMBERS UP
    42, --- adidas PREDATOR 21+ NUMBERS UP
    45, --- adidas X SPEEDFLOW+ NUMBERS UP
    46, --- Lotto Maestro 2AW - All Black/Acacia Green
    47, --- Nike Mercurial Vapor Elite - Gear Up
    48, --- Nike Superfly Elite - Gear Up
    49, --- Nike Tiempo Elite - Gear Up
    50, --- Nike Phantom GT2 Elite - Gear Up
    51, --- Nike Phantom GT2 Elite DF - Gear Up
    52, --- Nike Superfly Elite CR7 - Spark Creativity
    53, --- JOMA PROPULSION
    54, --- JOMA SUPERCOPA
    55, --- adidas X SPEEDFLOW+ METEORITE
    56, --- adidas X SPEEDFLOW ESCAPE LIGHT
    57, --- adidas PREDATOR FREAK+
    58, --- adidas PREDATOR FREAK.1
    59, --- adidas X SPEEDFLOW+ Messi
    60, --- mizuno Morelia DNA Japan
    61, --- mizuno Morelia Neo III β Japan DNA
    62, --- mizuno Morelia Neo III β Japan Next Generation
    63, --- mizuno Rebula Cup Japan Next Wave
    91, --- Pirma IMPERIO LEGEND - Black
    92, --- Pirma IMPERIO LEGEND - White
    130, --- adidas X GHOSTED 20+ INFLIGHT
    131, --- adidas COPA 20+ INFLIGHT
    132, --- adidas NEMEZIZ 19+ INFLIGHT
    133, --- adidas PREDATOR 20+ INFLIGHT
    134, --- adidas COPA 20+ DARK MOTION
    135, --- adidas NEMEZIZ 19+ DARK MOTION
    136, --- adidas PREDATOR 20+ DARK MOTION
    137, --- adidas X GHOSTED 20+ DARK MOTION
    139, --- adidas X GHOSTED 20+ PF
    140, --- adidas PREDATOR 20+ PP HYPE
    142, --- adidas Predator Accelerator 1998
    143, --- adidas X GHOSTED+ GLORY HUNTER
    144, --- adidas COPA 20+ GLORY HUNTER
    145, --- adidas PREDATOR 20+ GLORY HUNTER
    146, --- adidas COPA 20+ PRECISION TO BLUR
    147, --- adidas NEMEZIZ 20+ PRECISION TO BLUR
    148, --- adidas PREDATOR 20+ PRECISION TO BLUR
    149, --- adidas X GHOSTED 20+ PRECISION TO BLUR
    150, --- adidas NEMEZIZ + ATMOSPHERIC
    151, --- adidas PREDATOR 20+ ATMOSPHERIC
    152, --- adidas X GHOSTED+ ATMOSPHERIC
    153, --- adidas COPA MUNDIAL ETERNAL CLASS PT1
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
    166, --- adidas NEMEZIZ MESSI 20.1
    167, --- JOMA PROW.2011 PROPULSION LIMON FLUOR
    168, --- Lotto Maestro 100 IV
    169, --- Mizuno Morelia Neo III Beta - Black
    170, --- Mizuno Morelia Neo III Beta - Blue
    171, --- Mizuno Rebula Cup Japan - White
    172, --- Mizuno Wave Cup Legend
    173, --- Mizuno Rebula Cup Japan - Black
    174, --- Mizuno Morelia UL
    175, --- Mizuno Morelia Neo III Beta - Cyber
    176, --- Mizuno Morelia Neo III Beta - Red
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
    193, --- PUMA Speed of Light ULTRA
    194, --- PUMA Turbo-Pack FUTURE
    195, --- PUMA Turbo-Pack ULTRA
    196, --- Nike Mercurial Superfly - Pink Blast/White/Black
    197, --- Nike Mercurial Superfly - White/Black
    198, --- Nike Phantom GT Elite DF - Pure Platinum
    199, --- Nike Mercurial Superfly – Blue/Red/White
    200, --- Nike Phantom SK - Red/Silver/Black
    201, --- Nike Mercurial Superfly - Purple/Silver/Crimson
    202, --- Nike Mercurial Superfly - White/Silver/Dark Raisin
    203, --- Nike Mercurial Vapor - White/Silver/Dark Raisin
    204, --- Nike Mercurial Superfly - Bright Crimson/Silver
    205, --- Nike Phantom GT Elite - Photo Blue/Silver
    206, --- Nike Phantom GT Elite DF - Photo Blue/Silver
    207, --- Nike Tiempo Legend - Platinum/Rage Green/Metallic
    208, --- Nike Mercurial Superfly - White/Silver/Mango
    209, --- Nike Mercurial Vapor - White/Silver/Mango
    210, --- Nike Phantom GT Elite - Blue/Pink/Yellow
    211, --- Nike Phantom GT Elite DF - Blue/Pink/Yellow
    212, --- Nike Phantom GT Elite - Grey/Black/Green Glow/Gold
    213, --- Nike Mercurial Superfly - White/Silver/Volt
    214, --- Nike Mercurial Vapor - White/Silver/Volt
    215, --- Nike Mercurial Superfly - Dynamic Turq/Lime/Noir
    216, --- Nike Mercurial Vapor - Dynamic Turq/Lime/Noir
    217, --- Nike Phantom GT Elite - Lime/Aquamarine/Noir
    218, --- Nike Phantom GT Elite DF - Lime/Aquamarine/Noir
    219, --- Nike Tiempo Legend - Aquamarine/White/Lime Glow
    220, --- Nike Mercurial Vapor - White/Black
    221, --- New Balance Furon V6 Ignite Hype Pack
    222, --- New Balance Tekela V3 Ignite Hype Pack
    223, --- New Balance Furon V6 Energy Streak
    224, --- New Balance Tekela V3 Energy Streak
    225, --- adidas COPA 21+ BLACK PACK
    226, --- adidas NEMEZIZ 20+ BLACK PACK
    227, --- adidas PREDATOR 21+ BLACK PACK
    228, --- adidas X Ghosted+ BLACK PACK
    229, --- adidas COPA 21+ SUPERLATIVE
    230, --- adidas NEMEZIZ 20+ SUPERLATIVE
    231, --- adidas PREDATOR 21+ SUPERLATIVE
    232, --- adidas X GHOSTED+ SUPERLATIVE
    233, --- adidas NEMEZIZ MESSI.1
    234, --- adidas COPA MUNDIAL ETERNAL CLASS PT 2
    235, --- adidas COPA MUNDIAL PRIMEKNIT FG
    236, --- adidas PREDATOR ACCELERATOR ETERNAL CLASS PT 2
    237, --- adidas NEMEZIZ 20+ SUPERSPECTRAL
    238, --- adidas COPA 21+ SUPERSPECTRAL
    239, --- adidas PREDATOR 21+ SUPERSPECTRAL
    240, --- adidas X GHOSTED+ SUPERSPECTRAL
    241, --- adidas PREDATOR 21+ SHOWPIECE
    242, --- adidas X GHOSTED+ SHOWPIECE
    301, --- adidas PREDATOR PULSE UCL
    304, --- adidas F50 ADIZERO UCL
    305, --- mizuno Morelia WAVE CUP LEGEND
    306, --- mizuno Morelia ZERO
    307, --- PUMA King Pele
    308, --- PUMA King
    309, --- Nike CTR Maestri II
    310, --- Nike Hypervenom Phantom
    311, --- Nike Mercurial 98
    312, --- Nike Mercurial Vapor 02
    313, --- Nike Total 90 III
    504, --- Nike Tiempo Legend Elite - Black/Crimson
    505, --- Nike Vapor Elite - Wolf Grey
    506, --- Nike Neymar Vapor XII Silêncio
    507, --- adidas NEMEZIZ 19.1 302 REDIRECT
    508, --- adidas NEMEZIZ 19.1 HARD WIRED
    509, --- adidas PREDATOR 19.1 Black/Black/Matte Gold
    510, --- adidas Predator White and Gold
    511, --- adidas PREDATOR 19.1 HARD WIRED
    512, --- Nike Lunar Gato II
    513, --- Nike React Gato
    514, --- New Balance Audazo V4 Pro
    515, --- PUMA 365 Roma 1TT - NRGY Red/Rhubarb
    516, --- PUMA 365 Roma 1TT - Gray Dawn/NRGY Red
    517, --- umbro Chaleira 2 Pro - White/Black/Regal Blue
    518, --- umbro Chaleira 2 Pro - Lollipop
    519, --- umbro Chaleira 2 Pro - White
    520, --- PUMA Chasing Adrenaline ULTRA
    521, --- New Balance Audazo V5
    522, --- Nike Lunar Gato II - Bright
    523, --- Nike Lunar Gato II - Energy
    524, --- Nike React Gato - Bright Crimson/Black
    525, --- Nike Premier Sala
    526, --- Nike Tiempo Legend 8 Pro X
    527, --- adidas X GHOSTED.1 IN - White/Gold
    528, --- adidas X GHOSTED.1 IN - Signal Green/Energy Ink
    529, --- adidas PREDATOR MUTATOR+ IN
    530, --- adidas X GHOSTED.1 IN SUPERLATIVE
    531, --- adidas COPA SENSE.1 IN SALA SUPERSPECTRAL
    532, --- adidas COPA SENSE.1 IN SALA SUPERLATIVE
    533 --- adidas X GHOSTED.3 Turf LL
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
