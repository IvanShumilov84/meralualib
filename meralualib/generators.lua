--- Модуль генераторов сигналов.


local timers = require("meralualib.timers")
local bitsignals = require("meralualib.bitsignals")


local M = {}


do
    -- Класс Генератор Импульсов PulseGen.

    --[[ Описание:

        1. Запуск по true на входе блока.
        2. Импульсы имеют низкий уровень = 0/false, высокий уровень = 1/true.
        3. Имеется возможность настройки длительности уровней по времени, по умолчанию длительность
            каждого уровня = 1 секунда.
        4. Настройка типа выхода - вещественный 0-1 (по умолчанию), булевый.
        5. На выходе получаем периодический сигнал прямоугольной формы амплитудой 0-1, либо true-false.

    ]]

    --[[ Пример использования:
        
        local gn = require("meralualib.generators")  -- Импорт библиотеки.
        local pulse_gen = gn.PulseGen:new()  -- Создание экземпляра.
        -- Вариант, когда экземпляр возвращает импульсы:
        setValue("pulse_gen.q", pulse_gen(true, 2, 0.5))
        -- Вариант отдельного вызова экземпляра и отдельного чтения его выхода:
        pulse_gen(true, 2, 0.5)
        setValue("pulse_gen.q", pulse_gen.q)
    ]]


    M.PulseGen = {}

    -- Метод создания нового экземпляра.
    function M.PulseGen:new()

        -- Режим выхода.
        local QMODE = {
            REAL = "real",
            BOOL = "bool"
        }

        local obj = {
            -- Входы.
            input = false,  -- Разрешение работы.
            ptl = 1,  -- Длительность низкого уровня, секунды.
            pth = 1,  -- Длительность высогого уровня, секунды.
            qmode = QMODE.REAL,  -- Тип выходного сигнала: вещественный 0-1, булевый false-true.
            -- Выходы.
            q = 0  -- Выход.
        }

        -- Внутренние переменные.
        local private = {
            tn = timers.Ton:new(),
            rtrig = bitsignals.RTrig:new(),
            q = false
        }

        local mt = {}

        -- Вызов экземпляра.
        function mt:__call(input, ptl, pth, qmode)
            if input ~= nil then
                self.input = input
            end
            if ptl ~= nil then
                self.ptl = ptl
            end
            if pth ~= nil then
                self.pth = pth
            end
            if qmode ~= nil then
                self.qmode = qmode
            end

            private.rtrig:upd(self.input);
            if private.rtrig.q then
                private.tn.pt = self.pth;
                private.q = true;
            end

            private.tn:calc(self.input and not private.tn.q);

            if private.tn.pt == self.ptl and private.tn.q then
                private.tn.pt = self.pth;
            elseif private.tn.pt == self.pth and private.tn.q then
                private.tn.pt = self.ptl;
            end

            if self.input then
                if private.tn.q then
                    private.q = not private.q;
                end
            else
                private.q = false;
            end

            if self.qmode == QMODE.BOOL then
                self.q = private.q
            else
                self.q = private.q and 1 or 0
            end

            return self.q
        end

        setmetatable(obj, mt)
        return obj
    end
end


return M
