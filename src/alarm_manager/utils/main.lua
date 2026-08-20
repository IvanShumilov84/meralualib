--[[
    Менетжер тревог.
]]
-- TODO Добавить обработку LOGIC = CHANGE.

-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."

local datatype = require(lib_path .. "datatype")
local SIAM_LOG_PRIOR = datatype.SIAM_LOG_PRIOR

local hmi = require(lib_path .. "hmi")
local Btn_click = hmi["Btn_click"]

local module_utils = require(lib_path .. "module_utils")

local siam_wrapper = require(lib_path .. "siam_wrapper")
local tags = require(lib_path .. "tags")
local timers = require(lib_path .. "timers")


local M = {}
local MODULE_NAME = "alarm_manager"
local MODULE_COMMENT = "Менеджер тревог"

---@alias ALARM_APPEARANCE_VALUE integer

---Перечислитель визуального способа появления тревоги.
---@class ALARM_APPEARANCE
---@field STATIC ALARM_APPEARANCE_VALUE Активная тревога сразу поялвяется.
---@field BLINK ALARM_APPEARANCE_VALUE Активная тревога моргает при появлении.
---@field FLASH ALARM_APPEARANCE_VALUE Активная тревога вспыхивает при появлении.
local ALARM_APPEARANCE = datatype.Enum:new({
    STATIC = 0,
    BLINK = 1,
    FLASH = 2,
}, {
    name = "ALARM_APPEARANCE",
    description = "Визуальный способ появления тревоги."
})
M.ALARM_APPEARANCE = ALARM_APPEARANCE


---@class AlarmMsgColors
---@field error number Цвет активной тревоги класса "Ошибка" (по умолчанию красный, формат C++ Hex: 0x00424CEB)
---@field warn number Цвет активной тревоги класса "Предупреждение" (по умолчанию оранжевый, формат C++ Hex: 0x00008BFF)
---@field info number Цвет активной тревоги класса "Информирование" (по умолчанию жёлтый, формат C++ Hex: 0x0033FEFE)
---@field unack number Цвет неквитированной тревоги (по умолчанию серый, формат C++ Hex: 0x00A6A6A6)

---Настройки менеджера тревог.
---@class ManagerSettings
---@field alarm_appearance ALARM_APPEARANCE_VALUE Визуальный способ появления тревоги (по умолчанию: ALARM_APPEARANCE.FLASH)
---@field create_tags boolean Создать каналы таблиц в СИАМ: количества активных/неквитированных тревог, каналы кнопок квитирования, ... (по умолчанию: true)
---@field msg_color AlarmMsgColors Цвета тревог
local _manager_settings = {
    alarm_appearance = ALARM_APPEARANCE.FLASH,
    create_tags = true,
    msg_color = {
        error = 0x00424CEB,
        warn  = 0x00008BFF,
        info  = 0x0033FEFE,
        unack = 0x00A6A6A6,
    },
}
M.manager_settings = _manager_settings


---@alias LOGIC_VALUE integer

---Перечислитель способа наблюдения за событием.
---@class LOGIC
---@field DISCRETE LOGIC_VALUE Событие дискретное: ноль/отличное от ноля.
---@field ANALOG LOGIC_VALUE Событие аналоговое.
---@field CHANGE LOGIC_VALUE Обрабатывается любое изменение события.
---@field EVENT LOGIC_VALUE Событие имеет значения true/false.
---@field CS_CLIENT LOGIC_VALUE Полное повторение состояния тревоги из менеджера тревог Кодесис.
local LOGIC = datatype.Enum:new({
    DISCRETE = 0,
    ANALOG = 1,
    CHANGE = 2,
    EVENT = 3,
    CS_CLIENT = 4,
}, {
    name = "LOGIC",
    description = "Способ наблюдения за событием."
})
M.LOGIC = LOGIC

---@alias LIMIT_TYPE_VALUE integer

---Перечислитель типа ограничения значения при обработке аналогового события.
---@class LIMIT_TYPE
---@field LOW LIMIT_TYPE_VALUE Значение ограничено снизу.
---@field HIGH LIMIT_TYPE_VALUE Значение ограничено сверху.
---@field LOW_HIGH LIMIT_TYPE_VALUE Значение ограничено снизу и сверху.
local LIMIT_TYPE = datatype.Enum:new({
    LOW = 0,
    HIGH = 1,
    LOW_HIGH = 2,
}, {
    name = "LIMIT_TYPE",
    description = "Тип ограничения при обработке аналогового события."
})
M.LIMIT_TYPE = LIMIT_TYPE

local _LIMIT_STATE = {  -- Состояние событий по ограничениям при обработке аналогового события.
    norm = "norm",  -- Событие в допуске.
    low = "low",  -- Событие по ограничению снизу.
    high = "high",  -- Событие по ограничению сверху.
}
local ALARM_STATUS = {  -- Статусы тревоги в менеджере тревог СИАМ.
    ACTIVE = 0,  -- Активная.
    NOT_ACTIVE = 1,  -- Неактивная.
    ACK = 2,  -- Квитированная.
}

---@alias CS_ALARM_STATE_VALUE integer

---Перечислитель состояния тревоги из Кодесис.
---@class CS_ALARM_STATE
---@field NOT_DEFINED CS_ALARM_STATE_VALUE Неопределено.
---@field NORMAL CS_ALARM_STATE_VALUE Тревога неактивна.
---@field PENDING CS_ALARM_STATE_VALUE Условие тревоги активно, но сама тревога неактивна.
---@field ACTIVE CS_ALARM_STATE_VALUE Тревога активна.
---@field WAITING_FOR_CONFIRMATION CS_ALARM_STATE_VALUE Тревога неактивна, но требует квитирования.
---@field ACTIVE_ACKNOWLEDGED CS_ALARM_STATE_VALUE Тревога аткивна и квитирована.
local CS_ALARM_STATE = datatype.Enum:new({
    NOT_DEFINED = 255,
    NORMAL = 0,
    PENDING = 1,
    ACTIVE = 2,
    WAITING_FOR_CONFIRMATION = 3,
    ACTIVE_ACKNOWLEDGED = 4,
}, {
    name = "CS_ALARM_STATE",
    description = "Состояние тревоги из Кодесис."
})

---@alias ALARM_CLASS_VALUE integer

---Перечислитель класса тревоги.
---@class ALARM_CLASS
---@field ERROR ALARM_CLASS_VALUE Ошибка.
---@field WARN ALARM_CLASS_VALUE Предупреждение.
---@field INFO ALARM_CLASS_VALUE Информирование.
local ALARM_CLASS = datatype.Enum:new({
    ERROR = 0,
    WARN = 1,
    INFO = 2,
}, {
    name = "ALARM_CLASS",
    description = "Класс тревоги."
})
M.ALARM_CLASS = ALARM_CLASS

local ALARM_CLASS_CONFIG = {  -- Настройки классов тревог.
    [ALARM_CLASS.ERROR] = {log_prior = SIAM_LOG_PRIOR.ERROR},
    [ALARM_CLASS.WARN] = {log_prior = SIAM_LOG_PRIOR.WARNING},
    [ALARM_CLASS.INFO] = {log_prior = SIAM_LOG_PRIOR.INFO},
}

local MSG_COLOR = {  -- Цвета тревог по классам.
    [ALARM_CLASS.ERROR] = _manager_settings.msg_color.error,
    [ALARM_CLASS.WARN] = _manager_settings.msg_color.warn,
    [ALARM_CLASS.INFO] = _manager_settings.msg_color.info,
}

local _MSG_COLOR_BASE = 0x00FFFFFF  -- Базовый цвет фона тревог (белый).
local MSG_COLOR_UNACK = _manager_settings.msg_color.unack  -- Цвет фона неквитированных тревог.


-- Обновление настройки цветов тревог.
local function msg_color_upd()
    MSG_COLOR = {  -- Цвета тревог по классам.
        [ALARM_CLASS.ERROR] = _manager_settings.msg_color.error,
        [ALARM_CLASS.WARN] = _manager_settings.msg_color.warn,
        [ALARM_CLASS.INFO] = _manager_settings.msg_color.info,
    }
    MSG_COLOR_UNACK = _manager_settings.msg_color.unack
end


---@alias CONFIRM_METHOD_VALUE integer

---Перечислитель способа подтверждения тревоги.
---@class CONFIRM_METHOD
---@field ACK CONFIRM_METHOD_VALUE (не использовать, в разработке) Квитирование тревоги.
---@field REP CONFIRM_METHOD_VALUE Деактивация тревоги.
---@field ACK_REP CONFIRM_METHOD_VALUE (не использовать, в разработке) подтверждение деактивированной или деактивация квитированной тревоги.
---@field REP_ACK CONFIRM_METHOD_VALUE Подтверждение деактивированной тревоги.
---@field ACK_REP_ACK CONFIRM_METHOD_VALUE (не использовать, в разработке) Подтверждение деактивированной тревоги, причем перед деактивацией тревога опционально могла быть сквитирована.
local CONFIRM_METHOD = datatype.Enum:new({
    ACK = 0,
    REP = 1,
    ACK_REP = 2,
    REP_ACK = 3,
    ACK_REP_ACK = 4,
}, {
    name = "CONFIRM_METHOD",
    description = "Способ подтверждения тревоги."
})
M.CONFIRM_METHOD = CONFIRM_METHOD


