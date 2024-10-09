-- Библиотека фирмы МЕРА.
-- Версия: v0

--- Модуль таймеров.
-- @module timers


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
            input_last = false,     -- Последнее значение входа таймера.
            start_time = 0,         -- Время старта работы таймера, в секундах.
            et_last = 0
        }
        obj.enable = false   -- Вход активации таймера.
        obj.pt = 0          -- Время до активации выхода таймера, в секундах.
        obj.et = 0          -- Прошедшее время с момента true на входе таймера.
        obj.q = false       -- Выход таймера.

        -- Методы.
        function obj:calc(enable, pt)  -- Контроллер таймера.
            self.enable = enable or self.enable
            self.pt = pt or self.pt
            local cur_time = getRecorderTime()
            if self.enable and not private.input_last then
                private.start_time = cur_time
            end
            private.input_last = self.enable


            if self.enable and not self.q then
                self.et = cur_time - private.start_time
                if self.et < 0 then
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
    timers["Ton"] = Ton
end


return timers  -- Эта строка всегда последняя в этом модуле.
