--[[
-- Отладочная библиотека.
]]

local M = {}


do --  Получить текущее значение канала по имени.
    ---@param name string
    ---@param value number|nil
    ---@return number
    function M.getValue(name, value)
        assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
        assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        local msg = value and "" or " by default"
        value = value or 0
        print("function getValue('" .. name .. "') return value" .. msg .. ": " ..  value)
        return value
    end
end


do --  Получить текущее значение канала по имени.
    ---@param name string
    ---@param value number|nil
    ---@return number value
    ---@return number time
    ---@return number status
    function M.getValueEx(name, value, time, status)
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
end


do  -- Выдать значение в канал по имени.
    ---@param name string
    ---@param value number
    ---@return number
    function M.setValue(name, value)
        assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        print("function setValue('" .. name .. "') record value to channel: '" .. name .. "' = " .. value)
        return value
    end
end


do  -- Выдать значение в канал по имени.
    ---@param name string
    ---@param value number
    ---@param time number
    ---@param status number
    ---@return number value
    ---@return number time
    ---@return number status
    function M.setValueEx(name, value, time, status)
        assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        print("function setValueEx('" .. name .. "') record to channel: '" .. name .. "' - value = " .. value .. ", time = " .. time .. ", status = " .. status)
        return value, time, status
    end
end


do  -- Получить текущее состояние ПО Recorder.
    ---@param value number|nil
    ---@return number
    function M.getRecorderStatus(value)
        assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        local msg = value and "" or " by default"
        value = value or 0
        print("function getRecorderStatus() return value" .. msg .. ": " ..  value)
        return value
    end
end


do  -- Выдать сообщение в лог.
    function M.luacpLogMessage(category, text, priority)
        print("function luacpLogMessage() return: category = " .. category .. ", text = " .. text .. ", priority = " .. priority)
    end
end


do  -- Удалить сообщение ПКПАС.
    function M.Delete_Alarm(msgid)
    end
end


do  -- Показать пользовательское (информационное) сообщение ПКПАС с цветом фона и приоритетом.
    function M.U_Alarm2(text, msgid, tableid, colorbkgr, priority)
        print("Функция U_Alarm2(): text = " .. text .. ", msgid = " .. msgid .. ", tableid = " .. tableid .. ", colorbkgr = "  .. colorbkgr .. ", priority = " .. priority)
    end
end


do  -- Изменение у пользовательского (информационного) сообщения ПКПАС текста, цвета фона и приоритета.
    function M.U_Alarm2_Change(text, msgid, tableid, colorbkgr, priority)
        print("Функция U_Alarm2(): text = " .. text .. ", msgid = " .. msgid .. ", tableid = " .. tableid .. ", colorbkgr = "  .. colorbkgr .. ", priority = " .. priority)
    end
end


return M
