--[[
    Менетжер тревог.
]]


local M = {}
local MODULE_NAME = "alarm_manager"


local def_pth = require("_script_path")
local pth = def_pth.script_path("..\\meralualib")
def_pth.lib_path(pth)

local Abs = require("meralualib\\Abs")
local collect = require("meralualib\\collect")
local list_extend = collect.list_extend
local dict_extend = collect.dict_extend
local dict_find_value = collect.dict_find_value

local datatype = require("meralualib\\datatype")
local SIAM_LOG_PRIOR = datatype.SIAM_LOG_PRIOR

local hmi = require("meralualib\\hmi")
local Btn_click = hmi["Btn_click"]

local tags = require("meralualib\\tags")


M.Amanager = {}  -- Класс Менеджер тревог (singleton).
M.Amanager.alloc_ = Abs:alloc_{maxinst = 1}


-- Создать экземпляр менеджера тревог.
function M.Amanager:new()

    local init = false  -- Флаг инициализации.
    -- TODO: Вложенные в список alarm_list аварии вместо списков сделать словарями.
    local alarm_list  -- Список ошибок формата {{<событие>:boolean, <тип ошибки>:string, <номер таблицы>:number, <сообщение об ошибке>:string}, ...}.
    local active_alarms = {}  -- Список активных аварийных сообщений формата {[msgid]=boolean, ...}.
    local unack_alarms = {}  -- Спосок активных неквитированных сообщений {[msgid]=boolean, ...}.
    local MSG_COLOR_UNACK = 0x00A6A6A6  -- Цвет фона неквитированных сообщений.
    local MSG_COLORS = {
        MSG_COLOR_ALARM = {
            0x00C3C7F9, 0x00BABEF8, 0x00B1B5F7, 0x00A7ADF6, 0x009EA4F5,
            0x00959BF4, 0x008C93F3, 0x00828AF2, 0x007981F1, 0x007079F0,
            0x006770EF, 0x005E67EE, 0x00545EED, 0x004B56EC, 0x00424CEB
        },
        MSG_COLOR_WARN = {
            0x008FCDFF, 0x0085C8FF, 0x007AC3FF, 0x0070BFFF, 0x0066BAFF,
            0x005CB6FF, 0x0052B1FF, 0x0047ACFF, 0x003DA8FF, 0x0033A3FF,
            0x00299FFF, 0x001F9AFF, 0x001495FF, 0x000A91FF, 0x00008BFF
        },
        MSG_COLOR_INFO = {
            0x00C1FFFF, 0x00B7FFFF, 0x00ADFFFF, 0x00A3FFFF, 0x0098FEFE,
            0x008EFEFE, 0x0084FEFE, 0x007AFEFE, 0x0070FEFE, 0x0066FEFE,
            0x005CFEFE, 0x0051FEFE, 0x0047FEFE, 0x003DFEFE, 0x0033FEFE
        }
    }
    local new_msg_color = {}  -- Список идентификаторов цветов при появлении нового сообщения.
    local chname_prefix  -- Префикс имён каналов в СИАМ.
    local create_channels_conf  -- Конфигурация создания каналов.
    local TABLE_ID_PREFIX = "table_id_"  -- Префикс к индексу таблиц в именах каналов.
    local ACK_BTN_NAME = "acknow"  -- Название кнопки квитирования аварий.
    local ALARM_QTY_NAME = "alarm_qty"
    local tables_items = {}  -- Сущности таблиц (кнопки квитирования, каналы количества аварий, ...) формата {[table_id] = {acknow_btn, alarm_qty}, ...}.
    local ALARM_TYPES = {  -- Типы аварийных сообщений.
        ALARM_ACK = "alarm_ack",  -- Авариное сообщение с квитированием.
        WARN_ACK = "warn_ack",  -- Предупредительное сообщение с квитированием.
        INFO_ACK = "info_ack",  -- Информационное сообщение с квитированием.
        ALL_ALARM = "all_alarm",  -- Все сообщения.
    }
    local UNACK_ALARM_TYPES = {  -- Типы неквитированных аварийных сообщений.
        UNACK_ALARM_ACK = "unack_alarm_ack",  -- Авариное сообщение с квитированием.
        UNACK_WARN_ACK = "unack_warn_ack",  -- Предупредительное сообщение с квитированием.
        UNACK_INFO_ACK = "unack_info_ack",  -- Информационное сообщение с квитированием.
        UNACK_ALL_ALARM = "unack_all_alarm",  -- Все сообщения.
    }
    local UNACK_ALARM_MATCHING = {
        [UNACK_ALARM_TYPES.UNACK_ALARM_ACK] = ALARM_TYPES.ALARM_ACK,
        [UNACK_ALARM_TYPES.UNACK_WARN_ACK] = ALARM_TYPES.WARN_ACK,
        [UNACK_ALARM_TYPES.UNACK_INFO_ACK] = ALARM_TYPES.INFO_ACK,
        [UNACK_ALARM_TYPES.UNACK_ALL_ALARM] = ALARM_TYPES.ALL_ALARM,
    }

    -- Публичные свойства.
    local obj = self.alloc_({
        ack_cmd = {},  -- Список значений триггеров квитирования сообщений для каждой аварийной таблицы.
        reset = false,  -- Триггер сброса аварий.
    })

    -- Установить сообщение.
    local function set_ack_msg(text_id, text_msg, msgid, tableid, event, msg_color, log_prior)
        if event and (not active_alarms[msgid] or unack_alarms[msgid]) then
            Delete_Alarm(msgid)
            active_alarms[msgid] = true
            unack_alarms[msgid] = false
            new_msg_color[msgid] = 1
            U_Alarm2(text_id  .. text_msg, msgid, tableid, MSG_COLORS[msg_color][new_msg_color[msgid]], log_prior)
        end
        if event and new_msg_color[msgid] < #MSG_COLORS[msg_color] then
            new_msg_color[msgid] = new_msg_color[msgid] + 1
            U_Alarm2_Change(text_id  .. text_msg, msgid, tableid, MSG_COLORS[msg_color][new_msg_color[msgid]], log_prior)
        end

        if not event and active_alarms[msgid] then
            Delete_Alarm(msgid)
            local text = text_id  .. "[Неактивна] " .. text_msg
            U_Alarm2(text, msgid, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY)
            active_alarms[msgid] = false
            unack_alarms[msgid] = true
        end
        if unack_alarms[msgid] and obj.ack_cmd[tableid] then
            Delete_Alarm(msgid)
            unack_alarms[msgid] = false
        end
        if obj.reset then
            Delete_Alarm(msgid)
            active_alarms[msgid] = false
            unack_alarms[msgid] = false
        end
    end

    -- Установить аварийное сообщение.
    local function set_alarm_ack_msg(text_id, text_msg, msgid, tableid, event)
        set_ack_msg(text_id, text_msg, msgid, tableid, event, "MSG_COLOR_ALARM", SIAM_LOG_PRIOR.ERROR)
    end

    -- Установить предупредительное сообщение.
    local function set_warn_ack_msg(text_id, text_msg, msgid, tableid, event)
        set_ack_msg(text_id, text_msg, msgid, tableid, event, "MSG_COLOR_WARN", SIAM_LOG_PRIOR.WARNING)
    end

    -- Установить информационное сообщение.
    local function set_info_ack_msg(text_id, text_msg, msgid, tableid, event)
        set_ack_msg(text_id, text_msg, msgid, tableid, event, "MSG_COLOR_INFO", SIAM_LOG_PRIOR.INFO)
    end

    -- Очистить все сообщения перед стартом работы менеджера тревог.
    local function clear_msgs(msg_qty)
        for msgid = 1, msg_qty do
            Delete_Alarm(msgid)
        end
        return true
    end

    -- Соответствие функций типам аварийных сообщений.
    local ALARM_FUNC = {
        [ALARM_TYPES.ALARM_ACK] = set_alarm_ack_msg,
        [ALARM_TYPES.WARN_ACK] = set_warn_ack_msg,
        [ALARM_TYPES.INFO_ACK] = set_info_ack_msg,
    }

    -- Получить количество аварий одного типа.
    local function get_alarm_qty_one_type(args)
        args = args or {}
        local alarm_type = args.alarm_type or nil
        local table_id = args.table_id or nil
        local alarms = args.alarms or {}
        local is_all_alarm = args.is_all_alarm or false
        local alarm_qty = 0

        for i = 1, #alarm_list do
            if alarms[i] and alarm_list[i][3] == table_id and (is_all_alarm and true or alarm_list[i][2] == alarm_type) then
                alarm_qty = alarm_qty + 1
            end
        end
        return alarm_qty
    end

    -- Создать каналы кнопок квитирования аварий.
    local function create_acknow_btn_channels()
        for _, table_id in ipairs(create_channels_conf.acknow_btn or {}) do
            if not tables_items[table_id] then tables_items[table_id] = {} end
            tables_items[table_id][ACK_BTN_NAME] = Btn_click:new(chname_prefix .. TABLE_ID_PREFIX .. table_id .. "." .. ACK_BTN_NAME)
        end
    end

    -- Обновление состояний кнопок квитирования аварий.
    local function acknow_btn_upd()
        for table_id, table in pairs(tables_items) do
           table[ACK_BTN_NAME]:upd()
           obj.ack_cmd[table_id] = table[ACK_BTN_NAME].q
        end
    end

    -- Создать каналы подсчёта аварий.
    local function create_alarm_qty_channels()
        local ALARM_TYPES_ = {}
        local channels = {}
        dict_extend(ALARM_TYPES_, ALARM_TYPES)
        dict_extend(ALARM_TYPES_, UNACK_ALARM_TYPES)
        for alarm_type, tables in pairs(create_channels_conf[ALARM_QTY_NAME] or {}) do
            for _, table_id in ipairs(tables) do
                if dict_find_value(ALARM_TYPES_, alarm_type) then
                    if not tables_items[table_id] then tables_items[table_id] = {} end
                    if not tables_items[table_id][ALARM_QTY_NAME] then tables_items[table_id][ALARM_QTY_NAME] = {} end
                    local name = chname_prefix .. TABLE_ID_PREFIX .. table_id .. "." .. ALARM_QTY_NAME .. "." .. alarm_type
                    tables_items[table_id][ALARM_QTY_NAME][alarm_type] = name
                    local channel = {}
                    channel.name = name
                    table.insert(channels, channel)
                end
            end
        end
        tags:CreateNewTags(channels)
    end

    -- Обновление количества аварий и выдача в каналы.
    local function alarm_qty_channels_upd()
        for table_id, table in pairs(tables_items) do
            if table[ALARM_QTY_NAME] then
                for alarm_type, chname in pairs(table[ALARM_QTY_NAME]) do
                    local alarms
                    local alarm_type_
                    local is_all_alarm
                    if dict_find_value(ALARM_TYPES, alarm_type) then
                        alarms = active_alarms
                        alarm_type_ = alarm_type
                        if alarm_type == ALARM_TYPES.ALL_ALARM then is_all_alarm = true end
                    elseif dict_find_value(UNACK_ALARM_TYPES, alarm_type) then
                        alarms = unack_alarms
                        alarm_type_ = UNACK_ALARM_MATCHING[alarm_type]
                        if alarm_type == UNACK_ALARM_TYPES.UNACK_ALL_ALARM then is_all_alarm = true end
                    end
                    local alarm_qty = get_alarm_qty_one_type{alarm_type=alarm_type_, table_id=table_id, alarms=alarms, is_all_alarm=is_all_alarm}
                    setValue(chname, alarm_qty)
                end
            end
        end
    end

    -- Циклическое обновление менеджера тревог.
    function obj:upd(alarms, reset)

        alarm_list = alarms
        init = init or clear_msgs(#alarms)
        obj.reset = reset

        for msgid, alarm in ipairs(alarms) do
            local event = alarm[1]
            local alarm_type = alarm[2]
            local tableid = alarm[3]
            local text_id = "[id" .. msgid .. "] "
            local text_msg = alarm[4]
            ALARM_FUNC[alarm_type](text_id, text_msg, msgid, tableid, event)
        end

        acknow_btn_upd()
        alarm_qty_channels_upd()
    end

    ---@class args
    ---@field create_channels_conf? table Создать каналы модуля для СИАМ.

    -- Инициализация менеджера тревог.
    function obj:init(args)
        args = args or {}
        create_channels_conf = args.create_channels_conf or {}
        chname_prefix = args.create_channels_conf.chname_prefix or ""
        chname_prefix = (chname_prefix == "") and MODULE_NAME or chname_prefix
        chname_prefix = chname_prefix .. "."

        create_acknow_btn_channels()
        create_alarm_qty_channels()
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end


return M
