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
        ton_1.input = true  -- Запуск таймера.
        ton_1.pt = 5  -- Время таймера до присвоения true на выход q равно 5 секундам.
        ton_1:calc()  -- Вызов работы таймера в цикле программы.
        local some_event = ton_1.q  -- В переменной some_event через 5 секунд появится true.
        local ton_timer = ton_1.et  -- В переменной ton_timer время тикает от 0 до 5 при true на входе таймера.
    ]]
    Ton = {}
    -- Тело класса.
    function Ton:new()

        -- Свойства.
        local obj = {}
        obj.input = false  -- Вход активации таймера.
        obj.input_last = false  -- Последнее значение входа таймера.
        obj.start_time = 0  -- Время старта работы таймера, в секундах.
        obj.pt = 0  -- Время до активации выхода таймера, в секундах.
        obj.et = 0  -- Прошедшее время с момента true на входе таймера.
        obj.q = false  -- Выход таймера.

        -- Методы.
        function obj:calc()  -- Контроллер таймера.
            local cur_time = getRecorderTime()
            if self.input and not self.input_last then
                self.start_time = cur_time
            end
            self.input_last = self.input
            if not self.input then
                self.start_time = cur_time
            end
            self.q = false
            if (cur_time - self.start_time) > self.pt then
                self.q = true
            end
            self.et = 0
            if self.input then
                self.et = cur_time - self.start_time
            end
            if self.input and self.q then
                self.et = self.pt
            end
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
        local bool_value = false
        if real_value > 0 then
            bool_value = true
        end
        return bool_value
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
        local real_value = 0
        if bool_value then
            real_value = 1
        end
        return real_value
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
    ]]
    RTrig = {}
    -- Тело класса.
    function RTrig:new()

        -- Свойства.
        local obj = {}
        obj.clk = false  -- Вход триггера для детектирования фронта.
        obj.clk_last = false  -- Последнее значение входа триггера.
        obj.q = false  -- Выход триггера.

        -- Методы.
        function obj:calc()  -- Контроллер триггера.
            obj.q = false
            if self.clk and not self.clk_last then
                obj.q = true
            end
            self.clk_last = self.clk
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
        obj.clk = false  -- Вход триггера для детектирования фронта.
        obj.clk_last = false  -- Последнее значение входа триггера.
        obj.q = false  -- Выход триггера.

        -- Методы.
        function obj:calc()  -- Контроллер триггера.
            obj.q = false
            if not self.clk and self.clk_last then
                obj.q = true
            end
            self.clk_last = self.clk
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    lib["FTrig"] = FTrig
end


return lib  -- Эта строка всегда последняя в этом модуле.
