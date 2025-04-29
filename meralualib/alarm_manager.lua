--[[
    Менетжер тревог.
]]


local M = {}
local MODULE_NAME = "amanager"


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

local tags = require("meralualib\\tags")


M.Amanager = {}  -- Класс Менеджер тревог (singleton).
M.Amanager.alloc_ = Abs:alloc_{maxinst = 1}


-- Создать экземпляр менеджера тревог.
function M.Amanager:new()

    local init = false  -- Флаг инициализации.
    local alarm_list  -- Список ошибок формата {[msgid]={<событие>:boolean, <тип ошибки>:string, <номер таблицы>:number, <сообщение об ошибке>:string}, ...}.
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
    local modulename  -- Имя модуля для создания каналов в СИАМ.
    local alarm_qty_table  -- Словарь списков таблиц, для которых делать подсчёт ошибок.
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

    -- Получить имя канала-счётчика аварий определённого типа.
    local function get_alarm_qty_channel_name(args)
        local alarm_type = args.alarm_type
        local table_id = args.table_id
        return modulename .. ".table_id_" .. table_id .. "." .. alarm_type .. "_qty"
    end

    -- Получить имя канала-счётчика всех аварий.
    local function get_all_alarm_qty_channel_name(args)
        local table_id = args.table_id
        return modulename .. ".table_id_" .. table_id .. "." .. ALARM_TYPES.ALL_ALARM .. "_qty"
    end

    -- Получить имя канала-счётчика всех неквитированных аварий.
    local function get_unack_all_alarm_qty_channel_name(args)
        local table_id = args.table_id
        return modulename .. ".table_id_" .. table_id .. "." .. UNACK_ALARM_TYPES.UNACK_ALL_ALARM .. "_qty"
    end

    -- Получить список имен каналов-счётчиков аварий.
    local function get_alarm_qty_channel_names(args)
        local channels = {}
        local ALARM_TYPES_ = {}
        dict_extend(ALARM_TYPES_, ALARM_TYPES)
        dict_extend(ALARM_TYPES_, UNACK_ALARM_TYPES)

        for _, alarm_type in pairs(ALARM_TYPES_) do
            local tables = args[alarm_type] or {}
            for table_id in ipairs(tables) do
                local chan = {}
                chan.name = get_alarm_qty_channel_name{alarm_type = alarm_type, table_id = table_id}
                table.insert(channels, chan)
            end
        end
        return channels
    end

    -- Получить количество аварий одного типа.
    local function get_alarm_qty_one_type(args)
        local alarm_type = args.alarm_type
        local table_id = args.table_id
        local alarms = args.alarms
        local alarm_qty = 0

        for i = 1, #alarm_list do
            if alarms[i] and alarm_list[i][3] == table_id and alarm_list[i][2] == alarm_type then
                alarm_qty = alarm_qty + 1
            end
        end
        return alarm_qty
    end

    -- Получить количество всех аварий.
    local function get_all_alarm_qty(args)
        local table_id = args.table_id
        local alarm_qty = 0

        for i = 1, #alarm_list do
            if active_alarms[i] and alarm_list[i][3] == table_id then
                alarm_qty = alarm_qty + 1
            end
        end
        return alarm_qty
    end

    -- Получить количество всех неквитированных аварий.
    local function get_unack_all_alarm_qty(args)
        local table_id = args.table_id
        local alarm_qty = 0

        for i = 1, #alarm_list do
            if unack_alarms[i] and alarm_list[i][3] == table_id then
                alarm_qty = alarm_qty + 1
            end
        end
        return alarm_qty
    end

    -- Записать в каналы СИАМ количество аварий.
    local function set_alarms_qty(args)
        local ALARM_TYPES_ = {}
        dict_extend(ALARM_TYPES_, ALARM_TYPES)
        dict_extend(ALARM_TYPES_, UNACK_ALARM_TYPES)
        local alarm_type_

        for _, alarm_type in pairs(ALARM_TYPES_) do
            local alarms = {}
            if dict_find_value(ALARM_TYPES, alarm_type) then
                alarms = active_alarms
                alarm_type_ = alarm_type
            elseif dict_find_value(UNACK_ALARM_TYPES, alarm_type) then
                alarms = unack_alarms
                alarm_type_ = UNACK_ALARM_MATCHING[alarm_type]
            end
            local tables = args[alarm_type] or {}
            for table_id in ipairs(tables) do
                local chan_name = get_alarm_qty_channel_name{alarm_type = alarm_type, table_id = table_id}
                local alarm_qty = get_alarm_qty_one_type{alarm_type = alarm_type_, table_id = table_id, alarms = alarms}
                setValue(chan_name, alarm_qty)

                chan_name = get_all_alarm_qty_channel_name{table_id = table_id}
                alarm_qty = get_all_alarm_qty{table_id = table_id}
                setValue(chan_name, alarm_qty)

                chan_name = get_unack_all_alarm_qty_channel_name{table_id = table_id}
                alarm_qty = get_unack_all_alarm_qty{table_id = table_id}
                setValue(chan_name, alarm_qty)
            end
        end
    end

    -- Создать каналы в СИАМ.
    local function create_channels(args)
        local alarm_qty = args.alarm_qty
        local channels = {}
        list_extend(channels, get_alarm_qty_channel_names(alarm_qty))
        tags:CreateNewTags(channels)
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

        set_alarms_qty(alarm_qty_table)
    end

    ---@class args
    ---@field create_channels? table Создать каналы модуля для СИАМ.
    ---@field modulename? string Имя модуля для создания каналов в СИАМ.

    function obj:init(args)
        local create_channels_ = args.create_channels
        modulename = args.modulename or MODULE_NAME

        alarm_qty_table = create_channels_.alarm_qty
        create_channels(create_channels_)
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end




return M
