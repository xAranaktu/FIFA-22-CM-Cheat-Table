local TableManager = require 'lua/imports/CheatTableManager';

-- assigned in TableManager:start()
DEBUG_MODE = false 

gCTManager = TableManager:new()
gCTManager:initialize()
gCTManager:start()