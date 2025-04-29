--[[
    Математические функции.
]]


local M = {}


local datatype = require("meralualib\\datatype")
local DATAST = datatype.DATAST


---@param t_values table таблица со значениями для усреднения.
---@return number avg Среднее значений таблицы на входе.
---@return number status Статус выполнения функции.
--- Расчёт среднего значения.
function M.avg(t_values)
    assert(type(t_values) == "table", "Parameter 't_values': expected 'table', got '" .. type(t_values) .. "'. ")
    assert(#t_values ~= nil, "Table 't_values' is empty. ")
    local status = 0
    local avg = 0
    for _, v in ipairs(t_values) do
        avg = avg + v
    end
    return avg / #t_values, status
end


do  --- Расчёт среднего значения.
    M.avg_2 = {name = "avg_2"}
    local mt = {}
    setmetatable(M.avg_2, mt)

    ---@param ... table Аргументы для усреднения.
    ---@return {results: {result_1: number}, status: {status: string, msg: string}} ret avg Среднее значений таблицы на входе.
    --- Расчёт среднего значения.
    mt.__call = function(...)
        local t_values = {...}
        assert(type(t_values) == "table", "Parameter 't_values': expected 'table', got '" .. type(t_values) .. "'. ")
        assert(#t_values ~= nil, "Table 't_values' is empty. ")
        local ret = {}  -- Возвращаемое функцией значение.
        local results = {}  -- Результаты расчётов.
        local result_1  -- Расчёт функции.
        local status = {  -- Статус работы функции.
            ["status"] = DATAST["OK"],
            ["msg"] = "",
        }
        local avg = 0
        for _, v in ipairs(t_values) do
            avg = avg + v
        end
        result_1 = avg / #t_values
        table.insert(results, result_1)
        ret.results = results
        ret.status = status
        return ret
    end
end


return M
