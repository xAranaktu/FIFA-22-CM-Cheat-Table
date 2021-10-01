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

    self.fill_timer = nil
    self.custom_transfer_max_per_mage = 3
    self.custom_transfer_page = 1
    self.custom_transfers_counter = 0

    return o;
end

function thisFormManager:has_next_transfers_page(max_transfers)
    if (self.custom_transfer_page * self.custom_transfer_max_per_mage) < max_transfers then
        return true
    else
        return false
    end
end

function thisFormManager:has_prev_transfers_page()
    if self.custom_transfer_page <= 1 then
        return false
    else
        return true
    end
end

function thisFormManager:update_transfers_counter(num)
    if num ~= nil then
        self.frm.TotalTransfersLabel.Caption = string.format(
            'Confirmed Transfers: %d', num
        )
    else
        self.frm.TotalTransfersLabel.Caption = string.format(
            'Confirmed Transfers: %d', (readInteger('arr_NewTransfers') or 0)
        )
    end
end

function thisFormManager:confirm_transfer(sender)
    local comp_id = nil
    if sender.ClassName == 'TCEImage' then
        comp_id = string.gsub(sender.Name, "ConfirmBtnImage", "")
    else
        comp_id = string.gsub(sender.Name, "ConfirmBtnLabel", "")
    end
    comp_id = tonumber(comp_id)
    self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ConfirmBtnLabel%d', comp_id)].Visible = false
    self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ConfirmBtnImage%d', comp_id)].Visible = false

    local num_of_transfers = readInteger('arr_NewTransfers')
    writeInteger('arr_NewTransfers', num_of_transfers + 1)

    -- append
    local playerid = tonumber(self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('PlayerIDLabel%d', comp_id)].Caption)

    local current_teamid_comp = self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('FromTeamId%d', comp_id)]
    local current_teamid = nil
    if current_teamid_comp.ClassName == 'TEdit' or current_teamid_comp.ClassName == 'TCEEdit' then
        current_teamid = tonumber(current_teamid_comp.Text)
    else
        current_teamid = tonumber(current_teamid_comp.Items[current_teamid_comp.ItemIndex])
    end
    local new_teamid = tonumber(self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ToTeamId%d', comp_id)].Text)
    local release_clause = tonumber(self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ReleaseClauseValue%d', comp_id)].Text) or 0
    local contract_length = (tonumber(self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ContractLengthCombo%d', comp_id)].ItemIndex) + 1) * 12

    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 4)),
        playerid
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 8)),
        new_teamid
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 12)),
        current_teamid
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 16)),
        release_clause
    )
    writeInteger(
        string.format('arr_NewTransfers+%s', string.format('%X', (num_of_transfers) * 20 + 20)),
        contract_length
    )
    self.logger:info(string.format("Confirm transfer. PlayerID: %d, CurrentTeamID: %d, NewTeamID: %d, Clause: %d, Length: %d", playerid, current_teamid, new_teamid, release_clause, contract_length))
    self:update_transfers_counter()
end

