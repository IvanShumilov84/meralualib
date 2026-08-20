--[[
    Модуль инициализации.
]]


--#region Импорт модулей.
local datatype = require("meralualib.src.datatype")
local module_utils = require("meralualib.src.module_utils")
local tags = require("meralualib.src.tags")
local timers = require("meralualib.src.timers")
--#endregion Импорт модулей.


--#region Переменные.
local pth = module_utils.get_module_info().dir_path  -- Абсолютный путь до текущего скрипта.
local ton_init = timers["Ton"]:new()
local test_tag_names = {  -- Тестовые каналы имитации тревог.
    -- Скрипт 1 Таблица 1.
    -- каналы тревог с квитированием rep_ack.
    "am_script_01_table_01_error_rep_ack_01",
    "am_script_01_table_01_error_rep_ack_02",
    "am_script_01_table_01_warn_rep_ack_01",
    "am_script_01_table_01_warn_rep_ack_02",
    "am_script_01_table_01_info_rep_ack_01",
    "am_script_01_table_01_info_rep_ack_02",
    -- каналы тревог без квитирования rep.
    "am_script_01_table_01_error_rep_01",
    "am_script_01_table_01_error_rep_02",
    "am_script_01_table_01_warn_rep_01",
    "am_script_01_table_01_warn_rep_02",
    "am_script_01_table_01_info_rep_01",
    "am_script_01_table_01_info_rep_02",

    -- Скрипт 1 Таблица 2.
    -- каналы тревог с квитированием rep_ack.
    "am_script_01_table_02_error_rep_ack_01",
    "am_script_01_table_02_error_rep_ack_02",
    "am_script_01_table_02_warn_rep_ack_01",
    "am_script_01_table_02_warn_rep_ack_02",
    "am_script_01_table_02_info_rep_ack_01",
    "am_script_01_table_02_info_rep_ack_02",
    -- каналы тревог без квитирования rep.
    "am_script_01_table_02_error_rep_01",
    "am_script_01_table_02_error_rep_02",
    "am_script_01_table_02_warn_rep_01",
    "am_script_01_table_02_warn_rep_02",
    "am_script_01_table_02_info_rep_01",
    "am_script_01_table_02_info_rep_02",

    -- Скрипт 2 Таблица 3.
    -- каналы тревог с квитированием rep_ack.
    "am_script_02_table_03_error_rep_ack_01",
    "am_script_02_table_03_error_rep_ack_02",
    "am_script_02_table_03_warn_rep_ack_01",
    "am_script_02_table_03_warn_rep_ack_02",
    "am_script_02_table_03_info_rep_ack_01",
    "am_script_02_table_03_info_rep_ack_02",
    -- каналы тревог без квитирования rep.
    "am_script_02_table_03_error_rep_01",
    "am_script_02_table_03_error_rep_02",
    "am_script_02_table_03_warn_rep_01",
    "am_script_02_table_03_warn_rep_02",
    "am_script_02_table_03_info_rep_01",
    "am_script_02_table_03_info_rep_02",

    -- Тестовый канал синуса.
    "am_sine_signal",

}
local test_channels = {}

for _, tag_name in ipairs(test_tag_names) do
    local channel = {}
    channel.name = tag_name
    channel.info = "Тестовый канал Менеджера тревог."
    table.insert(test_channels, channel)
end
tags:CreateNewTags(test_channels, {pth_dir=pth})

--#endregion Переменные.


-- Сменился статус СИАМ: просмотр-запись или запись-просмотр?
local function is_recorder_changed_status()
    local recorder_status
    local recorder_status_last

    local function inner()
        local status_changed = false
        recorder_status = getRecorderStatus()
        if recorder_status_last == datatype.RECORDER_STATE.RS_VIEW and recorder_status == datatype.RECORDER_STATE.RS_REC
            or recorder_status_last == datatype.RECORDER_STATE.RS_REC and recorder_status == datatype.RECORDER_STATE.RS_VIEW
        then
            status_changed = true
        end
        recorder_status_last = recorder_status
        return status_changed
    end

    return inner
end


local is_recorder_changed_status_1 = is_recorder_changed_status()


function lua_main()

    --#region Тестовая имитация значений на каналах.

    -- Инициализация каналов при старте СИАМ.
    if not ton_init:calc(true, 0.1) or is_recorder_changed_status_1() then
        for _, chan_name in ipairs(test_tag_names) do
            setValue(chan_name, 0)
        end
    end

    setValue("am_sine_signal", 1 + 0.1 * math.sin(1 * getRecorderTime()))

    --#endregion Тестовая имитация значений на каналах.

end
