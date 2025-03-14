--[[
-- Модуль работы с файлами.
]]

local M = {}


do --  Функция чтения файла.
    ---@param path string
    ---@param coll_type string
    ---@param delim string
    ---@return table, integer
    function M.rfile(path, coll_type, delim)
        assert(type(path) == "string", "Parameter 'path': expected 'string', got '" .. type(path) .. "'. ")
        assert(
            type(coll_type) == "string",
            "Parameter 'coll_type': expected 'string', got '" .. type(coll_type) .. "'. "
        )
        assert(
            coll_type == "dict" or coll_type == "list",
            "Parameter 'coll_type' can take only one of the following string values: 'dict', 'list'. "
        )
        assert(type(delim) == "string", "Parameter 'delim': expected 'string', got '" .. type(delim) .. "'. ")
        assert(delim ~= "", "Parameter 'delim' should not be empty string. ")
        local f = io.open(path, "r")
        local err = 0
        local data = {}

        local function split(s, delimiter)
            -- Функция разделения строк на подстроки.
            local result = {}
            for match in (s..delimiter):gmatch("(.-)"..delimiter) do
                table.insert(result, match)
            end
            return result
        end

        local function trim(s)
            -- Функция удаления пробелов в начале и конце строки.
            return s:match( "^%s*(.-)%s*$" )
        end

        if f then
            while true do
                local line = f:read()
                if line == nil then
                    f:close()
                    break
                end
                    line = split(line, delim)
                    local array = {}
                    for i = 1, #line do
                        array[i] = trim(line[i])
                    end
                    if coll_type == "dict" then
                        if array[1] == "" then
                            ;
                        else
                            if #array == 1 then
                                data[array[1]] = ""
                            elseif #array == 2 then
                                data[array[1]] = array[2]
                            else
                                local tbl = {}
                                for i = 2, #array do
                                    table.insert(tbl, array[i])
                                end
                                data[array[1]] = tbl
                            end
                        end
                    end
                    if coll_type == "list" then
                        if #array == 1 then
                            table.insert(data, array[1])
                        else
                            table.insert(data, array)
                        end
                    end
            end
        else
            err = 1
        end
        return data, err
    end
end


do  -- Функция записи в файл.
    ---@class Args
    ---@field fpath_name string Имя и путь до файла.
    ---@field data table Таблица с данными для записи в файл.
    ---@field coll_type string Тип таблицы с данными:
    ---| "dict" # Словарь.
    ---| "list" # Список.
    ---| "list2" # Двумерный список.
    ---@field delim? string|nil Разделитель между данными в строке файла записи.
    ---@field keys? table|nil Список с параметрами, которые попадут в файл, порядок записи в файл параметров согласно этому списку.
    ---@field use_sort? boolean|nil Использовать сортировку имён параметров (по возрастанию) при записи в файл, если таблица с данными в виде словаря.
    ---@field write_mode? string|nil Режим записи в файл: "w", "a", "r+", "w+", "a+", "wb", "ab".
    ---@param args Args
    ---@return number err Ошибка работы функции: 0 - нет ошибок, 1 - есть ошибки.
    -- Функция записи в файл.
    function M.wfile(args)
        assert(type(args.fpath_name) == "string", "Parameter 'args.fpath_name': expected 'string', got '" .. type(args.fpath_name) .. "'. ")
        assert(type(args.data) == "table", "Parameter 'args.data': expected 'table', got '" .. type(args.data) .. "'. ")
        assert(
            type(args.coll_type) == "string",
            "Parameter 'args.coll_type': expected 'string', got '" .. type(args.coll_type) .. "'. "
        )
        assert(
            args.coll_type == "dict" or args.coll_type == "list" or args.coll_type == "list2",
            "Parameter 'args.coll_type' can take only one of the following string values: 'dict', 'list', 'list2'. "
        )
        assert(
            args.delim == nil or type(args.delim) == "string",
            "Parameter 'args.delim': expected 'string', got '" .. type(args.delim) .. "'. "
        )
        assert(
            args.keys == nil or type(args.keys) == "table",
            "Parameter 'args.keys': expected 'table', got '" .. type(args.keys) .. "'. "
        )
        assert(
            args.write_mode == nil or type(args.write_mode) == "string",
            "Parameter 'args.write_mode': expected 'string', got '" .. type(args.write_mode) .. "'. "
        )
        assert(
            args.use_sort == nil or type(args.use_sort) == "boolean",
            "Parameter 'args.use_sort': expected 'boolean', got '" .. type(args.use_sort) .. "'. "
        )
        args.write_mode = args.write_mode or "w+"
        local WRITE_MODES = {"w", "a", "r+", "w+", "a+", "wb", "ab"}
        local write_mode_assert = false
        for _, wmode in ipairs(WRITE_MODES) do
            if args.write_mode == wmode then
                write_mode_assert = true
                break
            end
        end
        assert(write_mode_assert, "The file recording modes can only be of the following types: 'w', 'a', 'r+', 'w+', 'a+', 'wb', 'ab'")
        args.delim = args.delim or ""
        local err = 1
        local f = io.open(args.fpath_name, args.write_mode)
        if f then
            if args.coll_type == "dict" then
                if args.keys then
                    local data_name_proxy = {}  -- Словарь с именами в нижнем регистре и исходными именами параметров.
                    for name, _ in pairs(args.data) do
                        local name_lower = string.lower(name)
                        data_name_proxy[name_lower] = name
                    end
                    local keys_sorted = {}  -- Список с отсортированными именами параметров.
                    for _, key in ipairs(args.keys) do
                        local key_lower = string.lower(key)
                        table.insert(keys_sorted, key_lower)
                    end
                    if args.use_sort then
                        table.sort(keys_sorted, function(a, b) return a < b end)
                    end
                    for _, key in ipairs(keys_sorted) do
                        if args.data[data_name_proxy[key]] ~= nil then
                            f:write(data_name_proxy[key], args.delim, args.data[data_name_proxy[key]], "\n")
                        end
                    end
                else
                    local name_sorted = {}  -- Список с отсортированными именами параметров.
                    local name_proxy = {}  -- Словарь с именами в нижнем регистре и исходными именами параметров.
                    for key, _ in pairs(args.data) do
                        local key_lower = string.lower(key)
                        table.insert(name_sorted, key_lower)
                        name_proxy[key_lower] = key
                    end
                    if args.use_sort then
                        table.sort(name_sorted, function(a, b) return a < b end)
                    end
                    for _, name in ipairs(name_sorted) do
                        f:write(name_proxy[name], args.delim, args.data[name_proxy[name]], "\n")
                    end
                end
            end
            if args.coll_type == "list" then
                for _, v in ipairs(args.data) do
                    f:write(v, "\n")
                end
            end
            if args.coll_type == "list2" then
                for _, list in ipairs(args.data) do
                    for _, v in ipairs(list) do
                        f:write(v, args.delim)
                    end
                    f:write("\n")
                end
            end
            f:close()
            err = 0
        end
        return err
    end
end


return M