function thisFormManager:delete_transfer(sender)
    local comp_id = nil
    if sender.ClassName == 'TCEImage' then
        comp_id = string.gsub(sender.Name, "DeleteBtnImage", "")
    else
        comp_id = string.gsub(sender.Name, "DeleteBtnLabel", "")
    end
    comp_id = tonumber(comp_id)

    for i=comp_id, self.frm.TransfersScroll.ComponentCount-1 do
        self.frm.TransfersScroll.Component[i].Top = self.frm.TransfersScroll.Component[i].Top - self.frm.TransfersScroll.Component[i].Height
    end

    local num_of_transfers = readInteger('arr_NewTransfers')
    local playerid = tonumber(self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('PlayerIDLabel%d', comp_id)].Caption)
    local current_teamid_comp = self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('FromTeamId%d', comp_id)]
    local current_teamid = nil
    if current_teamid_comp.ClassName == 'TEdit' or current_teamid_comp.ClassName == 'TCEEdit' then
        current_teamid = tonumber(current_teamid_comp.Text)
    else
        current_teamid = tonumber(current_teamid_comp.Items[current_teamid_comp.ItemIndex])
    end
    local new_teamid = tonumber(self.frm.TransfersScroll[string.format('NewTransferContainerPanel%d', comp_id)][string.format('ToTeamId%d', comp_id)].Text)

    self.logger:info(string.format("Delete Transfer. PlayerID: %d, CurrentTeamID: %d, NewTeamID: %d", playerid, current_teamid, new_teamid))

    rewrite_transfers = {}
    local transfer_is_in_queue = false
    for i=0, num_of_transfers do
        local pid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 4)))
        local ntid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 8)))
        local ctid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 12)))
        local rl_clause = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 16)))
        local cl = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 20)))
        if pid == playerid and ctid == current_teamid and ntid == new_teamid then
            transfer_is_in_queue = true
        else
            table.insert(rewrite_transfers, pid)
            table.insert(rewrite_transfers, ntid)
            table.insert(rewrite_transfers, ctid)
            table.insert(rewrite_transfers, rl_clause)
            table.insert(rewrite_transfers, cl)
        end
    end

    if transfer_is_in_queue then
        self.logger:info("^Transfer in queue")
        for i=1, #rewrite_transfers do
            writeInteger(
                string.format('arr_NewTransfers+%s', string.format('%X', i * 4)),
                rewrite_transfers[i]
            )
        end
        writeInteger('arr_NewTransfers', num_of_transfers - 1)
    end
    self:update_transfers_counter(num_of_transfers - 1)
    sender.Owner.Visible = false
    self.custom_transfers_counter = self.custom_transfers_counter - 1
end

