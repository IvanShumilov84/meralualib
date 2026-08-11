--[[
    Модуль обёрток СИАМ функций.
]]


-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."


local m = {}


-- Получить список имён тегов.
function m.get_tag_names_list(tag_pref)
    tag_pref = tag_pref or ""
    local list = {}
    local index = 0

    while true do
        local found, name = getRecorderTag(index, tag_pref)
        if not found then
            break
        end
        table.insert(list, name)
        index = index + 1
    end
    return list
end


return m
