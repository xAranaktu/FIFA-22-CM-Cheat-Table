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

    self.fav_teams_limit = 60
    self.fav_scorers_limit = 100

    self.after_delete_timer = nil
    self.form_components_description = nil
    self.current_addrs = {}
    self.tab_panel_map = {}

    return o;
end
function thisFormManager:need_match_fixing_sync()
    if readInteger("arr_fixedGamesData") == self.frm.MatchFixingScroll.ComponentCount then
        return false
    end
    return true
end

function thisFormManager:clear_fav_teams_containers()
    for i=0, self.frm.MatchFixingFavScroll.ComponentCount-1 do
        self.frm.MatchFixingFavScroll.Component[0].destroy()
    end
end
function thisFormManager:clear_match_fixing_containers()
    for i=0, self.frm.MatchFixingScroll.ComponentCount-1 do
        self.frm.MatchFixingScroll.Component[0].destroy()
    end
end
function thisFormManager:clear_fav_scorers_containers()
    for i=0, self.frm.MatchFixingFavScorersScroll.ComponentCount-1 do
        self.frm.MatchFixingFavScorersScroll.Component[0].destroy()
    end
end

function thisFormManager:call_after_delete_fav_team()
    timer_setEnabled(self.after_delete_timer, false)
    self.after_delete_timer = nil
    self:clear_fav_teams_containers()
    self:create_fav_teams_containers()
    self.logger:info("Deleted team from favourite teams")
end

function thisFormManager:delete_fav_team(sender)
    if messageDialog("Are you sure you want to delete this team from your favourite teams?", mtInformation, mbYes,mbNo) == mrNo then
        return false
    end

    local fncall_after = function()
        self:call_after_delete_fav_team()
    end

    local fav_teams = readInteger("arr_fixedGamesAlwaysWin")
    local id, _ = string.gsub(sender.Name, "%D", '')
    id = tonumber(id)

    if type(self.cfg.fav_teams) == 'table' then
        local tid = tonumber(
            self.frm.MatchFixingFavScroll[string.format('FavTeamContainerPanel%d', id)][string.format('FavTeamIDLabel%d', id)].Caption
        )
        local new_fav_teams = {}
        for i, val in ipairs(self.cfg.fav_teams) do
            if val ~= tid then
                table.insert(new_fav_teams, val)
            end
        end
        self.cfg.fav_teams = new_fav_teams
        self.fnSaveCfg(self.cfg)
    end

    local bytecount = ((fav_teams - id) * 4) + 4
    local bytes = readBytes(string.format('arr_fixedGamesAlwaysWin+%s', string.format('%X', id * 4 + 4)), bytecount, true)
    writeBytes(string.format('arr_fixedGamesAlwaysWin+%s', string.format('%X', id * 4)), bytes)

    writeInteger("arr_fixedGamesAlwaysWin", fav_teams-1)
    self.after_delete_timer = createTimer(nil)
    timer_onTimer(self.after_delete_timer, fncall_after)
    timer_setInterval(self.after_delete_timer, 250)
    timer_setEnabled(self.after_delete_timer, true)
end

