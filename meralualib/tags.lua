-- TODO Сделать отчёт по успешности создания каналов и количеству созданных/несозданных каналов. Перечислить несозданные каналы.

local def_pth = require("_script_path")
local pth = def_pth.script_path()
def_pth.lib_path(pth .. "..\\meralualib")

local DEF_ENV = "SIAMGLB" -- глобальное пространство имен по умолчанию

local Abs = require("Abs")
local uts = require("utils")

local Tags = {}
Tags.alloc_ = Abs:alloc_{maxinst = 1}



function Tags:creator_envs()
  local env_ = {}
  local env_name = DEF_ENV

  local pr_env = nil

  function env_:get_parent_env()

    return pr_env
  end

  return function (env)
    env = env or DEF_ENV
    assert(type(env) == "string")
    pr_env = self
    return env_
  end
end
Tags.CreateEnv = Tags:creator_envs()


function Tags:new()

  local tg = self.alloc_()
  tg = self.CreateEnv()

  local current_env = "SIAMGLB" --
  local init_ = false -- флаг начальной инициализации 
  local en_addsiam = true
  


  --- Функция создает теги на основе переданной таблицы имен и инициализирующих значений
  ---@param ttags {name: string, defval: number, info: string} -- таблица имен тегов и инициализирующих значений
  ---@param option? {env: string, unique: boolean, addsiam: boolean, fname: string, pth_dir: string} -- дополнительные опции
  function tg:CreateNewTags(ttags, option)
    --[[
    на входе таблица в формате 
    {
      ["name"] = "tag_name" ["defval"] = 0 ["info"] = "tag description"
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
    local addsiam = option.addsiam == nil and en_addsiam or option.addsiam  -- добавлять в СИАМ
    local fname = type(option.fname) == "string" and option.fname or "__CREATE_NEWTAGS__.lua"

    local pth_dir = option.pth_dir ~= nil and type(option.pth_dir) == "string" and option.pth_dir or pth .."\\..\\"
    pth_dir = pth_dir .. fname

    if addsiam then
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
    end
    if not uts.find_tblvalue(self, env) then
      self[env] = {}
    end

    for t_id, tag in pairs(ttags) do
      tag = tag
      assert(type(tag.name) == "string", "Assert in function InitTags, the key of the table must be a string")
      local info  = tag.info or ""
      assert(type(info) == "string", "Assert in function InitTags, the key of the table must be a string")
      if info:len() > 0 then        
        info = ' -- ' .. info
      end
      tag.defval = tag.defval or 0
      --self.tags[tag.name] = tag.defval
      self[env][tag.name] = tag.defval

      table.insert(strings_tname, '-- setValue("' .. tag.name .. '")' .. info)
    end

    if addsiam then 
      f = io.open(pth_dir, "w")
      for _, v in ipairs(strings_tname) do
        f:write(v, "\n")
      end
      f:close()
      init_ = true
    end
  end

  --- устанавливает текущее пространство имен
  ---@param env string
  function tg:set_name_env(env)
    env = env or DEF_ENV
    assert(type(env) == "string")
    if not uts.find_tblvalue(self[current_env], env) then
      self[current_env][env] = {}
    end
    current_env = env
    --return current_env
  end

  --- Возвращает текущее пространство имен
  --- @return string
  function tg:get_name_env()
    return current_env
  end

  --- Возвращает число вложенных пространств имен в текущем 
  --- @param owner_env string
  --- @return number
  function tg:getCountEnvs(owner_env)
    env = owner_env or current_env
    assert(type(env) == "string")
    --local cnt = 0
    if type(self[env]) ~= "table" then
      return 0
    end
    return uts.get_count_keys(self[env], "table")
    --return cnt
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
  --- Функция установки глобального флага разрешения добавлять теги в СИАМ
  ---@param opt boolean | integer
  function tg:set_en_addsiam(opt)
    opt = opt or true
    opt = type(opt) == "boolean" and opt or type(opt) == "number" and opt > 0
    en_addsiam = opt
  end
  --- Функция возвращает значение флага разрешения добавлять теги в СИАМ
  ---@return boolean
  function tg:get_en_addsiam()
    return en_addsiam
  end

  setmetatable(tg, self)
  self.__index = self

  return tg
end

Tags = Tags:new()
return Tags

