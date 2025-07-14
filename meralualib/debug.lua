--[[
    Отладочная библиотека.
]]


local M = {}
local L = {}


-- Замещение API СИАМ функций тестовыми для отладки в IDE.
function M.replace_siam_funcs()
    for k, v in pairs(L) do
        _ENV[k] = v
    end
end


-- Получить текущее значение канала по имени.
---@param name string
---@param value number|nil
---@return number
function L.getValue(name, value)
    assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
    assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
    local msg = value and "" or " by default"
    value = value or 0
    print("function getValue('" .. name .. "') return value" .. msg .. ": " ..  value)
    return value
end


-- Получить текущее значение канала по имени.
---@param name string
---@param value number|nil
---@return number value
---@return number time
---@return number status
function L.getValueEx(name, value, time, status)
    assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
    assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
    assert(time == nil or type(time) == "number", "Parameter 'time': expected 'number', got '" .. type(time) .. "'. ")
    assert(status == nil or type(status) == "number", "Parameter 'status': expected 'number', got '" .. type(status) .. "'. ")
    local msg_v = value and "" or " by default"
    local msg_t = time and "" or " by default"
    local msg_s = status and "" or " by default"
    value = value or 0
    time = time or 0
    status = status or 0
    print("function getValueEx('" .. name .. "') return value" .. msg_v .. " = " ..  value .. ", time" .. msg_t .. " = " .. time .. ", status" .. msg_s .. " = " .. status)
    return value, time, status
end


-- Получить оценку значения канала по имени.
---@param name string
---@param estimate string
---@param value number|nil
---@return number value
---@return number time
---@return number status
function L.getEstimate(name, estimate, value, time, status)
    assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
    assert(estimate == nil or type(estimate) == "string", "Parameter 'estimate': expected 'string', got '" .. type(estimate) .. "'. ")
    assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
    assert(time == nil or type(time) == "number", "Parameter 'time': expected 'number', got '" .. type(time) .. "'. ")
    assert(status == nil or type(status) == "number", "Parameter 'status': expected 'number', got '" .. type(status) .. "'. ")
    local msg_v = value and "" or " by default"
    local msg_t = time and "" or " by default"
    local msg_s = status and "" or " by default"
    value = value or 0
    time = time or 0
    status = status or 0
    print("function getEstimate('" .. name .. "') return value" .. msg_v .. " = " ..  value .. ", time" .. msg_t .. " = " .. time .. ", status" .. msg_s .. " = " .. status)
    return value, time, status
end


-- Выдать значение в канал по имени.
---@param name string
---@param value number
---@return number
function L.setValue(name, value)
    assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
    assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
    print("function setValue('" .. name .. "') record value to channel: '" .. name .. "' = " .. value)
    return value
end


-- Выдать значение в канал по имени.
---@param name string
---@param value number
---@param time number
---@param status number
---@return number value
---@return number time
---@return number status
function L.setValueEx(name, value, time, status)
    assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
    assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
    print("function setValueEx('" .. name .. "') record to channel: '" .. name .. "' - value = " .. value .. ", time = " .. time .. ", status = " .. status)
    return value, time, status
end


-- Получить текущее состояние ПО Recorder.
---@param value number|nil
---@return number
function L.getRecorderStatus(value)
    assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
    local msg = value and "" or " by default"
    value = value or 0
    print("function getRecorderStatus() return value" .. msg .. ": " ..  value)
    return value
end


-- Выдать сообщение в лог.
function L.luacpLogMessage(category, text, priority)
    print("function luacpLogMessage() return: category = " .. category .. ", text = " .. text .. ", priority = " .. priority)
end


-- Удалить сообщение ПКПАС.
function L.Delete_Alarm(msgid)
end


-- Показать пользовательское (информационное) сообщение ПКПАС с цветом фона и приоритетом.
function L.U_Alarm2(text, msgid, tableid, colorbkgr, priority)
    print("function U_Alarm2(): text = " .. text .. ", msgid = " .. msgid .. ", tableid = " .. tableid .. ", colorbkgr = "  .. colorbkgr .. ", priority = " .. priority)
end


-- Изменение у пользовательского (информационного) сообщения ПКПАС текста, цвета фона и приоритета.
function L.U_Alarm2_Change(text, msgid, tableid, colorbkgr, priority)
    print("function U_Alarm2(): text = " .. text .. ", msgid = " .. msgid .. ", tableid = " .. tableid .. ", colorbkgr = "  .. colorbkgr .. ", priority = " .. priority)
end


-- Получение статуса сообщения.
function L.U_Alarm2_GetStatus(msgid, tableid)
    print("function U_Alarm2_GetStatius(): msgid = " .. msgid .. ", tableid = " .. tableid)
end


return M
