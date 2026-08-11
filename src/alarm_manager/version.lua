-- Версия модуля.
local M = {}

M.version = {
    major = 0,
    minor = 0,
    patch = 0,
}


-- Получить версию библиотеки в виде строки "vMAJOR{sep}MINOR{sep}PATCH".
---@param sep? string  -- Разделитель между числами в версии.
---@return string
function M.get_version_string(sep)
    if not (type(sep) == "string") then
        sep = "_"
    end

    return "v" .. M.version.major .. sep .. M.version.minor .. sep .. M.version.patch
end


return M
