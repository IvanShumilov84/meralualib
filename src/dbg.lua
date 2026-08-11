--[[
    Модуль отладки в IDE.
]]


-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."


local M = {}


--- Лог в консоль.
--- Вид лога: !!!DEBUG: data = ([1] = <значение 1>, ...)   file = (path = <путь до файла, вызвавшего функцию>, line = <номер строки вызова функции>)
--- @param args table
function M.clog(args)
    assert(type(args) == "table", "The argument of the function must be a table")
    local label = args.label or "!!!DEBUG:"  -- Префикс сообщения в логе консоли.
    local sep = args.sep or ", "  -- Разделитель между переданными анализируемыми данными.
    local data = args.data or {}  -- Список анализируемых данных.

    local info = debug.getinfo(2, "lS")
    local line = tostring(info.currentline)
    local full_path = info.source:sub(2)  -- убираем '@'

    io.write(label, " ")
    io.write("data = (")
    local plce_ = false
    for k, v in pairs(data) do
        local value = tostring(v)
        io.write(plce_ == true and sep or '')
        io.write("[", k, "] = ", value)
        plce_ = true
    end
    io.write(")   ")
    io.write(" file = (path = '", full_path, "', line = ", line, ")")
    io.write("\n")
end


--- Лог в консоль.
--- Вид лога: !!!DEBUG: data = ([1] = <значение 1>, ...)   file = (path = <путь до файла, вызвавшего функцию>, line = <номер строки вызова функции>)
--- @param func function
--- @param args table
function M.exlog(args)
    assert(type(args) == "table", "The argument of the function must be a table")
    local func = type(args.func) == "function" and args.func or print
    local label = args.label or "!!!DEBUG:"  -- Префикс сообщения в логе консоли.
    local sep = args.sep or ", "  -- Разделитель между переданными анализируемыми данными.
    local data = args.data or {}  -- Список анализируемых данных.
    local prt = args.prt or true -- Позволяет отключить вызов callback-функции

    local info = debug.getinfo(2, "lS")
    local line = tostring(info.currentline)
    local full_path = info.source:sub(2)  -- убираем '@'

    local log = label .. " " .. "data = ("
    local plce_ = false
    for k, v in pairs(data) do
        local value = tostring(v)
        if plce_ == true then
            log = log .. sep
        end
        log = log .. "[" .. k .. "] = " .. value
        plce_ = true
    end
    log = log .. ")   " .. " file = (path = '" .. full_path .. "', line = " .. line .. ")" -- .. "\n"
    if prt == true then
        func(log)       
    end
    return log
end

--- Фабрика для создания создания различных функций логирования
--- @param func? function
--- @param not_func? boolean
function M.Createloger(func, not_func)
    func = type(func) == "function" and func or print
    local nfn = not_func or false
    local func_ = func
    return function (args)
        args.func = func_
        args.prt = not nfn
        return M.exlog(args)
    end
end

return M
