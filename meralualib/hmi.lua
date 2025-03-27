--[[
-- Модуль обработки элементов графического интерфейса мнемосхем.
--]]

local M = {}


local tags = require("meralualib\\tags")


-- Создание каналов к элементу мнемосхемы.
---@param elem_name string Имя элемента мнемосхемы.
---@param items {suffix...: string} Суффиксы к именам каналов.
local function create_tags(elem_name, items)
    local ttag = {}
    for _, item in ipairs(items) do
        local tag = {}
        tag.name = elem_name .. "." .. item
        table.insert(ttag, tag)
    end
    tags:CreateNewTags(ttag)
end


do --  Класс Кнопка-кликер.
    Btn_click = {}

    function Btn_click:new(name)

        -- Публичные свойства.
        local obj = {
            cmd = false, --  [вход] Событие.
            unlock = true, --  [вход] Разблокировка кнопки.
            q = false --  [выход] Действие.
        }

        -- Приватные свойства.
        local private = {
            cmd_last = false -- Предыдущее значение события.
        }

        create_tags(name, {"cmd", "unlock", "q"})

        -- Публичные методы.
        function obj:upd(cmd)
            -- Контроллер.
            assert(
                cmd == nil or type(cmd) == "boolean",
                "Argument 'cmd': expected 'boolean', got '" .. type(cmd) .. "'. "
            )
            assert(
                name == nil or type(name) == "string",
                "Argument 'name': expected 'string', got '" .. type(name) .. "'. "
            )
            assert(name == nil or name ~= "", "Argument 'name' is empty string. ")
            if cmd ~= nil then
                self.cmd = cmd
            elseif name ~= nil then
                self.cmd = getValue(name .. ".cmd") > 0
            end
            self.q = self.cmd and not private.cmd_last
            private.cmd_last = self.cmd
            if name ~= nil then
                setValue(name .. ".q", self.q and 1 or 0)
                setValue(name .. ".unlock", self.unlock and 1 or 0)
            end
            return self.q
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    M["Btn_click"] = Btn_click
end


do --  Класс Кнопка-переключатель.
    Btn_toggle = {}

    function Btn_toggle:new(name)

        -- Публичные свойства.
        local obj = {
            cmd = false, --  [вход] Событие.
            unlock = true, --  [вход] Разблокировка кнопки.
            q = false --  [выход] Действие.
        }

        -- Приватные свойства.
        local private = {
            cmd_last = false -- Предыдущее значение события.
        }

        create_tags(name, {"cmd", "unlock", "q"})

        -- Публичные методы.
        function obj:upd(cmd)
            -- Контроллер.
            assert(
                cmd == nil or type(cmd) == "boolean",
                "Argument 'cmd': expected 'boolean', got '" .. type(cmd) .. "'. "
            )
            assert(
                name == nil or type(name) == "string",
                "Argument 'name': expected 'string', got '" .. type(name) .. "'. "
            )
            assert(name == nil or name ~= "", "Argument 'name' is empty string. ")
            if cmd ~= nil then
                self.cmd = cmd
            elseif name ~= nil then
                self.cmd = getValue(name .. ".cmd") > 0
            end
            if self.cmd and not private.cmd_last then
                self.q = not self.q
            end
            private.cmd_last = self.cmd
            if name ~= nil then
                setValue(name .. ".q", self.q and 1 or 0)
                setValue(name .. ".unlock", self.unlock and 1 or 0)
            end
            return self.q
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    M["Btn_toggle"] = Btn_toggle
end


do --  Класс Выпадающий список.
    Combobox = {}

    function Combobox:new(name)

        -- Публичные свойства.
        local obj = {
            index = 0, --  [выход] Индекс выбранного значения из списка.
            unlock = true, --  [вход] Разблокировка списка.
            trig = false --  [выход] Событие смены значения из списка.
        }

        -- Приватные свойства.
        local private = {
            index_last = 0 -- Предыдущий индекс.
        }

        create_tags(name, {"index", "unlock"})

        -- Публичные методы.
        function obj:upd(index)
            -- Контроллер.
            assert(index == nil or type(index) == "number", private:msg_index_number(index))
            assert(name == nil or type(name) == "string", private:msg_name_string(name))
            assert(name == nil or name ~= "", private:msg_name_empty(name))
            if index ~= nil then
                self.index = index
            elseif name ~= nil then
                self.index = getValue(name .. ".index")
            end
            self.trig = self.index ~= private.index_last
            private.index_last = self.index
            if name ~= nil then
                setValue(name .. ".unlock", self.unlock and 1 or 0)
            end
            return self.index, self.trig
        end

        function obj:setIndex(index)
            -- Инициализировать индекс.
            assert(type(index) == "number", private:msg_index_number(index))
            assert(type(name) == "string", private:msg_name_string(name))
            assert(name ~= "", private:msg_name_empty(name))
            self.index = index
            setValue(name .. ".index", index)
        end

        -- Приватные методы.
        function private:msg_index_number(index)
            -- Сообщение в ассерт, что index не число.
            return "Argument 'index': expected 'number', got '" .. type(index) .. "'. "
        end

        function private:msg_name_string(name)
            -- Сообщение в ассерт, что name не строка.
            return "Argument 'name': expected 'string', got '" .. type(name)  .. "'. "
        end

        function private:msg_name_empty(name)
            -- Сообщение в ассерт, что name пустая строка.
            return "Argument 'name' is empty string. "
        end

        setmetatable(obj, self)
        self.__index = self
        return obj
    end
    M["Combobox"] = Combobox
end

return M
