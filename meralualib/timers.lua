-- Библиотека фирмы МЕРА.
-- Версия: v0

--- Модуль таймеров.
-- @module timers
local Timers = {}

do
--- Класс Таймер TON.
--
-- Реализация классического таймера TON (timer on delay).
--
-- @class Ton 
    Ton = {}

--- Пример 1:
-- @code
--      local ton_1 = lib["Ton"]:new()  -- Создать экземпляр таймера (метод вызывается один раз).
--      ton_1.enable = true  -- Запуск таймера.
--      ton_1.pt = 5  -- Время таймера до присвоения true на выход q равно 5 секундам.
--      -- Главная функция скрипта, вызвается с заданной периодичностью.
--      function lua_main()
--          ton_1:calc()  -- Вызов работы таймера в цикле программы.
--          local some_event = ton_1.q  -- В переменной some_event через 5 секунд появится true.
--          local ton_timer = ton_1.et  -- В переменной ton_timer время тикает от 0 до 5 при true на входе таймера.
--      end
--
--- Пример 2:
-- @code
--      local ton_2 = lib["Ton"]:new()
--      ton_2.pt = 10
--      -- Главная функция скрипта, вызвается с заданной периодичностью.
--      function lua_main()
--          ton_2:calc(true) -- Вызов с передачей в качестве первого параметра enable = true, значение уставки 10 секунд.
--          ton_2:calc(true, 5)  -- Вызов с передачей двух параметров enable = true, pt = 5 секунд
--          local some_event_2 = ton_2:calc(true) -- В переменной some_event через 5 секунд появится true.
--      end
--
-- Реализация таймера предусматривает переход Recorder или СИАМ из просмотра в запись и обатно произвольное число раз,
-- при этом отсчёт времени таймером не прерывается.
    -- Тело класса.
    function Ton:new()

        -- Свойства.
        local obj = {}
        local private = {
            enable_last = false,     -- Последнее значение входа таймера.
            start_time = 0,         -- Время старта работы таймера, в секундах.
            et_last = 0
        }
        obj.enable = false   -- Вход активации таймера.
        obj.pt = 0          -- Время до активации выхода таймера, в секундах.
        obj.et = 0          -- Прошедшее время с момента true на входе таймера.
        obj.q = false       -- Выход таймера.

        -- Методы.
        function obj:calc(enable, pt)  -- Контроллер таймера.
            if enable ~= nil then
                self.enable = enable --~= nil and enable or self.enable
            end
            if pt ~= nil then
                self.pt = pt --~= nil and pt or self.pt
            end
            local cur_time = getRecorderTime()
            if self.enable and not private.enable_last then
                private.start_time = cur_time
            end
            private.enable_last = self.enable


            if self.enable and not self.q then
                self.et = cur_time - private.start_time
                if self.et < private.et_last then
                    private.start_time = (-1) * private.et_last
                    self.et = cur_time - private.start_time
                end
                private.et_last = self.et
            elseif not self.enable then
                self.et = 0
                private.et_last = 0
            end


            if self.enable and self.et >= self.pt then
                self.q = true
            elseif not self.enable then
                self.q = false
            end
            return self.q
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    Timers["Ton"] = Ton
end

do
    --- Класс Таймер TOF.
    --
    -- Реализация классического таймера TOF (timer off delay).
    --
    -- @class Tof 
        Tof = {}
    
    --- Пример 1:
    -- @code
    --      local tof_1 = lib["Tof"]:new()  -- Создать экземпляр таймера (метод вызывается один раз).
    --      tof_1.enable = true  -- Запуск таймера.
    --      tof_1.pt = 5  -- Время таймера до сброса в значение false выхода q равно 5 секундам.
    --      -- Главная функция скрипта, вызвается с заданной периодичностью.
    --      function lua_main()
    --          tof_1:calc()  -- Вызов работы таймера в цикле программы.
    --          local some_event = tof_1.q  -- В переменной some_event через 5 секунд появится false.
    --          local tof_timer = tof_1.et  -- В переменной tof_timer время изменяется от 0 до 5 после 
    --                                      -- сброса на входе таймера.
    --      end
    --
    --- Пример 2:
    -- @code
    --      local tof_2 = lib["Tof"]:new()
    --      tof_2.pt = 10
    --      -- Главная функция скрипта, вызвается с заданной периодичностью.
    --      function lua_main()
    --          tof_2:calc(enable) -- Вызов с передачей в качестве первого параметра enable = true, значение уставки 10 секунд.
    --          tof_2:calc(enable, 5)  -- Вызов с передачей двух параметров enable = true, pt = 5 секунд.
    --          local some_event_2 = tof_2:calc(enable) -- В переменной some_event через 5 секунд появится false 
    --                                                  -- при условии сброса enable = false.
    --      end
    --
    -- Реализация таймера предусматривает переход Recorder или СИАМ из просмотра в запись и обатно произвольное число раз,
    -- при этом отсчёт времени таймером не прерывается.
        -- Тело класса.
        function Tof:new()
    
            -- Свойства.
            local obj = {}
            local private = {
                tn = Ton:new(),
                enable_last = false,     -- Последнее значение входа таймера.
                start_time = 0,         -- Время старта работы таймера, в секундах.
                et_last = 0
            }

            obj.enable = false   -- Вход активации таймера.
            obj.pt = 0          -- Время до активации выхода таймера, в секундах.
            obj.et = 0          -- Прошедшее время с момента true на входе таймера.
            obj.q = false       -- Выход таймера.

            -- Методы.
            function obj:calc(enable, pt)  -- Контроллер таймера.
                if enable ~= nil then
                    self.enable = enable
                end 
                if pt ~= nil then
                    self.pt = pt --~= nil and pt or self.pt
                end
                private.tn:calc(not self.enable and private.enable_last, self.pt)
                self.et = private.tn.et

                private.enable_last = self.enable or private.enable_last and not private.tn.q
                if private.enable_last then
                    self.q = true
                else
                    self.q = false
                end
                return self.q
            end
    
            setmetatable(obj, self)
            self.__index = self
            return obj
        end
        Timers["Tof"] = Tof
    end

return Timers  -- Эта строка всегда последняя в этом модуле.