function thisFormManager:create_fav_teams_container(i, teamid)
    local fnDelete_fav_team = function(sender)
        self:delete_fav_team(sender)
    end

    local max_in_row = 8
    -- Container
    local row = i//max_in_row
    local row_i = (i - max_in_row * row)

    local fav_team_container = createPanel(self.frm.MatchFixingFavScroll)
    fav_team_container.Name = string.format('FavTeamContainerPanel%d', i+1)
    fav_team_container.BevelOuter = bvNone
    fav_team_container.Caption = ''

    fav_team_container.Color = '0x001B1A1A'
    fav_team_container.Width = 100
    fav_team_container.Height = 100
    fav_team_container.Left = 10 + 100*row_i
    fav_team_container.Top = 10 + 110*row
    fav_team_container.OnClick = fnDelete_fav_team

    -- Team Badge
    if teamid == nil then
        teamid = readInteger(string.format('arr_fixedGamesAlwaysWin+%s', string.format('%X', i * 4 + 4)))
    end

    local badgeimg = createImage(fav_team_container)
    local ss_c = self:load_crest(teamid)
    badgeimg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()

    badgeimg.Name = string.format('FavTeamImage%d', i+1)
    badgeimg.Cursor = "crHandPoint"
    badgeimg.Left = 12
    badgeimg.Top = 0
    badgeimg.Height = 75
    badgeimg.Width = 75
    badgeimg.Stretch = true
    badgeimg.OnClick = fnDelete_fav_team

    -- TeamID
    local teamid_label = createLabel(fav_team_container)
    teamid_label.Name = string.format('FavTeamIDLabel%d', i+1)
    teamid_label.Visible = true
    teamid_label.Caption = teamid
    teamid_label.AutoSize = false
    teamid_label.Width = 100
    teamid_label.Height = 19
    teamid_label.Left = 0
    teamid_label.Top = 80
    teamid_label.Font.Size = 11
    teamid_label.Font.Color = '0xC0C0C0'
    teamid_label.Alignment = 'taCenter'
    teamid_label.Cursor = "crHandPoint"
    teamid_label.OnClick = fnDelete_fav_team
end

function thisFormManager:create_fav_teams_containers()
    local fav_teams = readInteger("arr_fixedGamesAlwaysWin")

    if fav_teams <= 0 then
        return false
    end

    for i=0, fav_teams-1 do
        self:create_fav_teams_container(i)
    end
end

function thisFormManager:call_after_delete_fixed_match()
    timer_setEnabled(self.after_delete_timer, false)
    self.after_delete_timer = nil
    self:clear_match_fixing_containers()
    self:create_match_fixing_containers()
end

function thisFormManager:delete_match_fix(sender)
    local fncall_after_delete_fixed_match = function()
        self:call_after_delete_fixed_match()
    end
    if self:need_match_fixing_sync() then
        ShowMessage("Close this and try again after 2s.")
        self.after_delete_timer = createTimer(nil)
        timer_onTimer(self.after_delete_timer, fncall_after_delete_fixed_match)
        timer_setInterval(self.after_delete_timer, 250)
        timer_setEnabled(self.after_delete_timer, true)
        return
    end

    if messageDialog("Are you sure you want to delete this match fix?", mtInformation, mbYes,mbNo) == mrNo then
        return
    end

    local num_of_fixed_fixtures = readInteger("arr_fixedGamesData")
    local id, _ = string.gsub(sender.Name, "%D", '')
    id = tonumber(id)

    local bytecount = ((num_of_fixed_fixtures - id) * 16) + 16
    local bytes = readBytes(string.format('arr_fixedGamesData+%s', string.format('%X', id * 16 + 4)), bytecount, true)
    writeBytes(string.format('arr_fixedGamesData+%s', string.format('%X', (id-1) * 16 + 4)), bytes)

    writeInteger("arr_fixedGamesData", num_of_fixed_fixtures-1)
    self.after_delete_timer = createTimer(nil)
    timer_onTimer(self.after_delete_timer, fncall_after_delete_fixed_match)
    timer_setInterval(self.after_delete_timer, 250)
    timer_setEnabled(self.after_delete_timer, true)
end

