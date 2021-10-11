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

    self.default_teamsheets_addrs = {}
    self.default_mentalities_addrs = {}

    self.change_list = {}

    return o;
end

function thisFormManager:get_teamkits(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end
    local arr_flds = {
        {
            name = "teamtechid",
            expr = "eq",
            values = {teamid}
        }
    }

    local addrs = self.game_db_manager:find_record_addr(
        "teamkits", arr_flds
    )
    local found = #addrs or 0
    self.logger:info(string.format("Found %d teamkits for team %d", found, teamid))

    if found > 0 then
        writeQword("pTeamkitsTableCurrentRecord", addrs[1])
    end
    return addrs
end

function thisFormManager:get_competitionkits(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end
    local arr_flds = {
        {
            name = "teamtechid",
            expr = "eq",
            values = {teamid}
        }
    }

    local addrs = self.game_db_manager:find_record_addr(
        "competitionkits", arr_flds
    )
    local found = #addrs or 0
    self.logger:info(string.format("Found %d competitionkits for team %d", found, teamid))

    if found > 0 then
        writeQword("pCompetitionkitsTableCurrentRecord", addrs[1])
    end
    return addrs
end

function thisFormManager:get_team_default_teamsheet(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end
    local arr_flds = {
        {
            name = "teamid",
            expr = "eq",
            values = {teamid}
        }
    }

    local addrs = self.game_db_manager:find_record_addr(
        "default_teamsheets", arr_flds, 1
    )
    local found_default_teamsheets = #addrs or 0
    self.logger:info(string.format("Found %d default_teamsheets for team %d", found_default_teamsheets, teamid))

    if found_default_teamsheets > 0 then
        writeQword("pDefaultteamsheetsTableCurrentRecord", addrs[1])
    end
    return addrs
end

function thisFormManager:get_team_default_mentalities(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end
    local arr_flds = {
        {
            name = "teamid",
            expr = "eq",
            values = {teamid}
        }
    }

    local addrs = self.game_db_manager:find_record_addr(
        "default_mentalities", arr_flds, 5
    )
    local found_default_mentalities = #addrs or 0
    self.logger:info(string.format("Found %d default_mentalities for team %d", found_default_mentalities, teamid))

    return addrs
end

function thisFormManager:get_team_manager_record_addr(teamid)
    if type(teamid) == 'string' then
        teamid = tonumber(teamid)
    end
    local arr_flds = {
        {
            name = "teamid",
            expr = "eq",
            values = {teamid}
        }
    }

    local addr = self.game_db_manager:find_record_addr(
        "manager", arr_flds
    )

    if #addr <= 0 then
        self.logger:warning(string.format("No manager for teamid: %d", teamid))
        return 0
    end

    return addr[1]
end

function thisFormManager:swap_players(sender)
    if self.player_to_swap == nil then
        self.player_swap_img = createImage(sender.Parent)
        self.player_swap_img.Name = string.format("SwapImg%s", sender.Name)
        self.player_swap_img.Left = sender.Left + 20
        self.player_swap_img.Top = sender.Top + 20
        self.player_swap_img.Height = 32
        self.player_swap_img.Width = 32
        self.player_swap_img.Stretch = true
        self.player_swap_img.Hint = sender.Hint
        self.player_swap_img.ShowHint = true
        self.player_swap_img.Picture.LoadFromStream(findTableFile('refresh.png').Stream)
        self.player_swap_img.Visible = true
        self.player_swap_img.bringToFront()
        self.player_to_swap = sender
    else
        if self.player_to_swap == sender then
            self.player_to_swap = nil
            self.player_swap_img.destroy()
            self.player_swap_img = nil
            return 
        end

        local swap_idx0,_ = string.gsub(self.player_to_swap.Name, "%D", '')
        local swap_idx1,_ = string.gsub(sender.Name, "%D", '')
        swap_idx0 = tonumber(swap_idx0)
        swap_idx1 = tonumber(swap_idx1)

        local playerid0,_ = string.gsub(self.player_to_swap.Hint, "%D", '')
        local playerid1,_ = string.gsub(sender.Hint, "%D", '')

        local _iplayerid0 = tonumber(playerid0)
        local playername0 = self:get_player_name(_iplayerid0)
        local player0addr = nil
        if _iplayerid0 >= 280000 then
            player0addr = self:find_player_by_id(_iplayerid0)
        end

        local _iplayerid1 = tonumber(playerid1)
        local playername1 = self:get_player_name(_iplayerid1)
        local player1addr = nil
        if _iplayerid1 >= 280000 then
            player1addr = self:find_player_by_id(_iplayerid1)
        end

        if swap_idx0 and swap_idx1 then
            self.logger:debug(#self.team_formation_players)
            local p1 = self.team_formation_players[swap_idx0]
            local p2 = self.team_formation_players[swap_idx1]
            self.logger:debug(string.format(
                "Swap %d (%d) with %d (%d)", 
                p1, swap_idx0, 
                p2, swap_idx1
            ))
            self.team_formation_players[swap_idx0] = p2
            self.team_formation_players[swap_idx1] = p1
        end

        local ss_hs = self:load_headshot(
            _iplayerid0, player0addr
        )
        if self:safe_load_picture_from_ss(sender.Picture, ss_hs) then
            ss_hs.destroy()
        end

        ss_hs = self:load_headshot(
            _iplayerid1, player1addr
        )
        if self:safe_load_picture_from_ss(self.player_to_swap.Picture, ss_hs) then
            ss_hs.destroy()
        end

        sender.Hint = string.format("%s (ID: %s)", playername0 or '', playerid0)
        self.player_to_swap.Hint = string.format("%s (ID: %s)", playername1 or '', playerid1)

        local id0, _ = string.gsub(self.player_to_swap.Name, "%D", '')
        local id1, _ = string.gsub(sender.Name, "%D", '')

        local lbl_name = string.format("TeamPlayerIDLabel%d", id0)
        local lbl_comp = self.frm[lbl_name]
        if lbl_comp == nil then
            lbl_comp = self.frm.FormationReservesScroll[lbl_name]
        end
        if lbl_comp then
            lbl_comp.Caption = playername1 or playerid1
            lbl_comp.Hint = string.format("%s (ID: %s)", playername1 or '', playerid1)
            lbl_comp.ShowHint = true
        end

        lbl_name = string.format("TeamPlayerIDLabel%d", id1)
        local lbl_comp = self.frm[lbl_name]
        if lbl_comp == nil then
            lbl_comp = self.frm.FormationReservesScroll[lbl_name]
        end
        if lbl_comp then
            lbl_comp.Caption = playername0 or playerid0
            lbl_comp.Hint = string.format("%s (ID: %s)", playername0 or '', playerid0)
            lbl_comp.ShowHint = true
        end

        self.player_to_swap = nil
        self.player_swap_img.destroy()
        self.player_swap_img = nil
    end
end

function thisFormManager:update_formation_pitch(formation_data, teamsheet_addr)
    self.logger:info(string.format("update_formation_pitch. Formation id: %d", formation_data['sourceformationid']))

    if not teamsheet_addr then
        self.logger:warning("No teamsheet_addr")
        return
    end

    local fnSwapPlayers = function(sender)
        self.change_list["players_swapped"] = true
        self:swap_players(sender)
    end

    local pimgcomp = nil
    local plblcomp = nil
    local offsetx = nil
    local offsety = nil

    local scrnH = getScreenHeight()

    local w = self.frm.FormationPitchImg.Width - 20
    local h = 630

    if scrnH < 950 then
        self.logger:debug("small")
        h = 350
    end

    self.logger:debug(string.format("w: %d, h: %d", w, h))

    local pw = self.frm.TeamPlayerImg1.Width
    local ph = self.frm.TeamPlayerImg1.Height
    local playerid = -1
    local players_on_pitch = {}

    for i=0, self.frm.FormationReservesScroll.ComponentCount-1 do
        self.frm.FormationReservesScroll.Component[0].destroy()
    end
    local available_players_count = 0

    local owner = self.frm.FormationReservesScroll
    for i=0, #self.team_formation_players-1 do
        playerid = self.team_formation_players[i+1]
        if playerid == nil or playerid == -1 then break end

        local player_addr = nil
        if playerid >= 280000 then
            player_addr = self:find_player_by_id(playerid)
        end

        local playername = self:get_player_name(playerid)

        if i <= 10 then
            offsetx = formation_data[string.format("offset%dx", i)]
            offsety = formation_data[string.format("offset%dy", i)]
            pimgcomp = self.frm[string.format("TeamPlayerImg%d", i+1)]
            plblcomp = self.frm[string.format("TeamPlayerIDLabel%d", i+1)]

            pimgcomp.OnClick = fnSwapPlayers
            pimgcomp.Left = math.floor((offsetx * w) - pw/2 + 10)
            pimgcomp.Top = math.floor(h - ((offsety * h) + ( ph + 15)) + 10)

            plblcomp.Caption = playername or playerid
            plblcomp.AutoSize = false
            plblcomp.Width = pw
            plblcomp.Alignment = "taCenter"
            
            plblcomp.Hint = string.format("%s (ID: %d)", playername or '', playerid)
            plblcomp.ShowHint = true
            pimgcomp.Hint = string.format("%s (ID: %s)", playername or '', playerid)
            pimgcomp.ShowHint = true

            local ss_hs = self:load_headshot(
                playerid, player_addr
            )
            if self:safe_load_picture_from_ss(pimgcomp.Picture, ss_hs) then
                ss_hs.destroy()
            end
        else
            available_players_count = available_players_count + 1
            local left = 10
            if (i % 2 == 0) then
                left = left + 80
            end
            local top = 10 + (105 * math.floor(math.floor(i-11)/2))
            local headshot_img = createImage(owner)
            headshot_img.Name = string.format("TeamPlayerImg%d", i+1)
            headshot_img.OnClick = fnSwapPlayers
            headshot_img.Left = left
            headshot_img.Top = top
            headshot_img.Height = 75
            headshot_img.Width = 75
            headshot_img.Stretch = true
            headshot_img.Hint = string.format("%s (ID: %s)", playername or '', playerid)
            headshot_img.ShowHint = true
            --headshot_img.onClick = ClickSwapPlayers
            headshot_img.Cursor = "crHandPoint"

            local ss_hs = self:load_headshot(
                playerid, player_addr
            )
            if self:safe_load_picture_from_ss(headshot_img.Picture, ss_hs) then
                ss_hs.destroy()
            end

            local lbl = createLabel(owner)
            lbl.AutoSize = false
            lbl.Name = string.format("TeamPlayerIDLabel%d", i+1)
            lbl.Caption = playername or playerid
            lbl.Hint = string.format("%s (ID: %d)", playername or '', playerid)
            lbl.ShowHint = true
            lbl.Width = 75
            lbl.Height = 15
            lbl.Left = left
            lbl.Top = top + 83
            lbl.Alignment = "taCenter"
            lbl.Transparent = false
            lbl.ParentColor = false
            lbl.ParentFont = false
            lbl.Color = 0x00000000
            lbl.Font.Color = 0x00FFFFFF
        end
    end

    self.frm.TeamAvailablePlayersLabel.Caption = string.format("Available Players (%d)", available_players_count)
end

function thisFormManager:get_teamkits_components_description() 
    local fnUpdateComboHint = function(sender)
        if sender.ClassName == "TCEComboBox" then
            if sender.ItemIndex >= 0 then
                sender.Hint = sender.Items[sender.ItemIndex]
            else
                sender.Hint = "ERROR"
            end
        end
    end
    local fnCommonDBValGetter = function(addrs, table_name, field_name, raw)
        return self:fnCommonDBValGetter(addrs, table_name, field_name, raw)
    end
    local fnCommonOnChange = function(sender)
        -- self.logger:debug(string.format("thisFormManager: %s", sender.Name))
        fnUpdateComboHint(sender)
        self.has_unsaved_changes = true
        self.change_list[sender.Name] = sender.Text or sender.ItemIndex
    end
    local fnSaveCommon = function(addrs, comp_name, comp_desc)
        if comp_desc["not_editable"] then return end

        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]

        local addr = addrs[table_name]

        local new_value = self.frm[comp_name].Text
        local log_msg = string.format(
            "%X, %s - %s = %s",
            addr, table_name, field_name, new_value
        )
        self.logger:debug(log_msg)
        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value)
    end

    local fnTeamKitColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillKitColor(colorID)
    end
    local fnJerseyNumberColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillJerseyNumberColor(colorID)
    end

    local fnJerseyNameColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillJerseyNameColor(colorID)
    end

    local fnShortsNumberColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillShortsNumberColor(colorID)
    end

    local fnTeamKitHexColorOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('TeamKitColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('TeamKitColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('TeamKitColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('TeamKitColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end

    local fnTeamKitJerseyNumberHexColorOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('TeamKitJerseyNumberColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('TeamKitJerseyNumberColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('TeamKitJerseyNumberColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('TeamKitJerseyNumberColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end

    local fnTeamKitJerseyNameColorOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('TeamKitJerseyNameColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('TeamKitJerseyNameColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('TeamKitJerseyNameColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('TeamKitJerseyNameColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end

    local fnTeamKitShortsNumberColorOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('TeamKitShortsNumberColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('TeamKitShortsNumberColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('TeamKitShortsNumberColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('TeamKitShortsNumberColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end
    
    

    local components_description = {
        -- TeamKits
        KitTeamTechIDEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamtechid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamKitIDEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamkitid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamKitTypeTechIDEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamkittypetechid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamYearEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "year"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        }, 
        KitTeamPowidEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "powid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamDlcEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "dlc"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamIsembargoedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "isembargoed"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamIsinheritbasedetailmapEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "isinheritbasedetailmap"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamHasadvertisingkitEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "hasadvertisingkit"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamIslockedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "islocked"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamRenderingmaterialtypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "renderingmaterialtype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },

        KitTeamChestbadgeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "chestbadge"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamCaptainarmbandEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "captainarmband"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },

        TeamKitColor1Hex = {
            events = {
                OnChange = fnTeamKitHexColorOnChange
            }
        },
        TeamKitColor2Hex = {
            events = {
                OnChange = fnTeamKitHexColorOnChange
            }
        },
        TeamKitColor3Hex = {
            events = {
                OnChange = fnTeamKitHexColorOnChange
            }
        },
        TeamKitColor1RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorprimr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor1GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorprimg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor1BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorprimb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor1PercentEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorprimpercent"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor2RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorsecr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor2GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorsecg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor2BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorsecb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor2PercentEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolorsecpercent"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor3RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolortertr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor3GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolortertg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor3BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolortertb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },
        TeamKitColor3PercentEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "teamcolortertpercent"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamKitColorOnChange
            }
        },

        -- Jersey
        KitTeamJerseyFitEdit = { 
            db_field = {
                table_name = "teamkits",
                field_name = "jerseyfit"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseyshapestyleEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseyshapestyle"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseycollargeometrytypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseycollargeometrytype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseyrenderingdetailmaptypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseyrenderingdetailmaptype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseynamelayouttypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynamelayouttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseynamefonttypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynamefonttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamNumberfonttypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "numberfonttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseybacknamefontcaseEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseybacknamefontcase"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseybacknameplacementcodeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseybacknameplacementcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseyfrontnumberplacementcodeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseyfrontnumberplacementcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseyleftsleevebadgeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseyleftsleevebadge"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamJerseyrightsleevebadgeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseyrightsleevebadge"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamKitJerseyNumberColor1Hex = {
            events = {
                OnChange = fnTeamKitJerseyNumberHexColorOnChange
            }
        },
        TeamKitJerseyNumberColor2Hex = {
            events = {
                OnChange = fnTeamKitJerseyNumberHexColorOnChange
            }
        },
        TeamKitJerseyNumberColor3Hex = {
            events = {
                OnChange = fnTeamKitJerseyNumberHexColorOnChange
            }
        },
        TeamKitJerseyNameColor1Hex = {
            events = {
                OnChange = fnTeamKitJerseyNameColorOnChange
            }
        },
        TeamKitJerseyNumberColor1RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorprimr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor1GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorprimg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor1BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorprimb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor2RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorsecr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor2GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorsecg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor2BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorsecb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor3RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorterr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor3GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorterg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNumberColor3BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynumbercolorterb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNumberColorOnChange
            }
        },
        TeamKitJerseyNameColor1RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynamecolorr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNameColorOnChange
            }
        },
        TeamKitJerseyNameColor1GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynamecolorg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNameColorOnChange
            }
        },
        TeamKitJerseyNameColor1BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "jerseynamecolorb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnJerseyNameColorOnChange
            }
        },
        -- Shorts
        KitTeamShortStyleEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortstyle"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamShortsnumberfonttypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumberfonttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamShortsnumberplacementcodeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumberplacementcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        KitTeamShortsrenderingdetailmaptypeEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsrenderingdetailmaptype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamKitShortsNumberColor1Hex = {
            events = {
                OnChange = fnTeamKitShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor2Hex = {
            events = {
                OnChange = fnTeamKitShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor3Hex = {
            events = {
                OnChange = fnTeamKitShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor1RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorprimr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor1GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorprimg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor1BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorprimb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor2RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorsecr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor2GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorsecg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor2BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorsecb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor3RedEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorterr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor3GreenEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorterg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        },
        TeamKitShortsNumberColor3BlueEdit = {
            db_field = {
                table_name = "teamkits",
                field_name = "shortsnumbercolorterb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnShortsNumberColorOnChange
            }
        }
    }

    return components_description
end

function thisFormManager:get_competitionkits_components_description() 
    local fnUpdateComboHint = function(sender)
        if sender.ClassName == "TCEComboBox" then
            if sender.ItemIndex >= 0 then
                sender.Hint = sender.Items[sender.ItemIndex]
            else
                sender.Hint = "ERROR"
            end
        end
    end
    local fnCommonDBValGetter = function(addrs, table_name, field_name, raw)
        return self:fnCommonDBValGetter(addrs, table_name, field_name, raw)
    end
    local fnCommonOnChange = function(sender)
        -- self.logger:debug(string.format("thisFormManager: %s", sender.Name))
        fnUpdateComboHint(sender)
        self.has_unsaved_changes = true
        self.change_list[sender.Name] = sender.Text or sender.ItemIndex
    end
    local fnSaveCommon = function(addrs, comp_name, comp_desc)
        if comp_desc["not_editable"] then return end

        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]

        local addr = addrs[table_name]

        local new_value = self.frm[comp_name].Text
        local log_msg = string.format(
            "%X, %s - %s = %s",
            addr, table_name, field_name, new_value
        )
        self.logger:debug(log_msg)
        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value)
    end
    local fnCompetitionKitJerseyNumberColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillCompetitionJerseyNumberColor(colorID)
    end
    local fnCompetitionKitJerseyNameColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillCompetitionJerseyNameColor(colorID)
    end
    local fnCompetitionKitShortsNumberColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillCompetitionKitShortsNumberColor(colorID)
    end
    local fnCompetitionKitJerseyNumberColorHexOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('CompetitionKitJerseyNumberColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('CompetitionKitJerseyNumberColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('CompetitionKitJerseyNumberColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('CompetitionKitJerseyNumberColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end
    local fnCompetitionKitJerseyNameColorHexOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('CompetitionKitJerseyNameColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('CompetitionKitJerseyNameColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('CompetitionKitJerseyNameColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('CompetitionKitJerseyNameColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end
    local fnCompetitionKitShortsNumberColorHexOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('CompetitionKitShortsNumberColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('CompetitionKitShortsNumberColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('CompetitionKitShortsNumberColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('CompetitionKitShortsNumberColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end

    local components_description = {
        -- competitionkits
        CompetitionKitJerseyNumberColor1Hex = {
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorHexOnChange
            }
        },
        CompetitionKitJerseyNumberColor2Hex = {
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorHexOnChange
            }
        },
        CompetitionKitJerseyNumberColor3Hex = {
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorHexOnChange
            }
        },
        CompetitionKitJerseyNameColor1Hex = {
            events = {
                OnChange = fnCompetitionKitJerseyNameColorHexOnChange
            }
        },
        CompetitionKitShortsNumberColor1Hex = {
            events = {
                OnChange = fnCompetitionKitShortsNumberColorHexOnChange
            }
        },
        CompetitionKitShortsNumberColor2Hex = {
            events = {
                OnChange = fnCompetitionKitShortsNumberColorHexOnChange
            }
        },
        CompetitionKitShortsNumberColor3Hex = {
            events = {
                OnChange = fnCompetitionKitShortsNumberColorHexOnChange
            }
        },

        CompetitionKitTeamTechIDEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "teamtechid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitCompetitionIDEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "competitionid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamKitTypeTechIDEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "teamkittypetechid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamYearEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "year"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },

        CompetitionKitTeamJerseynamelayouttypeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynamelayouttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamJerseynamefonttypeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynamefonttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamNumberfonttypeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "numberfonttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamJerseybacknamefontcaseEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseybacknamefontcase"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamJerseybacknameplacementcodeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseybacknameplacementcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamJerseyfrontnumberplacementcodeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseyfrontnumberplacementcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitJerseyNumberColor1RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorprimr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor1GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorprimg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor1BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorprimb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor2RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorsecr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor2GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorsecg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor2BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorsecb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor3RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorterr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor3GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorterg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNumberColor3BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorterb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNumberColorOnChange
            }
        },
        CompetitionKitJerseyNameColor1RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynamecolorr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNameColorOnChange
            }
        },
        CompetitionKitJerseyNameColor1GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynamecolorg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNameColorOnChange
            }
        },
        CompetitionKitJerseyNameColor1BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynamecolorb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitJerseyNameColorOnChange
            }
        },
        CompetitionKitTeamShortsnumberfonttypeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "shortsnumberfonttype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitTeamShortsnumberplacementcodeEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "shortsnumberplacementcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CompetitionKitShortsNumberColor1RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorprimr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor1GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorprimg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor1BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorprimb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor2RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorsecr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor2GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorsecg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor2BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorsecb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor3RedEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorterr"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor3GreenEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorterg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
        CompetitionKitShortsNumberColor3BlueEdit = {
            db_field = {
                table_name = "competitionkits",
                field_name = "jerseynumbercolorterb"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCompetitionKitShortsNumberColorOnChange
            }
        },
    }

    return components_description
