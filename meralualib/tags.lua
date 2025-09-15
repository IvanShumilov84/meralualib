-- TODO Сделать отчёт по успешности создания каналов и количеству созданных/несозданных каналов. Перечислить несозданные каналы.

local def_pth = require("_script_path")
local pth = def_pth.script_path()
def_pth.lib_path(pth)

local Abs = require("Abs")
local nds = require("nodes")
local d_type = require("datatype")

nds.__index = nds
local Tags = setmetatable({}, nds)
Tags.alloc_ = Abs:alloc_{maxinst = 1}


local DEF_ENV = "SIAMGLB" -- глобальное пространство имен по умолчанию
local def_value = 0 -- значение по умолчанию принятое в системе, возможно следует поменять на nil
local en_autocreate_tags = true
local en_err_tag_notexist = false
--- Возвращает ссылку на текущее пространство имен
-- function Tags:get_cur_env()
--   return Tags.get_cur_t()()
-- end

---@param ttags {s_tags: string | table, value?: any, info?: string}
function CreateTagsObj(ttags)

  --s_tags, Value, info
  assert(type(ttags) == "table")  -- [1]= s_tags, [2] = Value, [3] = info

  local t = {}
  t.info = ttags.info or ttags[3]
  t.siamtagname = "" -- имя канала в СИАМ - системе
  t.scrtagname = "" -- дублирующее имя канала в Lua - системе

  local s_tags = ttags.s_tags or ttags[1]
  assert(s_tags ~= nil)
  local t_inf = type(s_tags)
  assert(t_inf == "string" or t_inf == "table")

  if t_inf == "string" then
    s_tags = trim(s_tags)
    assert(s_tags ~= "")
    t.siamtagname = s_tags
    t.scrtagname = s_tags
  else
    -- преобразование в идентификаторах
    t.scrtagname = trim(s_tags[1])
    assert(t.scrtagname ~= "")
    t.siamtagname = trim(s_tags[2])
    assert(t.siamtagname ~= "")
  end

  t.value = ttags.value or ttags[2] or def_value -- значение  

  --[[  Возможность добавления специальных полей 
    -- значения фалагов оценки и других
  --]]
  t.datast = 0

  function t:get()
    return self.value
  end
  function t:set(Value)
    self.value = Value
    return self.value
  end
  function t:get_name()
    return self.scrtagname
  end

  setmetatable(t, {
    __call = function (self, Value)
      if Value ~= nil then
        return self:set(Value)
      else
        return self:get()
      end
    end,
    -- __newindex = function (self, key, Value)
    --   rawset(self, key, value)
    -- end
  })

  return t
end

local test_t = CreateTagsObj{"test_1", "величина  = 100"}
print(test_t())
print(test_t:get())
print(test_t(200))
print(test_t(test_t(300)))

