--[[
    Модуль отладки в IDE.
]]


local M = {}


-- Лог в консоль.
-- Вид лога: !!!DEBUG: data = (<переданные данные data>)   file = (path = <путь до файла, вызвавшего функцию>, line = <номер строки вызова функции>)
function M.clog(args)
    local label = args.label or "!!!DEBUG:"  -- Префикс сообщения в логе консоли.
    local sep = args.sep or ", "  -- Разделитель между переданными анализируемыми данными.
    local data = args.data or {}  -- Список анализируемых данных.

    local info = debug.getinfo(2, "lS")
    local line = tostring(info.currentline)

    local source = info.source:sub(2)  -- убираем '@'
    local full_path = source           -- например: folder/subfolder/myfile.lua

    -- Определяем тип слэша: Unix (/) или Windows (\)
    local is_windows = package.config:sub(1,1) == "\\"
    local separ = is_windows and "\\" or "/"

    -- Нормализуем путь под текущую ОС
    full_path = full_path:gsub("/", separ):gsub("\\", separ)

    -- Извлекаем имя файла
    local file_name = full_path:match("([^" .. separ .. "]+)$") or full_path

    -- Определяем, является ли путь относительным
    local is_relative = not full_path:match("^[%a]:") and not full_path:find("^" .. separ .. separ)

    -- Получаем абсолютный путь (пробуем определить через dir_path)
    local absolute_path = nil
    if is_relative then
        -- Пытаемся получить текущую директорию через arg[0]
        local current_dir = "."
        if arg and type(arg[0]) == "string" then
            current_dir = arg[0]:match("(.*" .. separ .. ")") or "."
        end
        absolute_path = current_dir .. separ .. full_path
    else
        -- Если путь уже абсолютный — просто возвращаем его
        absolute_path = full_path
    end

    io.write(label, " ")
    io.write("data = (")
    for _, v in ipairs(data) do
        v = tostring(v)
        io.write(v, sep)
    end
    io.write(")   ")
    io.write(" file = (path = '", absolute_path, "', line = ", line, ")")
    io.write("\n")
end


return M