function thisFormManager:create_player_transfer_comp(playerid, player_addr, current_team_ids, teamid, clause, contract_length, is_confirmed_by_user)
    self.custom_transfers_counter = self.custom_transfers_counter + 1


    local fnDeleteTransfer = function(sender)
        self:delete_transfer(sender)
    end

    local fnConfirmTransfer = function(sender)
        self:confirm_transfer(sender)
    end


    local name = string.format('NewTransferContainerPanel%d', self.custom_transfers_counter)
    local reindex = false
    local deleted = 0
    for i=0, self.frm.TransfersScroll.ComponentCount-1 do
        -- Delete deleted transfers
        if not self.frm.TransfersScroll.Component[i-deleted].Visible then
            self.frm.TransfersScroll.Component[i-deleted].destroy()
            deleted = deleted + 1
            reindex = true
        end
    end

    -- reindex
    if reindex then
        for i=0, self.frm.TransfersScroll.ComponentCount-1 do
            local comp = self.frm.TransfersScroll.Component[i]
            comp.Name = string.gsub(comp.Name, '%d', i+1)
            for j=0, comp.ComponentCount-1 do
                comp.Component[j].Name = string.gsub(comp.Component[j].Name, '%d', i+1)
            end
        end
    end

    local panel_player_transfer_container = createPanel(self.frm.TransfersScroll)
    panel_player_transfer_container.Name = name
    panel_player_transfer_container.BevelOuter = bvNone
    panel_player_transfer_container.Caption = ''

    panel_player_transfer_container.Color = '0x00302825'
    panel_player_transfer_container.Width = 780
    panel_player_transfer_container.Height = 160
    panel_player_transfer_container.Left = 10

    if self.custom_transfers_counter == 1 then
        panel_player_transfer_container.Top = 70
    else
        panel_player_transfer_container.Top = 160*(self.custom_transfers_counter-1) + 85
    end

    -- Player miniface
    local playerimg = createImage(panel_player_transfer_container)
    local ss_p = self:load_headshot(
        playerid, player_addr
    )
    if self:safe_load_picture_from_ss(playerimg.Picture, ss_p) then
        ss_p.destroy()
    end
    
    playerimg.Name = string.format('PlayerImage%d', self.custom_transfers_counter)
    playerimg.Left = 20
    playerimg.Top = 25
    playerimg.Height = 90
    playerimg.Width = 90
    playerimg.Stretch = true

    -- PlayerID
    local PlayerIDLabel = createLabel(panel_player_transfer_container)

    PlayerIDLabel.Name = string.format('PlayerIDLabel%d', self.custom_transfers_counter)
    PlayerIDLabel.AutoSize = false
    PlayerIDLabel.Left = 20
    PlayerIDLabel.Height = 14
    PlayerIDLabel.Top = 125
    PlayerIDLabel.Width = 90
    PlayerIDLabel.Alignment = "taCenter"
    PlayerIDLabel.Caption = playerid

    -- From
    local FromLabel = createLabel(panel_player_transfer_container)

    FromLabel.Name = string.format('FromTeamLabel%d', self.custom_transfers_counter)
    FromLabel.AutoSize = false
    FromLabel.Left = 135
    FromLabel.Height = 14
    FromLabel.Top = 0
    FromLabel.Width = 90
    FromLabel.Alignment = "taCenter"
    FromLabel.Caption = "From:"

    -- From Crest
    local FromCrestImg = createImage(panel_player_transfer_container)
    local ss_c = self:load_crest(current_team_ids[1])
    FromCrestImg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
    
    FromCrestImg.Name = string.format('FromCrestImage%d', self.custom_transfers_counter)
    FromCrestImg.Left = 135
    FromCrestImg.Top = 25
    FromCrestImg.Height = 90
    FromCrestImg.Width = 90
    FromCrestImg.Stretch = true

    -- From Edit/Combo
    if #current_team_ids == 1 then
        -- If only one team
        local FromTeamId = createEdit(panel_player_transfer_container)
        FromTeamId.Name = string.format('FromTeamId%d', self.custom_transfers_counter)
        FromTeamId.BorderStyle = "bsNone"
        FromTeamId.ParentFont = false
        FromTeamId.Color = 5653320
        FromTeamId.Font.CharSet = "EASTEUROPE_CHARSET"
        FromTeamId.Font.Color = 12632256 -- clCream
        FromTeamId.Font.Height = -12
        FromTeamId.Font.Name = "Verdana"
        FromTeamId.AutoSize = false
        FromTeamId.Left = 135
        FromTeamId.Height = 14
        FromTeamId.Top = 124
        FromTeamId.Width = 90
        FromTeamId.Alignment = "taCenter"
        FromTeamId.Text = current_team_ids[1]
        FromTeamId.ReadOnly = true
    else
        -- If multiple teams
        local FromTeamId = createComboBox(panel_player_transfer_container)
        for i = 1, #current_team_ids do
            FromTeamId.items.add(current_team_ids[i])
        end
        FromTeamId.ItemIndex = 0
        FromTeamId.Name = string.format('FromTeamId%d', self.custom_transfers_counter)
        FromTeamId.AutoSize = false
        FromTeamId.Left = 135
        FromTeamId.Height = 22
        FromTeamId.Top = 124
        FromTeamId.Width = 90
        FromTeamId.Style = "csDropDownList"
        FromTeamId.OnChange = reload_team_from_crest
    end

    -- To
    local ToLabel = createLabel(panel_player_transfer_container)

    ToLabel.Name = string.format('ToTeamLabel%d', self.custom_transfers_counter)
    ToLabel.AutoSize = false
    ToLabel.Left = 265
    ToLabel.Height = 14
    ToLabel.Top = 0
    ToLabel.Width = 90
    ToLabel.Alignment = "taCenter"
    ToLabel.Caption = "To:"

    -- To Crest
    local ToCrestImg = createImage(panel_player_transfer_container)
    local ss_c = self:load_crest(teamid)
    ToCrestImg.Picture.LoadFromStream(ss_c)
    ss_c.destroy()
    
    ToCrestImg.Name = string.format('ToCrestImage%d', self.custom_transfers_counter)
    ToCrestImg.Left = 265
    ToCrestImg.Top = 25
    ToCrestImg.Height = 90
    ToCrestImg.Width = 90
    ToCrestImg.Stretch = true

    -- To Edit
    local ToTeamId = createEdit(panel_player_transfer_container)
    ToTeamId.Name = string.format('ToTeamId%d', self.custom_transfers_counter)
    ToTeamId.BorderStyle = "bsNone"
    ToTeamId.Color = 5653320
    ToTeamId.ParentFont = false
    ToTeamId.Font.CharSet = "EASTEUROPE_CHARSET"
    ToTeamId.Font.Color = 15793151
    ToTeamId.Font.Height = -12
    ToTeamId.Font.Name = "Verdana"
    ToTeamId.AutoSize = false
    ToTeamId.Alignment = "taCenter"
    ToTeamId.Left = 265
    ToTeamId.Height = 14
    ToTeamId.Top = 124
    ToTeamId.Width = 90
    ToTeamId.Text = teamid
    ToTeamId.OnChange = reload_team_to_crest

    -- Release Clause Label
    local RCLabel = createLabel(panel_player_transfer_container)

    RCLabel.Name = string.format('RCLabel%d', self.custom_transfers_counter)
    RCLabel.AutoSize = false
    RCLabel.Left = 375
    RCLabel.Height = 14
    RCLabel.Top = 25
    RCLabel.Width = 110
    RCLabel.Alignment = "taCenter"
    RCLabel.Caption = "Release Clause:"

    -- Release Clause Edit
    local RCValue = createEdit(panel_player_transfer_container)
    RCValue.Name = string.format('ReleaseClauseValue%d', self.custom_transfers_counter)
    RCValue.BorderStyle = "bsNone"
    RCValue.Color = 5653320
    RCValue.ParentFont = false
    RCValue.Font.CharSet = "EASTEUROPE_CHARSET"
    RCValue.Font.Color = 15793151
    RCValue.Font.Height = -12
    RCValue.Font.Name = "Verdana"
    RCValue.AutoSize = false
    RCValue.Alignment = "taCenter"
    RCValue.Left = 495
    RCValue.Height = 14
    RCValue.Top = 29
    RCValue.Width = 100
    RCValue.Text = clause

    -- Contract Length Label
    local CLLabel = createLabel(panel_player_transfer_container)

    CLLabel.Name = string.format('CLLabel%d', self.custom_transfers_counter)
    CLLabel.AutoSize = false
    CLLabel.Left = 375
    CLLabel.Height = 14
    CLLabel.Top = 65
    CLLabel.Width = 110
    CLLabel.Alignment = "taCenter"
    CLLabel.Caption = "Contract Length:"

    -- Contract Length Combo
    local CLCombo = createComboBox(panel_player_transfer_container)
    local contract_length_values = {
        '1 year', '2 years', '3 years', '4 years', '5 years'
    }
    for i = 1, #contract_length_values do
        CLCombo.items.add(contract_length_values[i])
    end

    CLCombo.ItemIndex = contract_length - 1
    CLCombo.Name = string.format('ContractLengthCombo%d', self.custom_transfers_counter)
    CLCombo.AutoSize = false
    CLCombo.Left = 495
    CLCombo.Height = 22
    CLCombo.Top = 63
    CLCombo.Width = 100
    CLCombo.Style = "csDropDownList"

    -- Confirm Btn
    if not is_confirmed_by_user then
        local ConfirmImg = createImage(panel_player_transfer_container)
        ConfirmImg.Picture.LoadFromStream(findTableFile('btn.png').Stream)

        ConfirmImg.Name = string.format('ConfirmBtnImage%d', self.custom_transfers_counter)
        ConfirmImg.Left = 605
        ConfirmImg.Top = 20
        ConfirmImg.Height = 56
        ConfirmImg.Width = 161
        ConfirmImg.OnClick = fnConfirmTransfer
        ConfirmImg.Cursor = "crHandPoint"

        local ConfirmLabel = createLabel(panel_player_transfer_container)
        ConfirmLabel.Name = string.format('ConfirmBtnLabel%d', self.custom_transfers_counter)
        ConfirmLabel.AnchorSideLeft.Control = ConfirmImg
        ConfirmLabel.AnchorSideTop.Control = ConfirmImg
        ConfirmLabel.AnchorSideRight.Control = ConfirmImg
        ConfirmLabel.AnchorSideRight.Side = "asrBottom"
        ConfirmLabel.AnchorSideBottom.Control = ConfirmImg
        ConfirmLabel.AnchorSideBottom.Side = "asrBottom"
        ConfirmLabel.Anchors = "[akTop, akLeft, akRight, akBottom]"
        ConfirmLabel.Alignment = "taCenter"
        ConfirmLabel.AutoSize = false
        ConfirmLabel.BorderSpacing.Top = 13
        ConfirmLabel.Caption = 'Confirm'
        ConfirmLabel.Font.CharSet = "EASTEUROPE_CHARSET"
        ConfirmLabel.Font.Color = 12632256  -- clSilver
        ConfirmLabel.Font.Height = -15
        ConfirmLabel.Font.Name = 'Verdana'
        ConfirmLabel.ParentColor = false
        ConfirmLabel.ParentFont = false
        ConfirmLabel.OnClick = fnConfirmTransfer
        ConfirmLabel.Cursor = "crHandPoint"
    end

    -- Delete Btn
    local DeleteImg = createImage(panel_player_transfer_container)
    DeleteImg.Picture.LoadFromStream(findTableFile('btn.png').Stream)

    DeleteImg.Name = string.format('DeleteBtnImage%d', self.custom_transfers_counter)
    DeleteImg.Left = 605
    DeleteImg.Top = 81
    DeleteImg.Height = 56
    DeleteImg.Width = 161
    DeleteImg.OnClick = fnDeleteTransfer
    DeleteImg.Cursor = "crHandPoint"

    local DeleteLabel = createLabel(panel_player_transfer_container)
    DeleteLabel.Name = string.format('DeleteBtnLabel%d', self.custom_transfers_counter)
    DeleteLabel.AnchorSideLeft.Control = DeleteImg
    DeleteLabel.AnchorSideTop.Control = DeleteImg
    DeleteLabel.AnchorSideRight.Control = DeleteImg
    DeleteLabel.AnchorSideRight.Side = "asrBottom"
    DeleteLabel.AnchorSideBottom.Control = DeleteImg
    DeleteLabel.AnchorSideBottom.Side = "asrBottom"
    DeleteLabel.Anchors = "[akTop, akLeft, akRight, akBottom]"
    DeleteLabel.Alignment = "taCenter"
    DeleteLabel.BorderSpacing.Top = 13
    DeleteLabel.Caption = 'Delete'
    DeleteLabel.Font.CharSet = "EASTEUROPE_CHARSET"
    DeleteLabel.Font.Color = 12632256
    DeleteLabel.Font.Height = -15
    DeleteLabel.Font.Name = 'Verdana'
    DeleteLabel.ParentColor = false
    DeleteLabel.ParentFont = false
    DeleteLabel.OnClick = fnDeleteTransfer
    DeleteLabel.Cursor = "crHandPoint"
