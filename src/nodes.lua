-- @build_token: LIB_PATH_VERSION
local lib_path = "meralualib.src."

local def_pth = require(lib_path .. "_script_path")
local pth = def_pth.script_path()
def_pth.lib_path(pth)

ut = require(lib_path .. "utils")
trim = ut.strtrim

--- Таблица ссылок
local lnk = {}
function lnk:set_active_t(t)
  assert(type(t) == "table")
  self.cur_t = t
  return t
end


function lnk:get_func_active_t()
  return function ()
    return self.cur_t
  end
end


function lnk:get_func_insert()
  return function(data)
    local l = self.cur_t
    if l ~= nil and data ~= nil then
      for k, v in pairs(data) do
        l[k] = v
      end
    end
    return l
  end
end


function lnk:clear()
  self.cur_t = nil
end

--- 
local node = {}

--- заглушка получения id по умолчанию - это может быть расчет has суммы или другой способ
function node:get_def_id()
  local def_id = "GLOBAL"
  return def_id
end

function node.get_cur_t()
  return lnk:get_func_insert()
end

-- function node:get_links()
--   return lnk
-- end

function node:creator(id_, own)
  --- TODO добавить проверку в экземляре own на наличие текущего потомка и в случае отстутствия вызвать 
  --- метод добавления. На данный момент не производится встречной проверки в родительском классе 
  --- наличия текущего потомка

  local t = lnk:set_active_t {} -- текущее пространство имен (вирт. окружение) хранит все текущие теги

  local ch = {}
  local pr =  own or nil
  local prived_data = {} -- хранит приватные данные 
  local id_t = type(id_) == "string" and id_ or self:get_def_id()


  ---@param fld_type? t_field
  function t:cnt_cust_data(fld_type)
    fld_type = fld_type or "any"
    return ut.get_count_keys(prived_data, fld_type)
  end


  function t:get_all_data()
    return prived_data
  end

  function t:get_cust_data(keys)
    if keys == nil then
      return self:get_all_data()
    end
    if type(keys) == "table" then
      local res = {}
      for k in ipairs(keys) do
        table.insert(res, prived_data[k])
      end
      if #res == 1 then
        return table.unpack(res)
      end
      return res
    end
    return prived_data[keys]
  end



  --- Поиск данных по ключу
  function t:find_key(key)
    --print("call find_key(key)")
    local find_key_data = ut.find_tblvalue
    --print(find_key_data)
    return find_key_data(prived_data, key, "key")
  end

  ---NOTE реализовать проверку на уникальность ключей?
  --- @param data any -- добавляемые данные
  --- @param opt? table -- опции добавления not
  function t:set_data(data, opt)
    assert(data ~= nil, "Error in the function et_data().Attempt to add not-existing data")
    opt = opt or {}
    assert(type(opt) == "table")
    local unique = opt.unique or false -- не реализовано
    local separate = opt.separ or true
    if type(data) == "table" and separate then
      for k, v in pairs(data) do
        prived_data[trim(k)] =v
      end
    else
      prived_data = data
    end
  end

  --- Создание новой связанной таблицей 
  --- TODO: добавить выбор опции на проверку уникальности id, в данный момент 
  --- id должен быть уникальным
  function t:new_t(id_)
    assert(type(id_) == "string")
    id_ = trim(id_)
    assert(id_ ~= nil and id_ ~= "")

    for _, v in ipairs(ch) do
      assert(v ~= id_)
    end
    local t_ch = self:creator(id_, self)
    ch[#ch +1] = t_ch
    return t_ch
  end


  function t:get_id()
    --print("get_id >>> current name env: ", id_t)
    return id_t
  end

  --- Возвращает родительский узел (таблицу)
  --- 
  function t:get_parent_t(active)
    --print("get_parent_t >>> pr = ", pr)
    return active == true and pr ~= nil and lnk:set_active_t(pr) or pr
    -- if active == true and pr ~= nil then
    --   lnk:setactive_t(pr)
    -- end
    --return pr
  end

  --- Возвращает ссылку на таблицу потомков
  function t:get_chld_t()
    return ch
  end


  --- Возвращает количество вложенных узлов 
  --- Поиск осуществляется либо в текущем узле либо во вложенном,
  --- учитываетя первый уровень вложения относительно текущего
  function t:get_cnt_ch(id_)
    assert(id_ ~= "")
    local ns = lnk:get_func_active_t()()
    local len = 0
    --if id_ ~= nil and self:get_id() ~= id_ then 
    -- формально не запрещено иметь одинаковый id для родителя и потомка
    --print("self id = ", self:get_id(), "-> id = ", id_)
    if id_ ~= nil then
      len = self:find_ch(id_):get_cnt_ch()
    else
    --local ch = self:get_ch_t()
      len = #ch
    end
    lnk:set_active_t(ns)
    return len
  end


  --- Поиск вложенного узла по id с возможной активацией
  --- Возвращает найденный узел или nil
  function t:find_ch(id_, act)
    --assert(type(id_) == "string")
    assert(id_ ~= nil and id_ ~= "")
    id_ = trim(id_)
    for _, v in ipairs(ch) do
      if v:get_id() == id_ then
        -- print("find_ch: >>> Action = ", act)
        -- print("find_ch: >>> Current table = ", lnk:get_func_active_t()())
        -- print("find_ch: >>> New1 table = ", v)
        -- print("find_ch: >>> New2 table = ", lnk:set_active_t(v))
        -- print("find_ch: >>> New Current table = ", lnk:get_func_active_t()())

        return act == true and lnk:set_active_t(v) or v
      end
    end
    return nil
  end

  --- TODO удаление узла и всех вложенных ...
  --- 
  function t:del_ch(id_)
    if find_ch(id_) then
    end
  end

  setmetatable(t, self)
  self.__index = self

  return t
end

return node