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

    self.fill_timer = nil
    self.form_components_description = nil
    self.current_addrs = {}
    self.tab_panel_map = {}
    self.incidents = {}

    return o;
end

function thisFormManager:clear_custom_incident_containers()
    for i=0, self.frm.MatchIncidentsScroll.ComponentCount-1 do
        self.frm.MatchIncidentsScroll.Component[0].destroy()
    end
end


function thisFormManager:onShow(sender)
    self.logger:debug(string.format("onShow: %s", self.name))

    self.incidents = {
        SCORE = {
            TOTAL = 0,
            UNIQUE_SCORERS = 0,
            SCORERS = {},
            ASSISTS = {}
        },
    }

    self.frm.NewIncidentContainer.Visible = false
    self.frm.HomeTeamIDEdit.Text = "Home Team ID"
    self.frm.HomeScoreEdit.Text = "0"
    self.frm.AwayTeamIDEdit.Text = "Away Team ID"
    self.frm.AwayScoreEdit.Text = "0"
    self.frm.GoalScorerEdit.Text = "PlayerID..."
    self.frm.GoalAssistEdit.Text = "PlayerID..."
    self.frm.IncidentTypeCB.ItemIndex = 0

    -- TODO Assists
    self.frm.GoalAssistEdit.Visible = false
    self.frm.GoalAssistLabel.Visible = false

    local ss_c = self:load_crest(nil)
    self.frm.HomeTeamCrest.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
    ss_c = self:load_crest(nil)
    self.frm.AwayTeamCrest.Picture.LoadFromStream(ss_c)
    ss_c.destroy()

    self:clear_custom_incident_containers()
end

function thisFormManager:create_custom_incident_container(i)
    -- Container
    local custom_incident_container = createPanel(self.frm.MatchIncidentsScroll)
    custom_incident_container.Name = string.format('CustomIncidentContainerPanel%d', i+1)
    custom_incident_container.BevelOuter = bvNone
    custom_incident_container.Caption = ''

    custom_incident_container.Color = '0x001B1A1A'
    custom_incident_container.Width = 330
    custom_incident_container.Height = 175
    custom_incident_container.Left = 0
    custom_incident_container.Top = 10 + 165*i

    -- Incident type label
    local available_incidents = {
        'Goal'
    }
    local incident_type_label = createLabel(custom_incident_container)
    incident_type_label.Name = string.format('IncidentTypeLabel%d', i+1)
    incident_type_label.Caption = available_incidents[self.frm.IncidentTypeCB.ItemIndex+1]
    incident_type_label.Visible = true
    incident_type_label.AutoSize = false
    incident_type_label.Left = 110
    incident_type_label.Height = 19
    incident_type_label.Width = 90
    incident_type_label.Top = 5
    incident_type_label.Font.Size = 12
    incident_type_label.Font.Color = '0xC0C0C0'
    incident_type_label.Alignment = 'taCenter'

    
    local playerid = tonumber(self.frm.GoalScorerEdit.Text)
    if playerid then
        local playeraddr = nil
        -- Headshot
        local headshot_img = createImage(custom_incident_container)

        if playerid >= 280000 then
            playeraddr = self:find_player_by_id(playerid)
        end
        
        local stream = self:load_headshot(
            playerid, playeraddr
        )
        headshot_img.Picture.LoadFromStream(stream)
        stream.destroy()
        
        headshot_img.Name = string.format('HeadshotImage%d', i+1)
        headshot_img.Left = 110
        headshot_img.Top = 35
        headshot_img.Height = 90
        headshot_img.Width = 90
        headshot_img.Stretch = true
    end

    local playerid_label = createLabel(custom_incident_container)
    playerid_label.Name = string.format('PlayerIDLabel%d', i+1)
    playerid_label.Caption = playerid
    playerid_label.Visible = true
    playerid_label.AutoSize = false
    playerid_label.Left = 110
    playerid_label.Height = 19
    playerid_label.Width = 90
    playerid_label.Top = 135
    playerid_label.Font.Size = 12
    playerid_label.Font.Color = '0xC0C0C0'
    playerid_label.Alignment = 'taCenter'

    self.incidents['SCORE']['UNIQUE_SCORERS'] = self.incidents['SCORE']['UNIQUE_SCORERS'] + 1
end

function thisFormManager:new_incident(i)
    local playerid = self.frm.GoalScorerEdit.Text
    for i=0, self.frm.MatchIncidentsScroll.ComponentCount-1 do
        local container = self.frm.MatchIncidentsScroll.Component[i]
        for j=0, container.ComponentCount-1 do
            local comp = container.Component[j]
            if comp.Name == string.format('PlayerIDLabel%d', i+1) then
                if comp.Caption == playerid then
                    local ngoals = 0
                    local iplayerid = tonumber(playerid)
                    for k=1, #self.incidents['SCORE']['SCORERS'] do
                        if self.incidents['SCORE']['SCORERS'][k] == iplayerid then
                            ngoals = ngoals + 1
                        end
                    end
                    container[string.format('IncidentTypeLabel%d', i+1)].Caption = string.format('Goal (%dx)', ngoals)
                    return true
                end
            end
        end
    end
    self:create_custom_incident_container(i)