end

function thisFormManager:new_custom_transfer(playerid, current_team_ids, teamid, clause, contract_length, is_confirmed_by_user)
    if not playerid then
        playerid = inputQuery("Queue Player Transfer", "Enter playerid:", "0")
        if not playerid or tonumber(playerid) <= 0 then
            ShowMessage("Enter Valid PlayerID")
            return
        end
        playerid = tonumber(playerid)
    end

    if not teamid then
        teamid = inputQuery("Queue Player Transfer", "Enter new teamid:", "0")
        if not teamid or tonumber(teamid) <= 0 then
            ShowMessage("Enter Valid TeamID")
            return
        end
        teamid = tonumber(teamid)
    end

    local player_addr = self:find_player_by_id(playerid)
    if (not is_confirmed_by_user) or (is_confirmed_by_user and playerid >= 280000) then
        if player_addr <= 0 then
            self.logger:critical("Player with ID: " .. playerid .. " doesn't exists in your current CM save")
            return
        end
    end

    if not current_team_ids then
        current_team_ids = {}
        local teamplayerlink = self:find_player_club_team_record(playerid)
        if teamplayerlink <= 0 then
            self.logger:critical("Player with ID: " .. playerid .. " don't have any current team...")
            return
        end
        local current_teamid = self.game_db_manager:get_table_record_field_value(teamplayerlink, "teamplayerlinks", "teamid")
        table.insert(current_team_ids, current_teamid)
    end

    if not clause then
        clause = 'None'
    end

    if not contract_length then
        contract_length = 3
    end

    self:create_player_transfer_comp(playerid, player_addr, current_team_ids, teamid, clause, contract_length, is_confirmed_by_user)
