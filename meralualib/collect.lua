-- [[
-- Библиотека для работы с коллекциями: словарь, список, ...
-- ]]

local t = {}


do --  Функция поиска ключа по значению в словаре.
    ---@param dict table Словарь.
    ---@param value number Искомое значение.
    ---@param default string Возвращаемый ключ в случае отсутствия искомого значения.
    ---@return string key Ключ искомого значения.
    function t.dict_find_key(dict, value, default)
        assert(type(dict) == "table", "Parameter 'dict': expected 'table', got '" .. type(dict) .. "'. ")
        assert(type(value) == "number", "Parameter 'value': expected 'number', got '" .. type(value) .. "'. ")
        assert(type(default) == "string", "Parameter 'default': expected 'string', got '" .. type(default) .. "'. ")
        local key
        key = default or key
        for k, v in pairs(dict) do
            if v == value then
                key = k
                break
            end
        end
        return key
    end
end


do --  Функция расширения списка.
    ---@param list_1 table
    ---@param list_2 table
    ---@return table
    function t.list_extend(list_1, list_2)
        assert(type(list_1) == "table", "Parameter 'list_1': expected 'table', got '" .. type(list_1) .. "'. ")
        assert(type(list_2) == "table", "Parameter 'list_2': expected 'table', got '" .. type(list_2) .. "'. ")
        if not #list_2 then return list_1 end
        for _, v in ipairs(list_2) do table.insert(list_1, v) end
        return list_1
    end
end


return t