local caller_path  -- Путь до вызвавшего скрипта.
local script_id  -- номер вызывающего скрипта.
local _ALARM_ID_COUNTER_VAR_NAME = "#alarm_manager__alarm_id_counter"  -- Имя переменной окружения счётчика сквозных ID тревог.
local _ALARM_ID_SEED = 0  -- Инициализация переменной счётчика сквозных ID тревог.
local _TOTAL_ALARMS_VAR_NAME = "#alarm_manager__total_alarms"  -- Имя переменной окружения общего количества тревог (необходимо для очищения тревог перед стартом скриптов).
local _SCRIPT_ID_VAR_NAME = "#alarm_manager__script_id"  -- Имя переменной окружения идентификационного номера скрипта.
local _SCRIPT_ID_SEED = 0  -- Инициализация переменной счётчика ID вызывающих скриптов.
local _TBL_IDS_ENV = "#alarm_manager__tbl_ids"  -- Имя переменной окружения идентификационных номеров таблиц.
local _siam_tag_names_list  -- Список имён всех каналов СИАМ.
local _tables = {}  -- Список таблиц тревог.
local _unique_tables = {}  -- Словарь уникальных таблиц тревог.
local _pending_tables = {}   -- Таблицы, ожидающие регистрации.
local _alarm_list = {}  -- Список тревог.
local _event_last = {}  -- Список активного состояния тревог true/false.
local _COLOR_QTY = 15  -- Количество генерируемых цветов при ALARM_APPEARANCE.FLASH.
local _SCRIPT_PERIOD  -- Период вызывающего скрипта.
local _ALARM_FLASH_TIME = 1.5  -- Время вспышки при активации тревоги, секунды.
local _get_msg_color = {}  -- Список генераторов цвета для каждой тревоги для эффекта вспышки во время появления тревог.
local alarm_qty = {  -- Список меток для количества активных/неквитированных тревог.
    "error",
    "warn",
    "info",
    "all_alarm",
}

---@class AnalogConfig
---@field msg_detail boolean? Отображать дополнительную информацию по каналу в сообщении. (по умолчанию: false)
---@field display_val boolean? Отображать значение отслеживаемого параметра в сообщении активной тревоги. (по умолчанию: false)
---@field get_limit_from_chan boolean? Получать значения пределов из каналов. (по умолчанию: false)

---@class AtableConfig
---@field table_id integer? Номер таблицы тревог. (по умолчанию: -1)
---@field module_name string? Имя системы. (по умолчанию: "")
---@field ack_btn boolean? Флаг создания кнопки квитирования. (по умолчанию: false)
---@field analog AnalogConfig? Настройки для аналоговых тревог.
---@field display_id_at_msg boolean? Флаг отображения внутреннего ID в сообщении. (по умолчанию: false)
---@field display_alarm_state_label boolean? Отображать лейбл состояния тревоги в начале сообщения. (по умолчанию: true)
---@field alarm_delay_on number? Время задержки активации тревог, секунды. (по умолчанию: 0)
---@field alarm_delay_off number? Время задержки деактивации тревог, секунды. (по умолчанию: 0)
local _table_config = {  -- Конфигурация таблицы тревог.
    table_id = -1,
    module_name = "",
    ack_btn = false,
    analog = {
        msg_detail = false,
        display_val = false,
        get_limit_from_chan = false,
    },
    display_id_at_msg = false,
    display_alarm_state_label = true,
    alarm_delay_on = 0,
    alarm_delay_off = 0,
}

local _TABLE_ID_PREFIX = "table_id_"  -- Префикс к индексу таблиц в именах каналов.
local _MAIN_TABLE_ID = -1  -- Идентификационный номер главной таблицы.
local _MAIN_TABLE_NAME = "Главная таблица"  -- Комментарий к главной таблице.
local _ACK_BTN_NAME = "acknow"  -- Название кнопки квитирования аварий.
local _ALARM_QTY_NAME = "alarm_qty"  -- Часть имени каналов количества активных тревог.
local _UNACK_QTY_NAME = "unack_qty"  -- Часть имени каналов количества несквитированных тревог.
local analog_low_high = {}  -- Список состояний сработки сообщений вида: {[msgid] = "norm"/"low"/"high", ...}
local analog_low_high_last = {}  -- Список последних состояний сработки сообщений вида: {[msgid] = "low"/"high", ...}
local PRIOR_DEF = 100  -- Приоритет тревоги в пределах одного класса тревог по умолчанию.
local PRIOR_MIN = 1  -- Высший приоритет тревоги.
local PRIOR_MAX = 1000  -- Низший приоритет тревоги.
local _DBG_PREF_MSG = "Отладочное сообщение: "


---@class AlarmAnalogConfig
---@field msg_detail boolean? Отображать дополнительную информацию по каналу в сообщении при logic = LOGIC.ANALOG (по умолчанию: false).
---@field display_val boolean? Отображать значение отслеживаемого параметра в сообщении активной тревоги при logic = LOGIC.ANALOG (по умолчанию: false).
---@field get_limit_from_chan boolean? Получать значения пределов из каналов при logic = LOGIC.ANALOG (по умолчанию: false).

---@class AlarmConfig
---@field logic LOGIC_VALUE? Способ наблюдения за событием (по умолчанию: LOGIC.EVENT).
---@field class ALARM_CLASS_VALUE? Класс тревоги (по умолчанию: ALARM_CLASS.ERROR).
---@field msg string? Текст тревоги (по умолчанию: "Пример сообщения. Заполните поле 'msg'").
---@field confirm_method CONFIRM_METHOD_VALUE? Способ подтверждения события (по умолчанию: CONFIRM_METHOD.REP_ACK).
---@field prior integer? Приоритет тревоги в пределах одного класса: 1 - наибольший, 1000 - наименьший (по умолчанию: 100).
---@field delay_on number? Время задержки активации тревоги, секунды (по умолчанию: 0).
---@field delay_off number? Время задержки деактивации тревоги, секунды (по умолчанию: 0).
---@field event boolean|number? Состояние события при logic = LOGIC.EVENT (по умолчанию: false/0).
---@field channel string? Имя канала при logic = LOGIC.DISCRETE | LOGIC.ANALOG | LOGIC.CHANGE (по умолчанию: "").
---@field limit_type LIMIT_TYPE_VALUE? Тип ограничения при logic = LOGIC.ANALOG (по умолчанию: LIMIT_TYPE.LOW_HIGH).
---@field low number? Значение нижнего предела при logic = LOGIC.ANALOG (по умолчанию: 0).
---@field high number? Значение верхнего предела при logic = LOGIC.ANALOG (по умолчанию: 0).
---@field ch_low string? Имя канала для значения нижнего предела при logic = LOGIC.ANALOG (по умолчанию: "").
---@field ch_high string? Имя канала для значения верхнего предела при logic = LOGIC.ANALOG (по умолчанию: "").
---@field discrete_val integer? Значение предела при logic = LOGIC.DISCRETE (по умолчанию: 0).
---@field hyst_low number? Значение гистерезиса для нижнего предела при logic = LOGIC.ANALOG (по умолчанию: 0).
---@field hyst_high number? Значение гистерезиса для верхнего предела при logic = LOGIC.ANALOG (по умолчанию: 0).
---@field cs_alarm_state CS_ALARM_STATE_VALUE? Состояние тревоги из Кодесис при logic = LOGIC.CS_CLIENT (по умолчанию: CS_ALARM_STATE.NORMAL).
---@field cs_ack string? Имя канала квитирования тревоги при LOGIC.CS_CLIENT (по умолчанию: "").
---@field analog AlarmAnalogConfig? Настройки при logic = LOGIC.ANALOG.
local _alarm_config = {  -- Структура тревоги.
    logic = LOGIC.EVENT,
    class = ALARM_CLASS.ERROR,
    msg = "Пример сообщения. Заполните поле 'msg'",
    confirm_method = CONFIRM_METHOD.REP_ACK,
    prior = PRIOR_DEF,
    delay_on = 0,
    delay_off = 0,
    event = "boolean|number",
    channel = "",
    limit_type = LIMIT_TYPE.LOW_HIGH,
    low = 0,
    high = 0,
    ch_low = "",
    ch_high = "",
    discrete_val = 0,
    hyst_low = 0,
    hyst_high = 0,
    cs_alarm_state = CS_ALARM_STATE.NORMAL,
    cs_ack = "",
    analog = {
        msg_detail = _table_config.analog.msg_detail,
        display_val = _table_config.analog.display_val,
        get_limit_from_chan = _table_config.analog.get_limit_from_chan,
    },
}
local is_ack = {}  -- Массив флагов квитирования тревог.
local ton = {}
local tof = {}
local manager_upd_delay = timers["Ton"]:new()  -- Задержка обновления менеджера тревог при старте.
local _blink_timer = timers["Ton"]:new()  -- Таймер моргания тревоги при появлении при ALARM_APPEARANCE.BLINK.
local _blink_clk = 0.2  -- Период моргания тревоги при появлении при ALARM_APPEARANCE.BLINK, секунды.
local _new_alarm_id = 0  -- ID последней активированной тревоги, используется для ALARM_APPEARANCE.BLINK.
local _BLINK_QTY = 6  -- Количество смены цвета тревоги при ALARM_APPEARANCE.BLINK.


