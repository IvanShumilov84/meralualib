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

--  Экземпляр RTrig.
local rtrig_1 = lib["RTrig"]:new()
-- setValue("__meralualibtests_rtrig__rtrig_1.clk")


-- Главная функция скрипта, вызвается с заданной периодичностью
function lua_main()
	-- Работа с rtrig_1.
	rtrig_1:calc()
	rtrig_1.clk = real_to_bool(getValue("__meralualibtests_rtrig__rtrig_1.clk"))
	setValue("__meralualibtests_rtrig__rtrig_1.q", bool_to_real(rtrig_1.q))
end
