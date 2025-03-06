-- 

local def_pth = require("_script_path")
local pth = def_pth.script_path()
def_pth.lib_path(pth .. "\\..\\meralualib")


local Abs = require("Abs")


local Tags = {}
Tags.alloc_ = Abs:alloc_{maxinst = 1}

function Tags:new()

  local tg = self.alloc_()
  tg.tags = {}

  local current_env = "SIAMGLB" -- глобальное пространство имен по умолчанию
  local init_ = false -- флаг начальной инициализации 

  --- Функция создает теги на основе переданной таблицы имен и инициализирующих значений
  ---@param ttags {name: string, defval: number} -- таблица имен тегов и инициализирующих значений
  ---@param option {env: string, unique: boolean, addsiam: boolean, pth_dir: string} -- дополнительные опции
  function tg:CreateNewTags(ttags, option)
    --[[
    на входе таблица в формате 
    {
      ["name"] = "tag_name" ["defval"] = 0
      ["name"] = "tag_name" ["defval"] = 0
    }
    -- Теги для которых значение по умолчанию не задано инициализируются нулем.
    -- Если путь к файлу не задан, то путь сохранения специального файла либо в директориии вызова функции, либо зависит от цепочки вызовов.
    --]]
    assert (type(ttags) == "table", "Assert in function InitTags, the input parameter must be a table")
    local strings_tname = {}
    option = option or {}
    assert(type(option) == "table")
    local env = option.env or current_env -- пространство имен
    local unique = option.unique or false -- проверка на уникальность
    local addsiam = option.addsiam or false -- добавлять в СИАМ

    local pth_dir = option.pth_dir
    pth_dir = pth_dir ~= nil and type(pth_dir) == "string" and pth_dir or pth .."\\..\\"
    pth_dir = pth_dir .. "__CREATE_NEWTAGS__.lua"

    local f = nil
    if init_ then
      f = io.open(pth_dir, "r")
    end
    if f then 
      while true do
        local str_ = f:read()
        table.insert(strings_tname, str_)
        if str_ == nil then
          break
        end
      end
      f:close()
    else

      table.insert(strings_tname, '--Скрипт создан автоматически, не изменять вручную')
      table.insert(strings_tname, 'function lua_main() end')      
    end

    f = io.open(pth_dir, "w")
    for t_id, tag in ipairs(ttags) do
      tag = tag
      assert(type(tag.name) == "string", "Assert in function InitTags, the key of the table must be a string") 
      tag.defval = tag.defval or 0
      self.tags[tag.name] = tag.defval
      table.insert(strings_tname, '--setValue("' .. tag.name .. '")')
    end
    for _, v in ipairs(strings_tname) do
      f:write(v, "\n")
    end
    f:close()
    init_ = true
  end

  --- устанавливает текущее пространство имен
  ---@param env string
  function tg:set_current_env(env)
    env = env or "SIAMGLB"
    assert(type(env) == "string")
    current_env = env
    return current_env
  end

  --- Возвращает текущее пространство имен
  function tg:ret_current_env()

    return current_env
  end

  --- Возвращает число вложенных пространств имен в текущем 
  --- @param owner_env string
  function tg:getCountEnvs(owner_env)
    env = env or current_env
    assert(type(env) == "string")

    local cnt = 0
    return cnt
  end

  --- Возвращает все вложенные пространства имен
  function tg:getEnvs(owner_env)
  end

  --- Возвращает родительское пространство имен
  function tg:getPareentEnv()
  end

  --- Функция возвращает число тегов в текущещм пространстве имен
  function tg:getCountTags(env)

    return 0
  end

  setmetatable(tg, self)
  self.__index = self

  return tg
end

Tags = Tags:new()
return Tags

