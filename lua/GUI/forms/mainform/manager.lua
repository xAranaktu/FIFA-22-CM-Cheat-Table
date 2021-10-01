

local FormManager = require 'lua/imports/FormManager';

local thisFormManager = FormManager:new()

function thisFormManager:new(o)
    o = o or FormManager:new(o)
    setmetatable(o, self)
    self.__index = self
    
    self.cfg = nil
    self.logger = nil

    self.frm = nil
    self.name = ""

    self.ce_visible = false

    return o;
end


function thisFormManager:update_status(new_status)
    self.frm.LabelStatus.Caption = new_status
end

function thisFormManager:remove_loading_panel()
    self.frm.LoadingPanel.Visible = false
end

function thisFormManager:load_images()
    local stream = self:load_headshot(41)
    self.frm.PlayersEditorImg.Picture.LoadFromStream(stream)
    stream.destroy()

    stream = self:load_crest(1)
    self.frm.TeamsEditorImg.Picture.LoadFromStream(stream)
    stream.destroy()
end

function thisFormManager:onSettingsClick()
    SettingsForm.show()
end

function thisFormManager:onCEClick()
    self.ce_visible = not self.ce_visible

    getMainForm().Visible = self.ce_visible
end

function thisFormManager:OnWindowCloseClick(sender)
    local addrlist = getAddressList()
    -- Deactivate scripts on Exit while in DEBUG MODE
    if DEBUG_MODE then
        local scripts_record = addrlist.getMemoryRecordByDescription('Scripts')
        deactive_all(scripts_record)

        -- Deactivate hidden stuff too
        deactive_all(addrlist.getMemoryRecordByID(13))

        scripts_record.Active = false
        -- Deactivate CURRENT_DATE_SCRIPT
        -- ADDR_LIST.getMemoryRecordByID(CT_MEMORY_RECORDS['CURRENT_DATE_SCRIPT']).Active = false

        -- Deactivate hook loadlibrary & exit cm
        -- ADDR_LIST.getMemoryRecordByID(4831).Active = false
    end
    -- Deactivate "GUI" script
    addrlist.getMemoryRecordByID(CT_MEMORY_RECORDS['GUI_SCRIPT']).Active = false
    self.frm.close()
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    local org_onCEClose = getMainForm().OnClose
    getMainForm().OnClose = function(sender)
        self.logger:info("Deactivating all scripts")

        local addrlist = getAddressList() 
        for i=0,addrlist.Count-1 do
            local entry = addrlist[i]
            if entry.Active then
                self.logger:debug(string.format("Deactivating: %s", entry.Description))
                entry.Active = false
            end
        end
        self.logger:info("Deactivated all scripts")
        org_onCEClose(sender)
        return caFree 
    end

    self.frm.Exit.OnClick = function(sender)
        self:OnWindowCloseClick(sender)
    end

    self.frm.LabelLatestLEVer.OnClick = function(sender)
        shellExecute("https://www.patreon.com/xAranaktu/posts?filters[tag]=CM Cheat Table")
    end

    self.frm.Patreon.OnClick = function(sender)
        shellExecute(URL_LINKS.PATREON)
    end

    self.frm.Discord.OnClick = function(sender)
        shellExecute(URL_LINKS.DISCORD)
    end

    self.frm.Settings.OnClick = function(sender)
        self:onSettingsClick(sender)
    end

    self.frm.CE.OnClick = function(sender)
        self:onCEClick(sender)
    end

    self.frm.PlayersEditorImg.OnClick = function(sender)
        PlayersEditorForm.show()
    end

    self.frm.PlayersEditorBtn.OnClick = function(sender)
        PlayersEditorForm.show()
    end

    self.frm.PlayersEditorBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.PlayersEditorBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.PlayersEditorBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.TeamsEditorImg.OnClick = function(sender)
        TeamsEditorForm.show()
    end

    self.frm.TeamsEditorBtn.OnClick = function(sender)
        TeamsEditorForm.show()
    end

    self.frm.TeamsEditorBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.TeamsEditorBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.TeamsEditorBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.PlayersTransferImg.OnClick = function(sender)
        TransferPlayersForm.show()
    end

    self.frm.PlayersTransferBtn.OnClick = function(sender)
        TransferPlayersForm.show()
    end

    self.frm.PlayersTransferBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.PlayersTransferBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.PlayersTransferBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.ScheduleEditorImg.OnClick = function(sender)
        MatchScheduleEditorForm.show()
    end

    self.frm.ScheduleEditorBtn.OnClick = function(sender)
        MatchScheduleEditorForm.show()
    end

    self.frm.ScheduleEditorBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.ScheduleEditorBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.ScheduleEditorBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.MatchFixingImg.OnClick = function(sender)
        MatchFixingForm.show()
    end
    
    self.frm.MatchFixingBtn.OnClick = function(sender)
        MatchFixingForm.show()
    end

    self.frm.MatchFixingBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.MatchFixingBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.MatchFixingBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end
end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self.frm.LoadingPanel.Visible = true
    self.frm.LoadingPanel.Caption = "Loading data..."

    self:assign_current_form_events()
end

return thisFormManager;