-- Функция получения итератора для генерации цвета от белого до базового при ALARM_APPEARANCE.FLASH.
local function get_color_flash(base_color, max_steps)
    local step = 0

    -- Извлечение компонентов из base_color (формат 0xAABBGGRR)
    local target_r = math.floor(base_color % 0x100)             -- Red
    local target_g = math.floor((base_color / 0x100) % 0x100)   -- Green
    local target_b = math.floor((base_color / 0x10000) % 0x100) -- Blue

    -- Начальный цвет — белый
    local start_r, start_g, start_b = 255, 255, 255

    local get_color = function()
        if step >= max_steps then
            return nil
        end

        local progress = step / (max_steps - 1)

        local r, g, b

        if step == max_steps - 1 then
            r = target_r
            g = target_g
            b = target_b
        else
            r = math.floor(target_r * progress + start_r * (1 - progress) + 0.5)
            g = math.floor(target_g * progress + start_g * (1 - progress) + 0.5)
            b = math.floor(target_b * progress + start_b * (1 - progress) + 0.5)
        end

        -- Сборка цвета в формате ABGR (A = 00)
        local new_color = b * 0x10000 + g * 0x100 + r

        step = step + 1

        return new_color
    end

    return get_color
end


-- Функция получения итератора для генерации цвета при ALARM_APPEARANCE.BLINK.
local function get_color_blink(color, max_steps)
    local step = 0
    local new_color = color

    local get_color = function(clk, is_new_msg)
        if step >= max_steps then
            return nil
        end

        if clk then
            if not is_new_msg then
                new_color = color
                step = max_steps
            elseif new_color == _MSG_COLOR_BASE then
                new_color = color
            else
                new_color = _MSG_COLOR_BASE
            end
            step = step + 1
        end

        return new_color
    end

    return get_color
end


-- Получить значение переменной окружения как число.
local function getenv_number(varname)
    return tonumber(LU_GetEnvironmentString(varname))
end


-- Получить значение переменной окружения как строка.
local function getenv_str(varname)
    return LU_GetEnvironmentString(varname)
end


-- Установить значение переменной окружения.
local function setenv(varname, value)
    LU_SetEnvironmentString(varname, tostring(value))
end


local _delete_msgs = true
-- Очистить все сообщения перед стартом работы менеджера тревог.
local function clear_msgs()
    if _delete_msgs then
        _delete_msgs = false
        for msgid = 0, getenv_number(_TOTAL_ALARMS_VAR_NAME) do
            Delete_Alarm(msgid)
        end
    end
end


-- Состояния, возвращаемые функцией LU_GetEnvironmentString.
local VARENV_STATUS = {
    EMPTY_NAME = "Error1_DEBUG",  -- Передана пустая строка вместо имени переменной.
    NOT_EXIST = "Error3_DEBUG",  -- Переменная с данным именем не существует.
}


-- Переменная окружения существует?
local function is_varenv_exist(varname)
    return "" ~= (LU_GetEnvironmentString(varname))
    -- return nil ~= tonumber(LU_GetEnvironmentString(varname))
    -- return VARENV_STATUS.EMPTY_NAME ~= LU_GetEnvironmentString(varname) and VARENV_STATUS.NOT_EXIST ~= LU_GetEnvironmentString(varname)
end


-- Переменная окружения типа number?
local function is_varenv_number(varname)
    return nil ~= tonumber(LU_GetEnvironmentString(varname))
end


-- Скрипт является первым вызвавшим модуль менеджера тревог?
local function is_first_script()
    return script_id == _SCRIPT_ID_SEED
end


--- Разделяет строку на список подстрок по указанному разделителю
--- @param str string Исходная строка для разделения
--- @param sep string|nil Разделитель (по умолчанию пробел "%s"). Может быть любым односимвольным разделителем или паттерном Lua
--- @return table<number, string> Список подстрок, полученных из исходной строки
--- @example
---   local csv = "apple,banana,cherry"
---   local list = split(csv, ",")
---   -- list = {"apple", "banana", "cherry"}
---   
---   local words = "one two three"
---   local word_list = split(words)
---   -- word_list = {"one", "two", "three"}
local function split(str, sep)
    local result = {}
    -- Если разделитель не указан, бьем по пробелам
    sep = sep or "%s"

    -- Паттерн [^sep]+ ищет всё, что не является разделителем
    for match in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, match)
    end
    return result
end


-- Возвращает список номеров таблиц из переменной окружения.
--- @return table<number, number> list Отсортированный список номеров таблиц из переменной окружения.
local function get_tbl_ids()
    local tbl_ids_env = split(getenv_str(_TBL_IDS_ENV), "|")
    local tbl_ids_env_number = {}
    for _, str in ipairs(tbl_ids_env) do
        table.insert(tbl_ids_env_number, tonumber(str))
    end
    table.sort(tbl_ids_env_number)

    return tbl_ids_env_number
end


-- Получить имя канала количества тревог.
local function get_alarm_qty_channel_name(table_id, alarm_status, alarm_type)
    return MODULE_NAME .. "." .. _TABLE_ID_PREFIX .. table_id .. "." .. alarm_status .. "." .. alarm_type
end


local ACTIVE_ALARM_COMMENT = "канал количества активных тревог класса"
local UNACK_ALARM_COMMENT = "канал количества неквитированных тревог класса"


-- Получить инфо канала количества тревог.
local function get_alarm_qty_channel_info(table_id, alarm_status_comment, alarm_type, module_name)
    return MODULE_COMMENT .. ": таблица №" .. table_id .. ", " .. alarm_status_comment .. " '" .. alarm_type .. "' [модуль '" .. module_name .. "']."

end

-- Получить словарь: "имя канала количества тревог" - "номер таблицы".
--- @param table_ids table Список ID таблиц.
--- @return table  -- Словарь: "имя канала количества тревог" - "номер таблицы".
local function get_alarm_qty_channels_list(table_ids)
    local list = {}
    for _, table_id in ipairs(table_ids) do
        for alarm_status, alarm_status_comment in pairs({[_ALARM_QTY_NAME] = ACTIVE_ALARM_COMMENT, [_UNACK_QTY_NAME] = UNACK_ALARM_COMMENT}) do
            for _, alarm_type in ipairs(alarm_qty) do
                local channel = {}
                channel.name = get_alarm_qty_channel_name(table_id, alarm_status, alarm_type)
                channel.info = get_alarm_qty_channel_info(table_id, alarm_status_comment, alarm_type, _unique_tables[table_id] and _unique_tables[table_id].conf.module_name or "")

                table.insert(list, channel)
            end
        end
    end

    return list
end


--- Объединяет несколько списков в один без дублирования значений.
--- Порядок элементов сохраняется: сначала идут уникальные значения из первого списка,
--- затем новые значения из второго и т.д.
--- @param ... table[] Два или более списков для объединения
--- @example
--- @return table<number, any> set Новый список, содержащий уникальные значения из всех в
---   local a = {1, 2, 3}
---   local b = {3, 4, 5}
---   local c = {5, 6}
---   local merged = merge_unique(a, b, c)
---   -- merged = {1, 2, 3, 4, 5, 6}
local function merge_unique(...)
    local seen = {}
    local result = {}

    for _, list in ipairs({...}) do
        for _, v in ipairs(list) do
            if not seen[v] then
                seen[v] = true
                table.insert(result, v)
            end
        end
    end

    return result
end


-- Создание переменных окружения.
local function create_varenv()

    -- Создание и инициализация переменной окружения ID скриптов (требуется при первом запуске скриптов после загрузки СИАМ).
    if not is_varenv_exist(_SCRIPT_ID_VAR_NAME) then
        setenv(_SCRIPT_ID_VAR_NAME, _SCRIPT_ID_SEED)
    end

    -- Создание и инициализация переменной окружения ID тревог  (требуется при первом запуске скриптов после загрузки СИАМ).
    if not is_varenv_exist(_ALARM_ID_COUNTER_VAR_NAME) then
        setenv(_ALARM_ID_COUNTER_VAR_NAME, _ALARM_ID_SEED)
    end

    -- Создание и инициализация переменной окружения общего количества тревог (требуется при первом запуске скриптов после загрузки СИАМ).
    if not is_varenv_exist(_TOTAL_ALARMS_VAR_NAME) then
        setenv(_TOTAL_ALARMS_VAR_NAME, _ALARM_ID_SEED)
    end

    -- Создаём переменную окружения идентификационных номеров таблиц.
    if not is_varenv_exist(_TBL_IDS_ENV) then
        setenv(_TBL_IDS_ENV, -1)
    end

    -- Заполняем/дополняем переменную окружения идентификационных номеров таблиц значениями.
    local table_ids = {}
    for _, tbl in ipairs(_tables) do
        local table_id = tbl.conf.table_id
        table.insert(table_ids, table_id)
    end
    table.sort(table_ids)
    local tbl_ids_env = get_tbl_ids()
    tbl_ids_env = merge_unique(table_ids, tbl_ids_env)
    setenv(_TBL_IDS_ENV, table.concat(tbl_ids_env, "|"))


    -- Создание и инициализация переменных окружения количества тревог для всех таблиц.
    for _, channel in ipairs(get_alarm_qty_channels_list(get_tbl_ids())) do
        if not is_varenv_exist(channel.name) then
            setenv(channel.name, 0)
        end
    end