end

function thisFormManager:onTeamIDChange(imgcomponent, teamid)
    local ss_c = self:load_crest(teamid)
    imgcomponent.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
end

function thisFormManager:onScoreChange()
    local htscore = tonumber(self.frm.HomeScoreEdit.Text)
    if htscore == nil then return false end

    local atscore = tonumber(self.frm.AwayScoreEdit.Text)
    if atscore == nil then return false end

    local sum = htscore + atscore
    if self.incidents['SCORE']['TOTAL'] >= 20 then
        self.frm.NewIncidentContainer.Visible = false
    elseif sum > 0 and self.incidents['SCORE']['TOTAL'] < sum then
        self.frm.NewIncidentContainer.Visible = true
    else
        self.frm.NewIncidentContainer.Visible = false
    end
end

function thisFormManager:AddNewIncident()
    table.insert(self.incidents['SCORE']['SCORERS'], tonumber(self.frm.GoalScorerEdit.Text))
    self:new_incident(self.incidents['SCORE']['UNIQUE_SCORERS'])
    self.incidents['SCORE']['TOTAL'] = self.incidents['SCORE']['TOTAL'] + 1
    self:onScoreChange()
end

function thisFormManager:ConfirmMatchFix()
    local gameid = readInteger("arr_fixedGamesData")
    local home_teamid = tonumber(self.frm.HomeTeamIDEdit.Text)
    if home_teamid == nil or home_teamid == 0 then
        home_teamid = 4294967295
    end

    local away_teamid = tonumber(self.frm.AwayTeamIDEdit.Text)
    if away_teamid == nil or away_teamid == 0 then
        away_teamid = 4294967295
    end

    local home_score = tonumber(self.frm.HomeScoreEdit.Text)
    local away_score = tonumber(self.frm.AwayScoreEdit.Text)

    writeInteger("arr_fixedGamesData", gameid + 1)

    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 4)),
        home_teamid
    )
    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 8)),
        away_teamid
    )
    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 12)),
        home_score
    )
    writeInteger(
        string.format('arr_fixedGamesData+%s', string.format('%X', (gameid) * 16 + 16)),
        away_score
    )

    writeInteger(
        string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172)),
        home_teamid
    )

    writeInteger(
        string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172 + 4)),
        away_teamid
    )

    writeInteger(
        string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172 + 8)),
        self.incidents['SCORE']['TOTAL']
    )
    
    local scorer_off = 12
    for i=1, 20 do
        writeInteger(
            string.format('arr_fixedGoals+%s', string.format('%X', (gameid) * 172 + scorer_off)),
            self.incidents['SCORE']['SCORERS'][i] or 0
        )
        scorer_off = scorer_off + 8
    end

    self.frm.close()
    MatchFixingForm.show()
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    -- self.frm.OnClose = function(sender)
    --     self.frm.close()
    --     MatchFixingForm.show()
    -- end

    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    self.frm.HomeTeamIDEdit.OnClick = function(sender)
        if tonumber(sender.Text) == nil then
            sender.Text = ""
        end
    end
    self.frm.HomeTeamIDEdit.OnChange = function(sender)
        local teamid = tonumber(sender.Text)
        if teamid == nil then 
            teamid = 4294967295
        end

        self:onTeamIDChange(self.frm.HomeTeamCrest, teamid)
    end
    self.frm.AwayTeamIDEdit.OnChange = function(sender)
        local teamid = tonumber(sender.Text)
        if teamid == nil then 
            teamid = 4294967295
        end

        self:onTeamIDChange(self.frm.AwayTeamCrest, teamid)
    end
    self.frm.AwayTeamIDEdit.OnClick = function(sender)
        if tonumber(sender.Text) == nil then
            sender.Text = ""
        end
    end
    self.frm.GoalScorerEdit.OnClick = function(sender)
        sender.Text = ""
    end
    self.frm.HomeScoreEdit.OnClick = function(sender)
        sender.Text = ""
    end
    self.frm.HomeScoreEdit.OnChange = function(sender)
        self:onScoreChange()
    end
    self.frm.AwayScoreEdit.OnClick = function(sender)
        sender.Text = ""
    end
    self.frm.AwayScoreEdit.OnChange = function(sender)
        self:onScoreChange()
    end

    self.frm.NewIncidentButton.OnClick = function(sender)
        self:AddNewIncident()
    end

    self.frm.ConfirmBtn.OnClick = function(sender)
        self:ConfirmMatchFix()
    end

    self.frm.NewIncidentButton.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end
    self.frm.NewIncidentButton.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end
    self.frm.NewIncidentButton.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.ConfirmBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end
    self.frm.ConfirmBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end
    self.frm.ConfirmBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    
end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.incidents = {}
    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self:assign_current_form_events()
end

return thisFormManager;