function Tags:new()

  self:creator(DEF_ENV)   
  local f_get_env = self.get_cur_t()  -- функциональный указатель на активное пространство имен

  local init_ = false -- флаг начальной инициализации 
  local en_addsiam = true

  local tg = self.alloc_()    -- управляет доступом

  --- TODO перенести в отдельную функцию функционал работы с файлом
  --- 
  
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

    assert (type(ttags) == "table", "Assert in function CreateNewTags, the input parameter must be a table")

    local strings_tname = {}
    option = option or {}
    assert(type(option) == "table")

    local s_env = option.senv or option[1] or "" --current_env -- пространство имен 
    assert(type(s_env) == "string")
    s_env = trim(s_env)
    if s_env ~= "" then
      if tg:get_name_env() ~= s_env then
        tg:set_name_env(s_env)
      end
    end

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

    local l_env = f_get_env()
    -- if not l_env:find_key("tags") then
    --   l_env:set_data()
    -- if rawget(l_env, "tags") == nil then
    --   rawset(l_env, "tags", {})
    -- end

    for t_id, tag in pairs(ttags) do

      assert(type(tag.name) == "string", "Assert in function InitTags, the key of the table must be a string")
      tag.name = trim(tag.name)
      

      local info  = tag.info or ""
      assert(type(info) == "string", "Assert in function InitTags, the key of the table must be a string")
      if info:len() > 0 then
        info_ = ' -- ' .. info
      end

      tag.defval = tag.defval ~= nil and tag.defval or 0
      l_env:set_data({[tag.name] = CreateTagsObj{tag.name, tag.defval, info} })
      table.insert(strings_tname, '-- setValue("' .. tag.name .. '")' .. info_)
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
  function tg:set_name_env(s_env)
    s_env = s_env or DEF_ENV
    assert(type(s_env) == "string")
    --print("set_name_env (1) env = ", f_get_env())
    local new_env = f_get_env():new_t(s_env)
    --print("set_name_env (2) env = ", f_get_env())
    --print("set_name_env (1) new_env = ", new_env)
    return f_get_env()
  end

  --- Возвращает текущее пространство имен
  --- @return string
  function tg:get_name_env()
    --print("get_name_env: ", f_get_env())
    return f_get_env():get_id()
  end

  --- Возвращает число вложенных пространств имен в текущем 
  --- @param owner_env string
  --- @return number
  function tg:getCountEnvs(owner_env)
    owner_env = type(owner_env)=="string" and owner_env or nil
    --assert(type(owner_env) == "string")
    return f_get_env():get_cnt_ch(owner_env)
    -- if type(self[env]) ~= "table" then
    --   return 0
    -- end
    -- return uts.get_count_keys(self[env], "table")
    -- --return cnt
  end

  --- Возвращает все вложенные пространства имен 
  function tg:getEnvs(owner_env)
    return f_get_env():get_chld_t()
  end

  --- Возвращает пространство имен по имени или false
  --- поиск осуществляется только во вложенных пространствах имен (1 уровень вложенности)
  function tg:findEvent(s_env)
    print("findEvent >>> Current1 env = ", f_get_env())

    local res = f_get_env():find_ch(s_env, true)
    print("findEvent >>> Current2 env = ", f_get_env())

    print("findEvent >>> result env = ", res)
    return res ~= nil or nil
  end

  --- Возвращает родительское пространство имен
  function tg:getParentEnv()
    return f_get_env():get_parent_t(true)
  end

  --- Функция возвращает число тегов в текущещм пространстве имен
  --- @param env string -- пространство имен первого уровня вложенности 
  --- TODO реализовать поддержку вложенных пространств имен
  function tg:getCountTags(env)
    --print("getCountTags >>> Current env = ", f_get_env())
    --local f_get_env1 = self.get_cur_t()
    local t = f_get_env()
    return t:cnt_cust_data()
  end

  --- Функция поиска тэга в пространстве имен
  --- TODO find_tag() реализовать поддержку пространств имен
  --- @param tag string
  --- @param env? string
  function tg:find_tag(tag, env)
    local status, _, tag_obj = f_get_env():find_key(tag)
    return status, tag_obj
  end

  --- Функция возвращает все тэги пространства имен 
  --- TODO get_all_tagsObj() реализовать поддержку пространств имен
  function tg:get_all_tagsObj(env)
    return f_get_env():get_all_data()
  end

  --- TODO Функция объединения тэгов указанного пространства имен с текущим
  --- TODO Функция импорта тэгов указанного пространства имен в глобальное пространство имен Lua _G или _ENV(по умолчанию) - в Lua >=5.2
  --- Если пространство имен не указано, то импортируется текущее пространство имен
  --- TODO Функция удаления из глобального пространства имен тэгов указанного простнаства имен

  --- NOTE Функция доступа к тегам текущего пространства имен --- Вариант 1: Tags.anytag
  --- TODO Вариант 2: Tags().anytag

  --- TODO Функция доступа к тегам пространства имен через указание имени простарнства имен
  --- Вариант 1: Tags(namespace).anytag
  --- Вариант 2: Tags.namespace.anytag

  mt = setmetatable({}, self)
  self.__index = self
  mt_1 = getmetatable(mt) or {}


  mt.__call = function (self, s_env)
    local env = self:findEvent(s_env)
    --print("__call env = ", env)
  end


  mt.__index = function (self, key)
    --print("tags key = ", key)
    local _, tgobj = self:find_tag(key)
    --print("__index tag = ", tgobj:get_name(), tgobj())
    return tgobj ~= nil and tgobj() or nil -- mt_1.__index --and mt_1.__index(self, key) --rawget(self, key)
  end


  mt.__newindex = function(self, key, value)
    local _, tgobj = self:find_tag(key)
    if tgobj ~= nil then
      tgobj(value)
    elseif en_autocreate_tags then
      --print("key type value: ", type(key), key)
      self:CreateNewTags({{name = key, defval = value,}},{addsiam = false})
    elseif en_err_tag_notexist then
      error("Error tag".. key .. "not exist")
    end
  end

  setmetatable(tg, mt)


  return tg
end

Tags = Tags:new()

---setmetatable(Tgs, Tags)
---Tags.__index = Tags
--Tags2 = Tags:new()

return Tags