end


-- Обновление количества тревог для всех таблиц в каналах-счётчиках СИАМ.
local function alarm_qty_upd()
    for _, channel in ipairs(get_alarm_qty_channels_list(get_tbl_ids())) do
        setValue(channel.name, getenv_number(channel.name))
        setenv(channel.name, 0)
    end
end


local is_varenv_created = false  -- Переменные окружения созданы?
-- Первичная и циклическая инициализация менеджера тревог.
local function cycle_init()

    -- Создание переменных окружения.
    if not is_varenv_created then
        is_varenv_created = true
        create_varenv()
    end

    -- Если скрипт является первым вызвавшим модуль менеджера тревог.
    if is_first_script() then
        -- Удаление сообщений с предыдущей сессии запуска на просмотр/запись СИАМ.
        clear_msgs()

        -- Установка общего количества зарегистрированных тревог в переменную окружения.
        setenv(_TOTAL_ALARMS_VAR_NAME, getenv_number(_ALARM_ID_COUNTER_VAR_NAME))

        -- Установка начального значения ID тревог.
        setenv(_ALARM_ID_COUNTER_VAR_NAME, _ALARM_ID_SEED)

        -- Установка начального значения ID скриптов.
        setenv(_SCRIPT_ID_VAR_NAME, _SCRIPT_ID_SEED)

        -- Подсчёт количества активных тревог для главной таблицы.
        for _, table_id in pairs(get_tbl_ids()) do
            for _, alarm_class in ipairs(alarm_qty) do
                local varname = get_alarm_qty_channel_name(table_id, _ALARM_QTY_NAME, alarm_class)
                local main_tbl_varname = get_alarm_qty_channel_name(_MAIN_TABLE_ID, _ALARM_QTY_NAME, alarm_class)
                setenv(main_tbl_varname, getenv_number(main_tbl_varname) + getenv_number(varname))
            end
        end

        -- Подсчёт количества неквитированных тревог для главной таблицы.
        for _, table_id in pairs(get_tbl_ids()) do
            for _, alarm_class in ipairs(alarm_qty) do
                local varname = get_alarm_qty_channel_name(table_id, _UNACK_QTY_NAME, alarm_class)
                local main_tbl_varname = get_alarm_qty_channel_name(_MAIN_TABLE_ID, _UNACK_QTY_NAME, alarm_class)
                setenv(main_tbl_varname, getenv_number(main_tbl_varname) + getenv_number(varname))
            end
        end

        -- Обновление количества тревог для всех таблиц в каналах-счётчиках СИАМ.
        alarm_qty_upd()

    end

    -- Присвоение вызывающим скриптам ID с обновлением ID для следующего скрипта в переменной окружения.
    if not script_id then
        script_id = getenv_number(_SCRIPT_ID_VAR_NAME)
        setenv(_SCRIPT_ID_VAR_NAME, script_id + 1)
    end

end


