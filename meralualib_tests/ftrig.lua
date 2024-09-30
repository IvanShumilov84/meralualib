--[[
    Для проверки рекомендуется период вызова скрипта сделать 1 секунду.
]]

require("_script_path")

 --  Подгружаем библиотеку.
local lib = require("../meralualib")


--  Фунцкия конвертации реал в бул.
local real_to_bool = lib["real_to_bool"]
--  Фунцкия конвертации бул в реал.
local bool_to_real = lib["bool_to_real"]

--  Экземпляр FTrig.
local ftrig_1 = lib["FTrig"]:new()
-- setValue("__meralualibtests_ftrig__ftrig_1.clk")


-- Главная функция скрипта, вызвается с заданной периодичностью
function lua_main()
	-- Работа с ftrig_1.
	ftrig_1:calc()
	ftrig_1.clk = real_to_bool(getValue("__meralualibtests_ftrig__ftrig_1.clk"))
	setValue("__meralualibtests_ftrig__ftrig_1.q", bool_to_real(ftrig_1.q))
end