end

function thisFormManager:get_components_description()
    local fnUpdateComboHint = function(sender)
        if sender.ClassName == "TCEComboBox" then
            if sender.ItemIndex >= 0 then
                sender.Hint = sender.Items[sender.ItemIndex]
            else
                sender.Hint = "ERROR"
            end
        end
    end

    local fnCommonOnChange = function(sender)
        -- self.logger:debug(string.format("thisFormManager: %s", sender.Name))
        fnUpdateComboHint(sender)
        self.has_unsaved_changes = true
        self.change_list[sender.Name] = sender.Text or sender.ItemIndex
    end
    local fnCommonDBValGetter = function(addrs, table_name, field_name, raw)
        return self:fnCommonDBValGetter(addrs, table_name, field_name, raw)
    end

    local fnTeamColorOnChange = function(sender)
        self.change_list[sender.Name] = sender.Text
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        self:fillTeamColor(colorID)
    end

    local fnTeamColorHexOnChange = function(sender)
        local colorID, _ = string.gsub(sender.Name, '%D', '')
        local value = string.gsub(sender.Text, '#', '')
        value = string.gsub(value, '0x', '')
        if string.len(value) < 6 then
            return 0
        elseif string.len(value) > 6 then
            sender.Text = "#FFFFFF"
            return 1
        end
        local red = tonumber(string.sub(value, 1, 2), 16)
        local green = tonumber(string.sub(value, 3, 4), 16)
        local blue = tonumber(string.sub(value, 5, 6), 16)
    
        self.frm[string.format('TeamColor%dPreview', colorID)].Color = string.format(
            '0x%02X%02X%02X',
            blue,
            green,
            red
        )
    
        local red_comp = self.frm[string.format('TeamColor%dRedEdit', colorID)]
        local saved_red_onchange = red_comp.OnChange
        red_comp.OnChange = nil
        red_comp.Text = red
        red_comp.OnChange = saved_red_onchange

        local green_comp = self.frm[string.format('TeamColor%dGreenEdit', colorID)]
        local saved_green_onchange = green_comp.OnChange
        green_comp.OnChange = nil
        green_comp.Text = green
        green_comp.OnChange = saved_green_onchange
    
        local blue_comp = self.frm[string.format('TeamColor%dBlueEdit', colorID)]
        local saved_blue_onchange = blue_comp.OnChange
        blue_comp.OnChange = nil
        blue_comp.Text = blue
        blue_comp.OnChange = saved_blue_onchange

        self.change_list[red_comp.Name] = red
        self.change_list[green_comp.Name] = green
        self.change_list[blue_comp.Name] = blue
    end

    local fnFillCommonCB = function(sender, current_value, cb_rec_id)
        --self.logger:debug(string.format("Fill: %s", sender.Name))
        local has_items = sender.Items.Count > 0

        if type(tonumber) ~= "string" then
            current_value = tostring(current_value)
        end

        sender.Hint = ""

        local dropdown = getAddressList().getMemoryRecordByID(cb_rec_id)
        local dropdown_items = dropdown.DropDownList
        --self.logger:debug(string.format("dropdown_items: %d", dropdown_items.Count))
        for j = 0, dropdown_items.Count-1 do
            local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")
            --self.logger:debug(string.format("val: %d (%s)", val, type(val)))
            if not has_items then
                -- Fill combobox in GUI with values from memory record dropdown
                sender.items.add(desc)
            end

            if current_value == val then
                sender.Hint = desc
                sender.ItemIndex = j

                if has_items then return end
            end
        end
    end

    local fnOnChangeFormation = function(sender)
        local idx = sender.ItemIndex - 1
        if idx < 0 then idx = 0 end

        local mentality = self.frm.TeamFormationPlanCB.ItemIndex
        if not self.mentality_formations[mentality] then
            self.mentality_formations[mentality] = {
                formation_idx = idx
            }
        else
            self.mentality_formations[mentality]["formation_idx"] = idx
        end

        self:update_formation_pitch(
            FORMATIONS_DATA[idx],
            self.current_addrs["default_teamsheets"]
        )
        fnUpdateComboHint(sender)
    end

    local fnSaveCommonCB = function(addrs, comp_name, comp_desc)
        local component = self.frm[comp_name]
        local cb_rec_id = comp_desc["cb_id"]
        local new_value = 0
        if cb_rec_id then
            local dropdown = getAddressList().getMemoryRecordByID(cb_rec_id)
            local dropdown_items = dropdown.DropDownList
            local dropdown_selected_value = dropdown.Value
        
            for j = 0, dropdown_items.Count-1 do
                local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")
                if component.Items[component.ItemIndex] == desc then
                    new_value = tonumber(val)
                    break
                end
            end
        else 
            new_value = component.ItemIndex
        end

        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]
        local raw = comp_desc["db_field"]["raw_val"]

        local addr = addrs[table_name]

        local log_msg = string.format(
            "%X, %s - %s = %d",
            addr, table_name, field_name, new_value
        )
        self.logger:debug(log_msg)
        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value, raw)
    end

    local fnSaveCommon = function(addrs, comp_name, comp_desc)
        if comp_desc["not_editable"] then return end

        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]

        local addr = addrs[table_name]

        local new_value = self.frm[comp_name].Text
        local log_msg = string.format(
            "%X, %s - %s = %s",
            addr, table_name, field_name, new_value
        )
        self.logger:debug(log_msg)
        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value)
    end

    local components_description = {
        TeamIDEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamid"
            },
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            },
            not_editable = true
        },
        TeamOVREdit = {
            db_field = {
                table_name = "teams",
                field_name = "overallrating"
            },
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            },
            not_editable = true
        },
        TeamATTEdit = {
            db_field = {
                table_name = "teams",
                field_name = "attackrating"
            },
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            },
            not_editable = true
        },
        TeamMIDEdit = {
            db_field = {
                table_name = "teams",
                field_name = "midfieldrating"
            },
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            },
            not_editable = true
        },
        TeamDEFEdit = {
            db_field = {
                table_name = "teams",
                field_name = "defenserating"
            },
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            },
            not_editable = true
        },
        TeamFoundationEdit = {
            db_field = {
                table_name = "teams",
                field_name = "foundationyear"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamLeagueTitlesEdit = {
            db_field = {
                table_name = "teams",
                field_name = "leaguetitles"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamDomesticCupsEdit = {
            db_field = {
                table_name = "teams",
                field_name = "domesticcups"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamRivalTeamIDEdit = {
            db_field = {
                table_name = "teams",
                field_name = "rivalteam"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamBudgetEdit = {
            db_field = {
                table_name = "teams",
                field_name = "transferbudget"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamWorthEdit = {
            db_field = {
                table_name = "teams",
                field_name = "clubworth"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamStadiumCapacityEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamstadiumcapacity"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamClWinsEdit = {
            db_field = {
                table_name = "teams",
                field_name = "uefa_cl_wins"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamElWinsEdit = {
            db_field = {
                table_name = "teams",
                field_name = "uefa_el_wins"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamUEFAConsecutiveWinsEdit = {
            db_field = {
                table_name = "teams",
                field_name = "uefa_consecutive_wins"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PrevElWinnerCB = {
            db_field = {
                table_name = "teams",
                field_name = "prev_el_champ",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["NO_YES_CB"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamPopularityCB = {
            db_field = {
                table_name = "teams",
                field_name = "popularity",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["ZERO_TEN"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamDomPrestigeCB = {
            db_field = {
                table_name = "teams",
                field_name = "domesticprestige",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["ZERO_TEN"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamIntPrestigeCB = {
            db_field = {
                table_name = "teams",
                field_name = "internationalprestige",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["ZERO_TEN"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamProfitabilityCB = {
            db_field = {
                table_name = "teams",
                field_name = "profitability",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["ZERO_TEN"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamYouthDevCB = {
            db_field = {
                table_name = "teams",
                field_name = "youthdevelopment",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["ZERO_TEN"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamColor1Hex = {
            events = {
                OnChange = fnTeamColorHexOnChange
            }
        },
        TeamColor1RedEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor1r"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor1GreenEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor1g"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor1BlueEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor1b"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor2Hex = {
            events = {
                OnChange = fnTeamColorHexOnChange
            }
        },
        TeamColor2RedEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor2r"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor2GreenEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor2g"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor2BlueEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor2b"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor3Hex = {
            events = {
                OnChange = fnTeamColorHexOnChange
            }
        },
        TeamColor3RedEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor3r"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor3GreenEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor3g"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamColor3BlueEdit = {
            db_field = {
                table_name = "teams",
                field_name = "teamcolor3b"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnTeamColorOnChange
            }
        },
        TeamManagerIDEdit = {
            db_field = {
                table_name = "manager",
                field_name = "managerid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerFirstnameEdit = {
            db_field = {
                table_name = "manager",
                field_name = "firstname"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerSurnameEdit = {
            db_field = {
                table_name = "manager",
                field_name = "surname"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerCommonnameEdit = {
            db_field = {
                table_name = "manager",
                field_name = "commonname"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerNationalityCB = {
            db_field = {
                table_name = "manager",
                field_name = "nationality",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["PLAYERS_NATIONALITY"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHashighqualityheadCB = {
            db_field = {
                table_name = "manager",
                field_name = "hashighqualityhead",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["NO_YES_CB"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHeadAssetIDEdit = {
            db_field = {
                table_name = "manager",
                field_name = "headassetid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHeadclasscodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "headclasscode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHeadTypeCodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "headtypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHeadvariationEdit = {
            db_field = {
                table_name = "manager",
                field_name = "headvariation"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerBodyTypeCodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "bodytypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerGenderCB = {
            db_field = {
                table_name = "manager",
                field_name = "gender",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["GENDER_CB"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerEthnicityEdit = {
            db_field = {
                table_name = "manager",
                field_name = "ethnicity"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerSkintonecodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "skintonecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerSkintypecodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "skintypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerPersonalityEdit = {
            db_field = {
                table_name = "manager",
                field_name = "personalityid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerOutfitIDEdit = {
            db_field = {
                table_name = "manager",
                field_name = "outfitid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerSeasonaloutfitidEdit = {
            db_field = {
                table_name = "manager",
                field_name = "seasonaloutfitid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHairtypecodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "hairtypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHairstylecodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "hairstylecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHaircolorcodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "haircolorcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerFacialHairtypecodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "facialhairtypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerFacialHaircolorcodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "facialhaircolorcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerEyebrowcodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "eyebrowcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerEyecolorcodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "eyecolorcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerSideburnscodeEdit = {
            db_field = {
                table_name = "manager",
                field_name = "sideburnscode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerFaceposerpresetEdit = {
            db_field = {
                table_name = "manager",
                field_name = "faceposerpreset"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerHeightCB = {
            db_field = {
                table_name = "manager",
                field_name = "height",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["HEIGHT_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamManagerWeightCB = {
            db_field = {
                table_name = "manager",
                field_name = "weight",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["WEIGHT_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TeamFormationCB = {
            db_field = {
                table_name = "default_mentalities",
                field_name = "sourceformationid",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["FORMATION_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnOnChangeFormation
            }
        }
    }

    return components_description
end

function thisFormManager:fillTeamColor(colorID)
    self:fillColorPreview(colorID, "TeamColor")
end

function thisFormManager:fillKitColor(colorID)
    self:fillColorPreview(colorID, "TeamKitColor")
end

function thisFormManager:fillJerseyNumberColor(colorID)
    self:fillColorPreview(colorID, "TeamKitJerseyNumberColor")
end

function thisFormManager:fillCompetitionJerseyNumberColor(colorID)
    self:fillColorPreview(colorID, "CompetitionKitJerseyNumberColor")
end

function thisFormManager:fillJerseyNameColor(colorID)
    self:fillColorPreview(colorID, "TeamKitJerseyNameColor")
end

function thisFormManager:fillCompetitionJerseyNameColor(colorID)
    self:fillColorPreview(colorID, "CompetitionKitJerseyNameColor")
end

function thisFormManager:fillCompetitionKitShortsNumberColor(colorID)
    self:fillColorPreview(colorID, "CompetitionKitShortsNumberColor")
end

function thisFormManager:fillShortsNumberColor(colorID)
    self:fillColorPreview(colorID, "TeamKitShortsNumberColor")
end

function thisFormManager:get_playerlinks(teamid)
    local arr_flds = {
        {
            name = "teamid",
            expr = "eq",
            values = {teamid}
        }
    }

    local addrs = self.game_db_manager:find_record_addr(
        "teamplayerlinks", arr_flds
    )
    local found_teamplayerlinks = #addrs or 0
    self.logger:info(string.format("Found %d teamplayerlinks for team %d", found_teamplayerlinks, teamid))

    return addrs
end

function thisFormManager:get_playerlink(playerid, teamid)
    if #self.team_players_links == 0 and teamid >0 then
        self.team_players_links = self:get_playerlinks(teamid)
    end

    if #self.team_players_links == 0 then
        return 0
    end

    for i=1, #self.team_players_links do
        local addr = self.team_players_links[i]
        local pid = self.game_db_manager:get_table_record_field_value(addr, "teamplayerlinks", "playerid")
        if pid == playerid then
            return addr
        end
    end
    
    return 0
end

function thisFormManager:fill_teamkits()
    self.logger:debug(string.format("fill_teamkits"))
    local kits_comp_desc = self:get_teamkits_components_description()
    local addrs = self.current_addrs

    for i=0, self.frm.ComponentCount-1 do
        local component = self.frm.Component[i]
        if component == nil then
            goto continue
        end

        local component_name = component.Name
        --self.logger:debug(component.Name)
        local comp_desc = kits_comp_desc[component_name]
        if comp_desc == nil then
            goto continue
        end

        local component_class = component.ClassName
        component.OnChange = nil
        if component_class == 'TCEEdit' then
            if comp_desc["valGetter"] then
                component.Text = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
            else
                component.Text = "TODO SET VALUE!"
            end
        elseif component_class == 'TCETrackBar' then
            --
        elseif component_class == 'TCEComboBox' then
            --self.logger:debug(component.Name)
            if comp_desc["valGetter"] and comp_desc["cbFiller"] then
                local current_field_val = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
                --self.logger:debug(current_field_val)
                comp_desc["cbFiller"](
                    component,
                    current_field_val,
                    comp_desc["cb_id"]
                )
            else
                component.ItemIndex = 0
            end
            if component.ItemIndex >= 0 then
                component.Hint = component.Items[component.ItemIndex]
            else
                self.logger:warning(string.format("Invalid value: %s", component.Name))
                component.Hint = "ERROR"
            end
        elseif component_class == 'TCECheckBox' then
            component.State = comp_desc["valGetter"](addrs, comp_desc)
        end

        if comp_desc['events'] then
            for key, value in pairs(comp_desc['events']) do
                component[key] = value
            end
        end

        ::continue::
    end


    self:fillKitColor(1)
    self:fillKitColor(2)
    self:fillKitColor(3)

    self:fillJerseyNumberColor(1)
    self:fillJerseyNumberColor(2)
    self:fillJerseyNumberColor(3)

    self:fillJerseyNameColor(1)

    self:fillShortsNumberColor(1)
    self:fillShortsNumberColor(2)
    self:fillShortsNumberColor(3)
end

function thisFormManager:fill_competitionkits()
    self.logger:debug(string.format("fill_competitionkits"))
    local kits_comp_desc = self:get_competitionkits_components_description()
    local addrs = self.current_addrs

    for i=0, self.frm.ComponentCount-1 do
        local component = self.frm.Component[i]
        if component == nil then
            goto continue
        end

        local component_name = component.Name
        --self.logger:debug(component.Name)
        local comp_desc = kits_comp_desc[component_name]
        if comp_desc == nil then
            goto continue
        end

        local component_class = component.ClassName
        component.OnChange = nil
        if component_class == 'TCEEdit' then
            if comp_desc["valGetter"] then
                component.Text = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
            else
                component.Text = "TODO SET VALUE!"
            end
        elseif component_class == 'TCETrackBar' then
            --
        elseif component_class == 'TCEComboBox' then
            --self.logger:debug(component.Name)
            if comp_desc["valGetter"] and comp_desc["cbFiller"] then
                local current_field_val = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
                --self.logger:debug(current_field_val)
                comp_desc["cbFiller"](
                    component,
                    current_field_val,
                    comp_desc["cb_id"]
                )
            else
                component.ItemIndex = 0
            end
            if component.ItemIndex >= 0 then
                component.Hint = component.Items[component.ItemIndex]
            else
                self.logger:warning(string.format("Invalid value: %s", component.Name))
                component.Hint = "ERROR"
            end
        elseif component_class == 'TCECheckBox' then
            component.State = comp_desc["valGetter"](addrs, comp_desc)
        end

        if comp_desc['events'] then
            for key, value in pairs(comp_desc['events']) do
                component[key] = value
            end
        end

        ::continue::
    end

    self:fillCompetitionJerseyNumberColor(1)
    self:fillCompetitionJerseyNumberColor(2)
    self:fillCompetitionJerseyNumberColor(3)

    self:fillCompetitionJerseyNameColor(1)

    self:fillCompetitionKitShortsNumberColor(1)
    self:fillCompetitionKitShortsNumberColor(2)
    self:fillCompetitionKitShortsNumberColor(3)
end

function thisFormManager:fill_form(addrs, teamid)
    self.logger:debug(string.format("fill_form: %s", self.name))

    self.default_teamsheets_addrs = {}
    self.default_mentalities_addrs = {}
    self.team_formation_players = {}
    self.team_players_links = {}
    self.mentality_formations = {}
    local record_addr = addrs["teams"]

    if record_addr == nil and teamid == nil then
        self.logger:error(
            string.format("Can't Fill %s form. Team record address or teamid is required", self.name)
        )
    end

    if not teamid then
        teamid = self.game_db_manager:get_table_record_field_value(record_addr, "teams", "teamid")
    end

    if self.form_components_description == nil then
        self.form_components_description = self:get_components_description()
    end

    local manager_record_addr = self:get_team_manager_record_addr(teamid)
    if manager_record_addr then
        writeQword("pManagerTableCurrentRecord", manager_record_addr)
        self.current_addrs["manager"] = manager_record_addr
        addrs["manager"] = manager_record_addr
        self.logger:debug(string.format("Manager addr: %X", addrs["manager"]))
    end

    self.team_players_links = self:get_playerlinks(teamid)

    self.default_teamsheets_addrs = self:get_team_default_teamsheet(teamid)
    self.default_mentalities_addrs = self:get_team_default_mentalities(teamid)
    if #self.default_teamsheets_addrs > 0 and #self.default_mentalities_addrs > 0 then
        local teamsheet_addr = self.default_teamsheets_addrs[1]
        for j=0, 51 do
            local playerid = self.game_db_manager:get_table_record_field_value(
                teamsheet_addr, "default_teamsheets",
                string.format("playerid%d", j)
            )
            table.insert(self.team_formation_players, playerid)
        end

        self.current_addrs["default_teamsheets"] = teamsheet_addr

        local fnFormationPlanOnChange = function(sender)
            self:TeamFormationPlanOnChange(sender)
        end
    
        self.frm.TeamFormationPlanCB.OnChange = nil
        self.frm.TeamFormationPlanCB.clear()
        self.frm.TeamFormationPlanCB.items.add("ALL")

        local mentality_addr = self.default_mentalities_addrs[1]
        if #self.default_mentalities_addrs == 5 then
            self.frm.TeamFormationPlanCB.items.add("Ultra Defensive")
            self.frm.TeamFormationPlanCB.items.add("Defensive")
            self.frm.TeamFormationPlanCB.items.add("Balanced")
            self.frm.TeamFormationPlanCB.items.add("Attacking")
            self.frm.TeamFormationPlanCB.items.add("Ultra Attacking")
            self.frm.TeamFormationPlanCB.ItemIndex = 3
            mentality_addr = self.default_mentalities_addrs[3]
        else
            self.frm.TeamFormationPlanCB.ItemIndex = 0
        end
        self.frm.TeamFormationPlanCB.OnChange = fnFormationPlanOnChange

        local formationid = self.game_db_manager:get_table_record_field_value(mentality_addr, "default_mentalities", "sourceformationid") or 0
        if formationid < 0 then formationid = 0 end
        self:update_formation_pitch(
            FORMATIONS_DATA[formationid],
            teamsheet_addr
        )
        self.current_addrs["default_mentalities"] = mentality_addr
        self.current_addrs["default_teamsheets"] = teamsheet_addr
        self.frm.TeamFormationTab.Visible = true
    else
        self.current_addrs["default_mentalities"] = 0
        self.current_addrs["default_teamsheets"] = 0
        self.frm.TeamFormationTab.Visible = false
    end

    for i=0, self.frm.ComponentCount-1 do
        local component = self.frm.Component[i]
        if component == nil then
            goto continue
        end

        local component_name = component.Name
        --self.logger:debug(component.Name)
        local comp_desc = self.form_components_description[component_name]
        if comp_desc == nil then
            goto continue
        end

        local component_class = component.ClassName
        component.OnChange = nil
        if component_class == 'TCEEdit' then
            if comp_desc["valGetter"] then
                component.Text = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
            else
                component.Text = "TODO SET VALUE!"
            end
        elseif component_class == 'TCETrackBar' then
            --
        elseif component_class == 'TCEComboBox' then
            --self.logger:debug(component.Name)
            if comp_desc["valGetter"] and comp_desc["cbFiller"] then
                local current_field_val = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
                --self.logger:debug(current_field_val)
                comp_desc["cbFiller"](
                    component,
                    current_field_val,
                    comp_desc["cb_id"]
                )
            else
                component.ItemIndex = 0
            end
            if component.ItemIndex >= 0 then
                component.Hint = component.Items[component.ItemIndex]
            else
                self.logger:warning(string.format("Invalid value: %s", component.Name))
                component.Hint = "ERROR"
            end
        elseif component_class == 'TCECheckBox' then
            component.State = comp_desc["valGetter"](addrs, comp_desc)
        end

        if comp_desc['events'] then
            for key, value in pairs(comp_desc['events']) do
                component[key] = value
            end
        end

        ::continue::
    end

    local ss_c = self:load_crest(
        teamid, record_addr
    )
    if self:safe_load_picture_from_ss(self.frm.ClubCrest.Picture, ss_c) then
        ss_c.destroy()
        self.frm.ClubCrest.Picture.stretch=true
    end

    self:fillTeamColor(1)
    self:fillTeamColor(2)
    self:fillTeamColor(3)

    local teamname = self.game_db_manager:get_table_record_field_value(record_addr, "teams", "teamname") or ""

    local caption = string.format("%s (ID: %d)", teamname, teamid)

    self.frm.TeamNameLabel.Caption = caption
    self.frm.ClubCrest.Hint = caption
    self.frm.ClubCrest.ShowHint = true

    -- Team Kits
    self:clear_kits()

    self.teamkits_addrs = self:get_teamkits(teamid)

    local kitcompids = {}
    local tmp_kits = {}
    if #self.teamkits_addrs > 0 then
        table.insert(kitcompids, 0)
        tmp_kits[0] = {}
        for i=1, #self.teamkits_addrs do
            local teamkit_addr = self.teamkits_addrs[i]
            local kittypeid = self.game_db_manager:get_table_record_field_value(teamkit_addr, "teamkits", "teamkittypetechid")
            local kittypename = KITTYPE_NAMES[kittypeid] or string.format("Unknown Kit (%d)", kittypeid)

            local itm = {
                dbtable = "teamkits",
                addr = teamkit_addr
            }
            itm["lbl"] = kittypename
            tmp_kits[0][kittypeid] = itm
        end
    end

    self.competitionkits_addrs = self:get_competitionkits(teamid)

    if #self.competitionkits_addrs > 0 then 
        for i=1, #self.competitionkits_addrs do
            local compkit_addr = self.competitionkits_addrs[i]
            local competitionid = self.game_db_manager:get_table_record_field_value(compkit_addr, "competitionkits", "competitionid")
            local kittypeid = self.game_db_manager:get_table_record_field_value(compkit_addr, "competitionkits", "teamkittypetechid")
            local kittypename = KITTYPE_NAMES[kittypeid] or string.format("Unknown Kit (%d)", kittypeid)

            if not tmp_kits[competitionid] then
                table.insert(kitcompids, competitionid)
                tmp_kits[competitionid] = {}
            end

            kittypename = string.format("C%d - %s", competitionid, kittypename)

            local itm = {
                dbtable = "competitionkits",
                addr = compkit_addr
            }
        
            itm["lbl"] = kittypename
            tmp_kits[competitionid][kittypeid] = itm
        end
    end
    table.sort(kitcompids)

    local kit_idx = 0
    for i=1, #kitcompids do
        local cid = kitcompids[i]
        local compkits = tmp_kits[cid]

        for j=0, 23 do
            local compkit = compkits[j]
            if compkit then
                self.kits[kit_idx] = compkit
                self.frm.KitPickListBox.Items.Add(compkit["lbl"])

                kit_idx = kit_idx + 1
            end
        end
    end

    self.has_unsaved_changes = false
    self.logger:debug(string.format("fill_form %s done", self.name))
end

function thisFormManager:onShow(sender, team_addr)
    self.logger:debug(string.format("onShow: %s", self.name))
    -- Show Loading panel
    self.frm.WhileLoadingPanel.Visible = true
    self.frm.FindTeamBtn.Visible = false

    local onShow_delayed_wrapper = function()
        self:onShow_delayed(team_addr)
    end

    self.fill_timer = createTimer(nil)

    -- Load Data
    timer_onTimer(self.fill_timer, onShow_delayed_wrapper)
    timer_setInterval(self.fill_timer, 1000)
    timer_setEnabled(self.fill_timer, true)
end

function thisFormManager:onShow_delayed(team_addr)
    -- Disable Timer
    timer_setEnabled(self.fill_timer, false)
    self.fill_timer = nil

    self.current_addrs = {}
    self.current_addrs["teams"] = team_addr or readPointer("pTeamsTableCurrentRecord")
    self.current_addrs["manager"] = 0
    self.current_addrs["default_mentalities"] = 0
    self.current_addrs["default_teamsheets"] = 0
    self.current_addrs["teamkits"] = 0
    self.current_addrs["competitionkits"] = 0

    gCTManager:init_ptrs()
    self.game_db_manager:cache_player_names()

    self:fill_form(self.current_addrs)

    -- Hide Loading Panel and show components
    self.frm.WhileLoadingPanel.Visible = false
    self.frm.FindTeamBtn.Visible = true
end

function thisFormManager:TeamFormationPlanOnChange(sender)
    local idx = sender.ItemIndex
    if #self.default_mentalities_addrs == 5 then
        -- formation balanced
        if idx == 0 then
            idx = 3
        end

        local formationid = self.game_db_manager:get_table_record_field_value(self.default_mentalities_addrs[idx], "default_mentalities", "sourceformationid") or 0
        if formationid < 0 then formationid = 0 end
        
        local org_onchange = self.frm.TeamFormationCB.OnChange
        self.frm.TeamFormationCB.OnChange = nil
        self.frm.TeamFormationCB.ItemIndex = formationid+1
        self.frm.TeamFormationCB.Hint = self.frm.TeamFormationCB.Items[self.frm.TeamFormationCB.ItemIndex]
        self.frm.TeamFormationCB.OnChange = org_onchange
        self:update_formation_pitch(
            FORMATIONS_DATA[formationid],
            self.default_teamsheets_addrs[1]
        )
    end
end

function thisFormManager:check_if_has_unsaved_changes()
    if self.has_unsaved_changes then
        if messageDialog("You have some unsaved changes in team editor\nDo you want to apply them?", mtInformation, mbYes,mbNo) == mrYes then
            self:onApplyChangesBtnClick()
        else
            self.has_unsaved_changes = false
            self.default_teamsheets_addrs = {}
            self.default_mentalities_addrs = {}
            self.team_formation_players = {}
            self.team_players_links = {}
            self.mentality_formations = {}
            self.change_list = {}
        end
    end
end

function thisFormManager:onKitPickListBoxSelectionChange(sender, user)
    local selected = self.frm.KitPickListBox.ItemIndex

    if not self.kits[selected] then
        self:TeamKitsTabsVis(false)
        self:CompetitionKitsTabsVis(false)
        self.frm.TeamKitsTabsContainer.Visible = false
        self.frm.TeamCompetitionKitsTabsContainer.Visible = false
        return 
    end

    self.selected_kit = self.kits[selected]

    self.current_addrs[self.selected_kit.dbtable] = self.selected_kit.addr

    --print(string.format("%s: 0x%X",self.selected_kit.dbtable, self.selected_kit.addr))
    if self.selected_kit.dbtable == "teamkits" then
        self:fill_teamkits()

        self:TeamKitsTabsVis(true)
        self:CompetitionKitsTabsVis(false)
        self.frm.TeamKitsTabsContainer.Visible = true
        self.frm.TeamCompetitionKitsTabsContainer.Visible = false
    elseif self.selected_kit.dbtable == "competitionkits" then
        self:fill_competitionkits()
        
        self:TeamKitsTabsVis(false)
        self:CompetitionKitsTabsVis(true)
        self.frm.TeamKitsTabsContainer.Visible = false
        self.frm.TeamCompetitionKitsTabsContainer.Visible = true
    else
        print("WTF " .. self.selected_kit.dbtable)
        self:TeamKitsTabsVis(false)
        self:CompetitionKitsTabsVis(false)
        self.frm.TeamKitsTabsContainer.Visible = false
        self.frm.TeamCompetitionKitsTabsContainer.Visible = false
    end

end

function thisFormManager:onApplyChangesBtnClick()
    self.logger:info("Apply Changes team")

    local kits_comp_desc = self:get_teamkits_components_description()
    local compkits_comp_desc = self:get_competitionkits_components_description()

    self.logger:debug("Iterate change_list")
    for key, value in pairs(self.change_list) do
        local comp_desc = self.form_components_description[key] or kits_comp_desc[key] or compkits_comp_desc[key]
        local component = self.frm[key]
        if component then
            local component_class = component.ClassName

            self.logger:debug(string.format(
                "Edited comp: %s (%s), val: %s",
                key, component_class, value
            ))
            if component_class == 'TCEEdit' then
                if comp_desc["OnSaveChanges"] then
                    comp_desc["OnSaveChanges"](
                        self.current_addrs, key, comp_desc
                    )
                end
            elseif component_class == 'TCECheckBox' then
                if comp_desc["OnSaveChanges"] then
                    comp_desc["OnSaveChanges"](
                        self.current_addrs, key, comp_desc
                    )
                end
            elseif component_class == 'TCEComboBox' then
                if comp_desc["OnSaveChanges"] then
                    comp_desc["OnSaveChanges"](
                        self.current_addrs, key, comp_desc
                    )
                end
            end
        end
    end

    local must_update_players = false
    local formationid = 0
    if self.mentality_formations[0] then
        self.logger:debug("overwrite all mentalities")
        must_update_players = true
        formationid = self.mentality_formations[0]["formation_idx"]
        for j=1, #self.default_mentalities_addrs do
            local addr = self.default_mentalities_addrs[j]
            for k, v in pairs(FORMATIONS_DATA[formationid]) do
                self.game_db_manager:set_table_record_field_value(addr, "default_mentalities", k, v)
            end
        end
    else
        for key, value in pairs(self.mentality_formations) do
            if key ~= 0 then
                must_update_players = true
                self.logger:debug(string.format("overwrite %d mentality", key))
                formationid = value["formation_idx"]
                local addr = self.default_mentalities_addrs[key]
                for k, v in pairs(FORMATIONS_DATA[formationid]) do
                    self.game_db_manager:set_table_record_field_value(addr, "default_mentalities", k, v)
                end
            end
        end
    end

    if self.change_list["players_swapped"] or must_update_players then
        local mentality_addr = self.default_mentalities_addrs[1]
        if #self.default_mentalities_addrs == 5 then
            mentality_addr = self.default_mentalities_addrs[3]
        end
    
        formationid = self.game_db_manager:get_table_record_field_value(mentality_addr, "default_mentalities", "sourceformationid") or 0
        if formationid < 0 then formationid = 0 end
        for i=1, #self.team_formation_players do
            local db_field_name = string.format("playerid%d", i-1)
            local playerid = self.team_formation_players[i]

            self.logger:debug(string.format("%s -> %d", db_field_name, playerid))
            for j=1, #self.default_teamsheets_addrs do
                local addr = self.default_teamsheets_addrs[j]
                self.game_db_manager:set_table_record_field_value(addr, "default_teamsheets", db_field_name, playerid)
            end

            local playerlinkaddr = self:get_playerlink(playerid)

            if i <= 11 then
                local positionid = FORMATIONS_DATA[formationid][string.format("position%d", i-1)]
                self.logger:debug(string.format("%d -> Position %d", playerid, positionid))
                if playerlinkaddr > 0 then
                    self.game_db_manager:set_table_record_field_value(playerlinkaddr, "teamplayerlinks", "position", positionid)
                end

                for j=1, #self.default_mentalities_addrs do
                    local addr = self.default_mentalities_addrs[j]
                    self.game_db_manager:set_table_record_field_value(addr, "default_mentalities", db_field_name, playerid)
                end
            elseif i <= 18 and playerlinkaddr > 0 then
                -- substitute
                self.logger:debug(string.format("%d -> Position %d", playerid, 28))
                self.game_db_manager:set_table_record_field_value(playerlinkaddr, "teamplayerlinks", "position", 28)
            elseif playerlinkaddr > 0 then
                -- tribune
                self.logger:debug(string.format("%d -> Position %d", playerid, 29))
                self.game_db_manager:set_table_record_field_value(playerlinkaddr, "teamplayerlinks", "position", 29)
            end
        end
    end

    self.has_unsaved_changes = false
    self.change_list = {}
    self.mentality_formations = {}
    local msg = string.format("Team with ID %s has been edited", self.frm.TeamIDEdit.Text)
    showMessage(msg)
    self.logger:info(msg)
end

function thisFormManager:clear_kits()
    self.frm.KitPickListBox.clear()
    self.kits = {}
    self.selected_kit = {}
    self.teamkits_addrs = {}
    self.competitionkits_addrs = {}
end

function thisFormManager:TeamKitsTabsVis(state)
    for comp, _ in pairs(self.teamkits_tab_panel_map) do
        self.frm[comp].Visible = state
    end
end

function thisFormManager:CompetitionKitsTabsVis(state)
    for comp, _ in pairs(self.competitionkits_tab_panel_map) do
        self.frm[comp].Visible = state
    end
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    local fnTabClick = function(sender)
        self:TabClick(sender)
    end

    local fnTabMouseEnter= function(sender)
        self:TabMouseEnter(sender)
    end

    local fnTabMouseLeave = function(sender)
        self:TabMouseLeave(sender)
    end

    local fnTeamKitsTabClick = function(sender)
        if self.frm[self.teamkits_tab_panel_map[sender.Name]].Visible then return end

        for key,value in pairs(self.teamkits_tab_panel_map) do
            if key == sender.Name then
                sender.Color = '0x001D1618'
                self.frm[value].Visible = true
            else
                self.frm[key].Color = '0x003F2F34'
                self.frm[value].Visible = false
            end
        end
    end

    local fnTeamCompKitsTabClick = function(sender)
        if self.frm[self.competitionkits_tab_panel_map[sender.Name]].Visible then return end

        for key,value in pairs(self.competitionkits_tab_panel_map) do
            if key == sender.Name then
                sender.Color = '0x001D1618'
                self.frm[value].Visible = true
            else
                self.frm[key].Color = '0x003F2F34'
                self.frm[value].Visible = false
            end
        end
    end

    self.frm.TeamInfoTab.OnClick = fnTabClick
    self.frm.TeamInfoTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamInfoTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TeamFormationTab.OnClick = fnTabClick
    self.frm.TeamFormationTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamFormationTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TeamManagerTab.OnClick = fnTabClick
    self.frm.TeamManagerTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamManagerTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TeamKitsTab.OnClick = fnTabClick
    self.frm.TeamKitsTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamKitsTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TeamKitsGeneralTab.OnClick = fnTeamKitsTabClick
    self.frm.TeamKitsGeneralTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamKitsGeneralTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TeamKitsJerseyTab.OnClick = fnTeamKitsTabClick
    self.frm.TeamKitsJerseyTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamKitsJerseyTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TeamKitsShortsTab.OnClick = fnTeamKitsTabClick
    self.frm.TeamKitsShortsTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TeamKitsShortsTab.OnMouseLeave = fnTabMouseLeave

    self.frm.CompetitionKitsGeneralTab.OnClick = fnTeamCompKitsTabClick
    self.frm.CompetitionKitsGeneralTab.OnMouseEnter = fnTabMouseEnter
    self.frm.CompetitionKitsGeneralTab.OnMouseLeave = fnTabMouseLeave

    self.frm.CompetitionKitsJerseyTab.OnClick = fnTeamCompKitsTabClick
    self.frm.CompetitionKitsJerseyTab.OnMouseEnter = fnTabMouseEnter
    self.frm.CompetitionKitsJerseyTab.OnMouseLeave = fnTabMouseLeave

    self.frm.CompetitionKitsShortsTab.OnClick = fnTeamCompKitsTabClick
    self.frm.CompetitionKitsShortsTab.OnMouseEnter = fnTabMouseEnter
    self.frm.CompetitionKitsShortsTab.OnMouseLeave = fnTabMouseLeave

    self.frm.SyncImage.OnClick = function(sender)
        if not self.current_addrs["teams"] then return end
        self:check_if_has_unsaved_changes()
        self:onShow()
    end

    self.frm.KitPickListBox.OnSelectionChange = function(sender, user)
        self:onKitPickListBoxSelectionChange(sender, user)
    end

    self.frm.ApplyChangesBtn.OnClick = function(sender)
        self:onApplyChangesBtnClick()
    end

    self.frm.ApplyChangesBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.ApplyChangesBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.ApplyChangesBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.FindTeamBtn.OnClick = function(sender)
        FindTeamForm.show()
    end

    self.frm.FindTeamBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.FindTeamBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.FindTeamBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end
end

function thisFormManager:setup(params)
    self.cfg = params.cfg
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.logger:info(string.format("Setup Form Manager: %s", self.name))
    self.tab_panel_map = {
        TeamInfoTab = "TeamInfoPanel",
        TeamFormationTab = "TeamFormationPanel",
        TeamManagerTab = "TeamManagerPanel",
        TeamKitsTab = "TeamKitsPanel",
        TeamKitsGeneralTab = "TeamKitsKitPanel",
        TeamKitsJerseyTab = "TeamKitsJerseyPanel",
        TeamKitsShortsTab = "TeamKitsShortsPanel",
        CompetitionKitsGeneralTab = "TeamCompetitionKitsKitPanel",
        CompetitionKitsJerseyTab = "TeamCompetitionKitsJerseyPanel",
        CompetitionKitsShortsTab = "TeamCompetitionKitsShortsPanel",
    }
    self.change_list = {}
    self.default_teamsheets_addrs = {}
    self.default_mentalities_addrs = {}
    self.teamkits_addrs = {}
    self.competitionkits_addrs = {}
    self.selected_kit = {}
    self.kits = {}
    self.team_formation_players = {}
    self.team_players_links = {}
    self.mentality_formations = {}
    self.player_to_swap = nil
    self.player_swap_img = nil

    self.teamkits_tab_panel_map = {
        TeamKitsGeneralTab = "TeamKitsKitPanel",
        TeamKitsJerseyTab = "TeamKitsJerseyPanel",
        TeamKitsShortsTab = "TeamKitsShortsPanel"
    }

    self.competitionkits_tab_panel_map = {
        CompetitionKitsGeneralTab = "TeamCompetitionKitsKitPanel",
        CompetitionKitsJerseyTab = "TeamCompetitionKitsJerseyPanel",
        CompetitionKitsShortsTab = "TeamCompetitionKitsShortsPanel",
    }

    local scrnW = getScreenWidth()
    local scrnH = getScreenHeight()

    if scrnH >= 950 and self.frm.Height ~= 900 then
        self.logger:info(string.format("Resize teams editor: %s", self.name))
        self.frm.Width = 1270
        self.frm.Height = 900
        self.frm.Top = 50
        self.frm.FormationSmallPitchImg.Visible = false
        self.frm.FormationPitchImg.Visible = true
        for i=0, 10 do
            local pimgcomp = self.frm[string.format("TeamPlayerImg%d", i+1)]
            pimgcomp.Width = 75
            pimgcomp.Height = 75
        end
    end

    self:assign_current_form_events()
end

return thisFormManager;