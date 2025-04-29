-- [[
-- Библиотека для работы с коллекциями: словарь, список, ...
-- ]]

local M = {}


do --  Функция поиска ключа по значению в словаре.
    ---@param dict table Словарь.
    ---@param value number Искомое значение.
    ---@param default string Возвращаемый ключ в случае отсутствия искомого значения.
    ---@return string key Ключ искомого значения.
    function M.dict_find_key(dict, value, default)
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


do --  Функция поиска ключа по значению в словаре.
    ---@param dict table Словарь.
    ---@param value any Искомое значение.
    ---@return boolean is_value_exist Возвращает true, если значение существует.
    function M.dict_find_value(dict, value)
        assert(type(dict) == "table", "Parameter 'dict': expected 'table', got '" .. type(dict) .. "'. ")
        local is_value_exist = false
        for _, v in pairs(dict) do
            if v == value then
                is_value_exist = true
                break
            end
        end
        return is_value_exist
    end
end


do --  Функция расширения списка.
    ---@param list_1 table
    ---@param list_2 table
    ---@return table
    function M.list_extend(list_1, list_2)
        assert(type(list_1) == "table", "Parameter 'list_1': expected 'table', got '" .. type(list_1) .. "'. ")
        assert(type(list_2) == "table", "Parameter 'list_2': expected 'table', got '" .. type(list_2) .. "'. ")
        if not #list_2 then return list_1 end
        for _, v in ipairs(list_2) do table.insert(list_1, v) end
        return list_1
    end
end


do --  Функция расширения словаря.
    ---@param dict_1 table
    ---@param dict_2 table
    ---@return table
    function M.dict_extend(dict_1, dict_2)
        assert(type(dict_1) == "table", "Parameter 'dict_1': expected 'table', got '" .. type(dict_1) .. "'. ")
        assert(type(dict_2) == "table", "Parameter 'dict_2': expected 'table', got '" .. type(dict_2) .. "'. ")
        if not #dict_2 then return dict_1 end
        for k, v in pairs(dict_2) do
            dict_1[k] = v
        end
        return dict_1
    end
end


return M
