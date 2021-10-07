require 'lua/consts';
require 'lua/helpers';

local LIP = require 'lua/requirements/LIP';

local Logger = require 'lua/imports/logger';
local MemoryManager = require 'lua/imports/MemoryManager';
local GameDBManager = require 'lua/imports/GameDBManager';

local mainFormManager = require 'lua/GUI/forms/mainform/manager';
local settingsFormManager = require 'lua/GUI/forms/settingsform/manager';
local playersEditorFormManager = require 'lua/GUI/forms/playerseditorform/manager';
local teamsEditorFormManager = require 'lua/GUI/forms/teamseditorform/manager';
local findteamFormManager = require 'lua/GUI/forms/findteamform/manager';
local findplayerFormManager = require 'lua/GUI/forms/findplayerform/manager';
local transferplayersFormManager = require 'lua/GUI/forms/transferplayersform/manager';
local matchscheduleeditorFormManager = require 'lua/GUI/forms/matchscheduleeditorform/manager';
local matchfixingFormManager = require 'lua/GUI/forms/matchfixingform/manager';
local newmatchfixFormManager = require 'lua/GUI/forms/newmatchfixform/manager';

local TableManager = {}

function TableManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.logger = Logger:new()

    local save_offsets_callback = function(offsets)
       self:save_offsets(offsets)
    end
    
    self.memory_manager = MemoryManager:new(nil, self.logger, save_offsets_callback)
    self.game_db_manager = GameDBManager:new(nil, self.logger, self.memory_manager)

    self.FIFA_year = 22
    self.game_name = "FIFA 22"

    self.addr_list = getAddressList()

    self.proc_name = ""

    self.dirs = {}
    self.form_managers = {}
    self.cfg = {}
    self.offsets = {}
    self.ptrs = {}

    self.no_internet = false
    self.show_ce = true

    --timers
    self.auto_attach_timer = nil

    return o;
end

function TableManager:get_frm_mgr(key)
    return self.form_managers[key]
end

function TableManager:get_frm(key)
    return self:get_frm_mgr(key).frm
end

function TableManager:execute_cmd(cmd)
    self.logger:info(string.format('execute cmd -  %s', cmd))
    local p = assert(io.popen(cmd))
    local result = p:read("*all")
    p:close()
    if result then
        self.logger:info(string.format('execute cmd result -  %s', result))
    end
end

function TableManager:delete_directory(dir)
    self:execute_cmd(string.format('rmdir /s /q "%s"', dir))
end

function TableManager:create_dirs()
    local d_dir = string.gsub(self.dirs["DATA"], "/","\\")
    local fifa_sett_dir = string.gsub(self.dirs["CACHE"], "/","\\")
    local cmds = {
        "mkdir " .. '"' .. d_dir .. '"',
        "ECHO A | xcopy cache " .. '"' .. fifa_sett_dir .. '" /E /i',
    }
    for i=1, #cmds do
        self:execute_cmd(cmds[i])
    end

end

function TableManager:get_ct_ver()
    local ver = string.gsub(self.addr_list.getMemoryRecordByID(0).Description, 'v', '')
    return ver
end

function TableManager:check_for_ct_update()
    local new_version_is_available = false
    local r = getInternet()
    local version = r.getURL(URL_LINKS.VERSION)
    r.destroy()

    if version == nil then
        self.no_internet = true
        self.logger:warning("CT Update check failed. No internet?")
        return false
    end

    local patrons_version = version:sub(1,8)
    if (not patrons_version) then return false end

    local free_version = version:sub(9,17)
    if (not free_version) then return false end

    self.logger:info(string.format(
        "Patrons ver -  %s, free ver - %s", patrons_version, free_version
    ))

    local ipatronsver, _ = string.gsub(
        patrons_version, '%.', ''
    )
    ipatronsver = tonumber(ipatronsver)
    if (not ipatronsver) then return false end

    local ifreever, _ = string.gsub(
        free_version, '%.', ''
    )
    ifreever = tonumber(ifreever)
    if (not ifreever) then return false end

    local current_ver = self:get_ct_ver()
    local icurver, _ = string.gsub(
        current_ver, '%.', ''
    )
    icurver = tonumber(icurver)
    if (not icurver) then return false end

    if self.cfg.flags.only_check_for_free_update then
        if self.cfg.other.ignore_update == free_version then
            return false
        end
        if ifreever > icurver then
            LATEST_VER = free_version
            self:get_frm("main_form").LabelLatestLEVer.Caption = string.format(
                "(Latest: %s)", LATEST_VER
            )
            self:get_frm("main_form").LabelLatestLEVer.Visible = true
            return true
        end
    else
        if (ifreever > icurver) or (ipatronsver > icurver) then
            if self.cfg.other.ignore_update == patrons_version then
                return false
            end
            LATEST_VER = patrons_version
            self:get_frm("main_form").LabelLatestLEVer.Caption = string.format(
                "(Latest: %s)", LATEST_VER
            )
            self:get_frm("main_form").LabelLatestLEVer.Visible = true
            return true
        end
    end

