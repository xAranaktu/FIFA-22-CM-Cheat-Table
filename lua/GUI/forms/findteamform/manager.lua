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

    self.found_teams = {}

    return o;
end

function thisFormManager:find_team_by_name(teamname)
    local arr_flds = {
        {
            name = "teamname",
            values = {teamname},
            is_string = true
        }
    }
    local addrs = self.game_db_manager:find_record_addr(
        "teams", arr_flds, 50 
    )
    return addrs
end

function thisFormManager:FindTeamSearchBtnOnClick(sender)
    local txt = self.frm.FindTeamEdit.Text
    local teamid = tonumber(txt)
    if teamid == nil then
        -- search for team name
        if string.len(txt) < 3 then
            showMessage("Input at least 3 characters or Team ID")
            return nil
        end
        self.found_teams = self:find_team_by_name(txt)
        for i=1, #self.found_teams do
            local addr = self.found_teams[i]
            local teamname = self.game_db_manager:get_table_record_field_value(addr, "teams", "teamname")
            local teamid = self.game_db_manager:get_table_record_field_value(addr, "teams", "teamid")
            team_string = string.format(
                '%s (ID: %d)',
                teamname,
                teamid
            )
            self.frm.FindTeamListBox.Items.Add(team_string)
        end
    else
        -- search for team id
        local team_addr = self:find_team_by_id(teamid)
        if team_addr <= 0 then
            local err_msg = string.format("Not found any team with ID %d", teamid)
            self.logger:error(err_msg, true)
            return nil
        else
            local team_editor_form_mgr = gCTManager:get_frm_mgr("teamseditor_form")
            team_editor_form_mgr:onShow(
                team_editor_form_mgr.frm,
                team_addr
            )
            self.frm.close()
        end
    end
end

function thisFormManager:FindTeamOkBtnClick(sender)
    if self.frm.FindTeamListBox.Items.Count <= 0 or self.frm.FindTeamListBox.ItemIndex < 0 then
        return
    end

    local team_addr = self.found_teams[self.frm.FindTeamListBox.ItemIndex+1]
    local team_editor_form_mgr = gCTManager:get_frm_mgr("teamseditor_form")
    team_editor_form_mgr:onShow(
        team_editor_form_mgr.frm,
        team_addr
    )
    self.frm.close()
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    self.frm.OnShow = function(sender)
        self.frm.FindTeamEdit.Text = "Enter team name or teamid..."
        self.frm.FindTeamListBox.clear()
    end

    self.frm.FindTeamEdit.OnClick = function(sender)
        sender.Text = ""
    end
    self.frm.FindTeamSearchBtn.OnClick = function(sender)
        self.found_teams = {}
        self.frm.FindTeamListBox.clear()
        self:FindTeamSearchBtnOnClick(sender)
    end

    self.frm.FindTeamOkBtn.OnClick = function(sender)
        self:FindTeamOkBtnClick(sender)
    end

    self.frm.FindTeamOkBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.FindTeamOkBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.FindTeamOkBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end
end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name
    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self.found_teams = {}

    self:assign_current_form_events()
end

return thisFormManager;