function thisFormManager:create_match_fixing_container(i)
    local fnDelete_match_fix = function(sender)
        self:delete_match_fix(sender)
    end

    local max_in_row = 3
    -- Container
    local caption = ""
    local row = i//max_in_row
    local row_i = (i - max_in_row * row)

    local match_fix_container = createPanel(self.frm.MatchFixingScroll)
    match_fix_container.Name = string.format('MatchFixContainerPanel%d', i+1)
    match_fix_container.BevelOuter = bvNone
    match_fix_container.Caption = ''

    match_fix_container.Color = '0x001B1A1A'
    match_fix_container.Width = 250
    match_fix_container.Height = 125
    match_fix_container.Left = 10 + 250*row_i
    match_fix_container.Top = 10 + 125*row
    match_fix_container.OnClick = fnDelete_match_fix

    -- Home Team Badge
    local home_teamid = readInteger(string.format('arr_fixedGamesData+%s', string.format('%X', i * 16 + 4)))

    local home_badgeimg = createImage(match_fix_container)
    local ss_c = self:load_crest(home_teamid)
    home_badgeimg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()

    home_badgeimg.Name = string.format('FixingHomeTeamImage%d', i+1)
    home_badgeimg.Left = 10
    home_badgeimg.Top = 10
    home_badgeimg.Height = 75
    home_badgeimg.Width = 75
    home_badgeimg.Stretch = true
    home_badgeimg.Cursor = "crHandPoint"
    home_badgeimg.OnClick = fnDelete_match_fix

    -- Home TeamID Label
    local home_teamid_label = createLabel(match_fix_container)

    if home_teamid == 4294967295 then
        caption = 'Any'
    else
        caption = home_teamid
    end
    home_teamid_label.Name = string.format('FixingHomeTeamIDLabel%d', i+1)
    home_teamid_label.Visible = true
    home_teamid_label.Caption = caption
    home_teamid_label.AutoSize = false
    home_teamid_label.Width = 75
    home_teamid_label.Height = 19
    home_teamid_label.Left = 10
    home_teamid_label.Top = 95
    home_teamid_label.Font.Size = 11
    home_teamid_label.Font.Color = '0xC0C0C0'
    home_teamid_label.Alignment = 'taCenter'
    home_teamid_label.Cursor = "crHandPoint"
    home_teamid_label.OnClick = fnDelete_match_fix

    -- Away Team Badge
    local away_teamid = readInteger(string.format('arr_fixedGamesData+%s', string.format('%X', i * 16 + 8)))

    local away_badgeimg = createImage(match_fix_container)
    local ss_c = self:load_crest(away_teamid)
    away_badgeimg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()

    away_badgeimg.Name = string.format('FixingAwayTeamImage%d', i+1)
    away_badgeimg.Left = 165
    away_badgeimg.Top = 10
    away_badgeimg.Height = 75
    away_badgeimg.Width = 75
    away_badgeimg.Stretch = true
    away_badgeimg.Cursor = "crHandPoint"
    away_badgeimg.OnClick = fnDelete_match_fix

    -- Away TeamID Label
    local away_teamid_label = createLabel(match_fix_container)
    if away_teamid == 4294967295 then
        caption = 'Any'
    else
        caption = away_teamid
    end
    
    away_teamid_label.Name = string.format('FixingAwayTeamIDLabel%d', i+1)
    away_teamid_label.Visible = true
    away_teamid_label.Caption = caption
    away_teamid_label.AutoSize = false
    away_teamid_label.Width = 75
    away_teamid_label.Height = 19
    away_teamid_label.Left = 165
    away_teamid_label.Top = 95
    away_teamid_label.Font.Size = 11
    away_teamid_label.Font.Color = '0xC0C0C0'
    away_teamid_label.Alignment = 'taCenter'
    away_teamid_label.Cursor = "crHandPoint"
    away_teamid_label.OnClick = fnDelete_match_fix

    -- Score Label
    local home_goals = readInteger(string.format('arr_fixedGamesData+%s', string.format('%X', i * 16 + 12)))
    local away_goals = readInteger(string.format('arr_fixedGamesData+%s', string.format('%X', i * 16 + 16)))
    local score_label = createLabel(match_fix_container)
    score_label.Name = string.format('FixingScoreResultLabel%d', i+1)
    score_label.Visible = true
    score_label.Caption = string.format("%d:%d", home_goals, away_goals)
    score_label.AutoSize = false
    score_label.Width = 60
    score_label.Height = 19
    score_label.Left = 95
    score_label.Top = 40
    score_label.Font.Size = 12
    score_label.Font.Color = '0xC0C0C0'
    score_label.Alignment = 'taCenter'
    score_label.OnClick = fnDelete_match_fix
