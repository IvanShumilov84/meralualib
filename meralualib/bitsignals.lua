
--- Модуль обработки с битовых сигналов
--- 
-- @module bitsignals

--
local t = {}



do  -- Класс триггер R-TRIG.
  --[[ 
      Реализация классического триггера R-TRIG (детектор переднего фронта).
      Пример вызова:
      r_trig_1 = t.RTrig:new()   -- Создать экземпляр триггера (метод вызывается один раз).
      r_trig_1.clk = some_clk         -- Обработка появления переднего фронта на канале some_clk.
      r_trig_1:upd()                 -- Вызов работы триггера в цикле программы.
      some_event = r_trig_1.q         -- На канале some_event появится true на время одного цилка программы
                                       при появлении переднего фронта на канале some_clk.

      Пример 2
      r_trig_1:upd(some_clk)                 -- Вызов триггера с одновременной передачей канала для отслеживания фронта.
      some_event = r_trig_1:upd(some_clk)    -- На канале some_event появится true на время одного цилка программы
                                              при появлении переднего фронта на канале some_clk.
  ]]
  t.RTrig = {}
  -- Тело класса.
  function t.RTrig:new()

      -- Свойства.
      local obj = {}
      local private = {
          clk_last = false    -- Последнее значение входа триггера.
      }
      obj.clk = false         -- Вход триггера для детектирования фронта.
      obj.q = false           -- Выход триггера.

      -- Методы.
      function obj:upd(clk)  -- Контроллер триггера.
          self.clk = clk == nil and self.clk or clk
          self.q = false
          if self.clk and not private.clk_last then
              self.q = true
          end
          private.clk_last = self.clk
          return self.q
      end

      setmetatable(obj, self)
      self.__index = self
      return obj
  end
end


do  -- Класс триггер F-TRIG.
  --[[
      Реализация классического триггера F-TRIG (детектор заднего фронта).
      Пример вывзова:

  ]]
  t.FTrig = {}
  -- Тело класса.
  function t.FTrig:new()

      -- Свойства.
      local obj = {}
      local private = {
          clk_last = false    -- Последнее значение входа триггера.
      }
      obj.clk = false         -- Вход триггера для детектирования фронта.
      obj.q = false           -- Выход триггера.

      -- Методы.
      function obj:upd(clk)  -- Контроллер триггера.
          self.clk = clk == nil and self.clk or clk
          self.q = false
          if not self.clk and private.clk_last then
              self.q = true
          end
          private.clk_last = self.clk
          return self.q
      end

      setmetatable(obj, self)
      self.__index = self
      return obj
  end
end


return t