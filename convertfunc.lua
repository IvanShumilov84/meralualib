--[[
-- Библиотека фирмы МЕРА.
-- Версия: v0
--]]

convertfunc = {}


do  -- Функция конвертации реал в бул.
  --[[
      Пример вызова:
      local real_to_bool = lib["real_to_bool"]
      local bool_value = real_to_bool(real_value)
  ]]
  function real_to_bool(real_value)
      assert(bool_value ~= nil , "bool_value is nil ")
      assert(type(bool_value) ~= "string", "bool_value is string ")

      return real_value > 0
  end
  convertfunc["real_to_bool"] = real_to_bool
end


do  -- Функция конвертации бул в реал.
  --[[
      Пример вызова:
      local bool_to_real = lib["bool_to_real"]
      local real_value = bool_to_real(bool_value)
  ]]
  function bool_to_real(bool_value)
      assert(bool_value ~= nil , "bool_value is nil ")
      assert(type(bool_value) ~= "string", "bool_value is string ")
      return bool_value and 1 or 0
  end
  convertfunc["bool_to_real"] = bool_to_real
end


return convertfunc