end

function TableManager:version_check()
    local ce_version = getCEVersion()
    self.logger:info(string.format('Cheat engine version: %f', ce_version))
    self:get_frm("main_form").LabelCEVer.Caption = ce_version

    local ct_ver = self:get_ct_ver()
    self.logger:info(string.format('Cheat Table version: %s', ct_ver))
    self:get_frm("main_form").LabelLEVer.Caption = ct_ver
end

function TableManager:get_forms_map()
    return {
        main_form = {
            mgr = mainFormManager,
            frm = MainWindowForm
        },
        settings_form = {
            mgr = settingsFormManager,
            frm = SettingsForm
        },
        playerseditor_form = {
            mgr = playersEditorFormManager,
            frm = PlayersEditorForm
        },
        teamseditor_form = {
            mgr = teamsEditorFormManager,
            frm = TeamsEditorForm
        },
        findteam_form = {
            mgr = findteamFormManager,
            frm = FindTeamForm
        },
        findplayer_form = {
            mgr = findplayerFormManager,
            frm = FindPlayerForm
        },
        transferplayers_form = {
            mgr = transferplayersFormManager,
            frm = TransferPlayersForm
        },
        matchscheduleeditor_form = {
            mgr = matchscheduleeditorFormManager,
            frm = MatchScheduleEditorForm
        },
        matchfixing_form = {
            mgr = matchfixingFormManager,
            frm = MatchFixingForm
        },
        newmatchfix_form = {
            mgr = newmatchfixFormManager,
            frm = NewMatchFixForm
        },
    }
end

function TableManager:setup_forms()
    local forms_map = self:get_forms_map()

    local dirs_cpy = deepcopy(self.dirs)
    local fnSaveCfg = function(cfg)
        self:save_cfg(cfg)
    end

    mainFormManager.dirs = dirs_cpy 

    settingsFormManager.dirs = dirs_cpy
    settingsFormManager.fnSaveCfg = fnSaveCfg

    playersEditorFormManager.dirs = dirs_cpy
    playersEditorFormManager.game_db_manager = self.game_db_manager
    playersEditorFormManager.memory_manager = self.memory_manager

    teamsEditorFormManager.dirs = dirs_cpy
    teamsEditorFormManager.game_db_manager = self.game_db_manager
    teamsEditorFormManager.memory_manager = self.memory_manager

    transferplayersFormManager.dirs = dirs_cpy
    transferplayersFormManager.game_db_manager = self.game_db_manager
    transferplayersFormManager.memory_manager = self.memory_manager

    findteamFormManager.game_db_manager = self.game_db_manager
    findteamFormManager.memory_manager = self.memory_manager

    findplayerFormManager.game_db_manager = self.game_db_manager
    findplayerFormManager.memory_manager = self.memory_manager

    matchscheduleeditorFormManager.dirs = dirs_cpy
    matchscheduleeditorFormManager.game_db_manager = self.game_db_manager
    matchscheduleeditorFormManager.memory_manager = self.memory_manager

    matchfixingFormManager.dirs = dirs_cpy
    matchfixingFormManager.game_db_manager = self.game_db_manager
    matchfixingFormManager.memory_manager = self.memory_manager
    matchfixingFormManager.fnSaveCfg = fnSaveCfg

    newmatchfixFormManager.dirs = dirs_cpy
    newmatchfixFormManager.game_db_manager = self.game_db_manager
    newmatchfixFormManager.memory_manager = self.memory_manager

    for k, v in pairs(forms_map) do
        self.form_managers[k] = v.mgr
        self.logger:debug(string.format("%s manager setup", k))
        v.mgr:setup({
            name=k,
            frm_obj=v.frm,
            logger=self.logger
        })
    end