--- Проверить и дополнить конфигурацию значениями по умолчанию.
---@generic T
---@param user_config? T Пользовательская конфигурация.
---@param default_config T Таблица с значениями по умолчанию.
---@return T config Проверенная конфигурация.
local function check_config(user_config, default_config, path)
    path = path or {}
    local errors = {}

    -- Если пользовательская конфигурация отсутствует
    if user_config == nil then
        -- Возвращаем глубокую копию, чтобы экземпляры не делили одну таблицу
        local copy = {}
        for k, v in pairs(default_config) do
            if type(v) == "table" then
                copy[k] = check_config(nil, v)   -- рекурсивное копирование
            else
                copy[k] = v
            end
        end
        return copy
    end

    -- Если дефолтная конфигурация не таблица
    if type(default_config) ~= "table" then
        return user_config
    end

    -- Если пользовательская конфигурация не таблица, но дефолтная - таблица
    if type(user_config) ~= "table" then
        local path_str = #path > 0 and table.concat(path, ".") or "root"
        assert(false, string.format("Type mismatch at '%s': expected table, got %s",
            path_str, type(user_config)))
    end

    -- Проверка на недопустимые поля в пользовательской конфигурации
    for key, user_value in pairs(user_config) do
        if default_config[key] == nil then
            local current_path = {}
            for _, p in ipairs(path) do table.insert(current_path, p) end
            table.insert(current_path, tostring(key))
            local path_str = table.concat(current_path, ".")
            assert(false, string.format("Invalid field at '%s': field '%s' is not allowed",
                #path > 0 and table.concat(path, ".") or "root", key))
        end
    end

    -- Проверка на недопустимые поля с накоплением ошибок
    for key, user_value in pairs(user_config) do
        if default_config[key] == nil then
            local current_path = {}
            for _, p in ipairs(path) do table.insert(current_path, p) end
            table.insert(current_path, tostring(key))
            local path_str = table.concat(current_path, ".")
            table.insert(errors, string.format("Invalid field at '%s': field '%s' is not allowed",
                #path > 0 and table.concat(path, ".") or "root", key))
        end
    end

    -- Рекурсивная проверка вложенных таблиц
    for key, default_value in pairs(default_config) do
        local user_value = user_config[key]
        local current_path = {}
        for _, p in ipairs(path) do table.insert(current_path, p) end
        table.insert(current_path, tostring(key))

        if type(user_value) == "table" and type(default_value) == "table" then
            local nested_errors = check_config(user_value, default_value, current_path)
            if nested_errors then
                for _, err in ipairs(nested_errors) do
                    table.insert(errors, err)
                end
            end
        end
    end

    if #errors > 0 then
        return errors
    end

    local result = {}

    -- Копируем значения из конфигурации
    for key, default_value in pairs(default_config) do
        local user_value = user_config[key]

        -- Создаём путь для текущего ключа
        local current_path = {}
        for _, p in ipairs(path) do table.insert(current_path, p) end
        table.insert(current_path, tostring(key))

        if user_value == nil then
            -- Используем значение по умолчанию
            result[key] = default_value
        else
            -- Рекурсивное объединение для таблиц
            if type(user_value) == "table" and type(default_value) == "table" then
                result[key] = check_config(user_value, default_value, current_path)
            else
                -- Проверка соответствия типов
                if default_value ~= "boolean|number" and type(user_value) ~= type(default_value) then
                    local path_str = table.concat(current_path, ".")
                    assert(false, string.format("Type mismatch at '%s': expected %s, got %s",
                        path_str, type(default_value), type(user_value)))
                end
                result[key] = user_value
            end
        end
    end

    return result
end


-- Получить цвет тревоги.
local function get_alarm_color(event, msgid, alarm_class)
    local msg_color

    if _manager_settings.alarm_appearance == ALARM_APPEARANCE.STATIC then
        msg_color = MSG_COLOR[alarm_class]
    elseif _manager_settings.alarm_appearance == ALARM_APPEARANCE.BLINK then
        if event and not _get_msg_color[msgid] and _blink_timer.q then
            _get_msg_color[msgid] = get_color_blink(MSG_COLOR[alarm_class], _BLINK_QTY)
        end
        if _get_msg_color[msgid] then
            msg_color = _get_msg_color[msgid](_blink_timer.q, msgid == _new_alarm_id)
        end
        if not event then
            _get_msg_color[msgid] = nil
        end
    elseif _manager_settings.alarm_appearance == ALARM_APPEARANCE.FLASH then
        if event and not _get_msg_color[msgid] then
            _get_msg_color[msgid] = get_color_flash(MSG_COLOR[alarm_class], _COLOR_QTY)
        end
        if _get_msg_color[msgid] then
            msg_color = _get_msg_color[msgid]()
        end
        if not event then
            _get_msg_color[msgid] = nil
        end
    end

    return msg_color
end


-- Тревога активна?
local function is_alarm_active(internal_id, table_id)
    return U_Alarm2_GetStatus(internal_id, table_id) == ALARM_STATUS.ACTIVE
end


-- Тревога в неквитированном состоянии?
local function is_alarm_unack(internal_id, table_id)
    return U_Alarm2_GetStatus(internal_id, table_id) == ALARM_STATUS.NOT_ACTIVE
end


-- Тревога в квитированном состоянии?
local function is_alarm_ack(internal_id, table_id)
    return U_Alarm2_GetStatus(internal_id, table_id) == ALARM_STATUS.ACK
end


-- Текстовые лейблы состояний тревог в журнале СИАМ.
local HISTORY_ALARM_STATE_LABELS = {
    ACK_ALARM = "[Квитирована] ",
    ACTIVE = "[Активна]",
    INACTIVE_ALARM = "[Неактивна] ",
    UNACK_ALARM = "[Неактивна, неквитирована] ",
}


-- Получить текст неквитированной тревоги.
local function get_unack_alarm_text(text_msg, use_unack_label)
    local unack_label = use_unack_label and HISTORY_ALARM_STATE_LABELS.UNACK_ALARM or ""
    text_msg = unack_label .. text_msg
    return text_msg
end


-- Получить текст квитированной тревоги.
local function get_ack_alarm_text(text_msg, use_ack_label)
    local label = use_ack_label and HISTORY_ALARM_STATE_LABELS.ACK_ALARM or ""
    text_msg = label .. text_msg
    return text_msg
end


-- Получить текст удалённой тревоги.
local function get_deleted_alarm_text(text_msg)
    return HISTORY_ALARM_STATE_LABELS.INACTIVE_ALARM .. text_msg
end


-- Установить тревогу.
local function set_alarm_to_active(text_msg, msgid, tableid, event, alarm_class, prior, internal_id, log_prior)
    local msg_color

    -- Установка тревоги.
    if event and (not is_alarm_active(internal_id, tableid) or is_alarm_unack(internal_id, tableid)) then
        msg_color = get_alarm_color(event, internal_id, alarm_class)

        Delete_Alarm(internal_id)  -- Вызов удаления нужен для появления последнего активного сообщения вверху менеджера тревог.
        U_Alarm2(text_msg, internal_id, tableid, msg_color, log_prior, prior)
        U_Alarm2_Change(text_msg, internal_id, tableid, msg_color, log_prior, prior, ALARM_STATUS.ACTIVE)
    end

    -- Управляем цветом тревоги для эффекта её визуального появления.
    msg_color = get_alarm_color(event, internal_id, alarm_class)
    if event and msg_color then
        U_Alarm2_Change(text_msg, internal_id, tableid, msg_color, log_prior, prior, ALARM_STATUS.ACTIVE)
    end

end


-- Установить тревогу в состояние неквитированной.
local function set_alarm_to_unack(text_msg, tableid, event, prior, internal_id, use_alarm_state_label)
    if not event and is_alarm_active(internal_id, tableid) then
        U_Alarm2_Change(get_unack_alarm_text(text_msg, use_alarm_state_label), internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior, ALARM_STATUS.NOT_ACTIVE)
        luacpLogMessage("ПКПАС", get_unack_alarm_text(text_msg, true), SIAM_LOG_PRIOR.NOTIFY)
    end
end


-- Установить тревогу в состояние квитированной.
local function set_alarm_to_ack(text_msg, msgid, tableid, prior, internal_id, use_alarm_state_label)
    if is_alarm_ack(internal_id, tableid) and not is_ack[internal_id] then
        is_ack[internal_id] = true
        luacpLogMessage("ПКПАС", get_ack_alarm_text(text_msg, true), SIAM_LOG_PRIOR.NOTIFY)
    end
end


-- Удалить тревогу.
local function delete_alarm(tableid, event, internal_id, text_msg)
    if not event and is_alarm_active(internal_id, tableid) then
        Delete_Alarm(internal_id)
        luacpLogMessage("ПКПАС", text_msg, SIAM_LOG_PRIOR.NOTIFY)
    end
end


-- Установить тревогу со способом подтверждения: CONFIRM_METHOD.REP_ACK.
local function set_rep_ack(text_msg, msgid, tableid, event, alarm_class, logic, prior, display_val, internal_id, table_rst, table_ack_cmd, display_alarm_state_label)

    local log_prior = ALARM_CLASS_CONFIG[alarm_class].log_prior

    -- Установить тревогу.
    set_alarm_to_active(text_msg, msgid, tableid, event, alarm_class, prior, internal_id, log_prior)

    -- Установить тревогу в состояние неквитированной.
    set_alarm_to_unack(text_msg, tableid, event, prior, internal_id, display_alarm_state_label)

    -- Установить тревогу в состояние квитированной.
    set_alarm_to_ack(text_msg, msgid, tableid, prior, internal_id, display_alarm_state_label)

    -- Квитирование тревоги через внешние кнопки.
    if table_rst or is_alarm_unack(internal_id, tableid) and table_ack_cmd then
        -- U_Alarm2_Change(get_unack_alarm_text(text_msg, display_alarm_state_label), internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior, ALARM_STATUS.ACK)
        U_Alarm2_Change(text_msg, internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior, ALARM_STATUS.ACK)
        luacpLogMessage("ПКПАС", get_deleted_alarm_text(text_msg), SIAM_LOG_PRIOR.NOTIFY)
    end

    -- Обновление текущего значения параметра в сообщении активной тревоги.
    if logic == LOGIC.ANALOG and is_alarm_active(internal_id, tableid) and display_val then
        U_Alarm2_Change(text_msg, internal_id, tableid, MSG_COLOR[alarm_class], log_prior, prior, ALARM_STATUS.ACTIVE)
    end

    -- Обновление текущего значения параметра в сообщении неквитированной тревоги.
    if logic == LOGIC.ANALOG and is_alarm_unack(internal_id, tableid) and display_val then
        U_Alarm2_Change(get_unack_alarm_text(text_msg, display_alarm_state_label), internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior, ALARM_STATUS.NOT_ACTIVE)
    end
end


-- Установить тревогу со способом подтверждения: CONFIRM_METHOD.REP.
local function set_rep(text_msg, msgid, tableid, event, alarm_class, logic, prior, display_val, internal_id)
    local log_prior = ALARM_CLASS_CONFIG[alarm_class].log_prior

    -- Установить тревогу.
    set_alarm_to_active(text_msg, msgid, tableid, event, alarm_class, prior, internal_id, log_prior)

    -- Удалить тревогу.
    delete_alarm(tableid, event, internal_id, get_deleted_alarm_text(text_msg))
end


-- Установить тревогу при logic=LOGIC.CS_CLIENT.
local function set_state(text_msg, msgid, tableid, alarm_class, prior, state, ack_chan, internal_id, display_alarm_state_label)
    local log_prior = ALARM_CLASS_CONFIG[alarm_class].log_prior

    -- Установить тревогу.
    set_alarm_to_active(text_msg, msgid, tableid, state == CS_ALARM_STATE.ACTIVE, alarm_class, prior, internal_id, log_prior)

    -- Перевод тревоги в состояние неквитированной.
    if state == CS_ALARM_STATE.WAITING_FOR_CONFIRMATION and not is_alarm_unack(internal_id, tableid) and U_Alarm2_GetStatus(internal_id, tableid) ~= ALARM_STATUS.ACK then
        Delete_Alarm(internal_id)
        U_Alarm2(get_unack_alarm_text(text_msg, display_alarm_state_label), internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior)
        U_Alarm2_Change(get_unack_alarm_text(text_msg, display_alarm_state_label), internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior, ALARM_STATUS.NOT_ACTIVE)
    end

    -- Удаление тревоги или перевод неквитированной тревоги в квитированную через внешнюю кнопку квитирования.
    if state == CS_ALARM_STATE.NORMAL then
        U_Alarm2_Change(get_unack_alarm_text(text_msg, true), internal_id, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, prior, ALARM_STATUS.ACK)
    end

    if state == CS_ALARM_STATE.WAITING_FOR_CONFIRMATION and U_Alarm2_GetStatus(internal_id, tableid) == ALARM_STATUS.ACK then
        setValue(ack_chan, 1)
    end

end


-- Обновление состояний кнопок квитирования тревог.
local function acknow_btn_upd(tbl)
    if tbl.ack_btn then
        tbl._ack_btn:upd()
        tbl._ack_cmd = tbl._ack_btn.q
    end
end


-- Подсчёт количества тревог для данной таблицы.
local function alarm_qty_calc(internal_id, table_id, aclass)
    -- Создаём таблицу имён классов тревог в нижнем регистре.
    local alarm_classes = {}
    for _, classname in ipairs(ALARM_CLASS:get_all_names()) do
        alarm_classes[classname] = string.lower(classname)
    end

    -- Подсчёт количества активных тревог каждого класса.
    if is_alarm_active(internal_id, table_id) then
        local alarm_class = alarm_classes[ALARM_CLASS:get_name(aclass)]
        local varname = get_alarm_qty_channel_name(table_id, _ALARM_QTY_NAME, alarm_class)
        setenv(varname, getenv_number(varname) + 1)
    end

    -- Подсчёт количества неквитированных тревог каждого класса.
    if is_alarm_unack(internal_id, table_id) then
        local alarm_class = alarm_classes[ALARM_CLASS:get_name(aclass)]
        local varname = get_alarm_qty_channel_name(table_id, _UNACK_QTY_NAME, alarm_class)
        setenv(varname, getenv_number(varname) + 1)
    end

    -- Подсчёт общего количества активных тревог всех классов для данной таблицы.
    local all_alarm_qty = 0
    for _, alarm_class in pairs(alarm_classes) do
        local varname = get_alarm_qty_channel_name(table_id, _ALARM_QTY_NAME, alarm_class)
        all_alarm_qty = all_alarm_qty + getenv_number(varname)
    end
    local name = get_alarm_qty_channel_name(table_id, _ALARM_QTY_NAME, "all_alarm")
    setenv(name, all_alarm_qty)

    -- Подсчёт общего количества неквитированных тревог всех классов для данной таблицы.
    local all_unack_qty = 0
    for _, alarm_class in pairs(alarm_classes) do
        local varname = get_alarm_qty_channel_name(table_id, _UNACK_QTY_NAME, alarm_class)
        all_unack_qty = all_unack_qty + getenv_number(varname)
    end
    name = get_alarm_qty_channel_name(table_id, _UNACK_QTY_NAME, "all_alarm")
    setenv(name, all_unack_qty)

end


-- Получить подробности о тревоге в виде строки.
local function get_alarm_details_string(alarm_id, alarm_msg)
    return string.format("alarm.id = %s (alarm.msg = '%s'): ",
        alarm_id, alarm_msg)
end


-- Проверка типа переменной.
local function check_var_type(var_val, var_name, var_type)
    assert(type(var_name) == "string", string.format("Type mismatch at 'var_name': expected string, got %s", type(var_name)))
    assert(type(var_type) == "string", string.format("Type mismatch at 'var_type': expected string, got %s", type(var_type)))
    assert(type(var_val) == var_type, string.format("Type mismatch at '%s': expected %s, got %s", var_name, var_type, type(var_val)))
end


-- Проверка значения на диапазон.
local function bound_check(alarm_id, alarm_msg, value_name, value, bound_min, bound_max)
    check_var_type(alarm_id, "alarm_id", "number")
    check_var_type(alarm_msg, "alarm_msg", "string")
    check_var_type(value_name, "value_name", "string")
    check_var_type(value, "value", "number")
    check_var_type(bound_min, "bound_min", "number")
    check_var_type(bound_max, "bound_max", "number")

    assert(value >= bound_min and value <= bound_max,
        get_alarm_details_string(alarm_id, alarm_msg) ..
        string.format("parameter '%s' value (= %s) must be within %s..%s",
            value_name, value, bound_min, bound_max)
    )
end


-- Проверка принадлежности значения параметра перечислителю.
local function param_enum_check(alarm_id, alarm_msg, value_name, value, enum)
    check_var_type(alarm_id, "alarm_id", "number")
    check_var_type(alarm_msg, "alarm_msg", "string")
    check_var_type(value_name, "value_name", "string")
    check_var_type(value, "value", "number")
    check_var_type(enum, "enum", "table")

    assert(enum:is_valid_value(value),
        get_alarm_details_string(alarm_id, alarm_msg) ..
        string.format("parameter '%s' value (= %s) does not belong to the '%s' enumerator.",
            value_name, value, enum:get_name_enum())
    )
end


-- Проверка значений уставок при LOGIC.ANALOG, LIMIT_TYPE.LOW_HIGH.
local function limit_type_check(alarm_id, alarm_msg, logic, limit_type, limit_low, limit_high)
    check_var_type(alarm_id, "alarm_id", "number")
    check_var_type(alarm_msg, "alarm_msg", "string")
    check_var_type(logic, "logic", "number")
    check_var_type(limit_type, "limit_type", "number")
    check_var_type(limit_low, "limit_low", "number")
    check_var_type(limit_high, "limit_high", "number")

    if logic == LOGIC.ANALOG and limit_type == LIMIT_TYPE.LOW_HIGH and (limit_low > limit_high) then
        assert(false,
            get_alarm_details_string(alarm_id, alarm_msg) ..
            string.format("with alarm settings LOGIC.ANALOG and LIMIT_TYPE.LOW_HIGH, " ..
                "the value of 'limit_low' (= %s) is greater than the value of 'limit_high' (= %s)",
                limit_low, limit_high)
        )
    end
end


-- Проверка значения гистерезиса уставки на неотрицательное значение.
local function hyst_check(alarm_id, alarm_msg, hyst_type, hyst_value)
    check_var_type(alarm_id, "alarm_id", "number")
    check_var_type(alarm_msg, "alarm_msg", "string")
    check_var_type(hyst_type, "hyst_type", "string")
    check_var_type(hyst_value, "hyst_value", "number")

    assert(hyst_value >= 0,
        get_alarm_details_string(alarm_id, alarm_msg) ..
        string.format("the parameter '%s' value (= %s) cannot be less than zero.",
            hyst_type, hyst_value)
    )
end


-- Проверка имён каналов пределов при LOGIC.ANALOG и analog.get_limit_from_chan=true.
local function limit_type_channel_names_check(id, alarm)

    -- Проверка на пустое имя.
    if (alarm.limit_type == LIMIT_TYPE.LOW or alarm.limit_type == LIMIT_TYPE.LOW_HIGH) and alarm.ch_low == "" then
        assert(false,
            get_alarm_details_string(id, alarm.msg) ..
            "parameter 'alarm.ch_low' - the lower limit channel name is empty.")
    end
    if (alarm.limit_type == LIMIT_TYPE.HIGH or alarm.limit_type == LIMIT_TYPE.LOW_HIGH) and alarm.ch_high == "" then
        assert(false,
            get_alarm_details_string(id, alarm.msg) ..
            "parameter 'alarm.ch_high' - the upper limit channel name is empty.")
    end

    -- Проверка на наличие имён каналов в СИАМ.
    local is_ch_low_exist = false
    local is_ch_high_exist = false
    for _, name in ipairs(_siam_tag_names_list) do
        if alarm.ch_low == name then
            is_ch_low_exist = true
        end
        if alarm.ch_high == name then
            is_ch_high_exist = true
        end
    end
    if (alarm.limit_type == LIMIT_TYPE.LOW or alarm.limit_type == LIMIT_TYPE.LOW_HIGH) then
        assert(is_ch_low_exist,
            get_alarm_details_string(id, alarm.msg) ..
            string.format("the name at parameter 'alarm.ch_low' = '%s' does not exist at SIAM.", alarm.ch_low))
    end
    if (alarm.limit_type == LIMIT_TYPE.HIGH or alarm.limit_type == LIMIT_TYPE.LOW_HIGH) then
        assert(is_ch_high_exist,
            get_alarm_details_string(id, alarm.msg) ..
            string.format("the name at parameter 'alarm.ch_high' = '%s' does not exist at SIAM.", alarm.ch_high))
    end

end


-- Проверка имени канала при logic=LOGIC.ANALOG.
local function analog_channel_name_check(id, alarm)

    -- Проверка на пустое имя.
    if alarm.channel == "" then
        assert(false,
            get_alarm_details_string(id, alarm.msg) ..
            "parameter 'alarm.channel' - channel name is empty.")
    end

    -- Проверка на наличие имени канала в СИАМ.
    local is_ch_exist = false
    for _, name in ipairs(_siam_tag_names_list) do
        if alarm.channel == name then
            is_ch_exist = true
        end
    end
    assert(is_ch_exist,
        get_alarm_details_string(id, alarm.msg) ..
        string.format("the name at parameter 'alarm.channel' = '%s' does not exist at SIAM.", alarm.channel))

end

-- Проверка имён каналов при logic=LOGIC.ANALOG.
local function channel_names_check(id, alarm)

    -- Проверка наличия списка каналов СИАМ.
    assert(_siam_tag_names_list, "The list of SIAM channel names has not been formed.")

    analog_channel_name_check(id, alarm)

    if alarm.analog.get_limit_from_chan then
        limit_type_channel_names_check(id, alarm)
    end

end

-- Словарь допустимых значений параметров.
local PARAM_BOUNDS = {
    prior = {bound_min=PRIOR_MIN, bound_max=PRIOR_MAX},
}

-- Словарь соответствия параметра перечислителю.
local PARAM_ENUM = {
    logic = LOGIC,
    class = ALARM_CLASS,
    confirm_method = CONFIRM_METHOD,
    limit_type = LIMIT_TYPE,
    cs_alarm_state = CS_ALARM_STATE,
}

-- Типы гистерезиса.
local PARAM_HYST_TYPE = {
    "hyst_low",  -- Гистерезис для нижней уставки.
    "hyst_high"  -- Гистерезис для верхней уставки.
}

-- Получить флаг тревоги при LOGIC.EVENT.
local function get_logic_event(event, delay_on, delay_off, internal_id)
    local type_ = type(event)
    if type_ == "boolean" then
        event = event
    elseif type_ == "number" then
        event = event > 0
    else
        event = false
    end

    event = ton[internal_id]:calc(event, delay_on)
    event = tof[internal_id]:calc(event, delay_off)
    return event
end

-- Получить флаг тревоги при LOGIC.DISCRETE.
local function get_logic_discrete(channel, discrete_val)
    return getValue(channel) > discrete_val
end

-- Получить флаг тревоги при logic=LOGIC.ANALOG.
local function get_logic_analog(id, channel, limit_type, low, high, hyst_low, hyst_high)
    local event = false

    if limit_type == LIMIT_TYPE.LOW then
        if getValue(channel) < low or (analog_low_high[id] == _LIMIT_STATE.low and getValue(channel) < low + hyst_low) then
            analog_low_high[id] = _LIMIT_STATE.low
            event = true
        else
            analog_low_high[id] = _LIMIT_STATE.norm
        end
    elseif limit_type == LIMIT_TYPE.HIGH then
        if getValue(channel) > high or (analog_low_high[id] == _LIMIT_STATE.high and getValue(channel) > high - hyst_high) then
            analog_low_high[id] = _LIMIT_STATE.high
            event = true
        else
            analog_low_high[id] = _LIMIT_STATE.norm
        end
    elseif limit_type == LIMIT_TYPE.LOW_HIGH then
        if (getValue(channel) < low and analog_low_high[id] == _LIMIT_STATE.high) then
            analog_low_high[id] = _LIMIT_STATE.low
        elseif(getValue(channel) > high and analog_low_high[id] == _LIMIT_STATE.low) then
            analog_low_high[id] = _LIMIT_STATE.high
        elseif getValue(channel) < low or (analog_low_high[id] == _LIMIT_STATE.low and getValue(channel) < low + hyst_low) then
            analog_low_high[id] = _LIMIT_STATE.low
            analog_low_high_last[id] = analog_low_high[id]
            event = true
        elseif getValue(channel) > high or (analog_low_high[id] == _LIMIT_STATE.high and getValue(channel) > high - hyst_high) then
            analog_low_high[id] = _LIMIT_STATE.high
            analog_low_high_last[id] = analog_low_high[id]
            event = true
        else
            analog_low_high[id] = _LIMIT_STATE.norm
        end
    end

    return event
end

-- Проверить состояние канала.
local function is_channel_bad(name)
    local _, _, status = getEstimate(name)
    return status ~= 0
end

-- Проверка состояния канала аналогового значения при logic=LOGIC.ANALOG.
local function check_logic_analog_channel(channel)
    local ch_bad = is_channel_bad(channel)
    local msg

    if ch_bad then
        msg = string.format("параметр 'alarm.channel' (имя канала аналогового значения) = '%s' - канал СИАМ неисправен", channel)
    end

    return msg
end

-- Проверка состояния каналов пределов при logic=LOGIC.ANALOG и alarm.analog.get_limit_from_chan=true.
local function check_logic_analog_limit_channels(limit_type, ch_low, ch_high)
    local msg
    local ch_low_bad = is_channel_bad(ch_low)
    local ch_high_bad = is_channel_bad(ch_high)
    local msg_low = string.format("параметр 'alarm.ch_low' (имя канала нижнего предела значения) = '%s' - канал СИАМ неисправен", ch_low)
    local msg_high = string.format("параметр 'alarm.ch_high' (имя канала верхнего предела значения) = '%s' - канал СИАМ неисправен", ch_high)

    if ch_low_bad and (limit_type == LIMIT_TYPE.LOW or limit_type == LIMIT_TYPE.LOW_HIGH)
            or ch_high_bad and (limit_type == LIMIT_TYPE.HIGH or limit_type == LIMIT_TYPE.LOW_HIGH)
    then
        if limit_type == LIMIT_TYPE.LOW and ch_low_bad then
            msg = msg_low
        elseif limit_type == LIMIT_TYPE.HIGH and ch_high_bad then
            msg = msg_high
        elseif limit_type == LIMIT_TYPE.LOW_HIGH then
            msg = ""
            msg = (ch_low_bad and not ch_high_bad) and msg_low or (msg)
            msg = (not ch_low_bad and ch_high_bad) and msg_high or (msg)
            msg = (ch_low_bad and ch_high_bad) and (msg_low .. ", " .. msg_high) or (msg)
        end
    end

    return msg
end

-- Проверка состояния канала аналогового значения при logic=LOGIC.ANALOG.
local function check_logic_analog_channels(internal_id, logic, event, msg, channel, get_limit_from_chan, limit_type, ch_low, ch_high)

    if check_logic_analog_channel(channel) then
        logic = LOGIC.EVENT
        event = true
        msg = check_logic_analog_channel(channel)
        msg = _DBG_PREF_MSG .. get_alarm_details_string(internal_id, msg) .. msg .. "."
    elseif get_limit_from_chan and check_logic_analog_limit_channels(limit_type, ch_low, ch_high) then
        logic = LOGIC.EVENT
        event = true
        msg = check_logic_analog_limit_channels(limit_type, ch_low, ch_high)
        msg = _DBG_PREF_MSG .. get_alarm_details_string(internal_id, msg) .. msg .. "."
    end

    return logic, event, msg
end

-- Получить значения пределов с каналов при logic=LOGIC.ANALOG.
local function get_logic_analog_limits(low, high, get_limit_from_chan, ch_low, ch_high)

    if get_limit_from_chan then
        low = getEstimate(ch_low)
        high = getEstimate(ch_high)
    end

    return low, high
end

-- Получить флаг тревоги.
local function get_event(id, logic, event, channel, discrete_val, limit_type, low, high, hyst_low, hyst_high, delay_on, delay_off, internal_id)

    if logic == LOGIC.EVENT then
        event = get_logic_event(event, delay_on, delay_off, internal_id)
    elseif logic == LOGIC.DISCRETE then
        event = get_logic_discrete(channel, discrete_val)
    elseif logic == LOGIC.ANALOG then
        event = get_logic_analog(id, channel, limit_type, low, high, hyst_low, hyst_high)
    end

    return event
end


-- Получить сообщение тревоги при LOGIC.ANALOG.
local function get_msg_analog(id, msg, channel, msg_detail, display_val, limit_type, limit_low, limit_high)
    -- local msg = alarm.msg

    if msg_detail then
        msg = msg .. ": '" .. channel .. "'"

        if display_val then
            msg = msg .. "(= " .. getEstimate(channel) .. ")"
        end

        if limit_type == LIMIT_TYPE.LOW then
            msg = msg .. " < " .. limit_low
        elseif limit_type == LIMIT_TYPE.HIGH then
            msg = msg .. " > " .. limit_high
        elseif limit_type == LIMIT_TYPE.LOW_HIGH and analog_low_high_last[id] == _LIMIT_STATE.low then
            msg = msg .. " < " .. limit_low
        elseif limit_type == LIMIT_TYPE.LOW_HIGH and analog_low_high_last[id] == _LIMIT_STATE.high then
            msg = msg .. " > " .. limit_high
        end
    end

    return msg
end


-- Получить сообщение тревоги.
local function get_msg(id, internal_id, logic, msg, channel, msg_detail, display_val, limit_type, limit_low, limit_high, display_id_at_msg)
    -- local msg = alarm.msg

    if logic == LOGIC.ANALOG then
        msg = get_msg_analog(id, msg, channel, msg_detail, display_val, limit_type, limit_low, limit_high)
    end

    if display_id_at_msg then
        msg = "[id" .. internal_id .. "] " .. msg
    end

    return msg
end


-- Создать каналы кнопок квитирования тревог для текущей таблицы.
local function create_acknow_btn_channels_for_current_table(tbl)
    if tbl.conf.ack_btn then
        local name = MODULE_NAME .. "." .. _TABLE_ID_PREFIX .. tbl.conf.table_id .. "." .. _ACK_BTN_NAME
        tbl._ack_btn = Btn_click:new(name, caller_path)
    end
end


-- Обновить менеджер тревог.
local function manager_update(alarm_list)
    --TODO Подумать убрать alarm_list? Так как ниже используется _alarm_list.
    -- Валидация списка тревог.
    assert(type(alarm_list) == "table", "Parameter 'alarm_list': expected 'table', got '"  .. type(alarm_list)  .. "'. ")

    -- Валидация параметров тревоги на правильно переданный тип (при отсутствии параметра присваивается значение по умолчанию).
    for id, alarm in ipairs(alarm_list) do
        assert(type(alarm) == "table", "Parameter 'alarm': expected 'table', got '"  .. type(alarm)  .. "'. ")
        _alarm_list[id].conf = check_config(alarm.conf, _alarm_config)
    end

    -- Получаем список всех каналов СИАМ.
    if not _siam_tag_names_list then
        _siam_tag_names_list = siam_wrapper.get_tag_names_list()
    end

    -- Обработка тревог.
    for id, alarm in ipairs(_alarm_list) do
        local internal_id = alarm.internal_id
        local logic = alarm.conf.logic
        local event = alarm.conf.event
        local aclass = alarm.conf.class
        local msg = alarm.conf.msg
        local prior = alarm.conf.prior
        local channel = alarm.conf.channel
        local msg_detail = alarm.conf.analog.msg_detail
        local display_val = alarm.conf.analog.display_val
        local get_limit_from_chan = alarm.conf.analog.get_limit_from_chan
        local limit_type = alarm.conf.limit_type
        local ch_low = alarm.conf.ch_low
        local ch_high = alarm.conf.ch_high
        local low = alarm.conf.low
        local high = alarm.conf.high
        local hyst_low = alarm.conf.hyst_low
        local hyst_high = alarm.conf.hyst_high
        local discrete_val = alarm.conf.discrete_val
        local cs_alarm_state = alarm.conf.cs_alarm_state
        local confirm_method = alarm.conf.confirm_method
        local cs_ack = alarm.conf.cs_ack
        local delay_on = math.max(alarm.conf.delay_on, alarm.tbl.alarm_delay_on)
        local delay_off = math.max(alarm.conf.delay_off, alarm.tbl.alarm_delay_off)
        local table_id = alarm.tbl.table_id
        local display_id_at_msg = alarm.tbl.display_id_at_msg
        local display_alarm_state_label = alarm.tbl.display_alarm_state_label

        --
        if not is_alarm_ack(internal_id, table_id) then
            is_ack[internal_id] = false
        end

        -- Валидация параметров тревоги на допустимые значения.
        for param, bounds in pairs(PARAM_BOUNDS) do
            bound_check(internal_id, msg, param, alarm.conf[param], bounds.bound_min, bounds.bound_max)
        end

        -- Валидация параметров тревоги на принадлежность перечисляемым типам.
        for param, enum in pairs(PARAM_ENUM) do
            param_enum_check(internal_id, msg, param, alarm.conf[param], enum)
        end

        -- Валидация значений уставок тревоги при LOGIC.ANALOG, LIMIT_TYPE.LOW_HIGH.
        limit_type_check(internal_id, msg, logic, limit_type, low, high)

        -- Валидация значений гистерезиса уставки при LOGIC.ANALOG.
        for _, hyst_type in ipairs(PARAM_HYST_TYPE) do
            hyst_check(internal_id, msg, hyst_type, alarm.conf[hyst_type])
        end

        if logic == LOGIC.ANALOG then
            -- Проверка имён каналов.
            channel_names_check(internal_id, alarm)

            logic, event, msg = check_logic_analog_channels(internal_id, logic, event, msg, channel, get_limit_from_chan, limit_type, ch_low, ch_high)

            -- Получить значения пределов.
            low, high = get_logic_analog_limits(low, high, get_limit_from_chan, ch_low, ch_high)
        end

        -- Получить флаг тревоги.
        event = get_event(id, logic, event, channel, discrete_val, limit_type, low, high, hyst_low, hyst_high, delay_on, delay_off, internal_id)

        -- 
        if event and _event_last[id] == false then
            _new_alarm_id = id
        end
        _event_last[id] = event

        -- Получаем сообщение тревоги.
        msg = get_msg(id, internal_id, logic, msg, channel, msg_detail, display_val, limit_type, low, high, display_id_at_msg)

        -- Установка тревог.
        if logic == LOGIC.CS_CLIENT then
            set_state(msg, id, table_id, aclass, prior, cs_alarm_state, cs_ack, internal_id, display_alarm_state_label)
        elseif confirm_method == CONFIRM_METHOD.REP  then
            set_rep(msg, id, table_id, event, aclass, logic, prior, display_val, internal_id)
        elseif confirm_method == CONFIRM_METHOD.REP_ACK then
            set_rep_ack(msg, id, table_id, event, aclass, logic, prior, display_val, internal_id, false, false, display_alarm_state_label)
        end

        alarm_qty_calc(internal_id, table_id, aclass)

    end

    for _, tbl in ipairs(_tables) do
        acknow_btn_upd(tbl)
    end

end


-- Проверить конфигурации таблиц.
local function check_tables_conf()
    for _, tbl in ipairs(_tables) do
        tbl.conf = check_config(tbl.conf, _table_config)
    end

end


local script_time_1  -- Время первого вызова скрипта.
local script_time_2  -- Время второго вызова скрипта.
-- Измерение периода вызывающего скрипта.
local function get_script_period()
    local script_period

    if script_time_1 and not script_time_2 then
        script_time_2 = getRecorderTime()
    end

    if not script_time_1 then
        script_time_1 = getRecorderTime()
    end

    if script_time_1 and script_time_2 then
        script_period = script_time_2 - script_time_1
    end

    return script_period
end


-- Обновление таймеров.
local function timers_upd()
    _blink_timer:calc(not _blink_timer.q, _blink_clk)
end


-- Получить имена каналов количества тревог.
local function get_alarm_qty_channels_(channels)
    local table_ids = {}

    for table_id, _ in pairs(_unique_tables) do
        table.insert(table_ids, table_id)
    end

    for _, chan in ipairs(get_alarm_qty_channels_list(table_ids)) do
        local channel = {}
        channel.name = chan.name
        channel.info = chan.info
        table.insert(channels, channel)
    end

    for _, chan in ipairs(get_alarm_qty_channels_list{_MAIN_TABLE_ID}) do
        local channel = {}
        channel.name = chan.name
        channel.info = chan.info
        table.insert(channels, channel)
    end

end


-- Создание каналов менеджера тревог в СИАМ.
local function create_channels()
    local channels = {}

    -- Получить имена каналов количества тревог.
    get_alarm_qty_channels_(channels)

    tags:CreateNewTags(channels, {pth_dir=caller_path})
end


-- Регистрация таблиц, созданных через new(), но ещё не добавленных
-- в _unique_tables/_tables. Вызывается в начале M:upd(), когда все
-- table_id уже установлены пользователем.
local function register_pending_tables()
    for _, tbl in ipairs(_pending_tables) do
        local table_id = tbl.conf.table_id

        if not _unique_tables[table_id] then
            _unique_tables[table_id] = tbl
            table.insert(_tables, tbl)
        else
            -- Таблица с таким table_id уже зарегистрирована.
            -- Добавляем ссылку на существующую.
            table.insert(_tables, _unique_tables[table_id])
        end
    end
    _pending_tables = {}
end


local is_channels_created = false  -- Каналы созданы?
-- Циклическое обновление менеджера тревог.
---@class upd
function M:upd()

    -- Получить путь до вызывающего скрипта для создания файла __CREATE_NEWTAGS__ рядом с ним.
    caller_path = module_utils.get_module_info(3).dir_path

    -- Обновление настройки цветов тревог.
    msg_color_upd()

    register_pending_tables()

    -- Проверка конфигурации таблиц.
    check_tables_conf()

    -- Первичная и циклическая инициализация менеджера тревог.
    cycle_init()

    -- Расчёт периода вызывающего скрипта.
    _SCRIPT_PERIOD = get_script_period()

    if _SCRIPT_PERIOD then
        _COLOR_QTY = _ALARM_FLASH_TIME / _SCRIPT_PERIOD
    end

    -- Создание каналов менеджера тревог.
    if not is_channels_created then
        is_channels_created = true
        create_channels()
    end

    -- Задержка работы менеджера тревог при старте скрипта.
    if manager_upd_delay:calc(true, 1) then

        -- Обновление таймеров.
        timers_upd()

        -- Обновляем состояние тревог, если список тревог не пустой.
        if #_alarm_list ~= 0 then
            manager_update(_alarm_list)
        end
    end

    -- Очищаем список тревог.
    _alarm_list = {}
end


-- Получить сквозной идентификационный номер тревоги.
local function get_next_alarm_id()
    local id = getenv_number(_ALARM_ID_COUNTER_VAR_NAME)

    if not id then
        assert(false,
            string.format("'%s' variable was not initialized.", _ALARM_ID_COUNTER_VAR_NAME))
    else
        id = id + 1
    end

    setenv(_ALARM_ID_COUNTER_VAR_NAME, id)

    return id
end


---Таблица тревог.
---@class Atable
local Atable = {}
---@private
Atable.__index = Atable


---@class AtableInstance : AtableConfig
local AtableInstance = {}
---@private
AtableInstance.__index = AtableInstance


--- Создать экземпляр таблицы тревог.
--- @param self Atable
--- @param config? AtableConfig Конфигурация таблицы тревог.
--- @return AtableInstance tbl_inst Созданный экземпляр таблицы тревог.
--- @raise string Если конфигурация не валидна.
--- @see AtableConfig Ссылка на таблицу с значениями по умолчанию.
function Atable:new(config)
    local public = check_config(config, _table_config)

    local _private = {
        _alarm_qty_channels = {},
        _unack_qty_channels = {},
        _ack_btn = nil,
        ack_cmd = false,
        reset = false,
    }

    local clk_upd = timers["Ton"]:new()

    setmetatable(public, AtableInstance)

    _private.conf = public

    -- Регистрация откладывается до manager_update.
    -- table_id может быть установлен после new().
    table.insert(_pending_tables, _private)

    return public
end


M.Atable = Atable


--- Регистрация тревоги в Менеджере тревог.
---
--- > ⚠️ **Не вызывайте метод внутри `if`!**
--- > Это может привести к остановке скрипта в рантайме
--- > при проверке переданных параметров.
---
--- @param self AtableInstance
--- @param config? AlarmConfig Настройки тревоги.
--- @return AlarmConfig alarm_inst Созданный экземпляр тревоги.
--- @raise string Если переданы несуществующие ключи.
--- @raise string Если переданы неверные типы значений.
--- @see AlarmConfig
--- @see LOGIC
--- @see ALARM_CLASS
--- @see LIMIT_TYPE
--- @see CS_ALARM_STATE
function AtableInstance:alarm(config)

    local public = config or _alarm_config

    local _private = {
        tbl = self,
        internal_id = get_next_alarm_id(),
    }

    if not ton[_private.internal_id] then
        ton[_private.internal_id] = timers["Ton"]:new()
    end

    if not tof[_private.internal_id] then
        tof[_private.internal_id] = timers["Tof"]:new()
    end

    _private.conf = public
    table.insert(_alarm_list, _private)

    return public
end


return M
