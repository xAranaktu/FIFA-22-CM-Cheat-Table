require 'lua/consts';
require 'lua/helpers';
json = require 'lua/requirements/json';

local FormManager = require 'lua/imports/FormManager';

local thisFormManager = FormManager:new()

function thisFormManager:new(o)
    o = o or FormManager:new(o)
    setmetatable(o, self)
    self.__index = self
    
    self.dirs = nil
    self.logger = nil

    self.frm = nil
    self.name = ""

    self.game_db_manager = nil
    self.memory_manager = nil

    self.has_unsaved_changes = false

    self.fill_timer = nil
    self.form_components_description = nil
    self.current_addrs = {}
    self.tab_panel_map = {}

    self.change_list = {}

    self.fut_found_players = nil
    self.cm_found_player_addr = 0

    return o;
end

function thisFormManager:update_total_stats()
    local sum = 0
    local attr_panel = self.frm.AttributesPanel
    for i = 0, attr_panel.ControlCount-1 do
        for j=0, attr_panel.Control[i].ControlCount-1 do
            local comp = attr_panel.Control[i].Control[j]
            if comp.ClassName == 'TCEEdit' then
                sum = sum + tonumber(comp.Text)
            end
        end
    end

    if sum > 3366 then
        sum = 3366
    elseif sum < 0 then
        sum = 0
    end

    self.frm.TotalStatsValueLabel.Caption = string.format(
        "%d / 3366", sum
    )
    self.frm.TotalStatsValueBar.Position = sum
end

function thisFormManager:recalculate_ovr(update_ovr_edit)
    local preferred_position_id = self.frm.PreferredPosition1CB.ItemIndex
    if preferred_position_id == 1 then return end -- ignore SW

    -- top 3 values will be put in "Best At"
    local unique_ovrs = {}
    local top_ovrs = {}

    local calculated_ovrs = {}
    for posid, attributes in pairs(OVR_FORMULA) do
        local sum = 0
        for attr, perc in pairs(attributes) do
            local attr_val = tonumber(self.frm[attr].Text)
            if attr_val == nil then
                return
            end
            sum = sum + (attr_val * perc)
        end
        sum = math.round(sum)
        unique_ovrs[sum] = sum

        calculated_ovrs[posid] = sum
    end
    if update_ovr_edit then
        self.frm.OverallEdit.Text = calculated_ovrs[string.format("%d", preferred_position_id)] + tonumber(self.frm.ModifierEdit.Text)
    end

    local iovr = tonumber(self.frm.OverallEdit.Text)
    if iovr then
        if iovr > 99 then 
            self.frm.OverallEdit.Text = 99
        elseif iovr <= 0 then
            self.frm.OverallEdit.Text = 1
        end
    end
    self.change_list["OverallEdit"] = self.frm.OverallEdit.Text

    for k,v in pairs(unique_ovrs) do
        table.insert(top_ovrs, k)
    end

    table.sort(top_ovrs, function(a,b) return a>b end)

    -- Fill "Best At"
    local position_names = {
        ['1'] = {
            short = {},
            long = {},
            showhint = false
        },
        ['2'] = {
            short = {},
            long = {},
            showhint = false
        },
        ['3'] = {
            short = {},
            long = {},
            showhint = false
        }
    }
    -- remove useless pos
    local not_show = {
        4,6,9,11,13,15,17,19
    }
    for posid, ovr in pairs(calculated_ovrs) do
        for i = 1, #not_show do
            if tonumber(posid) == not_show[i] then
                goto continue
            end
        end
        for i = 1, 3 do
            if ovr == top_ovrs[i] then
                if #position_names[string.format("%d", i)]['short'] <= 2 then
                    table.insert(position_names[string.format("%d", i)]['short'], self.frm.PreferredPosition1CB.Items[tonumber(posid)])
                elseif #position_names[string.format("%d", i)]['short'] == 3 then
                    table.insert(position_names[string.format("%d", i)]['short'], '...')
                    position_names[string.format("%d", i)]['showhint'] = true
                end
                table.insert(position_names[string.format("%d", i)]['long'], self.frm.PreferredPosition1CB.Items[tonumber(posid)])
            end
        end
        ::continue::
    end

    for i = 1, 3 do
        if top_ovrs[i] then
            self.frm[string.format("BestPositionLabel%d", i)].Caption = string.format("- %s: %d ovr", table.concat(position_names[string.format("%d", i)]['short'], '/'), top_ovrs[i])
            if position_names[string.format("%d", i)]['showhint'] then
                self.frm[string.format("BestPositionLabel%d", i)].Hint = string.format("- %s: %d ovr", table.concat(position_names[string.format("%d", i)]['long'], '/'), top_ovrs[i])
                self.frm[string.format("BestPositionLabel%d", i)].ShowHint = true
            else
                self.frm[string.format("BestPositionLabel%d", i)].ShowHint = false
            end
        else
            self.frm[string.format("BestPositionLabel%d", i)].Caption = '-'
            self.frm[string.format("BestPositionLabel%d", i)].ShowHint = false
        end
    end

    self:update_total_stats()
end

function thisFormManager:roll_random_attributes(components)
    self.has_unsaved_changes = true
    for i=1, #components do
        -- tmp disable onchange event
        local onchange_event = self.frm[components[i]].OnChange
        self.frm[components[i]].OnChange = nil
        self.frm[components[i]].Text = math.random(ATTRIBUTE_BOUNDS['min'], ATTRIBUTE_BOUNDS['max'])
        self.frm[components[i]].OnChange = onchange_event

        self.change_list[components[i]] = self.frm[components[i]].Text 
    end
    self:update_trackbar(self.frm[components[1]])
    self:recalculate_ovr(true)
    
end

