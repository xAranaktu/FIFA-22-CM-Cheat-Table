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


    self.addr_list = nil
    self.fnSaveCfg = nil
    self.new_cfg = {}
    self.has_unsaved_changes = false
    self.selection_idx = 0

    return o;
end

function thisFormManager:save_cfg()
    self.cfg = deepcopy(self.new_cfg)
    self.fnSaveCfg(self.new_cfg)
    self.has_unsaved_changes = false
end

function thisFormManager:FillScriptsTree(record, tn)
    local next_node = nil
    for i=0, record.Count-1 do
        if record.Child[i].Type == 0 or record.Child[i].Type == 11 then
            next_node = tn.add(record.Child[i].Description)
            next_node.Data = record.Child[i].ID
            if record.Child[i].Active then
                next_node.MultiSelected = true
            end
        else
            next_node = tn
        end
        if record.Child[i].Count > 0 then
            next_node.hasChildren = true
            if record.Child[i].Active then
                next_node.Expanded = true
            end
            self:FillScriptsTree(record.Child[i], next_node)
        end
    end
end

function thisFormManager:ActivateSection(index)
    local Panels = {
        'GeneralSettingsPanel',
        'PlayerEditorSettingsPanel',
        'AutoActivationSettingsPanel',
        'CTUpdatesSettingsPanel'
    }
    self.frm.SettingsSectionsListBox.setItemIndex(index)
    for i=1, #Panels do
        if index == i-1 then
            SettingsForm[Panels[i]].Visible = true
        else
            SettingsForm[Panels[i]].Visible = false
        end
    end
end

function thisFormManager:SectionsListBoxSelectionChange(sender, user)
    self:ActivateSection(sender.getItemIndex())
end

function thisFormManager:onShow(sender)
    self.new_cfg = deepcopy(self.cfg)
    self.has_unsaved_changes = false
    self.selection_idx = 0

    -- Hide not needed?
    self.frm.CachePlayersDataCB.Visible = false
    self.frm.CachePlayersDataLabel.Visible = false

    -- Fill General
    self.frm.SelectCacheDirectoryDialog.InitialDir = string.gsub(self.dirs["CACHE"], "/","\\")
    self.frm.CacheFilesDirEdit.Hint = self.dirs["CACHE"]
    self.frm.CacheFilesDirEdit.Text = self.dirs["CACHE"]
    self.frm.GUIOpacityEdit.Text = self.new_cfg.gui.opacity

    self.frm.SyncWithGameHotkeyEdit.Text = self.new_cfg.hotkeys.sync_with_game
    self.frm.SearchPlayerByIDHotkeyEdit.Text = self.new_cfg.hotkeys.search_player_by_id

    if self.new_cfg.flags then
        if self.new_cfg.flags.hide_ce_scanner == nil then
            self.new_cfg.flags.hide_ce_scanner = true
        end

        if self.new_cfg.flags.hide_ce_scanner then
            self.frm.HideCEMemScannerCB.State = 1
        end

        if self.new_cfg.flags.check_for_update == nil then
            self.new_cfg.flags.check_for_update = true
            
        end

        if self.new_cfg.flags.check_for_update then
            self.frm.SettingsCheckForUpdateCB.State = 1
        end

        if self.new_cfg.flags.only_check_for_free_update == nil then
            self.new_cfg.flags.only_check_for_free_update = false
        end

        if self.new_cfg.flags.only_check_for_free_update then
            self.frm.SettingsCheckForFreeUpdateCB.State = 1
        end

        if self.new_cfg.flags.cache_players_data then
            self.frm.CachePlayersDataCB.State = 1
        end

        if self.new_cfg.flags.hide_players_potential then
            self.frm.HidePlayerPotCB.State = 1
        end

    end

    -- Fill Auto Activation
    self.frm.CTTreeview.Items.clear()
    local root = self.frm.CTTreeview.Items.Add('Scripts')
    root.hasChildren = true
    root.Expanded = true

    self:FillScriptsTree(getAddressList().getMemoryRecordByDescription('Scripts'), root)

    -- Show correct panel
    self:ActivateSection(self.selection_idx)
end

function thisFormManager:onSaveSettingsClick(sender)
    local opacity = self.new_cfg.gui.opacity
    if opacity < 100 then
        opacity = 100
        self.new_cfg.gui.opacity = opacity
        self.frm.GUIOpacityEdit.Text = opacity
    elseif opacity > 255 then
        opacity = 255
        self.new_cfg.gui.opacity = opacity
        self.frm.GUIOpacityEdit.Text = opacity
    end

    local scripts_ids = {18}  -- Always expand 'Scripts'
    for i=0, self.frm.CTTreeview.Items.Count-1 do
        local is_selected = self.frm.CTTreeview.Items[i].MultiSelected
        if is_selected then
            table.insert(scripts_ids, self.frm.CTTreeview.Items[i].Data)
        end
    end

    for i = 1, #FORMS do
        local form = FORMS[i]

        -- Update opacity of all forms
        form.AlphaBlend = true
        form.AlphaBlendValue = opacity
    end
    self.new_cfg.auto_activate = scripts_ids

    self.new_cfg.flags.hide_ce_scanner = self.frm.HideCEMemScannerCB.State == 1

    self.new_cfg.flags.check_for_update = self.frm.SettingsCheckForUpdateCB.State == 1
    self.new_cfg.flags.only_check_for_free_update = self.frm.SettingsCheckForFreeUpdateCB.State == 1

    self.new_cfg.flags.cache_players_data = self.frm.CachePlayersDataCB.State == 1
    self.new_cfg.flags.hide_players_potential = self.frm.HidePlayerPotCB.State == 1

    self:save_cfg()
    showMessage('Settings has been saved.')
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    self.frm.RestoreDefaultSettingsButton.OnClick = function(sender)
    end
    self.frm.ClearCacheButton.OnClick = function(sender)
    end
    self.frm.CacheFilesDirEdit.OnClick = function(sender)
    end
    self.frm.GUIOpacityEdit.OnChange = function(sender)
        self.has_unsaved_changes = true
        local opacity = tonumber(sender.Text)
        if not opacity then return end
    
        self.new_cfg.gui.opacity = opacity
    end
    self.frm.HideCEMemScannerCB.OnChange = function(sender)
        self.has_unsaved_changes = true
        if sender.State == 1 then
            self.new_cfg.flags.hide_ce_scanner = true
        else
            self.new_cfg.flags.hide_ce_scanner = false
        end
    end

    self.frm.SettingsSaveSettings.OnClick = function(sender)
        self:onSaveSettingsClick(sender)
    end

    self.frm.SettingsSectionsListBox.OnSelectionChange = function(sender, user)
        self:SectionsListBoxSelectionChange(sender, user)
    end

end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self:assign_current_form_events()
end

return thisFormManager;