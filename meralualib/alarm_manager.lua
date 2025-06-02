--[[
    Менетжер тревог.
]]
-- TODO Добавить в свойство alarm_list.class значение warn_error.
-- TODO Добавить обработку logic.change.
-- TODO Добавить задержку обработки тревоги на время delay


local M = {}
local MODULE_NAME = "alarm_manager"


local def_pth = require("_script_path")
local pth = def_pth.script_path("..\\meralualib")
def_pth.lib_path(pth)

local Abs = require("meralualib\\Abs")
local collect = require("meralualib\\collect")
local dict_extend = collect.dict_extend
local dict_find_value = collect.dict_find_value

local datatype = require("meralualib\\datatype")
local SIAM_LOG_PRIOR = datatype.SIAM_LOG_PRIOR

local hmi = require("meralualib\\hmi")
local Btn_click = hmi["Btn_click"]

local tags = require("meralualib\\tags")

local timers = require("meralualib\\timers")
local Ton = timers["Ton"]


M.Amanager = {}  -- Класс Менеджер тревог (singleton).
M.Amanager.alloc_ = Abs:alloc_{maxinst = 1}


-- Создать экземпляр менеджера тревог.
function M.Amanager:new()

    local init = false  -- Флаг инициализации.
    local alarm_list  -- Список ошибок формата {{<событие>:boolean, <тип ошибки>:string, <номер таблицы>:number, <сообщение об ошибке>:string}, ...}.

    --[[
        alarm_list = {
            {
                class: ALARM_CLASS,  -- Класс тревоги.
                table_id: number,  -- Номер таблицы сообщения.
                logic: LOGIC,  -- Способ наблюдения за событием.
                event: boolean,  -- Состояние события при logic="event".
                channel: string,  -- Имя канала при logic="discrete"/"analog"/"change".
                limit_type: LIMIT_TYPE,  -- Типы ограничений logic="analog".
                low: number,  -- Значение нижнего предела при logic="analog", по умолчанию = 0.
                high: number,  -- Значение верхнего предела при logic="analog" по умолчанию = 0.
                discrete_val: number,  -- Значение предела для logic="discrete", по умолчанию = 0.
                msg: string,  -- Текст сообщения.
                hyst_low: number,  -- Значение гистерезиса для нижнего предела при logic="analog", по умолчанию = 0.
                hyst_high: number,  -- Значение гистерезиса для верхнего предела при logic="analog", по умолчанию = 0.
                ch_low: string,  -- Имя канала для значения нижнего предела при logic="analog".
                ch_high: string,  -- Имя канала для значения верхнего предела при logic="analog".
                confirm_method: CONFIRM_METHOD,  -- Способ подтверждения события.

                delay: number,  -- Время задержки обработки тревоги, секунды.
            },
            ...
        }
    ]]

    local active_alarms = {}  -- Список активных тревог формата {[msgid]=boolean, ...}.
    local unack_alarms = {}  -- Спосок неквитированных тревог {[msgid]=boolean, ...}.
    local MSG_COLOR_UNACK = 0x00A6A6A6  -- Цвет фона неквитированных тревог.
    local COLOR_QTY = 15
    local get_msg_color = {}  -- Список генераторов цвета для каждой тревоги для эффекта вспышки во время появления тревог.
    local module_name  -- Имя модуля, для которого создаются каналы Менеджера тревог.
    local chname_prefix  -- Префикс имён каналов в СИАМ.
    local create_channels_conf  -- Конфигурация создания каналов.
    local TABLE_ID_PREFIX = "table_id_"  -- Префикс к индексу таблиц в именах каналов.
    local ACK_BTN_NAME = "acknow"  -- Название кнопки квитирования аварий.
    local ALARM_QTY_NAME = "alarm_qty"  -- Часть имени каналов количества ошибок.
    local tables_items = {}  -- Сущности таблиц (кнопки квитирования, каналы количества тревог, ...) формата {[table_id] = {acknow_btn, alarm_qty}, ...}.
    local analog_low_high = {}  -- Список состояний сработки сообщений вида: {[msgid] = "norm"/"low"/"high", ...}
    local analog_low_high_last = {}  -- Список последних состояний сработки сообщений вида: {[msgid] = "low"/"high", ...}
    local display_analog_val = false
    local cur_analog_val = ""
    local LOGIC = {  -- Способ наблюдения за событием.
        discrete = "discrete",  -- Событие дискретное: ноль/отличное от ноля.
        analog = "analog",  -- Событие аналоговое.
        change = "change",  -- Обрабатывается любое изменение события.
        event = "event",  -- Событие имеет значения true/false.
    }
    local LIMIT_TYPE = {  -- Типы ограничений при обработке аналогового события.
        low = "low",  -- Событие ограничено значением снизу.
        high = "high",  -- Событие ограничено значением сверху.
        low_high = "low_high",  -- Событие ограничено значениями снизу и сверху.
    }
    local limit_state = {  -- Состояние событий по ограничениям при обработке аналогового события.
        norm = "norm",  -- Событие в допуске.
        low = "low",  -- Событие по ограничению снизу.
        high = "high",  -- Событие по ограничению сверху.
    }
    local ALARM_STATUS = {  -- Статусы тревоги.
        ACTIVE = 0,  -- Активная.
        NOT_ACTIVE = 1,  -- Неактивная.
        ACK = 2,  -- Квитированная.
    }
    local ALARM_CLASS = {  -- Классы тревог.
        error = "error",  -- Ошибка.
        warn = "warn",  -- Предупреждение.
        info = "info",  -- Информирование.
        all_alarm = "all_alarm",  -- Все сообщения.
    }
    local ALARM_CLASS_CONFIG = {  -- Настройки классов тревог.
        [ALARM_CLASS.error] = {log_prior = SIAM_LOG_PRIOR.ERROR},
        [ALARM_CLASS.warn] = {log_prior = SIAM_LOG_PRIOR.WARNING},
        [ALARM_CLASS.info] = {log_prior = SIAM_LOG_PRIOR.INFO},
    }
    local UNACK_NAME = "_unack"
    local UNACK_ALARM_NAMES = {  -- Имена каналов СИАМ количества неквитированных тревог.
        ERROR = "error" .. UNACK_NAME,  -- Авариное сообщение с квитированием.
        WARN = "warn" .. UNACK_NAME,  -- Предупредительное сообщение с квитированием.
        INFO = "info" .. UNACK_NAME,  -- Информационное сообщение с квитированием.
        ALL_ALARM = "all_alarm" .. UNACK_NAME,  -- Все сообщения.
    }
    local UNACK_ALARM_MATCHING = {
        [UNACK_ALARM_NAMES.ERROR] = ALARM_CLASS.error,
        [UNACK_ALARM_NAMES.WARN] = ALARM_CLASS.warn,
        [UNACK_ALARM_NAMES.INFO] = ALARM_CLASS.info,
        [UNACK_ALARM_NAMES.ALL_ALARM] = ALARM_CLASS.all_alarm,
    }
    local MSG_COLOR = {  -- Цвета тревог по классам.
        [ALARM_CLASS.error] = 0x00424CEB,  -- Цвет "Carmine Pink".
        [ALARM_CLASS.warn] = 0x00008BFF,  -- Цвет "American Orange".
        [ALARM_CLASS.info] = 0x0033FEFE,  -- Цвет "Yellow (RYB)"
    }

    -- Публичные свойства.
    local obj = self.alloc_({
        ack_cmd = {},  -- Список значений триггеров квитирования сообщений для каждой аварийной таблицы.
        reset = false,  -- Триггер сброса аварий.
    })

    local clk_upd = Ton:new()

    -- Функция получения итератора для генерации цвета от белого до базового.
    local function get_color_iter(base_color, max_steps)
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

    -- Установить тревогу со способом подтверждения: CONFIRM_METHOD.rep_ack.
    local function set_rep_ack(text_msg, msgid, tableid, event, alarm_type, logic)
        local msg_color
        local text_inactive = "[Неактивна] " .. text_msg
        local log_prior = ALARM_CLASS_CONFIG[alarm_type].log_prior
        if event and (not active_alarms[msgid] or unack_alarms[msgid]) then
            Delete_Alarm(msgid)
            active_alarms[msgid] = true
            unack_alarms[msgid] = false
            get_msg_color[msgid] = get_color_iter(MSG_COLOR[alarm_type], COLOR_QTY)
            msg_color = get_msg_color[msgid]()
            U_Alarm2(text_msg, msgid, tableid, msg_color, log_prior)
        end

        msg_color = get_msg_color[msgid] and get_msg_color[msgid]() or nil
        if event and msg_color ~= nil then
            U_Alarm2_Change(text_msg, msgid, tableid, msg_color, log_prior, ALARM_STATUS.ACTIVE)
        end

        if not event and active_alarms[msgid] then
            Delete_Alarm(msgid)
            U_Alarm2(text_inactive, msgid, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY)
            U_Alarm2_Change(text_inactive, msgid, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, ALARM_STATUS.NOT_ACTIVE)
            active_alarms[msgid] = false
        end

        if unack_alarms[msgid] and obj.ack_cmd[tableid] then
            Delete_Alarm(msgid)
        end

        if obj.reset then
            -- Delete_Alarm(msgid)
            U_Alarm2_Change(text_inactive, msgid, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, ALARM_STATUS.ACK)
            active_alarms[msgid] = false
        end

        if logic == LOGIC.analog and active_alarms[msgid] and msg_color == nil and display_analog_val then
            U_Alarm2_Change(text_msg, msgid, tableid, MSG_COLOR[alarm_type], log_prior, ALARM_STATUS.ACTIVE)
        end

        if logic == LOGIC.analog and unack_alarms[msgid] and display_analog_val then
            U_Alarm2_Change(text_inactive, msgid, tableid, MSG_COLOR_UNACK, SIAM_LOG_PRIOR.NOTIFY, ALARM_STATUS.NOT_ACTIVE)
        end
    end

    -- Способы подтверждения тревог.
    local CONFIRM_METHOD = {
        rep_ack = "rep_ack",  -- Квитирование деактивированной тревоги.
    }

    -- Соответствие способа подтверждения тревоги вызываемой функции для обработки тревоги.
    local CONFIRM_METHOD_FUNC = {
        [CONFIRM_METHOD.rep_ack] = set_rep_ack,
    }

    -- Очистить все сообщения перед стартом работы менеджера тревог.
    local function clear_msgs(msg_qty)
        for msgid = 1, msg_qty do
            Delete_Alarm(msgid)
        end
        return true
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
        dict_extend(ALARM_TYPES_, ALARM_CLASS)
        dict_extend(ALARM_TYPES_, UNACK_ALARM_NAMES)
        for alarm_type, tables in pairs(create_channels_conf[ALARM_QTY_NAME] or {}) do
            for _, table_id in ipairs(tables) do
                if dict_find_value(ALARM_TYPES_, alarm_type) then
                    if not tables_items[table_id] then tables_items[table_id] = {} end
                    if not tables_items[table_id][ALARM_QTY_NAME] then tables_items[table_id][ALARM_QTY_NAME] = {} end
                    local name = chname_prefix .. TABLE_ID_PREFIX .. table_id .. "." .. ALARM_QTY_NAME .. "." .. alarm_type
                    tables_items[table_id][ALARM_QTY_NAME][alarm_type] = name
                    local channel = {}
                    channel.name = name
                    channel.info = "Менеджер тревог: таблица №" .. table_id .. ", канал количества ошибок класса '" .. alarm_type .. "' [модуль '" .. module_name .. "']."
                    table.insert(channels, channel)
                end
            end
        end
        tags:CreateNewTags(channels)
    end

    -- Получить количество аварий одного типа.
    local function get_alarm_qty_one_type(args)
        args = args or {}
        local alarm_type = args.alarm_type or nil
        local table_id = args.table_id or nil
        local alarms = args.alarms or {}
        local is_all_alarm = args.is_all_alarm or false
        local alarm_qty = 0

        for i = 1, #alarm_list do
            if alarms[i] and alarm_list[i].table_id == table_id and (is_all_alarm and true or alarm_list[i].class == alarm_type) then
                alarm_qty = alarm_qty + 1
            end
        end
        return alarm_qty
    end

    -- Обновление количества аварий и выдача в каналы СИАМ.
    local function alarm_qty_channels_upd()
        for table_id, table in pairs(tables_items) do
            if table[ALARM_QTY_NAME] then
                for alarm_type, chname in pairs(table[ALARM_QTY_NAME]) do
                    local alarms
                    local alarm_type_
                    local is_all_alarm
                    if dict_find_value(ALARM_CLASS, alarm_type) then
                        alarms = active_alarms
                        alarm_type_ = alarm_type
                        if alarm_type == ALARM_CLASS.all_alarm then is_all_alarm = true end
                    elseif dict_find_value(UNACK_ALARM_NAMES, alarm_type) then
                        alarms = unack_alarms
                        alarm_type_ = UNACK_ALARM_MATCHING[alarm_type]
                        if alarm_type == UNACK_ALARM_NAMES.ALL_ALARM then is_all_alarm = true end
                    end
                    local alarm_qty = get_alarm_qty_one_type{alarm_type=alarm_type_, table_id=table_id, alarms=alarms, is_all_alarm=is_all_alarm}
                    setValue(chname, alarm_qty)
                end
            end
        end
    end

    -- Получить состояние тревоги.
    local function get_event(args)
        local msgid = args.msgid
        local logic = args.logic or ""
        local event = args.event or false
        local channel = args.channel or ""
        local limit_type = args.limit_type or ""
        local low = args.low or 0
        local high = args.high or 0
        local discrete_val = args.discrete_val or 0
        local hyst_low = args.hyst_low or 0
        local hyst_high = args.hyst_high or 0

        local event_ = false
        if logic == LOGIC.event then
            event_ = event
        elseif logic == LOGIC.discrete then
            event_ = getValue(channel) > discrete_val
        elseif logic == LOGIC.analog then
            if limit_type == LIMIT_TYPE.low then
                if getValue(channel) < low or (analog_low_high[msgid] == limit_state.low and getValue(channel) < low + hyst_low) then
                    analog_low_high[msgid] = limit_state.low
                    event_ = true
                else
                    analog_low_high[msgid] = limit_state.norm
                end
            elseif limit_type == LIMIT_TYPE.high then
                if getValue(channel) > high or (analog_low_high[msgid] == limit_state.high and getValue(channel) > high - hyst_high) then
                    analog_low_high[msgid] = limit_state.high
                    event_ = true
                else
                    analog_low_high[msgid] = limit_state.norm
                end
            elseif limit_type == LIMIT_TYPE.low_high then
                if (getValue(channel) < low and analog_low_high[msgid] == limit_state.high) then
                    analog_low_high[msgid] = limit_state.low
                elseif(getValue(channel) > high and analog_low_high[msgid] == limit_state.low) then
                    analog_low_high[msgid] = limit_state.high
                elseif getValue(channel) < low or (analog_low_high[msgid] == limit_state.low and getValue(channel) < low + hyst_low) then
                    analog_low_high[msgid] = limit_state.low
                    analog_low_high_last[msgid] = analog_low_high[msgid]
                    event_ = true
                elseif getValue(channel) > high or (analog_low_high[msgid] == limit_state.high and getValue(channel) > high - hyst_high) then
                    analog_low_high[msgid] = limit_state.high
                    analog_low_high_last[msgid] = analog_low_high[msgid]
                    event_ = true
                else
                    analog_low_high[msgid] = limit_state.norm
                end
            end
        end
        return event_
    end

    -- Обновление отображения тревог в Менеджере тревог.
    local function alarm_upd()
        for msgid, alarm in ipairs(alarm_list) do
            local logic = alarm.logic or ""
            local channel = alarm.channel or ""
            local event = alarm.event or false
            local alarm_type = alarm.class or ""
            local confirm_method = alarm.confirm_method or CONFIRM_METHOD.rep_ack
            local tableid = alarm.table_id or -1
            local text_msg = alarm.msg or ""
            local limit_type = alarm.limit_type or ""
            local low = alarm.low or 0
            local high = alarm.high or 0
            local ch_low = alarm.ch_low or ""
            local ch_high = alarm.ch_high or ""
            local discrete_val = alarm.discrete_val or 0
            local hyst_low = alarm.hyst_low or 0
            local hyst_high = alarm.hyst_high or 0

            local ch_low_value, ch_low_status
            ch_low_value, _, ch_low_status = getEstimate(ch_low)
            low = ch_low_status == 0 and ch_low_value or low

            local ch_high_value, ch_high_status
            ch_high_value, _, ch_high_status = getEstimate(ch_high)
            high = ch_high_status == 0 and ch_high_value or high

            if limit_type == LIMIT_TYPE.low_high and (high < low) then
                low, high = 0, 0
            end
            hyst_low = hyst_low < 0 and 0 or hyst_low
            hyst_high = hyst_high < 0 and 0 or hyst_high

            event = get_event{
                msgid=msgid, logic=logic, event=event, channel=channel, limit_type=limit_type, low=low, high=high,
                discrete_val=discrete_val, hyst_low=hyst_low, hyst_high=hyst_high
            }

            local analog_text = ""  -- Тескт при выводе аналоговой тревоги.
            if logic == LOGIC.analog then
                cur_analog_val = ""
                if display_analog_val then
                    cur_analog_val = "(" .. getEstimate(channel) .. ")"
                end
                analog_text = ": '" .. channel .. "'" .. cur_analog_val
                if limit_type == LIMIT_TYPE.low then
                    analog_text = analog_text .. " < " .. low
                elseif limit_type == LIMIT_TYPE.high then
                    analog_text = analog_text .. " > " .. high
                elseif limit_type == LIMIT_TYPE.low_high and analog_low_high_last[msgid] == limit_state.low then
                    analog_text = analog_text .. " < " .. low
                elseif limit_type == LIMIT_TYPE.low_high and analog_low_high_last[msgid] == limit_state.high then
                    analog_text = analog_text .. " > " .. high
                end
            end

            local text = {  -- Шаблон для вывода текста тревоги.
                id = "[id" .. msgid .. "] ",
                msg = text_msg,
                analog_text = analog_text
            }
            text_msg = text.id .. text.msg .. text.analog_text

            if U_Alarm2_GetStatus(msgid, tableid) == ALARM_STATUS.NOT_ACTIVE then
                unack_alarms[msgid] = true
            else
                unack_alarms[msgid] = false
            end

            CONFIRM_METHOD_FUNC[confirm_method](text_msg, msgid, tableid, event, alarm_type, logic)

        end
    end

    -- Циклическое обновление менеджера тревог.
    function obj:upd(alarms, reset)

        alarm_list = alarms
        init = init or clear_msgs(#alarm_list)
        obj.reset = reset

        alarm_upd()
        acknow_btn_upd()
        alarm_qty_channels_upd()
    end

    ---@class args
    ---@field create_channels_conf? table Создать каналы модуля для СИАМ.

    -- Инициализация менеджера тревог.
    function obj:init(args)
        args = args or {}
        display_analog_val = args.display_analog_val or display_analog_val
        create_channels_conf = args.create_channels_conf or {}
        chname_prefix = args.create_channels_conf.chname_prefix or ""
        chname_prefix = (chname_prefix == "") and MODULE_NAME or chname_prefix
        chname_prefix = chname_prefix .. "."
        module_name = args.create_channels_conf.module_name or ""
        module_name = (module_name == "") and MODULE_NAME or module_name

        create_acknow_btn_channels()
        create_alarm_qty_channels()
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end


return M