end

function thisFormManager:create_match_fixing_containers()
    local num_of_fixed_fixtures = readInteger("arr_fixedGamesData")

    if num_of_fixed_fixtures <= 0 then
        return
    end

    for i=0, num_of_fixed_fixtures-1 do
        self:create_match_fixing_container(i)
    end
end


function thisFormManager:call_after_delete_fav_scorer()
    timer_setEnabled(self.after_delete_timer, false)
    self.after_delete_timer = nil
    self:clear_fav_scorers_containers()
    self:create_fav_scorers_containers()
    self.logger:info("Deleted player from favourite scorers")
end

function thisFormManager:delete_fav_scorer(sender)
    if messageDialog("Are you sure you want to delete this player from your favourite scorers?", mtInformation, mbYes,mbNo) == mrNo then
        return false
    end

    local fncall_after = function()
        self:call_after_delete_fav_scorer()
    end

    local fav_scorers = readInteger("arr_favGoalScorers")
    local id, _ = string.gsub(sender.Name, "%D", '')
    id = tonumber(id)

    if type(self.cfg.fav_scorers) == 'table' then
        local tid = tonumber(
            self.frm.MatchFixingFavScorersScroll[string.format('FavScorerContainerPanel%d', id)][string.format('FavScorerPlayerIDLabel%d', id)].Caption
        )
        local new_fav_scorers = {}
        for i, val in ipairs(self.cfg.fav_scorers) do
            if val ~= tid then
                table.insert(new_fav_scorers, val)
            end
        end
        self.cfg.fav_scorers = new_fav_scorers
        self.fnSaveCfg(self.cfg)
    end

    local bytecount = ((fav_scorers - id) * 4) + 4
    local bytes = readBytes(string.format('arr_favGoalScorers+%s', string.format('%X', id * 4 + 4)), bytecount, true)
    writeBytes(string.format('arr_favGoalScorers+%s', string.format('%X', id * 4)), bytes)

    writeInteger("arr_favGoalScorers", fav_scorers-1)
    self.after_delete_timer = createTimer(nil)
    timer_onTimer(self.after_delete_timer, fncall_after)
    timer_setInterval(self.after_delete_timer, 250)
    timer_setEnabled(self.after_delete_timer, true)

end

function thisFormManager:create_fav_scorer_container(i, playerid)
    local fnDelete_fav_scorer = function(sender)
        self:delete_fav_scorer(sender)
    end

    local max_in_row = 8
    -- Container
    local row = i//max_in_row
    local row_i = (i - max_in_row * row)

    local fav_scorer_container = createPanel(self.frm.MatchFixingFavScorersScroll)
    fav_scorer_container.Name = string.format('FavScorerContainerPanel%d', i+1)
    fav_scorer_container.BevelOuter = bvNone
    fav_scorer_container.Caption = ''

    fav_scorer_container.Color = '0x001B1A1A'
    fav_scorer_container.Width = 100
    fav_scorer_container.Height = 100
    fav_scorer_container.Left = 10 + 100*row_i
    fav_scorer_container.Top = 10 + 110*row
    fav_scorer_container.OnClick = fnDelete_fav_scorer

    -- Headshot
    if playerid == nil then
        playerid = readInteger(string.format('arr_favGoalScorers+%s', string.format('%X', i * 4 + 4)))
    end
    playerid = tonumber(playerid)

    local playeraddr = nil
    if playerid >= 280000 then
        playeraddr = self:find_player_by_id(playerid)
    end

    local headshotimg = createImage(fav_scorer_container)
    local ss_c = self:load_headshot(
        playerid, playeraddr
    )
    headshotimg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()

    headshotimg.Name = string.format('FavScorerImage%d', i+1)
    headshotimg.Cursor = "crHandPoint"
    headshotimg.Left = 12
    headshotimg.Top = 0
    headshotimg.Height = 75
    headshotimg.Width = 75
    headshotimg.Stretch = true
    headshotimg.OnClick = fnDelete_fav_scorer

    -- PlayerID
    local playerid_label = createLabel(fav_scorer_container)
    playerid_label.Name = string.format('FavScorerPlayerIDLabel%d', i+1)
    playerid_label.Visible = true
    playerid_label.Caption = playerid
    playerid_label.AutoSize = false
    playerid_label.Width = 100
    playerid_label.Height = 19
    playerid_label.Left = 0
    playerid_label.Top = 80
    playerid_label.Font.Size = 11
    playerid_label.Font.Color = '0xC0C0C0'
    playerid_label.Alignment = 'taCenter'
    playerid_label.Cursor = "crHandPoint"
    playerid_label.OnClick = fnDelete_fav_scorer
