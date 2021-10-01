require 'lua/consts';
require 'lua/helpers';

local MemoryManager = {}

function MemoryManager:new(o, logger, fnSaveOffsets)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.logger = logger
    self.fnSaveOffsets = fnSaveOffsets

    self.proc_name = nil
    self.base_address = 0
    self.module_size = 0

    self.offsets = {}

    return o;
end

function MemoryManager:save_offsets()
    self.fnSaveOffsets(self.offsets)
end

function MemoryManager:set_proc(new_proc_name)
    self.proc_name = new_proc_name

    self.base_address = getAddress(self.proc_name)
    self.module_size = getModuleSize(self.proc_name)
end

function MemoryManager:set_offsets(new_offsets)
    if new_offsets.offsets then
        self.offsets = new_offsets.offsets
    else
        self.offsets = new_offsets
    end
end

function MemoryManager:getAddressModule(module_name)
    local modules = enumModules()
    for _, module in ipairs(modules) do
        if module.Name == module_name then
            return module.Address
        end
    end
    return nil
end

function MemoryManager:check_process()
    -- Check if we are still attached

    if self.proc_name == nil then
        local critical_error = "Check process has failed. MemoryManager.proc_name is nil. Did you allowed CE to execute lua script at starup?"
        self.logger:critical(critical_error)
        assert(false, critical_error)
    end

    local pid = getProcessIDFromProcessName(self.proc_name)

    if pid == nil or pid ~= getOpenedProcessID() then
        local critical_error = "Invalid PID. Restart FIFA and Cheat Engine is required"
        self.logger:critical(critical_error)
        assert(false, critical_error)
    else
        return true
    end
end

function MemoryManager:AOBScanModule(aob, module_name, module_size)
    if aob == nil then
        local critical_error = "Update not properly installed. Remove all versions of the cheat table you have and download the latest one again"
        self.logger:critical(critical_error)
        assert(false, critical_error)
    end

    local memscan = createMemScan()
    local foundlist = createFoundList(memscan)

    local start = nil
    local stop = nil
    if module_name == nil then
        module_name = self.proc_name
        module_size = self.module_size
        start = self:getAddressModule(module_name)
        if start == nil then
            start = self.base_address
        end
    else
        module_size = getModuleSize(module_name)
        if module_size == nil then
            local module_sizes = {
                FootballCompEng_Win64_retail = 0xCE000
            }
            local mname = string.gsub(module_name, '.dll', '')
            module_size = module_sizes[mname]
        end
        start = self:getAddressModule(module_name)
    end

    if module_size ~= nil then
        self.logger:info(string.format("Module_size %s, %X", module_name, module_size))
        stop = start + module_size
        self.logger:info(string.format('%X - %X', start, stop))
    else
        stop = 0x7fffffffffff - start
        self.logger:info(
            string.format(
                'Module_size %s is nil. new stop: %X',
                module_name, stop
            )
        )
    end

    memscan.firstScan(
      soExactValue, vtByteArray, rtRounded, 
      aob, nil, start, stop, "*X*W", 
      fsmNotAligned, "1", true, false, false, false
    )
    memscan.waitTillDone()
    foundlist.initialize()
    memscan.Destroy()

    return foundlist
end

function MemoryManager:read_multilevel_pointer(base_addr, offsets)
    for i=1, #offsets do
        --self.logger:debug(string.format("read_multilevel_pointer %X", base_addr))
        if base_addr == 0 or base_addr == nil then
            --self.logger:warning(string.format("Invalid PTR: offset: %d", i))
            --self.logger:warning("All offsets")
            --for j=1, #offsets do
            --    self.logger:warning(string.format("%X", offsets[j]))
            --end
            return 0
        end
        --self.logger:debug(string.format("readPointer 0x%X + 0x%X", base_addr, offsets[i]))
        base_addr = readPointer(base_addr+offsets[i])
    end
    return base_addr
end

function MemoryManager:get_offset(base_addr, addr)
    return string.format('%X',tonumber(addr, 16) - base_addr)
end

function MemoryManager:get_address_with_offset(base_addr, offset)
    if offset == nil then return "0" end
    -- Offset saved in file may contains only numbers. We want to have string
    if type(offset) == 'number' then
        offset = tostring(offset)
    end
    return string.format('%X',tonumber(offset, 16) + base_addr)
end

