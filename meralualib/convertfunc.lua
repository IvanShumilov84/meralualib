--[[
-- Модуль конвертации величин.
--]]

local t = {}


do --  Функция конвертации real в bool.
    ---@param value number
    ---@return boolean
    function t.real_to_bool(value)
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        return value > 0
    end
end


do --  Функция конвертации bool в real.
    ---@param value boolean
    ---@return number
    function t.bool_to_real(value)
        assert(type(value) == "boolean", "Parameter 'value': expected 'boolean', got '" .. type(value) .. "'. ")
        return value and 1 or 0
    end
end


do --  Преобразование градусов Цельсия в градусы Фаренгейта.
    ---@param value number
    ---@return number
    function t.Celsius_to_Fahrenheit(value)
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        return 9 / 5 * value + 32
    end
end


do --  Преобразование градусов Цельсия в Кельвины.
    ---@param value number
    ---@return number
    function t.Celsius_to_Kelvin(value)
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        return value + 273.15
    end
end


do --  Преобразование Кельвинов в градусы Цельсия.
    ---@param value number
    ---@return number
    function t.Kelvin_to_Celsius(value)
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        return value - 273.15
    end
end


return t
