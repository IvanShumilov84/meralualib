
local t = {}

---@alias t_field
---|>"any"
---| "nil"
---| "number"
---| "string"
---| "boolean"
---| "table"
---| "function"
---| "thread"
---| "userdata"


-- Функция подсчета ключей в талице
---@param tbl table
---@param fld_type? t_field
t.get_count_keys = function (tbl, fld_type)
  assert(type(tbl) == "table")
  local res = 0
  fld_type = fld_type or "any"
  for k in pairs(tbl) do
    if fld_type == "any" or type(k) == fld_type then
      res = res + 1
    end
  end
  return res
end


---@alias f_opt
---|>"key"
---| "val"
---| "all"

--- Функция поиска значения в таблице.
--- Поиск возможен по ключу, либо по значению, либо по обоим полям
--- Возвращает упакованное значение status, {key, value}
---@param tbl table
---@param value any
---@param option? f_opt
---@return status boolean, table<{key: any, value: any}>
t.find_tblval = function (tbl, value, option)
  assert(type(tbl) == "table")
  assert(value ~= nil)
  option = option or "key"
  assert(option == "key" or option == "val" or option == "all")
  --local res = {false, nil, nil}
  for k, val in pairs(tbl) do
    if option == "key" or option == "all" then
      if k == value then
        return true, {k, val}
      end
    end
    if option == "val" or option == "all" then
      if val == value then
        return true, {k, val}
      end
    end
  end
  return false, {}
end

--- Функция поиска значения в таблице.
--- Возвращает распакованные значения status, key, value
---@param tbl table
---@param value any
---@param option? f_opt
---@return boolean status, any kay, any value
t.find_tblvalue = function (tbl, value, option)
  local status, tbl_res = t.find_tblval(tbl, value, option)
  return status, table.unpack(tbl_res)
end


--- Функция поиска ключей в таблице
--- 
----@generic T: {value:any, option: f_opt} 
----@generic R: {status: boolean, key: any, value: any}
---@param tbl table
---@param values string | table<{value:any, option: f_opt}>   
---@return table<{status: boolean, key: any, value: any}>
t.find_tblvalues = function (tbl, values)
  assert (type(tbl) == "table")
  local t_values = type(values)
  assert (t_values == "table" or t_values == "string")

  if t_values ~= "table" then
    return {{t.find_tblvalue(tbl, t_values, "key")}}
  end
  local res = {}
  local opt = "key"
  for _, val in pairs(values) do
    if type(val) == "table" then
      val = val.value or val[1]
      opt = val.option or val[2]
    end
    table.insert(res, {t.find_tblvalue(tbl, val, opt)})
  end
  return res
end


--- Функция выделяет неименованные значения в таблице
--- @param tbl table
--- @param keys table # список именованных ключей
t.extr_tabl_args = function (tbl, keys)
  assert(type(tbl) == "table")
  assert(type(keys) == "table")
  local res = {}
  for k, v in pairs(tbl) do
    if not t.find_tblvalue(keys, k, "val") then
      res[k] = v
    end
  end
  return res
end

---@alias ff_opt
---| f_opt
---| "string"

---@enum t_key
local t_key = {
  orinal_key = 0,
  sorted_key = 1
}

--- Функция поэлементной обработки значений таблицы 
--- Позволяет обрабатывать ограниченное значение элементов таблицы,
--- начиная с определенного индекса (ключа) таблицы 
---@param tbl table
---@param fexec function
---@param option? {startkey: t_field, cnt: number, combine: ff_opt, plchold: string, fkey: t_key}
t.tbl_exec = function (tbl, fexec, option)
  --[[
    Пример вызова:
    tbl_exact(tbl, print) # для распечатывания всех полей таблицы
  --]]
  assert(type(tbl) == "table")
  assert(type(fexec) == "function")
  option = option or {}
  assert(type(option) == "table")

  local startkey = option.startkey or option[1]
  local en = (startkey == nil)
  local cnt = option.cnt or option [2]
  cnt = (type(cnt) == "number" and cnt) or -1
  local combine = option.combine or option [3] or "val"
  local plchold = option.plchold or option [4] or ""
  local fkey = option.fkey or option [5] or t_key.sorted_key

  local res = {}
  local c = 0
  --local argv = {}
  for k, v in pairs(tbl) do
    en = en or startkey ~= nil and k == startkey
    if cnt >= 0 and c >= cnt then break end
    if en then
      local argv =
        combine == "all" and {k, v}
        or combine == "key" and {k}
        or combine  == "val" and {v}
        or combine == "string" and {tostring(k) .. tostring(plchold) .. tostring(v)}
      c = c + 1
      local k_ = fkey == t_key.orinal_key and k
                  or fkey == t_key.sorted_key and c
      res[k_] = fexec(table.unpack(argv))

    end
  end
  return res
end


--- Функция распаковки любых таблиц (массивов и словарей)
---@param tbl table
---@param option? {startkey: t_field, cnt: number, combine: ff_opt, plchold: string}
t.tbl_unpack = function (tbl, option)
  assert(type(tbl) == "table")
  local function floc(...)
    local arg = table.pack(...)
    if #arg == 1 then 
      return table.unpack(arg)
    end
    return arg
  end

  option = option or {}
  assert(type(option) == "table")
  option.plchold = option.plchold or option[4] or " : "
  option.fkey = t_key.sorted_key

  local arg = t.tbl_exec(tbl, floc, option)
  return table.unpack(arg)
end

--- Добавлене (замещение) данных в виртуальное окружение
--- работает, начиная с версии Lua 5.2
--- @param L table -- таблица с добавляемыми данными в виртуальное окружение
--- @param keys? table  -- таблица с перечнем (простой список) имен ключей для выборочного добавления данных
                        -- по умолчанию добавляются все данные из L                     
--- @param ENV? table   -- таблица виртуального окружения, по умолчанию _ENV
function t.add_env(L, keys, ENV)
  assert(type(L) == "table", "The argument of the function must be a table")
  keys = type(keys) == "table" and keys or {}
  ENV = type(ENV) == "table" and ENV or _ENV
  local fins = #keys == 0
  for k, v in pairs(L) do
    if not fins then
      for _, key in ipairs(keys) do
        if key == k then
          fins = true
          break
        end
      end
    end
    if fins then
      _ENV[k] = v
    end
  end
end

--- Отдельно взята функция из библиотеки strings от c0sui from github.com
function t.strtrim(str)
	str = str:match("^%s*(.-)%s*$")
	return str
end

return t