function MemoryManager:update_offset(name, save, module_name, module_size, section)
    local res_offset = nil
    local valid_i = {}
    local base_addr = self.base_address

    if module_name then
        name = string.format('%s.AOBS.%s', section, name)
        base_addr = getAddress(module_name)
    end
    
    self.logger:info(string.format("AOBScanModule, pattern for %s", name))

    local pat = getfield(string.format('AOB_PATTERNS.%s', name))
    if not pat then
        self.logger:error(string.format("No AOB for %s", name))
    end
    self.logger:info(pat)
    local res = self:AOBScanModule(
        pat,
        module_name,
        module_size
    )
    local res_count = res.getCount()
    if res_count == 0 then 
        self.logger:error(string.format("%s AOBScanModule error. Pattern not found. Try to restart FIFA and Cheat Engine", name))
        return false
    elseif res_count > 1 then
        self.logger:warning(string.format("%s AOBScanModule multiple matches - %i found", name, res_count))
        for i=0, res_count-1, 1 do
            res_offset = tonumber(res[i], 16)
            self.logger:warning(string.format("offset %i - %X", i+1, res_offset))
            valid_i[#valid_i+1] = i
        end
        if #valid_i >= 1 then
            self.logger:warning(string.format("picking offset at index - %i", valid_i[1]))
            self.offsets[name] = self:get_offset(base_addr, res[valid_i[1]])
        else
            self.logger:error(string.format("%s AOBScanModule error", name))
            return false
        end
    else
        self.offsets[name] = self:get_offset(base_addr, res[0])
        self.logger:info(string.format("New Offset for %s - 0x%s", name, self.offsets[name]))
    end
    res.destroy()
    if save then self:save_offsets() end
    return true
end

function MemoryManager:verify_offset(name)
    self.logger:info(string.format("Veryfing %s offset", name))

    local aob = getfield(string.format('AOB_PATTERNS.%s', name))
    if aob == nil then 
        return false
    end
    local nospace_aob = string.gsub(aob, "%s+", "")
    local aob_len = math.floor(string.len(nospace_aob)/2)
    local addres_to_check = self:get_address_with_offset(
        self.base_address, self.offsets[name]
    )
    
    self.logger:info(string.format("addres_to_check %s, aob: %s", addres_to_check, aob))
    
    local temp_bytes = readBytes(addres_to_check, aob_len, true)
    local bytes_to_verify = {}
    -- convert to hex
    for i =1,aob_len do
        bytes_to_verify[i] = string.format('%02X', temp_bytes[i])
    end

    local index = 1
    for b in string.gmatch(aob, "%S+") do
        if b == "??" then
            -- Ignore wildcards
        elseif b ~= bytes_to_verify[index] then
            self.logger:warning(string.format("Veryfing %s offset failed", name))
            self.logger:warning(string.format("Bytes in memory: %s != %s: %s", table.concat(bytes_to_verify, ' '), name, aob))
            if bytes_to_verify[1] == 'E9' then
                self.logger:critical('jmp already set. This happen when you close and reopen Cheat Table without deactivating scripts. Now, restart FIFA and Cheat Engine to fix this problem')
            end
            return false
        end
        index = index + 1
    end
    self.logger:info(string.format("Veryfing %s offset success", name))
    return addres_to_check
end

function MemoryManager:resolve_pointer(addr, start, fix)
    if fix == nil then fix = 0 end

    if type(addr) ~= "number" then
        addr = tonumber(addr, 16)
    end

    local result = byteTableToDword(readBytes(addr+start, 4, true)) + addr + start + 4 + fix

    return result
end

function MemoryManager:get_validated_address(name, module_name, section)
    local validated_address = nil
    if name == nil then return nil end

    self:check_process()
    if module_name then
        name = string.format('%s.AOBS.%s', section, name)
        
        local res = self:AOBScanModule(
            getfield(string.format('AOB_PATTERNS.%s', name)),
            module_name
        )
        local res_count = res.getCount()
        if res_count == 0 then 
            self.logger:error(string.format("%s AOBScanModule error. Try to restart FIFA and Cheat Engine", name))
            return '00000000'
        elseif res_count > 1 then
            self.logger:warning(string.format("%s AOBScanModule multiple matches - %i found", name, res_count))
        end
        self.logger:info(string.format('AOB FROM MODULE: %s -> %s', name, res[0]))

        return res[0]
    end

    if self.offsets[name] ~= nil then
        validated_address = self:verify_offset(name)
    end
    
    if not validated_address then
        if not self:update_offset(name, true) then assert(false, string.format('Could not find valid offset for: %s', name)) end
        validated_address = self:get_address_with_offset(
            self.base_address, self.offsets[name]
        )
    end
    
    return validated_address
end

function MemoryManager:get_validated_resolved_ptr(name, start, module_name, section)
    local addr = self:get_validated_address(name, module_name, section)
    local ptr = self:resolve_pointer(addr, start)

    return ptr
end

return MemoryManager;