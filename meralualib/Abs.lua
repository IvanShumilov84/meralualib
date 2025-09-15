
local Abs = {}
--Abs.__index = Abs
--[[
  - Абстрактный класс, реализующий проверку 
  реализации абстрактных методов в классах - потомках.
  Данный класс не может иметь экземпляров. При попытке создания экземпляра 
  генериться исключение error 
--]]


function Abs:checkVirtualMethods(class, attr)
  attr = attr and type(attr) == "string" or "abs__"
  for k, v in pairs(self) do
    if type(v) == "function" and k:find(attr) then
      if not class[k] or class[k] == v then
        error("Virtual or abstract method" .. k .. "must be implemented in subclass")
      end
    end
  end
  --return true
end

--- Проверка допустимости новой реализации
-- В конструкторе создаваемого класса определить экземпляр данного метода
-- check_instance = Abs:make_check_inst_func(N), где N - допустимое число экземпляров данного класса

function Abs:make_check_inst_func(maxinst)
  maxinst = maxinst or -1
  local inst = 0
  return function ()
    if inst >= maxinst and maxinst >= 0 then --and inst >= maxinst
      return false, inst
    end
    inst = inst + 1
    return true, inst
  end
end

--- TODO доработать класс Abs, добавить опции сохранения instance - saveinst
--- TODO доработать или удалить опции retinst, retall

---@param arg {maxinst: integer, retinst: bool, retall: bool}
---@return function
function Abs:alloc_(arg)
  
  maxinst = arg.maxinst or -1
  retinst = arg.retinst or false
  retall = arg.retall or false

  local inst = nil
  local check_inst = self:make_check_inst_func(maxinst)
  ---@param tinst table 
  ---@return table | table[] | nil
  return function (tinst)
    -- делать ли проверку type(tinst) == "table" ????
    -- tinst = tinst and type(tinst) == "table" or {}
    -- в этом случае не возможно создать таблицу с произвольным содержанием
    tinst = tinst or {}
    local check_, i_ = check_inst()
    if check_ then
      inst = inst or {}
      inst[i_] = tinst
      return inst[i_]
    else
      if retinst then
        if retall then
          return inst
        else
          return inst ~= nil and inst[i_] or nil
        end
      else
        error("Cannot instance class")
      end
    end
  end
end

function Abs:new()
  local mt = getmetatable(self)
  local o = {}
  local stt, err = pcall(function ()
    o = setmetatable({}, mt)
  end)
  if not stt then
    error("Static Class cannot be instantiated")
  end
  o.__index = self
  return o
end

Abs= setmetatable(Abs, {
    --__newindex = function(table, key, value)
    --  error("Cannot modify StaticClass")
    --end,
    __metatable = "Static Class cannot be instantiated"
  }
)

return Abs