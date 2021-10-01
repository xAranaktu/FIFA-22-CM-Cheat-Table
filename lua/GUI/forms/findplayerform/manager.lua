require 'lua/consts';
require 'lua/helpers';

local FormManager = require 'lua/imports/FormManager';

local thisFormManager = FormManager:new()

function thisFormManager:new(o)
    o = o or FormManager:new(o)
    setmetatable(o, self)
    self.__index = self
    
    self.dirs = nil
    self.cfg = nil
    self.new_cfg = nil
    self.logger = nil

    self.frm = nil
    self.name = ""

    self.game_db_manager = nil
    self.memory_manager = nil

    self.addr_list = nil
    self.fnSaveCfg = nil
    self.new_cfg = {}
    self.has_unsaved_changes = false
    self.selection_idx = 0

    self.form_components_description = nil
    self.current_addrs = {}

    self.found_players = {}

    return o;
end

function thisFormManager:find_players_by_name(playername)
    local result = {}
    if type(playername) ~= 'string' then
        playername = tostring(playername)
    end

    if string.len(playername) < 3 then
        return result
    end
    playername = string.lower(playername)
    local cached_player_names = self.game_db_manager:get_cached_player_names()
    for key, value in pairs(cached_player_names) do
        if string.match(value['fullname'], playername) then
            local v = value
            v["playerid"] = key
            table.insert(result, v)
        end
    end
    return result
end

function thisFormManager:clear_search_for_player()
    self.frm.FindPlayerListBox.clear()
    self.found_players = {}
end


function thisFormManager:FindPlayerSearchBtnOnClick(sender)
    self:clear_search_for_player()

    local txt = self.frm.FindPlayerEdit.Text
    if tonumber(txt) == nil then
        -- search for team name
        if string.len(txt) < 3 then
            showMessage("Input at least 3 characters or Player ID")
            return 1
        end
        self.found_players = self:find_players_by_name(txt)
        if #self.found_players <= 0 then
            self.logger:error(string.format("Player %s not found", txt))
            return 1
        end

        local player_addr = nil
        local player_string = ''
        for i=1, #self.found_players do
            player_string = string.format(
                '%s %s (ID: %d)',
                self.found_players[i]['firstname'],
                self.found_players[i]['surname'],
                self.found_players[i]['playerid']
            )
            self.frm.FindPlayerListBox.Items.Add(player_string)
        end
    else
        local playerid = tonumber(txt)
        local player_editor_form_mgr = gCTManager:get_frm_mgr("playerseditor_form")
        player_editor_form_mgr:onShow(
            player_editor_form_mgr.frm,
            self:find_player_by_id(playerid),
            self:find_player_club_team_record(playerid)
        )

        self:clear_search_for_player()
        self.frm.close()
    end
end

function thisFormManager:FindPlayerOkBtnClick(sender)
    if self.frm.FindPlayerListBox.Items.Count <= 0 or self.frm.FindPlayerListBox.ItemIndex < 0 then
        return
    end

    local playerid = self.found_players[self.frm.FindPlayerListBox.ItemIndex+1]["playerid"]

    local player_editor_form_mgr = gCTManager:get_frm_mgr("playerseditor_form")
    player_editor_form_mgr:onShow(
        player_editor_form_mgr.frm,
        self:find_player_by_id(playerid),
        self:find_player_club_team_record(playerid)
    )
    self.frm.close()
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    self.frm.OnShow = function(sender)
        self.frm.FindPlayerEdit.Text = "Enter name or ID..."
        self.frm.FindPlayerListBox.clear()
    end

    self.frm.FindPlayerEdit.OnClick = function(sender)
        sender.Text = ""
    end
    self.frm.FindPlayerSearchBtn.OnClick = function(sender)
        self:FindPlayerSearchBtnOnClick(sender)
    end

    self.frm.FindPlayerOkBtn.OnClick = function(sender)
        self:FindPlayerOkBtnClick(sender)
    end

    self.frm.FindPlayerOkBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.FindPlayerOkBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.FindPlayerOkBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end
end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name
    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self.found_players = {}

    self:assign_current_form_events()
end

return thisFormManager;