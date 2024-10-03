-- Библиотека фирмы МЕРА.
-- Версия: v0


local lib = {}
--[[
    Импорт библиотеки в свой моудуль:
    local lib = require("meralualib.meralualib")
]]


do  -- Класс Таймер TON.
    --[[ 
        Реализация классического таймера TON (timer on delay).
        Пример вызова:
        local ton_1 = lib["Ton"]:new()  -- Создать экземпляр таймера (метод вызывается один раз).
        ton_1.enable = true  -- Запуск таймера.
        ton_1.pt = 5  -- Время таймера до присвоения true на выход q равно 5 секундам.
        ton_1:calc()  -- Вызов работы таймера в цикле программы.
        local some_event = ton_1.q  -- В переменной some_event через 5 секунд появится true.
        local ton_timer = ton_1.et  -- В переменной ton_timer время тикает от 0 до 5 при true на входе таймера.

        Пример 2:
        local ton_2 = lib["Ton"]:new()
        ton2.pt = 10
        ton2:calc(true) -- Вызов с передачей в качестве первого параметра enable = true, значение уставки 10 секунд.
        ton2:calc(true, 5)  -- Вызов с передачей двух параметров enable = true, pt = 5 секунд
        -----
        -- Реализация таймера предусматривает переход Recorder или СИАМ из просмотра в запись и обатно произвольное число раз,
        -- при этом осчет времени таймером не прерывается.
    ]]
    Ton = {}
    -- Тело класса.
    function Ton:new()

        -- Свойства.
        local obj = {}
        local prived = {
            input_last = false,     -- Последнее значение входа таймера.
            start_time = 0,         -- Время старта работы таймера, в секундах.
            et_last = 0
        }
        obj.start = false   -- Вход активации таймера.
        obj.pt = 0          -- Время до активации выхода таймера, в секундах.
        obj.et = 0          -- Прошедшее время с момента true на входе таймера.
        obj.q = false       -- Выход таймера.

        -- Методы.
        function obj:calc(enable, pt)  -- Контроллер таймера.
            self.start = enable or self.start
            self.pt = pt or self.pt
            local cur_time = getRecorderTime()
            if self.start and not prived.input_last then
                prived.start_time = cur_time
            end
            prived.input_last = self.start

            self.et = 0
            if self.start then
                self.et = cur_time - prived.start_time
                if self.et < 0 then
                    prived.start_time = (-1) * prived.et_last
                    self.et = cur_time - prived.start_time                    
                end
                prived.et_last = self.et           
            end

            self.q = false
            if self.et >= self.pt then
                self.q = true
            end
            return self.q
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    lib["Ton"] = Ton
end


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
    lib["real_to_bool"] = real_to_bool
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
    lib["bool_to_real"] = bool_to_real
end


do  -- Класс триггер R-TRIG.
    --[[ 
        Реализация классического триггера R-TRIG (детектор переднего фронта).
        Пример вызова:
        r_trig_1 = lib["RTrig"]:new()  -- Создать экземпляр триггера (метод вызывается один раз).
        r_trig_1.clk = some_clk  -- Обработка появления переднего фронта на канале some_clk.
        r_trig_1:calc()  -- Вызов работы триггера в цикле программы.
        some_event = r_trig_1.q  -- На канале some_event появится true на время одного цилка программы
                                    при появлении переднего фронта на канале some_clk.

        Пример 2:

    ]]
    RTrig = {}
    -- Тело класса.
    function RTrig:new()

        -- Свойства.
        local obj = {}
        local prived = {
            clk_last = false  -- Последнее значение входа триггера.
        }
        obj.clk = false  -- Вход триггера для детектирования фронта.
        obj.q = false  -- Выход триггера.

        -- Методы.
        function obj:calc(clk)  -- Контроллер триггера.
            self.clk = clk or self.clk
            self.q = false
            if self.clk and not prived.clk_last then
                self.q = true
            end
            prived.clk_last = self.clk
            return self.q
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    lib["RTrig"] = RTrig
end


do  -- Класс триггер F-TRIG.
    --[[
        Реализация классического триггера F-TRIG (детектор заднего фронта).
        Пример вывзова:

    ]]
    FTrig = {}
    -- Тело класса.
    function FTrig:new()

        -- Свойства.
        local obj = {}
        local prived = {
            clk_last = false  -- Последнее значение входа триггера.
        }
        obj.clk = false  -- Вход триггера для детектирования фронта.
        obj.q = false  -- Выход триггера.

        -- Методы.
        function obj:calc(clk)  -- Контроллер триггера.
            self.clk = clk or self.clk
            self.q = false
            if not self.clk and prived.clk_last then
                self.q = true
            end
            prived.clk_last = self.clk
            return self.q
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    lib["FTrig"] = FTrig
end


return lib  -- Эта строка всегда последняя в этом модуле.