end

function thisFormManager:create_fav_scorers_containers()
    local fav_scorers = readInteger("arr_favGoalScorers")

    if fav_scorers <= 0 then
        return false
    end

    for i=0, fav_scorers-1 do
        self:create_fav_scorer_container(i)
    end
end

function thisFormManager:FixingTypeListBoxSelectionChange(sender, user)
    local Panels = {
        'MatchFixingContainer',
        'MatchFixingFavContainer',
        'MatchFixingFavScorersContainer',
    }
    for i=1, #Panels do
        if sender.ItemIndex == i-1 then
            self.frm[Panels[i]].Visible = true
        else
            self.frm[Panels[i]].Visible = false
        end
    end
end

function thisFormManager:MatchFixingAddFavTeam(sender)
    local fav_teams = readInteger("arr_fixedGamesAlwaysWin")
    if fav_teams >= self.fav_teams_limit then
        self.logger:critical(
            string.format("Add Fav team\nReached maximum number of favourite teams. %d is the limit.", self.fav_teams_limit)
        )
        return false
    end

    local teamid = inputQuery("Add Fav team", "Enter teamid:", "0")
    if not teamid or tonumber(teamid) <= 0 then
        self.logger:critical(string.format("Add Fav team\nEnter Valid TeamID\n %s is invalid.", teamid))
        return false
    end
    self.logger:info(string.format("New fav team: %s", teamid))

    writeInteger("arr_fixedGamesAlwaysWin", fav_teams + 1)

    writeInteger(
        string.format('arr_fixedGamesAlwaysWin+%s', string.format('%X', (fav_teams) * 4 + 4)),
        teamid
    )

    self:create_fav_teams_container(fav_teams, teamid)

    if type(self.cfg.fav_teams) == 'table' then
        table.insert(self.cfg.fav_teams, tonumber(teamid))
    else
        self.cfg.fav_teams = { tonumber(teamid) }
    end
    self.fnSaveCfg(self.cfg)

    self.logger:info(string.format("Success ID: %d", fav_teams + 1))
end

function thisFormManager:MatchFixingAddFavScorer(sender)
    local fav_scorers = readInteger("arr_favGoalScorers")
    if fav_scorers >= self.fav_scorers_limit then
        self.logger:critical(string.format("Add Fav scorer\nReached maximum number of favourite scorers. %d is the limit.", self.fav_scorers_limit))
        return false
    end

    local playerid = inputQuery("Add Fav scorer", "Enter playerid:", "0")
    if not playerid or tonumber(playerid) <= 0 then
        self.logger:critical(string.format("Add Fav scorer\nEnter Valid PlayerID\n %s is invalid.", playerid))
        return false
    end
    self.logger:info(string.format("New fav scorer: %s", playerid))

    writeInteger("arr_favGoalScorers", fav_scorers + 1)

    writeInteger(
        string.format('arr_favGoalScorers+%s', string.format('%X', (fav_scorers) * 4 + 4)),
        playerid
    )

    self:create_fav_scorer_container(fav_scorers, playerid)

    if type(self.cfg.fav_scorers) == 'table' then
        table.insert(self.cfg.fav_scorers, tonumber(playerid))
    else
        self.cfg.fav_scorers = { tonumber(playerid) }
    end
    self.fnSaveCfg(self.cfg)

    self.logger:info(string.format("Success ID: %d", fav_scorers + 1))
