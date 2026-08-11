--[[
    Декораторы.
]]


-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."


local t = {}


---@param func function декорируемая функция.
---@param name_prefix string префикс к каналу.
---@param test_mode boolean режим тест.
---@return any
--- Декоратор функций getValue, getValueEx и getEstimate для выбора тестового канала вычитки данных.
function t.getValueSel(func, name_prefix, test_mode)
    assert(type(func) == "function", "Parameter 'func': expected 'function', got '" .. type(func) .. "'. ")
    assert(
        type(name_prefix) == "string",
        "Parameter 'name_prefix': expected 'string', got '" .. type(name_prefix) .. "'. "
    )
    assert(type(test_mode) == "boolean", "Parameter 'test_mode': expected 'boolean', got '" .. type(test_mode) .. "'. ")
    return function(...)
        local name, estimate = ...
        estimate = estimate or "m"
        name = test_mode and name_prefix .. name or name
        return func(name, estimate)
    end
end


---@param func function декорируемая функция.
---@param id number номер текущего имени.
---@return any
--- Декоратор функций getValue, getValueEx и getEstimate для выбора одного из нескольких каналов вычитки данных.
function t.getValueSel2(func, id)
    assert(type(func) == "function", "Parameter 'func': expected 'function', got '" .. type(func) .. "'. ")
    ---@param t_names table список каналов.
    --- Получить текущее значение канала по имени.
    return function(t_names)
        assert(type(t_names) == "table", "Parameter 't_names': expected 'table', got '" .. type(t_names) .. "'. ")
        assert(#t_names ~= nil, "Table 't_names' is empty. ")
        for _, v in ipairs(t_names) do
            assert(type(v)  == "string", "Parameter 't_names[v]': expected 'string', got '" .. type(v) .. "'. ")
        end
        assert(type(id) == "number", "Parameter 'id': expected 'number', got '" .. type(id) .. "'. ")
        assert(id > 0, "Parameter 'id' less than or equal to zero. ")
        assert(id <= #t_names, "Parameter 'id' greater than dimension of the table 't_names'. ")
        return func(t_names[id])
    end
end


---@param func function декорируемая функция.
---@param id number номер текущего значения.
---@return any
--- Декоратор функции setValue для выбора значения, которое выдается в канал.
function t.setValueSel(func, id)
    assert(type(func) == "function", "Parameter 'func': expected 'function', got '" .. type(func) .. "'. ")
    ---@param name string имя канала.
    ---@param t_values table список значений.
    --- Выдать значение в канал по имени.
    return function(name, t_values)
        assert(type(name) == "string", "Parameter 'name': expected 'string', got '" .. type(name) .. "'. ")
        assert(type(t_values) == "table", "Parameter 't_values': expected 'table', got '" .. type(t_values) .. "'. ")
        assert(#t_values ~= nil, "Table 't_values' is empty. ")
        local t_dim = 0  -- Размер таблицы.
        for _, v in ipairs(t_values) do
            assert(type(v)  == "number", "Parameter 't_values[v]': expected 'number', got '" .. type(v) .. "'. ")
            t_dim = t_dim + 1
        end
        assert(type(id) == "number", "Parameter 'id': expected 'number', got '" .. type(id) .. "'. ")
        assert(id > 0, "Parameter 'id' less than or equal to zero. ")
        assert(id <= t_dim, "Parameter 'id' greater than dimension of the table 't_values'. ")
        return func(name, t_values[id])
    end
end





return t