end

function thisFormManager:fill_custom_transfers()
    for i=0, self.frm.TransfersScroll.ComponentCount-1 do
        self.frm.TransfersScroll.Component[0].destroy()
    end

    self.custom_transfers_counter = 0
    local num_of_transfers = readInteger('arr_NewTransfers')
    local idx = (self.custom_transfer_page-1) * self.custom_transfer_max_per_mage
    local max_comps = idx + self.custom_transfer_max_per_mage
    if max_comps > num_of_transfers then
        max_comps = num_of_transfers
    end

    for i=idx, max_comps - 1 do
        local pid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 4)))
        local ntid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 8)))
        local ctid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 12)))
        local rl_clause = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 16)))
        if rl_clause == 0 then rl_clause = 'None' end

        local cl = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 20))) // 12
        local is_confirmed_by_user = true
        self:new_custom_transfer(pid, {ctid}, ntid, rl_clause, cl, is_confirmed_by_user)
    end
    
    if self:has_next_transfers_page(num_of_transfers) then
        self.frm.NextTransfersPageBtn.Enabled = true
    else
        self.frm.NextTransfersPageBtn.Enabled = false
    end

    if self:has_prev_transfers_page() then
        self.frm.PrevTransfersPageBtn.Enabled = true
    else
        self.frm.PrevTransfersPageBtn.Enabled = false
    end
    self:update_transfers_counter(num_of_transfers)