function thisFormManager:update_cached_field(playerid, field_name, new_value)
    self.logger:info(string.format(
        "update_cached_field (%s) for playerid: %d. new_val = %d", 
        field_name, playerid, new_value
    ))
    local pgs_ptr = get_mode_manager_impl_ptr("PlayerGrowthManager")
    -- Start list = 0x5F0
    -- end list = 0x5F8

    if not pgs_ptr then
        self.logger:info("No PlayerGrowthManager pointer")
        return
    end
    local _start = readPointer(pgs_ptr + PLAYERGROWTHSYSTEM_STRUCT["_start"])
    local _end = readPointer(pgs_ptr + PLAYERGROWTHSYSTEM_STRUCT["_end"])
    if (not _start) or (not _end) then
        self.logger:info("No PlayerGrowthSystem start or end")
        return
    end
    local _max = 55

    local current_addr = _start
    local player_found = false
    for i=1, _max do
        -- self.logger:debug(string.format(
        --     "PlayerGrowthSystem Current - 0x%X, End - 0x%X",
        --     current_addr, _end
        -- ))
        if current_addr >= _end then
            -- no player to edit
            return
        end

        local pid = readInteger(current_addr + PLAYERGROWTHSYSTEM_STRUCT["pid"])
        if pid == playerid then
            player_found = true
            break
        end
        
        current_addr = current_addr + PLAYERGROWTHSYSTEM_STRUCT["size"]
    end

    if not player_found then return end

    self.logger:info(string.format(
        "Found PlayerGrowthSystem for: %d at 0x%X",
        playerid, current_addr
    ))

    -- Overwrite cached xp in developement plans
    local field_offset_map = {
        "acceleration",
        "sprintspeed",
        "agility",
        "balance",
        "jumping",
        "stamina",
        "strength",
        "reactions",
        "aggression",
        "composure",
        "interceptions",
        "positioning",
        "vision",
        "ballcontrol",
        "crossing",
        "dribbling",
        "finishing",
        "freekickaccuracy",
        "headingaccuracy",
        "longpassing",
        "shortpassing",
        "marking",
        "shotpower",
        "longshots",
        "standingtackle",
        "slidingtackle",
        "volleys",
        "curve",
        "penalties",
        "gkdiving",
        "gkhandling",
        "gkkicking",
        "gkreflexes",
        "gkpositioning",
        "defensiveworkrate",
        "attackingworkrate",
        "weakfootabilitytypecode",
        "skillmoves"
    }

    local idx = 0
    for i=1, #field_offset_map do
        if field_name == field_offset_map[i] then
            idx = i
            break
        end
    end

    if idx <= 0 then return end
    self.logger:debug(string.format("update_cached_field: %s", field_name))

    if new_value < 1 then
        new_value = 1
    else
        if field_name == "attackingworkrate" or field_name == "defensiveworkrate" then
            if new_value > 3 then
                new_value = 3
            end
        elseif field_name == "weakfootabilitytypecode" or field_name == "skillmoves" then
            if new_value > 5 then
                new_value = 5
            end
        end
    end

    local xp_points_to_apply = 1000
    if field_name == "attackingworkrate" or field_name == "defensiveworkrate" then
        local xp_to_wr = {
            5000,    -- medium
            100,    -- low
            10000   -- high
        }
        xp_points_to_apply = xp_to_wr[new_value]
    elseif field_name == "weakfootabilitytypecode" or field_name == "skillmoves" then
        local xp_to_star = {
            100,
            2500,
            5000,
            7500,
            10000
        }
        xp_points_to_apply = xp_to_star[new_value]
    else
        -- Add xp at: 14524d50c

        -- Add xp at: 145434DFC
        -- Xp points needed for attribute
        local xp_to_attribute = {
            1000,
            2101,
            3202,
            4305,
            5410,
            6518,
            7628,
            8742,
            9860,
            10983,
            12110,
            13243,
            14382,
            15528,
            16680,
            17840,
            19008,
            20185,
            21370,
            22565,
            23770,
            24986,
            26212,
            27450,
            28700,
            29963,
            31238,
            32527,
            33830,
            35148,
            36480,
            37828,
            39192,
            40573,
            41970,
            43385,
            44818,
            46270,
            47740,
            49230,
            50740,
            52271,
            53822,
            55395,
            56990,
            58608,
            60248,
            61912,
            63600,
            65313,
            67050,
            68813,
            70602,
            72418,
            74260,
            76130,
            78028,
            79955,
            81910,
            83895,
            85910,
            87956,
            90032,
            92140,
            94280,
            96453,
            98658,
            100897,
            103170,
            105478,
            107820,
            110198,
            112612,
            115063,
            117550,
            120075,
            122638,
            125240,
            127880,
            130560,
            133280,
            136041,
            138842,
            141685,
            144570,
            147498,
            150468,
            153482,
            156540,
            159643,
            162790,
            165983,
            169222,
            172508,
            175840,
            179220,
            182648,
            186125,
            189650
        }
        xp_points_to_apply = xp_to_attribute[new_value]
    end

    local write_to = current_addr+(4*idx)
    self.logger:debug(string.format(
        "XP: %d write to: 0x%X",
        xp_points_to_apply, write_to
    ))

    writeInteger(write_to, xp_points_to_apply)
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

    local fnFillHeadTypeCB = function(sender, headtypecode)
        --self.logger:debug(string.format("fnFillHeadTypeCB: %s. code: %d", sender.Name, headtypecode))
        sender.clear()
        local org_onchange = self.frm.HeadTypeGroupCB.OnChange
        self.frm.HeadTypeGroupCB.OnChange = nil
        for key, value in pairs(HEAD_TYPE_GROUPS) do
            for j=1, #value do
                if value[j] == headtypecode then
                    for k=1, #HEAD_TYPE_CB_IDX do
                        if HEAD_TYPE_CB_IDX[k] == key then
                            self.frm.HeadTypeGroupCB.ItemIndex = k-1
                            if self.frm.HeadTypeGroupCB.ItemIndex >= 0 then
                                self.frm.HeadTypeGroupCB.Hint = self.frm.HeadTypeGroupCB.Items[self.frm.HeadTypeGroupCB.ItemIndex]
                            else
                                self.frm.HeadTypeGroupCB.Hint = "ERROR"
                            end
                            
                            for l=1, #value do
                                sender.items.add(value[l])
                            end
                            --self.logger:debug(string.format("found: %d", j))
                            sender.ItemIndex = j-1
                            self.frm.HeadTypeGroupCB.OnChange = org_onchange
                            return
                        end
                    end
                end
            end
        end
        self.logger:error(string.format("headtypecode not found, %d", headtypecode))
        self.frm.HeadTypeGroupCB.OnChange = org_onchange
    end

    local fnOnChangeHeadTypeGroup = function(sender)
        local group_name = sender.Items[1]
        if sender.ItemIndex >= 0 then
            group_name = sender.Items[sender.ItemIndex]
        end
        sender.Hint = group_name
        local _key, _ = string.gsub(group_name, ' ', '_') 
        local headtypecodes = HEAD_TYPE_GROUPS[_key]
        
        local org_onchange = self.frm.HeadTypeCodeCB.OnChange
        self.frm.HeadTypeCodeCB.OnChange = nil
        self.frm.HeadTypeCodeCB.clear()

        for i=1, #headtypecodes do
            self.frm.HeadTypeCodeCB.items.add(headtypecodes[i])
        end
        self.frm.HeadTypeCodeCB.OnChange = org_onchange
        
        self.frm.HeadTypeCodeCB.ItemIndex = 0
        fnUpdateComboHint(self.frm.HeadTypeCodeCB)
        fnCommonOnChange(self.frm.HeadTypeCodeCB)
    end

    local fnOnChangeRequiresMinifaceUpdate = function(sender)
        local playerid = tonumber(self.frm.PlayerIDEdit.Text)
        if playerid >= 280000 then
            local ss_hs = self:load_headshot(
                playerid, nil,
                self.frm.SkinColorCB.ItemIndex+1,
                self.frm.HeadTypeCodeCB.Items[self.frm.HeadTypeCodeCB.ItemIndex],
                self.frm.HairColorCB.ItemIndex
            )
            if self:safe_load_picture_from_ss(self.frm.Headshot.Picture, ss_hs) then
                ss_hs.destroy()
                self.frm.Headshot.Picture.stretch=true
            end
        end
        fnCommonOnChange(sender)
    end

    local fnPerformanceBonusOnChange = function(sender)
        fnCommonOnChange(sender)

        if sender.ItemIndex == 0 then
            self.frm.PerformanceBonusCountLabel.Visible = false
            self.frm.PerformanceBonusCountEdit.Visible = false
            self.frm.PerformanceBonusValueLabel.Visible = false
            self.frm.PerformanceBonusValueEdit.Visible = false
        else
            self.frm.PerformanceBonusCountLabel.Visible = true
            self.frm.PerformanceBonusCountEdit.Visible = true
            self.frm.PerformanceBonusValueLabel.Visible = true
            self.frm.PerformanceBonusValueEdit.Visible = true
        end
    end

    local fnIsInjuredOnChange = function(sender)
        fnCommonOnChange(sender)

        if sender.ItemIndex == 0 then
            self.frm.InjuryCB.Visible = false
            self.frm.InjuryLabel.Visible = false
            self.frm.FullFitDateEdit.Visible = false
            self.frm.FullFitDateLabel.Visible = false
        else
            self.frm.InjuryCB.Visible = true
            self.frm.InjuryLabel.Visible = true
            self.frm.FullFitDateEdit.Visible = true
            self.frm.FullFitDateLabel.Visible = true
        end
    end

    local fnOnChangeAttribute = function(sender)
        if sender.Text == '' then return end
        self.has_unsaved_changes = true

        local new_val = tonumber(sender.Text)
        if new_val == nil then
            -- only numbers
            new_val = math.random(ATTRIBUTE_BOUNDS['min'],ATTRIBUTE_BOUNDS['max'])
        elseif new_val > ATTRIBUTE_BOUNDS['max'] then
            new_val = ATTRIBUTE_BOUNDS['max']
        elseif new_val < ATTRIBUTE_BOUNDS['min'] then
            new_val = ATTRIBUTE_BOUNDS['min']
        end
        sender.Text = new_val

        self:update_trackbar(sender)
        self:recalculate_ovr(true)

        self.change_list[sender.Name] = sender.Text
    end

    local fnOnChangeTrait = function(sender)
        self.has_unsaved_changes = true
        self.change_list[sender.Name] = sender.State >= 1
    end

    local fnCommonDBValGetter = function(addrs, table_name, field_name, raw)
        return self:fnCommonDBValGetter(addrs, table_name, field_name, raw)
    end

    local AttributesTrackBarOnChange = function(sender)
        local comp_desc = self.form_components_description[sender.Name]

        local new_val = sender.Position

        local lbl = self.frm[comp_desc['components_inheriting_value'][1]]
        local diff = new_val - tonumber(lbl.Caption)
        if comp_desc['depends_on'] then
            for i=1, #comp_desc['depends_on'] do
                local new_attr_val = tonumber(self.frm[comp_desc['depends_on'][i]].Text) + diff
                if new_attr_val > ATTRIBUTE_BOUNDS['max'] then
                    new_attr_val = ATTRIBUTE_BOUNDS['max']
                elseif new_attr_val < ATTRIBUTE_BOUNDS['min'] then
                    new_attr_val = ATTRIBUTE_BOUNDS['min']
                end
                -- save onchange event function
                local onchange_event = self.frm[comp_desc['depends_on'][i]].OnChange
                -- tmp disable onchange event
                self.frm[comp_desc['depends_on'][i]].OnChange = nil
                -- update value
                self.frm[comp_desc['depends_on'][i]].Text = new_attr_val
                self.change_list[comp_desc['depends_on'][i]] = new_attr_val

                -- restore onchange event
                self.frm[comp_desc['depends_on'][i]].OnChange = onchange_event
            end
        end

        lbl.Caption = new_val
        sender.SelEnd = new_val
        self:recalculate_ovr(true)
    end

    local fnTraitCheckbox = function(addrs, comp_desc)
        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]
        local bit = comp_desc["trait_bit"]

        local addr = addrs[table_name]

        local traitbitfield = self.game_db_manager:get_table_record_field_value(addr, table_name, field_name)
        local is_set = bAnd(bShr(traitbitfield, bit), 1)

        return is_set
    end

    local fnSaveTrait = function(addrs, comp_name, comp_desc)
        local component = self.frm[comp_name]
        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]

        local addr = addrs[table_name]
        

        local traitbitfield = self.game_db_manager:get_table_record_field_value(addr, table_name, field_name)
        local is_set = component.State >= 1

        if is_set then
            traitbitfield = bOr(traitbitfield, bShl(1, comp_desc["trait_bit"]))
            -- self.logger:debug(string.format("v is set: %d", traitbitfield))
        else
            traitbitfield = bAnd(traitbitfield, bNot(bShl(1, comp_desc["trait_bit"])))
            -- self.logger:debug(string.format("v not: %d", traitbitfield))
        end
        -- self.logger:debug(string.format("Save Trait: %d", traitbitfield))

        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, traitbitfield)
    end

    local fnDBValDaysToDate = function(addrs, table_name, field_name, raw)
        local addr = addrs[table_name]
        local days = self.game_db_manager:get_table_record_field_value(addr, table_name, field_name, raw)
        local date = days_to_date(days)
        local result = string.format(
            "%02d/%02d/%04d", 
            date["day"], date["month"], date["year"]
        )
        return result
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

        if comp_desc["db_field"]["is_in_dev_plan"] then
            self:update_cached_field(tonumber(self.frm.PlayerIDEdit.Text), field_name, new_value + 1)
        end
        
    end

    local fnSaveJoinTeamDate = function(addrs, comp_name, comp_desc)
        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]
        local addr = addrs[table_name]

        local new_value = 157195 -- 03/03/2013
        local d, m, y = string.match(self.frm[comp_name].Text, "(%d+)/(%d+)/(%d+)")
        if (not d) or (not m) or (not y) then
            self.logger:error(string.format(
                "Invalid date format in %s component: %s doesn't match DD/MM/YYYY pattern",
                comp_name, self.frm[comp_name].Text)
            )
        else
            new_value = date_to_days({
                day=tonumber(d),
                month=tonumber(m),
                year=tonumber(y)
            })
        end

        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value, raw)
    end

    local fnSaveCommon = function(addrs, comp_name, comp_desc)
        if comp_desc["not_editable"] then return end

        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]

        local addr = addrs[table_name]

        local new_value = tonumber(self.frm[comp_name].Text)
        local log_msg = string.format(
            "%X, %s - %s = %d",
            addr, table_name, field_name, new_value
        )
        self.logger:debug(log_msg)
        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value)
    end

    local fnSaveAttributeChange = function(addrs, comp_name, comp_desc)
        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]

        local addr = addrs[table_name]

        local new_value = tonumber(self.frm[comp_name].Text)
        local log_msg = string.format(
            "%X, %s - %s = %d",
            addr, table_name, field_name, new_value
        )
        self.logger:debug(log_msg)
        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, new_value)
        self:update_cached_field(tonumber(self.frm.PlayerIDEdit.Text), field_name, new_value)
    end

    local fnGetPlayerAge = function(addrs, table_name, field_name, raw, bdatedays)
        local addr = addrs[table_name]
        if not bdatedays then
            bdatedays = self.game_db_manager:get_table_record_field_value(addr, table_name, field_name, raw)
        end
        local bdate = days_to_date(bdatedays)

        self.logger:debug(
            string.format(
                "Player Birthdate: %02d/%02d/%04d", 
                bdate["day"], bdate["month"], bdate["year"]
            )
        )

        local int_current_date = self.game_db_manager:get_table_record_field_value(
            addrs["career_calendar"], "career_calendar", "currdate"
        )

        local current_date = {
            day = 1,
            month = 7,
            year = 2021
        }

        if int_current_date > 20080101 then
            local s_currentdate = tostring(int_current_date)
            current_date = {
                day = tonumber(string.sub(s_currentdate, 7, 8)),
                month = tonumber(string.sub(s_currentdate, 5, 6)),
                year = tonumber(string.sub(s_currentdate, 1, 4)),
            }
        end

        self.logger:debug(
            string.format(
                "Current Date: %02d/%02d/%04d", 
                current_date["day"], current_date["month"], current_date["year"]
            )
        )
        return calculate_age(current_date, bdate)
    end

    local fnSavePlayerAge = function(addrs, comp_name, comp_desc)
        
        local new_age = tonumber(self.frm[comp_name].Text)
        local field_name = comp_desc["db_field"]["field_name"]
        local table_name = comp_desc["db_field"]["table_name"]
        local current_age = fnGetPlayerAge(addrs, table_name, field_name)
        local addr = addrs[table_name]

        if new_age == current_age then return end
        local bdatedays = self.game_db_manager:get_table_record_field_value(addr, table_name, field_name, raw)

        bdatedays = bdatedays + ((current_age - new_age) * 366)

        self.game_db_manager:set_table_record_field_value(addr, table_name, field_name, bdatedays)
    end

    local fnFillCommonCB = function(sender, current_value, cb_rec_id)
        local has_items = sender.Items.Count > 0

        if type(tonumber) ~= "string" then
            current_value = tostring(current_value)
        end

        sender.Hint = ""

        local dropdown = getAddressList().getMemoryRecordByID(cb_rec_id)
        local dropdown_items = dropdown.DropDownList
        for j = 0, dropdown_items.Count-1 do
            local val, desc = string.match(dropdown_items[j], "(%d+): '(.+)'")
            -- self.logger:debug(string.format("val: %d (%s)", val, type(val)))
            if not has_items then
                -- Fill combobox in GUI with values from memory record dropdown
                sender.items.add(desc)
            end

            if current_value == val then
                -- self.logger:debug(string.format("Nationality: %d", current_value))
                sender.Hint = desc
                sender.ItemIndex = j

                if has_items then return end
            end
        end
    end
    local components_description = {
        PlayerIDEdit = {
            db_field = {
                table_name = "players",
                field_name = "playerid"
            },
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            },
            not_editable = true
        },
        OverallEdit = {
            db_field = {
                table_name = "players",
                field_name = "overallrating"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PotentialEdit = {
            db_field = {
                table_name = "players",
                field_name = "potential"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AgeEdit = {
            db_field = {
                table_name = "players",
                field_name = "birthdate"
            },
            valGetter = fnGetPlayerAge,
            OnSaveChanges = fnSavePlayerAge,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FirstNameIDEdit = {
            db_field = {
                table_name = "players",
                field_name = "firstnameid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        LastNameIDEdit = {
            db_field = {
                table_name = "players",
                field_name = "lastnameid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        CommonNameIDEdit = {
            db_field = {
                table_name = "players",
                field_name = "commonnameid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        JerseyNameIDEdit = {
            db_field = {
                table_name = "players",
                field_name = "playerjerseynameid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        GKSaveTypeEdit = {
            db_field = {
                table_name = "players",
                field_name = "gksavetype"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        GKKickStyleEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkkickstyle"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        ContractValidUntilEdit = {
            db_field = {
                table_name = "players",
                field_name = "contractvaliduntil"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PlayerJoinTeamDateEdit = {
            db_field = {
                table_name = "players",
                field_name = "playerjointeamdate"
            },
            valGetter = fnDBValDaysToDate,
            OnSaveChanges = fnSaveJoinTeamDate,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        JerseyNumberEdit = {
            db_field = {
                table_name = "teamplayerlinks",
                field_name = "jerseynumber"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        NationalityCB = {
            db_field = {
                table_name = "players",
                field_name = "nationality"
            },
            cb_id = CT_MEMORY_RECORDS["PLAYERS_NATIONALITY"],
            cbFiller = fnFillCommonCB,
            OnSaveChanges = fnSaveCommonCB,
            valGetter = fnCommonDBValGetter,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PreferredPosition1CB = {
            db_field = {
                table_name = "players",
                field_name = "preferredposition1"
            },
            cb_id = CT_MEMORY_RECORDS["PLAYERS_PRIMARY_POS"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PreferredPosition2CB = {
            db_field = {
                table_name = "players",
                field_name = "preferredposition2",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["PLAYERS_SECONDARY_POS"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PreferredPosition3CB = {
            db_field = {
                table_name = "players",
                field_name = "preferredposition3",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["PLAYERS_SECONDARY_POS"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PreferredPosition4CB = {
            db_field = {
                table_name = "players",
                field_name = "preferredposition4",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["PLAYERS_SECONDARY_POS"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        IsRetiringCB = {
            db_field = {
                table_name = "players",
                field_name = "isretiring",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["NO_YES_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        GenderCB = {
            db_field = {
                table_name = "players",
                field_name = "gender",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["GENDER_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AttackingWorkRateCB = {
            db_field = {
                table_name = "players",
                field_name = "attackingworkrate",
                raw_val = true,
                is_in_dev_plan = true
            },
            cb_id = CT_MEMORY_RECORDS["WR_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        DefensiveWorkRateCB = {
            db_field = {
                table_name = "players",
                field_name = "defensiveworkrate",
                raw_val = true,
                is_in_dev_plan = true
            },
            cb_id = CT_MEMORY_RECORDS["WR_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SkillMovesCB = {
            db_field = {
                table_name = "players",
                field_name = "skillmoves",
                raw_val = true,
                is_in_dev_plan = true
            },
            cb_id = CT_MEMORY_RECORDS["FIVE_STARS_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        WeakFootCB = {
            db_field = {
                table_name = "players",
                field_name = "weakfootabilitytypecode",
                raw_val = true,
                is_in_dev_plan = true
            },
            cb_id = CT_MEMORY_RECORDS["FIVE_STARS_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        InternationalReputationCB = {
            db_field = {
                table_name = "players",
                field_name = "internationalrep",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["FIVE_STARS_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PreferredFootCB = {
            db_field = {
                table_name = "players",
                field_name = "preferredfoot",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["PREFERREDFOOT_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        
        AttackTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Attack',
            components_inheriting_value = {
                "AttackValueLabel",
            },
            depends_on = {
                "CrossingEdit", "FinishingEdit", "HeadingAccuracyEdit",
                "ShortPassingEdit", "VolleysEdit"
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },
        -- Attributes
        CrossingEdit = {
            db_field = {
                table_name = "players",
                field_name = "crossing"
            },
            group = 'Attack',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        FinishingEdit = {
            db_field = {
                table_name = "players",
                field_name = "finishing"
            },
            group = 'Attack',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        HeadingAccuracyEdit = {
            db_field = {
                table_name = "players",
                field_name = "headingaccuracy"
            },
            group = 'Attack',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        ShortPassingEdit = {
            db_field = {
                table_name = "players",
                field_name = "shortpassing"
            },
            group = 'Attack',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        VolleysEdit = {
            db_field = {
                table_name = "players",
                field_name = "volleys"
            },
            group = 'Attack',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        DefendingTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Defending',
            components_inheriting_value = {
                "DefendingValueLabel",
            },
            depends_on = {
                "MarkingEdit", "StandingTackleEdit", "SlidingTackleEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },

        MarkingEdit = {
            db_field = {
                table_name = "players",
                field_name = "marking"
            },
            group = 'Defending',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        StandingTackleEdit = {
            db_field = {
                table_name = "players",
                field_name = "standingtackle"
            },
            group = 'Defending',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        SlidingTackleEdit = {
            db_field = {
                table_name = "players",
                field_name = "slidingtackle"
            },
            group = 'Defending',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        SkillTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Skill',
            components_inheriting_value = {
                "SkillValueLabel",
            },
            depends_on = {
                "DribblingEdit", "CurveEdit", "FreeKickAccuracyEdit",
                "LongPassingEdit", "BallControlEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },

        DribblingEdit = {
            db_field = {
                table_name = "players",
                field_name = "dribbling"
            },
            group = 'Skill',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        CurveEdit = {
            db_field = {
                table_name = "players",
                field_name = "curve"
            },
            group = 'Skill',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        FreeKickAccuracyEdit = {
            db_field = {
                table_name = "players",
                field_name = "freekickaccuracy"
            },
            group = 'Skill',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        LongPassingEdit = {
            db_field = {
                table_name = "players",
                field_name = "longpassing"
            },
            group = 'Skill',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        BallControlEdit = {
            db_field = {
                table_name = "players",
                field_name = "ballcontrol"
            },
            group = 'Skill',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        GoalkeeperTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Goalkeeper',
            components_inheriting_value = {
                "GoalkeeperValueLabel",
            },
            depends_on = {
                "GKDivingEdit", "GKHandlingEdit", "GKKickingEdit",
                "GKPositioningEdit", "GKReflexEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },

        GKDivingEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkdiving"
            },
            group = 'Goalkeeper',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        GKHandlingEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkhandling"
            },
            group = 'Goalkeeper',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        GKKickingEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkkicking"
            },
            group = 'Goalkeeper',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        GKPositioningEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkpositioning"
            },
            group = 'Goalkeeper',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        GKReflexEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkreflexes"
            },
            group = 'Goalkeeper',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        PowerTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Power',
            components_inheriting_value = {
                "PowerValueLabel",
            },
            depends_on = {
                "ShotPowerEdit", "JumpingEdit", "StaminaEdit",
                "StrengthEdit", "LongShotsEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },

        ShotPowerEdit = {
            db_field = {
                table_name = "players",
                field_name = "shotpower"
            },
            group = 'Power',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        JumpingEdit = {
            db_field = {
                table_name = "players",
                field_name = "jumping"
            },
            group = 'Power',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        StaminaEdit = {
            db_field = {
                table_name = "players",
                field_name = "stamina"
            },
            group = 'Power',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        StrengthEdit = {
            db_field = {
                table_name = "players",
                field_name = "strength"
            },
            group = 'Power',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        LongShotsEdit = {
            db_field = {
                table_name = "players",
                field_name = "longshots"
            },
            group = 'Power',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        MovementTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Movement',
            components_inheriting_value = {
                "MovementValueLabel",
            },
            depends_on = {
                "AccelerationEdit", "SprintSpeedEdit", "AgilityEdit",
                "ReactionsEdit", "BalanceEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },

        AccelerationEdit = {
            db_field = {
                table_name = "players",
                field_name = "acceleration"
            },
            group = 'Movement',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        SprintSpeedEdit = {
            db_field = {
                table_name = "players",
                field_name = "sprintspeed"
            },
            group = 'Movement',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        AgilityEdit = {
            db_field = {
                table_name = "players",
                field_name = "agility"
            },
            group = 'Movement',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        ReactionsEdit = {
            db_field = {
                table_name = "players",
                field_name = "reactions"
            },
            group = 'Movement',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        BalanceEdit = {
            db_field = {
                table_name = "players",
                field_name = "balance"
            },
            group = 'Movement',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        MentalityTrackBar = {
            valGetter = AttributesTrackBarVal,
            group = 'Mentality',
            components_inheriting_value = {
                "MentalityValueLabel",
            },
            depends_on = {
                "AggressionEdit", "ComposureEdit", "InterceptionsEdit",
                "AttackPositioningEdit", "VisionEdit", "PenaltiesEdit",
            },
            events = {
                OnChange = AttributesTrackBarOnChange,
            }
        },

        AggressionEdit = {
            db_field = {
                table_name = "players",
                field_name = "aggression"
            },
            group = 'Mentality',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        ComposureEdit = {
            db_field = {
                table_name = "players",
                field_name = "composure"
            },
            group = 'Mentality',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        InterceptionsEdit = {
            db_field = {
                table_name = "players",
                field_name = "interceptions"
            },
            group = 'Mentality',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        AttackPositioningEdit = {
            db_field = {
                table_name = "players",
                field_name = "positioning"
            },
            group = 'Mentality',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        VisionEdit = {
            db_field = {
                table_name = "players",
                field_name = "vision"
            },
            group = 'Mentality',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },
        PenaltiesEdit = {
            db_field = {
                table_name = "players",
                field_name = "penalties"
            },
            group = 'Mentality',
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveAttributeChange,
            events = {
                OnChange = fnOnChangeAttribute
            }
        },

        LongThrowInCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 0,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        PowerFreeKickCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 1,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        InjuryProneCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 2,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        SolidPlayerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 3,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        LeadershipCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 6,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        EarlyCrosserCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 7,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        FinesseShotCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 8,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        FlairCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 9,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        SpeedDribblerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 12,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        GKLongthrowCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 14,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        PowerheaderCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 15,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        GiantthrowinCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 16,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        OutsitefootshotCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 17,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        SwervePassCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 18,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        SecondWindCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 19,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        FlairPassesCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 20,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        BicycleKicksCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 21,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        GKFlatKickCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 22,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        OneClubPlayerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 23,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        TeamPlayerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 24,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        RushesOutOfGoalCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 27,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        CautiousWithCrossesCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 28,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        ComesForCrossessCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 29,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },

        SaveswithFeetCB = {
            db_field = {
                table_name = "players",
                field_name = "trait2"
            },
            trait_bit = 1,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        SetPlaySpecialistCB = {
            db_field = {
                table_name = "players",
                field_name = "trait2"
            },
            trait_bit = 2,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        DivesIntoTacklesCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 4,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        LongPasserCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 10,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        LongShotTakerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 11,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        PlaymakerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 13,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        ChipShotCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 25,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },
        TechnicalDribblerCB = {
            db_field = {
                table_name = "players",
                field_name = "trait1"
            },
            trait_bit = 26,
            valGetter = fnTraitCheckbox,
            OnSaveChanges = fnSaveTrait,
            events = {
                OnChange = fnOnChangeTrait
            }
        },

        -- Appearance
        HeightEdit = {
            db_field = {
                table_name = "players",
                field_name = "height"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        WeightEdit = {
            db_field = {
                table_name = "players",
                field_name = "weight"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        BodyTypeCB = {
            db_field = {
                table_name = "players",
                field_name = "bodytypecode",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["BODYTYPE_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        HeadTypeCodeCB = {
            db_field = {
                table_name = "players",
                field_name = "headtypecode",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["HEADTYPE_CB"],
            cbFiller = fnFillHeadTypeCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnOnChangeRequiresMinifaceUpdate
            }
        },
        HeadTypeGroupCB = {
            events = {
                OnChange = fnOnChangeHeadTypeGroup
            }
        },
        HairColorCB = {
            db_field = {
                table_name = "players",
                field_name = "haircolorcode",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["HAIRCOLOR_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnOnChangeRequiresMinifaceUpdate
            }
        },
        HairTypeEdit = {
            db_field = {
                table_name = "players",
                field_name = "hairtypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        HairStyleEdit = {
            db_field = {
                table_name = "players",
                field_name = "hairstylecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FacialHairTypeEdit = {
            db_field = {
                table_name = "players",
                field_name = "facialhairtypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FacialHairColorEdit = {
            db_field = {
                table_name = "players",
                field_name = "facialhaircolorcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SideburnsEdit = {
            db_field = {
                table_name = "players",
                field_name = "sideburnscode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        EyebrowEdit = {
            db_field = {
                table_name = "players",
                field_name = "eyebrowcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        EyeColorEdit = {
            db_field = {
                table_name = "players",
                field_name = "eyecolorcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SkinTypeEdit = {
            db_field = {
                table_name = "players",
                field_name = "skintypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SkinColorCB =  {
            db_field = {
                table_name = "players",
                field_name = "skintonecode",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["SKINCOLOR_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnOnChangeRequiresMinifaceUpdate
            }
        },
        TattooHeadEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattoohead"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TattooFrontEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattoofront"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TattooBackEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattooback"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TattooRightArmEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattoorightarm"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TattooLeftArmEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattooleftarm"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TattooRightLegEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattoorightleg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        TattooLeftLegEdit = {
            db_field = {
                table_name = "players",
                field_name = "tattooleftleg"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        HasHighQualityHeadCB = {
            db_field = {
                table_name = "players",
                field_name = "hashighqualityhead",
                raw_val = true
            },
            cb_id = CT_MEMORY_RECORDS["NO_YES_CB"],
            cbFiller = fnFillCommonCB,
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommonCB,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        HeadAssetIDEdit = {
            db_field = {
                table_name = "players",
                field_name = "headassetid"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        HeadVariationEdit = {
            db_field = {
                table_name = "players",
                field_name = "headvariation"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        HeadClassCodeEdit = {
            db_field = {
                table_name = "players",
                field_name = "headclasscode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        JerseyStyleEdit = {
            db_field = {
                table_name = "players",
                field_name = "jerseystylecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        JerseyFitEdit = {
            db_field = {
                table_name = "players",
                field_name = "jerseyfit"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        jerseysleevelengthEdit = {
            db_field = {
                table_name = "players",
                field_name = "jerseysleevelengthcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        hasseasonaljerseyEdit = {
            db_field = {
                table_name = "players",
                field_name = "hasseasonaljersey"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        shortstyleEdit = {
            db_field = {
                table_name = "players",
                field_name = "shortstyle"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        socklengthEdit = {
            db_field = {
                table_name = "players",
                field_name = "socklengthcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },

        GKGloveTypeEdit = {
            db_field = {
                table_name = "players",
                field_name = "gkglovetypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        shoetypeEdit = {
            db_field = {
                table_name = "players",
                field_name = "shoetypecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        shoedesignEdit = {
            db_field = {
                table_name = "players",
                field_name = "shoedesigncode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        shoecolorEdit1 = {
            db_field = {
                table_name = "players",
                field_name = "shoecolorcode1"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        shoecolorEdit2 = {
            db_field = {
                table_name = "players",
                field_name = "shoecolorcode2"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryEdit1 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycode1"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryColourEdit1 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycolourcode1"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryEdit2 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycode2"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryColourEdit2 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycolourcode2"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryEdit3 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycode3"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryColourEdit3 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycolourcode3"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryEdit4 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycode4"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AccessoryColourEdit4 = {
            db_field = {
                table_name = "players",
                field_name = "accessorycolourcode4"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },

        runningcodeEdit1 = {
            db_field = {
                table_name = "players",
                field_name = "runningcode1"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        runningcodeEdit2 = {
            db_field = {
                table_name = "players",
                field_name = "runningcode2"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FinishingCodeEdit1 = {
            db_field = {
                table_name = "players",
                field_name = "finishingcode1"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FinishingCodeEdit2 = {
            db_field = {
                table_name = "players",
                field_name = "finishingcode2"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AnimFreeKickStartPosEdit = {
            db_field = {
                table_name = "players",
                field_name = "animfreekickstartposcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        AnimPenaltiesStartPosEdit = {
            db_field = {
                table_name = "players",
                field_name = "animpenaltiesstartposcode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FacePoserPresetEdit = {
            db_field = {
                table_name = "players",
                field_name = "faceposerpreset"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        EmotionEdit = {
            db_field = {
                table_name = "players",
                field_name = "emotion"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SkillMoveslikelihoodEdit = {
            db_field = {
                table_name = "players",
                field_name = "skillmoveslikelihood"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        ModifierEdit = {
            db_field = {
                table_name = "players",
                field_name = "modifier"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        IsCustomizedEdit = {
            db_field = {
                table_name = "players",
                field_name = "iscustomized"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        UserCanEditNameEdit = {
            db_field = {
                table_name = "players",
                field_name = "usercaneditname"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },
        RunStyleEdit = {
            db_field = {
                table_name = "players",
                field_name = "runstylecode"
            },
            valGetter = fnCommonDBValGetter,
            OnSaveChanges = fnSaveCommon,
            events = {
                OnChange = fnCommonOnChange
            }
        },

        WageEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SquadRoleCB = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        ReleaseClauseEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PerformanceBonusCountEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PerformanceBonusValueEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        InjuryCB = {
            events = {
                OnChange = fnCommonOnChange
            }
        }, 
        DurabilityEdit= {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FullFitDateEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        MoraleCB = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        FormCB = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        LoanWageSplitEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        SharpnessEdit = {
            events = {
                OnChange = fnCommonOnChange
            }
        },
        PerformanceBonusTypeCB = {
            events = {
                OnChange = fnPerformanceBonusOnChange
            }
        },
        IsInjuredCB = {
            events = {
                OnChange = fnIsInjuredOnChange
            }
        }
    }

    return components_description
end

function thisFormManager:onShow(sender, player_addr, playerlink_addr)
    self.logger:debug(string.format("onShow: %s", self.name))
    self.frm.SearchPlayerByID.Visible = false
    self.frm.FindPlayerByID.Visible = false

    -- Show Loading panel
    self.frm.FindPlayerBtn.Visible = false
    self.frm.WhileLoadingPanel.Visible = true

    local onShow_delayed_wrapper = function()
        self:onShow_delayed(player_addr, playerlink_addr)
    end

    self.fill_timer = createTimer(nil)

    -- Load Data
    timer_onTimer(self.fill_timer, onShow_delayed_wrapper)
    timer_setInterval(self.fill_timer, 1000)
    timer_setEnabled(self.fill_timer, true)
end

function thisFormManager:onShow_delayed(player_addr, playerlink_addr)
    -- Disable Timer
    timer_setEnabled(self.fill_timer, false)
    self.fill_timer = nil

    self.current_addrs = {}
    self.current_addrs["players"] = player_addr or readPointer("pPlayersTableCurrentRecord")
    self.current_addrs["teamplayerlinks"] = playerlink_addr or readPointer("pTeamplayerlinksTableCurrentRecord")
    self.current_addrs["career_calendar"] = readPointer("pCareerCalendarTableCurrentRecord")
    self.current_addrs["career_users"] = readPointer("pUsersTableFirstRecord")
    gCTManager:init_ptrs()
    self.game_db_manager:cache_player_names()

    self:fill_form(self.current_addrs)
    self:recalculate_ovr(true)

    -- Clone CM
    self.frm.CopyCMFindPlayerByID.Text = 'Find player by ID...'
    self.frm.CloneFromListBox.setItemIndex(0)
    self.frm.CardContainerPanel.Visible = false
    self.frm.FutFIFACB.Hint = ''
    -- Hide Loading Panel and show components
    self.frm.PlayerInfoTab.Color = "0x001D1618"
    self.frm.PlayerInfoPanel.Visible = true
    self.frm.WhileLoadingPanel.Visible = false
    self.frm.FindPlayerBtn.Visible = true

    -- self.frm.FindPlayerByID.Visible = true
    -- self.frm.SearchPlayerByID.Visible = true
end

function thisFormManager:attributes_trackbar_val(args)
    local component_name = args['component_name']
    local comp_desc = self.form_components_description[component_name]

    local sum_attr = 0
    local items = 0
    if comp_desc['depends_on'] then
        for i=1, #comp_desc['depends_on'] do
            items = items + 1
            if self.frm[comp_desc['depends_on'][i]].Text == '' then
                local r = self.form_components_description[comp_desc['depends_on'][i]]
                self.frm[comp_desc['depends_on'][i]].Text = r["valGetter"](
                    self.current_addrs,
                    r["db_field"]["table_name"],
                    r["db_field"]["field_name"],
                    r["db_field"]["raw_val"]
                )
            end
            sum_attr = sum_attr + tonumber(self.frm[comp_desc['depends_on'][i]].Text)
        end
    end

    local result = math.ceil(sum_attr/items)
    if result > ATTRIBUTE_BOUNDS['max'] then
        result = ATTRIBUTE_BOUNDS['max']
    elseif result < ATTRIBUTE_BOUNDS['min'] then
        result = ATTRIBUTE_BOUNDS['min']
    end

    return result
end

function thisFormManager:update_trackbar(sender)
    self.logger:debug(string.format("update_trackbar: %s", sender.Name))
    local trackBarName = string.format("%sTrackBar", self.form_components_description[sender.Name]['group'])
    local valueLabelName = string.format("%sValueLabel", self.form_components_description[sender.Name]['group'])

    -- recalculate ovr of group of attrs
    local onchange_func = self.frm[trackBarName].OnChange
    self.frm[trackBarName].OnChange = nil

    local calc = self:attributes_trackbar_val({
        component_name = trackBarName,
    })

    self.frm[trackBarName].Position = calc
    self.frm[trackBarName].SelEnd = calc
    self.frm[valueLabelName].Caption = calc

    self.frm[trackBarName].OnChange = onchange_func

end

function thisFormManager:fill_form(addrs, playerid)
    local record_addr = addrs["players"]

    if record_addr == nil and playerid == nil then
        self.logger:error(
            string.format("Can't Fill %s form. Player record address or playerid is required", self.name)
        )
    end

    if not playerid then
        playerid = self.game_db_manager:get_table_record_field_value(record_addr, "players", "playerid")
    end

    self.logger:debug(string.format("fill_form: %s", self.name))
    if self.form_components_description == nil then
        self.form_components_description = self:get_components_description()
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
            if comp_desc["valGetter"] and comp_desc["cbFiller"] then
                local current_field_val = comp_desc["valGetter"](
                    addrs,
                    comp_desc["db_field"]["table_name"],
                    comp_desc["db_field"]["field_name"],
                    comp_desc["db_field"]["raw_val"]
                )
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

    if gCTManager.cfg.flags.hide_players_potential then
        self.frm.PotentialEdit.Text = "HIDDEN"
    end

    self.logger:debug("Update trackbars")
    local trackbars = {
        'AttackTrackBar',
        'DefendingTrackBar',
        'SkillTrackBar',
        'GoalkeeperTrackBar',
        'PowerTrackBar',
        'MovementTrackBar',
        'MentalityTrackBar',
    }
    for i=1, #trackbars do
        self:update_trackbar(self.frm[trackbars[i]])
    end

    local ss_hs = self:load_headshot(
        playerid, record_addr
    )
    if self:safe_load_picture_from_ss(self.frm.Headshot.Picture, ss_hs) then
        ss_hs.destroy()
        self.frm.Headshot.Picture.stretch=true
    end
    local team_record = self:find_player_club_team_record(playerid)
    local teamid = 0
    if team_record > 0 then
        teamid = self.game_db_manager:get_table_record_field_value(team_record, "teamplayerlinks", "teamid")
        local ss_c = self:load_crest(
            nil, team_record
        )
        if self:safe_load_picture_from_ss(self.frm.Crest64x64.Picture, ss_c) then
            ss_c.destroy()
            self.frm.Crest64x64.Picture.stretch=true
        end
        self.frm.TeamIDEdit.Text = teamid
    else
        self.frm.TeamIDEdit.Text = "Unknown"
    end

    self.frm.PlayerNameLabel.Caption = self:get_player_name(playerid)

    local career_only_comps = {
        "WageLabel",
        "WageEdit",
        "SquadRoleLabel",
        "SquadRoleCB",
        "LoanWageSplitLabel",
        "LoanWageSplitEdit",
        "PerformanceBonusTypeLabel",
        "PerformanceBonusTypeCB",
        "PerformanceBonusCountLabel",
        "PerformanceBonusCountEdit",
        "PerformanceBonusValueLabel",
        "PerformanceBonusValueEdit",
        "IsInjuredCB",
        "InjuredLabel",
        "InjuryCB",
        "InjuryLabel",
        "DurabilityEdit",
        "DurabilityLabel",
        "FullFitDateEdit",
        "FullFitDateLabel",
        "FormCB",
        "FormLabel",
        "MoraleCB",
        "MoraleLabel",
        "SharpnessEdit",
        "SharpnessLabel",
        "ReleaseClauseEdit",
        "ReleaseClauseLabel"
    }

    local is_in_cm = is_cm_loaded()

    local is_manager_career = false
    local is_manager_career_valid = false
    if is_in_cm then
        is_manager_career = self:is_manager_career(addrs["career_users"])
        if type(is_manager_career) == "boolean" then
            is_manager_career_valid = true
        end
    end

    if is_in_cm and is_manager_career_valid then
        local userclubtid = self:get_user_clubteamid(addrs["career_users"])
        local is_in_user_club = false
        if teamid > 0 and userclubtid > 0 then
            -- is_in_user_team
            if teamid == userclubtid then
                self.logger:debug("is in user club")
                is_in_user_club = true
            end
        end
        if is_manager_career then
            self.logger:debug("manager career")
        else
            self.logger:debug("player career")
        end
        -- player info - contract
        self:load_player_contract(playerid, is_in_user_club)

        -- TODO FIFA 22
        -- Player info - fitness & injury
        -- self:load_player_fitness(playerid)

        -- Player info - form
        -- self:load_player_form(playerid)

        -- Player info - Morale
        -- self:load_player_morale(playerid)

        -- Player Info - sharpness
        -- self:load_player_sharpness(playerid, is_manager_career)

        -- Player info - Release Clause
        -- self:load_player_release_clause(playerid)

        for i=1, #career_only_comps do
            self.change_list[career_only_comps[i]] = nil
        end

    else
        for i=1, #career_only_comps do
            self.frm[career_only_comps[i]].Visible = false
        end
    end

    self.has_unsaved_changes = false
    self.logger:debug(string.format("fill_form %s done", self.name))
end

function thisFormManager:get_player_fitness_addr(playerid)
    local fitness_manager_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pCareerModeSmth"),
        {0x0, 0x10, 0x48, 0x30, 0x180+0x50}
    )
    -- 0x19a0 start
    -- 0x19a8 end
    -- fm001
    local _start = readPointer(fitness_manager_ptr + 0x19a0)
    local _end = readPointer(fitness_manager_ptr + 0x19a8)
    if (not _start) or (not _end) then
        self.logger:info("No Fitness start or end")
        return -1
    end
    -- self.logger:debug(string.format("Player Fitness _start: %X", _start))
    -- self.logger:debug(string.format("Player Fitness _end: %X", _end))
    local current_addr = _start
    local player_found = false
    local _max = 2000
    for i=1, _max do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        --self.logger:debug(string.format("Player Fitness current_addr: %X", current_addr))
        local pid = readInteger(current_addr + PLAYERFITESS_STRUCT["pid"])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERFITESS_STRUCT["size"]
    end
    if not player_found then
        return 0
    end
    self.logger:debug(string.format("Player Fitness found at: %X", current_addr))
    return current_addr
end

function thisFormManager:save_player_fitness(playerid, new_fitness, is_injured, injury_type, full_fit_on)
    self.logger:info("save_player_fitness no space")
    if not playerid then
        self.logger:error("save_player_fitness no playerid!")
        return
    end
    local current_addr = self:get_player_fitness_addr(playerid)
    if current_addr == -1 then return end

    -- Get first free
    if current_addr == 0 then
        current_addr = self:get_player_fitness_addr(4294967295)

        if current_addr <= 0 then
            self.logger:error("save_player_fitness no space")
            return
        end

        writeInteger(current_addr + PLAYERFITESS_STRUCT["pid"], playerid)
        writeInteger(current_addr + PLAYERFITESS_STRUCT["tid"], 4294967295)
        writeInteger(current_addr + PLAYERFITESS_STRUCT["full_fit_date"], 20080101)
        writeInteger(current_addr + PLAYERFITESS_STRUCT["unk_date"], 20080101)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["unk0"], 0)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["fitness"], 100)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["is_injured"], 0)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["unk1"], 0)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["inj_type"], 0)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["unk2"], 0)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["unk3"], 1)
        writeBytes(current_addr + PLAYERFITESS_STRUCT["unk4"], 0)
    end

    if new_fitness then
        if type(new_fitness) == "string" then
            new_fitness, _ = string.gsub(
                new_fitness,
                '%D', ''
            )

            new_fitness = tonumber(new_fitness) -- remove non-digits
        end

        if new_fitness > 100 then
            new_fitness = 100
        elseif new_fitness <= 1 then
            new_fitness = 2
        end
        writeBytes(current_addr + PLAYERFITESS_STRUCT["fitness"], new_fitness)
    end

    if is_injured ~= nil and injury_type ~= nil and full_fit_on ~= nil then
        is_injured = is_injured == 1
        full_fit_on = date_to_value(full_fit_on)

        if injury_type > 35 then injury_type = 35 end

        if is_injured and injury_type > 0 and full_fit_on then
            writeInteger(current_addr + PLAYERFITESS_STRUCT["full_fit_date"], full_fit_on)
            writeInteger(current_addr + PLAYERFITESS_STRUCT["unk_date"], full_fit_on)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk0"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["is_injured"], 1)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk1"], 17)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["inj_type"], injury_type)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk2"], 2)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk3"], 1)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk4"], 0)
        else
            writeInteger(current_addr + PLAYERFITESS_STRUCT["full_fit_date"], 20080101)
            writeInteger(current_addr + PLAYERFITESS_STRUCT["unk_date"], 20080101)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk0"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["is_injured"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk1"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["inj_type"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk2"], 0)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk3"], 1)
            writeBytes(current_addr + PLAYERFITESS_STRUCT["unk4"], 0)
        end
    end
end

function thisFormManager:load_player_fitness(playerid)
    local fn_comps_vis = function(visible)
        self.frm.IsInjuredCB.Visible = visible
        self.frm.InjuredLabel.Visible = visible
        self.frm.InjuryCB.Visible = visible
        self.frm.InjuryLabel.Visible = visible
        self.frm.DurabilityEdit.Visible = visible
        self.frm.DurabilityLabel.Visible = visible
        self.frm.FullFitDateEdit.Visible = visible
        self.frm.FullFitDateLabel.Visible = visible
    end

    if not playerid then
        fn_comps_vis(false)
        return
    end

    local current_addr = self:get_player_fitness_addr(playerid)
    if current_addr == -1 then
        fn_comps_vis(false)
        return
    elseif current_addr == 0 then
        self.frm.IsInjuredCB.Visible = true
        self.frm.InjuredLabel.Visible = true
        self.frm.IsInjuredCB.ItemIndex = 0
        self.frm.InjuryCB.ItemIndex = 0
        self.frm.FullFitDateEdit.Text = "01/01/2008"
        self.frm.DurabilityEdit.Text = "100%"
        self.frm.InjuryLabel.Visible = false
        self.frm.InjuryCB.Visible = false
        self.frm.FullFitDateLabel.Visible = false
        self.frm.FullFitDateEdit.Visible = false
        return
    end
    fn_comps_vis(true)
    
    self.logger:debug(string.format("Player Fitness found at %X", current_addr))

    local is_injured = readBytes(current_addr + PLAYERFITESS_STRUCT["is_injured"], 1)
    self.frm.IsInjuredCB.ItemIndex = is_injured

    local durability = readBytes(current_addr + PLAYERFITESS_STRUCT["fitness"], 1)
    self.frm.DurabilityEdit.Text = string.format("%d", durability) .. "%"

    if self.frm.IsInjuredCB.ItemIndex == 0 then
        self.frm.InjuryCB.ItemIndex = 0
        self.frm.FullFitDateEdit.Text = "01/01/2008"
        self.frm.InjuryLabel.Visible = false
        self.frm.InjuryCB.Visible = false
        self.frm.FullFitDateLabel.Visible = false
        self.frm.FullFitDateEdit.Visible = false
    else
        self.frm.InjuryLabel.Visible = true
        self.frm.InjuryCB.Visible = true
        self.frm.FullFitDateLabel.Visible = true
        self.frm.FullFitDateEdit.Visible = true
        local injury_type = readBytes(current_addr + PLAYERFITESS_STRUCT["inj_type"], 1)
        self.frm.InjuryCB.ItemIndex = injury_type

        self.frm.FullFitDateEdit.Text = value_to_date(
            readInteger(current_addr + PLAYERFITESS_STRUCT["full_fit_date"])
        )
    end
    self.frm.IsInjuredCB.Hint = self.frm.IsInjuredCB.Items[self.frm.IsInjuredCB.ItemIndex]
end

function thisFormManager:get_player_form_addr(playerid)
    local form_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pModeManagers"),
        {0x0, 0x518, 0x0, 0x20, 0x130, 0x140}
    ) + 0x2C
    local n_of_players = readInteger(form_ptr - 0x4)

    local size_of =  PLAYERFORM_STRUCT['size']
    local _start = form_ptr
    local _end = _start + (n_of_players*size_of)
    if (not _start) or (not _end) then
        self.logger:info("No form start or end")
        return 0
    end
    local current_addr = _start
    local player_found = false

    for i=0, n_of_players, 1 do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        local pid = readInteger(current_addr + PLAYERFORM_STRUCT['pid'])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERFORM_STRUCT["size"]
    end
    if not player_found then
        -- self.logger:debug("player form not found")
        return 0
    end
    return current_addr
end

function thisFormManager:save_player_form(playerid, new_value)
    if not playerid then
        self.logger:error("save_player_form no playerid!")
        return
    end
    self.logger:debug(string.format("save_player_form: %d", playerid))
    local current_addr = self:get_player_form_addr(playerid)
    if current_addr == 0 then
        return
    end

    if not new_value or new_value < 1 then
        self.logger:warning(string.format("Invalid player form! %d - %d", new_value, playerid))
        new_value = 1
    elseif new_value > 5 then
        self.logger:warning(string.format("Invalid player form! %d - %d", new_value, playerid))
        new_value = 5
    end

    -- Arrow
    writeInteger(current_addr+PLAYERFORM_STRUCT['form'], new_value)

    -- avg. needed for arrow?
    local form_vals = {
        25, 50, 65, 75, 90
    }
    local form_val = form_vals[new_value]

    -- Last 10 games?
    for i=0, 9 do
        local off = PLAYERFORM_STRUCT['last_games_avg_1'] + (i * 4)
        writeInteger(current_addr+off, form_val)
    end

    -- Avg from last 10 games?
    writeInteger(current_addr+PLAYERFORM_STRUCT['recent_avg'], form_val)
end

function thisFormManager:load_player_form(playerid)
    local fn_comps_vis = function(visible)
        self.frm.FormCB.Visible = visible
        self.frm.FormLabel.Visible = visible
    end
    self.logger:debug("load_player_form")

    if not playerid then
        fn_comps_vis(false)
        return
    end

    local current_addr = self:get_player_form_addr(playerid)
    if current_addr == 0 then
        fn_comps_vis(false)
        return
    end

    self.logger:debug(string.format("Player Form found at %X", current_addr))
    fn_comps_vis(true)

    local current_form = readInteger(current_addr + PLAYERFORM_STRUCT['form'])
    if current_form < 1 then
        self.logger:info(string.format("Invalid player form! %d - %d", current_form, playerid))
        current_form = 1
    elseif current_form > 5 then
        self.logger:info(string.format("Invalid player form! %d - %d", current_form, playerid))
        current_form = 5
    end
    self.frm.FormCB.ItemIndex = current_form - 1
    self.frm.FormCB.Hint = self.frm.FormCB.Items[self.frm.FormCB.ItemIndex]
end

function thisFormManager:get_player_morale_addr(playerid)
    local size_of = PLAYERMORALE_STRUCT['size']
    local morale_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pModeManagers"),
        {0x0, 0x518, 0x0, 0x20, 0x168}
    )

    local _start = readPointer(morale_ptr + 0x4B0)
    local _end = readPointer(morale_ptr + 0x4B8)
    if (not _start) or (not _end) then
        self.logger:info("No Morale start or end")
        return
    end
    local squad_size = ((_end - _start) // size_of) + 1
    local current_addr = _start
    local player_found = false
    for i=0, squad_size, 1 do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        local pid = readInteger(current_addr + PLAYERMORALE_STRUCT['pid'])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERMORALE_STRUCT['size']
    end
    if not player_found then
        return 0
    end

    return current_addr
end

function thisFormManager:save_player_morale(playerid, new_value)
    if not playerid then
        self.logger:error("save_player_morale no playerid!")
        return
    end
    self.logger:debug(string.format("save_player_morale: %d", playerid))
    local current_addr = self:get_player_morale_addr(playerid)
    if current_addr == 0 then
        return
    end

    if not new_value or new_value < 1 then
        self.logger:warning(string.format("Invalid player morale! %d - %d", new_value, playerid))
        new_value = 1
    elseif new_value > 5 then
        self.logger:warning(string.format("Invalid player morale! %d - %d", new_value, playerid))
        new_value = 5
    end
    local morale_vals = {
        15, 40, 65, 75, 95
    }

    local morale = morale_vals[new_value]

    -- Will it be enough?
    writeInteger(current_addr+PLAYERMORALE_STRUCT['morale_val'], morale)
    writeInteger(current_addr+PLAYERMORALE_STRUCT['contract'], morale)
    writeInteger(current_addr+PLAYERMORALE_STRUCT['playtime'], morale)
end

function thisFormManager:load_player_morale(playerid)
    local fn_comps_vis = function(visible)
        self.frm.MoraleCB.Visible = visible
        self.frm.MoraleLabel.Visible = visible
    end

    if not playerid then
        fn_comps_vis(false)
        return
    end

    local current_addr = self:get_player_morale_addr(playerid)
    if current_addr == 0 then
        fn_comps_vis(false)
        return
    end

    self.logger:debug(string.format("Player Morale found at %X", current_addr))
    fn_comps_vis(true)

    local morale = readInteger(current_addr+PLAYERMORALE_STRUCT['morale_val'])

    if morale <= 35 then
        morale_level = 0    -- VERY_LOW
    elseif morale <= 55 then
        morale_level = 1    -- LOW
    elseif morale <= 70 then
        morale_level = 2    -- NORMAL
    elseif morale <= 85 then
        morale_level = 3    -- HIGH
    else
        morale_level = 4    -- VERY_HIGH
    end
    self.frm.MoraleCB.ItemIndex = morale_level
    self.frm.MoraleCB.Hint = self.frm.MoraleCB.Items[self.frm.MoraleCB.ItemIndex]
end

function thisFormManager:get_player_sharpness_addr(playerid)
    local fitness_manager_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pCareerModeSmth"),
        {0x0, 0x10, 0x48, 0x30, 0x180+0x50}
    )
    local _start = readPointer(fitness_manager_ptr + 0x19F0)

    if not _start then
        self.logger:info("Player Sharpness, no start.")
        return 0
    end

    -- 14542902F
    local current_addr = _start
    --self.logger:debug(string.format("load_player_sharpness, start %X", current_addr))
    local _max = 26001
    for i=1, _max do
        if current_addr == 0 then break end
        local pid = readInteger(current_addr + PLAYERSHARPNESS_STRUCT['pid'])
        if not pid then
            break
        end
        if pid == playerid then
            player_found = true
            break
        end
        if pid < playerid then
            current_addr = readPointer(current_addr)
        else
            current_addr = readPointer(current_addr+8)
        end
    end
    if not player_found or current_addr == 0 then
        self.logger:debug("Player Sharpness, player not found.")
        return 0
    end
    return current_addr
end

function thisFormManager:save_player_sharpness(playerid, new_value)
    if not playerid then
        self.logger:error("save_player_sharpness no playerid!")
        return
    end

    if new_value then
        if type(new_value) == "string" then
            new_value, _ = string.gsub(
                new_value,
                '%D', ''
            )

            new_value = tonumber(new_value) -- remove non-digits
        end
    end

    if new_value == nil then return end

    if new_value < 0 then
        new_value = 0
    elseif new_value > 100 then
        new_value = 100
    end

    local current_addr = self:get_player_sharpness_addr(playerid)
    if current_addr == 0 then
        return
    end
    writeBytes(current_addr + PLAYERSHARPNESS_STRUCT["sharpness"], new_value)

end

function thisFormManager:load_player_sharpness(playerid)
    local fn_comps_vis = function(visible)
        self.frm.SharpnessEdit.Visible = visible
        self.frm.SharpnessLabel.Visible = visible
    end
    if not playerid then
        fn_comps_vis(false)
        return
    end

    local current_addr = self:get_player_sharpness_addr(playerid)
    if current_addr == 0 then
        fn_comps_vis(false)
        return
    end

    fn_comps_vis(true)
    self.logger:debug(string.format("Player Sharpness found at %X", current_addr))
    local sharpness = readBytes(current_addr + PLAYERSHARPNESS_STRUCT["sharpness"], 1)
    self.frm.SharpnessEdit.Text = sharpness
end

function thisFormManager:get_player_release_clause_addr(playerid)
    local rlc_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pModeManagers"),
        {0x0, 0x518, 0x0, 0x20, 0xB8}
    )
    self.logger:debug(string.format("rlc_ptr: %X", rlc_ptr))
    -- Start list = 0x160
    -- end list = 0x168
    local _start = readPointer(rlc_ptr + 0x160)
    local _end = readPointer(rlc_ptr + 0x168)
    if (not _start) or (not _end) then
        self.logger:info("No Release Clauses start or end")
        return -1
    end

    local current_addr = _start
    local player_found = false
    local _max = 26001
    for i=1, _max do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        local pid = readInteger(current_addr + PLAYERRLC_STRUCT['pid'])
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERRLC_STRUCT['size']
    end
    if not player_found then
        return 0
    end
    return current_addr
end

function thisFormManager:save_player_release_clause(playerid, teamid, new_value)
    if not playerid then
        self.logger:error("save_player_release_clause no playerid!")
        return
    end

    if new_value then
        if type(new_value) == "string" then
            new_value, _ = string.gsub(
                new_value,
                '%D', ''
            )

            new_value = tonumber(new_value) -- remove non-digits
        end
    end

    local current_addr = self:get_player_release_clause_addr(playerid)
    -- No release clause pointer
    if current_addr == -1 then return end

    
    if new_value == 0 then
        -- Can't be 0
        new_value = nil
    elseif new_value and new_value > 2147483646 then
        -- Max possible value
        new_value = 2147483646
    end

    local add_clause = false
    local remove_clause = false
    if new_value == nil and current_addr == 0 then
        -- No new value and player don't have release clause
        return
    elseif new_value == nil and current_addr > 0 then
        -- Remove
        remove_clause = true
    elseif new_value and current_addr > 0 then
        -- Edit
        writeInteger(current_addr+PLAYERRLC_STRUCT["value"], new_value)
        return
    elseif new_value and current_addr == 0 then
        -- Add
        if not teamid then
            self.logger:error("save_player_release_clause no teamid!")
            return
        end
        add_clause = true
    end

    local rlc_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pModeManagers"),
        {0x0, 0x518, 0x0, 0x20, 0xB8}
    )
    local _start = readPointer(rlc_ptr + 0x160)
    local _end = readPointer(rlc_ptr + 0x168)
    if add_clause then
        current_addr = _end
        writeQword(rlc_ptr+0x168, current_addr+PLAYERRLC_STRUCT["size"])

        writeInteger(current_addr+PLAYERRLC_STRUCT["pid"], playerid)
        writeInteger(current_addr+PLAYERRLC_STRUCT["tid"], teamid)
        writeInteger(current_addr+PLAYERRLC_STRUCT["value"], new_value)
    elseif remove_clause then
        local bytecount = _end - current_addr + PLAYERRLC_STRUCT['size']
        local bytes = readBytes(current_addr+PLAYERRLC_STRUCT['size'], bytecount, true)
        writeBytes(current_addr, bytes)
        writeQword(rlc_ptr+0x168, _end-PLAYERRLC_STRUCT["size"])
    end
end

function thisFormManager:load_player_release_clause(playerid)
    local fn_comps_vis = function(visible)
        self.frm.ReleaseClauseEdit.Visible = visible
        self.frm.ReleaseClauseLabel.Visible = visible
    end

    if not playerid then
        fn_comps_vis(false)
        return
    end

    local current_addr = self:get_player_release_clause_addr(playerid)
    if current_addr == -1 then
        fn_comps_vis(false)
        return
    elseif current_addr == 0 then
        fn_comps_vis(true)
        self.frm.ReleaseClauseEdit.Text = "None"
        return
    end

    self.logger:debug(string.format("Player Release Clause found at %X", current_addr))
    local release_clause_value = readInteger(current_addr + PLAYERRLC_STRUCT['value'])
    self.frm.ReleaseClauseEdit.Text = release_clause_value
end

function thisFormManager:get_squad_role_addr(playerid)
    local squad_role_ptr = self.memory_manager:read_multilevel_pointer(
        readPointer("pCareerModeSmth"),
        {0x0, 0x10, 0x48, 0x30, 0x180+0x48}
    )
    -- teamid = squad_role_ptr + 18
    -- squad_role_ptr + 18 +0x8 Start list
    -- squad_role_ptr + 18 +x10 End List
    -- us002

    local _start = readPointer(squad_role_ptr + 0x20)
    local _end = readPointer(squad_role_ptr + 0x28)
    if (not _start) or (not _end) then
        self.logger:info("No Player Role start or end")
        return 0
    end
    --self.logger:debug(string.format("Player Role _start: %X", _start))
    --self.logger:debug(string.format("Player Role _end: %X", _end))
    local _max = 55
    local current_addr = _start
    local player_found = false
    for i=1, _max do
        if current_addr >= _end then
            -- no player to edit
            break
        end
        --self.logger:debug(string.format("Player Role current_addr: %X", current_addr))
        local pid = readInteger(current_addr + PLAYERROLE_STRUCT["pid"])
        --local role = readInteger(current_addr + PLAYERROLE_STRUCT["role"])
        --self.logger:debug(string.format("Player Role PID: %d, Role: %d", pid, role))
        if pid == playerid then
            player_found = true
            break
        end
        current_addr = current_addr + PLAYERROLE_STRUCT["size"]
    end
    if not player_found then
        return 0
    end
    return current_addr
end

function thisFormManager:save_player_contract(playerid, wage, squadrole, performance_bonus_type, performance_bonus_count, performance_bonus_value, loan_wage_split)
    if not playerid then
        self.logger:error("save_player_contract no playerid!")
        return
    end
    local table_name = "career_playercontract"
    local arr_flds = {
        {
            name = "playerid",
            expr = "eq",
            values = {playerid}
        }
    }

    local addr = self.game_db_manager:find_record_addr(
        table_name, arr_flds, 1 
    )

    -- No contract record
    if #addr <= 0 then
        return 
    end
    local playercontract_addr = addr[1]

    if squadrole ~= nil then
        local current_addr = self:get_squad_role_addr(playerid)
        if current_addr > 0 then
            writeInteger(current_addr + PLAYERROLE_STRUCT["role"], squadrole + 1)
        end
        self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "playerrole", squadrole+1)
    end

    if wage then
        if type(wage) == "string" then
            wage, _ = string.gsub(
                wage,
                '%D', ''
            )

            wage = tonumber(wage) -- remove non-digits
        end
        self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "wage", wage)
    end
    if loan_wage_split then
        if type(loan_wage_split) == "string" then
            loan_wage_split, _ = string.gsub(
                loan_wage_split,
                '%D', ''
            )

            loan_wage_split = tonumber(loan_wage_split) -- remove non-digits
        end
        self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "loan_wage_split", loan_wage_split)
    end

    if performance_bonus_type then
        self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonustype", performance_bonus_type)
        if performance_bonus_type == 0 then
            self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonusvalue", -1)
            self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonuscount", -1)
            self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonuscountachieved", 0)
        else
            if performance_bonus_value == nil then performance_bonus_value = 1 end
            if type(performance_bonus_value) == "string" then
                performance_bonus_value, _ = string.gsub(
                    performance_bonus_value,
                    '%D', ''
                )
    
                performance_bonus_value = tonumber(performance_bonus_value) -- remove non-digits
            end
            self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonusvalue", performance_bonus_value)
            local bonus = split(performance_bonus_count, '/')
            local current = tonumber(bonus[1])
            local max = tonumber(bonus[2])
            if current and max then
                local is_achieved = 0
                if max == current then
                    is_achieved = 1
                end
                self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "isperformancebonusachieved", is_achieved)
                self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonuscount", max)
                self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonuscountachieved", current)
            else
                self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "isperformancebonusachieved", 0)
                self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonuscount", 26)
                self.game_db_manager:set_table_record_field_value(playercontract_addr, table_name, "performancebonuscountachieved", 1)
            end
        end
    end


end

function thisFormManager:load_player_contract(playerid, is_in_user_club)
    local fn_comps_vis = function(visible)
        self.frm.WageLabel.Visible = visible
        self.frm.WageEdit.Visible = visible
        self.frm.SquadRoleLabel.Visible = visible
        self.frm.SquadRoleCB.Visible = visible
        self.frm.LoanWageSplitLabel.Visible = visible
        self.frm.LoanWageSplitEdit.Visible = visible
        self.frm.PerformanceBonusTypeLabel.Visible = visible
        self.frm.PerformanceBonusTypeCB.Visible = visible
        self.frm.PerformanceBonusCountLabel.Visible = visible
        self.frm.PerformanceBonusCountEdit.Visible = visible
        self.frm.PerformanceBonusValueLabel.Visible = visible
        self.frm.PerformanceBonusValueEdit.Visible = visible
    end

    if (
        not playerid or
        not is_in_user_club
    ) then
        fn_comps_vis(false)
        return 
    end

    local arr_flds = {
        {
            name = "playerid",
            expr = "eq",
            values = {playerid}
        }
    }

    local addr = self.game_db_manager:find_record_addr(
        "career_playercontract", arr_flds, 1 
    )

    -- No contract record
    if #addr <= 0 then
        fn_comps_vis(false)
        return 
    end
    local playercontract_addr = addr[1]
    local playerrole = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "playerrole")
    if playerrole == -1 then
        local current_addr = self:get_squad_role_addr(playerid)
        if current_addr > 0 then
            local role = readInteger(current_addr + PLAYERROLE_STRUCT["role"])
            self.frm.SquadRoleCB.ItemIndex = role - 1
            self.frm.SquadRoleCB.Hint = self.frm.SquadRoleCB.Items[self.frm.SquadRoleCB.ItemIndex]
        end
    else
        self.frm.SquadRoleCB.ItemIndex = playerrole - 1
        self.frm.SquadRoleCB.Hint = self.frm.SquadRoleCB.Items[self.frm.SquadRoleCB.ItemIndex]
    end
    fn_comps_vis(true)

    local wage = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "wage")
    self.frm.WageEdit.Text = wage

    local loan_wage_split = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "loan_wage_split")
    if loan_wage_split == -1 then
        self.frm.LoanWageSplitEdit.Text = "None"
        self.frm.LoanWageSplitLabel.Visible = false
        self.frm.LoanWageSplitEdit.Visible = false
    else
        self.frm.LoanWageSplitEdit.Text = string.format("%d", loan_wage_split) .. "%"
    end

    local performancebonustype = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "performancebonustype")
    self.frm.PerformanceBonusTypeCB.Hint = self.frm.PerformanceBonusTypeCB.Items[self.frm.PerformanceBonusTypeCB.ItemIndex]
    if performancebonustype == 0 then
        self.frm.PerformanceBonusTypeCB.ItemIndex = 0
        self.frm.PerformanceBonusCountEdit.Text = "0/25"
        self.frm.PerformanceBonusValueEdit.Text = "0"

        self.frm.PerformanceBonusCountLabel.Visible = false
        self.frm.PerformanceBonusCountEdit.Visible = false
        self.frm.PerformanceBonusValueLabel.Visible = false
        self.frm.PerformanceBonusValueEdit.Visible = false
    else
        self.frm.PerformanceBonusTypeCB.ItemIndex = performancebonustype
        local performancebonuscount = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "performancebonuscount")
        if performancebonuscount == -1 then
            self.frm.PerformanceBonusCountEdit.Text = "0/25"
        else
            local performancebonuscountachieved = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "performancebonuscountachieved")
            self.frm.PerformanceBonusCountEdit.Text = string.format("%d/%d", performancebonuscountachieved, performancebonuscount)
        end
        local performancebonusvalue = self.game_db_manager:get_table_record_field_value(playercontract_addr, "career_playercontract", "performancebonusvalue")
        self.frm.PerformanceBonusValueEdit.Text = performancebonusvalue
    end

end


function thisFormManager:onApplyChangesBtnClick()
    self.logger:info("Apply Changes player")

    if gCTManager.cfg.flags.hide_players_potential then
        self.change_list["PotentialEdit"] = nil
    end

    self.logger:debug("Iterate change_list")
    for key, value in pairs(self.change_list) do
        local comp_desc = self.form_components_description[key]
        local component = self.frm[key]
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

    local is_in_cm = is_cm_loaded()

    local is_manager_career = false
    local is_manager_career_valid = false
    if is_in_cm then
        is_manager_career = self:is_manager_career(self.current_addrs["career_users"])
        if type(is_manager_career) == "boolean" then
            is_manager_career_valid = true
        end
    end
    if is_in_cm and is_manager_career_valid then
        local playerid = tonumber(self.frm.PlayerIDEdit.Text)
        local teamid = tonumber(self.frm.TeamIDEdit.Text)

        -- TODO FIFA 22
        
        -- if self.change_list["FormCB"] then
        --     self:save_player_form(playerid, self.frm.FormCB.ItemIndex+1)
        -- end
        -- if self.change_list["MoraleCB"] then
        --     self:save_player_morale(playerid, self.frm.MoraleCB.ItemIndex+1)
        -- end
        -- if self.change_list["ReleaseClauseEdit"] then
        --     self:save_player_release_clause(playerid, teamid, self.frm.ReleaseClauseEdit.Text)
        -- end
        -- if self.change_list["SharpnessEdit"] then
        --     self:save_player_sharpness(playerid, self.frm.SharpnessEdit.Text)
        -- end

        if (
            self.change_list["WageEdit"] or 
            self.change_list["LoanWageSplitEdit"] or 
            self.change_list["SquadRoleCB"] or 
            self.change_list["PerformanceBonusTypeCB"] or 
            self.change_list["PerformanceBonusCountEdit"] or 
            self.change_list["PerformanceBonusValueEdit"]
        ) then
            local new_wage = nil
            if self.change_list["WageEdit"] and self.frm.WageEdit.Visible then
                new_wage = self.frm.WageEdit.Text
            end
            local new_squadrole = nil
            if self.change_list["SquadRoleCB"] and self.frm.SquadRoleCB.Visible then
                new_squadrole = self.frm.SquadRoleCB.ItemIndex
            end
            local new_performance_bonus_type = nil
            if self.frm.PerformanceBonusTypeCB.Visible then
                new_performance_bonus_type = self.frm.PerformanceBonusTypeCB.ItemIndex
            end
            local new_performance_count = nil
            if self.frm.PerformanceBonusCountEdit.Visible then
                new_performance_count = self.frm.PerformanceBonusCountEdit.Text
            end
            local new_performance_value = nil
            if self.frm.PerformanceBonusValueEdit.Visible then
                new_performance_value = self.frm.PerformanceBonusValueEdit.Text
            end
            local new_loan_wage_split = nil
            if self.change_list["LoanWageSplitEdit"] and self.frm.LoanWageSplitEdit.Visible then
                new_loan_wage_split = self.frm.LoanWageSplitEdit.Text
            end

            self:save_player_contract(
                playerid,
                new_wage,
                new_squadrole,
                new_performance_bonus_type,
                new_performance_count,
                new_performance_value,
                new_loan_wage_split
            )
        end

        -- TODO FIFA 22

        -- if (
        --     self.change_list["IsInjuredCB"] or
        --     self.change_list["InjuryCB"] or
        --     self.change_list["DurabilityEdit"] or
        --     self.change_list["FullFitDateEdit"]
        -- ) then
        --     local new_durability = nil
        --     if self.frm.DurabilityEdit.Visible then
        --         new_durability = self.frm.DurabilityEdit.Text
        --     end

        --     local new_isinjured = 0
        --     if self.frm.IsInjuredCB.Visible then
        --         new_isinjured = self.frm.IsInjuredCB.ItemIndex
        --     end

        --     local new_injury = 0
        --     if self.frm.InjuryCB.Visible then
        --         new_injury = self.frm.InjuryCB.ItemIndex
        --     end

        --     local new_fullfit = 20080101
        --     if self.frm.FullFitDateEdit.Visible then
        --         new_fullfit = self.frm.FullFitDateEdit.Text
        --     end

        --     self:save_player_fitness(
        --         playerid,
        --         new_durability,
        --         new_isinjured,
        --         new_injury,
        --         new_fullfit
        --     )
        -- end


    end

    self.has_unsaved_changes = false
    self.change_list = {}
    local msg = string.format("Player with ID %s has been edited", self.frm.PlayerIDEdit.Text)
    showMessage(msg)
    self.logger:info(msg)
end

function thisFormManager:check_if_has_unsaved_changes()
    if self.has_unsaved_changes then
        if messageDialog("You have some unsaved changes in player editor\nDo you want to apply them?", mtInformation, mbYes,mbNo) == mrYes then
            self:onApplyChangesBtnClick()
        else
            self.has_unsaved_changes = false
            self.change_list = {}
        end
    end
end

function thisFormManager:fut_find_player(player_name, page, fut_fifa)
    if page == nil then
        page = 1
    end

    -- no pagination here on futbin
    local request = URL_LINKS['FUT']['player_search'] .. string.format(
        '?year=%d&extra=1&term=%s',
        fut_fifa, encodeURI(player_name)
    )
    --self.logger:debug(string.format("FUT FIND PLAYER: %s", request))
    local r = getInternet()
    local reply = r.getURL(request)
    if reply == nil then
        self.logger:warning(string.format('No internet connection? No reply from: %s', request))
        return nil
    end

    local status, response = pcall(
        json.decode,
        reply
    )

    if status == false then
        self.logger:error('Futbin error: ' .. reply)
        return nil
    elseif response['error'] then
        self.logger:error('Futbin error: ' .. response['error'])
        return nil
    end
    --self.logger:debug(string.format("FUT FIND PLAYER response:\n %s", response))

    return response
end

function thisFormManager:fut_search_player(player_data, page)
    if string.len(player_data) < 3 then
        showMessage("Input at least 3 characters.")
        return
    end
    local fut_fifa = FIFA - self.frm.FutFIFACB.ItemIndex

    self.fut_found_players = self:fut_find_player(player_data, page, fut_fifa)
    if self.fut_found_players == nil then return end

    local players = self.fut_found_players

    local players_count = #players
    local scrollbox_width = 310

    -- FUTBIN, no pagination
    -- if players_count >= 24 then
    --     can_continue = true
    -- else
    --     can_continue = false
    -- end
    can_continue = false
    self.frm.NextPage.Enabled = can_continue

    if page == 1 then
        self.frm.PrevPage.Enabled = false
    else
        self.frm.PrevPage.Enabled = true
    end

    for i=1, players_count do
        local player = players[i]
        local card_type = player['version'] or 'Normal'
        local formated_string = string.format(
            '%s - %s - %d ovr - %s',
            player['full_name'], card_type, player['rating'], player['position']
        )

        -- Dynamic width
        local str_len = string.len(formated_string)
        if str_len >= 35 then
            local new_width = 310 + ((str_len - 35) * 8)
            if new_width > scrollbox_width then
                scrollbox_width = new_width
            end
        end
        self.frm.FUTPickPlayerListBox.Items.Add(formated_string)
    end

    -- Change width (add scroll)
    if scrollbox_width ~= self.frm.FUTPickPlayerListBox.Width then
        self.frm.FUTPickPlayerListBox.Width = scrollbox_width
    end

    if scrollbox_width > 310 then
        self.frm.FUTPickPlayerScrollBox.HorzScrollBar.Visible = true
    else
        self.frm.FUTPickPlayerScrollBox.HorzScrollBar.Visible = false
    end

    if players_count >= 27 then
        self.frm.FUTPickPlayerScrollBox.VertScrollBar.Visible = true
    else
        self.frm.FUTPickPlayerScrollBox.VertScrollBar.Visible = false
    end
end

function thisFormManager:fut_get_player_details(playerid, fut_fifa)
    self.logger:info(string.format("Loading FUT%d player: %d", fut_fifa, playerid))
    local request = string.format(
        URL_LINKS['FUT']['player_details'],
        fut_fifa,
        playerid
    )
    self.logger:debug(string.format("fut_get_player_details: %s", request))
    local r = getInternet()
    local reply = r.getURL(request)
    if reply == nil then
        self.logger:error(string.format('No internet connection? No reply from: %s', request))
        return nil
    end
    --self.logger:info(reply)
    self.logger:info(string.format("Reply len: %d", string.len(reply)))

    local base_playerid = string.match(reply, 'data%-baseid="(%d+)"')
    if base_playerid then
        self.logger:info(string.format("base_playerid: %d", base_playerid))
    end

    local miniface_img = string.match(reply, '<img%s+class="pcdisplay%-picture%-width "%s+id="player_pic"%s+src="(%a+://[%a+%./%d%?%=]+)')
    if miniface_img then
        self.logger:debug(string.format("miniface_img: %s", miniface_img))
    end
    local club_img = string.match(reply, '<img alt="c" id="player_club"%s+src="(%a+://[%a+%./%d%?%=]+)')

    local club_id = 0
    if club_img ~= nil then
        club_id = string.match(club_img, 'clubs/(%d+).png')
    else
        self.logger:info("club_img not found")
    end

    local nation_img = string.match(reply, '<img alt="n" id="player_nation"%s+src="(%a+://[%a+%./%d%?%=]+)')
    local nation_id = 0
    if nation_img ~= nil then
        nation_id = string.match(nation_img, 'nation/(%d+).png')
    else
        self.logger:info("nation_img not found")
    end

    local ovr = string.match(reply, '<div style="color:[#%S+;|;]+" class="pcdisplay%-rat">(%d+)</div>')
    local name = string.match(reply, '<div style="color:[#%S+;|;]+" class="pcdisplay%-name">([%S-? ?]+)</div>')
    local pos = string.match(reply, '<div style="color:[#%S+;|;]+" class="pcdisplay%-pos">([%w]+)</div>')

    local stat1_name, stat1_val = string.match(reply, '<div%A+class="pcdisplay%-ovr1 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat2_name, stat2_val = string.match(reply, '<div%A+class="pcdisplay%-ovr2 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat3_name, stat3_val = string.match(reply, '<div%A+class="pcdisplay%-ovr3 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat4_name, stat4_val = string.match(reply, '<div%A+class="pcdisplay%-ovr4 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat5_name, stat5_val = string.match(reply, '<div%A+class="pcdisplay%-ovr5 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat6_name, stat6_val = string.match(reply, '<div%A+class="pcdisplay%-ovr6 stat%-val" data%-stat="(%w+)">(%d+)</div>')
    local stat_json = string.match(reply, '<div style="display: none;" id="player_stats_json">([{"%w:,}]+)</div>')

    local special_img, rev, lvl, rare_type = string.match(reply, '<div id="Player%-card" data%-special%-img="(%d)" data%-revision="([(%w+_?)"|"]+) data%-level="(%w+)" data%-rare%-type="(%d+)"')

    local card = nil
    local card_type = nil

    if rev == '"' then
        rev = nil
    elseif rev ~= nil then
        rev = string.gsub(rev, '"', '')
    end

    if (fut_fifa == 20 or fut_fifa == 21) and (rare_type ~= nil and lvl ~= nil)then
        if (rev == nil) or (rev == 'if') then
            -- TODO Other FIFAs
            card = string.format(
                "%d_%s.png",
                rare_type, lvl
            )
            card_type = string.format('%s-%s', rare_type, lvl)
        else
            card = string.format(
                "%d_%s.png",
                rare_type, rev
            )
            card_type = string.format('%s-%s', rare_type, rev)
        end
    else
        rare_type = 1
        rev = 'gold'
        card = string.format(
            "%d_%s.png",
            rare_type, rev
        )
        card_type = string.format('%s-%s', rare_type, rev)
    end

    if stat_json ~= nil then
        stat_json = json.decode(stat_json)

        -- Special mapping for GK... 
        if pos == "GK" then
            stat_json['gkdiving'] = stat_json['ppace']
            stat_json['gkhandling'] = stat_json['pshooting']
            stat_json['gkkicking'] = stat_json['ppassing']
            stat_json['gkreflexes'] = stat_json['pdribbling']
            stat_json['gkpositioning'] = stat_json['pphysical']
            stat_json['speed'] = stat_json['pdefending']
        end
    end

    self.logger:debug(string.format("Card: %s, card_type: %s", card, card_type))
    self.logger:info(string.format("Loading FUT%d player: %d Finished", fut_fifa, playerid))

    return {
        base_playerid = base_playerid,
        special_img = special_img,
        card = card,
        card_type = card_type,
        miniface_img = miniface_img,
        club_img = club_img,
        nation_img = nation_img,
        club_id = club_id,
        nation_id = nation_id,
        ovr = ovr,
        name = name,
        pos = pos,
        stat1_name = stat1_name,
        stat1_val = stat1_val,
        stat2_name = stat2_name,
        stat2_val = stat2_val,
        stat3_name = stat3_name,
        stat3_val = stat3_val,
        stat4_name = stat4_name,
        stat4_val = stat4_val,
        stat5_name = stat5_name,
        stat5_val = stat5_val,
        stat6_name = stat6_name,
        stat6_val = stat6_val,
        stat_json = stat_json
    }
end

function thisFormManager:fut_create_card(player, idx)
    if not player then return end

    local fut_fifa = FIFA - self.frm.FutFIFACB.ItemIndex
    local player_details = self:fut_get_player_details(player['id'], fut_fifa)
    self.fut_found_players[idx]['details'] = player_details

    -- Cards img
    local card = player_details['card']
    if card ~= nil then
        local url = URL_LINKS['FUT']['card_bg'] .. card .. '?v=138'
        local stream = self:load_img('ut/cards_bg/' .. card, url)

        if stream then
            self.frm.CardBGImage.Picture.LoadFromStream(stream)
            stream.destroy()
        else
            self.logger:info("invalid card bg: " .. card .. " trying to load default gold")
            card = '1_gold.png'
            player_details['card_type'] = '1-gold'
            url = URL_LINKS['FUT']['card_bg'] .. card .. '?v=138'
            stream = self:load_img('ut/cards_bg/' .. card, url)
            if stream then
                self.frm.CardBGImage.Picture.LoadFromStream(stream)
                stream.destroy()
            else
                self.logger:info("default gold bg failed")
            end
        end
    end
    -- Headshot
    if player_details['miniface_img'] ~= nil then
        local img_comp = nil
        if player_details['special_img'] == 1 then
            img_comp = self.frm.CardSpecialHeadshotImage
            self.frm.CardHeadshotImage.Visible = false
            self.frm.CardSpecialHeadshotImage.Visible = true
        else
            img_comp = self.frm.CardHeadshotImage
            self.frm.CardHeadshotImage.Visible = true
            self.frm.CardSpecialHeadshotImage.Visible = false
        end
        -- print(player['headshot']['imgUrl'])

        local stream = self:load_img(
            string.format('heads/p%d.png', player['id']),
            player_details['miniface_img']
        )
        if stream then
            img_comp.Picture.LoadFromStream(stream)
            stream.destroy()
        end
    end

    -- Nationality Img
    local stream = self:load_img(
        string.format('flags/f%d.png', player_details['nation_id']),
        player_details['nation_img']
    )
    if stream then
        self.frm.CardNatImage.Picture.LoadFromStream(stream)
        stream.destroy()
    end

    -- Club crest Img
    stream = self:load_img(
        string.format('crest/l%d.png', player_details['club_id']),
        player_details['club_img']
    )
    if stream then
        self.frm.CardClubImage.Picture.LoadFromStream(stream)
        stream.destroy()
    end

    -- Font colors for labels on card
    local type_color_map = {
        -- Non Rare
        ['0-bronze'] = '0x2B2217',
        ['0-silver'] = '0x26292A',
        ['0-gold'] = '0x443A22',

        -- Rare
        ['1-bronze'] = '0x3A2717',
        ['1-silver'] = '0x303536',
        ['1-gold'] = '0x46390C',

        -- TOTW
        ['3-bronze'] = '0xBB9266',
        ['3-silver'] = '0xB0BCC8',
        ['3-gold'] = '0xE9CC74',

        -- HERO
        ['4-gold'] = '0xFBFBFB',

        -- TOTY
        ['5-gold'] = '0xEBCD5B',

        -- Record breaker
        ['6-gold'] = '0xFBFBFB',

        -- St. Patrick's Day
        ['7-gold'] = '0xFBFBFB',

        -- Domestic MOTM
        ['8-gold'] = '0xFBFBFB',

        -- FUT Champions
        ['18-bronze'] = '0xBB9266',
        ['18-silver'] = '0xB0BCC8',
        ['18-gold'] = '0xE3CF83',

        -- Pro player
        ['10-gold'] = '0x625217',

        -- Special item
        ['9-gold'] = '0x12FCC6',
        ['11-gold'] = '0x12FCC6',
        ['16-gold'] = '0x12FCC6',
        ['23-gold'] = '0x12FCC6',
        ['26-gold'] = '0x12FCC6',
        ['30-gold'] = '0x12FCC6',
        ['37-gold'] = '0x12FCC6',
        ['44-gold'] = '0x12FCC6',
        ['50-gold'] = '0x12FCC6',
        ['80-gold'] = '0x12FCC6',

        -- Icons
        ['12-icon'] = '0x625217',

        -- The journey
        ['17-gold'] = '0xE9CC74',

        -- OTW
        ['21-gold'] = '0xFF4782',

        -- Ultimate SCREAM
        ['21-otw'] = '0xFF690D',

        -- SBC
        ['24-gold'] = '0x72C0FF',

        -- Premium SBC
        ['25-gold'] = '0xFD95F6',

        -- Award winner
        ['28-gold'] = '0xFBFBFB',

        -- FUTMAS
        ['32-gold'] = '0xFBFBFB',

        -- POTM Bundesliga
        ['42-gold'] = '0xFBFBFB',

        -- POTM PL
        ['43-gold'] = '0x05f1ff',

        -- UEFA Euro League MOTM
        ['45-gold'] = '0xF39200',

        -- UCL Common
        ['47-gold'] = '0xFBFBFB',

        -- UCL Rare
        ['48-gold'] = '0xFBFBFB',

        -- UCL MOTM
        ['49-gold'] = '0xFBFBFB',

        -- Flashback sbc
        ['51-sbc_flashback'] = '0xB0FFEB',
        
        -- Swap Deals I
        ['52-bronze'] = '0x05b3c3',
        ['52-silver'] = '0x05b3c3',
        ['52-gold'] = '0x05b3c3',

        -- Swap Deals II
        ['53-gold'] = '0x05b3c3',

        -- Swap Deals III
        ['54-gold'] = '0x05b3c3',

        -- Swap Deals IV
        ['55-gold'] = '0x05b3c3',

        -- Swap Deals V
        ['56-gold'] = '0x05b3c3',

        -- Swap Deals VI
        ['57-gold'] = '0x05b3c3',

        -- Swap Deals VII
        ['58-gold'] = '0x05b3c3',

        -- Swap Deals VII
        ['59-gold'] = '0x05b3c3',

        -- Swap Deals IX
        ['60-gold'] = '0x05b3c3',

        -- Swap Deals X
        ['61-gold'] = '0x05b3c3',

        -- Swap Deals XI
        ['62-gold'] = '0x05b3c3',

        -- Swap Deals Rewards
        ['63-gold'] = '0x05b3c3',

        -- TOTY Nominee
        ['64-gold'] = '0xEFD668',

        -- TOTS Nominee
        ['65-gold'] = '0xEFD668',

        -- TOTS 85+
        ['66-gold'] = '0xEFD668',

        -- POTM MLS
        ['67-gold'] = '0xFBFBFB',

        -- UEFA Euro League TOTT
        ['68-gold'] = '0xFBFBFB',

        -- UCL Premium SBC
        ['69-gold'] = '0xFBFBFB',

        -- UCL Euro League TOTT
        ['70-gold'] = '0xFBFBFB',

        -- FUTURE Stars
        ['71-gold'] = '0xC0FF36',

        -- Carniball
        ['72-gold'] = '0xC0FF36',

        -- Lunar NEW YEAR
        ['73-gold'] = '0xFBFBFB',

        -- Holi
        ['74-gold'] = '0xFBFBFB',

        -- Easter
        ['75-gold'] = '0xFBFBFB',

        -- National Day I
        ['76-gold'] = '0xFBFBFB',

        -- UEFA EUROPA LEAGUE
        ['78-gold'] = '0xFBFBFB',

        -- POTM LaLiga
        ['79-gold'] = '0xFBFBFB',

        -- FUTURE Stars Nom
        ['83-gold'] = '0xC0FF36',

        -- Priem icon Moments
        ['84-gold'] = '0x625217',

        -- Headliners
        ['85-gold'] = '0xFBFBFB',
    }

    -- print(string.format('%d-%s', player['rarityId'], player['quality']))
    local f_color = type_color_map[player_details['card_type']]

    if f_color == nil then
        f_color = '0xFBFBFB'
    end

    -- OVR LABEL
    self.frm.CardNameLabel.Caption = player_details['ovr']
    self.frm.CardNameLabel.Font.Color = f_color

    -- Position LABEL
    self.frm.CardPosLabel.Caption = player_details['pos']
    self.frm.CardPosLabel.Font.Color = f_color

    -- Player Name Label
    self.frm.CardPlayerNameLabel.Caption = player_details['name']
    self.frm.CardPlayerNameLabel.Font.Color = f_color

    -- Attributes
    self:fut_fill_attributes(player_details, f_color)
end

function thisFormManager:fut_fill_attributes(player, f_color)
    -- Attr chem styles

    local chanded_attr_arr = {}

    local picked_chem_style = self.frm.FUTChemStyleCB.Items[self.frm.FUTChemStyleCB.ItemIndex]

    -- If picked chem style other than None/Basic
    if string.match(picked_chem_style, ',') then
        local changed_attr = split(string.match(picked_chem_style, "%((.+)%)"), ',')
        for i=1, #changed_attr do
            local attr = changed_attr[i]
            attr = string.gsub(attr, '+', '')
            chanded_attr_arr[string.match(attr, "([A-Z]+)")] = tonumber(string.match(attr, "([0-9]+)"))
        end
    end

    -- Attributes
    local attr_abbr = {
        pace = "PAC",
        shooting = "SHO",
        passing = "PAS",
        dribblingp = "DRI",
        defending = "DEF",
        heading = "PHY",
        gkdiving = "DIV",
        gkhandling = "HAN",
        gkkicking = "KIC",
        gkreflexes = "REF",
        speed = "SPE",
        gkpositioning = "POS"
    }
    for i=1, 6 do
        local component = self.frm[string.format('CardPlayerAttrLabel%d', i)]
        local attr_name = attr_abbr[player[string.format('stat%d_name', i)]]
        local attr_val = player[string.format('stat%d_val', i)]
        if chanded_attr_arr[attr_name] then
            attr_val = string.format("%d +%d", attr_val, chanded_attr_arr[attr_name])
        end

        local caption = string.format(
            '%s %s',
            attr_val,
            attr_name
        )
        component.Caption = caption
        if f_color then component.Font.Color = f_color end
    end
end

function thisFormManager:fut_copy_card_to_gui(player)
    self.logger:info("fut_copy_card_to_gui")
    local columns = {
        firstnameid = 1,
        lastnameid = 2,
        playerjerseynameid = 3,
        commonnameid = 4,
        skintypecode = 5,
        trait2 = 6,
        bodytypecode = 7,
        haircolorcode = 8,
        facialhairtypecode = 9,
        curve = 10,
        jerseystylecode = 11,
        agility = 12,
        tattooback = 13,
        accessorycode4 = 14,
        gksavetype = 15,
        positioning = 16,
        tattooleftarm = 17,
        hairtypecode = 18,
        standingtackle = 19,
        preferredposition3 = 20,
        longpassing = 21,
        penalties = 22,
        animfreekickstartposcode = 23,
        animpenaltieskickstylecode = 24,
        isretiring = 25,
        longshots = 26,
        gkdiving = 27,
        interceptions = 28,
        shoecolorcode2 = 29,
        crossing = 30,
        potential = 31,
        gkreflexes = 32,
        finishingcode1 = 33,
        reactions = 34,
        composure = 35,
        vision = 36,
        contractvaliduntil = 37,
        animpenaltiesapproachcode = 38,
        finishing = 39,
        dribbling = 40,
        slidingtackle = 41,
        accessorycode3 = 42,
        accessorycolourcode1 = 43,
        headtypecode = 44,
        sprintspeed = 45,
        height = 46,
        hasseasonaljersey = 47,
        tattoohead = 48,
        preferredposition2 = 49,
        strength = 50,
        shoetypecode = 51,
        birthdate = 52,
        preferredposition1 = 53,
        tattooleftleg = 54,
        ballcontrol = 55,
        shotpower = 56,
        trait1 = 57,
        socklengthcode = 58,
        weight = 59,
        hashighqualityhead = 60,
        gkglovetypecode = 61,
        tattoorightarm = 62,
        balance = 63,
        gender = 64,
        headassetid = 65,
        gkkicking = 66,
        internationalrep = 67,
        animpenaltiesmotionstylecode = 68,
        shortpassing = 69,
        freekickaccuracy = 70,
        skillmoves = 71,
        faceposerpreset = 72,
        usercaneditname = 73,
        avatarpomid = 74,
        attackingworkrate = 75,
        finishingcode2 = 76,
        aggression = 77,
        acceleration = 78,
        headingaccuracy = 79,
        iscustomized = 80,
        eyebrowcode = 81,
        runningcode2 = 82,
        modifier = 83,
        gkhandling = 84,
        eyecolorcode = 85,
        jerseysleevelengthcode = 86,
        accessorycolourcode3 = 87,
        accessorycode1 = 88,
        playerjointeamdate = 89,
        headclasscode = 90,
        defensiveworkrate = 91,
        tattoofront = 92,
        nationality = 93,
        preferredfoot = 94,
        sideburnscode = 95,
        weakfootabilitytypecode = 96,
        jumping = 97,
        personality = 98,
        gkkickstyle = 99,
        stamina = 100,
        playerid = 101,
        marking = 102,
        accessorycolourcode4 = 103,
        gkpositioning = 104,
        headvariation = 105,
        skillmoveslikelihood = 106,
        skintonecode = 107,
        shortstyle = 108,
        overallrating = 109,
        smallsidedshoetypecode = 110,
        emotion = 111,
        runstylecode = 112,
        jerseyfit = 113,
        accessorycode2 = 114,
        shoedesigncode = 115,
        shoecolorcode1 = 116,
        hairstylecode = 117,
        animpenaltiesstartposcode = 118,
        runningcode1 = 119,
        preferredposition4 = 120,
        volleys = 121,
        accessorycolourcode2 = 122,
        tattoorightleg = 123,
        facialhaircolorcode = 124
    }

    local comp_to_column = {
        FirstNameIDEdit = 'firstnameid',
        LastNameIDEdit = 'lastnameid',
        JerseyNameIDEdit = 'playerjerseynameid',
        CommonNameIDEdit = 'commonnameid',
        HairColorCB = "haircolorcode",
        FacialHairTypeEdit = "facialhairtypecode",
        CurveEdit = "curve",
        JerseyStyleEdit = "jerseystylecode",
        AgilityEdit = "agility",
        AccessoryEdit4 = "accessorycode4",
        GKSaveTypeEdit = "gksavetype",
        AttackPositioningEdit = "positioning",
        HairTypeEdit = "hairtypecode",
        StandingTackleEdit = "standingtackle",
        PreferredPosition3CB = "preferredposition3",
        LongPassingEdit = "longpassing",
        PenaltiesEdit = "penalties",
        AnimFreeKickStartPosEdit = "animfreekickstartposcode",
        AnimPenaltiesKickStyleEdit = "animpenaltieskickstylecode",
        IsRetiringCB = "isretiring",
        LongShotsEdit = "longshots",
        GKDivingEdit = "gkdiving",
        InterceptionsEdit = "interceptions",
        shoecolorEdit2 = "shoecolorcode2",
        CrossingEdit = "crossing",
        PotentialEdit = "potential",
        GKReflexEdit = "gkreflexes",
        FinishingCodeEdit1 = "finishingcode1",
        ReactionsEdit = "reactions",
        ComposureEdit = "composure",
        VisionEdit = "vision",
        AnimPenaltiesApproachEdit = "animpenaltiesapproachcode",
        FinishingEdit = "finishing",
        DribblingEdit = "dribbling",
        SlidingTackleEdit = "slidingtackle",
        AccessoryEdit3 = "accessorycode3",
        AccessoryColourEdit1 = "accessorycolourcode1",
        HeadTypeCodeCB = "headtypecode",
        SprintSpeedEdit = "sprintspeed",
        HeightEdit = "height",
        hasseasonaljerseyEdit = "hasseasonaljersey",
        PreferredPosition2CB = "preferredposition2",
        StrengthEdit = "strength",
        shoetypeEdit = "shoetypecode",
        AgeEdit = "birthdate",
        PreferredPosition1CB = "preferredposition1",
        BallControlEdit = "ballcontrol",
        ShotPowerEdit = "shotpower",
        socklengthEdit = "socklengthcode",
        WeightEdit = "weight",
        HasHighQualityHeadCB = "hashighqualityhead",
        GKGloveTypeEdit = "gkglovetypecode",
        BalanceEdit = "balance",
        HeadAssetIDEdit = "headassetid",
        GKKickingEdit = "gkkicking",
        InternationalReputationCB = "internationalrep",
        AnimPenaltiesMotionStyleEdit = "animpenaltiesmotionstylecode",
        ShortPassingEdit = "shortpassing",
        FreeKickAccuracyEdit = "freekickaccuracy",
        SkillMovesCB = "skillmoves",
        FacePoserPresetEdit = "faceposerpreset",
        AttackingWorkRateCB = "attackingworkrate",
        FinishingCodeEdit2 = "finishingcode2",
        AggressionEdit = "aggression",
        AccelerationEdit = "acceleration",
        HeadingAccuracyEdit = "headingaccuracy",
        EyebrowEdit = "eyebrowcode",
        runningcodeEdit2 = "runningcode2",
        ModifierEdit = "modifier",
        GKHandlingEdit = "gkhandling",
        EyeColorEdit = "eyecolorcode",
        jerseysleevelengthEdit = "jerseysleevelengthcode",
        AccessoryColourEdit3 = "accessorycolourcode3",
        AccessoryEdit1 = "accessorycode1",
        HeadClassCodeEdit = "headclasscode",
        DefensiveWorkRateCB = "defensiveworkrate",
        NationalityCB = "nationality",
        PreferredFootCB = "preferredfoot",
        SideburnsEdit = "sideburnscode",
        WeakFootCB = "weakfootabilitytypecode",
        JumpingEdit = "jumping",
        SkinTypeEdit = "skintypecode",
        GKKickStyleEdit = "gkkickstyle",
        StaminaEdit = "stamina",
        MarkingEdit = "marking",
        AccessoryColourEdit4 = "accessorycolourcode4",
        GKPositioningEdit = "gkpositioning",
        HeadVariationEdit = "headvariation",
        SkillMoveslikelihoodEdit = "skillmoveslikelihood",
        SkinColorCB = "skintonecode",
        shortstyleEdit = "shortstyle",
        OverallEdit = "overallrating",
        EmotionEdit = "emotion",
        JerseyFitEdit = "jerseyfit",
        AccessoryEdit2 = "accessorycode2",
        shoedesignEdit = "shoedesigncode",
        shoecolorEdit1 = "shoecolorcode1",
        HairStyleEdit = "hairstylecode",
        BodyTypeCB = "bodytypecode",
        AnimPenaltiesStartPosEdit = "animpenaltiesstartposcode",
        runningcodeEdit1 = "runningcode1",
        PreferredPosition4CB = "preferredposition4",
        VolleysEdit = "volleys",
        AccessoryColourEdit2 = "accessorycolourcode2",
        FacialHairColorEdit = "facialhaircolorcode"
    }

    local comp_to_fut = {
        OverallEdit = "ovr",
        LongShotsEdit = "longshotsaccuracy"
    }

    local playerid = tonumber(player['details']['base_playerid'])
    if playerid == nil then
        self.logger:critical('COPY ERROR\n baseplayerid is nil')
        return
    end

    -- No prime icons in our database, replace all info with medium version
    local prime_to_medium_icon = {
        [237067] = 237068,
        [190042] = 237074,
        [37576] = 237064,
        [1397] = 248450,
        [28130] = 238395,
        [190045] = 242522,
        [238380] = 238193,
        [247553] = 247555,
        [993] = 256014,
        [1114] = 243078,
        [1625] = 237069,
        [166906] = 239528,
        [167135] = 247324,
        [192181] = 239055,
        [226764] = 238438,
        [214100] = 238434,
        [238435] = 191189,
        [242519] = 242520,
        [996] = 255477,
        [984] = 255910,
        [241] = 239521,
        [1041] = 239517,
        [1088] = 239062,
        [1183] = 239065,
        [4231] = 242950,
        [4833] = 239542,
        [5589] = 239080,
        [7763] = 247614,
        [10264] = 239532,
        [45661] = 242939,
        [166149] = 247547,
        [190044] = 239531,
        [191695] = 239604,
        [214267] = 239522,
        [238382] = 1075,
        [238384] = 238386,
        [238388] = 4000,
        [238428] = 190053,
        [247699] = 247701,
        [990] = 255358,
        [51] = 239598,
        [246] = 239537,
        [1116] = 239526,
        [1256] = 242927,
        [1605] = 239069,
        [3647] = 243784,
        [5419] = 239082,
        [5984] = 242860,
        [6235] = 239602,
        [13128] = 239420,
        [13743] = 242931,
        [23174] = 254571,
        [31432] = 247695,
        [51539] = 239061,
        [138449] = 247075,
        [161840] = 239068,
        [166124] = 239057,
        [167680] = 247301,
        [190046] = 242518,
        [222000] = 239059,
        [238424] = 238425,
        [238427] = 1419,
        [238430] = 1040,
        [238443] = 238444,
        [242510] = 242511,
        [247703] = 247706,
        [999] = 256154,
        [987] = 256869,
        [981] = 256339,
        [969] = 256432,
        [240] = 239600,
        [570] = 239109,
        [1025] = 238431,
        [1198] = 239071,
        [1201] = 239111,
        [1620] = 238414,
        [1668] = 242859,
        [5471] = 242930,
        [5673] = 239114,
        [7289] = 237066,
        [7512] = 238418,
        [45674] = 247307,
        [53769] = 239026,
        [156353] = 238420,
        [214098] = 239421,
        [238441] = 5681,
        [239261] = 52241,
        [239519] = 942,
        [243027] = 7518,
        [243781] = 243712,
        [978] = 257417,
        [972] = 255758,
        [243029] = 243028,
        [243030] = 4202,
        [247515] = 247514,
        [248146] = 248155,
        [250890] = 250891,
        [975] = 255355,
        [242625] = 13383,
        [238439] = 238440
    }

    self.logger:info(string.format("fut_copy_card_to_gui, playerid: %d", playerid))
    if prime_to_medium_icon[playerid] then
        playerid = prime_to_medium_icon[playerid]
        self.logger:info(string.format("fut_copy_card_to_gui, remapped playerid: %d", playerid))
    end


    local comps_desc = self:get_components_description()
    local fut_players_file_path = "other/fut/base_fut_players.csv"
    for line in io.lines(fut_players_file_path) do
        local values = split(line, ',')
        local f_playerid = tonumber(values[columns['playerid']])
        if not f_playerid then goto continue end

        if f_playerid == playerid then
            if self.frm.FUTCopyAttribsCB.State == 0 then
                local trait1_comps = {
                    "LongThrowInCB",
                    "PowerFreeKickCB",
                    "InjuryProneCB",
                    "SolidPlayerCB",
                    "DivesIntoTacklesCB",
                    "",
                    "LeadershipCB",
                    "EarlyCrosserCB",
                    "FinesseShotCB",
                    "FlairCB",
                    "LongPasserCB",
                    "LongShotTakerCB",
                    "SpeedDribblerCB",
                    "PlaymakerCB",
                    "GKLongthrowCB",
                    "PowerheaderCB",
                    "GiantthrowinCB",
                    "OutsitefootshotCB",
                    "SwervePassCB",
                    "SecondWindCB",
                    "FlairPassesCB",
                    "BicycleKicksCB",
                    "GKFlatKickCB",
                    "OneClubPlayerCB",
                    "TeamPlayerCB",
                    "ChipShotCB",
                    "TechnicalDribblerCB",
                    "RushesOutOfGoalCB",
                    "CautiousWithCrossesCB",
                    "ComesForCrossessCB"
                }
                local trait1 = toBits(tonumber(values[columns['trait1']]))
                local index = 1
                for ch in string.gmatch(trait1, '.') do
                    local comp = self.frm[trait1_comps[index]]
                    if comp then
                        comp.State = tonumber(ch)
                        self.change_list[comp.Name] = tonumber(ch)
                    end
                    
                    index = index + 1
                end

                local trait2_comps = {
                    "",
                    "SaveswithFeetCB",
                    "SetPlaySpecialistCB"
                }
                local trait2 = toBits(tonumber(values[columns['trait2']]))
                local index = 1
                for ch in string.gmatch(trait2, '.') do
                    local comp = self.frm[trait2_comps[index]]
                    if comp then
                        comp.State = tonumber(ch)
                        self.change_list[comp.Name] = tonumber(ch)
                    end
                    
                    index = index + 1
                end
            end
            
            local dont_copy_headmodel = (
                self.frm.FUTCopyHeadModelCB.State == 1 or
                self.frm.FutFIFACB.ItemIndex > 0
            )
            for key, value in pairs(comp_to_column) do
                local component = self.frm[key]
                local component_name = component.Name
                local comp_desc = comps_desc[component_name]
                local component_class = component.ClassName
                local org_comp_on_change = component.OnChange
                if dont_copy_headmodel and (
                    component_name == 'HeadClassCodeEdit' or 
                    component_name == 'HeadAssetIDEdit' or 
                    component_name == 'HeadVariationEdit' or 
                    component_name == 'HairTypeEdit' or 
                    component_name == 'HairStyleEdit' or 
                    component_name == 'FacialHairTypeEdit' or 
                    component_name == 'FacialHairColorEdit' or 
                    component_name == 'SideburnsEdit' or 
                    component_name == 'EyebrowEdit' or 
                    component_name == 'EyeColorEdit' or 
                    component_name == 'SkinTypeEdit' or
                    component_name == 'HasHighQualityHeadCB' or 
                    component_name == 'HairColorCB' or 
                    component_name == 'HeadTypeCodeCB' or 
                    component_name == 'SkinColorCB' or
                    component_name == 'HeadTypeGroupCB'
                ) then
                    -- Don't change headmodel
                elseif component_name == 'AgeEdit' then
                    if self.frm.FUTCopyAgeCB.State == 0 then 
                        -- clear
                        component.OnChange = nil

                        -- Update AgeEdit
                        if comp_desc['valGetter'] then
                            component.Text = comp_desc['valGetter'](
                                self.current_addrs,
                                comp_desc["db_field"]["table_name"],
                                comp_desc["db_field"]["field_name"],
                                comp_desc["db_field"]["raw_val"],
                                values[columns['birthdate']]
                            )
                        end

                        component.OnChange = org_comp_on_change
                    end
                elseif component_name == 'HeadTypeCodeCB' then
                    component.OnChange = nil
                    comp_desc['cbFiller'](component, tonumber(values[columns[value]]))
                    component.OnChange = org_comp_on_change
                elseif component_class == 'TCEEdit' then
                    if self.frm.FUTCopyAttribsCB.State == 1 and (
                        component.Parent.Parent.Name == 'AttributesPanel' or 
                        component.Name == 'OverallEdit' or
                        component.Name == 'PotentialEdit'
                    ) then
                        -- Don't copy attributes
                    elseif self.frm.FUTCopyNameCB.State == 1 and (
                        component.Name == 'FirstNameIDEdit' or
                        component.Name == 'LastNameIDEdit' or
                        component.Name == 'JerseyNameIDEdit' or
                        component.Name == 'CommonNameIDEdit'
                    ) then
                        -- Don't copy name IDs
                    else
                        -- clear
                        component.OnChange = nil

                        local new_comp_text = (
                            player['details']['stat_json'][value] or 
                            player['details'][comp_to_fut[key]] or 
                            player['details']['stat_json'][comp_to_fut[key]] or 
                            values[columns[value]]
                        )
                        
                        -- Composure has been added in FIFA 18
                        if (
                            component.Name == 'ComposureEdit' and
                            tonumber(new_comp_text) == 0
                        ) then
                            new_comp_text = tonumber(player['details']['ovr']) - 6
                        end

                        component.Text = tonumber(new_comp_text)
            
                        component.OnChange = org_comp_on_change
                    end
                elseif component_class == 'TCEComboBox' then
                    if self.frm.FUTCopyAttribsCB.State == 1 and (
                        component.Parent.Parent.Name == 'AttributesPanel'
                    ) then
                        -- Don't copy attributes
                    elseif self.frm.FUTCopyNationalityCB.State == 1 and (
                        component.Name == 'NationalityCB'
                    ) then
                        -- Don't copy Nationality
                    else
                        -- clear
                        component.OnChange = nil

                        local new_comp_val = nil
                        if value == 'preferredposition1' then
                            local pos_name_to_id = {
                                GK = 0,
                                SW = 1,
                                RWB = 2,
                                RB = 3,
                                RCB = 4,
                                CB = 5,
                                LCB = 6,
                                LB = 7,
                                LWB = 8,
                                RDM = 9,
                                CDM = 10,
                                LDM = 11,
                                RM = 12,
                                RCM = 13,
                                CM = 14,
                                LCM = 15,
                                LM = 16,
                                RAM = 17,
                                CAM = 18,
                                LAM = 19,
                                RF = 20,
                                CF = 21,
                                LF = 22,
                                RW = 23,
                                RS = 24,
                                ST = 25,
                                LS = 26,
                                LW = 27
                            }
                            new_comp_val = pos_name_to_id[player['position']]
                        else
                            new_comp_val = (
                                player['details']['stat_json'][value] or
                                player['details'][comp_to_fut[key]] or
                                player['details']['stat_json'][comp_to_fut[key]] or
                                values[columns[value]]
                            )
                        end
                        if comp_desc['db_field'] and comp_desc['db_field']['raw_val'] then
                            local tbl_nm = comp_desc['db_field']['table_name']
                            local fld_nm = comp_desc['db_field']['field_name']
                            local meta_idx = DB_TABLES_META_MAP[tbl_nm][fld_nm]
                            local fld_desc = DB_TABLES_META[tbl_nm][meta_idx]
                            new_comp_val = math.floor(tonumber(new_comp_val) - fld_desc["rangelow"])
                        end

                        comp_desc['cbFiller'](component, new_comp_val, comp_desc["cb_id"])
                        component.OnChange = org_comp_on_change
                    end
                end

                self.change_list[component_name] = 1
            end

            if self.frm.FUTCopyAttribsCB.State == 0 then
                -- Apply chem style:
                local chem_style_itm_index = self.frm.FUTChemStyleCB.ItemIndex
                local chem_styles = {
                    -- Basic
                    {
                        SprintSpeedEdit = 5,
                        AttackPositioningEdit = 5,
                        ShotPowerEdit = 5,
                        VolleysEdit = 5,
                        PenaltiesEdit = 5,
                        VisionEdit = 5,
                        ShortPassingEdit = 5,
                        LongPassingEdit = 5,
                        CurveEdit = 5,
                        AgilityEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 5,
                        MarkingEdit = 5,
                        StandingTackleEdit = 5,
                        SlidingTackleEdit = 5,
                        JumpingEdit = 5,
                        StrengthEdit = 5
                    },
                    -- GK Basic
                    {
                        GKDivingEdit = 10,
                        GKHandlingEdit = 10,
                        GKKickingEdit = 10,
                        GKReflexEdit = 10,
                        AccelerationEdit = 5,
                        GKPositioningEdit = 10
                    },
                    -- Sniper
                    {
                        AttackPositioningEdit = 10,
                        FinishingEdit = 15,
                        VolleysEdit = 10,
                        PenaltiesEdit = 15,
                        AgilityEdit = 5,
                        BalanceEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 15
                    },
                    -- Finisher
                    {
                        FinishingEdit = 5,
                        ShotPowerEdit = 15,
                        LongShotsEdit = 15,
                        VolleysEdit = 10,
                        PenaltiesEdit = 10,
                        JumpingEdit = 15,
                        StrengthEdit = 10,
                        AggressionEdit = 10
                    },
                    -- Deadeye
                    {
                        AttackPositioningEdit = 10,
                        FinishingEdit = 15,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 5,
                        PenaltiesEdit = 5,
                        VisionEdit = 5,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 15,
                        CurveEdit = 10
                    },
                    -- Marksman
                    {
                        AttackPositioningEdit = 10,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 10,
                        VolleysEdit = 10,
                        PenaltiesEdit = 5,
                        AgilityEdit = 5,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 5,
                        JumpingEdit = 10,
                        StrengthEdit = 5,
                        AggressionEdit = 5
                    },
                    -- Hawk
                    {
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        AttackPositioningEdit = 10,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 10,
                        VolleysEdit = 10,
                        PenaltiesEdit = 5,
                        JumpingEdit = 10,
                        StrengthEdit = 5,
                        AggressionEdit = 10
                    },
                    -- Artist
                    {
                        VisionEdit = 15,
                        CrossingEdit = 5,
                        LongPassingEdit = 15,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        AgilityEdit = 5,
                        BalanceEdit = 5,
                        ReactionsEdit = 10,
                        BallControlEdit = 5,
                        DribblingEdit = 15
                    },
                    -- Architect
                    {
                        VisionEdit = 10,
                        CrossingEdit = 15,
                        FreeKickAccuracyEdit = 5,
                        LongPassingEdit = 15,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        JumpingEdit = 5,
                        StrengthEdit = 15,
                        AggressionEdit = 10
                    },
                    -- Powerhouse
                    {
                        VisionEdit = 10,
                        CrossingEdit = 5,
                        LongPassingEdit = 10,
                        ShortPassingEdit = 15,
                        CurveEdit = 10,
                        InterceptionsEdit = 5,
                        MarkingEdit = 10,
                        StandingTackleEdit = 15,
                        SlidingTackleEdit = 10
                    },
                    -- Maestro
                    {
                        AttackPositioningEdit = 5,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 10,
                        VolleysEdit = 10,
                        VisionEdit = 5,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 10
                    },
                    -- Engine
                    {
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        VisionEdit = 5,
                        CrossingEdit = 5,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        AgilityEdit = 5,
                        BalanceEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 10
                    },
                    -- Sentinel
                    {
                        InterceptionsEdit = 5,
                        HeadingAccuracyEdit = 10,
                        MarkingEdit = 15,
                        StandingTackleEdit = 15,
                        SlidingTackleEdit = 10,
                        JumpingEdit = 5,
                        StrengthEdit = 15,
                        AggressionEdit = 10
                    },
                    -- Guardian
                    {
                        AgilityEdit = 5,
                        BalanceEdit = 10,
                        ReactionsEdit = 5,
                        BallControlEdit = 5,
                        DribblingEdit = 15,
                        InterceptionsEdit = 10,
                        HeadingAccuracyEdit = 5,
                        MarkingEdit = 15,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 10
                    },
                    -- Gladiator
                    {
                        AttackPositioningEdit = 15,
                        FinishingEdit = 5,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 5,
                        InterceptionsEdit = 10,
                        HeadingAccuracyEdit = 15,
                        MarkingEdit = 5,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 15
                    },
                    -- Backbone
                    {
                        VisionEdit = 5,
                        CrossingEdit = 5,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        CurveEdit = 5,
                        InterceptionsEdit = 5,
                        HeadingAccuracyEdit = 5,
                        MarkingEdit = 10,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 10,
                        JumpingEdit = 5,
                        StrengthEdit = 10,
                        AggressionEdit = 5
                    },
                    -- Anchor
                    {
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        InterceptionsEdit = 5,
                        HeadingAccuracyEdit = 10,
                        MarkingEdit = 10,
                        StandingTackleEdit = 10,
                        SlidingTackleEdit = 10,
                        JumpingEdit = 10,
                        StrengthEdit = 10,
                        AggressionEdit = 10
                    },
                    -- Hunter
                    {
                        AccelerationEdit = 15,
                        SprintSpeedEdit = 10,
                        AttackPositioningEdit = 15,
                        FinishingEdit = 10,
                        ShotPowerEdit = 10,
                        LongShotsEdit = 5,
                        VolleysEdit = 10,
                        PenaltiesEdit = 15
                    },
                    -- Catalyst
                    {
                        AccelerationEdit = 15,
                        SprintSpeedEdit = 10,
                        VisionEdit = 15,
                        CrossingEdit = 10,
                        FreeKickAccuracyEdit = 10,
                        LongPassingEdit = 5,
                        ShortPassingEdit = 10,
                        CurveEdit = 15
                    },
                    -- Shadow
                    {
                        AccelerationEdit = 15,
                        SprintSpeedEdit = 10,
                        InterceptionsEdit = 10,
                        HeadingAccuracyEdit = 10,
                        MarkingEdit = 15,
                        StandingTackleEdit = 15,
                        SlidingTackleEdit = 15
                    },
                    -- Wall
                    {
                        GKDivingEdit = 15,
                        GKHandlingEdit = 15,
                        GKKickingEdit = 15
                    },
                    -- Shield
                    {
                        GKKickingEdit = 15,
                        GKReflexEdit = 15,
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5
                    },
                    -- Cat
                    {
                        GKReflexEdit = 15,
                        AccelerationEdit = 10,
                        SprintSpeedEdit = 5,
                        GKPositioningEdit = 15
                    },
                    -- Glove
                    {
                        GKDivingEdit = 15,
                        GKHandlingEdit = 15,
                        GKPositioningEdit = 15
                    },
                }

                if chem_styles[chem_style_itm_index] then
                    for component_name, modif in pairs(chem_styles[chem_style_itm_index]) do
                        local component = self.frm[component_name]
                        -- tmp disable onchange event
                        local onchange_event = component.OnChange
                        component.OnChange = nil

                        local new_attr_val = tonumber(component.Text) + modif
                        if new_attr_val > 99 then
                            new_attr_val = 99 
                        elseif new_attr_val <= 0 then
                            new_attr_val = 1
                        end

                        component.Text = new_attr_val
                        
                        component.OnChange = onchange_event
                        self.change_list[component_name] = 1
                    end
                end

                local trackbars = {
                    'AttackTrackBar',
                    'DefendingTrackBar',
                    'SkillTrackBar',
                    'GoalkeeperTrackBar',
                    'PowerTrackBar',
                    'MovementTrackBar',
                    'MentalityTrackBar',
                }
                for i=1, #trackbars do
                    self:update_trackbar(self.frm[trackbars[i]])
                end
                
                -- Adjust Potential
                if self.frm.FUTAdjustPotCB.State == 1 then
                    if tonumber(self.frm.OverallEdit.Text) > tonumber(self.frm.PotentialEdit.Text) then
                        self.frm.PotentialEdit.Text = self.frm.OverallEdit.Text
                    end
                    self.change_list["PotentialEdit"] = 1
                end

                -- Fix preferred positions
                local pos_arr = {self.frm.PreferredPosition1CB.ItemIndex+1}
                for i=2, 4 do
                    if pos_arr[1] ~= self.frm[string.format('PreferredPosition%dCB', i)].ItemIndex then
                        table.insert(pos_arr, self.frm[string.format('PreferredPosition%dCB', i)].ItemIndex)
                    end
                end
                for i=2, 4 do
                    self.frm[string.format('PreferredPosition%dCB', i)].ItemIndex = pos_arr[i] or 0
                end

                -- Recalc OVR for best at
                self.change_list["OverallEdit"] = 1
                self:recalculate_ovr(false)
            end
            -- DONE
            self.has_unsaved_changes = true
            ShowMessage('Data from FUT has been copied to GUI.\nTo see the changes in game you need to "Apply Changes"')
            return true
        elseif f_playerid > playerid then
            -- Not found
            self.logger:critical('COPY ERROR\n Player not Found: ' .. playerid)
            return false
        end
        ::continue::
    end
end

function thisFormManager:onFUTCopyPlayerBtnBtnClick(sender)
    if not self.fut_found_players then return end
    local selected = self.frm.FUTPickPlayerListBox.ItemIndex + 1
    local player = self.fut_found_players[selected]

    if not player then
        local eemsg = "Select player card first."
        self.logger:warning(eemsg)
        showMessage(eemsg)
        return
    end

    if player['details'] == nil then
        local fut_fifa = FIFA - self.frm.FutFIFACB.ItemIndex
        player['details'] = self:fut_get_player_details(player['id'], fut_fifa)
        self.fut_found_players[selected]['details'] = player
    end

    
    self:fut_copy_card_to_gui(player)
    self.logger:info("fut_copy_card_to_gui finished")
end

function thisFormManager:onCMCopyPlayerBtnClick(sender)
    self.logger:info("onCMCopyPlayerBtnClick")
    if not self.cm_found_player_addr or self.cm_found_player_addr <= 0 then
        self.logger:info("No player found")
        self.frm.CopyCMFindPlayerByID.Text = ''
        self.frm.CopyCMImage.Visible = false
        return
    end

    local copy_comp_list = {
        FirstNameIDEdit = true,
        LastNameIDEdit = true,
        JerseyNameIDEdit = true,
        CommonNameIDEdit = true,
        HairColorCB = true,
        FacialHairTypeEdit = true,
        CurveEdit = true,
        JerseyStyleEdit = true,
        AgilityEdit = true,
        AccessoryEdit4 = true,
        GKSaveTypeEdit = true,
        AttackPositioningEdit = true,
        HairTypeEdit = true,
        StandingTackleEdit = true,
        PreferredPosition3CB = true,
        LongPassingEdit = true,
        PenaltiesEdit = true,
        AnimFreeKickStartPosEdit = true,
        AnimPenaltiesKickStyleEdit = true,
        IsRetiringCB = true,
        LongShotsEdit = true,
        GKDivingEdit = true,
        InterceptionsEdit = true,
        shoecolorEdit2 = true,
        CrossingEdit = true,
        PotentialEdit = true,
        GKReflexEdit = true,
        FinishingCodeEdit1 = true,
        ReactionsEdit = true,
        ComposureEdit = true,
        VisionEdit = true,
        AnimPenaltiesApproachEdit = true,
        FinishingEdit = true,
        DribblingEdit = true,
        SlidingTackleEdit = true,
        AccessoryEdit3 = true,
        AccessoryColourEdit1 = true,
        HeadTypeCodeCB = true,
        SprintSpeedEdit = true,
        HeightEdit = true,
        hasseasonaljerseyEdit = true,
        PreferredPosition2CB = true,
        StrengthEdit = true,
        shoetypeEdit = true,
        AgeEdit = true,
        PreferredPosition1CB = true,
        BallControlEdit = true,
        ShotPowerEdit = true,
        socklengthEdit = true,
        WeightEdit = true,
        HasHighQualityHeadCB = true,
        GKGloveTypeEdit = true,
        BalanceEdit = true,
        HeadAssetIDEdit = true,
        GKKickingEdit = true,
        InternationalReputationCB = true,
        AnimPenaltiesMotionStyleEdit = true,
        ShortPassingEdit = true,
        FreeKickAccuracyEdit = true,
        SkillMovesCB = true,
        FacePoserPresetEdit = true,
        AttackingWorkRateCB = true,
        FinishingCodeEdit2 = true,
        AggressionEdit = true,
        AccelerationEdit = true,
        HeadingAccuracyEdit = true,
        EyebrowEdit = true,
        runningcodeEdit2 = true,
        ModifierEdit = true,
        GKHandlingEdit = true,
        EyeColorEdit = true,
        jerseysleevelengthEdit = true,
        AccessoryColourEdit3 = true,
        AccessoryEdit1 = true,
        HeadClassCodeEdit = true,
        DefensiveWorkRateCB = true,
        NationalityCB = true,
        PreferredFootCB = true,
        SideburnsEdit = true,
        WeakFootCB = true,
        JumpingEdit = true,
        SkinTypeEdit = true,
        GKKickStyleEdit = true,
        StaminaEdit = true,
        MarkingEdit = true,
        AccessoryColourEdit4 = true,
        GKPositioningEdit = true,
        HeadVariationEdit = true,
        SkillMoveslikelihoodEdit = true,
        SkinColorCB = true,
        shortstyleEdit = true,
        OverallEdit = true,
        EmotionEdit = true,
        JerseyFitEdit = true,
        AccessoryEdit2 = true,
        shoedesignEdit = true,
        shoecolorEdit1 = true,
        HairStyleEdit = true,
        BodyTypeCB = true,
        AnimPenaltiesStartPosEdit = true,
        runningcodeEdit1 = true,
        PreferredPosition4CB = true,
        VolleysEdit = true,
        AccessoryColourEdit2 = true,
        FacialHairColorEdit = true,
        LongThrowInCB = true,
        PowerFreeKickCB = true,
        InjuryProneCB = true,
        SolidPlayerCB = true,
        DivesIntoTacklesCB = true,
        LeadershipCB = true,
        EarlyCrosserCB = true,
        FinesseShotCB = true,
        FlairCB = true,
        LongPasserCB = true,
        LongShotTakerCB = true,
        SpeedDribblerCB = true,
        PlaymakerCB = true,
        GKLongthrowCB = true,
        PowerheaderCB = true,
        GiantthrowinCB = true,
        OutsitefootshotCB = true,
        SwervePassCB = true,
        SecondWindCB = true,
        FlairPassesCB = true,
        BicycleKicksCB = true,
        GKFlatKickCB = true,
        OneClubPlayerCB = true,
        TeamPlayerCB = true,
        ChipShotCB = true,
        TechnicalDribblerCB = true,
        RushesOutOfGoalCB = true,
        CautiousWithCrossesCB = true,
        ComesForCrossessCB = true,
        SaveswithFeetCB = true,
        SetPlaySpecialistCB = true
    }

    if self.frm.CMCopyAgeCB.State == 1 then
        copy_comp_list["AgeEdit"] = false
    end

    if self.frm.CMCopyNameCB.State == 1 then
        copy_comp_list["FirstNameIDEdit"] = false
        copy_comp_list["LastNameIDEdit"] = false
        copy_comp_list["JerseyNameIDEdit"] = false
        copy_comp_list["CommonNameIDEdit"] = false
    end

    if self.frm.CMCopyHeadModelCB.State == 1 then
        copy_comp_list["HeadClassCodeEdit"] = false
        copy_comp_list["HeadAssetIDEdit"] = false
        copy_comp_list["HeadVariationEdit"] = false
        copy_comp_list["HairTypeEdit"] = false
        copy_comp_list["HairStyleEdit"] = false
        copy_comp_list["FacialHairTypeEdit"] = false
        copy_comp_list["FacialHairColorEdit"] = false
        copy_comp_list["SideburnsEdit"] = false
        copy_comp_list["EyebrowEdit"] = false
        copy_comp_list["EyeColorEdit"] = false
        copy_comp_list["SkinTypeEdit"] = false
        copy_comp_list["HasHighQualityHeadCB"] = false
        copy_comp_list["HairColorCB"] = false
        copy_comp_list["HeadTypeCodeCB"] = false
        copy_comp_list["SkinColorCB"] = false
        copy_comp_list["HeadTypeGroupCB"] = false
    end
    
    local addrs = {
        players = self.cm_found_player_addr,
        career_calendar = readPointer("pCareerCalendarTableCurrentRecord"),
        career_users = readPointer("pUsersTableFirstRecord")
    }
    self.logger:debug(string.format("%X", addrs["players"]))
    local comps_desc = self:get_components_description()
    for key, value in pairs(copy_comp_list) do
        if value == true then
            local component = self.frm[key]
            local component_name = component.Name
            local comp_desc = comps_desc[component_name]
            local component_class = component.ClassName
            local org_comp_on_change = component.OnChange
            --self.logger:debug(component_name)
            component.OnChange = nil
            if component_class == 'TCEEdit' then
                if comp_desc["valGetter"] then
                    component.Text = comp_desc["valGetter"](
                        addrs,
                        comp_desc["db_field"]["table_name"],
                        comp_desc["db_field"]["field_name"],
                        comp_desc["db_field"]["raw_val"]
                    )
                end
            elseif component_class == 'TCEComboBox' then
                if comp_desc["valGetter"] and comp_desc["cbFiller"] then
                    local current_field_val = comp_desc["valGetter"](
                        addrs,
                        comp_desc["db_field"]["table_name"],
                        comp_desc["db_field"]["field_name"],
                        comp_desc["db_field"]["raw_val"]
                    )
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
            self.change_list[component_name] = 1
            component.OnChange = org_comp_on_change
        end
    end
    self.has_unsaved_changes = true
    ShowMessage('Player data has been copied to GUI.\nTo see the changes in game you need to "Apply Changes"')
    self.logger:info("CM Copy Done")
end

function thisFormManager:assign_current_form_events()
    self:assign_events()

    local fnTabClick = function(sender)
        self:TabClick(sender)
    end

    local fnTabMouseEnter= function(sender)
        self:TabMouseEnter(sender)
    end

    local fnTabMouseLeave = function(sender)
        self:TabMouseLeave(sender)
    end

    self.frm.OnShow = function(sender)
        self:onShow(sender)
    end

    -- self.frm.FindPlayerByID.OnClick = function(sender)
    --     sender.Text = ''
    -- end
    -- self.frm.SearchPlayerByID.OnClick = function(sender)
    --     local playerid = tonumber(self.frm.FindPlayerByID.Text)
    --     if playerid == nil then return end

    --     self:check_if_has_unsaved_changes()

    --     local player_found_addr = self:find_player_by_id(playerid)
    --     if player_found_addr and player_found_addr > 0 then
    --         self:find_player_club_team_record(playerid)
    --         self.frm.FindPlayerByID.Text = playerid
    --         self:recalculate_ovr()
    --         self:onShow()
    --     else 
    --         self.logger:error(string.format("Not found any player with ID: %d.", playerid))
    --     end
    -- end

    self.frm.FindPlayerBtn.OnClick = function(sender)
        FindPlayerForm.show()
    end

    self.frm.FindPlayerBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.FindPlayerBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.FindPlayerBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.PlayerEditorSettings.OnClick = function(sender)
        SettingsForm.show()
    end

    self.frm.SyncImage.OnClick = function(sender)
        if not self.current_addrs["players"] then return end
        self:check_if_has_unsaved_changes()

        --local addr = readPointer("pPlayersTableCurrentRecord")
        --if self.current_addrs["players"] == addr then return end

        self:onShow()
    end

    self.frm.RandomAttackAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "CrossingEdit", "FinishingEdit", "HeadingAccuracyEdit",
            "ShortPassingEdit", "VolleysEdit"
        })
    end
    self.frm.RandomDefendingAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "MarkingEdit", "StandingTackleEdit", "SlidingTackleEdit",
        })
    end
    self.frm.RandomSkillAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "DribblingEdit", "CurveEdit", "FreeKickAccuracyEdit",
            "LongPassingEdit", "BallControlEdit",
        })
    end
    self.frm.RandomGKAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "GKDivingEdit", "GKHandlingEdit", "GKKickingEdit",
            "GKPositioningEdit", "GKReflexEdit",
        })
    end
    self.frm.RandomPowerAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "ShotPowerEdit", "JumpingEdit", "StaminaEdit",
            "StrengthEdit", "LongShotsEdit",
        })
    end
    self.frm.RandomMovementAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "AccelerationEdit", "SprintSpeedEdit", "AgilityEdit",
            "ReactionsEdit", "BalanceEdit",
        })
    end
    self.frm.RandomMentalityAttr.OnClick = function(sender)
        self:roll_random_attributes({
            "AggressionEdit", "ComposureEdit", "InterceptionsEdit",
            "AttackPositioningEdit", "VisionEdit", "PenaltiesEdit",
        })
    end
    
    self.frm.PlayerInfoTab.OnClick = fnTabClick
    self.frm.PlayerInfoTab.OnMouseEnter = fnTabMouseEnter
    self.frm.PlayerInfoTab.OnMouseLeave = fnTabMouseLeave

    self.frm.AttributesTab.OnClick = fnTabClick
    self.frm.AttributesTab.OnMouseEnter = fnTabMouseEnter
    self.frm.AttributesTab.OnMouseLeave = fnTabMouseLeave

    self.frm.TraitsTab.OnClick = fnTabClick
    self.frm.TraitsTab.OnMouseEnter = fnTabMouseEnter
    self.frm.TraitsTab.OnMouseLeave = fnTabMouseLeave

    self.frm.AppearanceTab.OnClick = fnTabClick
    self.frm.AppearanceTab.OnMouseEnter = fnTabMouseEnter
    self.frm.AppearanceTab.OnMouseLeave = fnTabMouseLeave

    self.frm.AccessoriesTab.OnClick = fnTabClick
    self.frm.AccessoriesTab.OnMouseEnter = fnTabMouseEnter
    self.frm.AccessoriesTab.OnMouseLeave = fnTabMouseLeave

    self.frm.OtherTab.OnClick = fnTabClick
    self.frm.OtherTab.OnMouseEnter = fnTabMouseEnter
    self.frm.OtherTab.OnMouseLeave = fnTabMouseLeave

    self.frm.PlayerCloneTab.OnClick = fnTabClick
    self.frm.PlayerCloneTab.OnMouseEnter = fnTabMouseEnter
    self.frm.PlayerCloneTab.OnMouseLeave = fnTabMouseLeave

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

    -- FUT CLONE
    self.frm.CloneFromListBox.OnSelectionChange = function(sender, user)
        local Panels = {
            'CloneFromFUTPanel',
            'CloneFromCMPanel',
        }
        for i=1, #Panels do
            if sender.ItemIndex == i-1 then
                self.frm[Panels[i]].Visible = true
            else
                self.frm[Panels[i]].Visible = false
            end
        end
    end

    self.frm.FUTCopyPlayerBtn.OnClick = function(sender)
        self:onFUTCopyPlayerBtnBtnClick(sender)
    end

    self.frm.FUTCopyPlayerBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.FUTCopyPlayerBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.FUTCopyPlayerBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

    self.frm.FUTChemStyleCB.OnChange = function(sender)
        if sender.ItemIndex >= 0 then
            sender.Hint = sender.Items[sender.ItemIndex]
        else
            sender.Hint = "ERROR"
        end

        -- Labels on card
        local selected = self.frm.FUTPickPlayerListBox.ItemIndex + 1
        local player = self.fut_found_players[selected]
        if not player then return end
        if not player['details'] then return end
    
        self:fut_fill_attributes(player['details'])
    end

    self.frm.FindPlayerByNameFUTEdit.OnClick = function(sender)
        sender.Text = ''
    end

    self.frm.SearchPlayerByNameFUTBtn.OnClick = function(sender)
        self.frm.CardContainerPanel.Visible = false
        self.frm.FUTPickPlayerListBox.clear()
        if self.frm.FindPlayerByNameFUTEdit.Text == '' then return end
        if self.frm.FindPlayerByNameFUTEdit.Text == 'Enter player name you want to find' then return end
        self:fut_search_player(self.frm.FindPlayerByNameFUTEdit.Text, 1)
    end

    self.frm.FutFIFACB.OnChange = function(sender)
        self.frm.CardContainerPanel.Visible = false
        self.frm.FUTPickPlayerListBox.clear()
        if self.frm.FindPlayerByNameFUTEdit.Text == '' then return end
        if self.frm.FindPlayerByNameFUTEdit.Text == 'Enter player name you want to find' then return end
        self:fut_search_player(self.frm.FindPlayerByNameFUTEdit.Text, 1)
    end

    self.frm.FUTPickPlayerListBox.OnSelectionChange = function(sender, user)
        local selected = self.frm.FUTPickPlayerListBox.ItemIndex + 1
        if not self.fut_found_players then return end
    
        local player = self.fut_found_players[selected]
        if not player then return end
        -- Create CARD in GUI
        self:fut_create_card(player, selected)
    
        if not self.frm.CardContainerPanel.Visible then
            self.frm.CardContainerPanel.Visible = true
        end
    end

    self.frm.PrevPage.OnClick = function(sender)
        if FUT_API_PAGE == 1 then return end
    
        FUT_API_PAGE = FUT_API_PAGE - 1
        if FUT_API_PAGE < 1 then
            FUT_API_PAGE = 1
        end
        self.frm.FUTPickPlayerListBox.clear()
        self:fut_search_player(self.frm.FindPlayerByNameFUTEdit.Text, FUT_API_PAGE)
    end
    self.frm.NextPage.OnClick = function(sender)
        FUT_API_PAGE = FUT_API_PAGE + 1
        self.frm.FUTPickPlayerListBox.clear()
        self:fut_search_player(self.frm.FindPlayerByNameFUTEdit.Text, FUT_API_PAGE)
    end

    self.frm.CopyCMFindPlayerByID.OnClick = function(sender)
        self.cm_found_player_addr = 0
        self.frm.CopyCMImage.Visible = false
        sender.Text = ''
    end

    self.frm.CopyCMSearchPlayerByID.OnClick = function(sender)
        self.cm_found_player_addr = 0
        local playerid = tonumber(self.frm.CopyCMFindPlayerByID.Text)
        if playerid == nil then 
            self.frm.CopyCMImage.Visible = false
            return 
        end
        self.cm_found_player_addr = self:find_player_by_id(playerid)
        if not self.cm_found_player_addr or self.cm_found_player_addr <= 0 then
            self.cm_found_player_addr = 0
            self.frm.CopyCMImage.Visible = false
            return
        end
        local ss_hs = self:load_headshot(
            playerid, self.cm_found_player_addr
        )
        if self:safe_load_picture_from_ss(self.frm.CopyCMImage.Picture, ss_hs) then
            ss_hs.destroy()
            self.frm.CopyCMImage.Picture.stretch=true
            self.frm.CopyCMImage.Visible = true
        end
    end


    self.frm.CopyCMPlayerBtn.OnClick = function(sender)
        self:onCMCopyPlayerBtnClick(sender)
    end

    self.frm.CopyCMPlayerBtn.OnMouseEnter = function(sender)
        self:onBtnMouseEnter(sender)
    end

    self.frm.CopyCMPlayerBtn.OnMouseLeave = function(sender)
        self:onBtnMouseLeave(sender)
    end

    self.frm.CopyCMPlayerBtn.OnPaint = function(sender)
        self:onPaintButton(sender)
    end

end

function thisFormManager:setup(params)
    self.logger = params.logger
    self.frm = params.frm_obj
    self.name = params.name

    self.logger:info(string.format("Setup Form Manager: %s", self.name))

    self.tab_panel_map = {
        PlayerInfoTab = "PlayerInfoPanel",
        AttributesTab = "AttributesPanel",
        TraitsTab = "TraitsPanel",
        AppearanceTab = "AppearancePanel",
        AccessoriesTab = "AccessoriesPanel",
        OtherTab = "OtherPanel",
        PlayerCloneTab = "PlayerClonePanel"
    }
    self.frm.FindPlayerByID.Text = 'Find player by ID...'
    self.change_list = {}
    self.fut_found_players = nil
    self.cm_found_player_addr = 0
    self:assign_current_form_events()
end


return thisFormManager;