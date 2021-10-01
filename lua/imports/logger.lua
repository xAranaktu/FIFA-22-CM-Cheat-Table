-- Logger for Cheat Engine
-- @author - Aranaktu

-- log to file or console

local Logger = {
    time = os.date("*t"),
    is_debug_mode = false,
    print_text = false,
    min_level = 2
};

function Logger:new(o, time, fdir, fname, print_text, min_level)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.time = time or os.date("*t");
    self.fdir = fdir or "logs"
    self.fname = fname or ("log_" .. string.format("%02d-%02d-%02d", self.time.year, self.time.month, self.time.day) .. ".txt")
    self.fpath = string.format("%s/%s", self.fdir, self.fname)
    self.print_text = print_text or false
    self.min_level = min_level or 1

    self.levels = {
        "DEBUG",
        "INFO",
        "WARNING",
        "ERROR",
        "CRITICAL",
    }

    return o;
end

function Logger:get_level_text(level)
    if ((level <= 0) or (level > #self.levels)) then
        return "UNSET"
    end

    return self.levels[level]
end

function Logger:_write(level, text, show_message)
    local to_log = string.format("[ %s ] %s - %s\n", self:get_level_text(level), os.date("%c", os.time()), text)
    if (not DEBUG_MODE) then
        fo, err = io.open(self.fpath, "a+")
        if fo == nil then
            DEBUG_MODE = true;
            self.print_text = true;

            print(io.popen"cd":read'*l')
            print(string.format("[ %s ] %s - %s", self:get_level_text(level), os.date("%c", os.time()), 'Error opening file: ' .. err))
        else
            fo:write(to_log)
            io.close(fo)
        end
    end

    if (self.print_text or DEBUG_MODE) then
        print(to_log)
    end 

    if (show_message) then
        showMessage(text)
    end
end

function Logger:debug(text, show_message)
    local level = 1;
    if DEBUG_MODE then
        self:_write(level, text, show_message);
    end
end

function Logger:info(text, show_message)
    local level = 2;
    if level >= self.min_level then
        self:_write(level, text, show_message);
    end
end

function Logger:warning(text, show_message)
    local level = 3;
    if level >= self.min_level then
        self:_write(level, text, show_message);
    end
end

function Logger:error(text, show_message)
    local level = 4;
    if level >= self.min_level then
        self:_write(level, text, show_message);
    end
end

function Logger:critical(text)
    local level = 5;
    if level >= self.min_level then
        self:_write(level, text, true);
    end
end

return Logger;