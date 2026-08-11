-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."


local M = {}
local json = {}

-- Вспомогательные функции
local function escape_str(s)
    local escapes = {
        ['"'] = '\\"',
        ['\\'] = '\\\\',
        ['/'] = '\\/',
        ['\b'] = '\\b',
        ['\f'] = '\\f',
        ['\n'] = '\\n',
        ['\r'] = '\\r',
        ['\t'] = '\\t'
    }
    return s:gsub('[%c\\"/]', escapes)
end

local function is_array(t)
    local count = 0
    for k, v in pairs(t) do
        if type(k) ~= "number" then
            return false
        end
        count = count + 1
    end
    return count > 0
end

-- Основная функция сериализации
function json.encode(value, pretty, indent_level)
    indent_level = indent_level or 0
    local indent = pretty and string.rep("  ", indent_level) or ""
    local newline = pretty and "\n" or ""
    local space = pretty and " " or ""

    local t = type(value)
    
    if t == "string" then
        return '"' .. escape_str(value) .. '"'
    elseif t == "number" then
        if value ~= value then -- NaN
            return "null"
        elseif value == math.huge then
            return "1e+999"
        elseif value == -math.huge then
            return "-1e+999"
        else
            return tostring(value)
        end
    elseif t == "boolean" then
        return value and "true" or "false"
    elseif t == "table" then
        if next(value) == nil then
            return "{}"
        elseif is_array(value) then
            local parts = {}
            local max_index = 0
            for k in pairs(value) do
                if k > max_index then
                    max_index = k
                end
            end
            for i = 1, max_index do
                table.insert(parts, json.encode(value[i], pretty, indent_level + 1) or "null")
            end
            if pretty then
                return "[" .. newline .. indent .. "  " .. table.concat(parts, "," .. newline .. indent .. "  ") .. newline .. indent .. "]"
            else
                return "[" .. table.concat(parts, ",") .. "]"
            end
        else
            local parts = {}
            for k, v in pairs(value) do
                if type(k) == "string" then
                    table.insert(parts, '"' .. escape_str(k) .. '":' .. space .. json.encode(v, pretty, indent_level + 1))
                elseif type(k) == "number" then
                    table.insert(parts, '"' .. tostring(k) .. '":' .. space .. json.encode(v, pretty, indent_level + 1))
                end
            end
            if pretty then
                return "{" .. newline .. indent .. "  " .. table.concat(parts, "," .. newline .. indent .. "  ") .. newline .. indent .. "}"
            else
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
    elseif t == "nil" then
        return "null"
    else
        assert(false, "Unsupported type: " .. t)
    end
end

M.json = json


return M
