--[[
-- Модуль обработки аналоговых значений.
--]]

local t = {}


do -- Класс триггер изменения аналогового значения.
    ATrig = {}

    -- Тело класса.
    function ATrig:new()

        -- Публичные свойства.
        local obj = {
            step = 0, --  [вход] Шаг изменения значения.
            q = false, --  [выход] Состояние изменения значения.
            qu = false, --  [выход] Состояние увеличения значения.
            qd = false --  [выход] Состояние уменьшения значения.
        }

        -- Приватные свойства.
        local private = {
            value_last = 0, --  Последнее значение.
            diff = 0, --  Разность между значениями.
        }

        -- Публичные методы.
        function obj:upd(value, step)
            -- Контроллер.
            assert(
                type(value) == "number",
                "Argument 'value': expected 'number', got '" .. type(value) .. "'. "
            )
            assert(
                step == nil or type(step) == "number",
                "Argument 'step': expected 'number', got '" .. type(step) .. "'. "
            )
            self.step = step or self.step
            private.diff = value - private.value_last
            self.q = math.abs(private.diff) > self.step
            self.qu = value > private.value_last and self.q
            self.qd = value < private.value_last and self.q
            private.value_last = value
            return self.q, self.qu, self.qd
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    t["ATrig"] = ATrig
end

return t
