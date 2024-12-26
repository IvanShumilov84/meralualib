--[[
-- Модуль работы с файлами.
]]

local t = {}


do --  Функция чтения файла.
    ---@param path string
    ---@param coll_type string
    ---@param delim string
    ---@return table, integer
    function t.rfile(path, coll_type, delim)
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


do --  Функция записи в файл.
    ---@param fpath_name string
    ---@param data table
    ---@param coll_type string
    ---@param delim string|nil
    ---@param keys table|nil
    ---@return number
    function t.wfile(fpath_name, data, coll_type, delim, keys)
        assert(type(fpath_name) == "string", "Parameter 'fpath_name': expected 'string', got '" .. type(fpath_name) .. "'. ")
        assert(type(data) == "table", "Parameter 'data': expected 'table', got '" .. type(data) .. "'. ")
        assert(
            type(coll_type) == "string",
            "Parameter 'coll_type': expected 'string', got '" .. type(coll_type) .. "'. "
        )
        assert(
            coll_type == "dict" or coll_type == "list" or coll_type == "list2",
            "Parameter 'coll_type' can take only one of the following string values: 'dict', 'list', 'list2'. "
        )
        assert(
            delim == nil or type(delim) == "string",
            "Parameter 'delim': expected 'string', got '" .. type(delim) .. "'. "
        )
        assert(
            keys == nil or type(keys) == "table",
            "Parameter 'keys': expected 'table', got '" .. type(keys) .. "'. "
        )
        delim = delim or ""
        local err = 1
        local f = io.open(fpath_name, "w+")
        if f then
            if coll_type == "dict" then
                if keys then
                    for i = 1, #keys do
                        if data[keys[i]] ~= nil then
                            f:write(keys[i], delim, data[keys[i]], "\n")
                        end
                    end
                else
                    for k, v in pairs(data) do
                        f:write(k, delim, v, "\n")
                    end
                end
            end
            if coll_type == "list" then
                for _, v in ipairs(data) do
                    f:write(v, "\n")
                end
            end
            if coll_type == "list2" then
                for _, list in ipairs(data) do
                    for _, v in ipairs(list) do
                        f:write(v, delim)
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


return t