end

function thisFormManager:onShow(sender)
    self.logger:debug(string.format("onShow: %s", self.name))

    local is_in_cm = is_cm_loaded()
    if not is_in_cm then
        showMessage("This feature works only in career mode.")
        self.frm.close()
        return
    end

    getAddressList().getMemoryRecordByID(3034).Active = true
    self.frm.TransferTypeListBox.setItemIndex(0)

    local onShow_delayed_wrapper = function()
        self:onShow_delayed()
    end

    self.fill_timer = createTimer(nil)

    -- Load Data
    timer_onTimer(self.fill_timer, onShow_delayed_wrapper)
    timer_setInterval(self.fill_timer, 1000)
    timer_setEnabled(self.fill_timer, true)
end

function thisFormManager:onShow_delayed()
    timer_setEnabled(self.fill_timer, false)
    self.fill_timer = nil

    self:fill_custom_transfers()
end

function thisFormManager:OnNewTransferClick(sender)
    if self.frm.NextTransfersPageBtn.Enabled then
        self.logger:critical("Go to the last page before you create new transfer")
        return
    end

    self:new_custom_transfer()
end

function thisFormManager:update_transfers_page()
    self.frm.TransfersPageLabel.Caption = string.format(
        'Page: %d', self.custom_transfer_page
    )
end

function thisFormManager:get_transfers_csv_header()
    local header = [[
        playerid,from,to,contract_length,release_clause
    ]]

    header = string.gsub(header, "%s+", "")
    return header
end