end

function thisFormManager:onShow(sender)
    self.logger:debug(string.format("onShow: %s", self.name))
    local is_in_cm = is_cm_loaded()
    if not is_in_cm then
        showMessage("This feature works only in career mode.")
        self.frm.close()
        return
    end
    if not getAddressList().getMemoryRecordByID(4870).Active then
        getAddressList().getMemoryRecordByID(4870).Active = true

        if (type(self.cfg.fav_teams) == "table") then
            writeInteger("arr_fixedGamesAlwaysWin", #self.cfg.fav_teams)
            for i, val in ipairs(self.cfg.fav_teams) do
                local idx = i - 1
                writeInteger(string.format('arr_fixedGamesAlwaysWin+%s', string.format('%X', idx * 4 + 4)), val)
            end
        end

        if (type(self.cfg.fav_scorers) == "table") then
            writeInteger("arr_favGoalScorers", #self.cfg.fav_scorers)
            for i, val in ipairs(self.cfg.fav_scorers) do
                local idx = i - 1
                writeInteger(string.format('arr_favGoalScorers+%s', string.format('%X', idx * 4 + 4)), val)
            end
        end

    end

    self:clear_fav_teams_containers()
    self:clear_match_fixing_containers()
    self:clear_fav_scorers_containers()
    self:create_fav_teams_containers()
    self:create_match_fixing_containers()
    self:create_fav_scorers_containers()

    self.frm.FixingTypeListBox.setItemIndex(0)
    self:FixingTypeListBoxSelectionChange(self.frm.FixingTypeListBox)
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    self.frm.SyncImage.OnClick = function(sender)
        self:clear_fav_teams_containers()
        self:clear_match_fixing_containers()
        self:create_fav_teams_containers()
        self:create_match_fixing_containers()
        self:clear_fav_scorers_containers()
        self:create_fav_scorers_containers()
    end
    self.frm.MatchFixingSettings.OnClick = function(sender)
        SettingsForm.show()
    end

    self.frm.FixingTypeListBox.OnSelectionChange = function(sender, user)
        self:FixingTypeListBoxSelectionChange(sender, user)
    end

    self.frm.MatchFixingNewMatchFixBtn.OnClick = function(sender)
        if self:need_match_fixing_sync() then
            ShowMessage("Close this and try again after 2s.")
            self:clear_match_fixing_containers()
            self:create_match_fixing_containers()
            return false
        end
    
        self.frm.close()
        NewMatchFixForm.show()
    end

    self.frm.MatchFixingNewMatchFixBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.MatchFixingNewMatchFixBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.MatchFixingNewMatchFixBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.MatchFixingFavTeamHelp.OnClick = function(sender)
        ShowMessage([[
Favourite teams

Teams defined as a favourite will always win their games by 3:0.

If you got more than one favourite team and these teams will meet each other then the home team will always win.

You can only define 60 favourite teams at this moment.
]])
    end

    self.frm.MatchFixingAddFavTeamBtn.OnClick = function(sender)
        self:MatchFixingAddFavTeam(sender)
    end

    self.frm.MatchFixingAddFavTeamBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.MatchFixingAddFavTeamBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.MatchFixingAddFavTeamBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.MatchFixingFavScorerHelp.OnClick = function(sender)
        ShowMessage([[
Favourite Scorers

Players defined as favourite scorers will always all goals for their teams. (Except penalties)

You can only define 100 favourite scorers at this moment.
]])
    end

    self.frm.MatchFixingAddFavScorerBtn.OnClick = function(sender)
        self:MatchFixingAddFavScorer(sender)
    end

    self.frm.MatchFixingAddFavScorerBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.MatchFixingAddFavScorerBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.MatchFixingAddFavScorerBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end
end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.after_delete_timer = nil
    self.fav_teams_limit = 60
    self.fav_scorers_limit = 100

    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self:assign_current_form_events()
end

return thisFormManager;