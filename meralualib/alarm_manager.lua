--[[
    Менетжер тревог.
]]


local M = {}


def_pth = require("_script_path")
pth = def_pth.script_path("..\\meralualib")
def_pth.lib_path(pth)

local Abs = require("Abs")

local datatype = require("meralualib\\datatype")
local CH_NOT_READY = datatype.CH_NOT_READY
local CH_STATUS = datatype.CH_STATUS
local DATAST = datatype.DATAST
local SIAM_LOG_CAT = datatype.SIAM_LOG_CAT
local SIAM_LOG_PRIOR = datatype.SIAM_LOG_PRIOR
local UNKNOWN = datatype.UNKNOWN


M.Amanager = {}  -- Класс Менеджер тревог (singleton).
M.Amanager.alloc_ = Abs:alloc_{maxinst = 1}

-- Создать экземпляр менеджера тревог.
function M.Amanager:new()

    local init_upd = false  -- Флаг инициализации.
    local active_alarms = {}  -- Список активных аварийных сообщений.
    local unack_alarms = {}  -- Спосок активных неквитированных сообщений.
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

    -- Публичные свойства.
    local obj = self.alloc_({
        ack_cmd = {}  -- Список команд квитирования сообщений.
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
    end

    -- Типы сообщений.
    local ALARM_TYPES = {
        ["alarm_ack"] = set_alarm_ack_msg,  -- Авариное сообщение с квитированием.
        ["warn_ack"] = set_warn_ack_msg,  -- Предупредительное сообщение с квитированием.
        ["info_ack"] = set_info_ack_msg,  -- Информационное сообщение с квитированием.
    }

    -- Циклическое обновление менеджера тревог.
    function obj:upd(alarms)

        if not init_upd then
            init_upd = true
            clear_msgs(#alarms)
        end

        for msgid, alarm in ipairs(alarms) do
            local event = alarm[1]
            local alarm_type = alarm[2]
            local tableid = alarm[3]
            local text_id = "[id" .. msgid .. "] "
            local text_msg = alarm[4]

            ALARM_TYPES[alarm_type](text_id, text_msg, msgid, tableid, event)
        end
    end

    setmetatable(obj, self)
    self.__index = self
    return obj
end


return M