end

function TableManager:style_forms()
    local forms_map = self:get_forms_map()

    for k, v in pairs(forms_map) do
        self:get_frm_mgr(k):style_form()
    end
end

function TableManager:initialize()
    self.logger:info("================================")
    self.logger:info("=========== INITIALIZE =========")
    self.logger:info("================================")
    if (not cheatEngineIs64Bit()) then
        local critical_error = "Run 64-bit version of cheat engine (cheatengine-x86_64.exe)"
        self.logger:critical(critical_error)
        assert(false, critical_error)
    end

    -- DEFAULT GLOBALS, better leave it as is
    local env_homedrive = os.getenv('HOMEDRIVE')
    local env_systemdrive = os.getenv('SystemDrive')
    local env_username = os.getenv('USERNAME')

    if env_homedrive then
        self.logger:info("os.getenv('HOMEDRIVE') " .. env_homedrive)
    else
        self.logger:info('No HOMEDRIVE env var')
    end
    if env_systemdrive then
        self.logger:info("os.getenv('SystemDrive') " .. env_systemdrive)
    else
        self.logger:info('No SystemDrive env var')
    end
    self.dirs["HOMEDRIVE"] = env_homedrive or env_systemdrive or 'C:'
    self.logger:info(string.format("HOMEDRIVE: %s", self.dirs["HOMEDRIVE"]))

    self.dirs["FIFA_SETTINGS"] = string.format(
        "%s/Users/%s/Documents/FIFA %s/",
        self.dirs["HOMEDRIVE"], env_username, self.FIFA_year
    );

    self.dirs["DATA"] = self.dirs["FIFA_SETTINGS"] .. 'Cheat Table/data/';
    self.dirs["CACHE"] = self.dirs["FIFA_SETTINGS"] .. 'Cheat Table/cache/';

    self.dirs["CONFIG_FILE"] = self.dirs["DATA"] .. 'config.ini';
    self.dirs["OFFSETS_FILE"] = self.dirs["DATA"] .. 'offsets.ini';

    self.cfg = self:load_config()
    if (self.cfg.flags == nil) then
        local critical_error = "\nError!\nCorrupted config.ini\nTo solve this problem:\n1. Turn Off FIFA and Cheat Engine\n2. Go to Documents -> FIFA 22 -> Cheat Table -> data\n3. Delete the config.ini file"
        self.logger:critical(critical_error)
        assert(false, critical_error)
    end
    DEBUG_MODE = self.cfg.flags.debug_mode
    self.offsets = self:load_offsets()

    self:setup_forms()
end

-- function TableManager:hide_mem_scanner()
--     local main_form = getMainForm()

--     -- local min_h = 378 -- default one

--     main_form.Panel5.Constraints.MinHeight = 65
--     main_form.Panel5.Height = 65


--     -- Works for Cheat Engine 6.8.1
--     local comps = {
--         "Label6", "foundcountlabel", "sbOpenProcess", "lblcompareToSavedScan",
--         "ScanText", "lblScanType", "lblValueType", "SpeedButton2", "btnNewScan",
--         "gbScanOptions", "Panel2", "Panel3", "Panel6", "Panel7", "Panel8",
--         "btnNextScan", "ScanType", "VarType", "ProgressBar", "UndoScan",
--         "scanvalue", "btnFirst", "btnNext", "LogoPanel", "pnlScanValueOptions",
--         "Panel9", "Panel10", "Foundlist3", "SpeedButton3", "UndoScan"
--     }

--     for i=1, #comps do
--         if main_form[comps[i]] then
--             main_form[comps[i]].Visible = false
--         end
--     end
-- end


