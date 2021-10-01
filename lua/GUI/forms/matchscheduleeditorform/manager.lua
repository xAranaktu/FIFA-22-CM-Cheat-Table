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

    return o;
end

function thisFormManager:doApplyChanges()
    for i=0, self.frm.SchedulesScroll.ComponentCount-1 do
        local container = self.frm.SchedulesScroll.Component[i]
        for j=0, container.ComponentCount-1 do
            if string.sub(container.Component[j].Name, 0, 18) == 'MatchDateAddrLabel' then
                local new_val = date_to_value(
                    container[string.format('MatchDateEdit%d', i+1)].Text
                )
                if not new_val then
                    break
                end

                writeInteger(
                    tonumber(container.Component[j].Caption, 16) + 0x14,
                    new_val
                )
            end
        end
    end
    ShowMessage('Done.')
end

function thisFormManager:create_match_containers()
    local games_in_current_month = readInteger('fixturesData+8')
    
    if games_in_current_month == nil then
        self:clear_match_containers()
        return
    end
    self.logger:info(string.format("Games in current month: %d", games_in_current_month))

    -- Fill GUI
    for i=0, games_in_current_month-1 do
        local m_index = readInteger(string.format('fixturesData+%X', 12+i*4)) * 0x28

        local fixtureList = self.memory_manager:read_multilevel_pointer(readPointer('fixturesData'), {0x18, 0x60})
        local standingsList = self.memory_manager:read_multilevel_pointer(readPointer('fixturesData'), {0x18, 0x88, 0x30})
        local fixture = self.memory_manager:read_multilevel_pointer(fixtureList, {0x30}) + m_index
        local hometeam = standingsList + (readSmallInteger(fixture + 0x1A) * 0x28) -- HOMETEAM
        local awayteam = standingsList + (readSmallInteger(fixture + 0x1E) * 0x28) -- AWAYTEAM

        -- Container
        local panel_match_container = createPanel(self.frm.SchedulesScroll)
        panel_match_container.Name = string.format('MatchContainerPanel%d', i+1)
        panel_match_container.BevelOuter = bvNone
        panel_match_container.Caption = ''

        panel_match_container.Color = '0x00302825'
        panel_match_container.Width = 280
        panel_match_container.Height = 80
        panel_match_container.Left = 10
        panel_match_container.Top = 10 + 90*i

        -- Addr for apply changes
        local hidden_label = createLabel(panel_match_container)
        hidden_label.Name = string.format('MatchDateAddrLabel%d', i+1)
        hidden_label.Visible = false
        hidden_label.Caption = string.format('%X', fixture)


        -- Match Date Edit
        local match_date = createEdit(panel_match_container)
        match_date.Name = string.format('MatchDateEdit%d', i+1)
        match_date.Hint = 'Date format: DD/MM/YYYY'
        match_date.BorderStyle = bsNone
        match_date.Text = value_to_date(readInteger(fixture + 0x14))
        match_date.Color = '0x003A302C'
        match_date.Top = 0
        match_date.Left = 75
        match_date.Width = 130
        match_date.Font.Size = 14
        match_date.Font.Color = '0xFFFBF0'

        -- VS LABEL
        local vslabel = createLabel(panel_match_container)
        vslabel.Name = string.format('MatchLabel%d', i+1)
        vslabel.Caption = 'Vs.'
        vslabel.AutoSize = false
        vslabel.Width = 60
        vslabel.Height = 42
        vslabel.Left = 110
        vslabel.Top = 38
        vslabel.Font.Size = 26
        vslabel.Font.Color = '0xC0C0C0'

        -- Home Team Badge
        local badgeimg = createImage(panel_match_container)
        local ss_c = self:load_crest(readInteger(hometeam + 0x14))
        badgeimg.Picture.LoadFromStream(ss_c)
        ss_c.destroy()

        badgeimg.Name = string.format('MatchImageHT%d', i+1)
        badgeimg.Left = 0
        badgeimg.Top = 5
        badgeimg.Height = 75
        badgeimg.Width = 75
        badgeimg.Stretch = true

        -- Away Team Badge
        local badgeimg = createImage(panel_match_container)
        local ss_c = self:load_crest(readInteger(awayteam + 0x14))
        badgeimg.Picture.LoadFromStream(ss_c)
        ss_c.destroy()

        badgeimg.Name = string.format('MatchImageAT%d', i+1)
        badgeimg.Left = 205
        badgeimg.Top = 5
        badgeimg.Height = 75
        badgeimg.Width = 75
        badgeimg.Stretch = true
    end
end

function thisFormManager:clear_match_containers()
    for i=0, self.frm.SchedulesScroll.ComponentCount-1 do
        self.frm.SchedulesScroll.Component[0].destroy()
    end
end

function thisFormManager:onShow(sender)
    self.logger:debug(string.format("onShow: %s", self.name))
    local is_in_cm = is_cm_loaded()
    if not is_in_cm then
        showMessage("This feature works only in career mode.")
        self.frm.close()
        return
    end
    self:clear_match_containers()

    getAddressList().getMemoryRecordByID(4869).Active = false
    getAddressList().getMemoryRecordByID(4869).Active = true
    self:create_match_containers()
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    self.frm.MatchScheduleSettings.OnClick = function(sender)
        SettingsForm.show()
    end

    self.frm.SyncImage.OnClick = function(sender)
        self:clear_match_containers()
        self:create_match_containers()
    end

    self.frm.ScheduleEditorApplyChangesBtn.OnClick = function(sender)
        self:doApplyChanges()
    end
    self.frm.ScheduleEditorApplyChangesLabel.OnClick = function(sender)
        self:doApplyChanges()
    end
    
end

function thisFormManager:setup(params)
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self:assign_current_form_events()
end


return thisFormManager;