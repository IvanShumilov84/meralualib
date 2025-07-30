--[[
    Работа с импортом модулей.
]]


local M = {}


-- Функция реализует относительный импорт модулей.
function M.require_relative(module)
    -- Получаем путь к текущему файлу
    local source = debug.getinfo(2, "S").source:sub(2)
    local dir = source:match("(.*[/\\])")

    -- Заменяем точки на слэши (для точечной нотации)
    module = module:gsub("%.", "/")

    -- Формируем путь
    local full_path = dir .. module:gsub("\\", "/")

    -- Проверяем, существует ли файл
    local function file_exists(path)
        local f = io.open(path, "r")
        if f then
            io.close(f)
            return true
        end
        return false
    end

    -- Пытаемся найти .lua или init.lua
    local resolved_path = nil

    -- Вспомогательная функция endswith
    function string.endswith(str, ending)
        return ending == "" or str:sub(-#ending) == ending
    end

    -- Если это явно не .lua — проверим как папку с init.lua
    if not string.endswith(full_path:lower(), ".lua") then
        local path_with_slash = full_path:endswith("/") and full_path or full_path .. "/"
        local candidate = path_with_slash .. "init.lua"
        if file_exists(candidate) then
            resolved_path = candidate
        else
            candidate = full_path .. ".lua"
            if file_exists(candidate) then
                resolved_path = candidate
            end
        end
    else
        if file_exists(full_path) then
            resolved_path = full_path
        end
    end

    --BUG: Разобраться, почему в сиамовский лог вместо кириллицы выводятся кракозябры, хотя в консоль выводится кириллица нормально. 
    -- Если ничего не нашли — ошибка
    if not resolved_path then
        error("Модуль не найден: " .. module .. " (" .. full_path .. ")", 2)
    end

    -- Кэшируем по полному пути
    local key = "relmod:" .. resolved_path
    if package.loaded[key] then
        return package.loaded[key]
    end

    -- Загружаем и выполняем модуль
    local mod, err = loadfile(resolved_path)
    if not mod then
        error("Не удалось загрузить модуль: " .. resolved_path .. "\nОшибка: " .. tostring(err), 2)
    end

    local success, result = pcall(mod)
    if not success then
        error("Ошибка при выполнении модуля: " .. resolved_path .. "\n" .. tostring(result), 2)
    end

    package.loaded[key] = result
    return result
end


-- Получить информацию о модуле.
function M.get_module_info()
    local UNDEF = "undefined"
    local mod_info = {
        module_name = UNDEF,      -- имя модуля без .lua
        file_name = UNDEF,        -- имя файла с .lua
        full_path = UNDEF,        -- полный путь (относительно запуска)
        dir_path = UNDEF,         -- путь к папке файла
        is_relative = UNDEF,      -- true, если путь относительный
        absolute_path = UNDEF,    -- абсолютный путь (если доступен)
        separator = UNDEF         -- используемый разделитель
    }

    local info = debug.getinfo(2, "S")
    if not info then
        return mod_info
    end

    local source = info.source:sub(2)  -- убираем '@'
    local full_path = source           -- например: folder/subfolder/myfile.lua

    -- Определяем тип слэша: Unix (/) или Windows (\)
    local is_windows = package.config:sub(1,1) == "\\"
    local sep = is_windows and "\\" or "/"

    -- Нормализуем путь под текущую ОС
    full_path = full_path:gsub("/", sep):gsub("\\", sep)

    -- Извлекаем имя файла
    local file_name = full_path:match("([^" .. sep .. "]+)$") or full_path

    -- Убираем расширение
    local module_name = file_name:match("(.+)%..+")
    module_name = module_name or file_name

    -- Путь к директории
    local dir_path = full_path:sub(1, #full_path - #file_name)

    -- Определяем, является ли путь относительным
    local is_relative = not full_path:match("^[%a]:") and not full_path:find("^" .. sep .. sep)

    -- Получаем абсолютный путь (пробуем определить через dir_path)
    local absolute_path = nil
    if is_relative then
        -- Пытаемся получить текущую директорию через arg[0]
        local current_dir = "."
        if arg and type(arg[0]) == "string" then
            current_dir = arg[0]:match("(.*" .. sep .. ")") or "."
        end
        absolute_path = current_dir .. sep .. full_path
    else
        -- Если путь уже абсолютный — просто возвращаем его
        absolute_path = full_path
    end

    mod_info = {
        module_name = module_name,
        file_name = file_name,
        full_path = full_path,
        dir_path = dir_path,
        is_relative = is_relative,
        absolute_path = absolute_path,
        separator = sep
    }

    return mod_info
end

return M
