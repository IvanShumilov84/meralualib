-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."
local lib_conf = require(lib_path .. "__conf")
local module_utils = require(lib_path .. "module_utils")
local version = require(lib_path .. "alarm_manager.version")


local lib_category_name = lib_conf.lib_category_name
local lib_logs = lib_conf.use_logs
local module_name = "alarm_manager"
local utils_dir = "utils"  -- По умолчанию загружаем последнюю стабильную версию.
local main_file = "main"
local module_path = lib_path .. module_name .. "." .. utils_dir .. "." .. main_file

if lib_logs then
    local caller_path = module_utils.get_module_info(4).absolute_path
    local msg = "Из скрипта '" .. caller_path .. "' загружен модуль '" .. module_path .. "' версии " .. version.get_version_string(".") .. "."
    luacpLogMessage(lib_category_name, msg, 1)
end

return require(module_path)