function TableManager:can_autoactivate(script_id)
    local not_allowed_to_aa = {
        2998  -- "Generate new report" script, it's internal call and will cause crash when activated in Main Menu
    }

    for i=1, #not_allowed_to_aa do
        if not_allowed_to_aa[i] == script_id then
            return false
        end
    end
    return true
end

function TableManager:setup_internal_calls()
    local funcGenReportaddr = self.memory_manager:get_validated_address("fnGenYAReport")
    if not funcGenReportaddr then return end

    funcGenReportaddr = tonumber(funcGenReportaddr, 16)

    -- print(string.format("%X", funcGenReportaddr))
    writeQword("funcGenReport", funcGenReportaddr)
end

function TableManager:init_ptrs()
    local base_ptr = self.memory_manager:get_validated_resolved_ptr("DatabaseBasePtr", 4)
    self.logger:debug(string.format("DatabaseBasePtr %X", base_ptr))

    local DB_One_Tables_ptr = self.memory_manager:read_multilevel_pointer(readPointer(base_ptr), {0x10, 0x390})
    local DB_Two_Tables_ptr = self.memory_manager:read_multilevel_pointer(readPointer(base_ptr), {0x10, 0x3C0})
    local DB_Three_Tables_ptr = self.memory_manager:read_multilevel_pointer(readPointer(base_ptr), {0x10, 0x3F0})

    self.logger:debug(string.format("DB_One_Tables_ptr %X", DB_One_Tables_ptr))
    self.logger:debug(string.format("DB_Two_Tables_ptr %X", DB_Two_Tables_ptr))
    self.logger:debug(string.format("DB_Three_Tables_ptr %X", DB_Three_Tables_ptr))

    -- Bruteforce
    -- local base_ptr = gCTManager.memory_manager:get_validated_resolved_ptr("DatabaseBasePtr", 4)
    -- local one = gCTManager.memory_manager:read_multilevel_pointer(readPointer(base_ptr), {0x10, 0x390})
    -- local two = gCTManager.memory_manager:read_multilevel_pointer(readPointer(base_ptr), {0x10, 0x3C0})
    -- local three = gCTManager.memory_manager:read_multilevel_pointer(readPointer(base_ptr), {0x10, 0x3F0})
    -- local sh_n = {
    --     CZUM = "players",
    --     bneD = "dcplayernames",
    --     nQVU = "editedplayernames",
    --     RrqT = "teamplayerlinks",
    --     lyxL = "teams",
    --     qdZF = "leagueteamlinks",
    --     Knen = "manager",
    --     GJUr = "career_calendar",
    --     DvsP = "career_playercontract",
    --     mPrV = "career_users",
    --     AGmV = "default_teamsheets",
    --     ONtg = "default_mentalities"
    -- }
    -- 
    -- local bruteforce_find = {
    --     "CZUM",
    --     "bneD",
    --     "nQVU",
    --     "RrqT",
    --     "lyxL",
    --     "qdZF",
    --     "Knen",
    --     "GJUr",
    --     "DvsP",
    --     "mPrV",
    --     "AGmV",
    --     "ONtg"
    -- }
    -- 
    -- 
    -- local xxx = 0
    -- local yyy = 0
    -- local taddr = 0
    -- 
    -- xxx = 0
    -- yyy = 0
    -- print("one")
    -- taddr = one
    -- for i=1, 1024 do
    --     local shortname = readString(readPointer(taddr + xxx) + 0x14, 4)
    --     if shortname ~= nil then
    --         yyy = gCTManager.memory_manager:read_multilevel_pointer(taddr, {xxx, 0x28, 0x30})
    --         for zzz=1, #bruteforce_find do
    --             if bruteforce_find[zzz] == shortname then
    --                 gCTManager.logger:debug(string.format("%s %X iiii -> 0x%X", sh_n[shortname], yyy,  xxx))
    --             end
    --         end
    --     end
    -- 
    --     xxx = xxx + 8
    -- end
    -- 
    -- xxx = 0
    -- yyy = 0
    -- print("two")
    -- taddr = two
    -- for i=1, 1024 do
    --     local shortname = readString(readPointer(taddr + xxx) + 0x14, 4)
    --     if shortname ~= nil then
    --         yyy = gCTManager.memory_manager:read_multilevel_pointer(taddr, {xxx, 0x28, 0x30})
    --         for zzz=1, #bruteforce_find do
    --             if bruteforce_find[zzz] == shortname then
    --                 gCTManager.logger:debug(string.format("%s %X iiii -> 0x%X", sh_n[shortname], yyy,  xxx))
    --             end
    --         end
    --     end
    -- 
    --     xxx = xxx + 8
    -- end
    -- 
    -- xxx = 0
    -- yyy = 0
    -- print("three")
    -- taddr = three
    -- for i=1, 1024 do
    --     local shortname = readString(readPointer(taddr + xxx) + 0x14, 4)
    --     if shortname ~= nil then
    --         yyy = gCTManager.memory_manager:read_multilevel_pointer(taddr, {xxx, 0x28, 0x30})
    --         for zzz=1, #bruteforce_find do
    --             if bruteforce_find[zzz] == shortname then
    --                 gCTManager.logger:debug(string.format("%s %X iiii -> 0x%X", sh_n[shortname], yyy,  xxx))
    --             end
    --         end
    --     end
    -- 
    --     xxx = xxx + 8
    -- end

    self.game_db_manager:add_table(
        "manager",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x80, 0x28}),
        {"pManagerTableCurrentRecord", "pManagerTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "players",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0xC8, 0x28}),
        {"pPlayersTableCurrentRecord", "pPlayersTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "teams",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0xF8, 0x28}),
        {"pTeamsTableCurrentRecord", "pTeamsTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "editedplayernames",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x108, 0x28}),
        {"pEditedplayernamesTableCurrentRecord", "pEditedplayernamesTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "default_teamsheets",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x138, 0x28}),
        {"pDefaultteamsheetsTableCurrentRecord", "pDefaultteamsheetsTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "teamplayerlinks",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x148, 0x28}),
        {"pTeamplayerlinksTableCurrentRecord", "pTeamplayerlinksTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "dcplayernames",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x160, 0x28}),
        {"pDcplayernamesTableCurrentRecord", "pDcplayernamesTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "leagueteamlinks",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x170, 0x28}),
        {"pLeagueteamlinksTableCurrentRecord", "pLeagueteamlinksTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "default_mentalities",
        self.memory_manager:read_multilevel_pointer(DB_One_Tables_ptr, {0x198, 0x28}),
        {"pDefaultmentalitiesTableCurrentRecord", "pDefaultmentalitiesTableFirstRecord"}
    )

    ----------

    self.game_db_manager:add_table(
        "career_playercontract",
        self.memory_manager:read_multilevel_pointer(DB_Two_Tables_ptr, {0x20, 0x28}),
        {"pCareerPlayercontractTableCurrentRecord", "pCareerPlayercontractTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "career_users",
        self.memory_manager:read_multilevel_pointer(DB_Two_Tables_ptr, {0x40, 0x28}),
        {"pUsersTableCurrentRecord", "pUsersTableFirstRecord"}
    )

    self.game_db_manager:add_table(
        "career_calendar",
        self.memory_manager:read_multilevel_pointer(DB_Two_Tables_ptr, {0xB0, 0x28}),
        {"pCareerCalendarTableCurrentRecord", "pCareerCalendarTableFirstRecord"}
    )

    ----------

    local loc_pModeManagers = self.memory_manager:get_validated_resolved_ptr("pModeManagers", 3) or 0
    self.logger:debug(string.format("pModeManagers %X", loc_pModeManagers))
    writeQword("pModeManagers", loc_pModeManagers)

    if loc_pModeManagers > 0 then
        self.logger:debug(string.format(
            "form_ptr %X",
            get_mode_manager_impl_ptr("PlayerFormManager")
        ))
        self.logger:debug(string.format(
            "rlc_ptr %X",
            get_mode_manager_impl_ptr("PlayerContractManager")
        ))
        self.logger:debug(string.format(
            "morale_ptr %X",
            get_mode_manager_impl_ptr("PlayerMoraleManager")
        ))
        self.logger:debug(string.format(
            "pgs_ptr %X", 
            get_mode_manager_impl_ptr("PlayerGrowthManager")
        ))
    end
end

function TableManager:autoactivate_scripts()
    local always_activate = {
        14, -- Globals
        18, -- Scripts
        214 -- Hidden FIFA DB Tables
    }

    for i=1, #always_activate do
        local script_id = always_activate[i]
        local script_record = self.addr_list.getMemoryRecordByID(script_id)
        self.logger:info(string.format('Activating %s (%d)', script_record.Description, script_id))
        script_record.Active = true
    end

    for i=1, #self.cfg.auto_activate do
        local script_id = self.cfg.auto_activate[i]
        if self:can_autoactivate(script_id) then
            local script_record = self.addr_list.getMemoryRecordByID(script_id)
            if script_record then
                self.logger:info(string.format('Activating %s (%d)', script_record.Description, script_id))
                if not script_record.Active then
                    script_record.Active = true
                end
            end
        end
    end
end

function TableManager:file_exists(name)
    local f, err = io.open(name,"r")
    if f then
        io.close(f)
        sleep(250)
        return true
    else
        self.logger:warning(
            string.format("file_exists (%s) error %s", name, err or "")
        )
        return false
    end
end

function TableManager:save_cfg(cfg)
    if cfg == nil then 
        cfg = self.cfg 
    end

    if cfg == nil then return end

    self.logger:info(string.format(
        "Saving Config to %s", self.dirs["CONFIG_FILE"]
    ))
    LIP.save(self.dirs["CONFIG_FILE"], cfg);
    self.cfg = cfg
end

function TableManager:save_offsets(offsets)
    if not offsets or not offsets.offsets then
        offsets = {
            offsets = offsets
        }
    end

    self.logger:info(string.format(
        "Saving Offsets to %s", self.dirs["OFFSETS_FILE"]
    ))

    LIP.save(self.dirs["OFFSETS_FILE"], offsets);
end

function TableManager:update_offsets()
    for k,v in pairs(AOB_PATTERNS) do
        if type(v) == 'string' then
            -- main FIFA module
            self.memory_manager:update_offset(k, true)
        else
            -- DLC Module
            local module_name = v['MODULE_NAME']
            local module_size = getModuleSize(module_name)
            for kk, vv in pairs(v['AOBS']) do
                self.memory_manager:update_offset(kk, true, module_name, module_size, k)
            end
        end
    end
end


function TableManager:load_offsets()
    if self:file_exists(self.dirs["OFFSETS_FILE"]) then
        self.logger:info(string.format(
            'Loading OFFSETS_DATA from %s', self.dirs["OFFSETS_FILE"]
        ))
        local offsets = LIP.load(self.dirs["OFFSETS_FILE"])
        return offsets;
    else
        self.logger:info(string.format(
            'Offsets file not found at %s - loading default data', self.dirs["OFFSETS_FILE"]
        ))
        local data =
        {
            offsets =
            {
                AltTab = nil,
            },
        };
        LIP.save(self.dirs["OFFSETS_FILE"], data);
        return data
    end
end

function TableManager:load_config()
    if self:file_exists("config.ini") then
        -- Use files from cwd
        self.logger:info("Using cwd Config");
        self.dirs["CACHE"] = 'cache/';
        self.dirs["OFFSETS_FILE"] = "offsets.ini";
        self.dirs["CONFIG_FILE"] = "config.ini";
    elseif not self:file_exists(self.dirs["CONFIG_FILE"]) then
        local data = DEFAULT_CFG
        data.directories.cache_dir = self.dirs["CACHE"]
        self:create_dirs()
        local status, err = pcall(LIP.save, self.dirs["CONFIG_FILE"], data)
        self.logger:info(string.format(
            'cfg file not found at %s - loading default data', self.dirs["CONFIG_FILE"])
        )
        if not status then
            self.logger:error(
                string.format('LIP.SAVE FAILED for %s with err: %s', self.dirs["CONFIG_FILE"], err)
            )
            self.dirs["CACHE"] = 'cache/'
            self.dirs["OFFSETS_FILE"] = "offsets.ini"
            self.dirs["CONFIG_FILE"] = "config.ini"
            data.directories.cache_dir = self.dirs["CACHE"]
            local status, err = pcall(LIP.save, self.dirs["CONFIG_FILE"], data)
        end
    end

    if self:file_exists(self.dirs["CONFIG_FILE"]) then
        self.logger:info(
            string.format('Loading CFG_DATA from %s', self.dirs["CONFIG_FILE"])
        )
        local cfg = LIP.load(self.dirs["CONFIG_FILE"]);

        return cfg
    else
        return DEFAULT_CFG
    end
end

function TableManager:get_screen_id()
    local ptr = self.ptrs["screen_id"]

    return readString(readPointer(ptr))
end

function TableManager:log_screen_id()
    local screen_id = self:get_screen_id()

    if not screen_id then
        self.logger:info("Current Screen: nil")
    else
        self.logger:info(string.format("Current Screen: %s", screen_id))
    end
end

function TableManager:on_attach_to_process()
    local main_frm_mgr = self:get_frm_mgr("main_form")
    main_frm_mgr:update_status("Attached to the game process.")

    if self.cfg.flags.check_for_update then
        self:check_for_ct_update()
    end
    sleep(1000)

    self.ptrs["screen_id"] = self.memory_manager:get_validated_resolved_ptr("ScreenID", 3)
    self:log_screen_id()

    self.logger:info("Waiting for valid screen")
    while self:get_screen_id() == nil do
        showMessage('You are not in main menu in game. Enter there and close this window')
        sleep(1500)
    end
    self:log_screen_id()

    -- Generate offsets.ini with all offsets.
    --self:update_offsets()
    self.game_db_manager:load_playernames()
    self:save_cfg()
    self:autoactivate_scripts()
    self:init_ptrs()
    self:setup_internal_calls()

    self:style_forms()

    main_frm_mgr:remove_loading_panel()
    main_frm_mgr:load_images()

    getMainForm().Visible = true

    local success_msg = "Ready to use."
    self.logger:info(success_msg)
    main_frm_mgr:update_status(success_msg)
    showMessage(success_msg)
end

function TableManager:auto_attach_to_process()
    local proc_name = self.cfg.game.name
    local trial_name = self.cfg.game.name_trial

    if not proc_name and not trial_name then
        local critical_error = "Auto attach error. No proc name. Problem with config.ini?"
        self.logger:critical(critical_error)
        assert(false, critical_error)
    end

    if getProcessIDFromProcessName(proc_name) ~= nil then
        openProcess(proc_name)
    elseif getProcessIDFromProcessName(trial_name) ~= nil then
        openProcess(trial_name)
    else
        return
    end

    local attached_to = getOpenedProcessName()
    local pid = getOpenedProcessID()
    if pid > 0 and attached_to ~= nil then
        timer_setEnabled(self.auto_attach_timer, false)
        self.logger:info(string.format(
            "Attached to %s (PID: %d)", attached_to, pid
        ))
        self.proc_name = attached_to

        self.memory_manager:set_proc(self.proc_name)
        self.memory_manager:set_offsets(self.offsets)
        self:on_attach_to_process()
    end
end

function TableManager:start()
    if getOpenedProcessID() ~= 0 then
        local critical_error = "Restart required, getOpenedProcessID() ~= 0. Dont open process in Cheat Engine. Cheat Table will do it automatically if you allow for lua code execution."
        self.logger:critical(critical_error)
        assert(false, critical_error)
    end

    local forms_map = self:get_forms_map()

    for k, v in pairs(forms_map) do
        self:get_frm_mgr(k):set_cfg(self.cfg)
    end

    -- if self.cfg.flags.hide_ce_scanner then
    --     self:hide_mem_scanner()
    -- end

    self:get_frm_mgr("main_form"):update_status(string.format("Waiting for %s...", self.game_name))

    -- show GUI
    self.addr_list.getMemoryRecordByID(CT_MEMORY_RECORDS['GUI_SCRIPT']).Active = true

    self:version_check()

    local timer_callback = function()
        self:auto_attach_to_process()
    end

    self.logger:info("Searching for game process")

    self.auto_attach_timer = createTimer(nil)
    -- Without timer our GUI will not be displayed
    timer_onTimer(self.auto_attach_timer, timer_callback)
    timer_setInterval(self.auto_attach_timer, 2000)
    timer_setEnabled(self.auto_attach_timer, true)
end

return TableManager;