function thisFormManager:import_transfers(sender)
    if messageDialog("This action will remove all current custom transfers\nAre you sure?", mtInformation, mbYes,mbNo) == mrYes then
        -- pass
    else
        return false
    end

    local dialog = self.frm.ImportTransfersDialog
    dialog.Filter = "*.csv"
    dialog.FileName = "Transfers.csv"
    dialog.execute()
    local fname = dialog.FileName
    local line_idx = 1
    if self:file_exists(fname) then
        self.logger:info(string.format("Importing transfers from: %s", fname))
        for line in io.lines(fname) do
            if line_idx == 1 then
                if line ~= self:get_transfers_csv_header() then
                    self.logger:critical(string.format("Invalid csv file headers: %s", line), 'ERROR')
                end
            else
                local values = split(line, ',')
                if values == nil then break end

                local idx = line_idx - 2

                writeInteger('arr_NewTransfers', line_idx-1)
                -- PlayerID
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 4)),
                    values[1]
                )
                -- Current TeamID
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 12)),
                    values[2]
                )
                -- New TeamID
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 8)),
                    values[3]
                )
                -- Contract Length
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 20)),
                    values[4]
                )
                -- Release Clause
                writeInteger(
                    string.format('arr_NewTransfers+%s', string.format('%X', (idx) * 20 + 16)),
                    values[5]
                )
            end

            line_idx = line_idx + 1
        end
        self.logger:info(string.format("Importing transfers done", fname))
        self:fill_custom_transfers()
    else
        self.logger:critical(string.format("File not exists: %s", fname))
    end
end
function thisFormManager:export_transfers(sender)
    local dialog = self.frm.ExportTransfersDialog
    dialog.FileName = "Transfers.csv"
    dialog.execute()
    if dialog.FileName == nil or dialog.FileName == '' then
        self.logger:info("Invalid file")
        return
    end

    file = io.open(dialog.FileName, "w+")
    file:write(self:get_transfers_csv_header() .. '\n')
    local num_of_transfers = readInteger('arr_NewTransfers')

    local new_line = {}
    for i=0, num_of_transfers-1 do
        local pid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 4)))
        local ntid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 8)))
        local ctid = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 12)))
        local rl_clause = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 16)))
        local cl = readInteger(string.format('arr_NewTransfers+%s', string.format('%X', i * 20 + 20)))

        table.insert(new_line, pid)
        table.insert(new_line, ctid)
        table.insert(new_line, ntid)
        table.insert(new_line, cl)
        table.insert(new_line, rl_clause)
        file:write(
            table.concat(new_line, ",") .. '\n'
        )
        new_line = {}
    end
    file:close()
    local success_msg = string.format(
        "%d confirmed custom transfers has been exported to file:\n%s",
        num_of_transfers, dialog.FileName
    )
    self.logger:info(success_msg)
    showMessage(success_msg)
end

function thisFormManager:assign_current_form_events()
    self:assign_events()
    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    self.frm.TransferPlayersSettings.OnClick = function(sender)
        SettingsForm.show()
    end

    self.frm.SyncImage.OnClick = function(sender)
        self:fill_custom_transfers()

        -- Update Counter
        self:update_transfers_counter()
        self.custom_transfer_page = 1
    end

    self.frm.PrevTransfersPageBtn.OnClick = function(sender)
        self.custom_transfer_page = self.custom_transfer_page - 1
        self:fill_custom_transfers()
        self:update_transfers_page()
    end
    self.frm.NextTransfersPageBtn.OnClick = function(sender)
        self.custom_transfer_page = self.custom_transfer_page + 1
        self:fill_custom_transfers()
        self:update_transfers_page()
    end

    self.frm.ImportTransfersBtn.OnClick = function(sender)
        self:import_transfers(sender)
    end
    self.frm.ImportTransfersLabel.OnClick = function(sender)
        self:import_transfers(sender)
    end
    self.frm.ExportTransfersBtn.OnClick = function(sender)
        self:export_transfers(sender)
    end
    self.frm.ExportTransfersLabel.OnClick = function(sender)
        self:export_transfers(sender)
    end
    self.frm.TransferPlayersNewTransferBtn.OnClick = function(sender)
        self:OnNewTransferClick(sender)
    end

    self.frm.TransferPlayersNewTransferLabel.OnClick = function(sender)
        self:OnNewTransferClick(sender)
    end

end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name
    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self.fill_timer = nil
    self.custom_transfer_max_per_mage = 3
    self.custom_transfer_page = 1
    self.custom_transfers_counter = 0

    self:assign_current_form_events()
end

return thisFormManager;