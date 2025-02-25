--[[
-- Отладочная библиотека.
]]

local t = {}


do --  Получить текущее значение канала по имени.
    ---@param name string
    ---@param value number
    ---@return number
    function t.getValue(name, value)
        assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
        assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        local msg = value and "" or " by default"
        value = value or 0
        print("function getValue('" .. name .. "') return value" .. msg .. ": " ..  value)
        return value
    end
end


do --  Выдать значение в канал по имени.
    ---@param name string
    ---@param value number
    ---@return number
    function t.setValue(name, value)
        assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        print("function setValue('" .. name .. "') record value to channel: '" .. name .. "' = " .. value)
        return value
    end
end


do --  Получить текущее состояние ПО Recorder
    ---@param value number
    ---@return number
    function t.getRecorderStatus(value)
        assert(value == nil or type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        local msg = value and "" or " by default"
        value = value or 0
        print("function getRecorderStatus() return value" .. msg .. ": " ..  value)
        return value
    end
end

return t
